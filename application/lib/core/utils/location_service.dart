import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    debugPrint('LocationService: Initial permission status: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('LocationService: Requesting permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('LocationService: Permission after request: $permission');
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Permission denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: Permission denied forever.');
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    debugPrint('LocationService: Fetching current position...');
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('LocationService: Error getting position: $e');
      return null;
    }
  }

  static double calculateDistanceInKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000;
  }

  static Future<String?> getCityFromCoordinates(double lat, double lng) async {
    try {
      // Need to import 'package:geocoding/geocoding.dart'
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        // Try locality (City) first, then subAdminArea (District), then administrativeArea (State)
        return placemarks.first.locality ??
            placemarks.first.subAdministrativeArea ??
            placemarks.first.administrativeArea;
      }
    } catch (e) {
      // debugPrint('Error getting city: $e');
    }
    return null;
  }
}
