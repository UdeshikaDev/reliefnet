// lib/services/mock/mock_parcel_service.dart
// Phase 2 swap: replace MockParcelService with FirebaseParcelService in main.dart.

import 'dart:async';

import '../../core/enums/parcel_status.dart';
import '../../core/errors/app_exception.dart';
import '../../models/packed_parcel_model.dart';
import '../firestore/center_service.dart';
import '../firestore/parcel_service.dart';
import 'mock_data.dart';

/// In-memory implementation of [ParcelService].
///
/// Seeds realistic packed parcel data for a few centers on construction.
/// All mutating operations (reserve, pack, return) update the in-memory store
/// and re-emit via [parcelsStream] so [PackedParcelsProvider] stays live.
///
/// **Phase 2 swap:** Replace with FirebaseParcelService in main.dart.
///
/// [Fix — architectural] Also mirrors [DonationCenterModel.availableParcels]
/// onto [_centerService] after every pack/reserve/return, matching what
/// FirebaseParcelService does with a same-batch/same-transaction Firestore
/// write. Mock mode has no transactions, but it's single-threaded (no real
/// concurrent writers), so a plain read-then-write via
/// [CenterService.updateCenter] is enough to keep the two in sync — see
/// [_adjustAvailableParcels].
class MockParcelService implements ParcelService {
  final CenterService _centerService;

  // centerId → list of all packed parcels for that center
  final Map<String, List<PackedParcelModel>> _store = {};

  // centerId → broadcast stream controller
  final Map<String, StreamController<List<PackedParcelModel>>> _controllers =
      {};

  MockParcelService(this._centerService) {
    _seed();
  }

  // ── Seeding ──────────────────────────────────────────────────────────────
  //
  // This used to seed three centers under the ids 'center_001'/'002'/'003',
  // none of which exist in MockCenterService (real centers are 'c1'..'c14',
  // sourced from mock_data.dart). Reserving/packing against a real center
  // still worked because of the _lazySeedCenter fallback below, but it meant
  // this hand-built, more-realistic demo distribution (20 available / 5
  // reserved / 2 in transit / 47 distributed) was never actually reachable
  // through the app's real navigation, and its "reserved" entries pointed at
  // requestId/victimUid values that don't exist in mock_data.dart either.
  //
  // Now: parcel_001..parcel_005 come straight from mock_data.dart's
  // mockParcels (already correctly linked to request1/task1 and
  // request3/task2), grouped under their real centerId. c1 is then topped
  // up with extra bulk stock so pack/dispatch/accept-task flows have plenty
  // to work with; c2/c3 get a smaller top-up so their screens aren't empty.

  void _seed() {
    final now = DateTime.now();

    for (final parcel in mockParcels) {
      _store.putIfAbsent(parcel.centerId, () => []).add(parcel);
    }

    // Top up center1 (Kurunegala Relief Hub) with extra bulk stock.
    _store.putIfAbsent(MockUids.center1, () => []).addAll([
      ..._generate(
        centerId: MockUids.center1,
        prefix: 'c1_av',
        count: 15,
        status: ParcelStatus.available,
        packedAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now,
      ),
      ..._generate(
        centerId: MockUids.center1,
        prefix: 'c1_dt',
        count: 10,
        status: ParcelStatus.distributed,
        packedAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // Light stock for center2 (Maho) and center3 (Nikaweratiya).
    _store.putIfAbsent(MockUids.center2, () => []).addAll(
      _generate(
        centerId: MockUids.center2,
        prefix: 'c2_av',
        count: 8,
        status: ParcelStatus.available,
        packedAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now,
      ),
    );
    _store.putIfAbsent(MockUids.center3, () => []).addAll(
      _generate(
        centerId: MockUids.center3,
        prefix: 'c3_dt',
        count: 5,
        status: ParcelStatus.distributed,
        packedAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    );
  }

  List<PackedParcelModel> _generate({
    required String centerId,
    required String prefix,
    required int count,
    required ParcelStatus status,
    required DateTime packedAt,
    required DateTime updatedAt,
  }) {
    return List.generate(
      count,
      (i) => PackedParcelModel(
        parcelId: '${prefix}_${i + 1}',
        centerId: centerId,
        status: status,
        packedAt: packedAt,
        updatedAt: updatedAt,
      ),
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  List<PackedParcelModel> _getParcels(String centerId) {
    _lazySeedCenter(centerId); // auto-seed on first access
    return _store[centerId]!;
  }

  /// Seeds 20 available parcels for any centerId not already in the store
  /// (e.g. c4..c14, which don't get hand-built demo data above). Ensures
  /// AcceptTaskScreen can always reserve parcels for any real center.
  void _lazySeedCenter(String centerId) {
    if (_store.containsKey(centerId)) return; // already seeded, skip
    final now = DateTime.now();
    _store[centerId] = List.generate(
      20,
      (i) => PackedParcelModel(
        parcelId: '${centerId}_auto_${i + 1}',
        centerId: centerId,
        status: ParcelStatus.available,
        packedAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now,
      ),
    );
  }

  StreamController<List<PackedParcelModel>> _controllerFor(String centerId) {
    return _controllers.putIfAbsent(
      centerId,
      () => StreamController<List<PackedParcelModel>>.broadcast(),
    );
  }

  void _emit(String centerId) {
    final ctrl = _controllerFor(centerId);
    if (!ctrl.isClosed) ctrl.add(_getParcels(centerId));
  }

  /// Mirrors a change of [delta] available parcels onto the center's
  /// [DonationCenterModel.availableParcels] field via [CenterService].
  /// Called after every operation below that actually changes how many
  /// [ParcelStatus.available] docs exist for a center (pack: +count,
  /// reserve: -reserved.length, return: +returned.length) — mirroring
  /// exactly what FirebaseParcelService keeps in sync via the same batch/
  /// transaction as the parcel writes.
  ///
  /// Deliberately NOT called from [_lazySeedCenter]: that path is demo
  /// convenience for centers with no hand-built seed data (see its own doc
  /// comment), not a real pack/reserve/return event, so it doesn't touch
  /// the center doc — same as it never touched inventory stock either.
  Future<void> _adjustAvailableParcels(String centerId, int delta) async {
    if (delta == 0) return;
    final center = await _centerService.getCenterById(centerId);
    if (center == null) return;
    final next = center.availableParcels + delta;
    await _centerService.updateCenter(
      centerId,
      {'availableParcels': next < 0 ? 0 : next},
    );
  }

  // ── ParcelService interface ───────────────────────────────────────────────

  @override
  Stream<List<PackedParcelModel>> parcelsStream(String centerId) {
    final ctrl = _controllerFor(centerId);
    // Emit the current state immediately for new subscribers.
    Future.microtask(() {
      if (!ctrl.isClosed) ctrl.add(_getParcels(centerId));
    });
    return ctrl.stream;
  }

  @override
  Future<List<PackedParcelModel>> getAvailableParcels(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _getParcels(
      centerId,
    ).where((p) => p.status == ParcelStatus.available).toList();
  }

  @override
  Future<void> packParcels(String centerId, int count) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    final list = _store.putIfAbsent(centerId, () => []);
    for (int i = 0; i < count; i++) {
      list.add(
        PackedParcelModel(
          parcelId: 'p_new_${centerId}_${now.microsecondsSinceEpoch}_$i',
          centerId: centerId,
          status: ParcelStatus.available,
          packedAt: now,
          updatedAt: now,
        ),
      );
    }
    _emit(centerId);
    await _adjustAvailableParcels(centerId, count);
  }

  @override
  Future<List<String>> reserveParcels({
    required String centerId,
    required String requestId,
    required String victimUid,
    required String volunteerUid,
    required int count,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final available = _getParcels(
      centerId,
    ).where((p) => p.status == ParcelStatus.available).take(count).toList();

    if (available.length < count) {
      throw NotEnoughParcelsException(
        'Not enough parcels. Required: $count, '
        'Available: ${available.length}',
      );
    }

    final now = DateTime.now();
    final reserved = <String>[];
    final all = _getParcels(centerId);

    for (final p in available) {
      final idx = all.indexWhere((x) => x.parcelId == p.parcelId);
      if (idx != -1) {
        all[idx] = p.copyWith(
          status: ParcelStatus.reserved,
          reservedForRequestId: requestId,
          reservedForVictimUid: victimUid,
          reservedByVolunteerUid: volunteerUid,
          updatedAt: now,
        );
        reserved.add(p.parcelId);
      }
    }

    _emit(centerId);
    await _adjustAvailableParcels(centerId, -reserved.length);
    return reserved;
  }

  @override
  Future<void> updateParcelStatus(
    String centerId,
    String parcelId,
    ParcelStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final all = _getParcels(centerId);
    final idx = all.indexWhere((p) => p.parcelId == parcelId);
    if (idx != -1) {
      all[idx] = all[idx].copyWith(status: status, updatedAt: DateTime.now());
      _emit(centerId);
    }
  }

  @override
  Future<void> returnParcels(String centerId, List<String> parcelIds) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final all = _getParcels(centerId);
    final now = DateTime.now();
    var returnedCount = 0;
    for (final id in parcelIds) {
      final idx = all.indexWhere((p) => p.parcelId == id);
      if (idx != -1) {
        all[idx] = all[idx].copyWith(
          status: ParcelStatus.available,
          updatedAt: now,
        );
        returnedCount++;
      }
    }
    _emit(centerId);
    await _adjustAvailableParcels(centerId, returnedCount);
  }
}
