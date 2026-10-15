import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../config/campus_config.dart';

class CampusLocationService {
  const CampusLocationService();

  static const MethodChannel _deviceIntegrityChannel = MethodChannel(
    'com.snapmark/device_integrity',
  );

  /// Returns null only when the reported position is confidently inside campus.
  Future<String?> checkCampusLocation() async {
    if (!CampusConfig.isConfigured) {
      return 'Campus location is not configured. Ask your administrator to set the campus coordinates and radius.';
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Turn on Location on your phone to mark attendance.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return 'Location permission is needed to check that you are on campus.';
      }
      if (permission == LocationPermission.deniedForever) {
        return 'Location permission is blocked. Allow it for SnapMark in your phone settings, then try again.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final result = await _deviceIntegrityChannel.invokeMapMethod<String, dynamic>(
            'verifyAttendanceLocation',
            <String, Object>{
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'fixTimeMillis': position.timestamp.millisecondsSinceEpoch,
              'isMocked': position.isMocked,
              'campusLatitude': CampusConfig.latitude!,
              'campusLongitude': CampusConfig.longitude!,
              'radiusMeters': CampusConfig.radiusMeters!,
            },
          );
          if (result == null) {
            return 'SnapMark could not verify the Android attendance security checks. Please retry.';
          }
          return result['error'] as String?;
        } on PlatformException {
          return 'SnapMark could not verify the Android attendance security checks. Please retry.';
        } on MissingPluginException {
          return 'SnapMark could not verify the Android attendance security checks. Please retry.';
        }
      }

      // Non-Android targets retain the Dart-side location gate.
      if (position.isMocked) {
        return 'A mock location was detected. Turn off mock-location apps before scanning the attendance QR.';
      }
      if (!position.accuracy.isFinite ||
          position.accuracy <= 0 ||
          position.accuracy > 100) {
        return 'GPS signal is still weak (±${position.accuracy.round()} m). Turn on Precise Location and retry outdoors or near a window.';
      }
      final fixAge = DateTime.now().difference(position.timestamp);
      if (fixAge > const Duration(seconds: 20) ||
          fixAge < const Duration(seconds: -5)) {
        return 'Location reading is stale. Refresh GPS and retry.';
      }

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        CampusConfig.latitude!,
        CampusConfig.longitude!,
      );
      if (distanceMeters + position.accuracy > CampusConfig.radiusMeters!) {
        if (distanceMeters - position.accuracy > CampusConfig.radiusMeters!) {
          return 'Phone location is about ${distanceMeters.round()} m from the campus center; the allowed radius is ${CampusConfig.radiusMeters!.round()} m.';
        }
        return 'Location is near the campus boundary (about ${distanceMeters.round()} m away, GPS accuracy ±${position.accuracy.round()} m). Move farther inside and retry.';
      }

      return null;
    } on TimeoutException {
      return 'Could not get your location in time. Check your GPS signal and try again.';
    } catch (_) {
      return 'Could not verify your location. Check Location is enabled and try again.';
    }
  }

  Future<void> openDeveloperOptionsSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _deviceIntegrityChannel.invokeMethod<void>(
      'openDeveloperOptionsSettings',
    );
  }
}
