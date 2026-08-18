import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/relief_button.dart';

/// Shown to volunteers whose accounts are awaiting admin approval.
/// Back button is blocked. User can only check status or sign out.
class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      size: 60, color: AppColors.warning),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Account Under Review',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                const Text(
                  'Your volunteer account has been submitted and is being reviewed by our admin team.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Timeline chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.20)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 18, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text(
                        'Usually approved within 24 hours',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Steps
                const _StepRow(number: '1', text: 'Admin reviews your registration.', done: true),
                const SizedBox(height: 10),
                const _StepRow(number: '2', text: 'Admin approves your account.', done: false),
                const SizedBox(height: 10),
                const _StepRow(number: '3', text: 'You can start registering donation centers.', done: false),

                const SizedBox(height: 48),

                // Check status button
                ReliefButton(
                  label: 'Check Status',
                  onPressed: () => context.read<AuthProvider>().tryAutoLogin(),
                  isLoading: auth.isLoading,
                ),
                const SizedBox(height: 16),

                // Sign out
                TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () => context.read<AuthProvider>().signOut(),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Questions? reliefnet.support@example.lk',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  final bool done;

  const _StepRow({required this.number, required this.text, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.success : AppColors.surfaceAlt,
            border: Border.all(
              color: done ? AppColors.success : AppColors.divider,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(number,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: done ? AppColors.textPrimary : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}