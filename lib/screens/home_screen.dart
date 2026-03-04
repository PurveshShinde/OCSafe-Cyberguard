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
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.security, size: 40, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'OcSafe CyberGuard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Mobile Security',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _drawerItem(Icons.home_outlined, 'Dashboard', () {
            Navigator.pop(context);
            setState(() => _currentIndex = 0);
          }),
          _drawerItem(Icons.security_outlined, 'Permissions', () {
            Navigator.pop(context);
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PermissionsScreen()));
          }),
          _drawerItem(Icons.speed_outlined, 'Device Health', () {
            Navigator.pop(context);
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OptimizationScreen()));
          }),
          _drawerItem(Icons.analytics_outlined, 'Scan History', () {
            Navigator.pop(context);
            setState(() => _currentIndex = 1);
          }),
          const Divider(color: AppColors.divider),
          _drawerItem(Icons.settings_outlined, 'Settings', () {
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
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      onTap: onTap,
    );
  }
}
