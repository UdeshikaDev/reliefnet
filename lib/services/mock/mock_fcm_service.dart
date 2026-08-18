// lib/services/mock/mock_fcm_service.dart
//
// Phase 2 swap: replace MockFcmService with FirebaseFcmService in main.dart.

import '../fcm/fcm_service.dart';

/// Phase 1 no-op implementation of [FcmService].
///
/// - [getToken] returns a predictable mock string (sufficient for UI testing).
/// - [requestPermission] always returns `true`.
/// - [saveToken] does nothing (no Firestore in Phase 1).
///
/// **Phase 2 swap:** Replace with `FirebaseFcmService` in `main.dart`.
class MockFcmService implements FcmService {
  @override
  Future<String?> getToken() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Return a stable mock token so unit tests can assert it is non-null.
    return 'mock_fcm_token_phase1';
  }

  @override
  Future<bool> requestPermission() async {
    // Phase 1: assume permission is always granted.
    return true;
  }

  @override
  Future<void> saveToken(String uid) async {
    // Phase 1 no-op.
    // Phase 2: calls FirebaseUserService.setFcmToken(uid, token).
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    // Phase 1 no-op. Phase 2: FirebaseMessaging.instance.subscribeToTopic(topic).
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    // Phase 1 no-op. Phase 2: FirebaseMessaging.instance.unsubscribeFromTopic(topic).
  }
}