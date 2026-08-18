// lib/screens/volunteer/center_inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/centers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/packed_parcels_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/inventory/stock_item_card.dart';

// [Fix] "Parcels Ready" below (from InventoryProvider.maxParcels) is only
// ever *kit potential* — how many parcels the center's current raw stock
// could support. It is NOT the same as an actual available parcel document
// in the `packed_parcels` sub-collection, which is what
// TaskProvider.getAvailableParcelCount and FirebaseParcelService.reserveParcels
// check when a volunteer tries to accept a task on AcceptTaskScreen. Nothing
// on this screen (or anywhere else) previously called ParcelService.packParcels
// to bridge the two, so a center could show "5 parcels ready" here and on
// MyCentersScreen while the real available-parcel count volunteers see on
// AcceptTaskScreen stayed at 0 forever — the reported bug. The "Pack Parcels"
// button added below the summary header is that missing bridge: it consumes
// the stock and creates the real, reservable parcel documents.

class CenterInventoryScreen extends StatefulWidget {
  final String centerId;
  const CenterInventoryScreen({super.key, required this.centerId});
  @override
  State<CenterInventoryScreen> createState() => _CenterInventoryScreenState();
}

class _CenterInventoryScreenState extends State<CenterInventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().listenToInventory(widget.centerId);
      context.read<CentersProvider>().loadCenter(widget.centerId);
      context.read<PackedParcelsProvider>().listenToParcels(widget.centerId);
    });
  }

  @override
  void dispose() {
    context.read<PackedParcelsProvider>().stopListening();
    super.dispose();
  }

  /// Packs [count] parcels — calls [PackedParcelsProvider.packParcels], which
  /// deducts [count] worth of stock per the current blueprint and creates
  /// that many real, available packed-parcel documents. [count] is always
  /// the current `maxParcels` (everything current stock can support) — see
  /// the confirm dialog below.
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

    final pp = context.read<PackedParcelsProvider>();
    final ok = await pp.packParcels(widget.centerId, count);
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
    final ip  = context.watch<InventoryProvider>();
    final cp  = context.watch<CentersProvider>();
    final pp  = context.watch<PackedParcelsProvider>();
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';

    // Resolve center name — try myCenters first, then viewingCenter.
    final center = cp.myCenters.where((c) => c.centerId == widget.centerId)
        .firstOrNull ?? cp.viewingCenter;

    final isMain = cp.isMainCoordinator(widget.centerId, uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        title: Text(center?.name ?? 'Inventory',
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
        actions: [
          // Previously there was no button anywhere in the app that
          // navigated to CoordinatorDashboardScreen — confirmed by
          // grepping every screen/widget file for RouteNames.coordinatorDashboard.
          // CoordinatorDashboardScreen's own docstring claimed this screen
          // linked to it ("Navigation in: CenterInventoryScreen →
          // context.push(coordinatorDashboard, ...)"), but that push did
          // not exist in this file. A coordinator landing here had no way
          // to reach the pending-collections / confirm-collection screen
          // at all — this button is that missing link.
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_outlined),
            tooltip: 'Coordinator Dashboard',
            onPressed: () => context.push(
              RouteNames.coordinatorDashboard,
              extra: widget.centerId,
            ),
          ),
          if (isMain)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: 'Manage Sub Coordinators',
              onPressed: () => context.push(
                RouteNames.manageSubCoordinators,
                extra: widget.centerId,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_stock_fab',
        onPressed: () => context.push(RouteNames.addStockPath(widget.centerId)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add), label: const Text('Add Stock'),
      ),
      body: ip.isLoading && ip.items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ip.error != null && ip.items.isEmpty
              ? Center(child: AppErrorWidget(message: ip.error!))
              : Column(
                  children: [
                    // Summary header
                    _SummaryHeader(maxParcels: ip.maxParcels,
                        bottleneckName: ip.bottleneckItem?.itemName),

                    // ── Pack Parcels action ─────────────────────────────
                    // Turns "Parcels Ready" (kit potential) above into real,
                    // reservable packed_parcels documents. Without tapping
                    // this, that number never becomes anything a volunteer
                    // can actually accept a task against.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          if (pp.packError != null) ...[
                            AppErrorBanner(
                              message: pp.packError!,
                              onDismiss: pp.clearPackError,
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed:
                                  (ip.maxParcels == 0 || pp.isPacking)
                                      ? null
                                      : () => _packAvailable(ip.maxParcels),
                              icon: pp.isPacking
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Icon(Icons.inventory_2_outlined,
                                      size: 18),
                              label: Text(
                                ip.maxParcels == 0
                                    ? 'No stock to pack'
                                    : 'Pack ${ip.maxParcels} Parcel'
                                        '${ip.maxParcels != 1 ? 's' : ''}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
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
                        ],
                      ),
                    ),

                    if (ip.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: AppErrorBanner(message: ip.error!),
                      ),

                    Expanded(
                      child: ip.items.isEmpty
                          ? const EmptyStateWidget(
                              icon: Icons.inventory_2_outlined,
                              title: 'No inventory items',
                              subtitle: 'Add stock to start tracking inventory.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 90),
                              itemCount: ip.items.length,
                              itemBuilder: (ctx, i) => StockItemCard(
                                item: ip.items[i],
                                onAddStock: () => context.push(
                                    RouteNames.addStockPath(widget.centerId)),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int maxParcels;
  final String? bottleneckName;
  const _SummaryHeader({required this.maxParcels, this.bottleneckName});

  @override
  Widget build(BuildContext context) {
    final pc = maxParcels >= 10 ? AppColors.success
        : maxParcels > 0 ? AppColors.warning : AppColors.error;
    final hasBottleneck = bottleneckName != null;
    final bc = hasBottleneck ? AppColors.error : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pc.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pc.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Text('$maxParcels', style: TextStyle(fontSize: 32,
                      fontWeight: FontWeight.bold, color: pc)),
                  const Text('Parcels Ready',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bc.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bc.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    hasBottleneck ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: bc, size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasBottleneck ? 'Low: $bottleneckName' : 'Balanced',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: bc),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}