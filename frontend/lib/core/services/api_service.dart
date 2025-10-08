import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    // Android emulator için: 10.0.2.2
    // Gerçek cihaz için: Bilgisayarınızın IP adresi (örn: 192.168.1.100 veya 172.x.x.x)
    // Web için: localhost veya bilgisayar IP'si
    const String baseUrl = kIsWeb 
        ? 'http://localhost:8001/api'
        : 'http://172.31.88.134:8001/api'; // Okul WiFi IP adresi
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(minutes: 2), // 2 dakika
      receiveTimeout: const Duration(minutes: 2), // 2 dakika
      sendTimeout: const Duration(minutes: 2), // 2 dakika
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

      _dio.interceptors.add(InterceptorsWrapper(
        onError: (error, handler) {
          debugPrint('API Error: ${error.message}');
          if (error.response != null) {
            debugPrint('Response: ${error.response?.data}');
          }
          handler.next(error);
        },
      ));
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
    return await _dio.get('/universities/departments');
  }

  Future<Response> getCities() async {
    return await _dio.get('/universities/cities');
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

  // Health check
  Future<Response> healthCheck() async {
    return await _dio.get('/health');
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
