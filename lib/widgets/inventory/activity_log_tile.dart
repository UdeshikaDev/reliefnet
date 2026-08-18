// lib/widgets/inventory/activity_log_tile.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../models/inventory_item_model.dart';

/// Displays one [StockActivity] entry in a stock log list.
class ActivityLogTile extends StatelessWidget {
  final StockActivity activity;
  final String itemName;
  final String unit;

  const ActivityLogTile({
    super.key,
    required this.activity,
    required this.itemName,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isAdd  = activity.action == 'add';
    final color  = isAdd ? AppColors.success : AppColors.warning;
    final icon   = isAdd ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final label  = isAdd ? 'Restock' : 'Dispatch';
    final sign   = isAdd ? '+' : '−';
    final amount = activity.amount % 1 == 0
        ? activity.amount.toInt().toString()
        : activity.amount.toString();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        '$sign$amount $unit $itemName',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
          const SizedBox(width: 8),
          Text(activity.timestamp.timeAgo,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}