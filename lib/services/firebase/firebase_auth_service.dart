// lib/services/firebase/firebase_auth_service.dart
//
// Phase 2 implementation of AuthService — this is the class the interface's
// own doc comment already anticipated by name ("Phase 2:
// [FirebaseAuthService] implements this with FirebaseAuth"). Drop-in
// replacement for MockAuthService: nothing else in the app needs to change
// beyond main.dart's service instantiation, since AuthProvider only ever
// depends on the abstract AuthService interface.
//
// Calls two Cloud Functions (functions/index.js in this delivery):
//   sendOtp({phoneNumber})            → {success}
//   verifyOtp({phoneNumber, code})    → {token, uid, isNewUser}
// then signs in with the returned custom token.
//
// [Unverified] I have not run this against a real Firebase project or a
// deployed function — I don't have credentials to do that from here. The
// Cloud Functions side (functions/index.js) has been syntax-checked, had
// its dependencies actually installed, and successfully loaded as a real
// Node module against the current firebase-admin/firebase-functions
// packages — that's real verification, not a guess. This Flutter file is
// checked only by hand against the current FlutterFire docs (confirmed via
// web search this session, not training memory) for signInWithCustomToken
// and httpsCallable's exact usage.

import '../../core/enums/user_role.dart';
import '../../core/errors/app_exception.dart';
import '../../models/user_model.dart';
import '../auth/auth_service.dart';
import '../firestore/user_service.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class FirebaseAuthService implements AuthService {
  final UserService _userService;
  final fb_auth.FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  FirebaseAuthService(
    this._userService, {
    fb_auth.FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? fb_auth.FirebaseAuth.instance,
        // Adjust the region here if you deploy functions somewhere other
        // than the default (us-central1) — e.g.
        // FirebaseFunctions.instanceFor(region: 'asia-south1') is closer to
        // Sri Lanka if you want to reduce latency. [Speculation] I don't
        // know which region you'll deploy to, so this defaults to
        // whatever FirebaseFunctions.instance resolves to; change it here
        // in one place if needed.
        _functions = functions ?? FirebaseFunctions.instance;

  String? _pendingPhone;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    _pendingPhone = phoneNumber;
    try {
      final callable = _functions.httpsCallable('sendOtp');
      await callable.call({'phoneNumber': phoneNumber});
    } on FirebaseFunctionsException catch (e) {
      // HttpsError codes/messages set server-side (see functions/index.js)
      // surface here as e.message — passed straight through since they're
      // already written to be shown to the person (e.g. "Please wait 45s
      // before requesting another code.").
      throw AuthException(e.message ?? 'Could not send the verification code.');
    } catch (_) {
      throw const AuthException('Could not send the verification code. Check your connection and try again.');
    }
  }

  @override
  Future<bool> verifyOtp(String smsCode) async {
    if (_pendingPhone == null) {
      throw const AuthException('No phone number pending verification. Please start again.');
    }
    try {
      final callable = _functions.httpsCallable('verifyOtp');
      final result = await callable.call({
        'phoneNumber': _pendingPhone,
        'code': smsCode,
      });

      final token = result.data['token'] as String?;
      final isNewUser = result.data['isNewUser'] as bool? ?? false;
      if (token == null) {
        throw const AuthException('Verification failed. Please try again.');
      }

      await _auth.signInWithCustomToken(token);
      return isNewUser;
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(e.message ?? 'Invalid OTP code. Please try again.');
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> setRole(UserRole role, {String? nicNumber}) async {
    // No-op here, matching MockAuthService's own behaviour exactly — the
    // actual Firestore users/{uid} document is written by
    // AuthProvider.setRole() through UserService.createUser(), not through
    // this interface. AuthService's role here is authentication only.
    if (currentUid == null) {
      throw const AuthException('Not authenticated.');
    }
  }

  @override
  Future<void> signOut() async {
    _pendingPhone = null;
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final uid = currentUid;
    if (uid == null) return null;
    return _userService.getUser(uid);
  }
}
