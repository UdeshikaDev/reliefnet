// lib/screens/volunteer/task_detail_screen.dart
//
// New screen. Previously TaskHistoryScreen's cards showed only a compact
// summary (status, parcel count, relative time) and weren't tappable at
// all — TaskCard's custom onTap override was silently inert whenever
// showCta was false, which is how every history card was rendered.
// [Verified from code] This screen is what a tapped history card now opens:
// a full, read-only view of who the task was for for and who delivered it,
// which center it came from, and (for delivered tasks) a way through to
// the sealed receipt.
//
// Takes the DeliveryTaskModel directly via GoRouter's `extra` rather than
// re-fetching by ID — TaskHistoryScreen already has the full model in
// memory for each card, so there's no reason to look it up again.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/task_status.dart';
import '../../models/delivery_task_model.dart';
import '../../models/relief_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/center_name_text.dart';
import '../../widgets/common/get_directions_button.dart';

class TaskDetailScreen extends StatefulWidget {
  final DeliveryTaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  UserModel? _victim;
  UserModel? _volunteer;
  ReliefRequestModel? _request;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetails());
  }

  Future<void> _loadDetails() async {
    final userProvider = context.read<UserProvider>();
    final requestProvider = context.read<RequestProvider>();
    try {
      final results = await Future.wait([
        userProvider.fetchUserById(widget.task.victimUid),
        userProvider.fetchUserById(widget.task.volunteerUid),
        requestProvider.loadRequest(widget.task.requestId),
      ]);
      if (!mounted) return;
      setState(() {
        _victim = results[0] as UserModel?;
        _volunteer = results[1] as UserModel?;
        _request = results[2] as ReliefRequestModel?;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _viewReceipt() async {
    final receiptProvider = context.read<ReceiptProvider>();
    await receiptProvider.loadReceiptForTask(widget.task.taskId);
    if (!mounted) return;
    final receipt = receiptProvider.receipt;
    if (receipt != null) {
      context.push(RouteNames.receiptDetailPath(receipt.receiptId));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(receiptProvider.error ?? 'No receipt found for this task.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color get _statusColor {
    switch (widget.task.status) {
      case TaskStatus.delivered:
        return AppColors.success;
      case TaskStatus.cancelled:
        return AppColors.textSecondary;
      case TaskStatus.inTransit:
        return AppColors.primary;
      case TaskStatus.reserved:
      case TaskStatus.coordinatorConfirmed:
        return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (widget.task.status) {
      case TaskStatus.delivered:
        return 'Delivered';
      case TaskStatus.cancelled:
        return 'Cancelled';
      case TaskStatus.inTransit:
        return 'Delivering';
      case TaskStatus.reserved:
        return widget.task.isCoordinatorConfirmed
            ? 'Ready to Collect'
            : 'Awaiting Coordinator';
      case TaskStatus.coordinatorConfirmed:
        return 'Ready to Collect';
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Task Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Task #${task.taskId.length > 8 ? task.taskId.substring(task.taskId.length - 8) : task.taskId}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Task details ─────────────────────────────────────────────
            _Card(
              title: 'TASK',
              children: [
                _Row('Parcels',
                    '${task.parcelsCount} sealed parcel${task.parcelsCount > 1 ? 's' : ''}'),
                _Row(
                  'Center',
                  '',
                  valueWidget: CenterNameText(centerId: task.centerId),
                ),
                _Row('Created', _formatDate(task.createdAt)),
                _Row('Last updated', _formatDate(task.updatedAt)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Volunteer ─────────────────────────────────────────────────
            _Card(
              title: 'VOLUNTEER',
              loading: _loading,
              children: [
                _Row('Name', _volunteer?.displayName ?? _shortUid(task.volunteerUid)),
                _Row('Phone', _volunteer?.phone ?? 'Not available'),
              ],
            ),
            const SizedBox(height: 16),

            // ── Victim / recipient ───────────────────────────────────────
            _Card(
              title: 'VICTIM (RECIPIENT)',
              loading: _loading,
              children: [
                _Row('Name', _victim?.displayName ?? _shortUid(task.victimUid)),
                _Row('Phone', _victim?.phone ?? 'Not available'),
                if (_request != null) ...[
                  _Row('NIC', _request!.nicNumber),
                  _Row('Family size', '${_request!.familySize}'),
                ],
              ],
            ),

            if (_request != null) ...[
              const SizedBox(height: 16),
              GetDirectionsButton(
                lat: _request!.lat,
                lng: _request!.lng,
                label: 'Get Directions to Victim',
              ),
            ],

            if (task.status == TaskStatus.delivered) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _viewReceipt,
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  label: const Text('View Full Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortUid(String uid) =>
      uid.length > 12 ? '${uid.substring(0, 12)}…' : uid;

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool loading;
  const _Card({required this.title, required this.children, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            for (final c in children) ...[
              c,
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  const _Row(this.label, this.value, {this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(
          child: valueWidget ??
              Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
        ),
      ],
    );
  }
}
