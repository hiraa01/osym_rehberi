import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../models/recommendation_model.dart';

// ✅ Build runner GEREKTIRMEZ - Basit provider pattern

// Recommendation List Provider
final recommendationListProvider = FutureProvider.autoDispose.family<List<RecommendationModel>, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getStudentRecommendations(studentId);
  return (response.data as List)
      .map((rec) => RecommendationModel.fromJson(rec))
      .toList();
});

// Generate Recommendations Provider
final generateRecommendationsProvider = FutureProvider.autoDispose.family<List<RecommendationModel>, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.generateRecommendations(studentId);
  return (response.data as List)
      .map((rec) => RecommendationModel.fromJson(rec))
      .toList();
});

// Recommendation Stats Provider
final recommendationStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getRecommendationStats(studentId);
  return response.data as Map<String, dynamic>;
});
