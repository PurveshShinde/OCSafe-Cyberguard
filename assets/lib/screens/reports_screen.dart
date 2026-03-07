import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        final history = provider.scanHistory.reversed.toList();
        
        return Container(
          color: AppColors.background,
          child: history.isEmpty 
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) => _buildHistoryCard(context, history[index]),
              ),
        );
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, ScanResult result) {
    final dateStr = DateFormat('MMM d, yyyy h:mm a').format(result.scanDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Score Circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Text(
                '${result.securityScore}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.totalAppsScanned} apps • ${result.threatCount} threats',
                  style: TextStyle(
                    color: AppColors.textPrimary.withAlpha(153),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Checkmark
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No Scan History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Perform your first smart scan to\nsee security reports here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary.withAlpha(153),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
