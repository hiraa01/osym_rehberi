import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/api_service.dart';
import '../models/user_model.dart';

/// Simple Auth Service - No complex state management
class AuthService {
  final ApiService _apiService;
  UserModel? _currentUser;
  String? _authToken;

  AuthService(this._apiService);

  UserModel? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  Future<void> loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');
      final isOnboardingCompleted = prefs.getBool('is_onboarding_completed') ?? false;
      final isInitialSetupCompleted = prefs.getBool('is_initial_setup_completed') ?? false;

      if (token != null && userId != null) {
        _authToken = token;
        // OFFLINE-FIRST: Local storage'dan kullanıcı bilgilerini yükle (API YOK!)
        _currentUser = UserModel(
          id: userId,
          name: userName,
          email: userEmail,
          phone: userPhone,
          isActive: true, // Local'de varsa aktif sayıyoruz
          isOnboardingCompleted: isOnboardingCompleted,
          isInitialSetupCompleted: isInitialSetupCompleted,
          createdAt: DateTime.now(), // Gerçek değer backend'den gelecek
        );
      }
    } catch (e) {
      _currentUser = null;
      _authToken = null;
    }
  }

  // Background'da backend ile sync (UI'ı bloklamaz)
  Future<void> syncWithBackend(int userId) async {
    try {
      // Backend'den güncel kullanıcı bilgilerini al
      final response = await _apiService.getUserInfo(userId);
      final updatedUser = UserModel.fromJson(response.data);
      
      // Güncel bilgileri kaydet
      _currentUser = updatedUser;
      await _saveUserToLocal(updatedUser);
      
      // ✅ SYNC SONRASI: Student ID'yi de kontrol et ve güncelle
      await _loadAndSaveStudentId(userId);
    } catch (e) {
      // Sync hatası - offline mode devam
      throw Exception('Backend sync failed: $e');
    }
  }

  Future<void> _saveUserToLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.name != null) await prefs.setString('user_name', user.name!);
    if (user.email != null) await prefs.setString('user_email', user.email!);
    if (user.phone != null) await prefs.setString('user_phone', user.phone!);
    await prefs.setBool('is_onboarding_completed', user.isOnboardingCompleted);
    await prefs.setBool('is_initial_setup_completed', user.isInitialSetupCompleted);
  }

  Future<UserModel> register({
    String? email,
    String? phone,
    String? name,
  }) async {
    try {
      final response = await _apiService.register(
        email: email,
        phone: phone,
        name: name,
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Token ve user bilgilerini kaydet
      await _saveAuth(authResponse.token, authResponse.user.id);

      _currentUser = authResponse.user;
      _authToken = authResponse.token;

      // ✅ REGISTER SONRASI: Student ID'yi bul ve kaydet (varsa)
      await _loadAndSaveStudentId(authResponse.user.id);

      return authResponse.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> login({
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _apiService.login(
        email: email,
        phone: phone,
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Token ve user bilgilerini kaydet
      await _saveAuth(authResponse.token, authResponse.user.id);

      _currentUser = authResponse.user;
      _authToken = authResponse.token;

      // ✅ LOGIN SONRASI: Student ID'yi bul ve kaydet
      await _loadAndSaveStudentId(authResponse.user.id);

      return authResponse.user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ User ID'den Student ID'yi bul ve kaydet
  Future<void> _loadAndSaveStudentId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Önce cache'den kontrol et
      final cachedStudentId = prefs.getInt('student_id');
      if (cachedStudentId != null) {
        // Cache'de varsa, backend'den doğrula
        try {
          final studentResponse = await _apiService.getStudent(cachedStudentId);
          // Student bulundu, geçerli
          return;
        } catch (_) {
          // Cache'deki student_id geçersiz, sil ve yeniden bul
          await prefs.remove('student_id');
        }
      }
      
      // Backend'den student profilini getir
      final response = await _apiService.getUserStudentProfile(userId);
      final studentData = response.data['student'];
      
      if (studentData != null && studentData['id'] != null) {
        // Student ID'yi kaydet
        await prefs.setInt('student_id', studentData['id'] as int);
        debugPrint('✅ Student ID loaded and saved: ${studentData['id']}');
      } else {
        debugPrint('⚠️ No student profile found for user $userId');
      }
    } catch (e) {
      // Student bulunamadı - normal (henüz profil oluşturulmamış olabilir)
      debugPrint('ℹ️ Could not load student ID for user $userId: $e');
    }
  }

  Future<UserModel> updateUser({
    String? name,
    bool? isOnboardingCompleted,
    bool? isInitialSetupCompleted,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final response = await _apiService.updateUser(
        userId: _currentUser!.id,
        name: name,
        isOnboardingCompleted: isOnboardingCompleted,
        isInitialSetupCompleted: isInitialSetupCompleted,
      );

      _currentUser = UserModel.fromJson(response.data);
      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ TÜM CACHE'İ TEMİZLE - Yeni kullanıcı fresh data görsün!
    await prefs.clear();
    
    _currentUser = null;
    _authToken = null;
  }

  Future<void> _saveAuth(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', userId);
    if (_currentUser != null) {
      await _saveUserToLocal(_currentUser!);
    }
  }
}

// Global instance - Simple singleton pattern
AuthService? _authServiceInstance;

AuthService getAuthService(ApiService apiService) {
  _authServiceInstance ??= AuthService(apiService);
  return _authServiceInstance!;
}

