import '../core/utils/bottleneck_calculator.dart';

/// A stock activity log entry — appended whenever stock is added or deducted.
class StockActivity {
  final String action; // 'add' | 'deduct'
  final double amount;
  final String performedByUid;
  final DateTime timestamp;

  const StockActivity({
    required this.action,
    required this.amount,
    required this.performedByUid,
    required this.timestamp,
  });

  factory StockActivity.fromMap(Map<String, dynamic> map) => StockActivity(
        action: map['action'] as String,
        amount: (map['amount'] as num).toDouble(),
        performedByUid: map['performedByUid'] as String,
        timestamp: _parseDate(map['timestamp']),
      );

  Map<String, dynamic> toMap() => {
        'action': action,
        'amount': amount,
        'performedByUid': performedByUid,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Represents one ingredient/item tracked inside a donation center's inventory.
///
/// `kitPotential` = `floor(currentStock / quantityPerParcel)`.
/// Recomputed by the service layer whenever stock changes.
/// [isBottleneck] is set by [BottleneckCalculator] after comparing all items.
class InventoryItemModel {
  final String itemId;
  final String centerId;
  final String itemName;
  final String unit; // 'kg', 'g', 'L', 'units'

  /// Current stock in [unit]s.
  final double currentStock;

  /// Units of this item required per one packed parcel (from the blueprint).
  final double quantityPerParcel;

  /// `floor(currentStock / quantityPerParcel)` — how many full parcels this item can support.
  final int kitPotential;

  /// `true` if this item has the lowest [kitPotential] among all items in this center.
  final bool isBottleneck;

  final List<StockActivity> activityLog;
  final DateTime lastUpdatedAt;

  const InventoryItemModel({
    required this.itemId,
    required this.centerId,
    required this.itemName,
    required this.unit,
    required this.currentStock,
    required this.quantityPerParcel,
    required this.kitPotential,
    required this.isBottleneck,
    required this.lastUpdatedAt,
    this.activityLog = const [],
  });

  factory InventoryItemModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return InventoryItemModel(
      itemId: id ?? map['itemId'] as String,
      centerId: map['centerId'] as String,
      itemName: map['itemName'] as String,
      unit: map['unit'] as String,
      currentStock: (map['currentStock'] as num).toDouble(),
      quantityPerParcel: (map['quantityPerParcel'] as num).toDouble(),
      kitPotential: map['kitPotential'] as int? ?? 0,
      isBottleneck: map['isBottleneck'] as bool? ?? false,
      lastUpdatedAt: _parseDate(map['lastUpdatedAt']),
      activityLog: (map['activityLog'] as List? ?? [])
          .map((e) => StockActivity.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'centerId': centerId,
        'itemName': itemName,
        'unit': unit,
        'currentStock': currentStock,
        'quantityPerParcel': quantityPerParcel,
        'kitPotential': kitPotential,
        'isBottleneck': isBottleneck,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
        'activityLog': activityLog.map((e) => e.toMap()).toList(),
      };

  /// Converts to [InventoryInput] for use with [BottleneckCalculator].
  InventoryInput toInventoryInput() => InventoryInput(
        itemName: itemName,
        currentStock: currentStock,
        quantityPerParcel: quantityPerParcel,
      );

  InventoryItemModel copyWith({
    String? itemId,
    String? centerId,
    String? itemName,
    String? unit,
    double? currentStock,
    double? quantityPerParcel,
    int? kitPotential,
    bool? isBottleneck,
    List<StockActivity>? activityLog,
    DateTime? lastUpdatedAt,
  }) {
    return InventoryItemModel(
      itemId: itemId ?? this.itemId,
      centerId: centerId ?? this.centerId,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      quantityPerParcel: quantityPerParcel ?? this.quantityPerParcel,
      kitPotential: kitPotential ?? this.kitPotential,
      isBottleneck: isBottleneck ?? this.isBottleneck,
      activityLog: activityLog ?? this.activityLog,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}