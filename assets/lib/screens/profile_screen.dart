import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        final device = provider.deviceData;
        
        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded, 
                      size: 60, 
                      color: AppColors.primary
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        provider.userName.isEmpty ? 'CyberGuard User' : provider.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        provider.userEmail.isEmpty ? 'user@ocsafe.com' : provider.userEmail,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Info Cards
                _infoCard(
                  icon: Icons.smartphone_rounded,
                  title: 'Device Information',
                  value: device?.deviceModel ?? 'Android Smartphone',
                ),
                const SizedBox(height: 16),
                _infoCard(
                  icon: Icons.shield_rounded,
                  title: 'Security Score',
                  value: '${provider.securityScore}% PROTECTED',
                  isAccent: true,
                ),
                const SizedBox(height: 16),
                _infoCard(
                  icon: Icons.analytics_rounded,
                  title: 'Scan Statistics',
                  value: '${provider.scanHistory.length} Total Scans Completed',
                ),
                
                const SizedBox(height: 48),
                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard({
    required IconData icon, 
    required String title, 
    required String value, 
    bool isAccent = false
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAccent ? AppColors.primary.withOpacity(0.05) : AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
