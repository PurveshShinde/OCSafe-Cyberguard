import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/widgets/security_status_card.dart';
import 'package:ocsafe_cyberguard/widgets/smart_scan_button.dart';
import 'package:ocsafe_cyberguard/screens/permissions_screen.dart';
import 'package:ocsafe_cyberguard/screens/optimization_screen.dart';
import 'package:ocsafe_cyberguard/screens/scan_screen.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:intl/intl.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        final bool hasRunScan = provider.lastScanResult != null;
        
        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SecurityStatusCard(
                  score: hasRunScan ? provider.securityScore : 100,
                  isScanning: provider.isScanning,
                  lastScanTime: provider.lastScanResult?.scanDate,
                  scannedApps: provider.scannedApps,
                  totalApps: provider.totalApps,
                  actionButton: SmartScanButton(
                    isScanning: false,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildSectionHeader(context, 'Quick Actions'),
                const SizedBox(height: 16),
                _buildQuickActions(context, provider),
                if (provider.activityLogs.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  _buildSectionHeader(context, 'Security Activity'),
                  const SizedBox(height: 16),
                  _buildActivitySection(context, provider),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, SecurityProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _actionCard(
          context,
          icon: Icons.shield_rounded,
          label: 'Real-Time\nProtection',
          trailing: Switch(
            value: provider.realtimeProtection,
            activeColor: AppColors.primary,
            onChanged: provider.toggleRealtimeProtection,
          ),
        ),
        _actionCard(
          context,
          icon: Icons.public_rounded,
          label: 'Safe\nBrowsing',
          trailing: Switch(
            value: provider.safeBrowsing,
            activeColor: AppColors.primary,
            onChanged: provider.toggleSafeBrowsing,
          ),
        ),
        _actionCard(
          context,
          icon: Icons.lock_rounded,
          label: 'App\nPermissions',
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PermissionsScreen())),
        ),
        _actionCard(
          context,
          icon: Icons.analytics_rounded,
          label: 'Device\nHealth',
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OptimizationScreen())),
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 24),
                    ),
                    if (trailing != null) 
                      SizedBox(height: 24, child: Transform.scale(scale: 0.8, child: trailing)),
                  ],
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context, SecurityProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.activityLogs.take(5).length,
        separatorBuilder: (_, __) => Divider(
          height: 1, 
          color: AppColors.textPrimary.withOpacity(0.05),
          indent: 64,
        ),
        itemBuilder: (context, index) => _activityTile(context, provider.activityLogs[index]),
      ),
    );
  }

  Widget _activityTile(BuildContext context, ActivityLog log) {
    IconData icon;
    Color color;

    switch (log.type) {
      case ActivityType.threat:
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      case ActivityType.protection:
        icon = Icons.verified_user_outlined;
        color = AppColors.success;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = AppColors.primary;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        log.message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _formatTime(log.timestamp),
        style: TextStyle(
          color: AppColors.textPrimary.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.yMMMd().format(time);
  }
}
