import 'package:flutter/foundation.dart';

import '../core/enums/gender.dart';
import '../core/enums/user_role.dart';
import '../core/errors/app_exception.dart';
import '../models/user_model.dart';
import '../services/auth/auth_service.dart';
import '../services/firestore/user_service.dart';

/// Manages the entire phone OTP authentication flow.
///
/// **New user flow (3 steps):**
/// 1. [sendOtp] → sends SMS
/// 2. [verifyOtp] → validates code; [isNewUser] = true → screen pushes to Role Select
/// 3. [setRole] → creates Firestore profile; GoRouter redirect fires to home
///
/// **Returning user flow (2 steps):**
/// 1. [sendOtp]
/// 2. [verifyOtp] → loads existing [UserModel]; GoRouter redirect fires to home
///
/// **On app start:** [SplashScreen] calls [tryAutoLogin].
///
/// **Phase 2 swap:** In `main.dart`, replace `MockAuthService` → `FirebaseAuthService`
/// and `MockUserService` → `FirebaseUserService`. Zero other file changes.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  AuthProvider(this._authService, this._userService);

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;
  UserModel? _currentUser;
  bool _otpSent = false;
  bool _isNewUser = false;
  String _pendingPhone = '';

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get currentUser => _currentUser;
  bool get otpSent => _otpSent;
  bool get isNewUser => _isNewUser;

  /// GoRouter uses this to evaluate the redirect guard.
  bool get isAuthenticated => _currentUser != null;

  // ── Auto-login ─────────────────────────────────────────────────────────────

  /// Called by [SplashScreen]. Restores a persisted session if one exists.
  /// Phase 1 (mock): always returns null → user must sign in fresh each run.
  /// Phase 2 (Firebase): checks `FirebaseAuth.currentUser`.
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.getCurrentUser();
      _currentUser = user;
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Step 1: Send OTP ───────────────────────────────────────────────────────

  /// Sends an OTP SMS. [phoneNumber] must be `+94XXXXXXXXX` format.
  /// Sets [otpSent] = true on success. Screen then pushes to [OtpVerifyScreen].
  Future<void> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.sendOtp(phoneNumber);
      _pendingPhone = phoneNumber;
      _otpSent = true;
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not send OTP. Check your number and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────────────────────

  /// Returns `true` if code accepted (navigate next), `false` if wrong code.
  ///
  /// After `true`:
  /// - [isNewUser] == true → screen pushes to [RouteNames.roleSelect]
  /// - [isNewUser] == false → GoRouter redirect fires automatically
  Future<bool> verifyOtp(String smsCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final isNew = await _authService.verifyOtp(smsCode);
      _isNewUser = isNew;
      if (!isNew) {
        // Returning user — load existing profile so GoRouter redirect can fire.
        final uid = _authService.currentUid!;
        _currentUser = await _userService.getUser(uid);
      }
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Invalid code. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Step 3: Set Role (new users only) ──────────────────────────────────────

  /// Creates the user profile. Returns `true` on success.
  /// GoRouter redirect fires automatically after [currentUser] is set.
  /// [displayName], [gender], and [dateOfBirth] are collected on
  /// RoleSelectScreen for victims only (per the current UI) — all three are
  /// optional here so this doesn't break the volunteer signup path, which
  /// does not collect them.
  /// [displayName], [gender], [dateOfBirth], [nicNumber] and [address] are
  /// now collected on RoleSelectScreen for both victims and volunteers (all
  /// optional here so this doesn't break either path if a caller omits
  /// some of them).
  Future<bool> setRole(
    UserRole role, {
    String? nicNumber,
    String? displayName,
    Gender? gender,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.setRole(role, nicNumber: nicNumber);
      final uid = _authService.currentUid!;
      final now = DateTime.now();
      final newUser = UserModel(
        uid: uid,
        phone: _pendingPhone,
        role: role,
        isVerified: role != UserRole.volunteer, // volunteers start pending
        nicNumber: nicNumber,
        displayName: displayName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
        hasActiveRequest: false,
        createdAt: now,
        updatedAt: now,
      );
      await _userService.createUser(newUser);
      _currentUser = newUser;
      _isNewUser = false;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not save your role. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  /// Signs out and resets all state. GoRouter redirect sends user to phone entry.
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (_) {
      // Reset state regardless of error.
    } finally {
      _currentUser = null;
      _otpSent = false;
      _isNewUser = false;
      _pendingPhone = '';
      _error = null;
      notifyListeners();
    }
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void resetOtpState() {
    _otpSent = false;
    _error = null;
    notifyListeners();
  }
}