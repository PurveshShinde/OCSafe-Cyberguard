import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/features/home/presentation/widgets/home_screen_content.dart';

// Redirecting to the content widget which has the state and layout
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We are using the StatefulWidget version in home_screen_content.dart
    // which is incorrectly named HomeScreen in the previous file.
    // Let's fix the import and usage.
    return const HomeScreenContent(); 
  }
}
