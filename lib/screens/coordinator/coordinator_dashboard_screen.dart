// lib/screens/coordinator/coordinator_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/delivery_task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/centers_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';

/// Hub screen for a coordinator managing one donation center.
///
/// **Data sources:**
/// - [CentersProvider] — center name, role check (main vs sub coordinator)
/// - [TaskProvider]    — pending collection tasks (isCoordinatorConfirmed == false)
///
/// **Navigation in:**  `CenterInventoryScreen` → `context.push(coordinatorDashboard, extra: centerId)`
/// **Navigation out:** sub-screens use `context.push()` so back button returns here.
class CoordinatorDashboardScreen extends StatefulWidget {
  final String centerId;

  const CoordinatorDashboardScreen({super.key, required this.centerId});

  @override
  State<CoordinatorDashboardScreen> createState() =>
      _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState
    extends State<CoordinatorDashboardScreen> {
  late final CentersProvider _centersProvider;
  late final TaskProvider _taskProvider;

  @override
  void initState() {
    super.initState();
    _centersProvider = context.read<CentersProvider>();
    _taskProvider = context.read<TaskProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centersProvider.loadCenter(widget.centerId);
      _taskProvider.loadTasksForCenter(widget.centerId);
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      _centersProvider.loadCenter(widget.centerId),
      _taskProvider.loadTasksForCenter(widget.centerId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final centersProvider = context.watch<CentersProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final authProvider = context.watch<AuthProvider>();
    final center = centersProvider.viewingCenter;
    final uid = authProvider.currentUser?.uid ?? '';

    final isMainCoord = center != null
        ? centersProvider.isMainCoordinator(widget.centerId, uid)
        : false;
    final pendingTasks = taskProvider.pendingConfirmationTasks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(center?.name ?? 'Coordinator Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: centersProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Summary Cards ─────────────────────────────────────────
                  Row(
                    children: [
                      // [Fix — architectural] "Max Parcels" used to read
                      // maxParcelsAvailable — raw-stock kit potential, not
                      // an actual parcel count. A coordinator glancing at
                      // their dashboard cares first about what's actually
                      // ready to hand a volunteer, so this now shows the
                      // real, live availableParcels count. Packing
                      // capacity is still visible one tap away, via the
                      // Parcel Manager action below.
                      _SummaryCard(
                        label: 'Available Parcels',
                        value:
                            '${center?.availableParcels ?? 0}',
                        color: AppColors.success,
                        icon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        label: 'Pending Tasks',
                        value: '${pendingTasks.length}',
                        color: pendingTasks.isNotEmpty
                            ? AppColors.warning
                            : AppColors.success,
                        icon: Icons.assignment_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Quick Actions ─────────────────────────────────────────
                  _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.primary,
                    label: 'Parcel Manager',
                    subtitle: 'Bottleneck chart, blueprint & parcel counts',
                    onTap: () => context.push(
                      RouteNames.parcelManager,
                      extra: widget.centerId,
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.local_shipping_outlined,
                    iconColor: AppColors.warning,
                    label: 'Dispatch Parcels',
                    subtitle: 'Confirm volunteer collections',
                    badge: pendingTasks.isNotEmpty
                        ? '${pendingTasks.length}'
                        : null,
                    onTap: () => context.push(
                      RouteNames.dispatch,
                      extra: widget.centerId,
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.history_outlined,
                    iconColor: AppColors.textSecondary,
                    label: 'Stock Log',
                    subtitle: 'All inventory add / deduct activity',
                    onTap: () => context.push(
                      RouteNames.stockLog,
                      extra: widget.centerId,
                    ),
                  ),
                  if (isMainCoord)
                    _ActionTile(
                      icon: Icons.group_outlined,
                      iconColor: AppColors.success,
                      label: 'Sub Coordinators',
                      subtitle: 'Add or remove sub coordinators',
                      onTap: () => context.push(
                        RouteNames.manageSubCoordinators,
                        extra: widget.centerId,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Pending Collection Tasks ──────────────────────────────
                  _SectionHeader(
                    title: 'Pending Collections (${pendingTasks.length})',
                  ),
                  const SizedBox(height: 8),
                  if (taskProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (pendingTasks.isEmpty)
                    _EmptyTasksCard()
                  else
                    ...pendingTasks.map(
                      (task) => _TaskCard(task: task),
                    ),
                ],
              ),
            ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: badge != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ],
              )
            : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DeliveryTaskModel task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      // Previously this card's "Confirm Volunteer Collecting" button opened
      // an inline dialog directly — with no victim details and only the
      // volunteer's raw UID visible anywhere. It now opens
      // ConfirmCollectionScreen, which shows full volunteer + victim +
      // request details before the coordinator confirms.
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            context.push(RouteNames.confirmCollectionPath(task.taskId)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_ind_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Task #${task.taskId.substring(task.taskId.length > 8 ? task.taskId.length - 8 : 0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Awaiting Confirmation',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _TaskRow(
                icon: Icons.person_outline,
                label: 'Volunteer',
                valueWidget: FutureBuilder<UserModel?>(
                  future: context
                      .read<UserProvider>()
                      .fetchUserById(task.volunteerUid),
                  builder: (ctx, snap) {
                    final name = snap.data?.displayName ??
                        (snap.connectionState == ConnectionState.waiting
                            ? '…'
                            : task.volunteerUid);
                    return Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              _TaskRow(
                icon: Icons.inventory_2_outlined,
                label: 'Parcels',
                value: '${task.parcelsCount}',
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details & Confirm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _TaskRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
      ],
    );
  }
}

class _EmptyTasksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 40, color: AppColors.success),
          SizedBox(height: 10),
          Text(
            'All collections confirmed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No volunteers pending confirmation at this center.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}