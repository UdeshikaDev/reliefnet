// lib/screens/volunteer/task_history_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/task_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/task_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/task/task_card.dart';

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});
  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
      if (uid.isNotEmpty) context.read<TaskProvider>().loadTaskHistory(uid);
    });
  }

  // Previously history cards weren't tappable at all (see task_card.dart's
  // fix this session), so there was nowhere for this to lead — full task
  // details simply weren't reachable from here. Delivered tasks go to
  // their sealed receipt; anything else (cancelled tasks — the only other
  // terminal status TaskHistoryScreen shows) goes to the new read-only
  // TaskDetailScreen instead, since there's no receipt for those.
  Future<void> _openTask(dynamic task) async {
    if (task.status == TaskStatus.delivered) {
      final receiptProvider = context.read<ReceiptProvider>();
      await receiptProvider.loadReceiptForTask(task.taskId);
      if (!mounted) return;
      final receipt = receiptProvider.receipt;
      if (receipt != null) {
        context.push(RouteNames.receiptDetailPath(receipt.receiptId));
        return;
      }
      // Fall through to the plain detail screen if no receipt exists for
      // some reason (e.g. seeded/inconsistent data) rather than dead-end.
    }
    context.push(RouteNames.taskDetail, extra: task);
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TaskProvider>();
    final history = tp.taskHistory;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        title: const Text('Task History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: tp.isLoading && history.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : tp.error != null && history.isEmpty
              ? Center(child: AppErrorWidget(message: tp.error!))
              : history.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.history_outlined,
                      title: 'No completed tasks',
                      subtitle: 'Completed and cancelled deliveries will appear here.',
                    )
                  : Column(
                      children: [
                        _SummaryBar(history: history),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
                              await context.read<TaskProvider>().loadTaskHistory(uid);
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: history.length,
                              itemBuilder: (ctx, i) => TaskCard(
                                task: history[i],
                                onTap: () => _openTask(history[i]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final List history;
  const _SummaryBar({required this.history});

  @override
  Widget build(BuildContext context) {
    final delivered = history.where((t) => t.status == TaskStatus.delivered).length;
    final cancelled = history.where((t) => t.status == TaskStatus.cancelled).length;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _Stat(label: 'Delivered', count: delivered,
              color: AppColors.success, icon: Icons.check_circle_outline),
          const SizedBox(width: 20),
          _Stat(label: 'Cancelled', count: cancelled,
              color: AppColors.error, icon: Icons.cancel_outlined),
          const SizedBox(width: 20),
          _Stat(label: 'Total', count: history.length,
              color: AppColors.primary, icon: Icons.list_alt_outlined),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _Stat({required this.label, required this.count,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text('$count $label', style: TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: color)),
    ],
  );
}