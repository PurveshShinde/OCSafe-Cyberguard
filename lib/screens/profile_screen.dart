import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/widgets/glass_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGlow,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  child: const Icon(Icons.person, size: 48, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),

              // Name & Email Stream Builder
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots()
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  String displayName = provider.userName;
                  String displayEmail = provider.userEmail;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    displayName = data['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User';
                    displayEmail = data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
                  }

                  return Column(
                    children: [
                      // Name field
                      _buildInfoField(
                        context,
                        label: 'Name',
                        value: displayName,
                        onChanged: (v) {
                          provider.updateUserName(v);
                          if (FirebaseAuth.instance.currentUser != null) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .set({'name': v}, SetOptions(merge: true));
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email field
                      _buildInfoField(
                        context,
                        label: 'Email',
                        value: displayEmail,
                        onChanged: (v) {
                          provider.updateUserEmail(v);
                          // Option to update email in Firestore and maybe Auth
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
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
                    child: GlassContainer(
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
              GlassContainer(
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
          key: ValueKey(value),
          initialValue: value,
          style: Theme.of(context).textTheme.bodyLarge,
          onFieldSubmitted: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.6),
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
