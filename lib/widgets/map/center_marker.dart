import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_center_model.dart';

/// Pin color rules:
/// - Green  (hue 140) = availableParcels >= 10  → Well Stocked
/// - Orange (hue 30)  = availableParcels 1–9    → Low Stock
/// - Red    (hue 0)   = availableParcels == 0   → Critical
///
/// [Fix — architectural] Reads [DonationCenterModel.availableParcels] (the
/// real, live "ready right now" count) rather than the old
/// `maxParcelsAvailable` (renamed [DonationCenterModel.packingCapacity]),
/// which was only ever raw-stock kit potential — a center could show a
/// green "Well Stocked" pin here while having zero actual parcels a
/// volunteer could collect.
class CenterMarkerHelper {
  CenterMarkerHelper._();

  static BitmapDescriptor descriptorFor(DonationCenterModel center) {
    final hue = _hueFor(center.availableParcels);
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  static double _hueFor(int parcels) {
    if (parcels >= 10) return BitmapDescriptor.hueGreen;
    if (parcels > 0)   return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueRed;
  }

  // ── Availability label (no parcel count shown to public) ──────────────────
  static String _snippetFor(DonationCenterModel center) {
    if (center.availableParcels == 0) {
      return center.bottleneckItem != null
          ? 'Critical — needs ${center.bottleneckItem}'
          : 'Out of Stock';
    }
    if (center.availableParcels < 10) {
      return center.bottleneckItem != null
          ? 'Low Stock — needs ${center.bottleneckItem}'
          : 'Low Stock';
    }
    return 'Well Stocked';
  }

  static Marker buildMarker({
    required DonationCenterModel center,
    required VoidCallback onTap,
  }) {
    return Marker(
      markerId: MarkerId(center.centerId),
      position: LatLng(center.lat, center.lng),
      icon: descriptorFor(center),
      infoWindow: InfoWindow(
        title: center.name,
        snippet: _snippetFor(center),   // ← no parcel count
      ),
      onTap: onTap,
    );
  }
}

/// Small color-coded legend chip shown on the map overlay (top-right).
class MarkerLegend extends StatelessWidget {
  const MarkerLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendRow(color: AppColors.success, label: 'Well Stocked'),
          SizedBox(height: 4),
          _LegendRow(color: AppColors.warning, label: 'Low Stock'),
          SizedBox(height: 4),
          _LegendRow(color: AppColors.error,   label: 'Critical'),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}