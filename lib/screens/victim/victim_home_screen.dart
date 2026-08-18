// lib/screens/victim/victim_home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/request_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/request/request_card.dart';

/// Home screen for a verified victim.
///
/// Two states:
///   1. No active request → prominent "Submit New Request" CTA.
///   2. Has active request → summary card + "Track Delivery" / "Show QR" actions.
class VictimHomeScreen extends StatefulWidget {
  const VictimHomeScreen({super.key});

  @override
  State<VictimHomeScreen> createState() => _VictimHomeScreenState();
}

class _VictimHomeScreenState extends State<VictimHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<RequestProvider>().startListening(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reqProv = context.watch<RequestProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'ReliefNet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: AppColors.textPrimary),
            onPressed: () => context.push(RouteNames.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.textPrimary),
            onPressed: () => context.push(RouteNames.profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ────────────────────────────────────────────────────
            Text(
              'Hello, ${user?.displayName ?? 'there'} 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ReliefNet is here to help you get the support you need.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 28),

            // ── Error banner ─────────────────────────────────────────────────
            if (reqProv.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: AppErrorBanner(message: reqProv.error!),
              ),

            // ── Active request section ────────────────────────────────────
            if (reqProv.hasActiveRequest) ...[
              _SectionHeader(
                icon: Icons.track_changes_outlined,
                label: 'Your Active Request',
              ),
              const SizedBox(height: 10),

              RequestCard(
                request: reqProv.activeRequest!,
                onTap: () => context.push(
                  RouteNames.requestDetailPath(
                      reqProv.activeRequest!.requestId),
                ),
              ),

              const SizedBox(height: 16),

              // Action row
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.track_changes_outlined,
                      label: 'Track Delivery',
                      color: AppColors.primary,
                      onPressed: () => context.push(
                        RouteNames.trackDeliveryPath(
                            reqProv.activeRequest!.requestId),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Show QR only when delivering
                  if (reqProv.activeRequest!.status ==
                          RequestStatus.delivering ||
                      reqProv.activeRequest!.status ==
                          RequestStatus.collecting)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.qr_code_2_outlined,
                        label: 'Show QR',
                        color: AppColors.success,
                        onPressed: () => context.push(
                          RouteNames.victimQrPath(
                              reqProv.activeRequest!.requestId),
                        ),
                      ),
                    ),
                ],
              ),
            ] else ...[
              // ── No active request ────────────────────────────────────────
              _SubmitRequestCard(
                onTap: () => context.push(RouteNames.submitRequest),
              ),
            ],

            const SizedBox(height: 28),

            // ── Quick links ────────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.history_outlined,
              label: 'Request History',
            ),
            const SizedBox(height: 10),
            _LinkTile(
              icon: Icons.list_alt_outlined,
              label: 'View All My Requests',
              onTap: () => context.push(RouteNames.myRequests),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Icons.map_outlined,
              label: 'Find Donation Centers',
              onTap: () => context.push(RouteNames.publicMap),
            ),

            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () => auth.signOut(),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SubmitRequestCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SubmitRequestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF2A5C8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white, size: 36),
            SizedBox(height: 14),
            Text(
              'Submit a Relief Request',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tell us your family size and location. '
              'A volunteer will bring dry ration parcels to you.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}