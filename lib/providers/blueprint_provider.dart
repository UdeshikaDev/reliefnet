// lib/providers/blueprint_provider.dart
// Phase 2 swap: replace MockBlueprintService with FirebaseBlueprintService in main.dart.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/parcel_blueprint_model.dart';
import '../services/firestore/blueprint_service.dart';

/// Manages the global parcel blueprint.
///
/// **Read path:** [startListening] subscribes to [BlueprintService.blueprintStream].
/// Any admin update to the blueprint immediately reflects here and rebuilds
/// any widget that calls `context.watch<BlueprintProvider>()`.
///
/// **Write path:** [updateBlueprint] delegates to the service. On success the
/// stream re-emits the new blueprint automatically.
///
/// **Phase 2 swap:** Replace MockBlueprintService with FirebaseBlueprintService
/// in main.dart. Zero changes here.
class BlueprintProvider extends ChangeNotifier {
  final BlueprintService _service;
  BlueprintProvider(this._service);

  // ── State ─────────────────────────────────────────────────────────────────
  ParcelBlueprintModel? _blueprint;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  StreamSubscription<ParcelBlueprintModel>? _sub;

  // ── Getters ───────────────────────────────────────────────────────────────
  ParcelBlueprintModel? get blueprint => _blueprint;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  /// Convenience: items list from the current blueprint, or empty if not yet loaded.
  List<BlueprintItem> get items => _blueprint?.items ?? [];

  // ── Stream ────────────────────────────────────────────────────────────────

  /// Begin listening to blueprint updates.
  /// Safe to call on every navigation — cancels the previous subscription first.
  void startListening() {
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _sub = _service.blueprintStream().listen(
      (bp) {
        _blueprint = bp;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Could not load blueprint. Pull down to retry.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ── Admin write ───────────────────────────────────────────────────────────

  /// Overwrites the active blueprint. Admin-only.
  /// Returns `true` on success. The stream will re-emit automatically.
  Future<bool> updateBlueprint(ParcelBlueprintModel updated) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateBlueprint(updated);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not save blueprint. Please try again.';
      return false;
    } finally {
      _isSaving = false;
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}