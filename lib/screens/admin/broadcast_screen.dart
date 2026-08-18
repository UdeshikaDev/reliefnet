// lib/screens/admin/broadcast_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/broadcast_target.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/loading_overlay.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  BroadcastTarget _target = BroadcastTarget.allUsers;

  @override
  void initState() {
    super.initState();
    // Reset any previous success/error state from AdminProvider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().resetBroadcastState();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    final success = await context.read<AdminProvider>().sendBroadcast(
          target: _target,
          title: title,
          body: body,
        );

    if (success && mounted) {
      // Clear form after successful send.
      _titleController.clear();
      _bodyController.clear();
      setState(() => _target = BroadcastTarget.allUsers);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Broadcast sent to ${_target.label}.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();

    return LoadingOverlay(
      isLoading: adminProv.isSendingBroadcast,
      child: Scaffold(
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
            'Emergency Broadcast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.campaign_rounded,
                          color: AppColors.warning, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This sends a push notification to all selected users. '
                          'Use for emergencies only.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.warning,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (adminProv.error != null) ...[
                  AppErrorBanner(message: adminProv.error!),
                  const SizedBox(height: 16),
                ],

                // Target selector
                const Text(
                  'Send To',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BroadcastTarget>(
                      value: _target,
                      isExpanded: true,
                      icon: const Icon(Icons.expand_more_rounded,
                          color: AppColors.primary),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (t) {
                        if (t != null) setState(() => _target = t);
                      },
                      items: BroadcastTarget.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title field
                const Text(
                  'Notification Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('e.g. Flood Warning — Kurunegala'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a notification title.';
                    }
                    if (v.trim().length > 100) {
                      return 'Title must be 100 characters or fewer.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Message field
                const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bodyController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    'Write your emergency message here…',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a message body.';
                    }
                    if (v.trim().length > 500) {
                      return 'Message must be 500 characters or fewer.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Send button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        adminProv.isSendingBroadcast ? null : _send,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text('Send Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠️  Broadcasts cannot be recalled once sent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}