/// Abstract interface for GPS operations.
/// Phase 2 implementation uses `geolocator` + `geocoding`.
abstract class LocationService {
  /// Returns the device's current GPS coordinates.
  /// Throws [PermissionException] if location permission is denied.
  Future<({double lat, double lng})> getCurrentLocation();

  /// Reverse-geocodes a lat/lng pair to a human-readable address string.
  /// Returns `null` if geocoding fails.
  Future<String?> getAddressFromCoords(double lat, double lng);
}