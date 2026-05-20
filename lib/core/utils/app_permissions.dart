import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  AppPermissions._();

  static Future<bool> requestAll() async {
    // 1. Check Location Service Status
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location service is off, prompt user to enable it
      await Geolocator.openLocationSettings();
      // Wait a bit and check again, or just return false and let user try again
      return false;
    }

    if (!await _requestPermission(Permission.locationWhenInUse)) {
      return false;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (!await _requestPermission(Permission.locationAlways)) {
        return false;
      }
    }

    if (!await _requestPermission(Permission.camera)) {
      return false;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (!await _requestPermission(Permission.phone)) {
        return false;
      }
    }

    if (!await _requestPermission(Permission.microphone)) {
      return false;
    }

    if (!await _requestPermission(Permission.photos)) {
      return false;
    }

    return true;
  }

  static Future<bool> _requestPermission(Permission permission) async {
    var status = await permission.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    status = await permission.request();
    return status.isGranted ||
        (permission == Permission.photos && status.isLimited);
  }

  static Future<bool> areCriticalPermissionsGranted() async {
    final location = await Permission.locationWhenInUse.isGranted;
    final camera = await Permission.camera.isGranted;
    final phone = await Permission.phone.isGranted;
    final microphone = await Permission.microphone.isGranted;
    final photos = await Permission.photos.isGranted;
    return location && camera && phone && microphone && photos;
  }
}
