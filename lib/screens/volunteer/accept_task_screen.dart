// lib/screens/volunteer/accept_task_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/geo_utils.dart';
import '../../models/donation_center_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/task_provider.dart';
import '../../router/route_names.dart';
import '../../services/location/location_service.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/confirmation_dialog.dart';

class AcceptTaskScreen extends StatefulWidget {
  final String requestId;
  const AcceptTaskScreen({super.key, required this.requestId});
  @override
  State<AcceptTaskScreen> createState() => _AcceptTaskScreenState();
}

class _AcceptTaskScreenState extends State<AcceptTaskScreen> {
  DonationCenterModel? _selectedCenter;

  // Real, live "available"-status parcel counts per centerId, fetched
  // directly from ParcelService (via TaskProvider) — NOT from
  // DonationCenterModel.availableParcels, which mirrors this same number
  // onto the center doc for other screens' convenience but can be a
  // network round-trip stale (see TaskProvider.getAvailableParcelCount
  // doc comment). A center is only shown/selectable once its real count
  // is known.
  final Map<String, int> _availableCounts = {};
  final Set<String> _countsRequestedFor = {};
  bool _countsLoading = false;

  // Volunteer GPS — loaded from LocationService in initState.
  // Phase 1: MockLocationService returns fixed Kurunegala coords.
  // Phase 2: Geolocator.getCurrentPosition() returns real coords.
  double? _volunteerLat;
  double? _volunteerLng;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocation();

      // Load request details if not already cached.
      final rp = context.read<RequestProvider>();
      if (rp.viewingRequest?.requestId != widget.requestId) {
        rp.loadRequestById(widget.requestId);
      }

      // Ensure donation centers are loaded.
      final mp = context.read<MapProvider>();
      if (mp.filteredCenters.isEmpty) mp.startListening();
    });
  }

  /// Fetches the volunteer's current GPS location and triggers a rebuild
  /// so the center list sorts by distance.
  Future<void> _loadLocation() async {
    try {
      final loc = context.read<LocationService>();
      final pos = await loc.getCurrentLocation();
      if (mounted) {
        setState(() {
          _volunteerLat = pos.lat;
          _volunteerLng = pos.lng;
          _locationLoading = false;
        });
      }
    } catch (_) {
      // Location unavailable — still show centers, just unsorted.
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  /// Returns centers that:
  ///   1. Have enough available parcels for this request.
  ///   2. Are active.
  ///   3. Sorted nearest-first when GPS is available.
  List<DonationCenterModel> _sortedAvailable(
      List<DonationCenterModel> all, int parcelsNeeded) {
    final filtered = all.where((c) {
      final realCount = _availableCounts[c.centerId];
      // Hide until we actually know the live count — never fall back to
      // the cached availableParcels field (let alone packingCapacity,
      // which isn't even the same kind of number), which is what caused
      // "not enough parcels" errors on centers the UI said were fine.
      if (realCount == null) return false;
      return c.isActive && realCount >= parcelsNeeded;
    }).toList();

    if (_volunteerLat != null && _volunteerLng != null) {
      filtered.sort((a, b) {
        final dA =
            GeoUtils.distanceKm(a.lat, a.lng, _volunteerLat!, _volunteerLng!);
        final dB =
            GeoUtils.distanceKm(b.lat, b.lng, _volunteerLat!, _volunteerLng!);
        return dA.compareTo(dB);
      });
    }

    return filtered;
  }

  /// Fetches the real, live available-parcel count for each center in
  /// [centers] and merges the results into [_availableCounts]. Safe to
  /// call repeatedly — e.g. once when centers first load, and again after
  /// a failed [_confirm] so the list re-syncs with whatever the backend
  /// just found to be true.
  Future<void> _loadAvailableCounts(List<DonationCenterModel> centers) async {
    if (!mounted) return;
    setState(() => _countsLoading = true);
    final tp = context.read<TaskProvider>();
    final results = <String, int>{};
    await Future.wait(centers.map((c) async {
      try {
        results[c.centerId] = await tp.getAvailableParcelCount(c.centerId);
      } catch (_) {
        // Leave this center's count unset on failure — it simply won't be
        // shown as eligible until a retry succeeds, rather than trusting
        // a stale/guessed number.
      }
    }));
    if (!mounted) return;
    setState(() {
      _availableCounts.addAll(results);
      _countsLoading = false;
    });
  }

  double? _distanceTo(DonationCenterModel center) {
    if (_volunteerLat == null || _volunteerLng == null) return null;
    return GeoUtils.distanceKm(
        center.lat, center.lng, _volunteerLat!, _volunteerLng!);
  }

  Future<void> _confirm() async {
    if (_selectedCenter == null) return;
    final req = context.read<RequestProvider>().viewingRequest;
    if (req == null) return;

    final bool? ok = await showConfirmationDialog(
      context,
      title: 'Confirm Task',
      message: 'Accept delivery from ${_selectedCenter!.name}?\n\n'
          '${req.parcelsEntitled} '
          'parcel${req.parcelsEntitled != 1 ? 's' : ''} will be reserved.',
      confirmLabel: 'Accept',
    );
    if (ok != true || !mounted) return;

    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final success = await context.read<TaskProvider>().acceptTask(
          centerId: _selectedCenter!.centerId,
          requestId: req.requestId,
          victimUid: req.victimUid,
          volunteerUid: uid,
          parcelsNeeded: req.parcelsEntitled,
        );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Task accepted! Parcels reserved.'),
        backgroundColor: AppColors.success,
      ));
      context.go(RouteNames.volunteerHome);
    } else {
      // Reservation failed live at the backend (e.g. another volunteer
      // just took the last parcels) — re-sync the real counts so the
      // list reflects what's actually true before the volunteer retries.
      final mp = context.read<MapProvider>();
      _loadAvailableCounts(mp.filteredCenters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();
    final tp = context.watch<TaskProvider>();
    final mp = context.watch<MapProvider>();
    final req = rp.viewingRequest;

    // Kick off real-count fetching for any newly-seen centers. Guarded by
    // _countsRequestedFor so this only fires once per center list, not on
    // every rebuild.
    final centerIds = mp.filteredCenters.map((c) => c.centerId).toSet();
    final newIds = centerIds.difference(_countsRequestedFor);
    if (newIds.isNotEmpty) {
      _countsRequestedFor.addAll(newIds);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAvailableCounts(mp.filteredCenters);
      });
    }

    final available = req != null
        ? _sortedAvailable(mp.filteredCenters, req.parcelsEntitled)
        : <DonationCenterModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Accept Task',
            style: TextStyle(fontWeight: FontWeight.bold,)),
      ),
      body: rp.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : req == null
              ? const Center(child: Text('Request not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Request summary ─────────────────────────────────
                      _RequestSummaryCard(
                          familySize: req.familySize,
                          parcels: req.parcelsEntitled),
                      const SizedBox(height: 20),

                      // ── Error banner ────────────────────────────────────
                      if (tp.error != null) ...[
                        AppErrorBanner(message: tp.error!),
                        const SizedBox(height: 14),
                      ],

                      // ── Section label ───────────────────────────────────
                      Row(
                        children: [
                          const Text(
                            'Select Donation Center',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          // GPS status indicator
                          if (_locationLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            )
                          else if (_volunteerLat != null)
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_fixed,
                                    size: 14, color: AppColors.success),
                                SizedBox(width: 4),
                                Text('Sorted by distance',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.success))
                              ],
                            )
                          else
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_off,
                                    size: 14, color: AppColors.textHint),
                                SizedBox(width: 4),
                                Text('Location unavailable',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Centers with ≥${req.parcelsEntitled} parcels, nearest first',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),

                      // ── Center list ─────────────────────────────────────
                      if (_countsLoading && _availableCounts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      else if (available.isEmpty)
                        _NoCentersCard(parcels: req.parcelsEntitled)
                      else
                        ...available.map((c) => _CenterTile(
                              center: c,
                              availableCount: _availableCounts[c.centerId],
                              isSelected:
                                  _selectedCenter?.centerId == c.centerId,
                              distance: _distanceTo(c),
                              onTap: () =>
                                  setState(() => _selectedCenter = c),
                            )),

                      const SizedBox(height: 28),

                      // ── Confirm button ──────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              (_selectedCenter == null || tp.isLoading)
                                  ? null
                                  : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.divider,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: tp.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Confirm & Accept Task',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Request Summary Card ───────────────────────────────────────────────────────

class _RequestSummaryCard extends StatelessWidget {
  final int familySize;
  final int parcels;
  const _RequestSummaryCard(
      {required this.familySize, required this.parcels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.family_restroom,
              color: AppColors.primary, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family of $familySize',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              Text(
                '$parcels parcel${parcels != 1 ? 's' : ''} needed',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Center Tile ────────────────────────────────────────────────────────────────

class _CenterTile extends StatelessWidget {
  final DonationCenterModel center;
  final int? availableCount; // real, live count — null falls back to cached
  final bool isSelected;
  final double? distance; // km — null when GPS unavailable
  final VoidCallback onTap;

  const _CenterTile({
    required this.center,
    required this.availableCount,
    required this.isSelected,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            Radio<String>(
              value: center.centerId,
              groupValue: isSelected ? center.centerId : null,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),

            // Center info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    center.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Distance + parcel badges.
                  // Wrap (not Row) so that on narrow widths, or when the
                  // bottleneck-item badge has a long label, badges flow
                  // onto a second line instead of overflowing the tile.
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Distance badge
                      if (distance != null)
                        _Badge(
                          icon: Icons.place_outlined,
                          label: GeoUtils.formatDistance(distance!),
                          color: AppColors.primary,
                        ),

                      // Parcels available badge — real live count, the
                      // same number reserveParcels() will check against.
                      // Fallback to availableParcels (the cached mirror
                      // of this same real count) rather than
                      // packingCapacity — this tile only ever renders for
                      // centers _sortedAvailable already confirmed have a
                      // known live count, so the fallback is defensive
                      // only, but it should still be the right *kind* of
                      // number if it's ever hit.
                      _Badge(
                        icon: Icons.inventory_2_outlined,
                        label:
                            '${availableCount ?? center.availableParcels} parcels',
                        color: AppColors.success,
                      ),

                      // Bottleneck warning
                      if (center.bottleneckItem != null)
                        _Badge(
                          icon: Icons.warning_amber_outlined,
                          label: 'Low: ${center.bottleneckItem}',
                          color: AppColors.warning,
                        ),
                    ],
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

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Caps how wide a single badge can grow — long bottleneck-item
      // names get ellipsized inside the badge instead of pushing its
      // width past what the row/wrap has available.
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No Centers Card ────────────────────────────────────────────────────────────

class _NoCentersCard extends StatelessWidget {
  final int parcels;
  const _NoCentersCard({required this.parcels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 40, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(
            'No centers have $parcels+ parcels available',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try again later when more stock is logged.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}