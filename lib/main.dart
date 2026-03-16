import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/auth/login_screen.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OcSafeApp());
}

@pragma('vm:entry-point')
void mainBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  const MethodChannel backgroundChannel = MethodChannel('com.ocsafe.cyberguard/background');
  
  backgroundChannel.setMethodCallHandler((call) async {
    print('DEBUG: Background Method Call: ${call.method} with args: ${call.arguments}');
    
    if (call.method == 'package_event') {
      final String? packageName = call.arguments['package_name'];
      final String? action = call.arguments['action'];
      
      if (packageName != null) {
        final securityProvider = SecurityProvider();
        await securityProvider.initializeHeadless();
        
        if (action == 'android.intent.action.PACKAGE_ADDED') {
          print('DEBUG: Starting headless scan for $packageName');
          await securityProvider.scanSingleAppHeadless(packageName);
        } else if (action == 'android.intent.action.PACKAGE_REMOVED') {
          print('DEBUG: Starting headless cleanup for $packageName');
          await securityProvider.removeThreatHeadless(packageName);
        }
      }
    }
  });

  // Signal Kotlin that we are ready to receive queued events
  backgroundChannel.invokeMethod('flutter_ready');
}

class OcSafeApp extends StatelessWidget {
  const OcSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SecurityProvider()..initialize(),
      child: MaterialApp(
        title: 'OcSafe CyberGuard',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: AppTheme.theme,
        home: const LoginScreen(),
      ),
    );
  }
}
