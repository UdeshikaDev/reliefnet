import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/donation_center_model.dart';
import '../services/firestore/center_service.dart';

/// Filter options for the public map chip bar.
enum MapFilter { all, highStock, critical }

/// Manages the real-time center stream and the active chip filter.
///
/// **Responsibilities:**
/// - Starts/stops the center stream from [CenterService].
/// - Exposes [filteredCenters] based on [activeFilter].
/// - Tracks the [selectedCenter] for the bottom-sheet detail panel.
///
/// **Phase 2 swap:** In `main.dart` pass `FirebaseCenterService()` instead of
/// `MockCenterService()`. Zero changes to this provider file.
class MapProvider extends ChangeNotifier {
  final CenterService _centerService;

  MapProvider(this._centerService);

  // ── State ──────────────────────────────────────────────────────────────────
  List<DonationCenterModel> _allCenters = [];
  MapFilter _activeFilter = MapFilter.all;
  DonationCenterModel? _selectedCenter;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<DonationCenterModel>>? _sub;

  // ── Getters ────────────────────────────────────────────────────────────────
  MapFilter get activeFilter => _activeFilter;
  DonationCenterModel? get selectedCenter => _selectedCenter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Centers filtered by [activeFilter].
  ///
  /// [Fix — architectural] These thresholds now read [availableParcels] —
  /// the real, live "ready right now" count — instead of the old
  /// `maxParcelsAvailable` (renamed [packingCapacity]), which was only ever
  /// raw-stock kit potential. A center with plenty of stock but nothing
  /// actually packed yet has packingCapacity > 0 and availableParcels == 0;
  /// showing it as "High Stock" on the public map was actively misleading
  /// for a victim or volunteer deciding where to go.
  List<DonationCenterModel> get filteredCenters {
    return switch (_activeFilter) {
      MapFilter.all      => _allCenters,
      MapFilter.highStock => _allCenters
          .where((c) => c.availableParcels >= 10)
          .toList(),
      MapFilter.critical  => _allCenters
          .where((c) => c.availableParcels == 0)
          .toList(),
    };
  }

  /// Total count of all active centers regardless of filter.
  int get totalCount => _allCenters.length;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Begin listening to center updates. Call once from the screen's [initState].
  void startListening() {
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _sub = _centerService.activeCentersStream().listen(
      (centers) {
        _allCenters = centers;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Could not load centers. Pull down to retry.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stop the stream subscription. Called by [dispose].
  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Change the active chip filter. Triggers [filteredCenters] recompute.
  void setFilter(MapFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  /// Mark a center as selected (tapped on map). Pass `null` to deselect.
  void selectCenter(DonationCenterModel? center) {
    _selectedCenter = center;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Human-readable label for each filter chip.
  // AFTER — all 3 filters show count
String filterLabel(MapFilter filter) {
  final highCount     = _allCenters.where((c) => c.availableParcels >= 10).length;
  final criticalCount = _allCenters.where((c) => c.availableParcels == 0).length;
  return switch (filter) {
    MapFilter.all       => 'All (${_allCenters.length})',
    MapFilter.highStock => 'High Stock ($highCount)',
    MapFilter.critical  => 'Critical ($criticalCount)',
  };
}

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}