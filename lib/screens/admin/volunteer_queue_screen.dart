// lib/screens/admin/volunteer_queue_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/loading_overlay.dart';

class VolunteerQueueScreen extends StatefulWidget {
  const VolunteerQueueScreen({super.key});

  @override
  State<VolunteerQueueScreen> createState() => _VolunteerQueueScreenState();
}

class _VolunteerQueueScreenState extends State<VolunteerQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserProvider>().loadPendingVolunteers();
    });
  }

  Future<void> _approve(BuildContext ctx, UserModel volunteer) async {
    final name = volunteer.displayName ?? volunteer.phone;
    final confirmed = await showConfirmationDialog(
      ctx,
      title: 'Approve Volunteer',
      message:
          'Approve $name? They will be notified and can start volunteering immediately.',
      confirmLabel: 'Approve',
      isDestructive: false,
    );
    if (confirmed != true || !ctx.mounted) return;
    final success =
        await ctx.read<UserProvider>().approveVolunteer(volunteer.uid);
    if (success && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('$name approved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext ctx, UserModel volunteer) async {
    final name = volunteer.displayName ?? volunteer.phone;
    final confirmed = await showConfirmationDialog(
      ctx,
      title: 'Reject Volunteer',
      message:
          'Reject and permanently remove $name\'s account? This cannot be undone.',
      confirmLabel: 'Reject',
      isDestructive: true,
    );
    if (confirmed != true || !ctx.mounted) return;
    final success =
        await ctx.read<UserProvider>().rejectVolunteer(volunteer.uid);
    if (success && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('$name\'s account has been rejected.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();

    return LoadingOverlay(
      isLoading: userProv.isApprovingRejecting,
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
            'Pending Approvals (${userProv.pendingCount})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Builder(builder: (ctx) {
          if (userProv.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }

          if (userProv.error != null) {
            return Center(child: AppErrorBanner(message: userProv.error!));
          }

          if (userProv.pendingVolunteers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 56, color: AppColors.success),
                  SizedBox(height: 16),
                  Text(
                    'No pending volunteers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All accounts are reviewed.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: userProv.pendingVolunteers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final vol = userProv.pendingVolunteers[i];
              return _VolunteerQueueCard(
                volunteer: vol,
                onTap: () => context.push(
                  RouteNames.volunteerDetail,
                  extra: vol.uid,
                ),
                onApprove: () => _approve(ctx, vol),
                onReject: () => _reject(ctx, vol),
              );
            },
          );
        }),
      ),
    );
  }
}

// ── Card widget ───────────────────────────────────────────────────────────────

class _VolunteerQueueCard extends StatelessWidget {
  final UserModel volunteer;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VolunteerQueueCard({
    required this.volunteer,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.warning, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          volunteer.displayName ?? 'Unnamed Volunteer',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          volunteer.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // NIC — added so an admin can do a basic identity check
              // without opening the full detail screen. Previously this
              // card (and volunteer registration generally) had no NIC at
              // all to show here.
              if (volunteer.nicNumber != null)
                Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      'NIC: ${volunteer.nicNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),

              // Registered date
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    'Registered ${volunteer.createdAt.timeAgo}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}