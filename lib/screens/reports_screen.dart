import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/screens/report_detail_screen.dart';

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
                  const Text(
                    'No scan reports yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Run a smart scan from the Home tab to generate your first report.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Scan Reports', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                   TextButton.icon(
                     onPressed: () {
                       context.read<SecurityProvider>().clearHistory();
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All scan reports cleared')));
                     },
                     icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: AppColors.error),
                     label: const Text('Clear All', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                     style: TextButton.styleFrom(padding: EdgeInsets.zero),
                   ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8).copyWith(bottom: 120),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final result = history[index];
                  return Dismissible(
                    key: ValueKey(result.scanDate.toIso8601String()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_rounded, color: AppColors.error),
                    ),
                    onDismissed: (_) {
                      context.read<SecurityProvider>().deleteHistoryItem(result);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted')));
                    },
                    child: _reportTile(context, result),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _reportTile(BuildContext context, ScanResult result) {
    final scoreColor = result.securityScore >= 80
        ? AppColors.success
        : result.securityScore >= 50
            ? AppColors.warning
            : AppColors.error;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(result: result),
          ),
        );
      },
      child: Container(
         margin: const EdgeInsets.only(bottom: 16),
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(20),
           boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 5))
           ],
         ),
         child: Row(
           children: [
             Container(
               width: 56,
               height: 56,
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(
                 color: scoreColor.withValues(alpha: 0.1),
                 shape: BoxShape.circle,
               ),
               child: Stack(
                 alignment: Alignment.center,
                 children: [
                   CircularProgressIndicator(
                     value: result.securityScore / 100,
                     strokeWidth: 4,
                     backgroundColor: Colors.transparent,
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
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                   ),
                   const SizedBox(height: 4),
                   Text(
                     '${result.totalAppsScanned} apps · ${result.threatCount} threat${result.threatCount != 1 ? 's' : ''}',
                     style: const TextStyle(color: Colors.grey, fontSize: 13)
                   ),
                 ],
               )
             ),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
               decoration: BoxDecoration(
                 color: result.threatCount == 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(
                 result.threatCount == 0 ? 'Clean' : 'Found',
                 style: TextStyle(
                   fontWeight: FontWeight.bold,
                   color: result.threatCount == 0 ? AppColors.success : AppColors.error,
                   fontSize: 12
                 ),
               ),
             )
           ],
         ),
      ),
    );
  }
}
