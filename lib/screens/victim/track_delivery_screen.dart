// lib/screens/victim/track_delivery_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/request_status.dart';
import '../../providers/request_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/request/status_timeline.dart';

/// Real-time delivery tracking screen.
///
/// Subscribes to [RequestProvider.activeRequest] stream (already started on
/// [VictimHomeScreen]). Status updates from the volunteer automatically
/// re-render the [StatusTimeline] without any user action.
///
/// Shows "Show QR Code" button when status is collecting or delivering.
class TrackDeliveryScreen extends StatelessWidget {
  final String requestId;

  const TrackDeliveryScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final reqProv = context.watch<RequestProvider>();

    // Accept either the streamed active request or the last known one.
    final request = (reqProv.activeRequest?.requestId == requestId)
        ? reqProv.activeRequest
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Track Delivery',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: request == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading your request status…',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status banner ──────────────────────────────────────
                  _StatusBanner(status: request.status),

                  const SizedBox(height: 24),

                  // ── Timeline ───────────────────────────────────────────
                  const Text(
                    'Delivery Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatusTimeline(currentStatus: request.status),

                  const SizedBox(height: 28),

                  // ── QR code CTA ────────────────────────────────────────
                  if (request.status == RequestStatus.delivering ||
                      request.status == RequestStatus.collecting) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code_2_outlined,
                              size: 40, color: AppColors.success),
                          const SizedBox(height: 12),
                          const Text(
                            'Volunteer is on the way!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Please have your QR code ready. '
                            'The volunteer will scan it to confirm delivery.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => context
                                  .push(RouteNames.victimQrPath(requestId)),
                              icon: const Icon(Icons.qr_code_2, size: 20),
                              label: const Text('Show QR Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Completed state ────────────────────────────────────
                  if (request.status == RequestStatus.completed)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 48, color: AppColors.success),
                          SizedBox(height: 12),
                          Text(
                            'Delivery Complete!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your parcels have been delivered. '
                            'Thank you for using ReliefNet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ── Supporting widget ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final RequestStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, sub, color, icon) = switch (status) {
      RequestStatus.pending => (
          'Waiting for Volunteer',
          'Your request has been submitted and is visible to volunteers.',
          AppColors.warning,
          Icons.hourglass_top_rounded,
        ),
      RequestStatus.accepted => (
          'Volunteer Accepted',
          'A volunteer has accepted your request and is preparing.',
          AppColors.primary,
          Icons.person_pin_circle_outlined,
        ),
      RequestStatus.collecting => (
          'Parcels Being Collected',
          'Your volunteer is at the donation center collecting your parcels.',
          AppColors.primary,
          Icons.inventory_2_outlined,
        ),
      RequestStatus.delivering => (
          'On the Way to You!',
          'Your volunteer is heading to your location with your parcels.',
          AppColors.primary,
          Icons.local_shipping_outlined,
        ),
      RequestStatus.completed => (
          'Delivered ✓',
          'Your parcels have been delivered successfully.',
          AppColors.success,
          Icons.check_circle_outline,
        ),
      RequestStatus.expired => (
          'Request Expired',
          'No volunteer accepted within 72 hours. Please submit a new request.',
          AppColors.textSecondary,
          Icons.timer_off_outlined,
        ),
      RequestStatus.cancelled => (
          'Request Cancelled',
          'You cancelled this request.',
          AppColors.error,
          Icons.cancel_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
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