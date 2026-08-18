// lib/widgets/common/get_directions_button.dart

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/maps_launcher.dart';

class GetDirectionsButton extends StatelessWidget {
  final double lat;
  final double lng;
  final String label;

  const GetDirectionsButton({
    super.key,
    required this.lat,
    required this.lng,
    this.label = 'Get Directions',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => MapsLauncher.openDirections(
          context: context,
          lat: lat,
          lng: lng,
        ),
        icon: const Icon(Icons.directions_outlined, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
