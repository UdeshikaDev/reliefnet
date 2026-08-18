import 'dart:async';
import '../location/location_service.dart';

/// Mock implementation of [LocationService].
/// Returns a fixed coordinate in Kurunegala, Sri Lanka.
class MockLocationService implements LocationService {
  @override
  Future<({double lat, double lng})> getCurrentLocation() async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Kurunegala city center — realistic default
    return (lat: 7.4818, lng: 80.3609);
  }

  @override
  Future<String?> getAddressFromCoords(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'No. 42, Rajapihilla Road, Kurunegala 60000, Sri Lanka';
  }
}