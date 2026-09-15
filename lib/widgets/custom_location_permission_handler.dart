import 'dart:developer';
import 'package:geolocator/geolocator.dart';

class CustomLocationPermissionHandler {
  CustomLocationPermissionHandler._();

  /// Returns the current Position, or null if permission is denied
  /// or location services are disabled.
  /// Never throws — the app must remain functional without location.
  static Future<Position?> determinePosition() async {
    final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;

    try {
      // 1. Check if location services are enabled on the device
      final bool serviceEnabled =
      await geolocatorPlatform.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services are disabled on device.');
        return null;
      }

      // 2. Check current permission
      LocationPermission permission =
      await geolocatorPlatform.checkPermission();

      // 3. Request permission if not yet decided
      if (permission == LocationPermission.denied) {
        permission = await geolocatorPlatform.requestPermission();
      }

      // 4. If denied or denied forever, return null (do NOT throw)
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log('Location permission denied. App will run without it.');
        return null;
      }

      // 5. Permission granted — get current position
      return await geolocatorPlatform.getCurrentPosition();
    } catch (e) {
      log('determinePosition error: $e');
      return null;
    }
  }
}