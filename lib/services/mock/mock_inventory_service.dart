// lib/services/mock/mock_inventory_service.dart
// Phase 2 swap: replace with FirebaseInventoryService in main.dart.

import 'dart:async';
import '../../models/inventory_item_model.dart';
import '../../models/parcel_blueprint_model.dart';
import '../firestore/inventory_service.dart';
import 'mock_data.dart';

class MockInventoryService implements InventoryService {
  static const _delay = Duration(milliseconds: 500);

  final List<InventoryItemModel> _items = List.from(mockInventory);

  final StreamController<List<InventoryItemModel>> _controller =
      StreamController<List<InventoryItemModel>>.broadcast();

  // Constructor intentionally empty — do NOT emit here.
  MockInventoryService();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_items));
    }
  }

  @override
Future<List<InventoryItemModel>> getInventory(String centerId) async {
  await Future.delayed(_delay);
  _lazySeedCenter(centerId); // ← ADD THIS LINE
  return _items.where((i) => i.centerId == centerId).toList();
}

 @override
Stream<List<InventoryItemModel>> inventoryStream(String centerId) {
  _lazySeedCenter(centerId); // ← ADD THIS LINE
  Future.microtask(() => _emit());
  return _controller.stream
      .map((list) => list.where((i) => i.centerId == centerId).toList());
}

/// Auto-seeds 5 blueprint items at zero stock for any centerId not already
/// in the inventory list. Ensures pre-seeded mock centers are usable
/// without needing to register them as new centers first.
void _lazySeedCenter(String centerId) {
  final exists = _items.any((i) => i.centerId == centerId);
  if (exists) return;

  final blueprint = ParcelBlueprintModel.defaultBlueprint;
  final now = DateTime.now();
  for (final item in blueprint.items) {
    _items.add(InventoryItemModel(
      itemId:
          '${centerId}_${item.itemName.toLowerCase().replaceAll(' ', '_')}',
      centerId: centerId,
      itemName: item.itemName,
      unit: item.unit,
      currentStock: 0,
      quantityPerParcel: item.quantityPerParcel,
      kitPotential: 0,
      isBottleneck: false,
      lastUpdatedAt: now,
    ));
  }
  _emit(); // notify any active stream listeners of the new items
}

  @override
  Future<void> addStock({
    required String centerId,
    required String itemId,
    required double amount,
    required String performedByUid,
  }) async {
    await Future.delayed(_delay);
    final idx = _items.indexWhere(
      (i) => i.itemId == itemId && i.centerId == centerId,
    );
    if (idx == -1) return;

    final item = _items[idx];
    final newStock = item.currentStock + amount;
    final newKit = item.quantityPerParcel > 0
        ? (newStock / item.quantityPerParcel).floor()
        : 0;
    _items[idx] = item.copyWith(
      currentStock: newStock,
      kitPotential: newKit,
      activityLog: [
        ...item.activityLog,
        StockActivity(
          action: 'add',
          amount: amount,
          performedByUid: performedByUid,
          timestamp: DateTime.now(),
        ),
      ],
      lastUpdatedAt: DateTime.now(),
    );

    _recalculateBottleneck(centerId);
    _emit();
  }

  @override
  Future<void> deductStock({
    required String centerId,
    required String itemId,
    required double amount,
    required String performedByUid,
  }) async {
    await Future.delayed(_delay);
    final idx = _items.indexWhere(
      (i) => i.itemId == itemId && i.centerId == centerId,
    );
    if (idx == -1) return;

    final item = _items[idx];
    final newStock = (item.currentStock - amount).clamp(0.0, double.infinity);
    final newKit = item.quantityPerParcel > 0
        ? (newStock / item.quantityPerParcel).floor()
        : 0;
    _items[idx] = item.copyWith(
      currentStock: newStock,
      kitPotential: newKit,
      activityLog: [
        ...item.activityLog,
        StockActivity(
          action: 'deduct',
          amount: amount,
          performedByUid: performedByUid,
          timestamp: DateTime.now(),
        ),
      ],
      lastUpdatedAt: DateTime.now(),
    );

    _recalculateBottleneck(centerId);
    _emit();
  }

  @override
  Future<void> initializeInventory(
      String centerId, ParcelBlueprintModel blueprint) async {
    await Future.delayed(_delay);
    _items.removeWhere((i) => i.centerId == centerId);
    final now = DateTime.now();
    for (final blueprintItem in blueprint.items) {
      _items.add(InventoryItemModel(
        itemId:
            '${centerId}_${blueprintItem.itemName.toLowerCase().replaceAll(' ', '_')}',
        centerId: centerId,
        itemName: blueprintItem.itemName,
        unit: blueprintItem.unit,
        currentStock: 0,
        quantityPerParcel: blueprintItem.quantityPerParcel,
        kitPotential: 0,
        isBottleneck: false,
        lastUpdatedAt: now,
      ));
    }
    _emit();
  }

  /// The item with the lowest kitPotential is the bottleneck.
  void _recalculateBottleneck(String centerId) {
    final center = _items.where((i) => i.centerId == centerId).toList();
    if (center.isEmpty) return;
    int min = center.first.kitPotential;
    for (final i in center) {
      if (i.kitPotential < min) min = i.kitPotential;
    }
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].centerId == centerId) {
        _items[i] = _items[i].copyWith(
          isBottleneck: _items[i].kitPotential == min,
        );
      }
    }
  }

  void dispose() => _controller.close();
}