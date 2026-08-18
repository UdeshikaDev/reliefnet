// lib/widgets/task/delivery_step_indicator.dart

import 'package:flutter/material.dart';
import '../../core/enums/task_status.dart';
import '../../core/constants/app_colors.dart';

/// Vertical 4-step delivery progress indicator.
///
/// Steps:
///   1. Go to Center     (status: reserved, not coordinator confirmed)
///   2. Collect Parcels  (status: reserved + coordinatorConfirmed, or coordinatorConfirmed)
///   3. Deliver          (status: inTransit)
///   4. Done             (status: delivered)
///
/// The active step is highlighted; completed steps show a check circle.
class DeliveryStepIndicator extends StatelessWidget {
  final TaskStatus status;
  final bool isCoordinatorConfirmed;

  const DeliveryStepIndicator({
    super.key,
    required this.status,
    required this.isCoordinatorConfirmed,
  });

  // Which step index (0-based) is currently active.
  int get _activeStep {
    return switch (status) {
      TaskStatus.reserved => isCoordinatorConfirmed ? 1 : 0,
      TaskStatus.coordinatorConfirmed => 1,
      TaskStatus.inTransit => 2,
      TaskStatus.delivered => 3,
      TaskStatus.cancelled => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
        label: 'Go to Center',
        sublabel: 'Head to the donation center',
        icon: Icons.warehouse_outlined,
      ),
      _StepData(
        label: 'Collect Parcels',
        sublabel: isCoordinatorConfirmed
            ? 'Coordinator confirmed — collect your parcels'
            : 'Waiting for coordinator confirmation',
        icon: Icons.inventory_2_outlined,
      ),
      _StepData(
        label: 'Deliver',
        sublabel: 'Head to the victim\'s location',
        icon: Icons.directions_bike_outlined,
      ),
      _StepData(
        label: 'Done',
        sublabel: 'Delivery confirmed — receipt sealed',
        icon: Icons.check_circle_outline,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final isActive = i == _activeStep;
        final isDone = i < _activeStep ||
            status == TaskStatus.delivered;
        final isLast = i == steps.length - 1;
        return _StepRow(
          data: steps[i],
          isActive: isActive,
          isDone: isDone,
          isLast: isLast,
        );
      }),
    );
  }
}

class _StepData {
  final String label;
  final String sublabel;
  final IconData icon;
  const _StepData({
    required this.label,
    required this.sublabel,
    required this.icon,
  });
}

class _StepRow extends StatelessWidget {
  final _StepData data;
  final bool isActive;
  final bool isDone;
  final bool isLast;

  const _StepRow({
    required this.data,
    required this.isActive,
    required this.isDone,
    required this.isLast,
  });

  Color get _circleColor {
    if (isDone) return AppColors.success;
    if (isActive) return AppColors.primary;
    return AppColors.divider;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Step circle + connector line ──────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? Icons.check : data.icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone ? AppColors.success : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Step label + sublabel ─────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? AppColors.textPrimary
                          : isDone
                              ? AppColors.success
                              : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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