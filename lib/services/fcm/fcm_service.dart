// lib/services/fcm/fcm_service.dart

/// Abstract interface for Firebase Cloud Messaging operations.
///
/// Phase 1: [MockFcmService] is a no-op implementation.
/// Phase 2: [FirebaseFcmService] calls `FirebaseMessaging` SDK methods,
///   saves the FCM token to `users/{uid}.fcmToken` in Firestore, and
///   registers foreground message handlers with `flutter_local_notifications`.
abstract class FcmService {
  /// Returns the current device FCM registration token.
  /// Phase 2: calls `FirebaseMessaging.instance.getToken()`.
  Future<String?> getToken();

  /// Requests push notification permission from the OS (iOS + Android 13+).
  /// Returns `true` if permission is granted.
  /// Phase 2: calls `FirebaseMessaging.instance.requestPermission()`.
  Future<bool> requestPermission();

  /// Saves the current device token to the user's Firestore document.
  /// Phase 2: calls `UserService.setFcmToken(uid, token)`.
  Future<void> saveToken(String uid);

  /// Subscribes this device to an FCM topic — e.g. `'allUsers'`,
  /// `'victimsOnly'`, `'volunteersOnly'` (matching BroadcastTarget.name
  /// exactly). [Added in Phase 2] This is what actually lets
  /// AdminService.sendBroadcast reach a device — sendBroadcast sends to
  /// one of these topics, but nothing subscribed any device to them until
  /// this method existed and NotificationProvider.initFcm started calling
  /// it.
  /// Phase 2: calls `FirebaseMessaging.instance.subscribeToTopic(topic)`.
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribes this device from an FCM topic.
  /// Phase 2: calls `FirebaseMessaging.instance.unsubscribeFromTopic(topic)`.
  Future<void> unsubscribeFromTopic(String topic);
}