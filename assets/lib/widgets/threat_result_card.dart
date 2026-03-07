import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';

class ThreatResultCard extends StatelessWidget {
  final Threat threat;
  final VoidCallback? onDelete;
  final VoidCallback? onTrust;

  const ThreatResultCard({
    super.key,
    required this.threat,
    this.onDelete,
    this.onTrust,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor(threat.riskLevel);
    final isMalware = threat.riskLevel == 'MALWARE';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isMalware ? Icons.gpp_bad_rounded : Icons.gpp_maybe_rounded,
            color: color,
          ),
        ),
        title: Text(
          threat.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          threat.packageName,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            threat.riskLevel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Indicators:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...threat.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: color, weight: 12).setPadding(top: 6),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    threat.recommendedAction,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTrust,
                        icon: const Icon(Icons.verified_user_outlined, size: 18),
                        label: const Text('Trust App'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Uninstall'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toUpperCase()) {
      case 'MALWARE':
        return AppColors.error;
      case 'SUSPICIOUS':
        return AppColors.warning;
      case 'SAFE':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}

extension PaddingExtension on Widget {
  Widget setPadding({double top = 0, double bottom = 0, double left = 0, double right = 0}) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom, left: left, right: right),
      child: this,
    );
  }
}
