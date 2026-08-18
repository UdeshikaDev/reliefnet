// lib/services/mock/mock_admin_service.dart
//
// Phase 2 swap: replace MockAdminService with FirebaseAdminService in main.dart.
// No provider or screen changes needed.

import '../../core/enums/broadcast_target.dart';
import '../../models/admin_metrics_model.dart';
import '../firestore/admin_service.dart';

/// Mock implementation of [AdminService].
///
/// Returns realistic hardcoded metrics for Sri Lanka disaster relief context.
/// The [sendBroadcast] method is a no-op in Phase 1.
///
/// **Phase 2 swap:** Replace with `FirebaseAdminService` in `main.dart`.
class MockAdminService implements AdminService {
  @override
  Future<AdminMetrics> getSystemMetrics() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const AdminMetrics(
      totalRequests:          142,
      completedRequests:       98,
      pendingRequests:         12,
      cancelledRequests:        8,
      expiredRequests:         24,
      activeCenters:            5,
      registeredVolunteers:    23,
      approvedVolunteers:      20,
      pendingVolunteers:        3,
      totalParcelsDistributed: 186,
      requestsLast7Days: [
        DailyRequestCount('Mon', 18),
        DailyRequestCount('Tue', 24),
        DailyRequestCount('Wed', 16),
        DailyRequestCount('Thu', 29),
        DailyRequestCount('Fri', 22),
        DailyRequestCount('Sat', 19),
        DailyRequestCount('Sun', 14),
      ],
    );
  }

  @override
  Future<void> sendBroadcast({
    required BroadcastTarget target,
    required String title,
    required String body,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Phase 1 no-op.
    // Phase 2: calls FirebaseFunctions.instance.httpsCallable('sendBroadcast')
    //   with { target: target.name, title: title, body: body }.
  }
}