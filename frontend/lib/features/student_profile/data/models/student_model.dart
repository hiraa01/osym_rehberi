class StudentModel {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String classLevel;
  final String examType;
  final String fieldType;
  
  // TYT Scores
  final double tytTurkishNet;
  final double tytMathNet;
  final double tytSocialNet;
  final double tytScienceNet;
  
  // AYT Scores
  final double aytMathNet;
  final double aytPhysicsNet;
  final double aytChemistryNet;
  final double aytBiologyNet;
  final double aytLiteratureNet;
  final double aytHistory1Net;
  final double aytGeography1Net;
  final double aytPhilosophyNet;
  final double aytHistory2Net;
  final double aytGeography2Net;
  final double aytForeignLanguageNet;
  
  // Calculated Scores
  final double? tytTotalScore;
  final double? aytTotalScore;
  final double? totalScore;
  final int? rank;
  final double? percentile;
  
  // Preferences
  final List<String>? preferredCities;
  final List<String>? preferredUniversityTypes;
  final String? budgetPreference;
  final bool scholarshipPreference;
  final List<String>? interestAreas;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentModel({
    this.id,
    required this.name,
    this.email,
    this.phone,
    required this.classLevel,
    required this.examType,
    required this.fieldType,
    this.tytTurkishNet = 0.0,
    this.tytMathNet = 0.0,
    this.tytSocialNet = 0.0,
    this.tytScienceNet = 0.0,
    this.aytMathNet = 0.0,
    this.aytPhysicsNet = 0.0,
    this.aytChemistryNet = 0.0,
    this.aytBiologyNet = 0.0,
    this.aytLiteratureNet = 0.0,
    this.aytHistory1Net = 0.0,
    this.aytGeography1Net = 0.0,
    this.aytPhilosophyNet = 0.0,
    this.aytHistory2Net = 0.0,
    this.aytGeography2Net = 0.0,
    this.aytForeignLanguageNet = 0.0,
    this.tytTotalScore,
    this.aytTotalScore,
    this.totalScore,
    this.rank,
    this.percentile,
    this.preferredCities,
    this.preferredUniversityTypes,
    this.budgetPreference,
    this.scholarshipPreference = false,
    this.interestAreas,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      classLevel: json['class_level'],
      examType: json['exam_type'],
      fieldType: json['field_type'],
      tytTurkishNet: (json['tyt_turkish_net'] ?? 0.0).toDouble(),
      tytMathNet: (json['tyt_math_net'] ?? 0.0).toDouble(),
      tytSocialNet: (json['tyt_social_net'] ?? 0.0).toDouble(),
      tytScienceNet: (json['tyt_science_net'] ?? 0.0).toDouble(),
      aytMathNet: (json['ayt_math_net'] ?? 0.0).toDouble(),
      aytPhysicsNet: (json['ayt_physics_net'] ?? 0.0).toDouble(),
      aytChemistryNet: (json['ayt_chemistry_net'] ?? 0.0).toDouble(),
      aytBiologyNet: (json['ayt_biology_net'] ?? 0.0).toDouble(),
      aytLiteratureNet: (json['ayt_literature_net'] ?? 0.0).toDouble(),
      aytHistory1Net: (json['ayt_history1_net'] ?? 0.0).toDouble(),
      aytGeography1Net: (json['ayt_geography1_net'] ?? 0.0).toDouble(),
      aytPhilosophyNet: (json['ayt_philosophy_net'] ?? 0.0).toDouble(),
      aytHistory2Net: (json['ayt_history2_net'] ?? 0.0).toDouble(),
      aytGeography2Net: (json['ayt_geography2_net'] ?? 0.0).toDouble(),
      aytForeignLanguageNet: (json['ayt_foreign_language_net'] ?? 0.0).toDouble(),
      tytTotalScore: json['tyt_total_score']?.toDouble(),
      aytTotalScore: json['ayt_total_score']?.toDouble(),
      totalScore: json['total_score']?.toDouble(),
      rank: json['rank'],
      percentile: json['percentile']?.toDouble(),
      preferredCities: json['preferred_cities'] != null 
          ? List<String>.from(json['preferred_cities']) 
          : null,
      preferredUniversityTypes: json['preferred_university_types'] != null 
          ? List<String>.from(json['preferred_university_types']) 
          : null,
      budgetPreference: json['budget_preference'],
      scholarshipPreference: json['scholarship_preference'] ?? false,
      interestAreas: json['interest_areas'] != null 
          ? List<String>.from(json['interest_areas']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'class_level': classLevel,
      'exam_type': examType,
      'field_type': fieldType,
      'tyt_turkish_net': tytTurkishNet,
      'tyt_math_net': tytMathNet,
      'tyt_social_net': tytSocialNet,
      'tyt_science_net': tytScienceNet,
      'ayt_math_net': aytMathNet,
      'ayt_physics_net': aytPhysicsNet,
      'ayt_chemistry_net': aytChemistryNet,
      'ayt_biology_net': aytBiologyNet,
      'ayt_literature_net': aytLiteratureNet,
      'ayt_history1_net': aytHistory1Net,
      'ayt_geography1_net': aytGeography1Net,
      'ayt_philosophy_net': aytPhilosophyNet,
      'ayt_history2_net': aytHistory2Net,
      'ayt_geography2_net': aytGeography2Net,
      'ayt_foreign_language_net': aytForeignLanguageNet,
      'preferred_cities': preferredCities,
      'preferred_university_types': preferredUniversityTypes,
      'budget_preference': budgetPreference,
      'scholarship_preference': scholarshipPreference,
      'interest_areas': interestAreas,
    };
  }

  StudentModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? classLevel,
    String? examType,
    String? fieldType,
    double? tytTurkishNet,
    double? tytMathNet,
    double? tytSocialNet,
    double? tytScienceNet,
    double? aytMathNet,
    double? aytPhysicsNet,
    double? aytChemistryNet,
    double? aytBiologyNet,
    double? aytLiteratureNet,
    double? aytHistory1Net,
    double? aytGeography1Net,
    double? aytPhilosophyNet,
    double? aytHistory2Net,
    double? aytGeography2Net,
    double? aytForeignLanguageNet,
    double? tytTotalScore,
    double? aytTotalScore,
    double? totalScore,
    int? rank,
    double? percentile,
    List<String>? preferredCities,
    List<String>? preferredUniversityTypes,
    String? budgetPreference,
    bool? scholarshipPreference,
    List<String>? interestAreas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      classLevel: classLevel ?? this.classLevel,
      examType: examType ?? this.examType,
      fieldType: fieldType ?? this.fieldType,
      tytTurkishNet: tytTurkishNet ?? this.tytTurkishNet,
      tytMathNet: tytMathNet ?? this.tytMathNet,
      tytSocialNet: tytSocialNet ?? this.tytSocialNet,
      tytScienceNet: tytScienceNet ?? this.tytScienceNet,
      aytMathNet: aytMathNet ?? this.aytMathNet,
      aytPhysicsNet: aytPhysicsNet ?? this.aytPhysicsNet,
      aytChemistryNet: aytChemistryNet ?? this.aytChemistryNet,
      aytBiologyNet: aytBiologyNet ?? this.aytBiologyNet,
      aytLiteratureNet: aytLiteratureNet ?? this.aytLiteratureNet,
      aytHistory1Net: aytHistory1Net ?? this.aytHistory1Net,
      aytGeography1Net: aytGeography1Net ?? this.aytGeography1Net,
      aytPhilosophyNet: aytPhilosophyNet ?? this.aytPhilosophyNet,
      aytHistory2Net: aytHistory2Net ?? this.aytHistory2Net,
      aytGeography2Net: aytGeography2Net ?? this.aytGeography2Net,
      aytForeignLanguageNet: aytForeignLanguageNet ?? this.aytForeignLanguageNet,
      tytTotalScore: tytTotalScore ?? this.tytTotalScore,
      aytTotalScore: aytTotalScore ?? this.aytTotalScore,
      totalScore: totalScore ?? this.totalScore,
      rank: rank ?? this.rank,
      percentile: percentile ?? this.percentile,
      preferredCities: preferredCities ?? this.preferredCities,
      preferredUniversityTypes: preferredUniversityTypes ?? this.preferredUniversityTypes,
      budgetPreference: budgetPreference ?? this.budgetPreference,
      scholarshipPreference: scholarshipPreference ?? this.scholarshipPreference,
      interestAreas: interestAreas ?? this.interestAreas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
