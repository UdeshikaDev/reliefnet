// lib/screens/shared/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/app_error_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        final notifProv = context.read<NotificationProvider>();
        notifProv.startListening(user.uid);
        notifProv.initFcm(user.uid, role: user.role); // ← role ADD, see notification_provider.dart
      }
    });
  }

  Future<void> _markAllRead() async {
    await context.read<NotificationProvider>().markAllAsRead();
  }

  Future<void> _tapNotification(NotificationModel notif) async {
    // 1. Mark as read (stream re-emits automatically)
    await context.read<NotificationProvider>().markAsRead(notif.notificationId);
    // 2. Deep-link if a route path is available
    if (notif.routePath != null && mounted) {
      context.push(notif.routePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();

    return Scaffold(
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
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (notifProv.hasUnread)
            TextButton(
              onPressed: notifProv.isMarkingRead ? null : _markAllRead,
              child: notifProv.isMarkingRead
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
            ),
        ],
      ),
      body: Builder(builder: (ctx) {
        if (notifProv.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          );
        }

        if (notifProv.error != null) {
          return Center(child: AppErrorBanner(message: notifProv.error!));
        }

        if (notifProv.notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_rounded,
                    size: 56, color: AppColors.textHint),
                SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'You will be notified about\nrequest updates and deliveries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifProv.notifications.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (_, i) {
            final notif = notifProv.notifications[i];
            return _NotificationTile(
              notification: notif,
              onTap: () => _tapNotification(notif),
            );
          },
        );
      }),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    return switch (notification.type) {
      'request_submitted'                      => Icons.upload_file_rounded,
      'task_assigned' || 'request_accepted'    => Icons.delivery_dining_rounded,
      'parcel_collected' ||
      'collection_confirmed'                   => Icons.inventory_2_rounded,
      'volunteer_arrived'                      => Icons.qr_code_2_rounded,
      'delivery_confirmed' || 'delivery_done'  => Icons.check_circle_rounded,
      'request_expired'                        => Icons.timer_off_rounded,
      'account_verified'                       => Icons.verified_rounded,
      'photo_flagged'                          => Icons.flag_rounded,
      'admin_broadcast'                        => Icons.campaign_rounded,
      'pending_approval'                       => Icons.pending_actions_rounded,
      _                                        => Icons.notifications_rounded,
    };
  }

  Color get _iconColor {
    return switch (notification.type) {
      'delivery_confirmed' ||
      'delivery_done' ||
      'account_verified'      => AppColors.success,
      'request_expired' ||
      'photo_flagged'         => AppColors.error,
      'admin_broadcast' ||
      'pending_approval'      => AppColors.warning,
      _                       => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Unread dot ──────────────────────────────────────────────
            SizedBox(
              width: 10,
              child: isUnread
                  ? Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),

            // ── Type icon ───────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 14),

            // ── Text ────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notification.createdAt.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.routePath != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Tap to view',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color:
                              AppColors.primary.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}