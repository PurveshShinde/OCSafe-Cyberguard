import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/screens/dashboard_content.dart';
import 'package:ocsafe_cyberguard/screens/reports_screen.dart';
import 'package:ocsafe_cyberguard/screens/profile_screen.dart';
import 'package:ocsafe_cyberguard/screens/settings_screen.dart';
import 'package:ocsafe_cyberguard/screens/permissions_screen.dart';
import 'package:ocsafe_cyberguard/screens/optimization_screen.dart';

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
    ProfileScreen(),
  ];

  static const List<String> _titles = [
    'OcSafe CyberGuard',
    'Reports',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: AppColors.primary),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 70, bottom: 24, left: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.security, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OcSafe CyberGuard',
                  style: TextStyle(
                    color: Color(0xFF1E293B), // Dark slate blue
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mobile Security',
                  style: TextStyle(
                    color: Colors.grey,
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
              Navigator.pop(context);
              // Implement logout
            },
            isDestructive: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        icon, 
        color: isDestructive ? Colors.red.shade400 : const Color(0xFF64748B), // Slate gray for standard items
        size: 26,
      ),
      title: Text(
        label, 
        style: TextStyle(
          color: isDestructive ? Colors.red.shade400 : const Color(0xFF1E293B),
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
        )
      ),
      onTap: onTap,
    );
  }
}
