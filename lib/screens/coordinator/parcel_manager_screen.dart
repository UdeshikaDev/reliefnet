// lib/screens/coordinator/parcel_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/blueprint_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/packed_parcels_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/coordinator/blueprint_item_row.dart';
import '../../widgets/coordinator/bottleneck_bar_chart.dart';
import '../../widgets/coordinator/parcel_count_card.dart';

/// Shows the complete parcel health picture for one donation center:
///   1. Max parcels banner — the limiting kit potential from [InventoryProvider]
///   2. Pack Parcels action — converts that kit potential into real,
///      reservable [PackedParcelsProvider] documents (see [_packAvailable])
///   3. Bottleneck chart   — fl_chart bar chart per inventory item
///   4. Blueprint panel    — what goes into every packed parcel
///   5. Parcel status row  — Available / Reserved / InTransit / Distributed counts
///
/// **Navigation in:** `CoordinatorDashboardScreen` → `context.push(parcelManager, extra: centerId)`
/// **FAB:** navigate to [AddStockScreen] to restock the bottleneck item.
///
/// [Fix] "Max Parcels Available" (from [InventoryProvider.maxParcels]) is
/// only ever *kit potential* — how many parcels the center's current raw
/// stock could support. It is NOT the same as an actual available parcel
/// document in the `packed_parcels` sub-collection, which is what
/// [TaskProvider.getAvailableParcelCount] and [FirebaseParcelService.
/// reserveParcels] check when a volunteer tries to accept a task. Nothing
/// in the app previously called [ParcelService.packParcels] to bridge the
/// two, so a center could show "5 parcels" everywhere a coordinator/
/// volunteer looked, while the real available-parcel count volunteers see
/// on [AcceptTaskScreen] stayed at 0 forever. The "Pack Parcels" button
/// below the banner is that missing bridge.
class ParcelManagerScreen extends StatefulWidget {
  final String centerId;

  const ParcelManagerScreen({super.key, required this.centerId});

  @override
  State<ParcelManagerScreen> createState() => _ParcelManagerScreenState();
}

class _ParcelManagerScreenState extends State<ParcelManagerScreen> {
  late final InventoryProvider _inventoryProvider;
  late final PackedParcelsProvider _parcelsProvider;
  late final BlueprintProvider _blueprintProvider;

  @override
  void initState() {
    super.initState();
    _inventoryProvider = context.read<InventoryProvider>();
    _parcelsProvider = context.read<PackedParcelsProvider>();
    _blueprintProvider = context.read<BlueprintProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inventoryProvider.listenToInventory(widget.centerId);
      _parcelsProvider.listenToParcels(widget.centerId);
      _blueprintProvider.startListening();
    });
  }

  @override
  void dispose() {
    _inventoryProvider.stopListening();
    _parcelsProvider.stopListening();
    _blueprintProvider.stopListening();
    super.dispose();
  }

  /// Packs [count] parcels — i.e. calls [PackedParcelsProvider.packParcels],
  /// which deducts [count] worth of stock per the current blueprint and
  /// creates that many real, [ParcelStatus.available] documents that
  /// volunteers can actually reserve. [count] is always
  /// `inventoryProv.maxParcels` at the moment the button is tapped (the
  /// full amount current stock can support) — see the confirm dialog below.
  Future<void> _packAvailable(int count) async {
    if (count <= 0) return;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Pack Parcels',
      message: 'Pack $count parcel${count != 1 ? 's' : ''} now?\n\n'
          'This uses up the stock needed for $count parcel${count != 1 ? 's' : ''} '
          'per the standard blueprint, and makes them available for '
          'volunteers to collect right away.',
      confirmLabel: 'Pack',
    );
    if (confirmed != true || !mounted) return;

    final ok = await _parcelsProvider.packParcels(widget.centerId, count);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$count parcel${count != 1 ? 's' : ''} packed and now available.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProv = context.watch<InventoryProvider>();
    final parcelsProv = context.watch<PackedParcelsProvider>();
    final blueprintProv = context.watch<BlueprintProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Parcel Manager'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          RouteNames.addStockPath(widget.centerId),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
      body: inventoryProv.isLoading && inventoryProv.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // ── Max Parcels Banner ──────────────────────────────────────
                _MaxParcelsBanner(
                  maxParcels: inventoryProv.maxParcels,
                  bottleneckName:
                      inventoryProv.bottleneckItem?.itemName,
                ),
                const SizedBox(height: 10),

                // ── Pack Parcels action ─────────────────────────────────────
                // Turns the kit-potential number above into real, reservable
                // packed_parcels documents. Without tapping this, "Max Parcels
                // Available" never becomes anything a volunteer can accept.
                if (parcelsProv.packError != null) ...[
                  AppErrorBanner(
                    message: parcelsProv.packError!,
                    onDismiss: parcelsProv.clearPackError,
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: (inventoryProv.maxParcels == 0 ||
                            parcelsProv.isPacking)
                        ? null
                        : () => _packAvailable(inventoryProv.maxParcels),
                    icon: parcelsProv.isPacking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.inventory_2_outlined, size: 18),
                    label: Text(
                      inventoryProv.maxParcels == 0
                          ? 'No stock to pack'
                          : 'Pack ${inventoryProv.maxParcels} Parcel'
                              '${inventoryProv.maxParcels != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.divider,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Bottleneck Bar Chart ────────────────────────────────────
                _SectionCard(
                  title: 'Inventory Kit Potential',
                  subtitle:
                      'Each bar = how many parcels that item can support. Red = bottleneck.',
                  child: inventoryProv.items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No inventory items found.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 12, right: 8),
                          child: BottleneckBarChart(
                            items: inventoryProv.items,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // ── Parcel Status Counts ────────────────────────────────────
                _SectionCard(
                  title: 'Parcel Status',
                  subtitle:
                      'Live counts across all packed parcel documents for this center.',
                  child: parcelsProv.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              ParcelCountCard(
                                label: 'Available',
                                count: parcelsProv.availableCount,
                                color: AppColors.success,
                                icon: Icons.inventory_2_outlined,
                              ),
                              const SizedBox(width: 8),
                              ParcelCountCard(
                                label: 'Reserved',
                                count: parcelsProv.reservedCount,
                                color: AppColors.warning,
                                icon: Icons.lock_outline,
                              ),
                              const SizedBox(width: 8),
                              ParcelCountCard(
                                label: 'In Transit',
                                count: parcelsProv.inTransitCount,
                                color: AppColors.primary,
                                icon: Icons.local_shipping_outlined,
                              ),
                              const SizedBox(width: 8),
                              ParcelCountCard(
                                label: 'Delivered',
                                count: parcelsProv.distributedCount,
                                color: AppColors.textSecondary,
                                icon: Icons.check_circle_outline,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // ── Standard Parcel Blueprint ───────────────────────────────
                _SectionCard(
                  title: 'Standard Parcel Blueprint',
                  subtitle:
                      'Contents of every packed parcel. Edited by admin only.',
                  child: blueprintProv.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : blueprintProv.items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No blueprint loaded.',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : Column(
                              children: [
                                // Header row
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      2, 12, 2, 6),
                                  child: Row(
                                    children: const [
                                      Expanded(
                                        flex: 5,
                                        child: Text(
                                          'ITEM',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: Text(
                                          'QTY',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.8,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          'UNIT',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                    height: 1, color: AppColors.divider),
                                ...blueprintProv.items.asMap().entries.map(
                                      (e) => BlueprintItemRow(
                                        item: e.value,
                                        showDivider: e.key <
                                            blueprintProv.items.length - 1,
                                      ),
                                    ),
                              ],
                            ),
                ),
              ],
            ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────────

class _MaxParcelsBanner extends StatelessWidget {
  final int maxParcels;
  final String? bottleneckName;

  const _MaxParcelsBanner({
    required this.maxParcels,
    this.bottleneckName,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = maxParcels == 0;
    final bannerColor = isZero ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isZero ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
            color: bannerColor,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Max Parcels Available',
                  style: TextStyle(
                    fontSize: 12,
                    color: bannerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$maxParcels',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                    height: 1.1,
                  ),
                ),
                if (bottleneckName != null)
                  Text(
                    'Bottleneck: $bottleneckName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          child,
        ],
      ),
    );
  }
}