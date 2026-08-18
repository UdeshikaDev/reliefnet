// lib/services/location/location_service_impl.dart
//
// Phase 2 implementation of LocationService, backed by geolocator +
// geocoding (both already in pubspec.yaml — this isn't a Firebase
// service, hence the different naming convention and folder from the
// services/firebase/* classes, matching the `→ LocationServiceImpl()`
// hint already left in main.dart's comments).
//
// Drop-in replacement for MockLocationService: TaskProvider
// (confirmCollection/confirmDelivery GPS capture) and SubmitRequestScreen
// only depend on the abstract LocationService interface, so no
// provider/screen changes are needed beyond wiring this into main.dart.
//
// Requires location permission entries in the native project files —
// neither was in the uploaded lib.zip (only lib/ was included, not
// android/ or ios/), so these need to be added by hand:
//
//   android/app/src/main/AndroidManifest.xml, inside <manifest>, before <application>:
//     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//     <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
//
//   ios/Runner/Info.plist, inside the outer <dict>:
//     <key>NSLocationWhenInUseUsageDescription</key>
//     <string>ReliefNet needs your location to find nearby donation centers and confirm deliveries.</string>
//
// [Unverified] Checked by hand against current geolocator/geocoding usage
// — not run on a physical device or emulator from here.

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../../core/errors/app_exception.dart';
import 'location_service.dart';

class LocationServiceImpl implements LocationService {
  @override
  Future<({double lat, double lng})> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const PermissionException(
          'location (GPS is turned off — please enable it in device settings)');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionException('location');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const PermissionException(
          'location (permanently denied — enable it from device settings)');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (lat: position.latitude, lng: position.longitude);
  }

  @override
  Future<String?> getAddressFromCoords(double lat, double lng) async {
    // Per the interface's own doc comment: "Returns null if geocoding
    // fails" — so any failure here (no network, no result, plugin error)
    // just returns null rather than throwing, matching that contract
    // exactly.
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [p.street, p.subLocality, p.locality, p.postalCode, p.country]
          .where((s) => s != null && s.trim().isNotEmpty)
          .join(', ');
      return parts.isEmpty ? null : parts;
    } catch (_) {
      return null;
    }
  }
}
