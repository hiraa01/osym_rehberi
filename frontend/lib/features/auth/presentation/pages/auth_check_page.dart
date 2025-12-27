import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/api_service.dart';
import '../../data/providers/auth_service.dart';
import '../../../onboarding/presentation/pages/stitch_onboarding_page.dart';
import '../../../initial_setup/presentation/pages/initial_setup_page.dart';
import '../../../main_layout/presentation/pages/main_layout_page.dart';
import 'auth_page.dart';

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    // UI'ın render edilmesini bekle, sonra auth kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Onboarding kontrolü
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StitchOnboardingPage()),
          );
        }
        return;
      }

      // 2. Auth token kontrolü
      final authToken = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');

      if (authToken != null && userId != null) {
        // Token var, kullanıcı giriş yapmış
        // OFFLINE-FIRST: Önce local storage'dan yükle, backend'e istek atma
        final authService = getAuthService(ApiService());

        try {
          // Local storage'dan kullanıcı bilgilerini yükle (API çağrısı YOK)
          await authService.loadStoredAuth();

          if (authService.isAuthenticated && authService.currentUser != null) {
            // Kullanıcı local'de var
            final user = authService.currentUser!;

            if (mounted) {
              if (!user.isInitialSetupCompleted) {
                // İlk kurulum tamamlanmamış
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const InitialSetupPage()),
                );
              } else {
                // Her şey tamam, ana sayfaya git
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainLayoutPage()),
                );
              }
            }

            // Background'da backend ile sync yap (optional)
            _syncWithBackend(authService, userId);
            
            // ✅ KRİTİK: Student ID kontrolü ve otomatik düzeltme
            _ensureStudentId(authService, userId);
          } else {
            // Local'de kullanıcı bulunamadı, giriş sayfasına git
            _navigateToAuth();
          }
        } catch (e) {
          // Local storage okuma hatası
          debugPrint('Local auth load error: $e');
          _navigateToAuth();
        }
      } else {
        // Token yok, giriş sayfasına git
        _navigateToAuth();
      }
    } catch (e) {
      debugPrint('Auth status check error: $e');
      _navigateToAuth();
    }
  }

  // Background'da backend ile sync (UI'ı bloklamaz)
  Future<void> _syncWithBackend(dynamic authService, int userId) async {
    try {
      // Backend ile sync - hata olsa bile UI etkilenmez
      await authService.syncWithBackend(userId);
      debugPrint('✅ Backend sync successful');
    } catch (e) {
      debugPrint('⚠️ Backend sync failed (offline mode): $e');
      // Hata olsa bile devam et - offline mode
    }
  }

  // ✅ AUTO-REPAIR: Student ID'yi garanti et
  Future<void> _ensureStudentId(dynamic authService, int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');
      
      // Student ID varsa ve geçerliyse, işlem yapma
      if (studentId != null) {
        try {
          await authService._apiService.getStudent(studentId);
          debugPrint('✅ Student ID is valid: $studentId');
          return;
        } catch (_) {
          // Geçersiz student_id, temizle
          await prefs.remove('student_id');
          debugPrint('⚠️ Invalid student_id removed');
        }
      }
      
      // Student ID yoksa veya geçersizse, otomatik düzelt
      debugPrint('🔄 Ensuring student ID for user $userId...');
      final ensuredStudentId = await authService.ensureStudentId();
      
      if (ensuredStudentId != null) {
        debugPrint('✅ Student ID ensured: $ensuredStudentId');
      } else {
        debugPrint('⚠️ Could not ensure student ID (will be created when needed)');
      }
    } catch (e) {
      debugPrint('⚠️ Error ensuring student ID: $e');
      // Hata olsa bile devam et - kullanıcı deneme eklerken oluşturulacak
    }
  }

  void _navigateToAuth() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'ÖSYM Rehberi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
