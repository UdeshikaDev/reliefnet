/// Input data type for [BottleneckCalculator].
/// Decoupled from [InventoryItemModel] so the calculator can be tested
/// without importing the full model layer.
class InventoryInput {
  final String itemName;
  final double currentStock;

  /// How many units of this item go into one packed parcel.
  /// Defined by the active [ParcelBlueprintModel].
  final double quantityPerParcel;

  const InventoryInput({
    required this.itemName,
    required this.currentStock,
    required this.quantityPerParcel,
  });
}

/// The result of a [BottleneckCalculator.calculate] call.
class BottleneckResult {
  /// Maximum number of complete parcels that can be packed right now,
  /// limited by the scarcest item relative to its blueprint requirement.
  final int maxParcels;

  /// Name of the item that limits parcel production (lowest kit potential).
  /// Empty string if [items] was empty.
  final String bottleneckItem;

  /// Kit potential for every item: `floor(currentStock / quantityPerParcel)`.
  /// Use this list to power the bottleneck bar chart widget.
  final List<({String itemName, int kitPotential})> kitPotentials;

  const BottleneckResult({
    required this.maxParcels,
    required this.bottleneckItem,
    required this.kitPotentials,
  });
}

/// Fixed-Ratio Inventory Depletion algorithm.
///
/// **Kit potential** for each item = `floor(currentStock / quantityPerParcel)`
///
/// **Bottleneck** = item with the lowest kit potential.
///
/// **Max parcels available** = `min(all kit potentials)`.
///
/// Example:
/// ```
/// Rice   100 kg  / 2 kg per parcel  = 50  kits
/// Sugar   15 kg  / 0.5 kg per parcel = 30  kits  ← bottleneck
/// Dhal    90 kg  / 1 kg per parcel  = 90  kits
/// → maxParcels = 30, bottleneckItem = 'Sugar'
/// ```
class BottleneckCalculator {
  BottleneckCalculator._();

  static BottleneckResult calculate(List<InventoryInput> items) {
    if (items.isEmpty) {
      return const BottleneckResult(
        maxParcels: 0,
        bottleneckItem: '',
        kitPotentials: [],
      );
    }

    final potentials = items.map((item) {
      final kit = item.quantityPerParcel > 0
          ? (item.currentStock / item.quantityPerParcel).floor()
          : 0;
      return (itemName: item.itemName, kitPotential: kit);
    }).toList();

    final bottleneck = potentials.reduce(
      (a, b) => a.kitPotential <= b.kitPotential ? a : b,
    );

    return BottleneckResult(
      maxParcels: bottleneck.kitPotential,
      bottleneckItem: bottleneck.itemName,
      kitPotentials: potentials,
    );
  }
}