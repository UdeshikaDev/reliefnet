// lib/screens/admin/flagged_requests_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../models/relief_request_model.dart';
import '../../providers/request_provider.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/loading_overlay.dart';

class FlaggedRequestsScreen extends StatefulWidget {
  const FlaggedRequestsScreen({super.key});

  @override
  State<FlaggedRequestsScreen> createState() => _FlaggedRequestsScreenState();
}

class _FlaggedRequestsScreenState extends State<FlaggedRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RequestProvider>().loadFlaggedRequests();
    });
  }

  Future<void> _approve(BuildContext ctx, ReliefRequestModel req) async {
    final confirmed = await showConfirmationDialog(
      ctx,
      title: 'Approve Photo',
      message:
          'Mark this damage photo as verified? The request will return to the volunteer queue.',
      confirmLabel: 'Approve',
      isDestructive: false,
    );
    if (confirmed != true || !ctx.mounted) return;
    final success =
        await ctx.read<RequestProvider>().approvePhotoReview(req.requestId);
    if (success && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Photo approved. Request re-queued for volunteers.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext ctx, ReliefRequestModel req) async {
    final confirmed = await showConfirmationDialog(
      ctx,
      title: 'Reject Request',
      message:
          'Cancel this request due to invalid photo? The victim will be notified.',
      confirmLabel: 'Reject Request',
      isDestructive: true,
    );
    if (confirmed != true || !ctx.mounted) return;
    final success = await ctx
        .read<RequestProvider>()
        .rejectFlaggedRequest(req.requestId);
    if (success && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Request rejected and cancelled.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reqProv = context.watch<RequestProvider>();

    return LoadingOverlay(
      isLoading: reqProv.isApprovingRejecting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Photo Review Queue (${reqProv.flaggedRequests.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Builder(builder: (ctx) {
          if (reqProv.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }
          if (reqProv.error != null) {
            return Center(child: AppErrorBanner(message: reqProv.error!));
          }
          if (reqProv.flaggedRequests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 56, color: AppColors.success),
                  SizedBox(height: 16),
                  Text(
                    'No flagged photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All submitted photos have been reviewed.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reqProv.flaggedRequests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final req = reqProv.flaggedRequests[i];
              return _FlaggedRequestCard(
                request: req,
                onApprove: () => _approve(ctx, req),
                onReject: () => _reject(ctx, req),
              );
            },
          );
        }),
      ),
    );
  }
}

// ── Card widget ───────────────────────────────────────────────────────────────

class _FlaggedRequestCard extends StatelessWidget {
  final ReliefRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _FlaggedRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flag header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_rounded,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      const Text(
                        'Photo Flagged',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  request.submittedAt.timeAgo,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Request info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Damage photo thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: request.damagePhotoUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 90,
                      height: 90,
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.textHint),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.broken_image_rounded,
                          color: AppColors.textHint),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request #${request.requestId.substring(0, request.requestId.length.clamp(0, 8))}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _InfoRow('NIC', request.nicNumber),
                      _InfoRow('Family', '${request.familySize} members'),
                      _InfoRow(
                          'Parcels', '${request.parcelsEntitled} entitled'),
                      _InfoRow('Flag reason', 'EXIF / metadata mismatch'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject Request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}