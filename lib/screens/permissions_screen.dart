import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/services/permission_service.dart';
import 'package:ocsafe_cyberguard/widgets/simple_card.dart';

/// Displays and monitors device permissions.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh permissions when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityProvider>().refreshPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Permissions')),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          final statuses = provider.permissionStatuses;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Monitor which permissions are granted to apps on your device.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...PermissionService.monitoredPermissions.map((permission) {
                final status = statuses[permission];
                return _permissionTile(context, permission, status);
              }),
              const SizedBox(height: 24),
              _buildSummaryCard(context, statuses),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => provider.permissionService.openSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _permissionTile(BuildContext context, Permission permission, PermissionStatus? status) {
    final name = PermissionService.permissionNames[permission] ?? 'Unknown';
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
      statusColor = AppColors.warning;
    } else if (isPermanentlyDenied) {
      statusText = 'Denied';
      statusColor = AppColors.primary;
    } else if (isDenied) {
      statusText = 'Not Granted';
      statusColor = AppColors.primary;
    } else {
      statusText = 'Unknown';
      statusColor = AppColors.textSecondary;
    }

    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isGranted ? AppColors.warning : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isGranted ? AppColors.warning : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  isGranted ? 'This permission is currently granted' : 'Not granted — safe',
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

  Widget _buildSummaryCard(BuildContext context, Map<Permission, PermissionStatus> statuses) {
    final granted = statuses.values.where((s) => s.isGranted).length;
    final total = statuses.length;

    return SimpleCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            granted == 0 ? Icons.check_circle : Icons.info,
            color: granted == 0 ? AppColors.primary : AppColors.warning,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            '$granted of $total permissions granted',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            granted == 0
                ? 'Great! No sensitive permissions are granted.'
                : 'Review granted permissions for potential risks.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
