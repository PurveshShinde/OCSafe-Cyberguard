import 'package:permission_handler/permission_handler.dart';

/// Service for checking device permissions.
class PermissionService {
  /// List of permissions we monitor for security.
  static const List<Permission> monitoredPermissions = [
    Permission.camera,
    Permission.microphone,
    Permission.location,
    Permission.storage,
  ];

  /// Human-readable names for permissions.
  static final Map<Permission, String> permissionNames = {
    Permission.camera: 'Camera',
    Permission.microphone: 'Microphone',
    Permission.location: 'Location',
    Permission.storage: 'Storage',
  };

  /// Icons for each permission type.
  static final Map<Permission, int> permissionIcons = {
    Permission.camera: 0xe3af,       // Icons.camera_alt
    Permission.microphone: 0xe3af,   // Icons.mic
    Permission.location: 0xe55f,     // Icons.location_on
    Permission.storage: 0xe262,      // Icons.folder
  };

  /// Checks the status of all monitored permissions.
  /// Returns a map of permission to its current status.
  Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final statuses = <Permission, PermissionStatus>{};

    for (final permission in monitoredPermissions) {
      statuses[permission] = await permission.status;
    }

    return statuses;
  }

  /// Counts how many dangerous permissions are granted.
  int countGrantedDangerous(Map<Permission, PermissionStatus> statuses) {
    int count = 0;
    for (final entry in statuses.entries) {
      if (entry.value.isGranted) count++;
    }
    return count;
  }

  /// Opens the app settings page so user can manage permissions.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
