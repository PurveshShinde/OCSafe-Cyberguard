import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/widgets/simple_card.dart';

import 'package:ocsafe_cyberguard/screens/report_detail_screen.dart';

/// Displays scan history from the database.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        final history = provider.scanHistory;

        if (history.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No scan reports yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Run a smart scan from the Home tab to generate your first report.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) => _reportTile(context, history[index]),
        );
      },
    );
  }

  Widget _reportTile(BuildContext context, ScanResult result) {
    final scoreColor = result.securityScore >= 80
        ? AppColors.primary
        : result.securityScore >= 50
            ? AppColors.warning
            : AppColors.error;

    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(result: result),
          ),
        );
      },
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: result.securityScore / 100,
                  strokeWidth: 5,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
                Text(
                  '${result.securityScore}',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMd().add_jm().format(result.scanDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${result.totalAppsScanned} apps · ${result.threatCount} threat${result.threatCount != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  result.isFullScan ? 'Full Scan' : 'Limited Scan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: result.isFullScan ? AppColors.primary : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            result.threatCount == 0 ? Icons.check_circle : Icons.warning,
            color: result.threatCount == 0 ? AppColors.primary : AppColors.warning,
          ),
        ],
      ),
    );
  }
}
