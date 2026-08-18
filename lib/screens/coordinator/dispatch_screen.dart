// lib/screens/coordinator/dispatch_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/delivery_task_model.dart';
import '../../models/user_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';

/// Lists all active tasks for this center and lets the coordinator
/// confirm that each volunteer has physically collected their parcel(s).
///
/// Shows two sections:
///   - **Awaiting Confirmation** — tasks where [isCoordinatorConfirmed] == false
///   - **Coordinator Confirmed** — tasks where [isCoordinatorConfirmed] == true (in transit)
///
/// **Navigation in:** `CoordinatorDashboardScreen` → `context.push(dispatch, extra: centerId)`
class DispatchScreen extends StatefulWidget {
  final String centerId;

  const DispatchScreen({super.key, required this.centerId});

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  late final TaskProvider _taskProvider;

  @override
  void initState() {
    super.initState();
    _taskProvider = context.read<TaskProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskProvider.loadTasksForCenter(widget.centerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final pending = taskProvider.pendingConfirmationTasks;
    final confirmed = taskProvider.centerTasks
        .where((t) => t.isCoordinatorConfirmed)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Dispatch'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                _taskProvider.loadTasksForCenter(widget.centerId),
          ),
        ],
      ),
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  _taskProvider.loadTasksForCenter(widget.centerId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Awaiting Confirmation ─────────────────────────────────
                  _SectionHeader(
                    title: 'Awaiting Confirmation',
                    count: pending.length,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 8),
                  if (pending.isEmpty)
                    _EmptySection(
                      icon: Icons.check_circle_outline,
                      message: 'No pending confirmations.',
                    )
                  else
                    ...pending.map(
                      (task) => _DispatchTaskCard(task: task),
                    ),
                  const SizedBox(height: 24),

                  // ── Already Confirmed / In Transit ────────────────────────
                  _SectionHeader(
                    title: 'In Transit',
                    count: confirmed.length,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  if (confirmed.isEmpty)
                    _EmptySection(
                      icon: Icons.local_shipping_outlined,
                      message: 'No parcels currently in transit.',
                    )
                  else
                    ...confirmed.map(
                      (task) => _DispatchTaskCard(task: task, isConfirmed: true),
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
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _DispatchTaskCard extends StatelessWidget {
  final DeliveryTaskModel task;
  final bool isConfirmed;

  const _DispatchTaskCard({
    required this.task,
    this.isConfirmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isConfirmed
        ? AppColors.primary.withOpacity(0.3)
        : AppColors.warning.withOpacity(0.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      // Previously the only action here was an inline "Confirm Volunteer
      // Collecting" dialog with no victim details and only the volunteer's
      // raw UID visible. Now the whole card opens ConfirmCollectionScreen,
      // which shows full volunteer + victim + request details — for
      // already-confirmed tasks it opens the same screen in its read-only
      // "Already Confirmed" state, so this doubles as a details view for
      // in-transit tasks too, not just a confirm action for pending ones.
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            context.push(RouteNames.confirmCollectionPath(task.taskId)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    isConfirmed
                        ? Icons.local_shipping_outlined
                        : Icons.hourglass_empty_rounded,
                    size: 16,
                    color: isConfirmed ? AppColors.primary : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Task · ${task.parcelsCount} parcel${task.parcelsCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isConfirmed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'In Transit',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Volunteer name
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  const Text(
                    'Volunteer: ',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  FutureBuilder<UserModel?>(
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
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isConfirmed ? 'View Details' : 'View Details & Confirm',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}