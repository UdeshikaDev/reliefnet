// lib/services/firebase/firebase_user_service.dart
//
// Phase 2 implementation of UserService, backed by Firestore's `users`
// collection (document ID = the user's Firebase Auth uid).
//
// Added specifically because FirebaseAuthService alone doesn't make
// volunteer approval or precreated admin accounts work — both need profile
// data (role, isVerified) to be visible across devices, which
// MockUserService's in-memory-per-app-instance list can never provide.
// [Verified from code] confirmed by reading mock_user_service.dart directly
// — `final List<UserModel> _users = List.from(mockUsers)` is a plain Dart
// list, not shared storage.
//
// [Unverified] Checked by hand against current cloud_firestore usage
// patterns — I don't have a live Firestore instance to run this against
// from here.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/user_role.dart';
import '../../models/user_model.dart';
import '../firestore/user_service.dart';

class FirebaseUserService implements UserService {
  final FirebaseFirestore _db;
  FirebaseUserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<UserModel?> getUserById(String uid) => getUser(uid);

  @override
  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    await _users.doc(uid).update({
      ...fields,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> setFcmToken(String uid, String token) =>
      updateUser(uid, {'fcmToken': token});

  @override
  Future<List<UserModel>> getPendingVolunteers() async {
    final snap = await _users
        .where('role', isEqualTo: UserRole.volunteer.name)
        .where('isVerified', isEqualTo: false)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), id: d.id)).toList();
  }

  @override
  Future<void> approveVolunteer(String uid) =>
      updateUser(uid, {'isVerified': true});

  @override
  Future<void> rejectVolunteer(String uid) async {
    // Matches MockUserService's exact behaviour: deletes the profile
    // document entirely, matching "Permanently removes the volunteer from
    // the mock store" in that file. Note this only removes the Firestore
    // profile, not the underlying Firebase Auth record — deleting an Auth
    // user requires the Admin SDK (server-side), which this client-side
    // service doesn't have access to. If you want full cleanup, that needs
    // a Cloud Function (parallel to how sendOtp/verifyOtp are structured),
    // not a change here. [Speculation] I don't know if leaving the Auth
    // record behind matters for your use case — flagging it rather than
    // assuming either way.
    await _users.doc(uid).delete();
  }

  @override
  Future<UserModel?> findVolunteerByPhone(String phone) async {
    final q = phone.replaceAll(' ', '');
    final snap = await _users
        .where('phone', isEqualTo: q)
        .where('role', isEqualTo: UserRole.volunteer.name)
        .where('isVerified', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromMap(snap.docs.first.data(), id: snap.docs.first.id);
  }

  @override
  Future<UserModel?> findUserByPhone(String phone) async {
    final q = phone.replaceAll(' ', '');
    final snap = await _users.where('phone', isEqualTo: q).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromMap(snap.docs.first.data(), id: snap.docs.first.id);
  }
}
