import '../../models/inventory_item_model.dart';
import '../../models/parcel_blueprint_model.dart';

/// Abstract interface for center inventory operations.
abstract class InventoryService {
  /// Fetches all inventory items for a center — single fetch.
  Future<List<InventoryItemModel>> getInventory(String centerId);

  /// Real-time stream of inventory items for the inventory screen.
  Stream<List<InventoryItemModel>> inventoryStream(String centerId);

  /// Adds [amount] to item stock. Recomputes [kitPotential] and [isBottleneck].
  /// Appends a [StockActivity] log entry.
  Future<void> addStock({
    required String centerId,
    required String itemId,
    required double amount,
    required String performedByUid,
  });

  /// Deducts stock after parcel packing. Called by the Cloud Function
  /// (not directly by UI).
  Future<void> deductStock({
    required String centerId,
    required String itemId,
    required double amount,
    required String performedByUid,
  });

  /// Initialises inventory items from a blueprint.
  /// Creates one inventory item doc per blueprint item with stock = 0.
  Future<void> initializeInventory(
      String centerId, ParcelBlueprintModel blueprint);
}