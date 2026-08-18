import '../../core/enums/user_role.dart';
import '../../models/user_model.dart';

/// Abstract interface for phone OTP authentication operations.
/// Phase 1: [MockAuthService] implements this with in-memory state.
/// Phase 2: [FirebaseAuthService] implements this with FirebaseAuth.
abstract class AuthService {
  /// Sends a 6-digit OTP to [phoneNumber] (`+94XXXXXXXXX` format).
  Future<void> sendOtp(String phoneNumber);

  /// Verifies the OTP. Returns `true` if this is a brand-new user
  /// (no existing Firestore document), `false` if returning user.
  Future<bool> verifyOtp(String smsCode);

  /// Saves the user's chosen role after first-time OTP.
  Future<void> setRole(UserRole role, {String? nicNumber});

  /// Signs out the current user and clears all cached state.
  Future<void> signOut();

  /// Returns the currently authenticated user, or `null` if not signed in.
  Future<UserModel?> getCurrentUser();

  /// The UID of the currently authenticated user. `null` if not signed in.
  String? get currentUid;
}