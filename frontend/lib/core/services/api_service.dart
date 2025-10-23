import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    // ⚠️ IP ADRESİNİ DURUMUNUZA GÖRE DEĞİŞTİRİN:
    // 🖥️  Android Emulator:    10.0.2.2:8002
    // 📱 Gerçek Android Cihaz: Bilgisayarınızın WiFi IP'si (cmd: ipconfig)
    // 🌐 Web:                  localhost:8002
    
    // ✅ Güncel WiFi IP: ipconfig.exe ile kontrol edin
    const String baseUrl = kIsWeb 
        ? 'http://localhost:8002/api'
        : 'http://172.31.88.134:8002/api'; // 👈 Windows WiFi IP (değişebilir!)
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5), // Backend'e bağlanma için 5 saniye (hızlı fail)
      receiveTimeout: const Duration(seconds: 10), // Cevap almak için 10 saniye
      sendTimeout: const Duration(seconds: 10), // Veri göndermek için 10 saniye
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    // Bağlantı hatası interceptor'ı (hem debug hem production'da çalışır)
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('API Error: ${error.message}');
          if (error.response != null) {
            debugPrint('Response: ${error.response?.data}');
          }
        }
        
        // Bağlantı hatası kontrolü
        if (error.type == DioExceptionType.connectionTimeout || 
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError) {
          
          // Kullanıcı dostu hata mesajı oluştur
          final userFriendlyError = DioException(
            requestOptions: error.requestOptions,
            error: error,
            type: error.type,
            message: _getConnectionErrorMessage(error),
          );
          handler.next(userFriendlyError);
          return;
        }
        
        handler.next(error);
      },
    ));
  }

  /// Bağlantı hataları için kullanıcı dostu mesaj oluştur
  String _getConnectionErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return "⏱️ Bağlantı zaman aşımı! WiFi bağlantınızı kontrol edin ve aynı ağda olduğunuzdan emin olun.";
      
      case DioExceptionType.receiveTimeout:
        return "📡 Sunucudan yanıt alınamadı! WiFi bağlantınızı kontrol edin ve aynı ağda olduğunuzdan emin olun.";
      
      case DioExceptionType.sendTimeout:
        return "📤 Veri gönderilemedi! WiFi bağlantınızı kontrol edin ve aynı ağda olduğunuzdan emin olun.";
      
      case DioExceptionType.connectionError:
        return "🔌 Bağlantı hatası! WiFi bağlantınızı kontrol edin ve aynı ağda olduğunuzdan emin olun.";
      
      default:
        return "🌐 Ağ bağlantı sorunu! WiFi bağlantınızı kontrol edin ve aynı ağda olduğunuzdan emin olun.";
    }
  }

  // Student endpoints
  Future<Response> getStudents({int skip = 0, int limit = 100}) async {
    return await _dio.get('/students', queryParameters: {
      'skip': skip,
      'limit': limit,
    });
  }

  Future<Response> getStudent(int id) async {
    return await _dio.get('/students/$id');
  }

  Future<Response> createStudent(Map<String, dynamic> data) async {
    return await _dio.post('/students/', data: data); // Trailing slash added
  }

  Future<Response> updateStudent(int id, Map<String, dynamic> data) async {
    return await _dio.put('/students/$id', data: data);
  }

  Future<Response> deleteStudent(int id) async {
    return await _dio.delete('/students/$id');
  }

  Future<Response> calculateScores(int id) async {
    return await _dio.post('/students/$id/calculate-scores');
  }

  // University endpoints
  Future<Response> getUniversities() async {
    return await _dio.get('/universities');
  }

  Future<Response> getDepartments() async {
    return await _dio.get('/universities/departments/?limit=1000');  // ✅ Daha fazla bölüm getir
  }

  Future<Response> getCities() async {
    return await _dio.get('/universities/cities/');  // ✅ Trailing slash eklendi
  }

  Future<Response> getFieldTypes() async {
    return await _dio.get('/universities/field-types/');  // ✅ Trailing slash eklendi
  }

  Future<Response> getDepartmentsFiltered({
    String? fieldType,
    String? city,
    String? universityType,
    double? minScore,
    double? maxScore,
    bool? hasScholarship,
    int skip = 0,
    int limit = 100,
  }) async {
    return await _dio.get('/universities/departments', queryParameters: {
      if (fieldType != null) 'field_type': fieldType,
      if (city != null) 'city': city,
      if (universityType != null) 'university_type': universityType,
      if (minScore != null) 'min_score': minScore,
      if (maxScore != null) 'max_score': maxScore,
      if (hasScholarship != null) 'has_scholarship': hasScholarship,
      'skip': skip,
      'limit': limit,
    });
  }

  Future<Response> getUniversitiesFiltered({
    String? city,
    String? universityType,
    int skip = 0,
    int limit = 100,
  }) async {
    return await _dio.get('/universities', queryParameters: {
      if (city != null) 'city': city,
      if (universityType != null) 'university_type': universityType,
      'skip': skip,
      'limit': limit,
    });
  }

  // Recommendation endpoints
  Future<Response> generateRecommendations(int studentId, {int limit = 50}) async {
    return await _dio.post('/recommendations/generate/$studentId', queryParameters: {
      'limit': limit,
    });
  }

  Future<Response> getStudentRecommendations(int studentId) async {
    return await _dio.get('/recommendations/student/$studentId');
  }

  Future<Response> getRecommendationStats(int studentId) async {
    return await _dio.get('/recommendations/stats/$studentId');
  }

  // Health check (not under /api prefix)
  Future<Response> healthCheck() async {
    return await _dio.get(
      'http://${kIsWeb ? 'localhost' : '172.31.88.134'}:8002/health',
      options: Options(
        sendTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
  }

  // Auth endpoints
  Future<Response> register({
    String? email,
    String? phone,
    String? name,
  }) async {
    // Register için daha uzun timeout (database işlemleri için)
    return await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'phone': phone,
        'name': name,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 30), // 30 saniye timeout
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response> login({
    String? email,
    String? phone,
  }) async {
    // Login için de uzun timeout
    return await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'phone': phone,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response> getUserInfo(int userId) async {
    return await _dio.get('/auth/me/$userId');
  }

  Future<Response> updateUser({
    required int userId,
    String? name,
    String? email,
    String? phone,
    bool? isOnboardingCompleted,
    bool? isInitialSetupCompleted,
  }) async {
    return await _dio.put('/auth/me/$userId', data: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (isOnboardingCompleted != null) 'is_onboarding_completed': isOnboardingCompleted,
      if (isInitialSetupCompleted != null) 'is_initial_setup_completed': isInitialSetupCompleted,
    });
  }

  // Exam Attempt endpoints
  Future<Response> createExamAttempt(Map<String, dynamic> data) async {
    return await _dio.post('/exam-attempts/', data: data);
  }

  Future<Response> getStudentAttempts(int studentId) async {
    return await _dio.get('/exam-attempts/student/$studentId');
  }

  Future<Response> updateExamAttempt(int attemptId, Map<String, dynamic> data) async {
    return await _dio.put('/exam-attempts/$attemptId', data: data);
  }

  Future<Response> deleteExamAttempt(int attemptId) async {
    return await _dio.delete('/exam-attempts/$attemptId');
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
