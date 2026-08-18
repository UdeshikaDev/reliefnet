import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_center_model.dart';
import '../../providers/map_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/map/center_marker.dart';
import '../../widgets/map/map_fab.dart';
import 'center_detail_public_screen.dart';
import 'package:go_router/go_router.dart';

/// Public map screen — no login required.
///
/// Shows all active donation centers as colored pins on Google Maps.
/// Filter chips narrow results. Tapping a pin opens a bottom-sheet detail.
/// An expandable FAB offers "I Need Help" / "I Want to Help" shortcuts.
class PublicMapScreen extends StatefulWidget {
  const PublicMapScreen({super.key});

  @override
  State<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends State<PublicMapScreen> {
  GoogleMapController? _mapController;

  // Sri Lanka centre — default camera position.
  static const _initialCamera = CameraPosition(
    target: LatLng(7.5554, 80.3147), // Central Sri Lanka
    zoom: 9.5,
  );

  @override
  void initState() {
    super.initState();
    // Start streaming center data as soon as the screen mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Build markers from filtered centers ─────────────────────────────────

  Set<Marker> _buildMarkers(List<DonationCenterModel> centers) {
    return centers.map((center) {
      return CenterMarkerHelper.buildMarker(
        center: center,
        onTap: () => _onMarkerTapped(center),
      );
    }).toSet();
  }

  // ── Marker tap → select center → show bottom sheet ───────────────────────

  void _onMarkerTapped(DonationCenterModel center) {
    context.read<MapProvider>().selectCenter(center);
    _showCenterBottomSheet(center);
  }

  void _showCenterBottomSheet(DonationCenterModel center) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CenterDetailPublicScreen(center: center),
    ).then((_) {
      // Deselect when sheet is dismissed.
      if (mounted) {
        context.read<MapProvider>().selectCenter(null);
      }
    });
  }

  // ── Filter chip row ──────────────────────────────────────────────────────

  Widget _buildFilterChips(MapProvider mapProv) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: MapFilter.values.map((filter) {
            final isSelected = mapProv.activeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(mapProv.filterLabel(filter)),
                selected: isSelected,
                onSelected: (_) => mapProv.setFilter(filter),
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                backgroundColor: AppColors.surfaceAlt,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<MapProvider>();
    final centers = mapProv.filteredCenters;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'ReliefNet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(RouteNames.phoneEntry),
            icon: const Icon(Icons.login, size: 18, color: AppColors.primary),
            label: const Text(
              'Sign In',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ────────────────────────────────────────────
          _buildFilterChips(mapProv),

          const Divider(height: 1, color: AppColors.divider),

          // ── Map + overlays ──────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Error state
                if (mapProv.error != null && !mapProv.isLoading)
                  AppErrorWidget(
                    message: mapProv.error!,
                    onRetry: mapProv.startListening,
                  )

                // Loading state
                else if (mapProv.isLoading)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Loading donation centers…',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )

                // Map
                else
                  GoogleMap(
                    initialCameraPosition: _initialCamera,
                    markers: _buildMarkers(centers),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: (_) {
                      // Tap on empty map = deselect any selected center
                      context.read<MapProvider>().selectCenter(null);
                    },
                  ),

                // Empty filter state (shown on top of map)
                if (!mapProv.isLoading &&
                    mapProv.error == null &&
                    centers.isEmpty)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.85),
                      child: EmptyStateWidget(
                        icon: Icons.location_off_outlined,
                        title: mapProv.activeFilter == MapFilter.critical
                            ? 'No Critical Centers'
                            : 'No Centers Found',
                        subtitle: mapProv.activeFilter == MapFilter.highStock
                            ? 'No centers currently have 10+ parcels. Check back soon.'
                            : 'All centers are stocked. Great news!',
                        action: TextButton(
                          onPressed: () =>
                              mapProv.setFilter(MapFilter.all),
                          child: const Text('Show All Centers'),
                        ),
                      ),
                    ),
                  ),

                // Legend — top-right overlay
                if (!mapProv.isLoading && mapProv.error == null)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: MarkerLegend(),
                  ),

                // Center count badge — top-left overlay
                if (!mapProv.isLoading && mapProv.error == null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${centers.length} center${centers.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      // Expandable FAB — "I Need Help" / "I Want to Help"
      floatingActionButton: const MapFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}