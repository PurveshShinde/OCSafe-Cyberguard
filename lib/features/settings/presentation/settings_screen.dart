import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, 'Security Settings'),
          _buildSwitchTile(context, 'Auto Scan', true),
          _buildSwitchTile(context, 'Real-time Protection', true),
          _buildSwitchTile(context, 'Safe Browsing', true),
          const SizedBox(height: 24),
          
          _buildSectionHeader(context, 'App Preferences'),
          _buildSwitchTile(context, 'Dark Mode', true),
          _buildSettingsTile(context, 'Notification Control', Icons.notifications_none),
          _buildSettingsTile(context, 'Language', Icons.language, trailing: 'English'),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(context, 'Manage Subscription', Icons.card_membership),
          _buildSettingsTile(context, 'Change Password', Icons.lock_outline),
          _buildSettingsTile(
            context,
            'Delete Account',
            Icons.delete_outline,
            textColor: AppColors.error,
            iconColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
          ),
          const Divider(color: AppColors.glassBorder),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, bool value) {
    return SwitchListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      value: value,
      onChanged: (val) {},
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
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon, {
    String? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor ?? AppColors.textPrimary,
            ),
      ),
      trailing: trailing != null
          ? Text(trailing, style: Theme.of(context).textTheme.bodyMedium)
          : const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
      onTap: () {},
    );
  }
}
