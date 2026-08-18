import '../../core/enums/request_status.dart';
import '../../models/relief_request_model.dart';

/// Abstract interface for relief request operations.
abstract class RequestService {
  /// Fetches a single request by ID.
  Future<ReliefRequestModel?> getRequest(String requestId);

  /// Real-time stream of the victim's current active request.
  /// Emits `null` when no active request exists.
  Stream<ReliefRequestModel?> activeRequestStream(String victimUid);

  /// All completed/expired/cancelled requests for a victim (history view).
  Future<List<ReliefRequestModel>> getRequestHistory(String victimUid);

  /// All requests with status [RequestStatus.pending] — shown to volunteers on map.
  Future<List<ReliefRequestModel>> getPendingRequests();

  /// Creates a new request document. Returns the new document ID.
  Future<String> createRequest({
    required String victimUid,
    required String nicNumber,
    required int familySize,
    required int parcelsEntitled,
    required double lat,
    required double lng,
    required String damagePhotoUrl,
  });

  /// Updates request status, optionally setting assigned center and volunteer.
  Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status, {
    String? centerId,
    String? volunteerUid,
  });

  /// Cancels a request. Only valid while status == [RequestStatus.pending].
  Future<void> cancelRequest(String requestId);
  Future<List<ReliefRequestModel>> getFlaggedRequests();

  /// Admin approves the damage photo after manual review.
  ///
  /// Sets [photoMetadataVerified] = true and [photoFlaggedForAdminReview] = false.
  /// Status remains [RequestStatus.pending] so the request re-enters the
  /// volunteer queue.
  ///
  /// Phase 2: Cloud Function sends FCM "Your request is being processed" to victim.
  Future<void> approvePhotoReview(String requestId);
}