import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/api_service.dart';
import '../models/recommendation_model.dart';

part 'recommendation_api_provider.g.dart';

// Data class for stats
class RecommendationStats {
  final int totalRecommendations;
  final int safeChoices;
  final int realisticChoices;
  final int dreamChoices;
  final double averageScore;
  final double averageCompatibility;
  final double averageSuccessProbability;
  final double averagePreferenceScore;

  RecommendationStats({
    required this.totalRecommendations,
    required this.safeChoices,
    required this.realisticChoices,
    required this.dreamChoices,
    required this.averageScore,
    required this.averageCompatibility,
    required this.averageSuccessProbability,
    required this.averagePreferenceScore,
  });

  factory RecommendationStats.fromJson(Map<String, dynamic> json) {
    return RecommendationStats(
      totalRecommendations: json['total_recommendations'] ?? 0,
      safeChoices: json['safe_choices'] ?? 0,
      realisticChoices: json['realistic_choices'] ?? 0,
      dreamChoices: json['dream_choices'] ?? 0,
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
      averageCompatibility: (json['average_compatibility'] ?? 0.0).toDouble(),
      averageSuccessProbability: (json['average_success_probability'] ?? 0.0).toDouble(),
      averagePreferenceScore: (json['average_preference_score'] ?? 0.0).toDouble(),
    );
  }
}

// API Providers using the new Riverpod Generator syntax

@riverpod
Future<List<RecommendationModel>> recommendationList(Ref ref, int studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getStudentRecommendations(studentId);
  return (response.data as List)
      .map((rec) => RecommendationModel.fromJson(rec))
      .toList();
}

@riverpod
Future<RecommendationStats> recommendationStats(Ref ref, int studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getRecommendationStats(studentId);
  return RecommendationStats.fromJson(response.data);
}

@Riverpod(keepAlive: true)
class RecommendationGeneration extends _$RecommendationGeneration {
  @override
  AsyncValue<List<RecommendationModel>?> build() => const AsyncData(null);

  Future<void> generateRecommendations(int studentId, {int limit = 50}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.generateRecommendations(studentId, limit: limit);
      return (response.data as List)
          .map((rec) => RecommendationModel.fromJson(rec))
          .toList();
    });
  }
}
