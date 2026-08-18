// lib/screens/coordinator/stock_log_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';

/// Flattened, time-sorted view of all stock activity across every inventory
/// item in this center. Sourced from [InventoryItemModel.activityLog].
///
/// Filters: All · Restock (+) · Dispatch (-)
///
/// **Navigation in:** `CoordinatorDashboardScreen` → `context.push(stockLog, extra: centerId)`
class StockLogScreen extends StatefulWidget {
  final String centerId;

  const StockLogScreen({super.key, required this.centerId});

  @override
  State<StockLogScreen> createState() => _StockLogScreenState();
}

enum _LogFilter { all, restock, dispatch }

class _LogEntry {
  final String itemName;
  final String unit;
  final StockActivity activity;

  const _LogEntry({
    required this.itemName,
    required this.unit,
    required this.activity,
  });
}

class _StockLogScreenState extends State<StockLogScreen> {
  late final InventoryProvider _inventoryProvider;
  _LogFilter _filter = _LogFilter.all;

  @override
  void initState() {
    super.initState();
    _inventoryProvider = context.read<InventoryProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inventoryProvider.listenToInventory(widget.centerId);
    });
  }

  @override
  void dispose() {
    _inventoryProvider.stopListening();
    super.dispose();
  }

  List<_LogEntry> _buildEntries(List<InventoryItemModel> items) {
    final entries = <_LogEntry>[];
    for (final item in items) {
      for (final activity in item.activityLog) {
        entries.add(_LogEntry(
          itemName: item.itemName,
          unit: item.unit,
          activity: activity,
        ));
      }
    }
    // Most recent first
    entries.sort((a, b) =>
        b.activity.timestamp.compareTo(a.activity.timestamp));
    return entries;
  }

  List<_LogEntry> _applyFilter(List<_LogEntry> entries) {
    return switch (_filter) {
      _LogFilter.all => entries,
      _LogFilter.restock =>
        entries.where((e) => e.activity.action == 'add').toList(),
      _LogFilter.dispatch =>
        entries.where((e) => e.activity.action == 'deduct').toList(),
    };
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProv = context.watch<InventoryProvider>();
    final allEntries = _buildEntries(inventoryProv.items);
    final filtered = _applyFilter(allEntries);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Stock Log'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Filter chips ────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All (${allEntries.length})',
                  selected: _filter == _LogFilter.all,
                  onTap: () => setState(() => _filter = _LogFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:
                      'Restock (${allEntries.where((e) => e.activity.action == 'add').length})',
                  selected: _filter == _LogFilter.restock,
                  color: AppColors.success,
                  onTap: () => setState(() => _filter = _LogFilter.restock),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:
                      'Dispatch (${allEntries.where((e) => e.activity.action == 'deduct').length})',
                  selected: _filter == _LogFilter.dispatch,
                  color: AppColors.error,
                  onTap: () => setState(() => _filter = _LogFilter.dispatch),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Log list ────────────────────────────────────────────────────
          Expanded(
            child: inventoryProv.isLoading && inventoryProv.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No activity found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 60,
                          color: AppColors.divider,
                        ),
                        itemBuilder: (ctx, i) {
                          final entry = filtered[i];
                          return _LogTile(
                            entry: entry,
                            relativeTime:
                                _relativeTime(entry.activity.timestamp),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final _LogEntry entry;
  final String relativeTime;

  const _LogTile({required this.entry, required this.relativeTime});

  @override
  Widget build(BuildContext context) {
    final isAdd = entry.activity.action == 'add';
    final color = isAdd ? AppColors.success : AppColors.error;
    final icon = isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final prefix = isAdd ? '+' : '−';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${entry.activity.performedByUid.length > 12 ? entry.activity.performedByUid.substring(0, 12) : entry.activity.performedByUid}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${entry.activity.amount} ${entry.unit}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                relativeTime,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}