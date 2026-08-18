import 'package:flutter/material.dart'; // ← ADD THIS LINE
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Victim request marker helper.
/// Uses a cyan hue to distinguish from center pins.
class VictimMarkerHelper {
  VictimMarkerHelper._();

  static Marker buildMarker({
    required String requestId,
    required double lat,
    required double lng,
    required String snippet,
    required VoidCallback onTap,
  }) {
    return Marker(
      markerId: MarkerId('victim_$requestId'),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      infoWindow: InfoWindow(
        title: 'Request',
        snippet: snippet,
      ),
      onTap: onTap,
    );
  }
}