// lib/screens/volunteer/request_map_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/relief_request_model.dart';
import '../../providers/request_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/map/victim_marker.dart';

class RequestMapScreen extends StatefulWidget {
  const RequestMapScreen({super.key});
  @override
  State<RequestMapScreen> createState() => _RequestMapScreenState();
}

class _RequestMapScreenState extends State<RequestMapScreen> {
  GoogleMapController? _mapController;
  ReliefRequestModel? _selected;
  final Set<Marker> _markers = {};

  static const _initial = CameraPosition(
    target: LatLng(7.4818, 80.3609),
    zoom: 11.5,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<RequestProvider>().loadPendingRequests();
      if (mounted) _buildMarkers();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Builds the marker set from the current pending-requests list.
  ///
  /// FIX 1: uses `requestId:` (not `id:`)
  /// FIX 2: passes required `snippet:` string
  /// FIX 3: `onTap` is VoidCallback — capture `req` in the closure
  /// FIX 4: `buildMarker` returns Marker directly — no `.then()`
  void _buildMarkers() {
    final requests = context.read<RequestProvider>().pendingRequests;
    final built = <Marker>{};

    for (final req in requests) {
      final marker = VictimMarkerHelper.buildMarker(
        requestId: req.requestId,                               // FIX 1
        lat: req.lat,
        lng: req.lng,
        snippet:                                                // FIX 2
            'Family of ${req.familySize} · ${req.parcelsEntitled} '
            'parcel${req.parcelsEntitled != 1 ? 's' : ''}',
        onTap: () => setState(() => _selected = req),          // FIX 3
      );
      built.add(marker);                                        // FIX 4 — no .then()
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(built);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Pending Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_outlined),
            tooltip: 'List view',
            onPressed: () => context.push(RouteNames.requestList),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map / loading / error ─────────────────────────────────────────
          if (rp.isLoading && rp.pendingRequests.isEmpty)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (rp.error != null && rp.pendingRequests.isEmpty)
            Center(child: AppErrorWidget(message: rp.error!))
          else
            GoogleMap(
              initialCameraPosition: _initial,
              onMapCreated: (c) => _mapController = c,
              markers: _markers,
              onTap: (_) => setState(() => _selected = null),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

          // ── Count badge ───────────────────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10), // FIX 5
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '${rp.pendingRequests.length} pending',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // ── Bottom sheet on pin tap ───────────────────────────────────────
          if (_selected != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _RequestSheet(
                request: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _RequestSheet extends StatelessWidget {
  final ReliefRequestModel request;
  final VoidCallback onClose;

  const _RequestSheet({required this.request, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final verified = request.photoMetadataVerified;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Family + parcel row
          Row(
            children: [
              const Icon(Icons.family_restroom,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Family of ${request.familySize}  ·  '
                  '${request.parcelsEntitled} '
                  'parcel${request.parcelsEntitled != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close,
                    size: 20, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Verification badge + View Details button
          Row(
            children: [
              Icon(
                verified
                    ? Icons.verified_outlined
                    : Icons.hourglass_empty_outlined,
                size: 14,
                color: verified ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                verified ? 'Photo Verified' : 'Under Review',
                style: TextStyle(
                  fontSize: 12,
                  color: verified ? AppColors.success : AppColors.warning,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.push(
                  RouteNames.requestDetailVolPath(request.requestId),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}