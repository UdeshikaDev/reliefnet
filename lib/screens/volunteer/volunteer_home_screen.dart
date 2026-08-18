// lib/screens/volunteer/volunteer_home_screen.dart
// REPLACES Module 2 stub.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/centers_provider.dart';
import '../../providers/task_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/task/task_card.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});
  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<TaskProvider>().loadActiveTask(uid);
        context.read<CentersProvider>().listenToCentersForUser(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('ReliefNet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push(RouteNames.notifications),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push(RouteNames.profile),
            color: Colors.white,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
          if (uid.isNotEmpty) {
            await context.read<TaskProvider>().loadActiveTask(uid);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingHeader(user: user),
              _ActiveTaskSection(),
              _QuickActionsGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        backgroundColor: AppColors.surface,
        onTap: (i) {
          switch (i) {
            case 0: context.push(RouteNames.volunteerHome);
            case 1: context.push(RouteNames.requestMap);
            case 2: context.push(RouteNames.myCenters);
            case 3: context.push(RouteNames.taskHistory);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),   label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Find Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined),  label: 'My Centers'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined),label: 'History'),
        ],
      ),
    );
  }
}

// ── Greeting Header ────────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final UserModel? user;
  const _GreetingHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greeting,',
              style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(user?.displayName ?? 'Volunteer',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text('Verified Volunteer',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active Task Section ────────────────────────────────────────────────────────
class _ActiveTaskSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Task',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          // hasActiveTask is checked before isLoading and showCta is no
          // longer commented out. Both changes come from a comment block
          // that was left at the bottom of task_card.dart describing this
          // exact fix but never applied to this file — [Verified from
          // code] I read that comment block directly; I did not infer this
          // fix from scratch.
          if (tp.hasActiveTask)
            TaskCard(task: tp.activeTask!, showCta: true)
          else if (tp.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ))
          else if (tp.error != null)
            AppErrorBanner(message: tp.error!)
          else
            _NoActiveTaskCard(),
        ],
      ),
    );
  }
}

class _NoActiveTaskCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 42, color: AppColors.textHint),
          const SizedBox(height: 10),
          const Text('No active delivery',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Browse pending requests to help a family',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.push(RouteNames.requestMap),
            icon: const Icon(Icons.search, size: 16),
            label: const Text('Find a Request'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ─────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _ActionTile(icon: Icons.map_outlined,          label: 'Request Map',    subtitle: 'See pending requests',  onTap: () => context.push(RouteNames.requestMap)),
              _ActionTile(icon: Icons.list_alt_outlined,     label: 'Request List',   subtitle: 'Sort by distance',      onTap: () => context.push(RouteNames.requestList)),
              _ActionTile(icon: Icons.add_location_alt_outlined, label: 'Register Center', subtitle: 'Open a new center', onTap: () => context.push(RouteNames.registerCenter)),
              _ActionTile(icon: Icons.store_outlined,        label: 'My Centers',     subtitle: 'Manage inventory',      onTap: () => context.push(RouteNames.myCenters)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}