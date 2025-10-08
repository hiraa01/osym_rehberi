class DepartmentModel {
  final int? id;
  final String name;
  final String fieldType;
  final int universityId;
  final String? universityName;
  final String? city;
  final double? minScore;
  final int? minRank;
  final int? quota;
  final double? tuitionFee;
  final bool hasScholarship;
  final String? language;
  final String? description;

  const DepartmentModel({
    this.id,
    required this.name,
    required this.fieldType,
    required this.universityId,
    this.universityName,
    this.city,
    this.minScore,
    this.minRank,
    this.quota,
    this.tuitionFee,
    this.hasScholarship = false,
    this.language,
    this.description,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'],
      name: json['name'],
      fieldType: json['field_type'],
      universityId: json['university_id'],
      universityName: json['university_name'],
      city: json['city'],
      minScore: json['min_score']?.toDouble(),
      minRank: json['min_rank'],
      quota: json['quota'],
      tuitionFee: json['tuition_fee']?.toDouble(),
      hasScholarship: json['has_scholarship'] ?? false,
      language: json['language'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'field_type': fieldType,
      'university_id': universityId,
      'min_score': minScore,
      'min_rank': minRank,
      'quota': quota,
      'tuition_fee': tuitionFee,
      'has_scholarship': hasScholarship,
      'language': language,
      'description': description,
    };
  }

  DepartmentModel copyWith({
    int? id,
    String? name,
    String? fieldType,
    int? universityId,
    String? universityName,
    String? city,
    double? minScore,
    int? minRank,
    int? quota,
    double? tuitionFee,
    bool? hasScholarship,
    String? language,
    String? description,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fieldType: fieldType ?? this.fieldType,
      universityId: universityId ?? this.universityId,
      universityName: universityName ?? this.universityName,
      city: city ?? this.city,
      minScore: minScore ?? this.minScore,
      minRank: minRank ?? this.minRank,
      quota: quota ?? this.quota,
      tuitionFee: tuitionFee ?? this.tuitionFee,
      hasScholarship: hasScholarship ?? this.hasScholarship,
      language: language ?? this.language,
      description: description ?? this.description,
    );
  }
}
