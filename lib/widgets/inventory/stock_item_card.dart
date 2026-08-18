// lib/widgets/inventory/stock_item_card.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../models/inventory_item_model.dart';

/// Card showing one inventory item's stock level and kit potential.
/// Highlighted red + BOTTLENECK badge when [item.isBottleneck] is true.
class StockItemCard extends StatelessWidget {
  final InventoryItemModel item;
  final VoidCallback? onAddStock;

  const StockItemCard({super.key, required this.item, this.onAddStock});

  @override
  Widget build(BuildContext context) {
    final isB = item.isBottleneck;
    final borderColor = isB ? AppColors.error : AppColors.divider;
    final kitColor    = isB ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isB ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        item.itemName,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: isB ? AppColors.error : AppColors.textPrimary,
                        ),
                      ),
                      if (isB) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('BOTTLENECK',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                  color: AppColors.error, letterSpacing: 0.5)),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddStock,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Stock + Kit row ─────────────────────────────────────────────
            Row(
              children: [
                _InfoChip(
                  label: 'Stock',
                  value: '${item.currentStock % 1 == 0 ? item.currentStock.toInt() : item.currentStock} ${item.unit}',
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 10),
                _InfoChip(
                  label: 'Kit potential',
                  value: '${item.kitPotential} parcels',
                  color: kitColor,
                ),
                const Spacer(),
                Text('Updated ${item.lastUpdatedAt.timeAgo}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(height: 10),

            // ── Progress bar (stock / 200 reference) ───────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (item.currentStock / 200).clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceAlt,
                color: isB ? AppColors.error : AppColors.success,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    ],
  );
}