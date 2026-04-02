import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {

  final TextEditingController controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  String getBotReply(String message) {
    message = message.toLowerCase();

    if (message.contains("phishing")) return "Phishing is a scam.";
    else if (message.contains("malware")) return "Malware is harmful software.";
    else if (message.contains("vpn")) return "VPN protects your privacy.";
    else if (message.contains("password")) return "Use strong passwords.";
    else if (message.contains("otp")) return "Never share OTP.";

    return "Ask cybersecurity questions.";
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

      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg["isUser"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["isUser"] ? Colors.purple : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["msg"],
                      style: TextStyle(
                        color: msg["isUser"] ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Ask something...",
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  String userMessage = controller.text;

                  if (userMessage.isEmpty) return;

                  setState(() {
                    messages.add({"msg": userMessage, "isUser": true});
                  });

                  String reply = getBotReply(userMessage);

                  setState(() {
                    messages.add({"msg": reply, "isUser": false});
                  });

                  controller.clear();
                },
              )
            ],
          )

        ],
      ),
    );
  }
}
