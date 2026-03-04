import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/widgets/simple_card.dart';

/// Displays and monitors device permissions natively.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<Permission, PermissionStatus> _statuses = {};

  final List<Permission> _monitoredPermissions = [
    Permission.camera,
    Permission.microphone,
    Permission.location,
    Permission.storage,  // Often used dynamically on Android
    Permission.contacts,
    Permission.sms,
  ];

  final Map<Permission, String> _permissionNames = {
    Permission.camera: 'Camera',
    Permission.microphone: 'Microphone',
    Permission.location: 'Location',
    Permission.storage: 'Storage',
    Permission.contacts: 'Contacts',
    Permission.sms: 'SMS',
  };

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    for (var perm in _monitoredPermissions) {
      _statuses[perm] = await perm.status;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Permissions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Monitor core permissions required by the scanner and overall device health.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ..._monitoredPermissions.map((permission) {
            final status = _statuses[permission];
            return _permissionTile(context, permission, status);
          }),
          const SizedBox(height: 24),
          _buildSummaryCard(context),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => openAppSettings(),
            icon: const Icon(Icons.settings),
            label: const Text('Open App Settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile(BuildContext context, Permission permission, PermissionStatus? status) {
    final name = _permissionNames[permission] ?? 'Unknown';
    final isGranted = status?.isGranted ?? false;
    final isDenied = status?.isDenied ?? true;
    final isPermanentlyDenied = status?.isPermanentlyDenied ?? false;

    IconData icon;
    switch (name) {
      case 'Camera':
        icon = Icons.camera_alt;
        break;
      case 'Microphone':
        icon = Icons.mic;
        break;
      case 'Location':
        icon = Icons.location_on;
        break;
      case 'Storage':
        icon = Icons.folder;
        break;
      default:
        icon = Icons.security;
    }

    String statusText;
    Color statusColor;
    if (isGranted) {
      statusText = 'Granted';
      statusColor = AppColors.primary;
    } else if (isPermanentlyDenied) {
      statusText = 'Denied';
      statusColor = AppColors.warning;
    } else if (isDenied) {
      statusText = 'Not Granted';
      statusColor = AppColors.textSecondary;
    } else {
      statusText = 'Unknown';
      statusColor = AppColors.textSecondary;
    }

    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () async {
        await permission.request();
        await _refreshPermissions();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  isGranted ? 'This permission is currently granted to OcSafe' : 'Tap to request authorization',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final granted = _statuses.values.where((s) => s.isGranted).length;
    final total = _statuses.length;
    final allGranted = granted == total && total > 0;

    return SimpleCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            allGranted ? Icons.check_circle : Icons.info,
            color: allGranted ? AppColors.primary : AppColors.warning,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            '$granted of $total permissions granted',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            allGranted
                ? 'Great! The app has full capabilities to scan.'
                : 'Consider granting permissions for better scanning.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
