import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
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
    'Dashboard',
    'Reports',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomNavItem(0, Icons.home_rounded, 'Home'),
            _bottomNavItem(1, Icons.assignment_rounded, 'Reports'),
            _bottomNavItem(2, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.3),
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.3),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.03),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OcSafe CyberGuard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Mobile Security',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _drawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
                _drawerItem(Icons.lock_rounded, 'Permissions', -1, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen()))),
                _drawerItem(Icons.monitor_heart_rounded, 'Device Health', -1, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OptimizationScreen()))),
                _drawerItem(Icons.history_rounded, 'Scan History', 1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Divider(height: 1),
                ),
                _drawerItem(Icons.settings_rounded, 'Settings', -1, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                _drawerItem(Icons.info_rounded, 'About', -1),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int targetIndex, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: AppColors.textPrimary.withOpacity(0.7), size: 24),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap();
        } else if (targetIndex != -1) {
          setState(() => _currentIndex = targetIndex);
        }
      },
    );
  }
}
