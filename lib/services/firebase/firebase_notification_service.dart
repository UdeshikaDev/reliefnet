// lib/services/firebase/firebase_notification_service.dart
//
// Phase 2 implementation of NotificationService, backed by Firestore's
// `notifications` collection (FirestorePaths.notifications).
//
// Drop-in replacement for MockNotificationService: NotificationProvider
// only depends on the abstract NotificationService interface, so no
// provider/screen changes are needed beyond wiring this into main.dart.
//
// Per the interface's own doc comment, this is read + mark-as-read only —
// notification *creation* happens entirely in Cloud Functions triggered
// by other events (task assigned, volunteer approved, broadcast, etc.),
// none of which exist yet. Nothing in this pass creates a Cloud Function
// that writes to `notifications` — that's genuinely separate work, one
// small function per trigger event, best done alongside whichever feature
// each notification type belongs to rather than all at once here.
//
// Indexing note: the interface's own doc comment suggests
// `.where('recipientUid', isEqualTo: ...).orderBy('createdAt', descending: true)`
// directly — but that combination (equality filter + orderBy on a
// different field) needs a composite index, so this queries by
// recipientUid only and sorts client-side, the same composite-index-avoidance
// pattern used throughout this migration.
//
// [Unverified] Checked by hand against current cloud_firestore usage —
// not run against a live Firestore instance from here.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../models/notification_model.dart';
import '../firestore/notification_service.dart';

class FirebaseNotificationService implements NotificationService {
  final FirebaseFirestore _db;
  FirebaseNotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(FirestorePaths.notifications);

  @override
  Stream<List<NotificationModel>> notificationsStream(String recipientUid) {
    return _notifications
        .where('recipientUid', isEqualTo: recipientUid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => NotificationModel.fromMap(d.data(), id: d.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String recipientUid) async {
    // Single equality filter (recipientUid) — isRead filtered client-side
    // to avoid a two-field composite index, same reasoning applied
    // throughout this migration (see e.g. FirebaseRequestService.getPendingRequests).
    final snap =
        await _notifications.where('recipientUid', isEqualTo: recipientUid).get();
    final unread = snap.docs.where((d) => d.data()['isRead'] != true).toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
