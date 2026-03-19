import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';

/// AI Chatbot screen — opens the assistant in the device browser.
/// webview_flutter is not in pubspec; using url_launcher (already a dependency)
/// which is lighter and has no v3/v4 API compat issues.
class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  static const String _chatbotUrl =
      'https://id-preview--b39997e2-1066-44f9-bef9-0071f566b1cd.lovable.app';

  Future<void> _openChatbot(BuildContext context) async {
    final uri = Uri.parse(_chatbotUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open AI Assistant')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  size: 72,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'AI Security Assistant',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ask questions about threats, permissions, '
                'and how to keep your device safe.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _openChatbot(context),
                  icon: const Icon(Icons.open_in_browser_rounded,
                      color: Colors.white),
                  label: const Text(
                    'Open AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
