// lib/providers/request_provider.dart
//
// Phase 2 swap: In main.dart replace MockRequestService → FirebaseRequestService.
// No changes needed in this file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/parcel_calculator.dart';
import '../models/relief_request_model.dart';
import '../services/firestore/request_service.dart';
import '../services/storage/storage_service.dart';

/// Manages the victim's active request, submission flow, and history list.
///
/// **State fields:**
/// - [activeRequest]  — current active request (non-null while pending/accepted/etc.)
/// - [history]        — completed/expired/cancelled requests (MyRequestsScreen)
/// - [isSubmitting]   — true while the submit form POST is in flight
/// - [isLoading]      — true while history or a single request is loading
/// - [error]          — last error message (null when no error)
///
/// **Module 5 additions:**
/// - [pendingRequests] / [loadPendingRequests] — volunteer request map + list
/// - [viewingRequest]  / [loadRequestById]     — volunteer detail + accept screens
///
/// **Phase 2 swap:** Replace `MockRequestService` with `FirebaseRequestService`
/// in `main.dart`. This file is unchanged.
class RequestProvider extends ChangeNotifier {
  final RequestService _service; // ← single source of truth; never _requestService
  final StorageService _storageService;

  RequestProvider(this._service, this._storageService);

  // ── State ──────────────────────────────────────────────────────────────────

  ReliefRequestModel?              _activeRequest;
  List<ReliefRequestModel>         _history          = [];
  bool                             _isSubmitting     = false;
  bool                             _isLoading        = false;
  String?                          _error;
  String?                          _lastSubmittedRequestId;
  StreamSubscription<ReliefRequestModel?>? _sub;

  // ── Volunteer-side state (Module 5) ──────────────────────────────────────
  List<ReliefRequestModel> _pendingRequests = [];
  ReliefRequestModel?      _viewingRequest;

  // ── Getters ────────────────────────────────────────────────────────────────

  ReliefRequestModel?      get activeRequest            => _activeRequest;
  List<ReliefRequestModel> get history                  => _history;
  bool                     get isSubmitting             => _isSubmitting;
  bool                     get isLoading                => _isLoading;
  String?                  get error                    => _error;
  String?                  get lastSubmittedRequestId   => _lastSubmittedRequestId;
  bool                     get hasActiveRequest         => _activeRequest != null;
  List<ReliefRequestModel> get pendingRequests          => _pendingRequests;
  ReliefRequestModel?      get viewingRequest           => _viewingRequest;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void startListening(String victimUid) {
    _sub?.cancel();
    _sub = _service.activeRequestStream(victimUid).listen(
      (request) {
        _activeRequest = request;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Could not load your request. Pull down to retry.';
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ── Volunteer-side actions (Module 5) ──────────────────────────────────────

  /// Loads all requests with status == pending.
  /// Used by [RequestMapScreen] and [RequestListScreen].
  Future<void> loadPendingRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _pendingRequests = await _service.getPendingRequests(); // ← _service, not _requestService
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load requests. Pull down to retry.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads a single request by ID without affecting [activeRequest].
  /// Used by [RequestDetailVolScreen] and [AcceptTaskScreen].
  Future<void> loadRequestById(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _viewingRequest = await _service.getRequest(requestId); // ← _service, not _requestService
      if (_viewingRequest == null) _error = 'Request not found.';
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load request details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Victim-side actions ────────────────────────────────────────────────────

  Future<bool> submitRequest({
    required String victimUid,
    required String nicNumber,
    required int    familySize,
    required double lat,
    required double lng,
    File?           photoFile,
  }) async {
    _isSubmitting = true;
    _error = null;
    _lastSubmittedRequestId = null;
    notifyListeners();
    try {
      final parcelsEntitled = calculateParcels(familySize);

      // Previously this discarded the photoFile the victim actually took
      // and hardcoded a generic placeholder URL regardless of what was
      // captured — MockStorageService.uploadDamagePhoto already existed for
      // exactly this purpose but was never wired in anywhere. [Verified
      // from code: grep found zero references to StorageService before
      // this change.]
      String photoUrl;
      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        final fileName =
            'damage_${victimUid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        photoUrl =
            await _storageService.uploadDamagePhoto(victimUid, bytes, fileName);
      } else {
        // Screen-level validation should already require a photo before
        // calling submitRequest — this is a defensive fallback only.
        photoUrl = 'https://picsum.photos/seed/damage/400/300';
      }

      final requestId = await _service.createRequest(
        victimUid:       victimUid,
        nicNumber:       nicNumber,
        familySize:      familySize,
        parcelsEntitled: parcelsEntitled,
        lat:             lat,
        lng:             lng,
        damagePhotoUrl:  photoUrl,
      );
      _lastSubmittedRequestId = requestId;
      return true;
    } on ActiveRequestExistsException {
      _error =
          'You already have an active relief request. Cancel it before submitting a new one.';
      return false;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not submit request. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> cancelActiveRequest() async {
    if (_activeRequest == null) return false;
    if (_activeRequest!.status.name != 'pending') {
      _error = 'Only pending requests can be cancelled.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.cancelRequest(_activeRequest!.requestId);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not cancel request. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads completed/expired/cancelled requests for the history screen.
  ///
  /// Uses [SchedulerBinding.addPostFrameCallback] guard so that
  /// [notifyListeners] is never called during a build phase — preventing
  /// the "setState() called during build" FlutterError.
  Future<void> loadHistory(String victimUid) async {
    void safeNotify() {
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
      } else {
        notifyListeners();
      }
    }

    _isLoading = true;
    _error = null;
    safeNotify(); // ← safe first notify (was the crash site before the fix)

    try {
      _history = await _service.getRequestHistory(victimUid);
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load request history.';
    } finally {
      _isLoading = false;
      notifyListeners(); // ← always safe here (awaited = frame done)
    }
  }

  /// Fetches a request by ID without storing it anywhere.
  /// Used by victim [RequestDetailScreen] when [activeRequest] ID doesn't match.
  Future<ReliefRequestModel?> loadRequest(String requestId) async {
    try {
      return await _service.getRequest(requestId);
    } catch (_) {
      return null;
    }
  }
  // ── Admin-side state (Module 8) ──────────────────────────────────────────────

  List<ReliefRequestModel> _flaggedRequests = [];
  bool _isApprovingRejecting = false;

  List<ReliefRequestModel> get flaggedRequests => _flaggedRequests;
  bool get isApprovingRejecting => _isApprovingRejecting;

  // ── Admin: Flagged photo review (Module 8) ────────────────────────────────

  /// Loads all requests flagged for admin photo review.
  /// Used by [FlaggedRequestsScreen].
  Future<void> loadFlaggedRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _flaggedRequests = await _service.getFlaggedRequests();
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load flagged requests.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Admin approves the damage photo after manual review.
  ///
  /// Side-effects:
  ///   1. Calls service to set `photoMetadataVerified = true`, `photoFlaggedForAdminReview = false`.
  ///   2. Removes request from [_flaggedRequests] immediately (optimistic update).
  ///
  /// Returns `true` on success.
  Future<bool> approvePhotoReview(String requestId) async {
    _isApprovingRejecting = true;
    _error = null;
    notifyListeners();
    try {
      await _service.approvePhotoReview(requestId);
      _flaggedRequests.removeWhere((r) => r.requestId == requestId);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not approve request. Please try again.';
      return false;
    } finally {
      _isApprovingRejecting = false;
      notifyListeners();
    }
  }

  /// Admin rejects and cancels a flagged request.
  ///
  /// Side-effects:
  ///   1. Calls service to set `status = cancelled`.
  ///   2. Removes request from [_flaggedRequests] immediately (optimistic update).
  ///
  /// Returns `true` on success.
  Future<bool> rejectFlaggedRequest(String requestId) async {
    _isApprovingRejecting = true;
    _error = null;
    notifyListeners();
    try {
      await _service.cancelRequest(requestId);
      _flaggedRequests.removeWhere((r) => r.requestId == requestId);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not reject request. Please try again.';
      return false;
    } finally {
      _isApprovingRejecting = false;
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int parcelsForFamilySize(int familySize) => calculateParcels(familySize);

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}