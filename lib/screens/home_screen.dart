import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/screens/auth/login_screen.dart';
import 'package:ocsafe_cyberguard/screens/dashboard_content.dart';
import 'package:ocsafe_cyberguard/screens/ChatbotScreen.dart';
import 'package:ocsafe_cyberguard/screens/reports_screen.dart';
import 'package:ocsafe_cyberguard/screens/profile_screen.dart';
import 'package:ocsafe_cyberguard/screens/settings_screen.dart';
import 'package:ocsafe_cyberguard/screens/permissions_screen.dart';
import 'package:ocsafe_cyberguard/screens/optimization_screen.dart';

import 'package:ocsafe_cyberguard/screens/scan_screen.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';


/// Main scaffold with bottom navigation and side drawer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    DashboardContent(),
    ReportsScreen(),
    ChatbotScreen(),
    ProfileScreen(),
  ];

  static const List<String> _titles = [
    'OcSafe CyberGuard',
    'Reports',
    'AI Assistant',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // App-wide radiant background mapping the screenshot's exact palette
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF5F3FF), // Very soft pale purple
                Color(0xFFE0E7FF), // Extremely light indigo/purple hue
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          appBar: AppBar(
            title: Text(_titles[_currentIndex]),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          drawer: _buildDrawer(),
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildGlassBottomNav(),
        ),
      ],
    );
  }

  Widget _buildGlassBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home),
                _navItem(1, Icons.analytics_outlined, Icons.analytics),
                GestureDetector(
                  onTap: () {
                    final provider = context.read<SecurityProvider>();
                    if (!provider.isScanning) {
                      provider.runScan(ScanType.deep);
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
                      ]
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24),
                  ),
                ),
                _navItem(2, Icons.smart_toy_outlined, Icons.smart_toy),
                _navItem(3, Icons.settings_outlined, Icons.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData outlineIcon, IconData filledIcon) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        isSelected ? filledIcon : outlineIcon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 28,
      ),
      onPressed: () => setState(() => _currentIndex = index),
    );
  }

  // Removed buildWrapper

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent, // Using glass for Drawer
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface, // Clean flat color for drawer
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 70, bottom: 24, left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGlow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.security, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'OcSafe CyberGuard',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mobile Security',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _drawerItem(Icons.home, 'Dashboard', () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                }),
                _drawerItem(Icons.security, 'Permissions', () {
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PermissionsScreen()));
                }),
                _drawerItem(Icons.monitor_heart, 'Device Health', () {
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OptimizationScreen()));
                }),
                _drawerItem(Icons.history, 'Scan History', () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                }),
                _drawerItem(Icons.vpn_key_outlined, 'VPN Service', () async {
                  Navigator.pop(context);
                  final Uri url = Uri.parse('https://chromewebstore.google.com/detail/majdfhpaihoncoakbjgbdhglocklcgno?utm_source=item-share-cb');
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    debugPrint('Could not launch $url');
                  }
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1), // Light gray divider
                ),
                _drawerItem(Icons.settings, 'Settings', () {
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
                _drawerItem(Icons.info_outline, 'About', () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'OcSafe CyberGuard',
                    applicationVersion: '1.0.0',
                    children: [
                      const Text('A mobile security application that helps protect your device.'),
                    ],
                  );
                }),
              ],
            ),
          ),
          _drawerItem(
            Icons.logout,
            'Sign Out',
            () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            isDestructive: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        icon, 
        color: isDestructive ? AppColors.error : AppColors.textSecondary,
        size: 26,
      ),
      title: Text(
        label, 
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
        )
      ),
      onTap: onTap,
    );
  }
}
