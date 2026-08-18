import 'dart:async';
import '../../core/enums/user_role.dart';
import '../../core/errors/app_exception.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';
import '../firestore/user_service.dart';

/// Mock implementation of [AuthService].
///
/// Test phone numbers (OTP always `123456`):
/// - `+94710000001` → Victim (existing user)
/// - `+94710000002` → Volunteer approved (existing user)
/// - `+94710000003` → Admin (existing user)
/// - `+94710000004` → Volunteer pending (existing user)
/// - Any other number → New user (will prompt role selection)
class MockAuthService implements AuthService {
  static const _validOtp = '123456';
  static const _delay = Duration(milliseconds: 800);

  // Previously verifyOtp() and getCurrentUser() both checked the phone/uid
  // against `mockUsers` — the static, never-mutated seed list from
  // mock_data.dart. But a newly-registered account (created via
  // AuthProvider.setRole() → UserService.createUser()) is only ever added
  // to MockUserService's own internal _users list, a separate copy made
  // with `List.from(mockUsers)`. Mutating that copy never touches the
  // original `mockUsers` list. So a phone number that signed up during the
  // current session could never be found here, even without an app
  // restart — signing out and back in with that number would always look
  // like a brand-new user and get sent back to Role Select. [Verified from
  // code, reproduced by tracing the exact two call sites against each
  // other] Injecting UserService and querying through it means both
  // services now share one real source of truth.
  final UserService _userService;

  MockAuthService(this._userService);

  String? _pendingPhone;
  String? _currentUid;

  @override
  String? get currentUid => _currentUid;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    await Future.delayed(_delay);
    _pendingPhone = phoneNumber;
    // In the real service: FirebaseAuth.verifyPhoneNumber()
  }

  @override
  Future<bool> verifyOtp(String smsCode) async {
    await Future.delayed(_delay);
    if (smsCode != _validOtp) {
      throw const AuthException('Invalid OTP code. Please try again.');
    }

    final existingUser = await _userService.findUserByPhone(_pendingPhone!);

    if (existingUser != null) {
      _currentUid = existingUser.uid;
      return false; // returning user — go to role home
    } else {
      _currentUid = 'uid_new_${DateTime.now().millisecondsSinceEpoch}';
      return true; // new user — go to role select
    }
  }

  @override
  Future<void> setRole(UserRole role, {String? nicNumber}) async {
    await Future.delayed(_delay);
    if (_currentUid == null) throw const AuthException('Not authenticated.');
    // In the real service: write to Firestore users/{uid}
    // For mock: the user will be discoverable via MockUserService.getUser()
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUid = null;
    _pendingPhone = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentUid == null) return null;
    return _userService.getUser(_currentUid!);
  }
}