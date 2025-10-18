import 'package:flutter/material.dart';

import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../exam_attempts/presentation/pages/exam_attempts_page.dart';
import '../../../goals/presentation/pages/goals_page.dart';
import '../../../recommendations/presentation/pages/recommendations_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/animated_bottom_bar.dart';

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ExamAttemptsPage(),
    GoalsPage(),
    RecommendationsPage(),
    ProfilePage(),
  ];

  final List<BottomBarItem> _barItems = const [
    BottomBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Anasayfa',
    ),
    BottomBarItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Denemeler',
    ),
    BottomBarItem(
      icon: Icons.flag_outlined,
      activeIcon: Icons.flag,
      label: 'Hedefim',
    ),
    BottomBarItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: 'Öneriler',
    ),
    BottomBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AnimatedBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _barItems,
      ),
    );
  }
}

