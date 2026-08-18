// lib/services/firebase/firebase_parcel_service.dart
//
// Phase 2 implementation of ParcelService, backed by Firestore's
// `centers/{centerId}/packed_parcels` sub-collection
// (FirestorePaths.packedParcels(centerId)).
//
// Drop-in replacement for MockParcelService: TaskProvider and
// PackedParcelsProvider only depend on the abstract ParcelService
// interface, so no provider/screen changes are needed beyond wiring this
// into main.dart.
//
// Two deliberate behavior changes from the mock, both explicitly called
// for by this interface's own doc comments (see reserveParcels and
// packParcels below) — flagging both clearly since neither is a pure
// drop-in:
//
//   1. reserveParcels uses a real Firestore Transaction (the interface
//      doc comment says this "MUST" be the case; MockParcelService just
//      mutated an in-memory list with no concurrency control at all,
//      which was fine for a single in-memory instance but wouldn't be
//      safe against two real devices).
//   2. packParcels now actually checks center inventory against the
//      current blueprint before creating parcels, and deducts the
//      consumed stock — MockParcelService's packParcels never did either
//      (it fabricated parcels unconditionally), despite the interface
//      doc comment saying packing should happen "after verifying
//      sufficient inventory". No existing screen calls packParcels yet
//      (grepped — zero call sites outside the service/interface files),
//      so there's no existing behavior to preserve here.
//
// packParcels also does NOT replicate MockParcelService's
// _lazySeedCenter (20 fabricated "available" parcels for any
// never-before-seen centerId) — that was demo convenience for an
// in-memory mock, not real business logic; a real center should start
// with zero parcels until packParcels is actually called.
//
// [Fix — architectural] This service is also now the sole writer of
// DonationCenterModel.availableParcels — the real, live "ready right now"
// count, mirrored from this sub-collection onto the parent center doc so
// screens that just need a quick number don't each need their own
// parcelsStream/query. Previously the center doc only cached
// `maxParcelsAvailable` (renamed packingCapacity), which is raw-stock kit
// *potential* and has nothing to do with how many parcels are actually
// packed — see FirebaseInventoryService and DonationCenterModel's doc
// comments for the full story. packParcels/reserveParcels/returnParcels
// below each update availableParcels in the same batch/transaction as the
// parcel docs they touch, so the two can never be observably out of sync.
//
// [Unverified] Checked by hand against current cloud_firestore usage —
// not run against a live Firestore instance from here.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/constants/firestore_paths.dart';
import '../../core/enums/parcel_status.dart';
import '../../core/errors/app_exception.dart';
import '../../models/packed_parcel_model.dart';
import '../../models/parcel_blueprint_model.dart';
import '../firestore/parcel_service.dart';
import 'firebase_inventory_service.dart';

class FirebaseParcelService implements ParcelService {
  final FirebaseFirestore _db;

  /// Used only by packParcels to deduct consumed stock via the same,
  /// already-reviewed add/deduct + bottleneck-recalculation logic
  /// FirebaseInventoryService already implements — rather than
  /// duplicating that logic here. This mirrors the same "each service
  /// only takes an optional FirebaseFirestore" constructor shape used
  /// everywhere else, so main.dart's wiring doesn't need to change.
  late final FirebaseInventoryService _inventoryService;

  FirebaseParcelService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _inventoryService = FirebaseInventoryService(firestore: _db);
  }

  CollectionReference<Map<String, dynamic>> _parcelsCol(String centerId) =>
      _db.collection(FirestorePaths.packedParcels(centerId));

  /// Reference to the parent `centers/{centerId}` doc — used only to keep
  /// [DonationCenterModel.availableParcels] mirroring the real live count
  /// of [ParcelStatus.available] docs in [_parcelsCol], so screens that
  /// just need a quick number (map markers, My Centers, Global Inventory,
  /// the public center detail screen) don't each need their own
  /// `parcelsStream`/query. Every method below that changes how many
  /// parcels are actually available (packParcels, reserveParcels,
  /// returnParcels) must keep this field in sync — see each method's
  /// comment for exactly where.
  DocumentReference<Map<String, dynamic>> _centerDoc(String centerId) =>
      _db.collection(FirestorePaths.centers).doc(centerId);

  @override
  Stream<List<PackedParcelModel>> parcelsStream(String centerId) {
    return _parcelsCol(centerId).snapshots().map(
          (snap) => snap.docs
              .map((d) => PackedParcelModel.fromMap(d.data(), id: d.id))
              .toList(),
        );
  }

  @override
  Future<List<PackedParcelModel>> getAvailableParcels(String centerId) async {
    final snap = await _parcelsCol(centerId)
        .where('status', isEqualTo: ParcelStatus.available.name)
        .get();
    return snap.docs
        .map((d) => PackedParcelModel.fromMap(d.data(), id: d.id))
        .toList();
  }

  @override
  Future<void> packParcels(String centerId, int count) async {
    if (count <= 0) return;

    // 1. Read the current blueprint directly (same reasoning as reading
    //    inventory directly below — no BlueprintService dependency wired
    //    through main.dart's DI, so this reads Firestore itself rather
    //    than requiring a cross-service constructor change).
    final blueprintDoc = await _db
        .collection(FirestorePaths.blueprint)
        .doc(FirestorePaths.blueprintDocId)
        .get();
    final blueprint = blueprintDoc.exists
        ? ParcelBlueprintModel.fromMap(blueprintDoc.data()!)
        : ParcelBlueprintModel.defaultBlueprint;

    // 2. Read current inventory for this center.
    final inventorySnap = await _db
        .collection(FirestorePaths.inventoryItems(centerId))
        .get();
    final inventoryByName = {
      for (final doc in inventorySnap.docs)
        (doc.data()['itemName'] as String): doc,
    };

    // 3. Verify every blueprint item has enough stock for `count` parcels.
    //    [Speculation] This read-then-write has the same non-transactional
    //    race caveat as FirebaseInventoryService._mutateStock — two
    //    coordinators packing the same center's parcels at the exact same
    //    moment could both pass this check before either's deduction
    //    lands. Acceptable at this app's scale (documented there too);
    //    wrap in a transaction later if that becomes a real concern.
    final shortages = <String>[];
    for (final item in blueprint.items) {
      final needed = item.quantityPerParcel * count;
      final doc = inventoryByName[item.itemName];
      final have = (doc?.data()['currentStock'] as num?)?.toDouble() ?? 0;
      if (have < needed) {
        shortages.add(
          '${item.itemName} (need $needed ${item.unit}, have $have)',
        );
      }
    }
    if (shortages.isNotEmpty) {
      throw InsufficientInventoryException(
        'Not enough stock to pack $count parcel(s): ${shortages.join(', ')}.',
      );
    }

    // 4. Create the parcel documents.
    final now = DateTime.now();
    final batch = _db.batch();
    final col = _parcelsCol(centerId);
    for (var i = 0; i < count; i++) {
      final docRef = col.doc();
      final parcel = PackedParcelModel(
        parcelId: docRef.id,
        centerId: centerId,
        status: ParcelStatus.available,
        packedAt: now,
        updatedAt: now,
      );
      batch.set(docRef, parcel.toMap());
    }
    // Mirror the new available count onto the center doc in the same batch
    // as the parcel docs themselves, so the two can never observably drift
    // (a screen reading the center doc right after this commits will never
    // see the old availableParcels alongside the new parcel docs, or vice
    // versa).
    batch.update(_centerDoc(centerId), {
      'availableParcels': FieldValue.increment(count),
    });
    await batch.commit();

    // 5. Deduct the consumed stock, one item at a time via
    //    FirebaseInventoryService (also recalculates the bottleneck flag).
    final performedByUid =
        fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    for (final item in blueprint.items) {
      final doc = inventoryByName[item.itemName];
      if (doc == null) continue; // shouldn't happen, already checked above
      await _inventoryService.deductStock(
        centerId: centerId,
        itemId: doc.id,
        amount: item.quantityPerParcel * count,
        performedByUid: performedByUid,
      );
    }
  }

  @override
  Future<List<String>> reserveParcels({
    required String centerId,
    required String requestId,
    required String victimUid,
    required String volunteerUid,
    required int count,
  }) async {
    final col = _parcelsCol(centerId);

    // Query candidates OUTSIDE the transaction — the Flutter cloud_firestore
    // client SDK's Transaction.get() only accepts DocumentReferences, not
    // arbitrary queries, so we can't discover *which* docs to reserve from
    // inside the transaction itself. A small buffer (+5) beyond `count`
    // gives the transaction some slack if a couple of these get reserved by
    // someone else between this query and the transaction committing.
    final candidatesSnap = await col
        .where('status', isEqualTo: ParcelStatus.available.name)
        .limit(count + 5)
        .get();

    if (candidatesSnap.docs.length < count) {
      throw NotEnoughParcelsException(
        'Not enough parcels. Required: $count, '
        'Available: ${candidatesSnap.docs.length}',
      );
    }

    final candidateRefs = candidatesSnap.docs.map((d) => d.reference).toList();
    final now = DateTime.now();

    // The actual atomicity guarantee comes from here: every doc read below
    // is re-checked fresh inside the transaction, and the reservation
    // writes only commit if none of the read docs changed in between. If
    // another transaction reserves one of the same candidates first,
    // Firestore detects the conflict at commit time and automatically
    // re-runs this whole function against fresh data (default up to 5
    // retries) — so two volunteers racing for overlapping parcels can
    // never both end up with the same parcelId.
    return _db.runTransaction<List<String>>((transaction) async {
      final stillAvailable = <DocumentReference<Map<String, dynamic>>>[];
      for (final ref in candidateRefs) {
        if (stillAvailable.length == count) break;
        final doc = await transaction.get(ref);
        if (!doc.exists) continue;
        if (doc.data()?['status'] == ParcelStatus.available.name) {
          stillAvailable.add(ref);
        }
      }

      if (stillAvailable.length < count) {
        throw NotEnoughParcelsException(
          'Not enough parcels. Required: $count, '
          'Available: ${stillAvailable.length}',
        );
      }

      final ids = <String>[];
      for (final ref in stillAvailable) {
        transaction.update(ref, {
          'status': ParcelStatus.reserved.name,
          'reservedForRequestId': requestId,
          'reservedForVictimUid': victimUid,
          'reservedByVolunteerUid': volunteerUid,
          'updatedAt': now.toIso8601String(),
        });
        ids.add(ref.id);
      }
      // Same-transaction write, so a reader can never see the parcel docs
      // flip to `reserved` without the center's cached availableParcels
      // reflecting that in the same instant.
      transaction.update(_centerDoc(centerId), {
        'availableParcels': FieldValue.increment(-ids.length),
      });
      return ids;
    });
  }

  @override
  Future<void> updateParcelStatus(
    String centerId,
    String parcelId,
    ParcelStatus status,
  ) async {
    await _parcelsCol(centerId).doc(parcelId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> returnParcels(String centerId, List<String> parcelIds) async {
    if (parcelIds.isEmpty) return;
    final batch = _db.batch();
    final now = DateTime.now();
    final col = _parcelsCol(centerId);
    for (final id in parcelIds) {
      // Matches MockParcelService.returnParcels exactly: only status and
      // updatedAt change. reservedForRequestId/reservedForVictimUid/
      // reservedByVolunteerUid are deliberately left as-is (mock's
      // copyWith falls back to the existing value for anything not
      // passed) rather than cleared. [Speculation] That means a
      // returned-to-available parcel still carries stale reservation
      // metadata from its last assignment — harmless today since nothing
      // reads those fields once status is back to available, but worth
      // knowing if a future screen ever displays "reserved for" info
      // without also checking status first.
      batch.update(col.doc(id), {
        'status': ParcelStatus.available.name,
        'updatedAt': now.toIso8601String(),
      });
    }
    // These parcels are available again — same batch, so the center doc's
    // availableParcels can't ever be caught out of sync with the docs
    // that back it.
    batch.update(_centerDoc(centerId), {
      'availableParcels': FieldValue.increment(parcelIds.length),
    });
    await batch.commit();
  }
}
