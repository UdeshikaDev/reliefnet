// lib/widgets/coordinator/bottleneck_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/inventory_item_model.dart';

/// Bar chart showing [InventoryItemModel.kitPotential] for every item in a center.
///
/// The bar for the bottleneck item ([InventoryItemModel.isBottleneck] == true)
/// renders in [AppColors.error] (red). All other bars render in [AppColors.primary].
///
/// The minimum bar height is the number of complete parcels the center can pack.
/// The coordinator can see at a glance which item is limiting throughput.
class BottleneckBarChart extends StatefulWidget {
  final List<InventoryItemModel> items;

  const BottleneckBarChart({super.key, required this.items});

  @override
  State<BottleneckBarChart> createState() => _BottleneckBarChartState();
}

class _BottleneckBarChartState extends State<BottleneckBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No inventory data available.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final int maxKit = widget.items
        .map((i) => i.kitPotential)
        .fold(0, (prev, val) => val > prev ? val : prev);
    // Add 20% headroom so the tallest bar never hits the chart ceiling.
    final double maxY = ((maxKit * 1.25) + 1).ceilToDouble().clamp(5.0, double.infinity);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              setState(() {
                _touchedIndex =
                    (event is FlTapUpEvent || event is FlLongPressEnd)
                        ? null
                        : response?.spot?.touchedBarGroupIndex;
              });
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = widget.items[group.x];
                return BarTooltipItem(
                  '${item.itemName}\n${rod.toY.toInt()} parcels',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value < 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= widget.items.length) {
                    return const SizedBox.shrink();
                  }
                  final item = widget.items[index];
                  final label = item.itemName.length > 7
                      ? '${item.itemName.substring(0, 6)}…'
                      : item.itemName;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: item.isBottleneck
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight: item.isBottleneck
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isTouched = _touchedIndex == index;
            final barColor =
                item.isBottleneck ? AppColors.error : AppColors.primary;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.kitPotential.toDouble(),
                  color: isTouched ? barColor.withOpacity(0.7) : barColor,
                  width: 30,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: AppColors.surfaceAlt,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }
}