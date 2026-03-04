import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/widgets/simple_card.dart';

/// Displays the results of a security scan.
class ScanScreen extends StatelessWidget {
  final ScanResult result;

  const ScanScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final scoreColor = result.securityScore >= 80
        ? AppColors.primary
        : result.securityScore >= 50
            ? AppColors.warning
            : AppColors.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            SimpleCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: result.securityScore / 100,
                          strokeWidth: 8,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(scoreColor),
                        ),
                        Text(
                          '${result.securityScore}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.totalAppsScanned} apps scanned',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${result.threatCount} threat${result.threatCount != 1 ? 's' : ''} found',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: result.threatCount > 0 ? AppColors.error : AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Threats list
            if (result.threats.isEmpty) ...[
              SimpleCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No threats detected',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your device looks safe.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text('Threats Found', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...result.threats.map((threat) => _threatTile(context, threat)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _threatTile(BuildContext context, Threat threat) {
    Color severityColor;
    String severityLabel;

    switch (threat.severity) {
      case ThreatSeverity.high:
        severityColor = AppColors.error;
        severityLabel = 'HIGH';
        break;
      case ThreatSeverity.medium:
        severityColor = AppColors.warning;
        severityLabel = 'MEDIUM';
        break;
      case ThreatSeverity.low:
        severityColor = AppColors.textSecondary;
        severityLabel = 'LOW';
        break;
    }

    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning, color: severityColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  threat.appName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  threat.reason,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              severityLabel,
              style: TextStyle(
                color: severityColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
