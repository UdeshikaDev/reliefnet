// lib/services/mock/mock_request_service.dart
//
// Phase 2 swap: replace MockRequestService with FirebaseRequestService in main.dart.
// No provider or screen changes needed.

import 'dart:async';

import '../../core/enums/request_status.dart';
import '../../core/errors/app_exception.dart';
import '../../models/relief_request_model.dart';
import '../firestore/request_service.dart';
import 'mock_data.dart';

/// Mock implementation of [RequestService].
///
/// Uses a [StreamController.broadcast] so [activeRequestStream] re-emits
/// after every mutation (createRequest, cancelRequest, updateRequestStatus).
/// This drives the real-time status updates in [TrackDeliveryScreen].
class MockRequestService implements RequestService {
  static const _delay = Duration(milliseconds: 600);
  

  // Mutable internal list — same seed as Module 1 mock_data.dart
  final List<ReliefRequestModel> _requests = List.from(mockRequests);

  // Broadcast stream controller — mimics Firestore snapshots().
  final StreamController<List<ReliefRequestModel>> _controller =
      StreamController<List<ReliefRequestModel>>.broadcast();

  MockRequestService();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_requests));
    }
  }

  // ── RequestService interface ─────────────────────────────────────────────

  @override
  Future<ReliefRequestModel?> getRequest(String requestId) async {
    await Future.delayed(_delay);
    return _requests.where((r) => r.requestId == requestId).firstOrNull;
  }

  @override
  Stream<ReliefRequestModel?> activeRequestStream(String victimUid) {
    // Emit current state after the subscriber connects.
    Future.microtask(() => _emit());
    return _controller.stream.map(
      (list) => list
          .where((r) => r.victimUid == victimUid && r.isActive)
          .firstOrNull,
    );
  }

  @override
  Future<List<ReliefRequestModel>> getRequestHistory(String victimUid) async {
    await Future.delayed(_delay);
    return _requests
        .where((r) => r.victimUid == victimUid && !r.isActive)
        .toList();
  }

  @override
  Future<List<ReliefRequestModel>> getPendingRequests() async {
    await Future.delayed(_delay);
    // Previously this returned every pending request regardless of
    // photoFlaggedForAdminReview, so a flagged request was visible to
    // volunteers at the same time it sat in the admin review queue —
    // there was no actual either/or routing between the two. Excluding
    // flagged requests here means they only reappear for volunteers once
    // an admin calls approvePhotoReview (which sets the flag back to
    // false while leaving status as pending).
    return _requests
        .where((r) =>
            r.status == RequestStatus.pending && !r.photoFlaggedForAdminReview)
        .toList();
  }

  @override
  Future<String> createRequest({
    required String victimUid,
    required String nicNumber,
    required int familySize,
    required int parcelsEntitled,
    required double lat,
    required double lng,
    required String damagePhotoUrl,
  }) async {
    await Future.delayed(_delay);

    // Enforce one active request per victim.
    final hasActive = _requests.any(
      (r) => r.victimUid == victimUid && r.isActive,
    );
    if (hasActive) throw const ActiveRequestExistsException();

    final id = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Phase 1 simulated metadata check.
    // [Unverified — not a real EXIF/AI-tag check] There is no actual photo
    // metadata inspection anywhere in this app (confirmed: no EXIF-reading
    // package is used, and the "photo" is a mock-uploaded placeholder URL
    // either way). Previously this always set both flags to false, meaning
    // every request silently skipped verification and went straight to the
    // volunteer queue with photoMetadataVerified still false forever —
    // there was no way to exercise the "flagged → admin review" path via a
    // live submission at all (only the seeded demo request could show it).
    //
    // This deterministic stand-in gives testers a reproducible way to
    // trigger either branch: family sizes 1–14 "pass" instantly; 15+ (the
    // stepper's upper range) simulate a failed check and get flagged. This
    // is a testing convenience, not a fraud-detection heuristic — replace
    // entirely in Phase 2 with the real Cloud Function metadata check.
    final photoFailsCheck = familySize >= 15;

    _requests.add(ReliefRequestModel(
      requestId: id,
      victimUid: victimUid,
      nicNumber: nicNumber,
      familySize: familySize,
      parcelsEntitled: parcelsEntitled,
      damagePhotoUrl: damagePhotoUrl,
      photoMetadataVerified: !photoFailsCheck,
      photoFlaggedForAdminReview: photoFailsCheck,
      status: RequestStatus.pending,
      lat: lat,
      lng: lng,
      submittedAt: now,
      updatedAt: now,
      expiresAt: now.add(const Duration(hours: 72)),
    ));
    _emit();
    return id;
  }

  @override
  Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status, {
    String? centerId,
    String? volunteerUid,
  }) async {
    await Future.delayed(_delay);
    final i = _requests.indexWhere((r) => r.requestId == requestId);
    if (i == -1) return;
    _requests[i] = _requests[i].copyWith(
      status: status,
      assignedCenterId: centerId,
      assignedVolunteerUid: volunteerUid,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    await updateRequestStatus(requestId, RequestStatus.cancelled);
  }

  // ── Module 8 Additions (Admin Methods) ───────────────────────────────────

  @override
  Future<List<ReliefRequestModel>> getFlaggedRequests() async {
    await Future.delayed(_delay);
    return _requests
        .where((r) => r.photoFlaggedForAdminReview)
        .toList()
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  }

  @override
  Future<void> approvePhotoReview(String requestId) async {
    await Future.delayed(_delay);
    final idx = _requests.indexWhere((r) => r.requestId == requestId);
    if (idx == -1) return;

    _requests[idx] = _requests[idx].copyWith(
      photoMetadataVerified: true,
      photoFlaggedForAdminReview: false,
      // Status එක 'pending' ලෙසම පවතින බැවින් මෙය නැවත volunteer queue එකට එකතු වේ.
    );

    // ඔබගේ පවතින කේතයට අනුව '_activeController' වෙනුවට '_controller' භාවිතා කර ඇත
    _emit(); 
  }

  void dispose() {
    _controller.close();
  }
}