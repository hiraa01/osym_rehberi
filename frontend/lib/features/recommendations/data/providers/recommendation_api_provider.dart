import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../models/recommendation_model.dart';
import '../../presentation/providers/recommendation_settings_provider.dart';

// ✅ Build runner GEREKTIRMEZ - Basit provider pattern

// Recommendation List Provider
final recommendationListProvider = FutureProvider.family<List<RecommendationModel>, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getStudentRecommendations(studentId);
  
  // ✅ Backend formatı: {"recommendations": [...]}
  if (response.data is Map && response.data['recommendations'] != null) {
    return (response.data['recommendations'] as List)
        .map((rec) => RecommendationModel.fromJson(rec))
        .toList();
  }
  
  // ✅ Fallback: Eğer direkt liste gelirse (eski format)
  if (response.data is List) {
    return (response.data as List)
        .map((rec) => RecommendationModel.fromJson(rec))
        .toList();
  }
  
  return [];
});

// Generate Recommendations Provider
final generateRecommendationsProvider = FutureProvider.family<List<RecommendationModel>, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final settings = ref.read(recommendationSettingsProvider);
  final response = await apiService.generateRecommendations(
    studentId,
    wC: settings.wC,
    wS: settings.wS,
    wP: settings.wP,
  );
  return (response.data as List)
      .map((rec) => RecommendationModel.fromJson(rec))
      .toList();
});

// Recommendation Stats Provider
final recommendationStatsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getRecommendationStats(studentId);
  return response.data as Map<String, dynamic>;
});
