import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/components/glass_card.dart';
import 'package:ocsafe_cyberguard/core/components/neon_glow.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(20),
      children: const [
        _ActionCard(
          icon: Icons.shield,
          label: 'Real-Time\nProtection',
          isActive: true,
          showSwitch: true,
        ),
        _ActionCard(
          icon: Icons.public,
          label: 'Secure\nBrowsing',
          isActive: true,
        ),
        _ActionCard(
          icon: Icons.lock_person,
          label: 'App\nPermissions',
        ),
        _ActionCard(
          icon: Icons.bolt,
          label: 'Device\nOptimization',
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool showSwitch;

  const _ActionCard({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.showSwitch = false,
  });

  @override
  Widget build(BuildContext context) {
    return OcGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NeonGlow(
                glowColor: isActive ? AppColors.accent : Colors.transparent,
                child: Icon(
                  icon,
                  color: isActive ? AppColors.accent : AppColors.textSecondary,
                  size: 28,
                ),
              ),
              if (showSwitch)
                SizedBox(
                  height: 24,
                  width: 40,
                  child: Switch(
                    value: isActive,
                    onChanged: (v) {},
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.accent;
                      }
                      return null;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.accent.withValues(alpha: 0.3);
                      }
                      return null;
                    }),
                  ),
                ),
            ],
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
