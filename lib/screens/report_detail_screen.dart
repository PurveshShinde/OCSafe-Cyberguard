import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/widgets/threat_card.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/optimization_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final ScanResult result;

  const ReportDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Determine status
    final isSecure = result.threatCount == 0;
    final statusColor = isSecure ? AppColors.success : AppColors.error;
    final statusText = isSecure ? 'Secure' : 'Risks Found';
    final statusSubText = isSecure ? 'Monitoring suspicious activity.' : '${result.threatCount} threats require your attention.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Viruses & risks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusSubText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withValues(alpha: 0.15),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        isSecure ? Icons.bolt_rounded : Icons.warning_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recommended optimizations
              const Text(
                'Recommended optimizations',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    _buildOptimizationTile(
                      context: context,
                      icon: Icons.rocket_launch_rounded,
                      iconColor: AppColors.primary,
                      title: 'System boost',
                      subtitle: 'Close background apps to make your device run faster.',
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const OptimizationScreen()));
                      }
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Threat summary (Replace "Block suspicious app activities" when risks exist)
              if (!isSecure) ...[
                const Text(
                  'Threats detected',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ...result.threats.map((t) => ThreatCard(threat: t)),
                const SizedBox(height: 24),
              ] else ...[
                 // Block suspicious app activities (Safe state box mimicking screenshot)
                 Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Block suspicious app activities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          SizedBox(height: 4),
                          Text('No blocking history', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Scan records
              const Text(
                'Scan records',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Consumer<SecurityProvider>(
                builder: (context, provider, _) {
                  final history = provider.scanHistory.take(5).toList();
                  if (history.isEmpty) {
                    history.add(result); // Fallback to current result if history is empty
                  }
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: history.asMap().entries.map((entry) {
                         final index = entry.key;
                         final scan = entry.value;
                         final isLast = index == history.length - 1;
                         return Column(
                           children: [
                             _buildScanRecordTile(scan),
                             if (!isLast)
                               const Divider(height: 1, indent: 16, endIndent: 16),
                           ],
                         );
                      }).toList(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Go', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanRecordTile(ScanResult scan) {
    String scanTitle = scan.isFullScan ? 'Manual scan' : 'Installation scan';
    String description = scan.threatCount == 0
       ? 'Scanned ${scan.totalAppsScanned} items. No risky apps found.'
       : 'Scanned ${scan.totalAppsScanned} items. ${scan.threatCount} risks found.';
       
    // Check if scan is very recent
    final diff = DateTime.now().difference(scan.scanDate);
    String timeStr = 'Just now';
    if (diff.inMinutes > 2) {
      timeStr = DateFormat('h:mm:ss a').format(scan.scanDate);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scanTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Text(timeStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
