// lib/screens/admin/volunteer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/loading_overlay.dart';

class VolunteerDetailScreen extends StatefulWidget {
  final String uid;
  const VolunteerDetailScreen({super.key, required this.uid});

  @override
  State<VolunteerDetailScreen> createState() => _VolunteerDetailScreenState();
}

class _VolunteerDetailScreenState extends State<VolunteerDetailScreen> {
  UserModel? _volunteer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user =
          await context.read<UserProvider>().fetchUserById(widget.uid);
      if (mounted) {
        setState(() {
          _volunteer = user;
          if (user == null) _error = 'Volunteer profile not found.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve() async {
    final name = _volunteer?.displayName ?? _volunteer?.phone ?? 'volunteer';
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Approve Volunteer',
      message: 'Approve $name? They will receive a notification and can start volunteering immediately.',
      confirmLabel: 'Approve',
      isDestructive: false,
    );
    if (confirmed != true || !mounted) return;
    final success =
        await context.read<UserProvider>().approveVolunteer(widget.uid);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Volunteer approved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  Future<void> _reject() async {
    final name = _volunteer?.displayName ?? _volunteer?.phone ?? 'volunteer';
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Reject Volunteer',
      message:
          'Permanently remove $name\'s account? This action cannot be undone.',
      confirmLabel: 'Reject',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    final success =
        await context.read<UserProvider>().rejectVolunteer(widget.uid);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account rejected and removed.'),
          backgroundColor: AppColors.error,
        ),
      );
      context.pop();
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

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
          title: const Text(
            'Volunteer Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Builder(builder: (_) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }
          if (_error != null || _volunteer == null) {
            return Center(
                child: AppErrorBanner(message: _error ?? 'Unknown error'));
          }

          final vol = _volunteer!;
          final isPending = !vol.isVerified;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar + name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_rounded,
                            size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        vol.displayName ?? 'No name provided',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPending
                              ? AppColors.warning.withValues(alpha: 0.12)
                              : AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPending ? 'Pending Approval' : 'Approved Volunteer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isPending
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Detail cards
                _DetailRow(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: vol.phone),
                const SizedBox(height: 10),
                _DetailRow(
                    icon: Icons.badge_rounded,
                    label: 'NIC',
                    value: vol.nicNumber ?? 'Not provided'),
                const SizedBox(height: 10),
                _DetailRow(
                    icon: Icons.cake_rounded,
                    label: 'Date of Birth',
                    value: vol.dateOfBirth != null
                        ? _formatDate(vol.dateOfBirth!)
                        : 'Not provided'),
                const SizedBox(height: 10),
                _DetailRow(
                    icon: Icons.wc_rounded,
                    label: 'Gender',
                    value: vol.gender != null
                        ? _capitalize(vol.gender!.name)
                        : 'Not provided'),
                const SizedBox(height: 10),
                _DetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: vol.address ?? 'Not provided'),
                const SizedBox(height: 10),
                _DetailRow(
                    icon: Icons.verified_user_rounded,
                    label: 'Role',
                    value: vol.role.name.toUpperCase()),
                const SizedBox(height: 10),
                _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Registered',
                    value: vol.createdAt.dateTimeDisplay),
                const SizedBox(height: 10),
                _DetailRow(
                    icon: Icons.update_rounded,
                    label: 'Last Updated',
                    value: vol.updatedAt.timeAgo),

                // Action buttons (only for pending volunteers)
                if (isPending) ...[
                  const SizedBox(height: 32),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reject,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Reject Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _approve,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}