// lib/widgets/coordinator/blueprint_item_row.dart

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/parcel_blueprint_model.dart';

/// A single read-only row displaying one [BlueprintItem] in the blueprint list.
/// Used on [ParcelManagerScreen] to show what goes into each parcel.
///
/// Layout:
///   Item Name         Qty      Unit
///   Dehydrated Rice   2.0      kg
class BlueprintItemRow extends StatelessWidget {
  final BlueprintItem item;
  final bool showDivider;

  const BlueprintItemRow({
    super.key,
    required this.item,
    this.showDivider = true,
  });

  String _formatQty(double qty) {
    // Show "2" instead of "2.0", but "0.5" as "0.5"
    return qty == qty.truncate() ? qty.toInt().toString() : qty.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          child: Row(
            children: [
              // Item name
              Expanded(
                flex: 5,
                child: Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Quantity
              SizedBox(
                width: 48,
                child: Text(
                  _formatQty(item.quantityPerParcel),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: 8),
              // Unit
              SizedBox(
                width: 36,
                child: Text(
                  item.unit,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}