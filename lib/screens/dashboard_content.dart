import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/scan_screen.dart';

import 'package:intl/intl.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Security Scan',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 32),
              _buildGaugeCard(context, provider),
              const SizedBox(height: 24),
              _buildLastScanOverview(context, provider),
              const SizedBox(height: 24),
              _buildRecentScansSection(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGaugeCard(BuildContext context, SecurityProvider provider) {
    final score = provider.securityScore;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!provider.isScanning) {
                      provider.runScan();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.face_retouching_natural_rounded, size: 48, color: AppColors.primary), // Represents the face scanning icon
                      const SizedBox(height: 12),
                      Text(
                        provider.isScanning ? 'Scanning...' : 'Tap to Scan',
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastScanOverview(BuildContext context, SecurityProvider provider) {
    final lastScan = provider.lastScanResult;
    String timeStr = 'Never';
    if (lastScan != null) {
      final diff = DateTime.now().difference(lastScan.scanDate);
      if (diff.inMinutes < 1) timeStr = 'Just now';
      else if (diff.inMinutes < 60) timeStr = '${diff.inMinutes} minute(s) ago';
      else if (diff.inHours < 24) timeStr = '${diff.inHours} hour(s) ago';
      else timeStr = DateFormat.yMMMd().format(lastScan.scanDate);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Last Scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(timeStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatMetric('${lastScan?.totalAppsScanned ?? 0}', 'Items Scanned'),
              _buildStatMetric('${lastScan?.threatCount ?? 0}', 'Threats Found'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                   (lastScan == null || lastScan.threatCount == 0) 
                     ? 'All clear! No threats detected' 
                     : '${lastScan.threatCount} threats require attention',
                   style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentScansSection(BuildContext context, SecurityProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Scans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (provider.scanHistory.isEmpty)
           const Text('No recent scans.', style: TextStyle(color: AppColors.textSecondary)),
        ...provider.scanHistory.take(3).map((scan) {
           return Container(
             margin: const EdgeInsets.only(bottom: 12),
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: AppColors.surface,
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))
               ],
             ),
             child: Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     color: scan.threatCount == 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                   ),
                   child: Icon(
                     scan.threatCount == 0 ? Icons.check_circle_rounded : Icons.warning_rounded,
                     color: scan.threatCount == 0 ? AppColors.success : AppColors.error,
                     size: 20
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('${scan.totalAppsScanned} items scanned', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                       const SizedBox(height: 4),
                       Text(
                         DateFormat('h:mm a').format(scan.scanDate), 
                         style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)
                       ),
                     ],
                   )
                 ),
                 Text(
                   scan.threatCount == 0 ? 'Clean' : '${scan.threatCount} Threats',
                   style: TextStyle(
                     fontWeight: FontWeight.bold,
                     color: scan.threatCount == 0 ? AppColors.success : AppColors.error,
                     fontSize: 13
                   ),
                 )
               ],
             ),
           );
        }),
      ],
    );
  }
}
