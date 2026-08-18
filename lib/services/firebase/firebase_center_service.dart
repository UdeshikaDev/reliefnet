// lib/services/firebase/firebase_center_service.dart
//
// Phase 2 implementation of CenterService, backed by Firestore's `centers`
// collection.
//
// Built against services/firestore/center_service.dart's interface, which
// this delivery also fixed: it previously declared a different,
// unimplemented interface than the one MockCenterService/CentersProvider
// actually depended on (a second copy declared locally inside
// mock_center_service.dart). [Verified from code] Both files now share the
// one real interface.
//
// [Unverified] Checked by hand against current cloud_firestore usage
// patterns and against MockCenterService's exact behavior — not run
// against a live Firestore instance from here.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/donation_center_model.dart';
import '../firestore/center_service.dart';

class FirebaseCenterService implements CenterService {
  final FirebaseFirestore _db;
  FirebaseCenterService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _centers =>
      _db.collection('centers');

  @override
  Stream<List<DonationCenterModel>> activeCentersStream() {
    return _centers.where('isActive', isEqualTo: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => DonationCenterModel.fromMap(d.data(), id: d.id))
              .toList(),
        );
  }

  @override
  Future<DonationCenterModel?> getCenterById(String centerId) async {
    final doc = await _centers.doc(centerId).get();
    if (!doc.exists) return null;
    return DonationCenterModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<String> registerCenter({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required String mainCoordinatorUid,
  }) async {
    // Firestore's auto-generated doc ID rather than MockCenterService's
    // 'c${_centers.length + 1}_mock' scheme — that scheme was never safe
    // for concurrent registration from two different devices anyway (both
    // could compute the same next-index ID at once); Firestore's own ID
    // generation is collision-free by design, which matters now that this
    // genuinely runs across multiple devices.
    final docRef = _centers.doc();
    final center = DonationCenterModel(
      centerId: docRef.id,
      name: name,
      address: address,
      mainCoordinatorUid: mainCoordinatorUid,
      subCoordinatorUids: const [],
      lat: lat,
      lng: lng,
      isActive: true,
      packingCapacity: 0,
      availableParcels: 0,
      bottleneckItem: null,
      createdAt: DateTime.now(),
    );
    await docRef.set(center.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateCenter(String centerId, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    await _centers.doc(centerId).update(fields);
  }

  @override
  Future<void> addSubCoordinator(String centerId, String volunteerUid) async {
    // arrayUnion is atomic and a no-op if volunteerUid is already present —
    // strictly better than MockCenterService's read-modify-write, which
    // would have been a real race condition risk (two admins adding a
    // sub-coordinator to the same center at the same moment) now that this
    // runs across real, separate devices.
    await _centers.doc(centerId).update({
      'subCoordinatorUids': FieldValue.arrayUnion([volunteerUid]),
    });
  }

  @override
  Future<void> removeSubCoordinator(String centerId, String volunteerUid) async {
    await _centers.doc(centerId).update({
      'subCoordinatorUids': FieldValue.arrayRemove([volunteerUid]),
    });
  }
}
