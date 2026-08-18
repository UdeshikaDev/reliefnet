// lib/widgets/request/request_card.dart

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/request_status.dart';
import '../../models/relief_request_model.dart';

/// A compact card summarising a [ReliefRequestModel].
///
/// Used in [MyRequestsScreen] (history list) and as the active-request
/// preview card on [VictimHomeScreen].
///
/// [onTap] navigates to [RequestDetailScreen].
class RequestCard extends StatelessWidget {
  final ReliefRequestModel request;
  final VoidCallback? onTap;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status icon
            _StatusIcon(status: request.status),
            const SizedBox(width: 14),

            // Request info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusBadge(status: request.status),
                      const Spacer(),
                      Text(
                        _formatDate(request.submittedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Family of ${request.familySize} · ${request.parcelsEntitled} parcel${request.parcelsEntitled == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (request.assignedVolunteerUid != null)
                    const Text(
                      'Volunteer assigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    )
                  else
                    const Text(
                      'Waiting for volunteer',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Chevron
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final RequestStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      RequestStatus.pending    => (Icons.hourglass_top_rounded, AppColors.warning),
      RequestStatus.accepted   => (Icons.person_pin_circle_outlined, AppColors.primary),
      RequestStatus.collecting => (Icons.inventory_2_outlined, AppColors.primary),
      RequestStatus.delivering => (Icons.local_shipping_outlined, AppColors.primary),
      RequestStatus.completed  => (Icons.check_circle_outline, AppColors.success),
      RequestStatus.expired    => (Icons.timer_off_outlined, AppColors.textSecondary),
      RequestStatus.cancelled  => (Icons.cancel_outlined, AppColors.error),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

/// Pill badge with colour-coded label.
class _StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RequestStatus.pending    => ('Pending', AppColors.warning),
      RequestStatus.accepted   => ('Accepted', AppColors.primary),
      RequestStatus.collecting => ('Collecting', AppColors.primary),
      RequestStatus.delivering => ('Delivering', AppColors.primary),
      RequestStatus.completed  => ('Completed', AppColors.success),
      RequestStatus.expired    => ('Expired', AppColors.textSecondary),
      RequestStatus.cancelled  => ('Cancelled', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}