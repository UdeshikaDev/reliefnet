// lib/providers/packed_parcels_provider.dart
// Phase 2 swap: replace MockParcelService with FirebaseParcelService in main.dart.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/enums/parcel_status.dart';
import '../core/errors/app_exception.dart';
import '../models/packed_parcel_model.dart';
import '../services/firestore/parcel_service.dart';

/// Real-time status counts for packed parcels at a donation center.
///
/// Used by [ParcelManagerScreen] to display:
///   - [availableCount] — parcels ready to dispatch
///   - [reservedCount]  — parcels allocated to accepted tasks
///   - [inTransitCount] — parcels being delivered
///   - [distributedCount] — parcels successfully delivered
///
/// **Phase 2 swap:** Replace MockParcelService with FirebaseParcelService
/// in main.dart. Zero changes here.
class PackedParcelsProvider extends ChangeNotifier {
  final ParcelService _service;
  PackedParcelsProvider(this._service);

  // ── State ─────────────────────────────────────────────────────────────────
  List<PackedParcelModel> _parcels = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<PackedParcelModel>>? _sub;

  // Separate from [_error]/[_isLoading] above (which track the parcels
  // stream) so a failed pack attempt doesn't get silently overwritten by
  // the next stream event, and so the UI can show a pack-specific spinner
  // without it being reset every time parcelsStream re-emits.
  bool _isPacking = false;
  String? _packError;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<PackedParcelModel> get parcels => _parcels;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPacking => _isPacking;
  String? get packError => _packError;

  int get availableCount =>
      _parcels.where((p) => p.status == ParcelStatus.available).length;

  int get reservedCount =>
      _parcels.where((p) => p.status == ParcelStatus.reserved).length;

  int get inTransitCount =>
      _parcels.where((p) => p.status == ParcelStatus.inTransit).length;

  int get distributedCount =>
      _parcels.where((p) => p.status == ParcelStatus.distributed).length;

  int get totalCount => _parcels.length;

  // ── Stream ────────────────────────────────────────────────────────────────

  /// Begin listening to all parcel updates for [centerId].
  /// Safe to call on every navigation — cancels the previous subscription first.
  void listenToParcels(String centerId) {
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    _parcels = [];
    notifyListeners();

    _sub = _service.parcelsStream(centerId).listen(
      (parcels) {
        _parcels = parcels;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Could not load parcel data. Pull down to retry.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ── Packing ───────────────────────────────────────────────────────────────

  /// Actually creates [count] new [ParcelStatus.available] documents in the
  /// `packed_parcels` sub-collection for [centerId] — i.e. converts raw
  /// inventory stock into real, reservable parcels.
  ///
  /// This was previously never called from any screen: [InventoryProvider]
  /// only tracks `maxParcels` (how many parcels the *current stock could
  /// support*, aka "kit potential"), which is a completely separate number
  /// from how many parcel documents actually exist. A center could show
  /// "5 parcels" everywhere (My Centers, Parcel Manager's banner, the public
  /// map) purely because it had enough raw stock for 5 — while the
  /// `packed_parcels` sub-collection that [TaskProvider.getAvailableParcelCount]
  /// and [FirebaseParcelService.reserveParcels] actually check stayed empty,
  /// so volunteers could never accept a task for that center. Calling this
  /// is the missing step that bridges the two: it deducts the stock consumed
  /// (via [ParcelService.packParcels], which re-verifies inventory itself)
  /// and creates the real parcel docs, so `maxParcels` goes down while the
  /// live "available" count volunteers see goes up by the same amount.
  ///
  /// Returns true on success. On [InsufficientInventoryException] (stock ran
  /// out or changed between opening the screen and confirming) or any other
  /// failure, returns false and sets [packError].
  Future<bool> packParcels(String centerId, int count) async {
    _isPacking = true;
    _packError = null;
    notifyListeners();
    try {
      await _service.packParcels(centerId, count);
      return true;
    } on AppException catch (e) {
      _packError = e.message;
      return false;
    } catch (_) {
      _packError = 'Could not pack parcels. Please try again.';
      return false;
    } finally {
      _isPacking = false;
      notifyListeners();
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void clearPackError() {
    if (_packError != null) {
      _packError = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}