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
    // 🔍 DEBUG: Parsing recommendation
    debugPrint('🔍 DEBUG: Parsing RecommendationModel fromJson');
    debugPrint('🔍 DEBUG: JSON keys: ${json.keys.toList()}');
    debugPrint('🔍 DEBUG: JSON data: $json');
    
    // ✅ Backend'den gelen veri yapısını esnek şekilde handle et
    // Format 1: {department: {name: ..., university: {...}}}
    // Format 2: {department_name: ..., university_name: ..., ...}
    // Format 3: Nested structure

    final department = json['department'] as Map<String, dynamic>?;
    final university = department?['university'] as Map<String, dynamic>?;
    
    debugPrint('🔍 DEBUG: Department is Map: ${department != null}');
    debugPrint('🔍 DEBUG: University is Map: ${university != null}');
    if (department != null) {
      debugPrint('🔍 DEBUG: Department keys: ${department.keys.toList()}');
    }
    if (university != null) {
      debugPrint('🔍 DEBUG: University keys: ${university.keys.toList()}');
    }

    // ✅ Eğer nested yapı yoksa, direkt alanları kontrol et
    final departmentName = department?['name'] ??
        department?['program_name'] ??
        json['department_name'] as String?;

    final universityName =
        university?['name'] ?? json['university_name'] as String?;

    final city = university?['city'] ?? json['city'] as String?;

    final fieldType =
        department?['field_type'] ?? json['field_type'] as String?;

    final universityType =
        university?['university_type'] ?? json['university_type'] as String?;

    final minScore =
        department?['min_score']?.toDouble() ?? json['min_score']?.toDouble();

    final minRank = department?['min_rank'] ?? json['min_rank'] as int?;

    final quota = department?['quota'] ?? json['quota'] as int?;

    final tuitionFee = department?['tuition_fee']?.toDouble() ??
        json['tuition_fee']?.toDouble();

    final hasScholarship =
        department?['has_scholarship'] ?? json['has_scholarship'] as bool?;

    final language = department?['language'] ?? json['language'] as String?;

    // 🔍 DEBUG: Extracted values
    debugPrint('🔍 DEBUG: Extracted - departmentName: $departmentName, universityName: $universityName');
    debugPrint('🔍 DEBUG: Extracted - city: $city, fieldType: $fieldType');
    debugPrint('🔍 DEBUG: Extracted - minScore: $minScore, minRank: $minRank');
    debugPrint('🔍 DEBUG: Extracted - compatibilityScore: ${json['compatibility_score']}, finalScore: ${json['final_score']}');

    return RecommendationModel(
      id: json['id'] as int?,
      studentId: json['student_id'] as int? ?? 0,
      departmentId: json['department_id'] as int? ?? 0,
      compatibilityScore:
          (json['compatibility_score'] ?? json['compatibilityScore'] ?? 0.0)
              .toDouble(),
      successProbability:
          (json['success_probability'] ?? json['successProbability'] ?? 0.0)
              .toDouble(),
      preferenceScore:
          (json['preference_score'] ?? json['preferenceScore'] ?? 0.0)
              .toDouble(),
      finalScore: (json['final_score'] ?? json['finalScore'] ?? 0.0).toDouble(),
      recommendationReason:
          json['recommendation_reason'] ?? json['recommendationReason'] ?? '',
      isSafeChoice: json['is_safe_choice'] ?? json['isSafeChoice'] ?? false,
      isDreamChoice: json['is_dream_choice'] ?? json['isDreamChoice'] ?? false,
      isRealisticChoice:
          json['is_realistic_choice'] ?? json['isRealisticChoice'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null),
      departmentName: departmentName,
      fieldType: fieldType,
      universityName: universityName,
      city: city,
      universityType: universityType,
      minScore: minScore,
      minRank: minRank,
      quota: quota,
      tuitionFee: tuitionFee,
      hasScholarship: hasScholarship,
      language: language,
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
