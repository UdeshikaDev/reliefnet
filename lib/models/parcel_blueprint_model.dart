/// A single item line in the parcel blueprint.
class BlueprintItem {
  final String itemName;
  final String unit;

  /// Quantity of this item included in every packed parcel.
  final double quantityPerParcel;

  const BlueprintItem({
    required this.itemName,
    required this.unit,
    required this.quantityPerParcel,
  });

  factory BlueprintItem.fromMap(Map<String, dynamic> map) => BlueprintItem(
        itemName: map['itemName'] as String,
        unit: map['unit'] as String,
        quantityPerParcel: (map['quantityPerParcel'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'itemName': itemName,
        'unit': unit,
        'quantityPerParcel': quantityPerParcel,
      };
}

/// The global parcel blueprint — defines the contents of every packed parcel.
/// There is exactly one active blueprint (document ID: `current` in `parcel_blueprint/`).
/// Only admins can edit it.
///
/// Default blueprint:
/// - Dehydrated Rice  2.0 kg
/// - Sugar            0.5 kg
/// - Dhal             1.0 kg
/// - Milk Powder      0.4 kg
/// - Coconut Oil      0.5 L
class ParcelBlueprintModel {
  final List<BlueprintItem> items;
  final String lastUpdatedByUid;
  final DateTime lastUpdatedAt;

  const ParcelBlueprintModel({
    required this.items,
    required this.lastUpdatedByUid,
    required this.lastUpdatedAt,
  });

  factory ParcelBlueprintModel.fromMap(Map<String, dynamic> map) {
    return ParcelBlueprintModel(
      items: (map['items'] as List)
          .map((e) => BlueprintItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      lastUpdatedByUid: map['lastUpdatedByUid'] as String,
      lastUpdatedAt: _parseDate(map['lastUpdatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'items': items.map((i) => i.toMap()).toList(),
        'lastUpdatedByUid': lastUpdatedByUid,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  /// Returns the default blueprint used when a new center is registered.
  static ParcelBlueprintModel get defaultBlueprint => ParcelBlueprintModel(
        lastUpdatedByUid: 'system',
        lastUpdatedAt: DateTime(2025, 1, 1),
        items: const [
          BlueprintItem(itemName: 'Dehydrated Rice', unit: 'kg', quantityPerParcel: 2.0),
          BlueprintItem(itemName: 'Sugar', unit: 'kg', quantityPerParcel: 0.5),
          BlueprintItem(itemName: 'Dhal', unit: 'kg', quantityPerParcel: 1.0),
          BlueprintItem(itemName: 'Milk Powder', unit: 'kg', quantityPerParcel: 0.4),
          BlueprintItem(itemName: 'Coconut Oil', unit: 'L', quantityPerParcel: 0.5),
        ],
      );
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}