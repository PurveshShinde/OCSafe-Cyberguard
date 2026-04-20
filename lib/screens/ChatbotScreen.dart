import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'dart:ui';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> messages = [
    {"msg": "Hi! I'm your AI security assistant. How can I help you protect your device today?", "isUser": false}
  ];

  final List<String> _suggestions = [
    "What is Phishing?",
    "What does a VPN do?",
    "How to spot malware?",
    "Password best practices"
  ];

  String getBotReply(String message) {
    message = message.toLowerCase();
    if (message.contains("phishing")) {
      return "Phishing is a cyber attack where scammers impersonate trusted companies (like your bank) via email or SMS. They try to trick you into revealing passwords or credit card numbers. \n\nTip: Never click suspicious links and always verify the sender!";
    } else if (message.contains("malware")) {
      return "Malware stands for 'Malicious Software'. It includes viruses, trojans, and spyware designed to damage your device or steal background data. \n\nThe best defense is avoiding unofficial app stores and running regular deep scans with OcSafe.";
    } else if (message.contains("vpn")) {
      return "A VPN (Virtual Private Network) creates a secure, encrypted tunnel for your internet traffic. It hides your online activity from hackers, which is extremely important when using public Wi-Fi networks at cafes or airports.";
    } else if (message.contains("password") || message.contains("privacy") || message.contains("best practice")) {
      return "Here are the top rules for digital privacy:\n\n1. Use a unique password for every account.\n2. Turn on Two-Factor Authentication (2FA) everywhere.\n3. Review your app permissions regularly.\n4. Don't share OTPs with anyone.";
    } else if (message.contains("scan") || message.contains("virus")) {
      return "You can scan your device for threats at any time by tapping the large purple Scan button in the center of the bottom navigation bar. It will check all installed apps and files for known malware patterns.";
    }
    return "I am an AI trained in cybersecurity. I can help you understand threats like phishing, malware, or provide tips on VPNs, passwords, and how to use the OcSafe scanner.";
  }

  void _sendMessage() {
    String userMessage = controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"msg": userMessage, "isUser": true});
    });
    
    controller.clear();
    _scrollToBottom();

    // Simulate AI thinking delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        messages.add({"msg": getBotReply(userMessage), "isUser": false});
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _useSuggestion(String suggestion) {
    controller.text = suggestion;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isUser = msg["isUser"];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                          ]
                        ),
                        child: const Icon(Icons.security_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          msg["msg"],
                          style: TextStyle(
                            color: isUser ? Colors.white : AppColors.textPrimary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Quick Suggestions (Only shows until user sends their first message)
        if (messages.length == 1)
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return GestureDetector(
                  onTap: () => _useSuggestion(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                      ]
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Input Area
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110), // 110px bottom padding to clear the floating nav bar
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
                  ]
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Ask a question...",
                          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))
                          ]
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
