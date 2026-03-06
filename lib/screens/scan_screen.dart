import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/report_detail_screen.dart';

/// Displays the animated security scan and auto-transitions to report.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Scan')),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          if (!provider.isScanning && provider.lastScanResult != null) {
            // Once scan is done, we could automatically pop and push the report 
            // but for a better UX, we just show a "Scan Complete" and a button.
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 80),
                  const SizedBox(height: 24),
                  Text(
                    'Scan Complete!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${provider.lastScanResult!.threatCount} threats found',
                    style: TextStyle(
                      color: provider.lastScanResult!.threatCount > 0 ? AppColors.error : AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailScreen(result: provider.lastScanResult!),
                        ),
                      );
                    },
                    child: const Text('View Detailed Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }

          // Animated Scanning Stage
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scan mode indicator chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: provider.isFullScan
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: provider.isFullScan ? AppColors.primary : AppColors.warning,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        provider.isFullScan ? Icons.security : Icons.info_outline,
                        size: 16,
                        color: provider.isFullScan ? AppColors.primary : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.isFullScan
                            ? 'Full Scan Enabled'
                            : 'Limited Scan (Storage permission not granted)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: provider.isFullScan ? AppColors.primary : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(Icons.radar, size: 50, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  provider.scanStage.isNotEmpty ? provider.scanStage : 'Initializing scanner...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please do not close the app',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
