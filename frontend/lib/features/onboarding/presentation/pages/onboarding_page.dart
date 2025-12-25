import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/pages/auth_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: 'ÖSYM Rehberi\'ne\nHoş Geldiniz',
      description:
          'Üniversite tercihlerinizi yapay zeka destekli sistemimizle kolayca belirleyin. Hedeflerinize ulaşmanız için size özel öneriler sunuyoruz.',
      icon: Icons.school_rounded,
      gradient: [Color(0xFFE91E63), Color(0xFFFFC107)],
    ),
    OnboardingContent(
      title: 'Deneme Sonuçlarınızı\nKaydedin',
      description:
          'Yaptığınız denemelerin netlerini girerek gelişiminizi takip edin. Sistem, performansınıza göre size en uygun tercihleri önerir.',
      icon: Icons.analytics_rounded,
      gradient: [Color(0xFF2196F3), Color(0xFFFF4081)],
    ),
    OnboardingContent(
      title: 'Kişiselleştirilmiş\nTercih Önerileri',
      description:
          'Tercih ettiğiniz şehirler, bölümler ve üniversite türlerine göre yapay zeka size en uygun programları önerir.',
      icon: Icons.lightbulb_rounded,
      gradient: [Color(0xFFFFC107), Color(0xFFE91E63)],
    ),
    OnboardingContent(
      title: 'Hedefinizi\nTakip Edin',
      description:
          'Hedef bölümünüze ne kadar yakın olduğunuzu görün. İlerlemenizi anlık olarak izleyin ve motivasyonunuzu yüksek tutun.',
      icon: Icons.track_changes_rounded,
      gradient: [Color(0xFF00BCD4), Color(0xFF2196F3)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _skip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button - Stitch Style
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Atla',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], theme);
                },
              ),
            ),

            // Page indicator and next button - Stitch Style
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: theme.colorScheme.primary,
                      dotColor:
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                      dotHeight: 10,
                      dotWidth: 10,
                      spacing: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Başlayalım'
                            : 'Devam',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingContent content, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background - Stitch Style
          // ✅ Fixed aspect ratio: Layout kaymasını önler
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: content.gradient,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: content.gradient[0].withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                content.icon,
                size: 120,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 64),
          // Title - Stitch Style
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // Description - Stitch Style
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
