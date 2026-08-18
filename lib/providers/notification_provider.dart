// lib/providers/notification_provider.dart
// Phase 2 swap: replace Mock services with Firebase counterparts in main.dart.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/enums/user_role.dart';
import '../core/errors/app_exception.dart';
import '../models/notification_model.dart';
import '../services/fcm/fcm_service.dart';
import '../services/firestore/notification_service.dart';

/// Manages in-app notifications and FCM initialisation.
///
/// **Read path:** [startListening] subscribes to [NotificationService.notificationsStream].
/// The stream re-emits after every [markAsRead] / [markAllAsRead] call so the
/// badge count and list stay in sync without any manual refresh.
///
/// **Unread badge:** Any widget can read [unreadCount] via
/// `context.watch<NotificationProvider>().unreadCount` to show a badge.
///
/// **FCM init:** [initFcm] requests OS permission + saves token to Firestore.
/// Phase 1: [MockFcmService] makes this a no-op.
///
/// **Deep link:** [NotificationsScreen] reads [NotificationModel.routePath]
/// and calls `context.push(routePath)` when a notification is tapped.
///
/// **Phase 2 swap:** Replace Mock services → Firebase services in `main.dart`.
/// Zero changes here.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notifService;
  final FcmService _fcmService;

  NotificationProvider(this._notifService, this._fcmService);

  // ── State ─────────────────────────────────────────────────────────────────
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isMarkingRead = false;
  String? _error;
  String? _currentUid;
  StreamSubscription<List<NotificationModel>>? _sub;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isMarkingRead => _isMarkingRead;
  String? get error => _error;

  /// Number of unread notifications — use for bottom-nav / AppBar badge.
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  // ── Stream lifecycle ──────────────────────────────────────────────────────

  /// Subscribes to notifications for [uid].
  ///
  /// Safe to call multiple times — if [uid] hasn't changed the existing
  /// subscription is reused; otherwise the old sub is cancelled and a new one
  /// is started.
  void startListening(String uid) {
    if (_currentUid == uid && _sub != null) return; // already listening
    _currentUid = uid;
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _sub = _notifService.notificationsStream(uid).listen(
      (list) {
        _notifications = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Could not load notifications.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _currentUid = null;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Marks a single notification as read.
  /// The stream re-emits automatically — no extra [notifyListeners] needed.
  Future<void> markAsRead(String notificationId) async {
    // Silently skip already-read notifications.
    final alreadyRead = _notifications
        .any((n) => n.notificationId == notificationId && n.isRead);
    if (alreadyRead) return;
    try {
      await _notifService.markAsRead(notificationId);
    } catch (_) {
      // Mark-as-read failures are non-critical — silent.
    }
  }

  /// Marks every notification for the current user as read.
  /// Returns `true` on success.
  Future<bool> markAllAsRead() async {
    if (_currentUid == null || !hasUnread) return true;
    _isMarkingRead = true;
    _error = null;
    notifyListeners();
    try {
      await _notifService.markAllAsRead(_currentUid!);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not mark all as read. Please try again.';
      return false;
    } finally {
      _isMarkingRead = false;
      notifyListeners();
    }
  }

  // ── FCM ───────────────────────────────────────────────────────────────────

  /// Requests notification permission, saves the FCM token, and subscribes
  /// this device to the broadcast topics matching [role] — 'allUsers'
  /// always, plus 'victimsOnly' or 'volunteersOnly' (matching
  /// BroadcastTarget.name exactly) for victim/volunteer respectively.
  /// [role] is optional and simply skipped (no role-specific
  /// subscription) for public/admin accounts, or if the caller doesn't
  /// have it handy — 'allUsers' still happens either way.
  ///
  /// Call once per session after the user is authenticated (e.g. from each
  /// home screen's `initState` or from `SplashScreen` after `tryAutoLogin`).
  ///
  /// Phase 1: [MockFcmService] makes this a no-op — safe to call freely.
  /// Phase 2: Requests OS permission, fetches token, writes to Firestore,
  /// subscribes to topics — this is what actually makes
  /// AdminService.sendBroadcast (built alongside FirebaseAdminService)
  /// reach a real device; that function sends to a topic, this is what
  /// puts a device on it.
  Future<void> initFcm(String uid, {UserRole? role}) async {
    try {
      final granted = await _fcmService.requestPermission();
      if (!granted) return;
      await _fcmService.saveToken(uid);
      await _fcmService.subscribeToTopic('allUsers');
      final roleTopic = switch (role) {
        UserRole.victim => 'victimsOnly',
        UserRole.volunteer => 'volunteersOnly',
        _ => null,
      };
      if (roleTopic != null) {
        await _fcmService.subscribeToTopic(roleTopic);
      }
    } catch (_) {
      // FCM is non-critical — never surface errors to the user here.
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}