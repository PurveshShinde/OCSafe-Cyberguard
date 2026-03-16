import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/widgets/simple_card.dart';

/// User profile screen with device info and security score.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        final device = provider.deviceData;
        final score = provider.securityScore;
        final scoreColor = score >= 80
            ? AppColors.primary
            : score >= 50
                ? AppColors.warning
                : AppColors.error;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.person, size: 48, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Name field
              _buildInfoField(
                context,
                label: 'Name',
                value: FirebaseAuth.instance.currentUser?.displayName ?? provider.userName,
                onChanged: (v) {
                  FirebaseAuth.instance.currentUser?.updateDisplayName(v);
                  provider.updateUserName(v);
                },
              ),
              const SizedBox(height: 12),

              // Email field
              _buildInfoField(
                context,
                label: 'Email',
                value: FirebaseAuth.instance.currentUser?.email ?? provider.userEmail,
                onChanged: (v) {
                  // Email update requires re-authentication, so we just update the provider for now
                  provider.updateUserEmail(v);
                },
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: SimpleCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.smartphone, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            device != null ? device.deviceModel : 'Loading...',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SimpleCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.verified_user, color: scoreColor),
                          const SizedBox(height: 8),
                          Text(
                            'Score: $score%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: scoreColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Scan stats
              SimpleCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Statistics',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _statRow(context, 'Total Scans', '${provider.scanHistory.length}'),
                    const Divider(color: AppColors.divider, height: 20),
                    _statRow(context, 'Last Score',
                        provider.lastScanResult != null
                            ? '${provider.lastScanResult!.securityScore}%'
                            : 'N/A'),
                    const Divider(color: AppColors.divider, height: 20),
                    _statRow(context, 'Protection',
                        provider.realtimeProtection ? 'Active' : 'Disabled'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoField(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          style: Theme.of(context).textTheme.bodyLarge,
          onFieldSubmitted: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
