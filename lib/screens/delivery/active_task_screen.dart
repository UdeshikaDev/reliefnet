// lib/screens/delivery/active_task_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/enums/task_status.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/centers_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/task_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/center_name_text.dart';
import '../../widgets/common/get_directions_button.dart';
import '../../widgets/task/delivery_step_indicator.dart';

/// Volunteer's live delivery hub.
///
/// **Real-time:** Subscribes to [TaskProvider.startActiveTaskStream] on init.
/// When the coordinator confirms collection on their device, the stream emits
/// and the "Collect Parcels" button activates — no user action needed.
///
/// **No active task:** shows an empty state with a "Find Requests" button.
class ActiveTaskScreen extends StatefulWidget {
  final String taskId;
  const ActiveTaskScreen({super.key, required this.taskId});

  @override
  State<ActiveTaskScreen> createState() => _ActiveTaskScreenState();
}

class _ActiveTaskScreenState extends State<ActiveTaskScreen> {
  // Captured synchronously in initState (context is guaranteed valid at
  // that point) so dispose() never needs to call context.read() on a
  // BuildContext that may already be deactivated by teardown time. This is
  // the fix Flutter's own error message points at: "save a reference ...
  // in didChangeDependencies" — initState is the equivalent capture point
  // for a provider instance that doesn't change identity for the lifetime
  // of the app (this one is registered once, in main.dart, via
  // ChangeNotifierProvider.value).
  late final TaskProvider _taskProvider;

  @override
  void initState() {
    super.initState();
    _taskProvider = context.read<TaskProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // guards against a very fast navigate-away
      final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
      _taskProvider.startActiveTaskStream(uid);
    });
  }

  @override
  void dispose() {
    _taskProvider.stopActiveTaskStream();
    super.dispose();
  }

  // ── Action button logic ───────────────────────────────────────────────────

  Widget _buildActionButton(BuildContext context) {
    final task = context.watch<TaskProvider>().activeTask!;

    // Step 1 → 2: Go to center. No action needed — just show info.
    if (task.status == TaskStatus.reserved && !task.isCoordinatorConfirmed) {
      return Column(
        children: [
          _WaitingForCoordinatorBanner(centerId: task.centerId),
          const SizedBox(height: 12),
          _CenterDirectionsTile(centerId: task.centerId),
        ],
      );
    }

    // Step 2 → 3: Coordinator confirmed — volunteer collects parcels.
    if (task.status == TaskStatus.reserved ||
        task.status == TaskStatus.coordinatorConfirmed) {
      return Column(
        children: [
          _CenterDirectionsTile(centerId: task.centerId),
          const SizedBox(height: 12),
          _PrimaryActionButton(
            icon: Icons.inventory_2_outlined,
            label: 'Confirm Collection at Center',
            color: AppColors.primary,
            onTap: () => context.push(RouteNames.collectionConfirmPath(task.taskId)),
          ),
        ],
      );
    }

    // Step 3 → 4: In transit — deliver to victim.
    if (task.status == TaskStatus.inTransit) {
      return Column(
        children: [
          _PrimaryActionButton(
            icon: Icons.qr_code_scanner,
            label: 'Scan Victim QR to Confirm Delivery',
            color: AppColors.success,
            onTap: () => context.push(RouteNames.deliveryConfirmPath(task.taskId)),
          ),
          const SizedBox(height: 12),
          // Previously this always showed a hardcoded coordinate pair
          // (6.9271, 79.8612 — Colombo city centre, marked "// mock coords"
          // in the code) regardless of where the victim actually was.
          // [Verified from code] Now fetches the real request's lat/lng.
          _VictimLocationTile(requestId: task.requestId),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ── Cancel dialog ─────────────────────────────────────────────────────────

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Task?'),
        content: const Text(
          'The parcels will be returned to the center and the request will re-open for other volunteers. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Task'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await context.read<TaskProvider>().cancelTask();
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task cancelled — parcels returned.')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    // No active task
    if (!provider.hasActiveTask && !provider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Active Task'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              const Text(
                'No active task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Accept a request to get started.',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(RouteNames.requestList),
                icon: const Icon(Icons.search),
                label: const Text('Find Requests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final task = provider.activeTask;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Active Delivery'),
        elevation: 0,
        actions: [
          if (task != null &&
              task.status != TaskStatus.delivered &&
              task.status != TaskStatus.cancelled)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'cancel') _showCancelDialog(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Cancel Task',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : task == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: () async {
                    final uid =
                        context.read<AuthProvider>().currentUser?.uid ?? '';
                    context.read<TaskProvider>().startActiveTaskStream(uid);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error banner
                        if (provider.error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(provider.error!,
                                      style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: provider.clearError,
                                ),
                              ],
                            ),
                          ),

                        // ── Task summary card ─────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment_outlined,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Task #${task.taskId.length > 8 ? task.taskId.substring(task.taskId.length - 8) : task.taskId}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: AppColors.divider),
                              _SummaryRow(
                                label: 'Parcels',
                                value:
                                    '${task.parcelsCount} parcel${task.parcelsCount > 1 ? 's' : ''}',
                              ),
                              const SizedBox(height: 6),
                              _SummaryRow(
                                label: 'Center',
                                value: task.centerId,
                                valueWidget: CenterNameText(
                                  centerId: task.centerId,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _SummaryRow(
                                label: 'Coordinator',
                                value: task.isCoordinatorConfirmed
                                    ? '✓ Confirmed'
                                    : 'Pending',
                                valueColor: task.isCoordinatorConfirmed
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Delivery step indicator ───────────────────────
                        const Text(
                          'Delivery Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DeliveryStepIndicator(
                          status: task.status,
                          isCoordinatorConfirmed: task.isCoordinatorConfirmed,
                        ),

                        const SizedBox(height: 28),

                        // ── Context-aware action button ───────────────────
                        _buildActionButton(context),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ── Internal helper widgets ────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? valueWidget;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        valueWidget ??
            Text(value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                )),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _InfoBanner(
      {required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Previously took a raw (lat, lng) pair, and every call site passed the
/// same hardcoded (6.9271, 79.8612) — Colombo city centre — regardless of
/// where the victim's request actually was. [Verified from code, marked
/// "// mock coords" at the call site] Now takes the requestId and fetches
/// the real ReliefRequestModel (which already stores the victim's actual
/// submitted lat/lng) via RequestProvider.loadRequest — the same
/// non-mutating fetch method used elsewhere in this app for exactly this
/// kind of read-only lookup.
class _VictimLocationTile extends StatelessWidget {
  final String requestId;
  const _VictimLocationTile({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<RequestProvider>().loadRequest(requestId),
      builder: (context, snapshot) {
        final request = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Victim Location',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          request == null
                              ? (snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Loading…'
                                  : 'Not available')
                              : '${request.lat.toStringAsFixed(4)}, ${request.lng.toStringAsFixed(4)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (request != null) ...[
                const SizedBox(height: 12),
                GetDirectionsButton(
                  lat: request.lat,
                  lng: request.lng,
                  label: 'Get Directions to Victim',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Replaces the old plain-text "Go to {CENTERID} and wait..." banner —
/// fetches the real center name instead of showing the raw ID.
class _WaitingForCoordinatorBanner extends StatelessWidget {
  final String centerId;
  const _WaitingForCoordinatorBanner({required this.centerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CentersProvider>().fetchCenterById(centerId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? centerId.toUpperCase();
        return _InfoBanner(
          icon: Icons.schedule,
          color: AppColors.warning,
          message: 'Go to $name and wait for the coordinator to confirm.',
        );
      },
    );
  }
}

/// New — previously there was no way to get directions to the donation
/// center from this screen at all, only a plain text mention of its raw ID.
class _CenterDirectionsTile extends StatelessWidget {
  final String centerId;
  const _CenterDirectionsTile({required this.centerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CentersProvider>().fetchCenterById(centerId),
      builder: (context, snapshot) {
        final center = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warehouse_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Donation Center',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          center?.name ??
                              (snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Loading…'
                                  : centerId.toUpperCase()),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        if (center?.address != null)
                          Text(
                            center!.address,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (center != null) ...[
                const SizedBox(height: 12),
                GetDirectionsButton(
                  lat: center.lat,
                  lng: center.lng,
                  label: 'Get Directions to Center',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}