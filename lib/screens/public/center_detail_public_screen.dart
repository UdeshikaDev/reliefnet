import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_center_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

/// Bottom-sheet detail view for a single donation center.
/// Read-only — shown to public (guest) users.
class CenterDetailPublicScreen extends StatefulWidget {
  final DonationCenterModel center;

  const CenterDetailPublicScreen({super.key, required this.center});

  @override
  State<CenterDetailPublicScreen> createState() =>
      _CenterDetailPublicScreenState();
}

class _CenterDetailPublicScreenState extends State<CenterDetailPublicScreen> {
  UserModel? _mainCoordinator;
  List<UserModel> _subCoordinators = [];
  bool _isLoadingCoordinators = true;

  // ── Blueprint items hardcoded for Phase 1 ─────────────────────────────────
  static const List<_BlueprintItem> _blueprintItems = [
    _BlueprintItem(name: 'Dehydrated Rice', qty: '2.0 kg'),
    _BlueprintItem(name: 'Sugar', qty: '0.5 kg'),
    _BlueprintItem(name: 'Dhal', qty: '1.0 kg'),
    _BlueprintItem(name: 'Milk Powder', qty: '0.4 kg'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCoordinators();
  }

  // ── Async data loading ─────────────────────────────────────────────────────

  Future<void> _loadCoordinators() async {
    final userProvider = context.read<UserProvider>();

    final main =
        await userProvider.fetchUserById(widget.center.mainCoordinatorUid);

    final subFutures = widget.center.subCoordinatorUids
        .map((uid) => userProvider.fetchUserById(uid))
        .toList();
    final subResults = await Future.wait(subFutures);

    if (mounted) {
      setState(() {
        _mainCoordinator = main;
        _subCoordinators = subResults.whereType<UserModel>().toList();
        _isLoadingCoordinators = false;
      });
    }
  }

  // ── Availability helpers ───────────────────────────────────────────────────
  //
  // [Fix — architectural] Read availableParcels (real, live "ready right
  // now" count) rather than the old maxParcelsAvailable (renamed
  // DonationCenterModel.packingCapacity) — raw-stock kit potential. A
  // victim or volunteer viewing this public detail screen needs to know
  // what's actually available to collect, not how much stock theoretically
  // could be packed.

  Color get _availabilityColor {
    if (widget.center.availableParcels >= 10) return AppColors.success;
    if (widget.center.availableParcels > 0) return AppColors.warning;
    return AppColors.error;
  }

  String get _availabilityLabel {
    if (widget.center.availableParcels >= 10) return 'Well Stocked';
    if (widget.center.availableParcels > 0) return 'Low Stock';
    return 'Out of Stock';
  }

  IconData get _availabilityIcon {
    if (widget.center.availableParcels >= 10) {
      return Icons.check_circle_outline;
    }
    if (widget.center.availableParcels > 0) {
      return Icons.warning_amber_outlined;
    }
    return Icons.cancel_outlined;
  }

    // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _callUser(UserModel user) async {
    final uri = Uri.parse('tel:${user.phone}');
    try {
      // ★ Skip canLaunchUrl — it's unreliable for tel: on Android 11+.
      // The OS will resolve the dialer directly.
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the dialer. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _smsUser(UserModel user) async {
    final uri = Uri.parse('sms:${user.phone}');
    try {
      // ★ Skip canLaunchUrl — it's unreliable for sms: on Android 11+.
      // The OS will resolve the SMS app directly.
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the messaging app. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.center.lat},${widget.center.lng}',
    );
    try {
      // ★ externalApplication forces Google Maps / browser instead of a WebView
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildAddressRow(),
                  const SizedBox(height: 16),
                  _buildCoordinatorSection(),
                  const SizedBox(height: 16),
                  _buildStockStatus(),
                  const SizedBox(height: 16),
                  _buildBlueprintSection(),
                  const SizedBox(height: 16),
                  _buildAllocationNote(),
                  const SizedBox(height: 24),
                  _buildDirectionsButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drag Handle ────────────────────────────────────────────────────────────

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.center.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        FittedBox(
          child: _AvailabilityBadge(
            label: _availabilityLabel,
            color: _availabilityColor,
            icon: _availabilityIcon,
          ),
        ),
      ],
    );
  }

  // ── Address ────────────────────────────────────────────────────────────────

  Widget _buildAddressRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined,
            size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.center.address,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Coordinator Section ────────────────────────────────────────────────────

  Widget _buildCoordinatorSection() {
    if (_isLoadingCoordinators) return _buildCoordinatorSkeleton();

    final allCoordinators = <_CoordinatorEntry>[];
    if (_mainCoordinator != null) {
      allCoordinators
          .add(_CoordinatorEntry(user: _mainCoordinator!, isMain: true));
    }
    for (final sub in _subCoordinators) {
      allCoordinators.add(_CoordinatorEntry(user: sub, isMain: false));
    }

    if (allCoordinators.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              allCoordinators.length > 1 ? 'COORDINATORS' : 'COORDINATOR',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...List.generate(allCoordinators.length, (i) {
            final entry = allCoordinators[i];
            final isLast = i == allCoordinators.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCoordinatorRow(
                  entry.user,
                  isMain: entry.isMain,
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCoordinatorRow(UserModel user, {bool isMain = true}) {
    return Row(
      children: [
        // ── Avatar ──
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isMain
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isMain
                ? Icons.person_outline_rounded
                : Icons.people_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // ── Name + role ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMain ? 'Main Coordinator' : 'Sub-Coordinator',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                user.displayName ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // ── Message button ──
        Material(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _smsUser(user),
            borderRadius: BorderRadius.circular(10),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.message_outlined,
                color: AppColors.primary,
                size: 17,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // ── Call button ──
        Material(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _callUser(user),
            borderRadius: BorderRadius.circular(10),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.call_rounded,
                color: AppColors.success,
                size: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Shimmer-like placeholder while coordinator data loads.
  Widget _buildCoordinatorSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Skeleton message button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 6),
          // Skeleton call button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stock Status ───────────────────────────────────────────────────────────

  Widget _buildStockStatus() {
    if (widget.center.bottleneckItem != null) {
      return _buildCriticalItemCard();
    }
    return _buildWellStockedCard();
  }

  Widget _buildCriticalItemCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Critical Item Needed',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.center.bottleneckItem!,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.error,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This item is critically low. Donating it will directly '
            'increase the number of relief parcels available for victims.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellStockedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'All items are currently well stocked at this center.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Blueprint Preview ──────────────────────────────────────────────────────

  Widget _buildBlueprintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Standard Parcel Contents',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Every parcel contains the following items.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _blueprintItems
                .map((item) => _BlueprintRow(item: item))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Allocation Note ────────────────────────────────────────────────────────

  Widget _buildAllocationNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Parcels are allocated based on family size: '
              '1 parcel per 3 family members (rounded up). ',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Directions Button ──────────────────────────────────────────────────────

  Widget _buildDirectionsButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _openDirections,
        icon: const Icon(Icons.directions_rounded, size: 20),
        label: const Text(
          'Get Directions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Supporting Classes & Widgets ──────────────────────────────────────────────

class _CoordinatorEntry {
  final UserModel user;
  final bool isMain;
  const _CoordinatorEntry({required this.user, required this.isMain});
}

class _AvailabilityBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _AvailabilityBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _BlueprintItem {
  final String name;
  final String qty;
  const _BlueprintItem({required this.name, required this.qty});
}

class _BlueprintRow extends StatelessWidget {
  final _BlueprintItem item;

  const _BlueprintRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.qty,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}