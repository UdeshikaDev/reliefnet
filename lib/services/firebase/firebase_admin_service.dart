// lib/services/firebase/firebase_admin_service.dart
//
// Phase 2 implementation of AdminService.
//
// Two methods, two different designs — both deliberate deviations from
// the interface's literal doc comments, explained below:
//
// getSystemMetrics(): The interface says this should read a maintained
// `system_metrics/current` Firestore document, "updated by Cloud Functions
// after each significant event." Building that pipeline for real would
// mean a Cloud Function trigger on every write to relief_requests,
// delivery_tasks, users, centers, and handover_receipts — a lot of new
// server-side surface for what's still a small dataset. Instead, this
// checks for that rollup doc first (so if you *do* build that pipeline
// later, this starts using it with zero client changes), and falls back
// to computing the same numbers live from the source collections. Live
// computation means full reads of relief_requests/centers/users/
// handover_receipts on every AdminMetricsScreen visit — fine at this
// app's current scale, but worth revisiting (build the rollup pipeline)
// if those collections grow large.
//
// sendBroadcast(): genuinely needs a Cloud Function — FCM topic messaging
// requires the Admin SDK, there's no client-side equivalent. Added
// `sendBroadcast` to functions/index.js. [Depends on the not-yet-converted
// FCM bundle] — this function sends to FCM topics named 'allUsers'/
// 'victimsOnly'/'volunteersOnly' (matching BroadcastTarget.name), but
// nothing subscribes any device to those topics yet — that's
// FirebaseFcmService, still mocked. This will work correctly the moment
// that's wired up; until then it's a real, callable function with no
// actual subscribers to reach.
//
// [Unverified] Checked by hand against current cloud_firestore/
// cloud_functions usage — not run against a live Firestore instance from
// here.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/enums/broadcast_target.dart';
import '../../core/enums/request_status.dart';
import '../../core/enums/user_role.dart';
import '../../core/errors/app_exception.dart';
import '../../models/admin_metrics_model.dart';
import '../../models/relief_request_model.dart';
import '../firestore/admin_service.dart';

class FirebaseAdminService implements AdminService {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  FirebaseAdminService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<AdminMetrics> getSystemMetrics() async {
    final rollupDoc = await _db
        .collection(FirestorePaths.systemMetrics)
        .doc(FirestorePaths.systemMetricsDocId)
        .get();
    if (rollupDoc.exists) {
      return _fromRollupMap(rollupDoc.data()!);
    }
    return _computeMetricsLive();
  }

  AdminMetrics _fromRollupMap(Map<String, dynamic> data) {
    final days = (data['requestsLast7Days'] as List? ?? [])
        .map((e) => DailyRequestCount(
              e['label'] as String,
              (e['count'] as num).toInt(),
            ))
        .toList();
    return AdminMetrics(
      totalRequests: (data['totalRequests'] as num?)?.toInt() ?? 0,
      completedRequests: (data['completedRequests'] as num?)?.toInt() ?? 0,
      pendingRequests: (data['pendingRequests'] as num?)?.toInt() ?? 0,
      cancelledRequests: (data['cancelledRequests'] as num?)?.toInt() ?? 0,
      expiredRequests: (data['expiredRequests'] as num?)?.toInt() ?? 0,
      activeCenters: (data['activeCenters'] as num?)?.toInt() ?? 0,
      registeredVolunteers: (data['registeredVolunteers'] as num?)?.toInt() ?? 0,
      approvedVolunteers: (data['approvedVolunteers'] as num?)?.toInt() ?? 0,
      pendingVolunteers: (data['pendingVolunteers'] as num?)?.toInt() ?? 0,
      totalParcelsDistributed:
          (data['totalParcelsDistributed'] as num?)?.toInt() ?? 0,
      requestsLast7Days: days,
    );
  }

  Future<AdminMetrics> _computeMetricsLive() async {
    final requestsSnap = await _db.collection(FirestorePaths.requests).get();
    final requests = requestsSnap.docs
        .map((d) => ReliefRequestModel.fromMap(d.data(), id: d.id))
        .toList();
    int countByStatus(RequestStatus s) =>
        requests.where((r) => r.status == s).length;

    final centersSnap = await _db
        .collection(FirestorePaths.centers)
        .where('isActive', isEqualTo: true)
        .get();

    final volunteersSnap = await _db
        .collection(FirestorePaths.users)
        .where('role', isEqualTo: UserRole.volunteer.name)
        .get();
    final approvedVolunteers = volunteersSnap.docs
        .where((d) => d.data()['isVerified'] == true)
        .length;

    final receiptsSnap = await _db.collection(FirestorePaths.receipts).get();
    final totalParcelsDistributed = receiptsSnap.docs.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['parcelsDelivered'] as num?)?.toInt() ?? 0),
    );

    // Bucket requests submitted in each of the last 7 calendar days
    // (index 0 = 6 days ago, index 6 = today), matching the interface's
    // documented ordering.
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final days = List.generate(
      7,
      (i) => todayMidnight.subtract(Duration(days: 6 - i)),
    );
    final counts = List<int>.filled(7, 0);
    for (final r in requests) {
      final submittedDay = DateTime(
        r.submittedAt.year,
        r.submittedAt.month,
        r.submittedAt.day,
      );
      final idx = days.indexWhere((d) => d == submittedDay);
      if (idx != -1) counts[idx]++;
    }
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final requestsLast7Days = List.generate(
      7,
      (i) => DailyRequestCount(weekdayLabels[days[i].weekday - 1], counts[i]),
    );

    return AdminMetrics(
      totalRequests: requests.length,
      completedRequests: countByStatus(RequestStatus.completed),
      pendingRequests: countByStatus(RequestStatus.pending),
      cancelledRequests: countByStatus(RequestStatus.cancelled),
      expiredRequests: countByStatus(RequestStatus.expired),
      activeCenters: centersSnap.docs.length,
      registeredVolunteers: volunteersSnap.docs.length,
      approvedVolunteers: approvedVolunteers,
      pendingVolunteers: volunteersSnap.docs.length - approvedVolunteers,
      totalParcelsDistributed: totalParcelsDistributed,
      requestsLast7Days: requestsLast7Days,
    );
  }

  @override
  Future<void> sendBroadcast({
    required BroadcastTarget target,
    required String title,
    required String body,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendBroadcast');
      await callable.call({
        'target': target.name,
        'title': title,
        'body': body,
      });
    } on FirebaseFunctionsException catch (e) {
      // Same pattern as FirebaseAuthService.sendOtp — HttpsError
      // codes/messages set server-side (see functions/index.js) surface
      // here as e.message, already written to be shown to the person.
      throw AppException(e.message ?? 'Could not send the broadcast.');
    } catch (_) {
      throw const AppException('Could not send the broadcast. Check your connection and try again.');
    }
  }
}
