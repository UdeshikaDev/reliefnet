// lib/services/mock/mock_user_service.dart

import '../../core/enums/user_role.dart';
import '../../models/user_model.dart';
import '../firestore/user_service.dart';
import 'mock_data.dart';

class MockUserService implements UserService {
  static const _delay = Duration(milliseconds: 500);
  final List<UserModel> _users = List.from(mockUsers);

  @override
  Future<void> rejectVolunteer(String uid) async {
    await Future.delayed(_delay);
    // Permanently removes the volunteer from the mock store.
    // Phase 2: Firestore deleteDoc + FCM "Account rejected" via Cloud Function.
    _users.removeWhere((u) => u.uid == uid);
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    await Future.delayed(_delay);
    try { return _users.firstWhere((u) => u.uid == uid); }
    catch (_) { return null; }
  }

  @override
  Future<UserModel?> getUserById(String uid) => getUser(uid);

  @override
  Future<void> createUser(UserModel user) async {
    await Future.delayed(_delay);
    _users.removeWhere((u) => u.uid == user.uid);
    _users.add(user);
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await Future.delayed(_delay);
    final idx = _users.indexWhere((u) => u.uid == uid);
    if (idx == -1) return;
    final e = _users[idx];
    _users[idx] = e.copyWith(
      isVerified: fields['isVerified'] as bool? ?? e.isVerified,
      fcmToken:   fields['fcmToken']   as String? ?? e.fcmToken,
      hasActiveRequest: fields['hasActiveRequest'] as bool? ?? e.hasActiveRequest,
      displayName: fields['displayName'] as String? ?? e.displayName,
    );
  }

  @override
  Future<void> setFcmToken(String uid, String token) async =>
      updateUser(uid, {'fcmToken': token});

  @override
  Future<List<UserModel>> getPendingVolunteers() async {
    await Future.delayed(_delay);
    return _users
        .where((u) => u.role == UserRole.volunteer && !u.isVerified)
        .toList();
  }

  @override
  Future<void> approveVolunteer(String uid) async =>
      updateUser(uid, {'isVerified': true});

  @override
  Future<UserModel?> findVolunteerByPhone(String phone) async {
    await Future.delayed(_delay);
    // Strip spaces and normalise.
    final q = phone.replaceAll(' ', '');
    try {
      return _users.firstWhere(
        (u) => u.phone == q && u.role == UserRole.volunteer && u.isVerified,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel?> findUserByPhone(String phone) async {
    await Future.delayed(_delay);
    final q = phone.replaceAll(' ', '');
    return _users.where((u) => u.phone == q).firstOrNull;
  }
}