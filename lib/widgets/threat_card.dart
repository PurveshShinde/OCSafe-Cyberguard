import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';

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
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_amber_rounded, color: severityColor, size: 24),
          ),
          title: Text(
            threat.appName,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            'Risk Level: ${threat.riskLevel}',
            style: TextStyle(color: severityColor, fontWeight: FontWeight.w600, fontSize: 12),
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
          ],
        ),
      ),
    );
  }
}
