import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// API Service - Backend ile iletişim için optimize edilmiş servis
///
/// ⚠️ PERFORMANS NOTLARI:
/// - Normal endpoint'ler: 30-60 saniye timeout
/// - Büyük veri setleri (universities, departments): 120 saniye timeout + pagination kullanın
/// - Hesaplamalı endpoint'ler (recommendations): 180 saniye timeout
/// - Backend optimize edildi (SQLite WAL mode, index'ler) - timeout'lar makul seviyede
///
/// 📌 PAGINATION KULLANIMI:
/// - getUniversities(skip: 0, limit: 100) - İlk 100 üniversite
/// - getDepartments(skip: 0, limit: 500) - İlk 500 bölüm
/// - getDepartmentsFiltered(...) - Filtreli sorgular için pagination zorunlu
///
/// 🔄 RETRY MEKANİZMASI:
/// - Timeout hataları için manuel retry yapılabilir
/// - Background job pattern için polling mekanizması eklenebilir
class ApiService {
  late final Dio _dio;

  ApiService() {
    // ⚠️ IP ADRESİNİ DURUMUNUZA GÖRE DEĞİŞTİRİN:
    // 🖥️  Android Emulator:    10.0.2.2:8002
    // 📱 Gerçek Android Cihaz: Bilgisayarınızın WiFi IP'si (cmd: ipconfig)
    // 🌐 Web:                  localhost:8002

    // ✅ Güncel WiFi IP: ipconfig.exe ile kontrol edin
    // Android için IP adresini kontrol edin: ipconfig (Windows) veya ifconfig (Linux/Mac)
    const String baseUrl = kIsWeb
        ? 'http://localhost:8002/api'
        : 'http://172.31.88.134:8002/api'; // 👈 Windows WiFi IP (değişebilir!)

    if (kDebugMode) {
      debugPrint('API Base URL: $baseUrl');
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(
          seconds:
              120), // Backend'e bağlanma için 120 saniye (yavaş network için)
      receiveTimeout: const Duration(
          minutes: 20), // ✅ CRITICAL FIX: AI işlemleri için 20 dakika (5 dakikadan uzun olmalı)
      sendTimeout:
          const Duration(seconds: 120), // Veri göndermek için 120 saniye
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate', // Gzip desteği
      },
      // Android için connection ayarları
      persistentConnection:
          true, // ✅ True yaparak bağlantıyı yeniden kullan (daha hızlı)
      // Tüm status kodlarını kabul et (400-499 hataları da response olarak gelsin)
      validateStatus: (status) => status != null && status < 600,
      // Chrome için özel ayarlar
      followRedirects: false, // Redirect'leri takip etme
      maxRedirects: 0,
      // Android için özel ayarlar
      receiveDataWhenStatusError: true,
    ));

    // Platform-specific interceptors
    if (kIsWeb) {
      // Chrome için özel interceptor (web platformunda)
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          // Chrome için özel header'lar
          options.headers['Cache-Control'] = 'no-cache';
          options.headers['Pragma'] = 'no-cache';
          handler.next(options);
        },
        onError: (error, handler) {
          // Chrome için özel hata yönetimi
          if (kDebugMode) {
            debugPrint('[Chrome] Request failed: ${error.requestOptions.uri}');
            debugPrint('[Chrome] Error type: ${error.type}');
            debugPrint('[Chrome] Error message: ${error.message}');
          }
          handler.next(error);
        },
      ));
    } else {
      // Android için özel interceptor
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          // Android için özel header'lar
          options.headers.remove(
              'Connection'); // Connection header'ını kaldır (Dio otomatik ekler)
          options.headers['Cache-Control'] =
              'no-cache, no-store, must-revalidate';
          options.headers['Pragma'] = 'no-cache';
          options.headers['Expires'] = '0';
          // Her request için timeout'lar - Android için makul timeout'lar
          // NOT: Endpoint'lerde özel timeout varsa onlar kullanılır
          // Kritik endpoint'ler için özel timeout'lar tanımlanmıştır
          // NOT: connectTimeout sadece BaseOptions'ta ayarlanabilir, Options'ta yok
          options.receiveTimeout =
              const Duration(seconds: 300); // Default: 300 saniye
          options.sendTimeout = const Duration(seconds: 120);
          if (kDebugMode) {
            debugPrint('[Android] Request: ${options.method} ${options.uri}');
            debugPrint('[Android] Headers: ${options.headers}');
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Android için özel hata yönetimi
          if (kDebugMode) {
            debugPrint('[Android] Request failed: ${error.requestOptions.uri}');
            debugPrint('[Android] Error type: ${error.type}');
            debugPrint('[Android] Error message: ${error.message}');
            if (error.response != null) {
              debugPrint(
                  '[Android] Response status: ${error.response?.statusCode}');
            }
          }
          handler.next(error);
        },
      ));
    }

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
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
              '📡 API Response: ${response.requestOptions.method} ${response.requestOptions.uri}');
          debugPrint('📡 Status: ${response.statusCode}');
          debugPrint('📡 Data type: ${response.data.runtimeType}');
          debugPrint('📡 Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('🔴 API Error: ${error.message}');
          debugPrint('🔴 Error type: ${error.type}');
          if (error.response != null) {
            debugPrint('🔴 Response status: ${error.response?.statusCode}');
            debugPrint(
                '🔴 Response data type: ${error.response?.data.runtimeType}');
            debugPrint('🔴 Response data: ${error.response?.data}');

            // Backend'den gelen hata mesajını extract et
            if (error.response?.data is Map) {
              final errorData = error.response!.data as Map;
              final detail = errorData['detail'] ?? errorData['message'];
              if (detail != null) {
                debugPrint('🔴 Error detail: $detail');
              }
            }
          } else {
            debugPrint('🔴 No response (connection error)');
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

  // ✅ Hedef bölüm ekleme (Preferred Department)
  Future<Response> addPreferredDepartment(int studentId, int departmentId) async {
    return await _dio.post('/students/$studentId/add-preferred-department/$departmentId');
  }

  // University endpoints
  Future<Response> getUniversities({
    int skip = 0,
    int limit = 1000, // ✅ Tüm üniversiteleri çek - default 1000 kayıt
    String? city, // ✅ Şehir filtresi için
    List<String>? preferredCities, // ✅ Öğrencinin tercih ettiği şehirler
  }) async {
    // Üniversiteler çok sayıda olabilir - pagination kullanın
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };

    // ✅ Şehir filtresi varsa ekle
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    // ✅ Preferred cities filtresi - backend'e query parametresi olarak gönder
    if (preferredCities != null && preferredCities.isNotEmpty) {
      queryParams['preferred_cities'] = preferredCities.join(',');
    }

    return await _dio.get(
      '/universities/',
      queryParameters: queryParams,
      options: Options(
        receiveTimeout: const Duration(
            seconds: 180), // 3 dakika (pagination ile daha hızlı olmalı)
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Future<Response> getDepartments({
    int skip = 0,
    int limit = 30000, // ✅ Default 30000 - tüm bölümler gelsin (21.600+ kayıt için)
    String? normalizedName, // ✅ Normalize edilmiş isme göre filtrele
    String? fieldType, // ✅ Alan türü (TYT, SAY, EA, SÖZ, DİL)
    String? degreeType, // ✅ Derece türü (Associate, Bachelor)
  }) async {
    // Bölümler çok sayıda olabilir - pagination kullanın
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    if (normalizedName != null && normalizedName.isNotEmpty) {
      queryParams['normalized_name'] = normalizedName;
    }
    
    // ✅ KRİTİK: fieldType'a göre degreeType'ı otomatik belirle
    String? effectiveDegreeType = degreeType;
    if (fieldType != null) {
      final fieldTypeUpper = fieldType.toUpperCase();
      if (fieldTypeUpper == 'TYT') {
        // TYT seçildiyse zorla Associate gönder
        effectiveDegreeType = 'Associate';
      } else if (fieldTypeUpper == 'SAY' || 
                  fieldTypeUpper == 'EA' || 
                  fieldTypeUpper == 'SÖZ' || 
                  fieldTypeUpper == 'DİL') {
        // SAY/EA/SÖZ/DİL seçildiyse zorla Bachelor gönder
        effectiveDegreeType = 'Bachelor';
      }
    }
    
    // ✅ fieldType ve degreeType parametrelerini ekle (null kontrolü ile)
    if (fieldType != null && fieldType.isNotEmpty) {
      queryParams['field_type'] = fieldType;
    }
    if (effectiveDegreeType != null && effectiveDegreeType.isNotEmpty) {
      queryParams['degree_type'] = effectiveDegreeType;
    }

    return await _dio.get(
      '/universities/departments/',
      queryParameters: queryParams,
      options: Options(
        receiveTimeout: const Duration(
            seconds: 180), // 3 dakika (pagination ile daha hızlı olmalı)
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  // ✅ Unique (normalize edilmiş) bölüm listesi
  Future<Response> getUniqueDepartments({
    String? universityType, // devlet, vakif
    String? fieldType, // SAY, EA, SÖZ, DİL
  }) async {
    final queryParams = <String, dynamic>{};
    if (universityType != null && universityType.isNotEmpty) {
      queryParams['university_type'] = universityType;
    }
    if (fieldType != null && fieldType.isNotEmpty) {
      queryParams['field_type'] = fieldType;
    }

    return await _dio.get(
      '/universities/departments/unique/',
      queryParameters: queryParams,
      options: Options(
        receiveTimeout:
            const Duration(seconds: 60), // Unique listesi küçük olmalı
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response> getCities() async {
    // ✅ Şehirler listesi küçük ve cache'lenebilir - hızlı olmalı
    return await _dio.get(
      '/universities/cities/',
      options: Options(
        receiveTimeout:
            const Duration(seconds: 30), // 30 saniye (küçük veri seti)
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response> getFieldTypes() async {
    // ✅ Field types listesi küçük ve cache'lenebilir - hızlı olmalı
    return await _dio.get(
      '/universities/field-types/',
      options: Options(
        receiveTimeout:
            const Duration(seconds: 30), // 30 saniye (küçük veri seti)
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response> getDepartmentsFiltered({
    String? fieldType,
    String? city,
    String? universityType,
    String? degreeType, // ✅ ÖNEMLİ: degree_type parametresi eklendi (Associate, Bachelor)
    double? minScore,
    double? maxScore,
    bool? hasScholarship,
    int skip = 0,
    int limit = 2000, // ✅ Default 2000 - tüm bölümler gelsin
  }) async {
    // ✅ KRİTİK: fieldType'a göre degreeType'ı otomatik belirle
    String? effectiveDegreeType = degreeType;
    if (fieldType != null) {
      final fieldTypeUpper = fieldType.toUpperCase();
      if (fieldTypeUpper == 'TYT') {
        // TYT seçildiyse zorla Associate gönder
        effectiveDegreeType = 'Associate';
      } else if (fieldTypeUpper == 'SAY' || 
                  fieldTypeUpper == 'EA' || 
                  fieldTypeUpper == 'SÖZ' || 
                  fieldTypeUpper == 'DİL') {
        // SAY/EA/SÖZ/DİL seçildiyse zorla Bachelor gönder
        effectiveDegreeType = 'Bachelor';
      }
    }
    
    return await _dio.get(
      '/universities/departments/',
      queryParameters: {
        if (fieldType != null) 'field_type': fieldType,
        if (city != null) 'city': city,
        if (universityType != null) 'university_type': universityType,
        if (effectiveDegreeType != null) 'degree_type': effectiveDegreeType, // ✅ Otomatik belirlenen degree_type
        if (minScore != null) 'min_score': minScore,
        if (maxScore != null) 'max_score': maxScore,
        if (hasScholarship != null) 'has_scholarship': hasScholarship,
        'skip': skip,
        'limit': limit,
      },
      options: Options(
        receiveTimeout: const Duration(
            seconds: 120), // 2 dakika (filtreli sorgu - daha hızlı olmalı)
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response> getUniversitiesFiltered({
    String? city,
    String? universityType,
    int skip = 0,
    int limit = 100,
  }) async {
    return await _dio.get(
      '/universities',
      queryParameters: {
        if (city != null) 'city': city,
        if (universityType != null) 'university_type': universityType,
        'skip': skip,
        'limit': limit,
      },
      options: Options(
        receiveTimeout: const Duration(
            seconds: 120), // 2 dakika (filtreli sorgu - daha hızlı olmalı)
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  // Recommendation endpoints
  Future<Response> generateRecommendations(
    int studentId, {
    int limit = 50,
    double? wC,
    double? wS,
    double? wP,
  }) async {
    // Recommendations hesaplama çok uzun sürebilir (veritabanı sorguları, hesaplamalar)
    return await _dio.post(
      '/recommendations/generate/$studentId',
      queryParameters: {
        'limit': limit,
        if (wC != null) 'w_c': wC,
        if (wS != null) 'w_s': wS,
        if (wP != null) 'w_p': wP,
      },
      options: Options(
        receiveTimeout: const Duration(
            seconds: 180), // 3 dakika (filtreli sorgu - yavaş network için)
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Future<Response> getStudentRecommendations(int studentId, {int maxRetries = 3}) async {
    // ✅ Retry mekanizması eklendi - timeout ve connection hataları için
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        return await _dio.get(
          '/recommendations/student/$studentId',
          options: Options(
            receiveTimeout: const Duration(seconds: 180), // ✅ 3 dakika (120s -> 180s)
            sendTimeout: const Duration(seconds: 60),
            validateStatus: (status) =>
                status != null && status < 500, // 4xx hatalarını da handle et
          ),
        );
      } on DioException catch (e) {
        retryCount++;
        // Connection ve timeout hataları için retry yap
        if (e.type == DioExceptionType.unknown ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          if (retryCount < maxRetries) {
            if (kDebugMode) {
              debugPrint(
                  '[Retry] Attempt $retryCount/$maxRetries for getStudentRecommendations');
            }
            // Exponential backoff: 2s, 4s, 8s
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          }
        }
        // Diğer hatalar için retry yapma
        rethrow;
      }
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/recommendations/student/$studentId'),
      type: DioExceptionType.unknown,
      message: 'Max retries ($maxRetries) exceeded',
    );
  }

  Future<Response> clearStudentRecommendations(int studentId) async {
    return await _dio.delete('/recommendations/student/$studentId');
  }

  Future<Response> getRecommendationStats(int studentId) async {
    return await _dio.get('/recommendations/stats/$studentId');
  }

  // Coach Chat
  Future<Response> coachChat({
    required int studentId,
    required String message,
    bool useMl = true,
    int limit = 20,
    double wC = 0.4,
    double wS = 0.4,
    double wP = 0.2,
  }) async {
    // ✅ LLM yanıtları çok uzun sürebilir - timeout artırıldı ve error handling iyileştirildi
    return await _dio.post(
      '/chat/coach',
      data: {
        'student_id': studentId,
        'message': message,
        'use_ml': useMl,
        'limit': limit,
        'w_c': wC,
        'w_s': wS,
        'w_p': wP,
      },
      options: Options(
        receiveTimeout: const Duration(
            minutes: 20), // ✅ CRITICAL FIX: AI işlemleri için 20 dakika (5 dakikadan uzun olmalı)
        sendTimeout: const Duration(minutes: 20),
        validateStatus: (status) =>
            status != null && status < 500, // ✅ 4xx hatalarını da handle et
      ),
    );
  }

  // Auth endpoints
  Future<Response> register({
    String? email,
    String? phone,
    String? name,
  }) async {
    // Register için özel timeout ve connection ayarları
    return await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'phone': phone,
        'name': name,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Connection': 'close', // Her istek için yeni bağlantı
          'Cache-Control': 'no-cache',
        },
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> login({
    String? email,
    String? phone,
  }) async {
    // ✅ Login için daha uzun timeout (backend yavaş olabilir)
    return await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'phone': phone,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 60), // 30s -> 60s
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response> getUserInfo(int userId) async {
    return await _dio.get('/auth/me/$userId');
  }

  // ✅ Kullanıcının öğrenci profilini getir (user_id'den student_id bulmak için)
  Future<Response> getUserStudentProfile(int userId) async {
    return await _dio.get('/auth/student/$userId');
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
      if (isOnboardingCompleted != null)
        'is_onboarding_completed': isOnboardingCompleted,
      if (isInitialSetupCompleted != null)
        'is_initial_setup_completed': isInitialSetupCompleted,
    });
  }

  // Exam Attempt endpoints
  Future<Response> createExamAttempt(Map<String, dynamic> data,
      {int maxRetries = 3}) async {
    // ⚠️ Deneme kaydetme - backend optimize edilmeli (index'ler eklendi)
    // ✅ Retry mekanizması eklendi - connection hataları için
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        return await _dio.post(
          '/exam-attempts/',
          data: data,
          options: Options(
            receiveTimeout: const Duration(
                seconds: 120), // 2 dakika (backend optimize edildi)
            sendTimeout: const Duration(seconds: 60),
          ),
        );
      } on DioException catch (e) {
        retryCount++;
        // Connection hataları için retry yap
        if (e.type == DioExceptionType.unknown ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          if (retryCount < maxRetries) {
            if (kDebugMode) {
              debugPrint(
                  '[Retry] Attempt $retryCount/$maxRetries for createExamAttempt');
            }
            // Exponential backoff: 2s, 4s, 8s
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          }
        }
        // Diğer hatalar için retry yapma
        rethrow;
      }
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/exam-attempts/'),
      type: DioExceptionType.unknown,
      message: 'Max retries ($maxRetries) exceeded',
    );
  }

  Future<Response> getStudentAttempts(int studentId,
      {int maxRetries = 3}) async {
    // ⚠️ Deneme listesi - backend optimize edilmeli (index'ler eklendi)
    // ✅ Retry mekanizması eklendi - connection hataları için
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        return await _dio.get(
          '/exam-attempts/student/$studentId',
          options: Options(
            receiveTimeout: const Duration(
                seconds: 120), // 2 dakika (index'li sorgu - yavaş network için)
            sendTimeout: const Duration(seconds: 60),
          ),
        );
      } on DioException catch (e) {
        retryCount++;
        // Connection hataları için retry yap
        if (e.type == DioExceptionType.unknown ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          if (retryCount < maxRetries) {
            if (kDebugMode) {
              debugPrint(
                  '[Retry] Attempt $retryCount/$maxRetries for getStudentAttempts');
            }
            // Exponential backoff: 2s, 4s, 8s
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          }
        }
        // Diğer hatalar için retry yapma
        rethrow;
      }
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/exam-attempts/student/$studentId'),
      type: DioExceptionType.unknown,
      message: 'Max retries ($maxRetries) exceeded',
    );
  }

  Future<Response> updateExamAttempt(
      int attemptId, Map<String, dynamic> data) async {
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
