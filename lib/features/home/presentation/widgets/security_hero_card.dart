import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ocsafe_cyberguard/core/components/glass_card.dart';
import 'package:ocsafe_cyberguard/core/components/gradient_button.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/features/home/presentation/widgets/security_ring.dart';

class SecurityHeroCard extends StatelessWidget {
  const SecurityHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return OcGlassCard(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 48,
            color: AppColors.accent,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .custom(
                duration: 2.seconds,
                builder: (context, value, child) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.5 * value),
                          blurRadius: 20 * value,
                          spreadRadius: 5 * value,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
              ),
          const SizedBox(height: 16),
          Text(
            'Your Device is Protected',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Last Scan: 2h ago',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const SecurityRing(score: 92),
          const SizedBox(height: 32),
          OcGradientButton(
            text: 'Run Smart Scan',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
