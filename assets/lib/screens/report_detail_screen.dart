import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/app_scan_result.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:provider/provider.dart';

class ReportDetailScreen extends StatelessWidget {
  final ScanResult result;

  const ReportDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detailed Report',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: result.securityScore / 100,
                          strokeWidth: 8,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${result.securityScore}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(result.scanDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${result.totalAppsScanned} Apps Scanned',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Security Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // App Results List
            if (result.appResults.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No detailed app data available'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.appResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildAppResultCard(result.appResults[index]),
              ),
            
            const SizedBox(height: 40),
            _buildExplanationSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppResultCard(AppScanResult app) {
    Color statusColor;
    String statusLabel;
    
    if (app.score >= 60) {
      statusColor = AppColors.error;
      statusLabel = 'MALWARE';
    } else if (app.score >= 30) {
      statusColor = AppColors.warning;
      statusLabel = 'SUSPICIOUS';
    } else {
      statusColor = AppColors.success;
      statusLabel = 'SAFE';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  app.reason ?? 'No threats found',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
              Text(
                'Score: ${app.score}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Understanding Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Scores are calculated based on accessibility services, system overlays, unknown install sources, and auto-start permissions. Low scores (Green) indicate safe applications, while high scores (Red) represent potential security risks.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
