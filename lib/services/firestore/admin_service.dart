// lib/services/firestore/admin_service.dart

import '../../core/enums/broadcast_target.dart';
import '../../models/admin_metrics_model.dart';

/// Abstract interface for admin-only operations.
///
/// Phase 1: [MockAdminService] returns hardcoded metrics and no-ops broadcast.
/// Phase 2: [FirebaseAdminService] reads from `system_metrics` Firestore doc
/// and calls the `sendBroadcast` Cloud Function via `cloud_functions`.
abstract class AdminService {
  /// Returns system-wide aggregate metrics.
  /// Phase 2: reads the `system_metrics/current` Firestore document.
  Future<AdminMetrics> getSystemMetrics();

  /// Sends a push notification broadcast to the target user group.
  ///
  /// [target] determines which FCM topic receives the message.
  /// Phase 2: calls `FirebaseFunctions.instance.httpsCallable('sendBroadcast')`.
  Future<void> sendBroadcast({
    required BroadcastTarget target,
    required String title,
    required String body,
  });
}