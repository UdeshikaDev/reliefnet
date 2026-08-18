// lib/services/firestore/user_service.dart

import '../../models/user_model.dart';

abstract class UserService {
  Future<UserModel?> getUser(String uid);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(String uid, Map<String, dynamic> fields);
  Future<void> setFcmToken(String uid, String token);
  Future<List<UserModel>> getPendingVolunteers();
  Future<void> approveVolunteer(String uid);

  /// Rejects a volunteer request.
  Future<void> rejectVolunteer(String uid);

  /// Finds an approved volunteer by phone number. Returns null if not found.
  Future<UserModel?> findVolunteerByPhone(String phone);

  /// Finds any user, of any role, by phone number. Returns null if not
  /// found. Used by AuthService.verifyOtp to decide whether a phone number
  /// belongs to a returning user or a brand-new one.
  Future<UserModel?> findUserByPhone(String phone);

  /// Fetches any user by UID without affecting current-user state.
  /// Used to resolve sub-coordinator UIDs to display names.
  Future<UserModel?> getUserById(String uid);
}