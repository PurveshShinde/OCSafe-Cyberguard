import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/widgets/simple_card.dart';
import 'package:ocsafe_cyberguard/widgets/threat_card.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';

class ReportDetailScreen extends StatelessWidget {
  final ScanResult result;

  const ReportDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final scoreColor = result.securityScore >= 80
        ? AppColors.primary
        : result.securityScore >= 50
            ? AppColors.warning
            : AppColors.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Detailed Scan Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header
            SimpleCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: result.securityScore / 100,
                          strokeWidth: 6,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(scoreColor),
                        ),
                        Text(
                          '${result.securityScore}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Score',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMMMd().add_jm().format(result.scanDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.grid_view, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('${result.totalAppsScanned} apps scanned', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.warning, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('${result.threatCount} threats found', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Threat Summary Section
            Text('Threat Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (result.threats.isEmpty)
              SimpleCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: AppColors.primary, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Excellent! Your device is secure. No suspicious apps or risky permissions were detected.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...result.threats.map((t) => ThreatCard(threat: t)),

            const SizedBox(height: 24),

            // Help section
            const Text('What does this mean?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'OcSafe CyberGuard analyzes your installed apps and their permissions. '
              'Apps that request dangerous combinations of permissions or have suspicious names are flagged for your review. '
              'This is a local heuristics scan; if an app is flagged, consider whether you trust its source before uninstalling.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Device Health Section
            const Text('Device Security Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Consumer<SecurityProvider>(
              builder: (context, provider, _) {
                final health = provider.deviceData;
                if (health == null) return const SizedBox.shrink();

                return SimpleCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_android, color: AppColors.textSecondary),
                        title: const Text('Device Model', style: TextStyle(fontSize: 14)),
                        trailing: Text(health.deviceModel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.system_update, color: AppColors.textSecondary),
                        title: const Text('Android Version', style: TextStyle(fontSize: 14)),
                        trailing: Text(health.androidVersion, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.battery_std, color: AppColors.textSecondary),
                        title: const Text('Battery Level', style: TextStyle(fontSize: 14)),
                        trailing: Text('${health.batteryLevel}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.storage, color: AppColors.textSecondary),
                        title: const Text('Storage Used', style: TextStyle(fontSize: 14)),
                        trailing: Text('${health.storageUsedPercentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
