import 'package:flutter/material.dart';

class RecommendationModel {
  final int? id;
  final int studentId;
  final int departmentId;
  final double compatibilityScore;
  final double successProbability;
  final double preferenceScore;
  final double finalScore;
  final String recommendationReason;
  final bool isSafeChoice;
  final bool isDreamChoice;
  final bool isRealisticChoice;
  final DateTime? createdAt;
  
  // Department info (populated from API)
  final String? departmentName;
  final String? fieldType;
  final String? universityName;
  final String? city;
  final String? universityType;
  final double? minScore;
  final int? minRank;
  final int? quota;
  final double? tuitionFee;
  final bool? hasScholarship;
  final String? language;

  const RecommendationModel({
    this.id,
    required this.studentId,
    required this.departmentId,
    required this.compatibilityScore,
    required this.successProbability,
    required this.preferenceScore,
    required this.finalScore,
    required this.recommendationReason,
    required this.isSafeChoice,
    required this.isDreamChoice,
    required this.isRealisticChoice,
    this.createdAt,
    this.departmentName,
    this.fieldType,
    this.universityName,
    this.city,
    this.universityType,
    this.minScore,
    this.minRank,
    this.quota,
    this.tuitionFee,
    this.hasScholarship,
    this.language,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id'],
      studentId: json['student_id'],
      departmentId: json['department_id'],
      compatibilityScore: (json['compatibility_score'] ?? 0.0).toDouble(),
      successProbability: (json['success_probability'] ?? 0.0).toDouble(),
      preferenceScore: (json['preference_score'] ?? 0.0).toDouble(),
      finalScore: (json['final_score'] ?? 0.0).toDouble(),
      recommendationReason: json['recommendation_reason'] ?? '',
      isSafeChoice: json['is_safe_choice'] ?? false,
      isDreamChoice: json['is_dream_choice'] ?? false,
      isRealisticChoice: json['is_realistic_choice'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      departmentName: json['department']?['name'],
      fieldType: json['department']?['field_type'],
      universityName: json['department']?['university']?['name'],
      city: json['department']?['university']?['city'],
      universityType: json['department']?['university']?['university_type'],
      minScore: json['department']?['min_score']?.toDouble(),
      minRank: json['department']?['min_rank'],
      quota: json['department']?['quota'],
      tuitionFee: json['department']?['tuition_fee']?.toDouble(),
      hasScholarship: json['department']?['has_scholarship'],
      language: json['department']?['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'department_id': departmentId,
      'compatibility_score': compatibilityScore,
      'success_probability': successProbability,
      'preference_score': preferenceScore,
      'final_score': finalScore,
      'recommendation_reason': recommendationReason,
      'is_safe_choice': isSafeChoice,
      'is_dream_choice': isDreamChoice,
      'is_realistic_choice': isRealisticChoice,
    };
  }

  RecommendationModel copyWith({
    int? id,
    int? studentId,
    int? departmentId,
    double? compatibilityScore,
    double? successProbability,
    double? preferenceScore,
    double? finalScore,
    String? recommendationReason,
    bool? isSafeChoice,
    bool? isDreamChoice,
    bool? isRealisticChoice,
    DateTime? createdAt,
    String? departmentName,
    String? fieldType,
    String? universityName,
    String? city,
    String? universityType,
    double? minScore,
    int? minRank,
    int? quota,
    double? tuitionFee,
    bool? hasScholarship,
    String? language,
  }) {
    return RecommendationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      departmentId: departmentId ?? this.departmentId,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      successProbability: successProbability ?? this.successProbability,
      preferenceScore: preferenceScore ?? this.preferenceScore,
      finalScore: finalScore ?? this.finalScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      isSafeChoice: isSafeChoice ?? this.isSafeChoice,
      isDreamChoice: isDreamChoice ?? this.isDreamChoice,
      isRealisticChoice: isRealisticChoice ?? this.isRealisticChoice,
      createdAt: createdAt ?? this.createdAt,
      departmentName: departmentName ?? this.departmentName,
      fieldType: fieldType ?? this.fieldType,
      universityName: universityName ?? this.universityName,
      city: city ?? this.city,
      universityType: universityType ?? this.universityType,
      minScore: minScore ?? this.minScore,
      minRank: minRank ?? this.minRank,
      quota: quota ?? this.quota,
      tuitionFee: tuitionFee ?? this.tuitionFee,
      hasScholarship: hasScholarship ?? this.hasScholarship,
      language: language ?? this.language,
    );
  }

  String get recommendationType {
    if (isSafeChoice) return 'Güvenli Tercih';
    if (isDreamChoice) return 'Hayal Tercihi';
    if (isRealisticChoice) return 'Gerçekçi Tercih';
    return 'Genel';
  }

  Color get recommendationTypeColor {
    if (isSafeChoice) return Colors.green;
    if (isDreamChoice) return Colors.orange;
    if (isRealisticChoice) return Colors.blue;
    return Colors.grey;
  }
}
