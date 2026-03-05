import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/services/uninstall_service.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';

class ThreatCard extends StatelessWidget {
  final Threat threat;

  const ThreatCard({super.key, required this.threat});

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    switch (threat.riskLevel) {
      case 'HIGH':
        severityColor = AppColors.error;
        break;
      case 'MEDIUM':
        severityColor = AppColors.warning;
        break;
      default:
        severityColor = AppColors.primary;
    }

    return Card(
      color: severityColor.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: severityColor.withValues(alpha: 0.3), width: 1),
      ),
      elevation: 0,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              threat.riskLevel == 'HIGH' ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded,
              color: severityColor,
              size: 28,
            ),
          ),
          title: Text(
            threat.appName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${threat.riskLevel} RISK',
                    style: TextStyle(color: severityColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            const Text('Reasons for detection:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            ...threat.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.textSecondary)),
                      Expanded(child: Text(r, style: const TextStyle(color: AppColors.textSecondary))),
                    ],
                  ),
                )),
            if (threat.permissionsRequested.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Dangerous Permissions:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                threat.permissionsRequested.map((p) => p.split('.').last).join(', '),
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      threat.recommendedAction,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _handleUninstall(context),
                icon: const Icon(Icons.delete_forever, color: Colors.white, size: 22),
                label: const Text('UNINSTALL THREAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: severityColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _handleUninstall(BuildContext context) async {
      try {
        if (threat.packageName.startsWith('/storage/') || threat.packageName.toLowerCase().endsWith('.apk')) {
          final file = File(threat.packageName);
          if (await file.exists()) {
             await file.delete();
             if (!context.mounted) return;
             Provider.of<SecurityProvider>(context, listen: false).removeApkThreat(threat);
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('APK file deleted successfully.'), backgroundColor: Colors.green),
             );
          } else {
             if (!context.mounted) return;
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Failed to delete: File not found.'), backgroundColor: AppColors.error),
             );
          }
        } else {
          await UninstallService.uninstallApp(threat.packageName);
          // Optimistically remove from UI for a snappier experience while Android processes the uninstall.
          if (!context.mounted) return;
          Provider.of<SecurityProvider>(context, listen: false).removeAppThreat(threat.packageName);
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Could not initiate uninstall: $e'), backgroundColor: AppColors.error),
        );
      }
  }
}
