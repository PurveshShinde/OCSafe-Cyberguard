import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSectionHeader('Security & Protection'),
              _settingsCard([
                _switchTile(
                  'Real-Time Protection',
                  'Monitor apps for suspicious behavior',
                  provider.realtimeProtection,
                  provider.toggleRealtimeProtection,
                ),
                _switchTile(
                  'Safe Browsing',
                  'Check URLs against phishing databases',
                  provider.safeBrowsing,
                  provider.toggleSafeBrowsing,
                ),
                _switchTile(
                  'Auto Scan',
                  'Automatically scan during device idle',
                  provider.autoScan,
                  provider.toggleAutoScan,
                ),
              ]),
              const SizedBox(height: 32),

              _buildSectionHeader('General Settings'),
              _settingsCard([
                _actionTile(Icons.language_rounded, 'App Language', 'English'),
                _divider(),
                _actionTile(Icons.notifications_none_rounded, 'System Notifications', 'Enabled'),
                _divider(),
                _actionTile(Icons.dark_mode_outlined, 'Appearance', 'Light Mode'),
              ]),
              const SizedBox(height: 32),

              _buildSectionHeader('About'),
              _settingsCard([
                _actionTile(Icons.info_outline_rounded, 'CyberGuard Version', '2.0.0-Octane'),
                _divider(),
                _actionTile(Icons.description_outlined, 'Privacy Policy', ''),
                _divider(),
                _actionTile(Icons.support_agent_rounded, 'Technical Support', ''),
              ]),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary.withOpacity(0.7),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _actionTile(IconData icon, String title, String trailingText) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty)
            Text(
              trailingText,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
        ],
      ),
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.textSecondary.withOpacity(0.05), indent: 56);
}
