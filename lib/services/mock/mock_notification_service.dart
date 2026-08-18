// lib/services/mock/mock_notification_service.dart
//
// Phase 2 swap: replace MockNotificationService with
// FirebaseNotificationService in main.dart. Zero other changes.

import 'dart:async';

import '../../models/notification_model.dart';
import '../firestore/notification_service.dart';
import 'mock_data.dart';

/// In-memory implementation of [NotificationService].
///
/// Uses a per-user [StreamController.broadcast] so that [markAsRead] and
/// [markAllAsRead] immediately re-emit the updated list — exactly as
/// Firestore `snapshots()` would behave in Phase 2.
///
/// **Phase 2 swap:** Replace with `FirebaseNotificationService` in `main.dart`.
class MockNotificationService implements NotificationService {
  static const _delay = Duration(milliseconds: 250);

  // Mutable copy of the seed data — mutations are reflected in streams.
  final List<NotificationModel> _notifications =
      List.from(mockNotifications);

  // One broadcast controller per recipientUid.
  final Map<String, StreamController<List<NotificationModel>>> _ctrlMap = {};

  StreamController<List<NotificationModel>> _ctrlFor(String uid) {
    return _ctrlMap.putIfAbsent(
      uid,
      () => StreamController<List<NotificationModel>>.broadcast(),
    );
  }

  /// Emits the current sorted list for [uid] on their stream.
  void _emit(String uid) {
    final ctrl = _ctrlFor(uid);
    if (ctrl.isClosed) return;
    final list = _notifications
        .where((n) => n.recipientUid == uid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    ctrl.add(list);
  }

  // ── NotificationService interface ─────────────────────────────────────────

  @override
  Stream<List<NotificationModel>> notificationsStream(String recipientUid) {
    // Emit current value immediately after the subscriber connects.
    Future.microtask(() => _emit(recipientUid));
    return _ctrlFor(recipientUid).stream;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(_delay);
    final idx =
        _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (idx == -1) return;
    final uid = _notifications[idx].recipientUid;
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    _emit(uid);
  }

  @override
  Future<void> markAllAsRead(String recipientUid) async {
    await Future.delayed(_delay);
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientUid == recipientUid &&
          !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _emit(recipientUid);
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void dispose() {
    for (final ctrl in _ctrlMap.values) {
      ctrl.close();
    }
    _ctrlMap.clear();
  }
}