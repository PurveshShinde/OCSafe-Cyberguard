import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/scan_screen.dart';
import 'package:ocsafe_cyberguard/screens/reports_screen.dart';
import 'package:ocsafe_cyberguard/screens/sms_screen.dart';
import 'package:ocsafe_cyberguard/widgets/arc_gauge.dart';
import 'package:ocsafe_cyberguard/services/apk_scanner.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 32),
              _buildGaugeCard(context, provider),
              const SizedBox(height: 32),
              _buildSmsAlertsButton(context),
              const SizedBox(height: 40),
              _buildRecentScansSection(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGaugeCard(BuildContext context, SecurityProvider provider) {
    return Column(
      children: [
        provider.isScanning
          ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          : ArcGauge(score: provider.securityScore.toDouble()),
        const SizedBox(height: 12),
        const Text(
          'Security Check',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildRecentScansSection(BuildContext context, SecurityProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Scans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
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
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(
                     color: scan.threatCount == 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Text(
                     scan.threatCount == 0 ? 'Clean' : '${scan.threatCount} Threats',
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       color: scan.threatCount == 0 ? AppColors.success : AppColors.error,
                       fontSize: 12
                     ),
                   ),
                 )
               ],
             ),
           );
        }),
      ],
    );
  }

  Widget _buildSmsAlertsButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsScreen()));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6344FF), Color(0xFFFF2E93)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.message_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SMS Financial Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Scan local SMS for transactions', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              )
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
