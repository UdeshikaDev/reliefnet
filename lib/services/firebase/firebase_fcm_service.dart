// lib/services/firebase/firebase_fcm_service.dart
//
// Phase 2 implementation of FcmService, backed by firebase_messaging.
//
// Drop-in replacement for MockFcmService: NotificationProvider only
// depends on the abstract FcmService interface, so no provider changes
// are needed beyond wiring this into main.dart — except NotificationProvider.initFcm
// itself, which now also subscribes to broadcast topics (see that file's
// comment on the `role` parameter for why).
//
// Takes a UserService — not just an optional FirebaseFirestore, unlike
// every other Firebase*Service in this app — because the interface's own
// doc comment says saveToken "calls UserService.setFcmToken(uid, token)",
// and that's a typed method on the UserService interface, not a raw
// Firestore write this class should be duplicating.
//
// Not included here: registering a foreground message handler with
// flutter_local_notifications (so a push that arrives while the app is
// open actually shows a banner). That's app-startup wiring — a listener
// registered once in main.dart, plus Android notification channel setup —
// not a per-call FcmService method, so it doesn't fit this interface as
// written. Says so explicitly rather than silently skipping it: if you
// want that, it's a small, separate addition to main.dart, happy to add
// it.
//
// [Unverified] Checked by hand against current firebase_messaging usage —
// not run against a live device from here.

import 'package:firebase_messaging/firebase_messaging.dart';

import '../firestore/user_service.dart';
import '../fcm/fcm_service.dart';

class FirebaseFcmService implements FcmService {
  final UserService _userService;
  final FirebaseMessaging _messaging;

  FirebaseFcmService(this._userService, {FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> saveToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _userService.setFcmToken(uid, token);
  }

  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
