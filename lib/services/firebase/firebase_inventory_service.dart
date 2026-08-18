// lib/services/firebase/firebase_inventory_service.dart
//
// Phase 2 implementation of InventoryService, backed by Firestore's
// `centers/{centerId}/inventory_items` sub-collection
// (FirestorePaths.inventoryItems(centerId)).
//
// Drop-in replacement for MockInventoryService: InventoryProvider only
// depends on the abstract InventoryService interface, so no
// provider/screen changes are needed beyond wiring this into main.dart.
//
// Because inventory items live in a sub-collection scoped to one center's
// document, there's no need for MockInventoryService's manual
// `.where((i) => i.centerId == centerId)` filtering — the collection
// reference itself is already scoped, so every query here is a plain,
// unfiltered read/listen on that sub-collection.
//
// [Unverified] Checked by hand against current cloud_firestore usage and
// against MockInventoryService's exact behavior — not run against a live
// Firestore instance from here.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/utils/bottleneck_calculator.dart';
import '../../models/inventory_item_model.dart';
import '../../models/parcel_blueprint_model.dart';
import '../firestore/inventory_service.dart';

class FirebaseInventoryService implements InventoryService {
  final FirebaseFirestore _db;
  FirebaseInventoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _itemsCol(String centerId) =>
      _db.collection(FirestorePaths.inventoryItems(centerId));

  String _slug(String itemName) => itemName.toLowerCase().replaceAll(' ', '_');

  @override
  Future<List<InventoryItemModel>> getInventory(String centerId) async {
    await _lazySeedCenter(centerId);
    final snap = await _itemsCol(centerId).get();
    return snap.docs
        .map((d) => InventoryItemModel.fromMap(d.data(), id: d.id))
        .toList();
  }

  @override
  Stream<List<InventoryItemModel>> inventoryStream(String centerId) {
    // Fire-and-forget, mirroring MockInventoryService's non-blocking
    // Future.microtask lazy seed. Unlike the mock we don't need a manual
    // _emit() afterward — Firestore's snapshots() automatically re-emits
    // once the seed batch below commits.
    _lazySeedCenter(centerId);
    return _itemsCol(centerId).snapshots().map(
          (snap) => snap.docs
              .map((d) => InventoryItemModel.fromMap(d.data(), id: d.id))
              .toList(),
        );
  }

  /// Auto-seeds 5 blueprint items at zero stock for a center whose
  /// sub-collection is still empty. Same purpose as
  /// MockInventoryService._lazySeedCenter: pre-seeded mock centers (or any
  /// center registered before a real blueprint existed) stay usable
  /// without a separate "initialize this center" step.
  Future<void> _lazySeedCenter(String centerId) async {
    final col = _itemsCol(centerId);
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final blueprint = ParcelBlueprintModel.defaultBlueprint;
    final now = DateTime.now();
    final batch = _db.batch();
    for (final item in blueprint.items) {
      final itemId = '${centerId}_${_slug(item.itemName)}';
      final model = InventoryItemModel(
        itemId: itemId,
        centerId: centerId,
        itemName: item.itemName,
        unit: item.unit,
        currentStock: 0,
        quantityPerParcel: item.quantityPerParcel,
        kitPotential: 0,
        isBottleneck: false,
        lastUpdatedAt: now,
      );
      batch.set(col.doc(itemId), model.toMap());
    }
    await batch.commit();
  }

  @override
  Future<void> addStock({
    required String centerId,
    required String itemId,
    required double amount,
    required String performedByUid,
  }) async {
    await _mutateStock(
      centerId: centerId,
      itemId: itemId,
      delta: amount,
      action: 'add',
      performedByUid: performedByUid,
    );
  }

  @override
  Future<void> deductStock({
    required String centerId,
    required String itemId,
    required double amount,
    required String performedByUid,
  }) async {
    await _mutateStock(
      centerId: centerId,
      itemId: itemId,
      delta: -amount,
      action: 'deduct',
      performedByUid: performedByUid,
      clampAtZero: true,
    );
  }

  /// Shared add/deduct logic. [Unverified/Speculation] This is a
  /// read-modify-write, not a transaction — under concurrent addStock/
  /// deductStock calls on the *same* item there's a lost-update race on
  /// currentStock, same risk class MockCenterService used to have for
  /// subCoordinatorUids before that was moved to arrayUnion. Two volunteers
  /// rarely stock the same center's same item at the exact same instant in
  /// this app's real usage, so this matches the project's scope — wrap the
  /// read+update in a Firestore transaction (`_db.runTransaction`) later if
  /// that becomes a real concern.
  Future<void> _mutateStock({
    required String centerId,
    required String itemId,
    required double delta,
    required String action,
    required String performedByUid,
    bool clampAtZero = false,
  }) async {
    final docRef = _itemsCol(centerId).doc(itemId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final item = InventoryItemModel.fromMap(doc.data()!, id: doc.id);
    var newStock = item.currentStock + delta;
    if (clampAtZero && newStock < 0) newStock = 0;
    final newKit = item.quantityPerParcel > 0
        ? (newStock / item.quantityPerParcel).floor()
        : 0;
    final now = DateTime.now();

    await docRef.update({
      'currentStock': newStock,
      'kitPotential': newKit,
      'lastUpdatedAt': now.toIso8601String(),
      // arrayUnion appends atomically — safe even though currentStock
      // above isn't, since it's a separate, order-independent operation.
      'activityLog': FieldValue.arrayUnion([
        StockActivity(
          action: action,
          amount: delta.abs(),
          performedByUid: performedByUid,
          timestamp: now,
        ).toMap(),
      ]),
    });

    await _recalculateBottleneck(centerId);
  }

  @override
  Future<void> initializeInventory(
      String centerId, ParcelBlueprintModel blueprint) async {
    final col = _itemsCol(centerId);
    final existing = await col.get();
    final batch = _db.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    final now = DateTime.now();
    for (final blueprintItem in blueprint.items) {
      final itemId = '${centerId}_${_slug(blueprintItem.itemName)}';
      final model = InventoryItemModel(
        itemId: itemId,
        centerId: centerId,
        itemName: blueprintItem.itemName,
        unit: blueprintItem.unit,
        currentStock: 0,
        quantityPerParcel: blueprintItem.quantityPerParcel,
        kitPotential: 0,
        isBottleneck: false,
        lastUpdatedAt: now,
      );
      batch.set(col.doc(itemId), model.toMap());
    }
    await batch.commit();

    // [Fix] Every item is reset to zero stock above, so the center's
    // cached packingCapacity/bottleneckItem are now stale (still
    // showing whatever the count was under the old blueprint) until the
    // next addStock/deductStock call happens to touch this center. Same
    // class of bug as _mutateStock previously not writing back to the
    // center doc — recalculate right away instead of waiting on that.
    await _recalculateBottleneck(centerId);
  }

  /// The item with the lowest kitPotential is the bottleneck — reuses the
  /// shared BottleneckCalculator utility instead of MockInventoryService's
  /// inline min-finding loop, so this logic stays in exactly one place.
  ///
  /// [Fix] Previously this only updated each inventory_items doc's
  /// isBottleneck flag and stopped there — it never wrote the summary back
  /// onto the parent centers/{centerId} doc's packingCapacity /
  /// bottleneckItem fields. Those are the fields DonationCenterModel (and
  /// every screen that reads it — MyCentersScreen's center cards,
  /// AcceptTaskScreen, GlobalInventoryScreen, the public map markers) is
  /// actually built from, so a volunteer's "My Centers" card stayed frozen
  /// at whatever value the center had at registration (0), no matter how
  /// much stock was added or how many parcels got packed. This is the
  /// fix: after recalculating, also push packingCapacity and
  /// bottleneckItem onto the center doc so every screen reading
  /// DonationCenterModel picks up the live number.
  ///
  /// [Fix — architectural] This field used to be named `maxParcelsAvailable`
  /// and every screen treated it as "parcels ready to collect," which was
  /// wrong — it's raw-stock kit *potential*, not an actual packed-parcel
  /// count. Renamed to packingCapacity to match what it actually is.
  /// `availableParcels` — the real "ready right now" number — is a
  /// completely separate field that only [FirebaseParcelService] writes,
  /// mirroring the live `packed_parcels` sub-collection. This method has
  /// nothing to do with that field and must not touch it.
  ///
  /// [Inferred] bottleneckItem going null at maxParcels >= 10 (rather than
  /// always naming the lowest-stock item) isn't spelled out anywhere in
  /// the interface doc comments, but matches the one concrete reference
  /// available — every center in mock_data.dart with packingCapacity
  /// >= 10 has bottleneckItem: null, every one below 10 names an item —
  /// and lines up with the >=10 "well stocked" threshold this app already
  /// uses everywhere else (center_marker.dart's hue cutoff, this card's
  /// own color logic). Flag it if the real rule should be different —
  /// e.g. always naming the lowest item regardless of how high maxParcels
  /// is.
  Future<void> _recalculateBottleneck(String centerId) async {
    final col = _itemsCol(centerId);
    final snap = await col.get();
    final items = snap.docs
        .map((d) => InventoryItemModel.fromMap(d.data(), id: d.id))
        .toList();
    if (items.isEmpty) return;

    final result = BottleneckCalculator.calculate(
      items.map((i) => i.toInventoryInput()).toList(),
    );

    // BottleneckCalculator.calculate only names a single winning item, but
    // MockInventoryService marks every item tied at the lowest kitPotential
    // as a bottleneck (`isBottleneck: kitPotential == min`). Compute the
    // min directly from the calculator's own kitPotentials list so ties
    // are preserved exactly like the mock, rather than only flagging
    // whichever one item the calculator happened to name.
    final minKit = result.kitPotentials.map((k) => k.kitPotential).reduce(
          (a, b) => a < b ? a : b,
        );

    final batch = _db.batch();
    var wroteAny = false;
    for (final item in items) {
      final shouldBeBottleneck = item.kitPotential == minKit;
      if (item.isBottleneck != shouldBeBottleneck) {
        batch.update(col.doc(item.itemId), {'isBottleneck': shouldBeBottleneck});
        wroteAny = true;
      }
    }
    if (wroteAny) await batch.commit();

    final bottleneckName = result.maxParcels >= 10 || result.bottleneckItem.isEmpty
        ? null
        : result.bottleneckItem;

    await _db.collection(FirestorePaths.centers).doc(centerId).update({
      'packingCapacity': result.maxParcels,
      'bottleneckItem': bottleneckName,
    });
  }
}