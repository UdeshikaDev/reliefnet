// lib/models/admin_metrics_model.dart

/// Daily request count entry used by the AdminMetricsScreen bar chart.
class DailyRequestCount {
  final String label; // e.g. 'Mon', 'Tue'
  final int count;

  const DailyRequestCount(this.label, this.count);
}

/// System-wide aggregate statistics shown on the AdminMetricsScreen.
///
/// Phase 2: computed server-side and stored in a Firestore `system_metrics`
/// document, updated by Cloud Functions after each significant event.
/// Phase 1: returned by [MockAdminService] with hardcoded realistic numbers.
class AdminMetrics {
  final int totalRequests;
  final int completedRequests;
  final int pendingRequests;
  final int cancelledRequests;
  final int expiredRequests;
  final int activeCenters;
  final int registeredVolunteers;
  final int approvedVolunteers;
  final int pendingVolunteers;
  final int totalParcelsDistributed;

  /// Request counts for the last 7 days (index 0 = oldest, index 6 = today).
  final List<DailyRequestCount> requestsLast7Days;

  const AdminMetrics({
    required this.totalRequests,
    required this.completedRequests,
    required this.pendingRequests,
    required this.cancelledRequests,
    required this.expiredRequests,
    required this.activeCenters,
    required this.registeredVolunteers,
    required this.approvedVolunteers,
    required this.pendingVolunteers,
    required this.totalParcelsDistributed,
    required this.requestsLast7Days,
  });
}