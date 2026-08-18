// lib/providers/inventory_provider.dart
// Phase 2 swap: replace MockInventoryService with FirebaseInventoryService in main.dart.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/inventory_item_model.dart';
import '../models/parcel_blueprint_model.dart';
import '../services/firestore/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service;
  InventoryProvider(this._service);

  List<InventoryItemModel> _items = [];
  bool _isLoading = false;
  bool _isAddingStock = false;
  String? _error;
  StreamSubscription<List<InventoryItemModel>>? _sub;

  List<InventoryItemModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isAddingStock => _isAddingStock;
  String? get error => _error;

  /// Max complete parcels = min(all kitPotentials). 0 when empty.
  int get maxParcels {
    if (_items.isEmpty) return 0;
    int min = _items.first.kitPotential;
    for (final i in _items) { if (i.kitPotential < min) min = i.kitPotential; }
    return min;
  }

  /// The item that is currently the bottleneck. null when empty.
  InventoryItemModel? get bottleneckItem =>
      _items.where((i) => i.isBottleneck).firstOrNull;

  // ── Stream ─────────────────────────────────────────────────────────────────

  /// Start listening to real-time inventory for [centerId].
  /// Safe to call on every navigation — cancels the previous subscription first.
  void listenToInventory(String centerId) {
    _sub?.cancel();
    _isLoading = true; _error = null; _items = [];
    notifyListeners();

    _sub = _service.inventoryStream(centerId).listen(
      (items) {
        _items = items; _isLoading = false; _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Could not load inventory. Pull down to retry.';
        _isLoading = false; notifyListeners();
      },
    );
  }

  void stopListening() { _sub?.cancel(); _sub = null; }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Adds stock. The mock service re-emits the stream so [_items] updates automatically.
  Future<bool> addStock({
    required String centerId,
    required String itemId,
    required double amount,
    required String performedByUid,
  }) async {
    _isAddingStock = true; _error = null; notifyListeners();
    try {
      await _service.addStock(
        centerId: centerId, itemId: itemId,
        amount: amount, performedByUid: performedByUid,
      );
      return true;
    } on AppException catch (e) {
      _error = e.message; return false;
    } catch (_) {
      _error = 'Failed to add stock. Please try again.'; return false;
    } finally {
      _isAddingStock = false; notifyListeners();
    }
  }

  /// Seeds zero-stock inventory items for a newly registered center.
  Future<void> initializeInventoryForCenter(
      String centerId, ParcelBlueprintModel blueprint) async {
    try { await _service.initializeInventory(centerId, blueprint); }
    catch (_) {} // Non-critical — center will show empty inventory.
  }

  void clearError() { if (_error != null) { _error = null; notifyListeners(); } }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}