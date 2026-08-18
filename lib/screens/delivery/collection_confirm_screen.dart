// lib/screens/delivery/collection_confirm_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/task_provider.dart';

/// Volunteer confirms they have physically collected parcels from the center.
///
/// Displayed after coordinator has confirmed (button becomes active only then).
/// Calls [TaskProvider.confirmCollection] which:
///   1. Parcels: reserved → inTransit
///   2. Task: → inTransit
///   3. Request: → delivering
///
/// On success navigates back to [ActiveTaskScreen] which auto-updates via stream.
class CollectionConfirmScreen extends StatefulWidget {
  final String taskId;
  const CollectionConfirmScreen({super.key, required this.taskId});

  @override
  State<CollectionConfirmScreen> createState() =>
      _CollectionConfirmScreenState();
}

class _CollectionConfirmScreenState extends State<CollectionConfirmScreen> {
  bool _checkedId = false;
  bool _checkedCount = false;
  bool _checkedSealed = false;

  bool get _allChecked => _checkedId && _checkedCount && _checkedSealed;

  Future<void> _confirm(BuildContext context) async {
    if (!_allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete all checks before confirming.')),
      );
      return;
    }
    final ok = await context.read<TaskProvider>().confirmCollection();
    if (ok && context.mounted) {
      // Was context.go(RouteNames.activeTaskPath(widget.taskId)) — go()
      // replaces the entire navigation stack with just this destination,
      // which is why "Active Delivery" had nothing left to pop back to
      // afterward. This screen was reached via context.push() from
      // ActiveTaskScreen (confirmed in active_task_screen.dart), so
      // popping back to that existing instance is both correct and
      // simpler — it's already watching TaskProvider and will show the
      // updated (now inTransit) status automatically via the stream,
      // matching this file's own doc comment: "navigates back to
      // ActiveTaskScreen which auto-updates via stream."
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collection confirmed — head to the victim!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final task = provider.activeTask;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collection Confirm')),
        body: const Center(child: Text('No active task.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Collect Parcels'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primary, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    '${task.parcelsCount} Parcel${task.parcelsCount > 1 ? 's' : ''} Ready',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Complete the checks below before collecting',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Pre-Collection Checklist',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            // ── Checklist ─────────────────────────────────────────────────
            _CheckItem(
              checked: _checkedId,
              title: 'Verify your ID with the coordinator',
              subtitle: 'Show your volunteer ID card or phone number',
              onChanged: (v) => setState(() => _checkedId = v ?? false),
            ),
            const SizedBox(height: 10),
            _CheckItem(
              checked: _checkedCount,
              title: 'Count the parcels',
              subtitle:
                  'Confirm you received exactly ${task.parcelsCount} sealed parcel${task.parcelsCount > 1 ? 's' : ''}',
              onChanged: (v) => setState(() => _checkedCount = v ?? false),
            ),
            const SizedBox(height: 10),
            _CheckItem(
              checked: _checkedSealed,
              title: 'Check seals are intact',
              subtitle: 'All parcels must be factory-sealed before you leave',
              onChanged: (v) => setState(() => _checkedSealed = v ?? false),
            ),

            const SizedBox(height: 30),

            // ── Error ─────────────────────────────────────────────────────
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

            // ── Confirm button ─────────────────────────────────────────────
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(provider.isConfirmingCollection
                    ? 'Confirming…'
                    : 'I Have Collected the Parcels'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _allChecked ? AppColors.primary : AppColors.divider,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final bool checked;
  final String title;
  final String subtitle;
  final ValueChanged<bool?> onChanged;

  const _CheckItem({
    required this.checked,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: checked
            ? AppColors.success.withOpacity(0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checked ? AppColors.success : AppColors.divider,
        ),
      ),
      child: CheckboxListTile(
        value: checked,
        onChanged: onChanged,
        activeColor: AppColors.success,
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}