import 'dart:math';

/// Geographic utility helpers used throughout the map and delivery screens.
class GeoUtils {
  GeoUtils._();

  /// Haversine formula — returns distance between two coordinates in **kilometres**.
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Returns a human-readable distance string.
  /// `< 1 km` → `'500 m'`, `>= 1 km` → `'3.2 km'`.
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  /// Returns `true` if [lat] and [lng] are within Sri Lanka's bounding box.
  /// Used to sanity-check GPS captures before submitting requests.
  static bool isWithinSriLanka(double lat, double lng) {
    return lat >= 5.9 && lat <= 9.9 && lng >= 79.5 && lng <= 81.9;
  }

  /// Builds a Google Maps `geo:` URI for the given coordinates.
  /// Used by the "Get Directions" button on the center detail screen.
  static String googleMapsUri(double lat, double lng, {String? label}) {
    final labelPart = label != null ? Uri.encodeComponent(label) : '';
    return 'geo:$lat,$lng?q=$lat,$lng($labelPart)';
  }

  static double _toRad(double deg) => deg * pi / 180;
}