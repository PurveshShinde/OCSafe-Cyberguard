import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/services/apk_scanner.dart';
import 'package:ocsafe_cyberguard/widgets/simple_card.dart';
import 'package:ocsafe_cyberguard/widgets/primary_button.dart';
import 'package:ocsafe_cyberguard/screens/scan_screen.dart';
import 'package:ocsafe_cyberguard/screens/permissions_screen.dart';
import 'package:ocsafe_cyberguard/screens/optimization_screen.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';


/// Main dashboard content shown on the Home tab.
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _buildSummaryCard(context, provider),
    const SizedBox(height: 24),
    _buildQuickActions(context, provider),
    const SizedBox(height: 24),
    _buildActivitySection(context, provider),

    const SizedBox(height: 24),

    const Text(
      "AI Security Assistant",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),

    const SizedBox(height: 12),

    SimpleCard(
      padding: const EdgeInsets.all(24),
      child: Container(
        height: 400,
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              "AI Assistant coming soon 🚀",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
      ),
    ),
  ],
),
        );
      },
    );
  }

  /// Security summary card containing the score and scan button.
  Widget _buildSummaryCard(BuildContext context, SecurityProvider provider) {
    final score = provider.securityScore;
    final color = AppColors.primary; // Screenshot shows strict purple

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 16,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score%',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SECURITY SCORE',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            score >= 80
                ? 'Your device is well protected'
                : score >= 50
                    ? 'Some security issues found'
                    : 'Security attention needed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            provider.lastScanResult != null
              ? 'Last scan: ${DateFormat.yMMMd().add_jm().format(provider.lastScanResult!.scanDate)}'
              : 'Never scanned',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.security, size: 20, color: Colors.white),
              label: Text(
                provider.isScanning ? 'Scanning...' : 'Run Smart Scan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                if (provider.isScanning) return;
                await _startScanWithPermission(context, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Handles storage permission check before launching the scan.
  /// All permission logic lives here — scanForSuspiciousFiles() only checks, never requests.
  Future<void> _startScanWithPermission(
    BuildContext context,
    SecurityProvider provider,
  ) async {
    final scanner = ApkScanner();
    bool granted = false;

    if (Platform.isAndroid) {
      granted = await scanner.hasStoragePermission();

      if (!granted) {
        if (!context.mounted) return;
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final int sdk = androidInfo.version.sdkInt;

        if (!context.mounted) return;

        // Show explanation dialog with user-specified wording
        final bool? userChoice = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.folder_open, color: AppColors.primary, size: 40),
                title: const Text(
                  'Storage Permission Required',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'CyberGuard needs access to device storage to scan APK files, '
                  'archives, and suspicious files across your device.\n\n'
                  'Without this permission, the scan will only check installed applications.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Continue with Limited Scan',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Allow Full Scan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );

        if (!context.mounted) return;

        if (userChoice == true) {
          // Fire the permission intent / dialog
          await scanner.requestStoragePermission();

          // Poll for up to 30 seconds for the user to toggle & return
          if (sdk >= 30) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Grant "All Files Access" in Settings, then return to the app...'),
                  duration: Duration(seconds: 30),
                  backgroundColor: AppColors.warning,
                ),
              );
            }
            for (int i = 0; i < 60; i++) {
              await Future.delayed(const Duration(milliseconds: 500));
              granted = await scanner.hasStoragePermission();
              if (granted) break;
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
            }
          } else {
            granted = await scanner.hasStoragePermission();
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(granted
                    ? '✅ Storage access granted — starting full scan.'
                    : '⚠️ Storage permission not granted. Running limited scan.'),
                duration: const Duration(seconds: 3),
                backgroundColor: granted ? AppColors.primary : AppColors.warning,
              ),
            );
          }
        }
        // If user chose "Continue with Limited Scan" or dismissed, granted stays false
      }
    }

    if (!context.mounted) return;

    // Set scan mode based on permission status
    provider.setFullScan(granted);
    provider.runScan();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }


  /// Quick action cards grid.
  Widget _buildQuickActions(BuildContext context, SecurityProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _actionCard(
              context,
              icon: Icons.shield,
              label: 'Real-Time\nProtection',
              isActive: provider.realtimeProtection,
              trailing: Switch(
                value: provider.realtimeProtection,
                onChanged: provider.toggleRealtimeProtection,
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            _actionCard(
              context,
              icon: Icons.public,
              label: 'Safe\nBrowsing',
              isActive: provider.safeBrowsing,
              onTap: () => provider.toggleSafeBrowsing(!provider.safeBrowsing),
              trailing: Switch(
                value: provider.safeBrowsing,
                onChanged: (val) => provider.toggleSafeBrowsing(val),
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            _actionCard(
              context,
              icon: Icons.lock,
              label: 'App\nPermissions',
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PermissionsScreen())),
              trailing: Switch(
                value: false,
                onChanged: null, // Visually disabled off switch
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            _actionCard(
              context,
              icon: Icons.monitor_heart,
              label: 'Device\nHealth',
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OptimizationScreen())),
              trailing: Switch(
                value: false,
                onChanged: null, // Visually disabled off switch
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isActive = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return SimpleCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 28,
              ),
              if (trailing != null)
                SizedBox(
                  height: 30,
                  child: Transform.scale(scale: 0.8, child: trailing),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.2,
                  color: AppColors.textPrimary, // Always dark like screenshot
                ),
          ),
        ],
      ),
    );
  }

  /// Recent activity feed.
  Widget _buildActivitySection(BuildContext context, SecurityProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (provider.activityLogs.isEmpty)
          SimpleCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No activity yet. Run a scan to get started.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SimpleCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: provider.activityLogs.take(5).map((log) {
                return _activityTile(context, log);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _activityTile(BuildContext context, ActivityLog log) {
    IconData icon = Icons.check_circle;
    Color color = AppColors.primary;

    if (log.type.name == 'threat') {
      icon = Icons.warning;
      color = AppColors.error;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        log.message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatTime(log.timestamp),
        style: Theme.of(context).textTheme.bodySmall,
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
