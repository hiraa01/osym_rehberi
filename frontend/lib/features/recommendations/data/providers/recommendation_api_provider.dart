import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../models/recommendation_model.dart';
import '../../presentation/providers/recommendation_settings_provider.dart';

// ✅ Build runner GEREKTIRMEZ - Basit provider pattern

// Recommendation List Provider
// ✅ FutureProvider.family: Aynı studentId için cache'lenir, tekrar çağrı yapılmaz
final recommendationListProvider =
    FutureProvider.family<List<RecommendationModel>, int>(
        (ref, studentId) async {
  debugPrint('🟢 recommendationListProvider called for studentId: $studentId');
  final apiService = ref.read(apiServiceProvider);

  try {
    debugPrint('🟢 Calling getStudentRecommendations API for studentId: $studentId');
    final response = await apiService.getStudentRecommendations(studentId);
    debugPrint('🟢 getStudentRecommendations API response received');

    // 🔍 DEBUG: Raw API Response
    debugPrint('🔍 DEBUG: Raw API Response Type: ${response.data.runtimeType}');
    debugPrint('🔍 DEBUG: Raw API Response Data: ${response.data}');
    debugPrint('🔍 DEBUG: Response Status Code: ${response.statusCode}');

    // ✅ Status code kontrolü
    if (response.statusCode != 200) {
      debugPrint('🔴 Recommendations API error: Status ${response.statusCode}');
      debugPrint('🔴 Response data: ${response.data}');
      // 404 ise öneri yok demektir, boş liste döndür
      if (response.statusCode == 404) {
        debugPrint('⚠️ No recommendations found (404)');
        return [];
      }
      // Diğer hatalar için exception fırlat
      throw Exception('Öneriler yüklenemedi: Status ${response.statusCode}');
    }

    // ✅ Response data null kontrolü
    if (response.data == null) {
      debugPrint('🔴 Recommendations API: response.data is null');
      throw Exception('Öneriler yüklenemedi: Response data null');
    }

    debugPrint(
        '🟢 Recommendations response type: ${response.data.runtimeType}');
    debugPrint('🟢 Recommendations response: ${response.data}');

    // ✅ GÜVENLİ PARSING: Backend {"recommendations": [...], "total": 0} veya direkt List dönebilir
    final data = response.data;
    List<dynamic> list = [];

    try {
      if (data is Map<String, dynamic>) {
        // Eğer Map geldiyse 'recommendations' anahtarını al
        debugPrint('🔍 DEBUG: Response is Map, extracting recommendations key');
        final recommendationsData = data['recommendations'];
        if (recommendationsData != null && recommendationsData is List) {
          list = recommendationsData;
          debugPrint('✅ Extracted ${list.length} recommendations from Map');
        } else {
          debugPrint('⚠️ Recommendations key not found or not a List, returning empty list');
          return [];
        }
      } else if (data is List) {
        // Eğer direkt Liste geldiyse onu kullan
        debugPrint('🔍 DEBUG: Response is List, using directly');
        list = data;
        debugPrint('✅ Using List directly, length: ${list.length}');
      } else {
        debugPrint('🔴 Unknown response format: ${data.runtimeType}');
        throw Exception('Öneriler yüklenemedi: Beklenmeyen response formatı (${data.runtimeType})');
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 Recommendation Parsing Error: $e');
      debugPrint('🔴 Stack Trace: $stackTrace');
      rethrow;
    }

    // ✅ Boş liste kontrolü
    if (list.isEmpty) {
      debugPrint('⚠️ Recommendations list is empty');
      return [];
    }
    
    debugPrint('🟢 Found ${list.length} recommendations');
    final recommendationsList = list;

    // ✅ Her recommendation item'ını parse et
    final parsedRecommendations = <RecommendationModel>[];
    for (int i = 0; i < recommendationsList.length; i++) {
      final rec = recommendationsList[i];
      if (rec is Map<String, dynamic>) {
        try {
          debugPrint(
              '🟢 Parsing recommendation $i/${recommendationsList.length}');
          debugPrint('🟢 Keys: ${rec.keys.toList()}');
          debugPrint(
              '🟢 Sample data: student_id=${rec['student_id']}, department_id=${rec['department_id']}');

          // ✅ Department yapısını kontrol et
          if (rec.containsKey('department')) {
            debugPrint('🟢 Has department key: ${rec['department'] is Map}');
            if (rec['department'] is Map) {
              final dept = rec['department'] as Map<String, dynamic>;
              debugPrint('🟢 Department keys: ${dept.keys.toList()}');
            }
          }

          final model = RecommendationModel.fromJson(rec);
          parsedRecommendations.add(model);
          debugPrint(
              '✅ Successfully parsed recommendation $i: ${model.departmentName ?? "N/A"} - ${model.universityName ?? "N/A"}');
        } catch (e, stackTrace) {
          debugPrint('🔴 Error parsing recommendation $i: $e');
          debugPrint('🔴 Recommendation data keys: ${rec.keys.toList()}');
          debugPrint('🔴 Full recommendation data: $rec');
          debugPrint('🔴 Stack trace: $stackTrace');
          // Hata olsa bile devam et, diğer önerileri parse etmeye çalış
        }
      } else {
        debugPrint(
            '🔴 Invalid recommendation item $i type: ${rec.runtimeType}, value: $rec');
      }
    }

    debugPrint(
        '🟢 Successfully parsed ${parsedRecommendations.length} out of ${recommendationsList.length} recommendations');
    if (parsedRecommendations.isEmpty && recommendationsList.isNotEmpty) {
      debugPrint('🔴 CRITICAL: No recommendations were successfully parsed!');
      debugPrint(
          '🔴 First recommendation sample: ${recommendationsList.first}');
    }
    if (parsedRecommendations.isEmpty) {
      debugPrint('⚠️ WARNING: Parsed list is EMPTY');
      debugPrint('⚠️ WARNING: Original list length: ${recommendationsList.length}');
    }
    debugPrint('🔍 DEBUG: Returning ${parsedRecommendations.length} parsed recommendations');
    return parsedRecommendations;
  } on DioException catch (e, stackTrace) {
    debugPrint('🔴 DioException in recommendationListProvider: $e');
    debugPrint('🔴 Error type: ${e.type}');
    debugPrint('🔴 Stack trace: $stackTrace');
    
    // Timeout hataları için özel mesaj
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      debugPrint('⏱️ Timeout error - recommendations API took too long');
      throw Exception('Öneriler yüklenirken zaman aşımı oluştu. Lütfen tekrar deneyin.');
    }
    
    // Connection hataları için özel mesaj
    if (e.type == DioExceptionType.connectionError) {
      debugPrint('🔌 Connection error - cannot reach server');
      throw Exception('Sunucuya bağlanılamadı. WiFi bağlantınızı kontrol edin.');
    }
    
    // Diğer hatalar için genel mesaj
    rethrow;
  } catch (e, stackTrace) {
    debugPrint('🔴 Error in recommendationListProvider: $e');
    debugPrint('🔴 Stack trace: $stackTrace');
    // Genel hatalar için exception fırlat (boş liste döndürme)
    throw Exception('Öneriler yüklenirken hata oluştu: ${e.toString()}');
  }
});

// Generate Recommendations Provider
final generateRecommendationsProvider =
    FutureProvider.family<List<RecommendationModel>, int>(
        (ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final settings = ref.read(recommendationSettingsProvider);

  try {
    final response = await apiService.generateRecommendations(
      studentId,
      wC: settings.wC,
      wS: settings.wS,
      wP: settings.wP,
    );

    // ✅ Status code kontrolü
    if (response.statusCode != 200) {
      debugPrint(
          '🔴 Generate Recommendations API error: Status ${response.statusCode}');
      debugPrint('🔴 Response data: ${response.data}');
      return [];
    }

    // ✅ Response data null kontrolü
    if (response.data == null) {
      debugPrint('🔴 Generate Recommendations API: response.data is null');
      return [];
    }

    debugPrint(
        '🟢 Generate Recommendations response type: ${response.data.runtimeType}');

    // ✅ Backend formatı: List[RecommendationResponse] (direkt liste döner)
    if (response.data is List) {
      debugPrint(
          '🟢 Response is List, length: ${(response.data as List).length}');
      return (response.data as List)
          .map((rec) =>
              RecommendationModel.fromJson(rec as Map<String, dynamic>))
          .toList();
    }

    // ✅ Fallback: Eğer Map gelirse {"recommendations": [...]}
    if (response.data is Map) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap['recommendations'] != null) {
        final recommendationsList = dataMap['recommendations'] as List;
        debugPrint(
            '🟢 Found ${recommendationsList.length} recommendations in Map');
        return recommendationsList
            .map((rec) =>
                RecommendationModel.fromJson(rec as Map<String, dynamic>))
            .toList();
      }
    }

    debugPrint('🔴 Unknown response format: ${response.data.runtimeType}');
    return [];
  } catch (e, stackTrace) {
    debugPrint('🔴 Error in generateRecommendationsProvider: $e');
    debugPrint('🔴 Stack trace: $stackTrace');
    return [];
  }
});

// Recommendation Stats Provider
final recommendationStatsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getRecommendationStats(studentId);
  return response.data as Map<String, dynamic>;
});
