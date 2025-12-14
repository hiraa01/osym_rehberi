import 'package:flutter/material.dart';

import '../../../dashboard/presentation/pages/stitch_dashboard_page.dart';
import '../../../exam_attempts/presentation/pages/stitch_exam_attempts_page.dart';
import '../../../goals/presentation/pages/stitch_goals_page.dart';
import '../../../recommendations/presentation/pages/stitch_recommendations_page.dart';
import '../../../profile/presentation/pages/stitch_profile_page.dart';
import '../../../coach_chat/presentation/coach_chat_fab.dart';
import '../widgets/stitch_bottom_nav_bar.dart';

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _currentIndex = 0;
  final PageController _pageController =
      PageController(initialPage: 2); // Anasayfa ortada

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              StitchExamAttemptsPage(),
              StitchGoalsPage(),
              StitchDashboardPage(), // Anasayfa ortada - Stitch Design
              StitchRecommendationsPage(),
              StitchProfilePage(),
            ],
          ),
          const CoachChatFab(), // Stack içinde Positioned widget
        ],
      ),
      bottomNavigationBar: StitchBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}
