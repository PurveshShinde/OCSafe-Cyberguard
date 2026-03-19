import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/auth/login_screen.dart';
import 'package:ocsafe_cyberguard/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print("DEBUG: Attempting to initialize Firebase...");
    await Firebase.initializeApp();
    print("DEBUG: Firebase initialized successfully.");
  } catch (e, stacktrace) {
    print("DEBUG: Firebase initialization failed: \$e");
    print(stacktrace);
    
    // TEMPORARY DEBUG UI / ERROR REPORTING
    // Prevents the black screen crash if config is missing
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Firebase Initialization Error:\\n\\n\$e\\n\\nPlease ensure google-services.json is added in android/app.',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    return;
  }

  // RESTORE ORIGINAL SCREEN: Run normal app if successful
  print("DEBUG: Starting OcSafeApp...");
  runApp(const OcSafeApp());
}

@pragma('vm:entry-point')
void mainBackground() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
