// lib/providers/centers_provider.dart
//
// Phase 2 swap: replace MockCenterService with FirebaseCenterService in main.dart.
// No changes needed in this file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/donation_center_model.dart';
import '../services/firestore/center_service.dart';

/// Manages center creation, coordinator assignment, and inventory access.
///
/// Shared between Module 3 (public map read), Module 5 (volunteer management),
/// and Module 6 (parcel manager). In Module 3 only the read-path is used.
///
/// **Phase 2 swap:** Replace `MockCenterService` with `FirebaseCenterService`
/// in `main.dart`. No changes needed here.
class CentersProvider extends ChangeNotifier {
  final CenterService _centerService;

  CentersProvider(this._centerService);

  // ── State ──────────────────────────────────────────────────────────────────
  List<DonationCenterModel> _myCenters = [];
  DonationCenterModel? _viewingCenter;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<DonationCenterModel>>? _sub;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<DonationCenterModel> get myCenters => _myCenters;
  DonationCenterModel? get viewingCenter => _viewingCenter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Coordinator role checks ────────────────────────────────────────────────

  bool isMainCoordinator(String centerId, String uid) =>
      _myCenters.any(
        (c) => c.centerId == centerId && c.mainCoordinatorUid == uid,
      );

  bool isSubCoordinator(String centerId, String uid) =>
      _myCenters.any(
        (c) => c.centerId == centerId && c.subCoordinatorUids.contains(uid),
      );

  // ── Stream ─────────────────────────────────────────────────────────────────

  void listenToCentersForUser(String uid) {
    _sub?.cancel();
    _sub = _centerService.activeCentersStream().listen(
      (centers) {
        _myCenters = centers
            .where(
              (c) =>
                  c.mainCoordinatorUid == uid ||
                  c.subCoordinatorUids.contains(uid),
            )
            .toList();
        notifyListeners();
      },
      onError: (_) => notifyListeners(),
    );
  }

  // ── Detail View ────────────────────────────────────────────────────────────

  Future<void> loadCenter(String centerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _viewingCenter = await _centerService.getCenterById(centerId);
      if (_viewingCenter == null) _error = 'Center not found.';
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load center details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a single center by ID without touching [viewingCenter] or any
  /// other shared state. Added for widgets that just need to display a
  /// center's name (e.g. a task card showing "Kurunegala Relief Hub"
  /// instead of a raw centerId) — loadCenter() above writes to shared
  /// provider state, so calling it from several list items at once (each
  /// showing a different center) would have them overwrite each other's
  /// result. This is a plain, side-effect-free fetch instead.
  Future<DonationCenterModel?> fetchCenterById(String centerId) {
    return _centerService.getCenterById(centerId);
  }

  // ── Registration ───────────────────────────────────────────────────────────

  Future<String?> registerCenter({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required String volunteerUid,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final id = await _centerService.registerCenter(
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        mainCoordinatorUid: volunteerUid,
      );
      return id;
    } on AppException catch (e) {
      _error = e.message;
      return null;
    } catch (_) {
      _error = 'Could not register center. Try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Sub Coordinators ───────────────────────────────────────────────────────

  /// Adds [uid] as a sub-coordinator of [centerId].
  ///
  /// **FIX:** After the service call, immediately apply an optimistic update
  /// to [_myCenters] and [_viewingCenter] in memory.
  ///
  /// Why needed: [MockCenterService.addSubCoordinator] calls `_emit()` on its
  /// broadcast stream, but Dart stream delivery is asynchronous — the update
  /// doesn't reach [_myCenters] until the next event loop iteration. The
  /// screen calls [ManageSubCoordinatorsScreen._loadSubCoords] immediately
  /// after this method returns, so it was reading stale [_myCenters] every
  /// time and the new sub-coordinator never appeared.
  Future<void> addSubCoordinator(String centerId, String uid) async {
    _error = null;
    try {
      await _centerService.addSubCoordinator(centerId, uid);

      // ── Optimistic update: patch _myCenters immediately ────────────────
      final idx = _myCenters.indexWhere((c) => c.centerId == centerId);
      if (idx != -1) {
        final c = _myCenters[idx];
        if (!c.subCoordinatorUids.contains(uid)) {
          _myCenters[idx] = c.copyWith(
            subCoordinatorUids: [...c.subCoordinatorUids, uid],
          );
        }
      }

      // ── Also patch _viewingCenter if it's the same center ──────────────
      if (_viewingCenter?.centerId == centerId) {
        final vc = _viewingCenter!;
        if (!vc.subCoordinatorUids.contains(uid)) {
          _viewingCenter = vc.copyWith(
            subCoordinatorUids: [...vc.subCoordinatorUids, uid],
          );
        }
      }

      notifyListeners();
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (_) {
      _error = 'Could not add sub coordinator. Please try again.';
      notifyListeners();
    }
  }

  /// Removes [uid] from sub-coordinators of [centerId].
  ///
  /// Same optimistic-update pattern as [addSubCoordinator].
  Future<void> removeSubCoordinator(String centerId, String uid) async {
    _error = null;
    try {
      await _centerService.removeSubCoordinator(centerId, uid);

      // ── Optimistic update: patch _myCenters immediately ────────────────
      final idx = _myCenters.indexWhere((c) => c.centerId == centerId);
      if (idx != -1) {
        final c = _myCenters[idx];
        _myCenters[idx] = c.copyWith(
          subCoordinatorUids:
              c.subCoordinatorUids.where((id) => id != uid).toList(),
        );
      }

      // ── Also patch _viewingCenter if it's the same center ──────────────
      if (_viewingCenter?.centerId == centerId) {
        final vc = _viewingCenter!;
        _viewingCenter = vc.copyWith(
          subCoordinatorUids:
              vc.subCoordinatorUids.where((id) => id != uid).toList(),
        );
      }

      notifyListeners();
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (_) {
      _error = 'Could not remove sub coordinator. Please try again.';
      notifyListeners();
    }
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}