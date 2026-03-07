import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/report_detail_screen.dart';

/// Dedicated scan page — starts the scan on mount and auto-transitions to the
/// detailed report when scanning completes.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  // Guard so we navigate exactly once.
  bool _navigated = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    // Kick off the scan *after* the first frame so Provider is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SecurityProvider>();
      if (!provider.isScanning) {
        provider.runScan();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Smart Scan'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          // ── Auto-navigate to report once scan finishes ──
          if (!provider.isScanning && provider.lastScanResult != null && !_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(result: provider.lastScanResult!),
                  ),
                );
              }
            });
          }

          // Brief "complete" state shown while navigation callback fires.
          if (!provider.isScanning && provider.lastScanResult != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 64),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Scan Complete!',
                    style: TextStyle(
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
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // ── Scanning in-progress UI ──
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scan mode badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: provider.isFullScan
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
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
                        provider.isFullScan ? Icons.security_rounded : Icons.info_outline_rounded,
                        size: 14,
                        color: provider.isFullScan ? AppColors.primary : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.isFullScan ? 'Full Scan Mode' : 'Limited Scan (User Apps)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: provider.isFullScan ? AppColors.primary : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),

                // Dual-ring radar animation with pulsing center icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withValues(alpha: 0.2)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeInOut,
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.radar_rounded, size: 56, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // Current stage label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        provider.scanStage.isNotEmpty
                            ? provider.scanStage
                            : 'Initializing scanner…',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please keep the app open',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
