// lib/screens/volunteer/my_centers_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_center_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/centers_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class MyCentersScreen extends StatefulWidget {
  const MyCentersScreen({super.key});
  @override
  State<MyCentersScreen> createState() => _MyCentersScreenState();
}

class _MyCentersScreenState extends State<MyCentersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<CentersProvider>().listenToCentersForUser(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp  = context.watch<CentersProvider>();
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        title: const Text('My Centers', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'register_fab',
        onPressed: () => context.push(RouteNames.registerCenter),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add), label: const Text('Register Center'),
      ),
      body: cp.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : cp.error != null
              ? Center(child: AppErrorWidget(message: cp.error!))
              : cp.myCenters.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.store_outlined,
                      title: 'No centers yet',
                      subtitle: 'Register a donation center to start managing stock.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        context.read<CentersProvider>().listenToCentersForUser(uid);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: cp.myCenters.length,
                        itemBuilder: (ctx, i) => _CenterCard(
                          center: cp.myCenters[i],
                          isMain: cp.isMainCoordinator(cp.myCenters[i].centerId, uid),
                        ),
                      ),
                    ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  final DonationCenterModel center;
  final bool isMain;
  const _CenterCard({required this.center, required this.isMain});

  @override
  Widget build(BuildContext context) {
    // [Fix — architectural] "ready" now genuinely means ready: this reads
    // DonationCenterModel.availableParcels (the real, live count of
    // packed_parcels docs with status == available), not the old
    // maxParcelsAvailable (renamed packingCapacity) — raw-stock kit
    // potential that was never actually packed into real parcels.
    final pc = center.availableParcels >= 10 ? AppColors.success
        : center.availableParcels > 0 ? AppColors.warning : AppColors.error;

    return GestureDetector(
      onTap: () => context.push(RouteNames.centerInventoryPath(center.centerId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.store, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(center.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMain ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isMain ? 'Main Coord.' : 'Sub Coord.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                            color: isMain ? AppColors.primary : AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(center.address,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: pc),
                        const SizedBox(width: 5),
                        Text('${center.availableParcels} parcels ready',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pc)),
                      ],
                    ),
                  ),
                  // Extra kit potential sitting in raw stock that hasn't
                  // been packed into real parcels yet — nudges the
                  // coordinator/volunteer toward CenterInventoryScreen's
                  // "Pack Parcels" action instead of assuming stock alone
                  // means something is ready to hand out. Skipped when a
                  // bottleneck warning is already showing in this Row, to
                  // avoid crowding/overflow on narrow screens.
                  if (center.bottleneckItem == null &&
                      center.packingCapacity > center.availableParcels) ...[
                    const SizedBox(width: 8),
                    Text(
                      '+${center.packingCapacity - center.availableParcels} packable',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                  if (center.bottleneckItem != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.warning_amber_outlined,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('Low: ${center.bottleneckItem}',
                        style: const TextStyle(fontSize: 12, color: AppColors.warning)),
                  ],
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}