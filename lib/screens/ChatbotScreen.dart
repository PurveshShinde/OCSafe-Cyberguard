import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Assistant"),
      ),
      body: const WebView(
        initialUrl: "https://id-preview--b39997e2-1066-44f9-bef9-0071f566b1cd.lovable.app",
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
