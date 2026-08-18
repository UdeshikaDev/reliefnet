// lib/providers/user_provider.dart
// Module 5: loadUser, updateDisplayName, fetchUserById, findVolunteerByPhone.
// Module 8: loadPendingVolunteers, approveVolunteer, rejectVolunteer (admin queue).
// Phase 2 swap: replace MockUserService with FirebaseUserService in main.dart.

import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/user_model.dart';
import '../services/firestore/user_service.dart';

/// Manages the current user's profile and the admin volunteer approval queue.
///
/// **Module 5 methods:**
/// - [loadUser]             — loads own profile after login
/// - [fetchUserById]        — resolves any UID → [UserModel] (sub-coordinator lookup)
/// - [findVolunteerByPhone] — phone-based volunteer search (sub-coordinator add)
///
/// **Module 8 additions (admin panel):**
/// - [loadPendingVolunteers] — loads volunteer approval queue
/// - [approveVolunteer]      — sets isVerified = true
/// - [rejectVolunteer]       — deletes volunteer account
///
/// **Phase 2 swap:** Replace `MockUserService` → `FirebaseUserService` in `main.dart`.
/// Zero changes here.
class UserProvider extends ChangeNotifier {
  final UserService _userService;
  UserProvider(this._userService);

  // ── State ─────────────────────────────────────────────────────────────────
  UserModel? _user;
  List<UserModel> _pendingVolunteers = [];
  bool _isLoading = false;
  bool _isApprovingRejecting = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  UserModel? get user => _user;
  List<UserModel> get pendingVolunteers => _pendingVolunteers;

  /// Number of pending volunteers — shown as badge on AdminHomeScreen.
  int get pendingCount => _pendingVolunteers.length;

  bool get isLoading => _isLoading;
  bool get isApprovingRejecting => _isApprovingRejecting;
  String? get error => _error;

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _userService.getUser(uid);
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load user profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String uid, String name) async {
    try {
      await _userService.updateUser(uid, {'displayName': name});
      if (_user?.uid == uid) {
        _user = _user?.copyWith(displayName: name);
        notifyListeners();
      }
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  /// Resolves any UID → [UserModel] without modifying [user] state.
  /// Used by ManageSubCoordinatorsScreen to display sub-coordinator names.
  Future<UserModel?> fetchUserById(String uid) =>
      _userService.getUserById(uid);

  /// Finds an approved volunteer by phone number.
  /// Returns `null` if no match found.
  Future<UserModel?> findVolunteerByPhone(String phone) =>
      _userService.findVolunteerByPhone(phone);

  // ── Admin: Volunteer queue (Module 8) ─────────────────────────────────────

  /// Loads all pending (unverified) volunteer accounts.
  /// Called from [AdminHomeScreen] initState and [VolunteerQueueScreen] initState.
  Future<void> loadPendingVolunteers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _pendingVolunteers = await _userService.getPendingVolunteers();
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load pending volunteers.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approves a pending volunteer. Returns `true` on success.
  ///
  /// Side-effects:
  ///   1. Sets `isVerified = true` in the service.
  ///   2. Removes the volunteer from [_pendingVolunteers] immediately.
  ///
  /// Phase 2: Cloud Function sends FCM "Your account is verified".
  Future<bool> approveVolunteer(String uid) async {
    _isApprovingRejecting = true;
    _error = null;
    notifyListeners();
    try {
      await _userService.approveVolunteer(uid);
      _pendingVolunteers.removeWhere((u) => u.uid == uid);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not approve volunteer. Please try again.';
      return false;
    } finally {
      _isApprovingRejecting = false;
      notifyListeners();
    }
  }

  /// Rejects and permanently removes a pending volunteer. Returns `true` on success.
  ///
  /// Side-effects:
  ///   1. Deletes the volunteer document via the service.
  ///   2. Removes the volunteer from [_pendingVolunteers] immediately.
  ///
  /// Phase 2: Cloud Function sends FCM "Account rejected" and deletes Auth account.
  Future<bool> rejectVolunteer(String uid) async {
    _isApprovingRejecting = true;
    _error = null;
    notifyListeners();
    try {
      await _userService.rejectVolunteer(uid);
      _pendingVolunteers.removeWhere((u) => u.uid == uid);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not reject volunteer. Please try again.';
      return false;
    } finally {
      _isApprovingRejecting = false;
      notifyListeners();
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void clear() {
    _user = null;
    _pendingVolunteers = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}