// lib/widgets/task/task_card.dart
// COMPLETE REPLACEMENT — adds showCta parameter + navigation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/task_status.dart';
import '../../models/delivery_task_model.dart';
import '../../router/route_names.dart';

/// Compact card showing a single delivery task's summary.
///
/// [showCta] = true  → active task card (tappable, shows "Continue Delivery" button)
///                     used by [VolunteerHomeScreen]
/// [showCta] = false → history card (read-only display)
///                     used by [TaskHistoryScreen]
///
/// [onTap] overrides the default navigation when provided.
class TaskCard extends StatelessWidget {
  final DeliveryTaskModel task;

  /// When true, the card is tappable and shows a CTA button to navigate
  /// to [ActiveTaskScreen]. Set false for history/read-only display.
  final bool showCta;

  /// Optional custom tap handler. When null and [showCta] is true,
  /// defaults to navigating to [RouteNames.activeTaskPath].
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.showCta = false,
    this.onTap,
  });

  Color get _statusColor {
    return switch (task.status) {
      TaskStatus.reserved          => AppColors.warning,
      TaskStatus.coordinatorConfirmed => AppColors.warning,
      TaskStatus.inTransit         => AppColors.primary,
      TaskStatus.delivered         => AppColors.success,
      TaskStatus.cancelled         => AppColors.textSecondary,
    };
  }

  String get _statusLabel {
    return switch (task.status) {
      TaskStatus.reserved =>
          task.isCoordinatorConfirmed ? 'Ready to Collect' : 'Awaiting Coordinator',
      TaskStatus.coordinatorConfirmed => 'Ready to Collect',
      TaskStatus.inTransit            => 'Delivering',
      TaskStatus.delivered            => 'Delivered',
      TaskStatus.cancelled            => 'Cancelled',
    };
  }

  String get _ctaLabel {
    return switch (task.status) {
      TaskStatus.reserved =>
          task.isCoordinatorConfirmed ? 'Collect Parcels →' : 'Go to Center →',
      TaskStatus.coordinatorConfirmed => 'Collect Parcels →',
      TaskStatus.inTransit            => 'Confirm Delivery →',
      TaskStatus.delivered            => 'View Receipt →',
      TaskStatus.cancelled            => 'View Details →',
    };
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    // Default: navigate to ActiveTaskScreen
    context.push(RouteNames.activeTaskPath(task.taskId));
  }

  @override
  Widget build(BuildContext context) {
    // Previously this was `showCta ? () => _handleTap(context) : null` —
    // meaning a custom onTap passed in by a caller (this class's own doc
    // comment: "[onTap] overrides the default navigation when provided")
    // was silently inert whenever showCta was false. TaskHistoryScreen
    // renders every card with showCta: false, so history cards were never
    // tappable at all, regardless of whether an onTap was supplied —
    // there was no way to see more than the compact summary this card
    // shows (no center, no victim, no receipt link). Tappability is now
    // based on whether there's anything to do (showCta OR a custom onTap
    // provided), not on showCta alone.
    final isTappable = showCta || onTap != null;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: showCta ? _statusColor.withOpacity(0.35) : AppColors.divider,
          width: showCta ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: isTappable ? () => _handleTap(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: task ID + status chip ─────────────────────────
              Row(
                children: [
                  // Status dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Task #${_shortId(task.taskId)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  if (isTappable && !showCta) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // ── Parcel count + time ─────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${task.parcelsCount} parcel${task.parcelsCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.updatedAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              // ── CTA button (active tasks only) ──────────────────────────
              if (showCta) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Coordinator status hint
                    if (task.status == TaskStatus.reserved &&
                        !task.isCoordinatorConfirmed)
                      const Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 13, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text(
                            'Waiting for coordinator',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.warning),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),

                    // CTA text button
                    Text(
                      _ctaLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(id.length - 8) : id;

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}