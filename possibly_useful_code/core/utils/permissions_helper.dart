import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_vizi_camera_app/core/di/service_locator.dart';
import 'package:flutter_vizi_camera_app/services/permission_service.dart';

class PermissionsHelper {
  static final PermissionService _permissionService =
      getIt<PermissionService>();

  /// Request all essential permissions for the camera app
  static Future<bool> requestEssentialPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ];

    final results = await permissions.request();

    // Check if all essential permissions are granted
    return results.values.every((status) => status == PermissionStatus.granted);
  }

  /// Request location permissions
  static Future<bool> requestLocationPermissions() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  /// Request sensor permissions (mainly for Android)
  static Future<bool> requestSensorPermissions() async {
    final status = await Permission.sensors.request();
    return status == PermissionStatus.granted;
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }

  /// Check if essential permissions are granted
  static Future<bool> hasEssentialPermissions() async {
    final camera = await Permission.camera.isGranted;
    final microphone = await Permission.microphone.isGranted;
    final storage = await Permission.storage.isGranted;

    return camera && microphone && storage;
  }

  /// Show permission rationale dialog
  static Future<bool> showPermissionRationale(
    BuildContext context, {
    required String title,
    required String message,
    required String permission,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await openAppSettings();
    }

    return result ?? false;
  }

  /// Handle permission denial with user-friendly messages
  static Future<void> handlePermissionDenied(
    BuildContext context,
    Permission permission,
  ) async {
    String title = '';
    String message = '';

    switch (permission) {
      case Permission.camera:
        title = 'Camera Access Required';
        message =
            'This app needs camera access to record videos. Please enable camera permission in Settings.';
        break;
      case Permission.microphone:
        title = 'Microphone Access Required';
        message =
            'This app needs microphone access to record audio. Please enable microphone permission in Settings.';
        break;
      case Permission.storage:
        title = 'Storage Access Required';
        message =
            'This app needs storage access to save your videos. Please enable storage permission in Settings.';
        break;
      case Permission.location:
        title = 'Location Access';
        message =
            'This app uses location to add metadata to your videos. You can enable this in Settings.';
        break;
      default:
        title = 'Permission Required';
        message = 'This app needs additional permissions to function properly.';
    }

    await showPermissionRationale(
      context,
      title: title,
      message: message,
      permission: permission.toString(),
    );
  }

  /// Request permissions with user-friendly flow
  static Future<bool> requestPermissionsWithFlow(
    BuildContext context, {
    bool includeLocation = false,
    bool includeSensors = false,
    bool includeNotifications = false,
  }) async {
    // Check if essential permissions are already granted
    if (await hasEssentialPermissions()) {
      return true;
    }

    // Show rationale before requesting permissions
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'ViziCam needs access to your camera, microphone, and storage to record and save videos. '
            'These permissions are essential for the app to function properly.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (shouldRequest != true) {
      return false;
    }

    // Request essential permissions
    final essentialGranted = await requestEssentialPermissions();

    if (!essentialGranted) {
      // Handle specific denied permissions
      if (!(await Permission.camera.isGranted)) {
        await handlePermissionDenied(context, Permission.camera);
      }
      if (!(await Permission.microphone.isGranted)) {
        await handlePermissionDenied(context, Permission.microphone);
      }
      if (!(await Permission.storage.isGranted)) {
        await handlePermissionDenied(context, Permission.storage);
      }
      return false;
    }

    // Request optional permissions
    if (includeLocation) {
      await requestLocationPermissions();
    }

    if (includeSensors) {
      await requestSensorPermissions();
    }

    if (includeNotifications) {
      await requestNotificationPermissions();
    }

    return true;
  }

  /// Get permission status summary
  static Future<Map<String, PermissionStatus>> getPermissionStatus() async {
    return {
      'camera': await Permission.camera.status,
      'microphone': await Permission.microphone.status,
      'storage': await Permission.storage.status,
      'location': await Permission.location.status,
      'sensors': await Permission.sensors.status,
      'notification': await Permission.notification.status,
    };
  }

  /// Check if app can request permission (not permanently denied)
  static Future<bool> canRequestPermission(Permission permission) async {
    final status = await permission.status;
    return status != PermissionStatus.permanentlyDenied;
  }
}
