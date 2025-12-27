import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

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
      
      // Null kontrolü ve response.data tip kontrolü
      if (response.data == null) {
        throw Exception('Kullanıcı bilgileri alınamadı');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Geçersiz kullanıcı bilgisi formatı');
      }

      final updatedUser = UserModel.fromJson(response.data as Map<String, dynamic>);
      
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
      debugPrint('🔵 Register attempt: email=$email, phone=$phone, name=$name');
      
      final response = await _apiService.register(
        email: email,
        phone: phone,
        name: name,
      );

      debugPrint('🔵 Register response status: ${response.statusCode}');
      debugPrint('🔵 Register response data type: ${response.data.runtimeType}');
      debugPrint('🔵 Register response data: ${response.data}');

      // Response status kontrolü - 400-499 hataları da artık response olarak geliyor
      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        // Backend'den hata response'u geldi
        String errorMessage = 'Kayıt başarısız';
        
        if (response.data != null) {
          if (response.data is Map) {
            errorMessage = (response.data as Map)['detail'] ?? 
                          (response.data as Map)['message'] ?? 
                          errorMessage;
          } else if (response.data is String) {
            errorMessage = response.data as String;
          }
        }
        
        debugPrint('🔴 Register failed: $errorMessage (Status: ${response.statusCode})');
        throw Exception(errorMessage);
      }

      // Null kontrolü ve response.data tip kontrolü
      if (response.data == null) {
        debugPrint('🔴 Register failed: response.data is null');
        throw Exception('Kayıt başarısız: Sunucudan yanıt alınamadı');
      }

      if (response.data is! Map<String, dynamic>) {
        debugPrint('🔴 Unexpected response format: ${response.data.runtimeType}');
        debugPrint('🔴 Response data: ${response.data}');
        throw Exception('Kayıt başarısız: Geçersiz yanıt formatı (${response.data.runtimeType})');
      }

      debugPrint('🟢 Register response is valid Map, parsing...');
      final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      debugPrint('🟢 Register successful: user_id=${authResponse.user.id}');

      // Token ve user bilgilerini kaydet
      await _saveAuth(authResponse.token, authResponse.user.id);

      _currentUser = authResponse.user;
      _authToken = authResponse.token;

      // ✅ REGISTER SONRASI: Student ID'yi bul ve kaydet (varsa)
      await _loadAndSaveStudentId(authResponse.user.id);

      return authResponse.user;
    } on DioException catch (e) {
      // Dio hatalarını özel olarak handle et
      debugPrint('🔴 DioException during register: ${e.type}');
      
      if (e.response != null) {
        // Backend'den hata response'u geldi
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        
        debugPrint('🔴 Error status: $statusCode');
        debugPrint('🔴 Error data type: ${errorData.runtimeType}');
        debugPrint('🔴 Error data: $errorData');
        
        // Backend'den gelen hata mesajını extract et
        String errorMessage = 'Kayıt başarısız';
        if (errorData is Map) {
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } else if (errorData is String) {
          errorMessage = errorData;
        }
        
        throw Exception(errorMessage);
      } else {
        // Network/connection hatası
        throw Exception('Bağlantı hatası: ${e.message}');
      }
    } catch (e) {
      debugPrint('🔴 Unexpected error during register: $e');
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

      // Null kontrolü ve response.data tip kontrolü
      if (response.data == null) {
        throw Exception('Giriş başarısız: Sunucudan yanıt alınamadı');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Giriş başarısız: Geçersiz yanıt formatı');
      }

      final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);

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
          await _apiService.getStudent(cachedStudentId);
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

  // ✅ AUTO-REPAIR: Student ID'yi garanti et - yoksa otomatik oluştur
  Future<int?> ensureStudentId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Önce cache'den kontrol et
      final cachedStudentId = prefs.getInt('student_id');
      if (cachedStudentId != null) {
        // Cache'de varsa, backend'den doğrula
        try {
          await _apiService.getStudent(cachedStudentId);
          // Student bulundu, geçerli
          debugPrint('✅ Student ID from cache is valid: $cachedStudentId');
          return cachedStudentId;
        } catch (_) {
          // Cache'deki student_id geçersiz, sil
          await prefs.remove('student_id');
          debugPrint('⚠️ Cached student_id is invalid, removed');
        }
      }
      
      // 2. User ID kontrolü
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        debugPrint('⚠️ User ID not found, cannot ensure student ID');
        return null;
      }
      
      // 3. Backend'den student profilini getir
      try {
        final response = await _apiService.getUserStudentProfile(userId);
        final studentData = response.data['student'];
        
        if (studentData != null && studentData['id'] != null) {
          // Student bulundu, kaydet
          final studentId = studentData['id'] as int;
          await prefs.setInt('student_id', studentId);
          debugPrint('✅ Student ID loaded from backend: $studentId');
          return studentId;
        }
      } catch (e) {
        debugPrint('⚠️ Could not load student profile: $e');
      }
      
      // 4. Student bulunamadı - otomatik oluştur
      debugPrint('🔄 Student profile not found, creating new one...');
      try {
        final userName = prefs.getString('user_name') ?? 'Öğrenci';
        final userEmail = prefs.getString('user_email');
        final userPhone = prefs.getString('user_phone');
        
        // Minimal student profili oluştur
        final studentResponse = await _apiService.createStudent({
          'name': userName,
          'email': userEmail,
          'phone': userPhone,
          'class_level': '12',
          'exam_type': 'TYT+AYT',
          'field_type': 'SAY', // Varsayılan, kullanıcı daha sonra güncelleyebilir
        });
        
        if (studentResponse.data != null && studentResponse.data['id'] != null) {
          final studentId = studentResponse.data['id'] as int;
          await prefs.setInt('student_id', studentId);
          debugPrint('✅ Student profile created automatically: $studentId');
          return studentId;
        }
      } catch (e) {
        debugPrint('🔴 Failed to create student profile: $e');
        // User silinmiş olabilir - logout yap
        if (e.toString().contains('404') || e.toString().contains('401')) {
          debugPrint('⚠️ User not found, logging out...');
          await logout();
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('🔴 Error ensuring student ID: $e');
      return null;
    }
  }

  // ✅ Student ID'yi getir (public method)
  Future<int?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('student_id');
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

      // Null kontrolü ve response.data tip kontrolü
      if (response.data == null) {
        throw Exception('Kullanıcı bilgileri güncellenemedi');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Geçersiz yanıt formatı');
      }

      _currentUser = UserModel.fromJson(response.data as Map<String, dynamic>);
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

