// lib/services/firebase/firebase_request_service.dart
//
// Phase 2 implementation of RequestService, backed by Firestore's
// `relief_requests` collection (FirestorePaths.requests).
//
// Drop-in replacement for MockRequestService: RequestProvider only depends
// on the abstract RequestService interface, so no provider/screen changes
// are needed beyond wiring this into main.dart.
//
// Storage convention: dates are stored as ISO-8601 strings via the model's
// existing toMap()/fromMap() (same convention FirebaseCenterService and
// DonationCenterModel already use), not Firestore Timestamps. This keeps
// every service consistent and means the model files don't need touching.
//
// Indexing note: every query below deliberately uses a single equality
// filter and does any extra filtering/sorting client-side, specifically to
// avoid needing composite indexes (Firestore requires one for
// equality-filter + orderBy-on-a-different-field, or two-field equality,
// combos). Request volumes per victim/center are small enough in this app
// that this trade-off is fine; if request volume ever grows large, move
// getPendingRequests/getFlaggedRequests to server-side filtering with the
// matching composite indexes added to firestore.indexes.json.
//
// [Unverified] Checked by hand against current cloud_firestore usage and
// against MockRequestService's exact behavior — not run against a live
// Firestore instance from here.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/enums/request_status.dart';
import '../../core/errors/app_exception.dart';
import '../../models/relief_request_model.dart';
import '../firestore/request_service.dart';

class FirebaseRequestService implements RequestService {
  final FirebaseFirestore _db;
  FirebaseRequestService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection(FirestorePaths.requests);

  @override
  Future<ReliefRequestModel?> getRequest(String requestId) async {
    final doc = await _requests.doc(requestId).get();
    if (!doc.exists) return null;
    return ReliefRequestModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Stream<ReliefRequestModel?> activeRequestStream(String victimUid) {
    // Single equality filter (victimUid) — no composite index needed.
    // isActive is filtered client-side, same as MockRequestService does
    // against its in-memory list.
    return _requests
        .where('victimUid', isEqualTo: victimUid)
        .snapshots()
        .map((snap) {
      final active = snap.docs
          .map((d) => ReliefRequestModel.fromMap(d.data(), id: d.id))
          .where((r) => r.isActive)
          .toList();
      return active.isEmpty ? null : active.first;
    });
  }

  @override
  Future<List<ReliefRequestModel>> getRequestHistory(String victimUid) async {
    final snap =
        await _requests.where('victimUid', isEqualTo: victimUid).get();
    final history = snap.docs
        .map((d) => ReliefRequestModel.fromMap(d.data(), id: d.id))
        .where((r) => !r.isActive)
        .toList()
      // Newest first — mock didn't sort at all, this is a small UX
      // improvement that doesn't change the interface contract.
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return history;
  }

  @override
  Future<List<ReliefRequestModel>> getPendingRequests() async {
    // Single equality filter (status) — photoFlaggedForAdminReview is
    // filtered client-side to avoid a two-field composite index. Pending
    // volume is small enough for this app's scale that over-fetching
    // flagged-pending docs and dropping them client-side is cheap.
    final snap = await _requests
        .where('status', isEqualTo: RequestStatus.pending.name)
        .get();
    return snap.docs
        .map((d) => ReliefRequestModel.fromMap(d.data(), id: d.id))
        .where((r) => !r.photoFlaggedForAdminReview)
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
    // Enforce one active request per victim, same rule as
    // MockRequestService. [Unverified/Speculation] This is a
    // check-then-write, not a transaction — theoretically racy if the same
    // victim submits from two devices at the exact same moment, same
    // caveat class as other check-then-write spots in this codebase.
    // Harden with a Firestore transaction (or a Cloud Function) later if
    // that ever becomes a real scenario.
    final existing =
        await _requests.where('victimUid', isEqualTo: victimUid).get();
    final hasActive = existing.docs
        .map((d) => ReliefRequestModel.fromMap(d.data(), id: d.id))
        .any((r) => r.isActive);
    if (hasActive) throw const ActiveRequestExistsException();

    // Firestore's auto-generated doc ID rather than MockRequestService's
    // 'req_${timestamp}' scheme, same reasoning as FirebaseCenterService:
    // collision-free across real, separate devices.
    final docRef = _requests.doc();
    final now = DateTime.now();

    // Same deterministic stand-in as MockRequestService for the
    // not-yet-built photo metadata check — see that file's comment for
    // the full rationale. Replace with the real Cloud Function check
    // (photoMetadataCheck, per relief_request_model.dart's doc comment)
    // when that's built; until then this keeps mock/Firebase behavior
    // identical so testers see the same flagged/unflagged behavior either way.
    final photoFailsCheck = familySize >= 15;

    final request = ReliefRequestModel(
      requestId: docRef.id,
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
    );
    await docRef.set(request.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status, {
    String? centerId,
    String? volunteerUid,
  }) async {
    // ReliefRequestModel.copyWith falls back to the existing value when a
    // param is null (`assignedCenterId ?? this.assignedCenterId`), so
    // MockRequestService never actually overwrites centerId/volunteerUid
    // to null just because a caller didn't pass them. Replicate that here
    // by only including the fields in the update map when non-null —
    // Firestore's .update() would otherwise happily set them to null.
    final fields = <String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (centerId != null) fields['assignedCenterId'] = centerId;
    if (volunteerUid != null) fields['assignedVolunteerUid'] = volunteerUid;
    await _requests.doc(requestId).update(fields);
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    await updateRequestStatus(requestId, RequestStatus.cancelled);
  }

  @override
  Future<List<ReliefRequestModel>> getFlaggedRequests() async {
    // Single equality filter (photoFlaggedForAdminReview) — sorted
    // client-side to avoid needing a composite index for the orderBy.
    final snap = await _requests
        .where('photoFlaggedForAdminReview', isEqualTo: true)
        .get();
    final flagged = snap.docs
        .map((d) => ReliefRequestModel.fromMap(d.data(), id: d.id))
        .toList()
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    return flagged;
  }

  @override
  Future<void> approvePhotoReview(String requestId) async {
    await _requests.doc(requestId).update({
      'photoMetadataVerified': true,
      'photoFlaggedForAdminReview': false,
      // Status stays 'pending' as-is, same as MockRequestService — this
      // re-enters the volunteer queue via getPendingRequests' filter.
    });
  }
}
