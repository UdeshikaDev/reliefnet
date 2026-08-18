// lib/screens/admin/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/confirmation_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load pending count badge on every visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserProvider>().loadPendingVolunteers();
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final auth = context.read<AuthProvider>();
    final adminName = auth.currentUser?.displayName ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              adminName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _AdminMenuItem(
            icon: Icons.group_rounded,
            label: 'Volunteer Queue',
            subtitle: 'Approve or reject pending volunteers',
            badge: userProv.pendingCount > 0
                ? '${userProv.pendingCount}'
                : null,
            badgeColor: AppColors.warning,
            onTap: () => context.push(RouteNames.volunteerQueue),
          ),
          _AdminMenuItem(
            icon: Icons.inventory_2_rounded,
            label: 'Blueprint Editor',
            subtitle: 'Edit items included in each relief parcel',
            onTap: () => context.push(RouteNames.blueprintEditor),
          ),
         // _AdminMenuItem(
          //  icon: Icons.flag_rounded,
          //  label: 'Flagged Photos',
          //  subtitle: 'Review damage photos flagged for admin approval',
           // onTap: () => context.push(RouteNames.flaggedRequests),
          //),
          _AdminMenuItem(
            icon: Icons.map_rounded,
            label: 'Global Inventory',
            subtitle: 'Parcel counts and bottlenecks across all centers',
            onTap: () => context.push(RouteNames.globalInventory),
          ),
          _AdminMenuItem(
            icon: Icons.campaign_rounded,
            label: 'Emergency Broadcast',
            subtitle: 'Send push notification to all users or a group',
            onTap: () => context.push(RouteNames.broadcast),
          ),
          _AdminMenuItem(
            icon: Icons.bar_chart_rounded,
            label: 'Metrics Dashboard',
            subtitle: 'System-wide statistics and charts',
            onTap: () => context.push(RouteNames.adminMetrics),
          ),
        ],
      ),
    );
  }
}

// ── Private widget ────────────────────────────────────────────────────────────

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor = AppColors.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            if (badge != null) const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textHint),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}