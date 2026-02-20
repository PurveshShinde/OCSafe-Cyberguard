import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/features/home/presentation/widgets/quick_actions_grid.dart';
import 'package:ocsafe_cyberguard/features/home/presentation/widgets/security_hero_card.dart';
import 'package:ocsafe_cyberguard/features/home/presentation/widgets/threat_activity_list.dart';
import 'package:ocsafe_cyberguard/features/navigation/presentation/widgets/bottom_nav_bar.dart';
import 'package:ocsafe_cyberguard/features/navigation/presentation/widgets/side_drawer.dart';
import 'package:ocsafe_cyberguard/features/profile/presentation/profile_screen.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    _HomeContent(),
    Center(child: Text('Security Scan (Coming Soon)')),
    Center(child: Text('Reports (Coming Soon)')),
    ProfileScreen(),
  ];

  static const List<String> _titles = [
    'OcSafe',
    'Security',
    'Reports',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: _currentIndex == 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'OcSafe',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              )
            : Text(
                _titles[_currentIndex],
                style: Theme.of(context).textTheme.headlineMedium,
              ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const SideDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.backgroundStart,
                  AppColors.backgroundEnd,
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ],
      ),
      bottomNavigationBar: OcBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          SecurityHeroCard(),
          QuickActionsGrid(),
          ThreatActivityList(),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08FFFFFF)
      ..strokeWidth = 1;

    const step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
