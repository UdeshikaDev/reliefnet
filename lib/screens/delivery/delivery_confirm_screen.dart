// lib/screens/delivery/delivery_confirm_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/request_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';
import '../../services/storage/storage_service.dart';
import '../../widgets/common/center_name_text.dart';
import '../../widgets/common/get_directions_button.dart';

/// Previously this screen went straight from a summary card to "Scan Victim
/// QR Code" with no photo step at all — the completion photo requirement
/// wasn't implemented anywhere in the app (confirmDelivery's
/// completionPhotoUrl was always a hardcoded placeholder). This now
/// requires a real camera photo before the scan button is enabled, and
/// uploads it via StorageService (MockStorageService.uploadHandoverPhoto,
/// which already existed but was never called from anywhere — [Verified
/// from code]).
class DeliveryConfirmScreen extends StatefulWidget {
  final String taskId;
  const DeliveryConfirmScreen({super.key, required this.taskId});

  @override
  State<DeliveryConfirmScreen> createState() => _DeliveryConfirmScreenState();
}

class _DeliveryConfirmScreenState extends State<DeliveryConfirmScreen> {
  File? _photoFile;
  bool _uploading = false;

  Future<void> _takePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera, // camera only, same policy as damage photos
      maxWidth: 1280,
      maxHeight: 960,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _photoFile = File(picked.path));
  }

  Future<void> _proceedToScan() async {
    final photoFile = _photoFile;
    if (photoFile == null) return;

    // Captured before the first await, not after — same reasoning as the
    // active_task_screen.dart dispose() fix earlier in this conversation:
    // if the widget were unmounted during the awaited file read below,
    // calling context.read() afterward could throw on a deactivated
    // context. flutter analyze's use_build_context_synchronously lint
    // flagged the original ordering; this addresses that directly rather
    // than just silencing the warning.
    final storageService = context.read<StorageService>();

    setState(() => _uploading = true);
    String? photoUrl;
    try {
      final bytes = await photoFile.readAsBytes();
      final fileName =
          'handover_${widget.taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      photoUrl =
          await storageService.uploadHandoverPhoto(widget.taskId, bytes, fileName);
    } catch (_) {
      // Upload failed — fall back to null rather than blocking the
      // handover entirely; QrScannerScreen/confirmDelivery already treat
      // completionPhotoUrl as optional.
      photoUrl = null;
    }
    if (!mounted) return;
    setState(() => _uploading = false);

    context.push(
      RouteNames.qrScannerPath(widget.taskId),
      extra: photoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final task = provider.activeTask;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Delivery')),
        body: const Center(child: Text('No active task.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Delivery'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_outlined,
                    color: AppColors.success, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Ready to Deliver',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Take a completion photo, then ask the victim to show their QR code to confirm delivery.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _DeliveryRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Parcels to deliver',
                    value: '${task.parcelsCount} sealed parcel${task.parcelsCount > 1 ? 's' : ''}',
                  ),
                  const Divider(height: 16, color: AppColors.divider),
                  _DeliveryRow(
                    icon: Icons.warehouse_outlined,
                    label: 'From center',
                    value: task.centerId,
                    valueWidget: CenterNameText(centerId: task.centerId),
                  ),
                  const Divider(height: 16, color: AppColors.divider),
                  _DeliveryRow(
                    icon: Icons.person_outline,
                    label: 'Recipient',
                    value: '${task.victimUid.substring(0, 12)}…',
                    valueWidget: FutureBuilder(
                      future: context
                          .read<UserProvider>()
                          .fetchUserById(task.victimUid),
                      builder: (context, snapshot) {
                        final name = snapshot.data?.displayName;
                        final shortUid = task.victimUid.length > 12
                            ? '${task.victimUid.substring(0, 12)}…'
                            : task.victimUid;
                        return Text(
                          name ?? shortUid,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Get directions to victim ─────────────────────────────────
            // Previously there was no way to get directions to the victim
            // from this screen at all.
            FutureBuilder(
              future: context.read<RequestProvider>().loadRequest(task.requestId),
              builder: (context, snapshot) {
                final request = snapshot.data;
                if (request == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GetDirectionsButton(
                    lat: request.lat,
                    lng: request.lng,
                    label: 'Get Directions to Victim',
                  ),
                );
              },
            ),

            // ── Completion photo ─────────────────────────────────────────
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
                  const Row(
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Completion Photo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_photoFile != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _photoFile!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        const Text(
                          'Photo captured',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _takePhoto,
                          child: const Text('Retake'),
                        ),
                      ],
                    ),
                  ] else
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 34, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text(
                              'Tap to Take Photo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Once you scan the QR, the receipt is sealed and cannot be changed.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_photoFile == null || _uploading) ? null : _proceedToScan,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.qr_code_scanner, size: 20),
                label: Text(_uploading ? 'Uploading photo…' : 'Scan Victim QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.divider,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (_photoFile == null) ...[
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Take a completion photo to continue',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;
  const _DeliveryRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              valueWidget ??
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}