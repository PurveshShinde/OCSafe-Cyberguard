import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
import 'package:intl/intl.dart';

class SecurityStatusCard extends StatelessWidget {
  final int score;
  final bool isScanning;
  final DateTime? lastScanTime;
  final Widget? actionButton;
  final int scannedApps;
  final int totalApps;

  const SecurityStatusCard({
    super.key,
    required this.score,
    required this.isScanning,
    this.lastScanTime,
    this.actionButton,
    this.scannedApps = 0,
    this.totalApps = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Circular Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: isScanning ? (totalApps > 0 ? scannedApps / totalApps : null) : score / 100,
                  strokeWidth: 12,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isScanning ? '${( (totalApps > 0 ? scannedApps / totalApps : 0) * 100).toInt()}%' : '$score%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'SECURITY SCORE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Status Message
          Text(
            isScanning ? 'Scanning $scannedApps / $totalApps apps' : _getStatusMessage(score),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Last Scan Time
          Text(
            _formatLastScan(),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          
          if (isScanning) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: totalApps > 0 ? scannedApps / totalApps : null,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
          ],

          if (actionButton != null) ...[
            const SizedBox(height: 32),
            actionButton!,
          ],
        ],
      ),
    );
  }

  String _formatLastScan() {
    if (lastScanTime == null) return 'No scans performed yet';
    final format = DateFormat('MMM d, yyyy h:mm a');
    return 'Last scan: ${format.format(lastScanTime!)}';
  }

  String _getStatusMessage(int score) {
    if (score >= 90) return 'Your device is well protected';
    if (score >= 70) return 'Few optimizations needed';
    if (score >= 40) return 'System vulnerabilities detected';
    return 'Critical security risk found';
  }
}
