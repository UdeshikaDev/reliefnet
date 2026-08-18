// lib/screens/coordinator/confirm_collection_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/relief_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/centers_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/center_name_text.dart';

/// Coordinator confirms that a specific volunteer has physically collected
/// their reserved parcels from the center.
///
/// Navigated to via `context.push(RouteNames.confirmCollectionPath(taskId))`
/// from [CoordinatorDashboardScreen] or [DispatchScreen] when the coordinator
/// taps a pending-collection task card.
///
/// Previously this screen only showed the task's raw volunteer UID (not a
/// name) and nothing about the victim or their request at all — there was no
/// way for a coordinator to see who they were actually handing parcels to,
/// or confirm the request behind the task, before confirming. It now fetches
/// and displays both the volunteer's and victim's profiles (via
/// UserProvider.fetchUserById) and the underlying request (via
/// RequestProvider.loadRequest).
///
/// On success, pops back to the calling screen. The volunteer's
/// [ActiveTaskScreen] stream fires automatically (shared MockTaskService).
class ConfirmCollectionScreen extends StatefulWidget {
  final String taskId;
  const ConfirmCollectionScreen({super.key, required this.taskId});

  @override
  State<ConfirmCollectionScreen> createState() =>
      _ConfirmCollectionScreenState();
}

class _ConfirmCollectionScreenState extends State<ConfirmCollectionScreen> {
  UserModel? _volunteer;
  UserModel? _victim;
  ReliefRequestModel? _request;
  bool _loadingDetails = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTaskAndDetails());
  }

  // Used to hardcode a single centerId ('center_001') that didn't match any
  // real center — this screen would only ever find a task if it happened to
  // already be loaded from the calling screen. Now it searches the
  // coordinator's own centers (from CentersProvider.myCenters) for whichever
  // one actually holds this task, so it works regardless of which center a
  // task belongs to.
  Future<void> _loadTaskAndDetails() async {
    final taskProvider = context.read<TaskProvider>();

    var task = taskProvider.centerTasks
        .where((t) => t.taskId == widget.taskId)
        .firstOrNull;

    if (task == null) {
      final myCenters = context.read<CentersProvider>().myCenters;
      for (final center in myCenters) {
        await taskProvider.loadTasksForCenter(center.centerId);
        if (!mounted) return;
        task = taskProvider.centerTasks
            .where((t) => t.taskId == widget.taskId)
            .firstOrNull;
        if (task != null) break;
      }
    }

    if (task == null || !mounted) return;

    setState(() => _loadingDetails = true);
    final userProvider = context.read<UserProvider>();
    final requestProvider = context.read<RequestProvider>();
    final foundTask = task;
    try {
      final results = await Future.wait([
        userProvider.fetchUserById(foundTask.volunteerUid),
        userProvider.fetchUserById(foundTask.victimUid),
        requestProvider.loadRequest(foundTask.requestId),
      ]);
      if (!mounted) return;
      setState(() {
        _volunteer = results[0] as UserModel?;
        _victim = results[1] as UserModel?;
        _request = results[2] as ReliefRequestModel?;
      });
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Collection?'),
        content: const Text(
          'Confirm that the volunteer has physically received the parcels. '
          'They will be notified to begin delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await context
        .read<TaskProvider>()
        .confirmCollectionByCoordinator(widget.taskId);

    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collection confirmed — volunteer notified.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(); // return to coordinator dashboard / dispatch
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    // Find this specific task from the loaded center tasks.
    final task = provider.centerTasks
        .where((t) => t.taskId == widget.taskId)
        .firstOrNull;

    final alreadyConfirmed = task?.isCoordinatorConfirmed ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Collection'),
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : task == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text('Task not found.',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Status header ──────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: alreadyConfirmed
                              ? AppColors.success.withOpacity(0.08)
                              : AppColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: alreadyConfirmed
                                ? AppColors.success.withOpacity(0.3)
                                : AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              alreadyConfirmed
                                  ? Icons.check_circle_outline
                                  : Icons.schedule,
                              color: alreadyConfirmed
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alreadyConfirmed
                                      ? 'Already Confirmed'
                                      : 'Awaiting Confirmation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: alreadyConfirmed
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                                Text(
                                  alreadyConfirmed
                                      ? 'Volunteer is collecting parcels'
                                      : 'Volunteer has arrived at the center',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Task details ───────────────────────────────────
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
                            const Text(
                              'TASK DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Task ID',
                              value: task.taskId.length > 12
                                  ? '…${task.taskId.substring(task.taskId.length - 12)}'
                                  : task.taskId,
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: 'Parcels',
                              value:
                                  '${task.parcelsCount} sealed parcel${task.parcelsCount > 1 ? 's' : ''}',
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Volunteer details ────────────────────────────────
                      // Previously the only "Volunteer" field on this screen
                      // was the raw volunteerUid string — no name, no phone.
                      _PersonCard(
                        title: 'VOLUNTEER (COLLECTING)',
                        icon: Icons.volunteer_activism_outlined,
                        iconColor: AppColors.primary,
                        loading: _loadingDetails,
                        name: _volunteer?.displayName,
                        phone: _volunteer?.phone,
                        fallbackUid: task.volunteerUid,
                      ),

                      const SizedBox(height: 16),

                      // ── Victim + request details ─────────────────────────
                      // This card did not exist at all before — a
                      // coordinator confirming a collection had no way to
                      // see who the parcels were ultimately going to, or
                      // any detail about their request.
                      _PersonCard(
                        title: 'VICTIM (RECIPIENT)',
                        icon: Icons.person_outline,
                        iconColor: AppColors.success,
                        loading: _loadingDetails,
                        name: _victim?.displayName,
                        phone: _victim?.phone,
                        fallbackUid: task.victimUid,
                        extraRows: _request == null
                            ? const []
                            : [
                                _DetailRow(
                                  label: 'NIC',
                                  value: _request!.nicNumber,
                                ),
                                _DetailRow(
                                  label: 'Family size',
                                  value: '${_request!.familySize}',
                                ),
                                _DetailRow(
                                  label: 'Parcels entitled',
                                  value: '${_request!.parcelsEntitled}',
                                ),
                                _DetailRow(
                                  label: 'Submitted',
                                  value: _formatDate(_request!.submittedAt),
                                ),
                              ],
                        photoUrl: _request?.damagePhotoUrl,
                      ),

                      const SizedBox(height: 16),

                      // ── Instructions ───────────────────────────────────
                      if (!alreadyConfirmed)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Before confirming:',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 8),
                              _BulletPoint(
                                  'Verify the volunteer\'s ID or phone number'),
                              _BulletPoint(
                                  'Count the parcels before handing over'),
                              _BulletPoint(
                                  'Confirm all parcel seals are intact'),
                            ],
                          ),
                        ),

                      const SizedBox(height: 30),

                      // ── Error ──────────────────────────────────────────
                      if (provider.error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(provider.error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ),

                      // ── Confirm button ─────────────────────────────────
                      if (!alreadyConfirmed)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: provider.isConfirmingCollection
                                ? null
                                : () => _confirm(context),
                            icon: provider.isConfirmingCollection
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              provider.isConfirmingCollection
                                  ? 'Confirming…'
                                  : 'Confirm — Volunteer is Collecting',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.success, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Collection already confirmed',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool loading;
  final String? name;
  final String? phone;
  final String fallbackUid;
  final List<Widget> extraRows;
  final String? photoUrl;

  const _PersonCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.loading,
    required this.name,
    required this.phone,
    required this.fallbackUid,
    this.extraRows = const [],
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final shortUid =
        fallbackUid.length > 12 ? '…${fallbackUid.substring(fallbackUid.length - 12)}' : fallbackUid;

    return Container(
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
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
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
          else ...[
            if (photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  photoUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _DetailRow(label: 'Name', value: name ?? shortUid),
            const SizedBox(height: 8),
            _DetailRow(label: 'Phone', value: phone ?? 'Not available'),
            for (final row in extraRows) ...[
              const SizedBox(height: 8),
              row,
            ],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  const _DetailRow({required this.label, required this.value, this.valueWidget});

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
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}