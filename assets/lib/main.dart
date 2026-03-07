import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OcSafeApp());
}

@pragma('vm:entry-point')
void mainBackground() {
  WidgetsFlutterBinding.ensureInitialized();
  
  const MethodChannel backgroundChannel = MethodChannel('com.ocsafe.cyberguard/background');
  
  backgroundChannel.setMethodCallHandler((call) async {
    print('DEBUG: Background Method Call: ${call.method} with args: ${call.arguments}');
    if (call.method == 'scan_app') {
      final String? packageName = call.arguments['package_name'];
      if (packageName != null) {
        print('DEBUG: Starting headless scan for $packageName');
        // Initialize independent headless instances
        final securityProvider = SecurityProvider();
        await securityProvider.initializeHeadless();
        await securityProvider.scanSingleAppHeadless(packageName);
      }
    }
  });

  // Signal Kotlin that we are ready to receive queued scans
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
        home: const HomeScreen(),
      ),
    );
  }
}
