// lib/screens/admin/global_inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_center_model.dart';
import '../../providers/map_provider.dart';
import '../../widgets/common/app_error_widget.dart';

class GlobalInventoryScreen extends StatefulWidget {
  const GlobalInventoryScreen({super.key});

  @override
  State<GlobalInventoryScreen> createState() => _GlobalInventoryScreenState();
}

class _GlobalInventoryScreenState extends State<GlobalInventoryScreen> {
  @override
  void initState() {
    super.initState();
    // MapProvider may already be listening from PublicMapScreen.
    // startListening is safe to call again — it cancels the previous sub.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MapProvider>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();

    // Aggregate totals
    //
    // [Fix — architectural] These now read availableParcels (the real,
    // live "ready right now" count) instead of the old
    // maxParcelsAvailable (renamed DonationCenterModel.packingCapacity),
    // which was only ever raw-stock kit potential — an admin using this
    // screen to gauge system-wide readiness needs the real number, same
    // reasoning as the public map's filter chips and marker colors.
    final centers = mapProv.filteredCenters;
    final totalParcels =
        centers.fold<int>(0, (sum, c) => sum + c.availableParcels);
    final criticalCount =
        centers.where((c) => c.availableParcels == 0).length;
    final highCount =
        centers.where((c) => c.availableParcels >= 10).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Global Inventory (${centers.length} centers)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Builder(builder: (_) {
        if (mapProv.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          );
        }
        if (mapProv.error != null) {
          return Center(child: AppErrorBanner(message: mapProv.error!));
        }
        if (centers.isEmpty) {
          return const Center(
            child: Text(
              'No active centers found.',
              style:
                  TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // ── Summary cards ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _SummaryCard(
                        label: 'Total Parcels',
                        value: '$totalParcels',
                        color: AppColors.primary),
                    const SizedBox(width: 10),
                    _SummaryCard(
                        label: 'High Stock',
                        value: '$highCount',
                        color: AppColors.success),
                    const SizedBox(width: 10),
                    _SummaryCard(
                        label: 'Critical',
                        value: '$criticalCount',
                        color: AppColors.error),
                  ],
                ),
              ),
            ),

            // ── Center list ────────────────────────────────────────────────
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CenterInventoryCard(center: centers[i]),
                  ),
                  childCount: centers.length,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Center card ───────────────────────────────────────────────────────────────

class _CenterInventoryCard extends StatelessWidget {
  final DonationCenterModel center;
  const _CenterInventoryCard({required this.center});

  Color get _statusColor {
    if (center.availableParcels == 0) return AppColors.error;
    if (center.availableParcels < 10) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  center.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Parcel count badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${center.availableParcels} parcels',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  center.address,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (center.bottleneckItem != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'Bottleneck: ${center.bottleneckItem}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}