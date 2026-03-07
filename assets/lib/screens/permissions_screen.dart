import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';

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
    Permission.storage,
    Permission.contacts,
    Permission.sms,
  ];

  final Map<Permission, String> _permissionNames = {
    Permission.camera: 'Camera Access',
    Permission.microphone: 'Microphone Access',
    Permission.location: 'Location Services',
    Permission.storage: 'File Storage',
    Permission.contacts: 'Contacts List',
    Permission.sms: 'SMS Logs',
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Security Permissions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSummaryHeader(),
          const SizedBox(height: 48),
          Text(
            'CORE PERMISSIONS'.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ..._monitoredPermissions.map((permission) {
            return _permissionTile(_statuses[permission], permission);
          }),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_rounded, size: 20),
              label: const Text('Open System Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final granted = _statuses.values.where((s) => s.isGranted).length;
    final total = _monitoredPermissions.length;
    final allGranted = granted == total && total > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (allGranted ? AppColors.success : AppColors.primary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allGranted ? Icons.verified_rounded : Icons.security_rounded,
              color: allGranted ? AppColors.success : AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$granted of $total Active',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                Text(
                  allGranted ? 'Full protection enabled' : 'Partial restrictions active',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile(PermissionStatus? status, Permission permission) {
    final name = _permissionNames[permission] ?? 'Security Module';
    final isGranted = status?.isGranted ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.03)),
      ),
      child: ListTile(
        onTap: () async {
          await permission.request();
          _refreshPermissions();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isGranted ? AppColors.primary : AppColors.textSecondary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIcon(permission),
            color: isGranted ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5),
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          isGranted ? 'Access granted' : 'Restricted access',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7), fontWeight: FontWeight.w500),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isGranted,
            onChanged: (v) async {
              if (v) {
                await permission.request();
              } else {
                await openAppSettings();
              }
              _refreshPermissions();
            },
            activeColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(Permission p) {
    if (p == Permission.camera) return Icons.camera_alt_outlined;
    if (p == Permission.microphone) return Icons.mic_none_rounded;
    if (p == Permission.location) return Icons.location_on_outlined;
    if (p == Permission.storage) return Icons.folder_open_rounded;
    if (p == Permission.contacts) return Icons.contacts_outlined;
    if (p == Permission.sms) return Icons.sms_outlined;
    return Icons.security_rounded;
  }
}
