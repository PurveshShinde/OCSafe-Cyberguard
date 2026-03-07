import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/report_detail_screen.dart';

/// Dedicated scan page — starts the scan on mount and auto-navigates to the
/// detailed report when complete.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Kick off the scan after the first frame so the provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SecurityProvider>();
      if (!provider.isScanning) {
        provider.runScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Smart Scan',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          // Auto-navigate to report once scan is done.
          if (!provider.isScanning &&
              provider.lastScanResult != null &&
              !_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReportDetailScreen(result: provider.lastScanResult!),
                  ),
                );
              }
            });
          }

          if (!provider.isScanning && provider.lastScanResult != null) {
            // Transitioning — show brief complete state before navigation fires.
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Scan Complete!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.lastScanResult!.threatCount} threat(s) found',
                    style: TextStyle(
                      fontSize: 16,
                      color: provider.lastScanResult!.threatCount > 0
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opening report…',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Scanning in progress UI ──
          final double progress = provider.totalApps > 0
              ? provider.scannedApps / provider.totalApps
              : 0.0;
          final int progressPct = (progress * 100).toInt();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scan mode badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: provider.isFullScan
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: provider.isFullScan
                          ? AppColors.primary
                          : AppColors.warning,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        provider.isFullScan
                            ? Icons.security_rounded
                            : Icons.info_outline_rounded,
                        size: 14,
                        color: provider.isFullScan
                            ? AppColors.primary
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.isFullScan
                            ? 'Full Scan Mode'
                            : 'Limited Scan (User Apps)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: provider.isFullScan
                              ? AppColors.primary
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Animated radar ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: provider.totalApps > 0 ? progress : null,
                        strokeWidth: 4,
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withOpacity(0.3)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: provider.totalApps > 0 ? progress : null,
                        strokeWidth: 8,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$progressPct%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Stage text
                Text(
                  provider.scanStage.isNotEmpty
                      ? provider.scanStage
                      : 'Initializing scanner…',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (provider.totalApps > 0) ...[
                  Text(
                    '${provider.scannedApps} / ${provider.totalApps} apps',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Please keep the app open',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
