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
  final String? universityType; // ✅ Backend'den gelen university_type (state, foundation, private)
  final String? degreeType; // ✅ Backend'den gelen degree_type (Associate, Bachelor)

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
    this.universityType,
    this.degreeType,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    // ✅ Güvenli null kontrolleri ile parse et
    return DepartmentModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '', // ✅ 'name' alanını kullan (original_name değil)
      fieldType: json['field_type'] as String? ?? 'SAY',
      universityId: json['university_id'] as int? ?? 0,
      universityName: json['university_name'] as String?,
      city: json['city'] as String?,
      // ✅ min_score null kontrolü: Eğer null ise null döndür, değilse double'a çevir
      minScore: json['min_score'] != null 
          ? (json['min_score'] is num 
              ? (json['min_score'] as num).toDouble() 
              : double.tryParse(json['min_score'].toString()))
          : null,
      // ✅ min_rank null kontrolü
      minRank: json['min_rank'] != null 
          ? (json['min_rank'] is int 
              ? json['min_rank'] as int 
              : int.tryParse(json['min_rank'].toString()))
          : null,
      // ✅ quota null kontrolü
      quota: json['quota'] != null 
          ? (json['quota'] is int 
              ? json['quota'] as int 
              : int.tryParse(json['quota'].toString()))
          : null,
      // ✅ tuition_fee null kontrolü
      tuitionFee: json['tuition_fee'] != null 
          ? (json['tuition_fee'] is num 
              ? (json['tuition_fee'] as num).toDouble() 
              : double.tryParse(json['tuition_fee'].toString()))
          : null,
      hasScholarship: json['has_scholarship'] as bool? ?? false,
      language: json['language'] as String?,
      description: json['description'] as String?,
      // ✅ university_type: Backend'den gelen university objesi içinden veya direkt
      universityType: () {
        if (json['university'] != null) {
          final university = json['university'] as Map<String, dynamic>?;
          return university?['university_type'] as String?;
        }
        return json['university_type'] as String?;
      }(),
      // ✅ degree_type: Backend'den gelen degree_type
      degreeType: json['degree_type'] as String?,
    );
  }
  
  // ✅ university_type için Türkçe label getter
  String get universityTypeLabel {
    switch (universityType?.toLowerCase()) {
      case 'state':
        return 'Devlet';
      case 'foundation':
        return 'Vakıf';
      case 'private':
        return 'Özel';
      default:
        return 'Belirtilmemiş';
    }
  }
  
  // ✅ degree_type için Türkçe label getter
  String get degreeTypeLabel {
    switch (degreeType?.toLowerCase()) {
      case 'associate':
        return 'Önlisans';
      case 'bachelor':
        return 'Lisans';
      default:
        return 'Belirtilmemiş';
    }
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
      'university_type': universityType,
      'degree_type': degreeType,
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
    String? universityType,
    String? degreeType,
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
      universityType: universityType ?? this.universityType,
      degreeType: degreeType ?? this.degreeType,
    );
  }
}
