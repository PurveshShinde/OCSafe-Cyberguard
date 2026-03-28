import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/widgets/glass_container.dart';

/// Settings screen with functional toggles that persist.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader(context, 'Security'),
              GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Real-Time Protection'),
                      subtitle: const Text('Monitor apps for suspicious behavior'),
                      value: provider.realtimeProtection,
                      onChanged: provider.toggleRealtimeProtection,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Safe Browsing'),
                      subtitle: const Text('Check URLs against phishing blacklist'),
                      value: provider.safeBrowsing,
                      onChanged: provider.toggleSafeBrowsing,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Auto Scan'),
                      subtitle: const Text('Automatically scan on app launch'),
                      value: provider.autoScan,
                      onChanged: provider.toggleAutoScan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionHeader(context, 'App'),
              GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language, color: AppColors.textSecondary),
                      title: const Text('Language'),
                      trailing: const Text('English',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
                      title: const Text('Notifications'),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppColors.textSecondary),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionHeader(context, 'About'),
              GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                      title: const Text('Version'),
                      trailing: const Text('1.0.0',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppColors.textSecondary),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
          ),
          const Divider(color: AppColors.divider),
        ],
      ),
    );
  }
}
