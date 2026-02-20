import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/components/glass_card.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';

class ThreatActivityList extends StatelessWidget {
  const ThreatActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const OcGlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ActivityItem(
                  icon: Icons.block,
                  label: 'Blocked malicious site',
                  timestamp: '10m ago',
                  color: AppColors.error,
                ),
                Divider(color: AppColors.glassBorder, height: 1),
                _ActivityItem(
                  icon: Icons.radar,
                  label: 'Scanned 142 apps',
                  timestamp: '2h ago',
                  color: AppColors.primary,
                ),
                Divider(color: AppColors.glassBorder, height: 1),
                _ActivityItem(
                  icon: Icons.check_circle_outline,
                  label: 'No threats found',
                  timestamp: 'Yesterday',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String timestamp;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.timestamp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Text(
        timestamp,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
