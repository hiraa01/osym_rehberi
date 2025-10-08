class UniversityModel {
  final int? id;
  final String name;
  final String city;
  final String universityType;
  final String? website;
  final String? description;
  final bool isActive;

  const UniversityModel({
    this.id,
    required this.name,
    required this.city,
    required this.universityType,
    this.website,
    this.description,
    this.isActive = true,
  });

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      universityType: json['university_type'],
      website: json['website'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'university_type': universityType,
      'website': website,
      'description': description,
      'is_active': isActive,
    };
  }

  UniversityModel copyWith({
    int? id,
    String? name,
    String? city,
    String? universityType,
    String? website,
    String? description,
    bool? isActive,
  }) {
    return UniversityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      universityType: universityType ?? this.universityType,
      website: website ?? this.website,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
