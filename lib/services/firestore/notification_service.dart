// lib/services/firestore/notification_service.dart

import '../../models/notification_model.dart';

/// Abstract interface for in-app notification document operations.
///
/// Phase 1: [MockNotificationService] serves data from [mockNotifications].
/// Phase 2: [FirebaseNotificationService] streams from Firestore
///   `notifications` collection, ordered by `createdAt` descending,
///   where `recipientUid == currentUid`.
///
/// Note: **All notification writes happen in Cloud Functions**, never from
/// the Flutter client. This service is read-only + mark-as-read only.
abstract class NotificationService {
  /// Real-time stream of all notifications for [recipientUid].
  /// Sorted by [NotificationModel.createdAt] descending (newest first).
  ///
  /// Phase 2: `FirebaseFirestore.instance
  ///   .collection('notifications')
  ///   .where('recipientUid', isEqualTo: recipientUid)
  ///   .orderBy('createdAt', descending: true)
  ///   .snapshots()`
  Stream<List<NotificationModel>> notificationsStream(String recipientUid);

  /// Marks a single notification as read.
  /// Phase 2: updates `notifications/{notificationId}.isRead = true`.
  Future<void> markAsRead(String notificationId);

  /// Marks every notification for [recipientUid] as read in a batch.
  /// Phase 2: Firestore `WriteBatch` over all unread docs for this user.
  Future<void> markAllAsRead(String recipientUid);
}