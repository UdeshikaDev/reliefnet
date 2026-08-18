// lib/screens/volunteer/register_center_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/parcel_blueprint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/centers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../router/route_names.dart';
import '../../services/location/location_service.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/relief_button.dart';
import '../../widgets/common/relief_text_field.dart';

class RegisterCenterScreen extends StatefulWidget {
  const RegisterCenterScreen({super.key});
  @override
  State<RegisterCenterScreen> createState() => _RegisterCenterScreenState();
}

class _RegisterCenterScreenState extends State<RegisterCenterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();

  double? _lat, _lng;
  bool    _gpsLoading = false;
  String? _gpsError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() { _gpsLoading = true; _gpsError = null; });
    try {
      final loc  = context.read<LocationService>();
      final pos  = await loc.getCurrentLocation();
      final addr = await loc.getAddressFromCoords(pos.lat, pos.lng);
      setState(() { _lat = pos.lat; _lng = pos.lng; });
      if (addr != null && _addressCtrl.text.isEmpty) _addressCtrl.text = addr;
    } catch (_) {
      setState(() => _gpsError = 'Could not capture location. Try again.');
    } finally {
      setState(() => _gpsLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null) {
      setState(() => _gpsError = 'Please capture your GPS location first.');
      return;
    }
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final cp  = context.read<CentersProvider>();
    final ip  = context.read<InventoryProvider>();

    final centerId = await cp.registerCenter(
      name:         _nameCtrl.text.trim(),
      address:      _addressCtrl.text.trim(),
      lat:          _lat!,
      lng:          _lng!,
      volunteerUid: uid,
    );
    if (!mounted) return;
    if (centerId != null) {
      await ip.initializeInventoryForCenter(
          centerId, ParcelBlueprintModel.defaultBlueprint);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Center registered! Visible on the public map.'),
        backgroundColor: AppColors.success,
      ));
      context.push(RouteNames.myCenters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CentersProvider>();

    return LoadingOverlay(
      isLoading: cp.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Register New Center',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Error banner ──────────────────────────────────────────
                if (cp.error != null) ...[
                  AppErrorBanner(message: cp.error!),
                  const SizedBox(height: 14),
                ],

                // ── Center name ───────────────────────────────────────────
                // FIX: prefixIcon → prefix, IconData → Icon widget
                ReliefTextField(
                  label: 'Center Name',
                  hint: 'e.g. Kurunegala Relief Hub',
                  controller: _nameCtrl,
                  prefix: const Icon(             // FIX 1a
                    Icons.store_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Center name is required.'
                      : null,
                ),
                const SizedBox(height: 14),

                // ── Address ───────────────────────────────────────────────
                ReliefTextField(
                  label: 'Address',
                  hint: 'e.g. No. 12, Main Street, Kurunegala',
                  controller: _addressCtrl,
                  maxLines: 2,
                  prefix: const Icon(             // FIX 1b
                    Icons.place_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Address is required.'
                      : null,
                ),
                const SizedBox(height: 20),

                // ── GPS location ──────────────────────────────────────────
                const Text(
                  'Center Location',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                if (_lat != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08), // FIX 3a
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.30)), // FIX 3b
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed,
                            color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_lat!.toStringAsFixed(4)}, '
                          '${_lng!.toStringAsFixed(4)}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (_gpsError != null) ...[
                  Text(_gpsError!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.error)),
                  const SizedBox(height: 8),
                ],

                ReliefButton(
                  label: _lat != null
                      ? 'Re-capture Location'
                      : 'Use My GPS Location',
                  onPressed: _gpsLoading ? null : _captureGps,
                  isLoading: _gpsLoading,
                  icon: Icons.my_location,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Phase 2: opens Google Maps pin confirmation.',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
                const SizedBox(height: 32),

                // ── Register button ───────────────────────────────────────
                ReliefButton(
                  label: 'Register Center',
                  onPressed: cp.isLoading ? null : _register,
                  isLoading: cp.isLoading,
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'The center appears on the public map immediately.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}