// lib/widgets/request/status_timeline.dart

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/request_status.dart';

/// Vertical timeline that shows the 5-stage delivery lifecycle.
///
/// Each step is either: done (filled green), current (pulsing primary),
/// or upcoming (outlined grey).
///
/// Pass [currentStatus] from [ReliefRequestModel.status] and the widget
/// computes which stages are done/active/pending automatically.
class StatusTimeline extends StatelessWidget {
  final RequestStatus currentStatus;

  const StatusTimeline({super.key, required this.currentStatus});

  // ── Stage definitions ─────────────────────────────────────────────────────

  static const _stages = [
    _Stage(
      status: RequestStatus.pending,
      label: 'Request Submitted',
      subtitle: 'Waiting for a volunteer to accept',
      icon: Icons.upload_rounded,
    ),
    _Stage(
      status: RequestStatus.accepted,
      label: 'Volunteer Assigned',
      subtitle: 'Volunteer is preparing to collect your parcels',
      icon: Icons.person_pin_circle_outlined,
    ),
    _Stage(
      status: RequestStatus.collecting,
      label: 'Parcels Being Collected',
      subtitle: 'Volunteer is at the donation center',
      icon: Icons.inventory_2_outlined,
    ),
    _Stage(
      status: RequestStatus.delivering,
      label: 'On the Way',
      subtitle: 'Volunteer is heading to your location',
      icon: Icons.local_shipping_outlined,
    ),
    _Stage(
      status: RequestStatus.completed,
      label: 'Delivered',
      subtitle: 'Parcels handed over successfully',
      icon: Icons.check_circle_outline,
    ),
  ];

  // ── Status ordering (active delivery path only) ───────────────────────────

  static const _order = [
    RequestStatus.pending,
    RequestStatus.accepted,
    RequestStatus.collecting,
    RequestStatus.delivering,
    RequestStatus.completed,
  ];

  _StepState _stateFor(RequestStatus stageStatus) {
    // Terminal non-delivery states
    if (currentStatus == RequestStatus.cancelled ||
        currentStatus == RequestStatus.expired) {
      return _StepState.upcoming;
    }

    final currentIdx = _order.indexOf(currentStatus);
    final stageIdx = _order.indexOf(stageStatus);

    if (stageIdx < 0 || currentIdx < 0) return _StepState.upcoming;
    if (stageIdx < currentIdx) return _StepState.done;
    if (stageIdx == currentIdx) return _StepState.current;
    return _StepState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    // Show cancellation / expiry banner instead of timeline
    if (currentStatus == RequestStatus.cancelled ||
        currentStatus == RequestStatus.expired) {
      return _TerminalBanner(status: currentStatus);
    }

    return Column(
      children: List.generate(_stages.length, (i) {
        final stage = _stages[i];
        final state = _stateFor(stage.status);
        final isLast = i == _stages.length - 1;
        return _TimelineRow(
          stage: stage,
          state: state,
          showConnector: !isLast,
        );
      }),
    );
  }
}

// ── Supporting types and widgets ──────────────────────────────────────────────

enum _StepState { done, current, upcoming }

class _Stage {
  final RequestStatus status;
  final String label;
  final String subtitle;
  final IconData icon;

  const _Stage({
    required this.status,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

class _TimelineRow extends StatelessWidget {
  final _Stage stage;
  final _StepState state;
  final bool showConnector;

  const _TimelineRow({
    required this.stage,
    required this.state,
    required this.showConnector,
  });

  Color get _circleColor {
    return switch (state) {
      _StepState.done    => AppColors.success,
      _StepState.current => AppColors.primary,
      _StepState.upcoming => AppColors.divider,
    };
  }

  Color get _labelColor {
    return switch (state) {
      _StepState.done    => AppColors.success,
      _StepState.current => AppColors.primary,
      _StepState.upcoming => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: circle + connector line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: state == _StepState.upcoming
                        ? AppColors.surfaceAlt
                        : _circleColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _circleColor,
                      width: state == _StepState.current ? 2.5 : 1.5,
                    ),
                  ),
                  child: Icon(
                    state == _StepState.done
                        ? Icons.check_rounded
                        : stage.icon,
                    size: 18,
                    color: state == _StepState.upcoming
                        ? AppColors.textHint
                        : _circleColor,
                  ),
                ),
                // Connector
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: state == _StepState.done
                          ? AppColors.success.withValues(alpha: 0.30)
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Right: label + subtitle
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: showConnector ? 24 : 0,
                top: 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stage.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: state == _StepState.current
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _labelColor,
                        ),
                      ),
                      if (state == _StepState.current) ...[
                        const SizedBox(width: 8),
                        _PulsingDot(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stage.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
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

/// Small animated dot shown next to the current active step.
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Shown for cancelled or expired requests instead of the stage steps.
class _TerminalBanner extends StatelessWidget {
  final RequestStatus status;

  const _TerminalBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == RequestStatus.cancelled;
    final color = isCancelled ? AppColors.error : AppColors.textSecondary;
    final icon = isCancelled ? Icons.cancel_outlined : Icons.timer_off_outlined;
    final label = isCancelled ? 'Request Cancelled' : 'Request Expired';
    final sub = isCancelled
        ? 'You cancelled this request.'
        : 'This request expired without a volunteer accepting it. Please submit a new request.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
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