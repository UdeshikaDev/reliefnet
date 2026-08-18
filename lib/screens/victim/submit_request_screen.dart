// lib/screens/victim/submit_request_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/parcel_calculator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../router/route_names.dart';
import '../../services/location/location_service.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/loading_overlay.dart';

/// Screen where a victim submits a new relief request.
///
/// Steps:
///   1. Choose family size (stepper, min 1, max 20)
///   2. Capture GPS location (mocked as Kurunegala centre in Phase 1)
///   3. Take a damage photo with the camera (gallery disabled)
///   4. Tap Submit → RequestProvider.submitRequest()
class SubmitRequestScreen extends StatefulWidget {
  const SubmitRequestScreen({super.key});

  @override
  State<SubmitRequestScreen> createState() => _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  int _familySize = 1;
  File? _photoFile;

  // Previously this screen hardcoded its own _mockLat/_mockLng constants
  // (Kurunegala town centre) instead of using LocationService — which
  // already existed, was already registered in main.dart's provider tree,
  // and was already used by two other screens (register_center_screen.dart,
  // accept_task_screen.dart). [Verified from code via grep] Using the same
  // abstraction here means Phase 2's real GeolocatorService swap covers
  // this screen too, with no extra work.
  double? _lat;
  double? _lng;
  bool _gpsCapturing = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureLocation());
  }

  // ── Camera ─────────────────────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera, // gallery disabled by design
      maxWidth: 1280,
      maxHeight: 960,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _photoFile = File(picked.path));
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _captureLocation() async {
    setState(() {
      _gpsCapturing = true;
      _gpsError = null;
    });
    try {
      final pos = await context.read<LocationService>().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _lat = pos.lat;
        _lng = pos.lng;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gpsError =
            'Could not get your location. Check location permission and try again.';
      });
    } finally {
      if (mounted) setState(() => _gpsCapturing = false);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a damage photo before submitting.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait for your location to be detected before submitting.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final nic = context.read<AuthProvider>().currentUser?.nicNumber ?? '';

    final success = await context.read<RequestProvider>().submitRequest(
      victimUid: uid,
      nicNumber: nic,
      familySize: _familySize,
      lat: _lat!,
      lng: _lng!,
      photoFile: _photoFile,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Request submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(RouteNames.victimHome);
    }
    // Error is displayed via the error banner in the provider.
  }

  @override
  Widget build(BuildContext context) {
    final reqProv = context.watch<RequestProvider>();
    final parcels = calculateParcels(_familySize);

    return LoadingOverlay(
      isLoading: reqProv.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Submit Request',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Error banner ────────────────────────────────────────────
              if (reqProv.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AppErrorBanner(message: reqProv.error!),
                ),

              // ── Section 1: Family Size ──────────────────────────────────
              _SectionCard(
                icon: Icons.group_outlined,
                title: 'Family Size',
                subtitle: 'How many people need support?',
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StepperButton(
                          icon: Icons.remove,
                          onPressed: _familySize > 1
                              ? () => setState(() => _familySize--)
                              : null,
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '$_familySize',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _StepperButton(
                          icon: Icons.add,
                          onPressed: _familySize < 20
                              ? () => setState(() => _familySize++)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You are entitled to $parcels parcel${parcels == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 parcel per 3 family members (rounded up)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Section 2: Your Location ────────────────────────────────
              _SectionCard(
                icon: Icons.location_on_outlined,
                title: 'Your Location',
                subtitle: 'We need your location to dispatch a volunteer.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _gpsError != null
                                ? Icons.location_off_outlined
                                : Icons.my_location,
                            size: 18,
                            color: _gpsError != null
                                ? AppColors.error
                                : AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _gpsError != null
                                      ? 'Location Unavailable'
                                      : (_lat == null
                                            ? 'Detecting Location…'
                                            : 'GPS Location Detected'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _gpsError != null
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ),
                                Text(
                                  _gpsError ??
                                      (_lat == null || _lng == null
                                          ? 'Waiting for GPS…'
                                          : 'Lat: ${_lat!.toStringAsFixed(4)}, Lng: ${_lng!.toStringAsFixed(4)}'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_gpsCapturing)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _gpsCapturing ? null : _captureLocation,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh GPS Location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Section 3: Damage Photo ─────────────────────────────────
              _SectionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Damage Photo',
                subtitle:
                    'A photo of damage is required to verify your request.',
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    if (_photoFile != null) ...[
                      // Photo preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _photoFile!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.success,
                          ),
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
                    ] else ...[
                      // Empty state: camera tap area
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.divider,
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 40,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Tap to Take Photo',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Camera only — gallery is disabled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Submit button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: reqProv.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.divider,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_outlined, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Your request will be reviewed and a volunteer\nwill be dispatched as soon as possible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? AppColors.surfaceAlt : AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 24,
            color: onPressed == null ? AppColors.textHint : Colors.white,
          ),
        ),
      ),
    );
  }
}
