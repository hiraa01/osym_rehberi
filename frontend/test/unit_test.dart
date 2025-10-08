import 'package:flutter_test/flutter_test.dart';
import 'package:osym_rehberi/features/student_profile/data/models/student_model.dart';

void main() {
  group('StudentModel Tests', () {
    test('StudentModel fromJson creates correct object', () {
      final json = {
        'id': 1,
        'name': 'Test Student',
        'email': 'test@example.com',
        'phone': '05551234567',
        'class_level': '12',
        'exam_type': 'TYT+AYT',
        'field_type': 'SAY',
        'tyt_turkish_net': 30.0,
        'tyt_math_net': 25.0,
        'tyt_social_net': 15.0,
        'tyt_science_net': 20.0,
        'ayt_math_net': 20.0,
        'ayt_physics_net': 15.0,
        'ayt_chemistry_net': 10.0,
        'ayt_biology_net': 12.0,
        'tyt_total_score': 90.0,
        'ayt_total_score': 57.0,
        'total_score': 147.0,
        'rank': 1000,
        'percentile': 85.5,
        'preferred_cities': ['İstanbul', 'Ankara'],
        'preferred_university_types': ['Devlet'],
        'budget_preference': 'medium',
        'scholarship_preference': true,
        'interest_areas': ['Mühendislik', 'Teknoloji'],
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final student = StudentModel.fromJson(json);

      expect(student.id, 1);
      expect(student.name, 'Test Student');
      expect(student.email, 'test@example.com');
      expect(student.phone, '05551234567');
      expect(student.classLevel, '12');
      expect(student.examType, 'TYT+AYT');
      expect(student.fieldType, 'SAY');
      expect(student.tytTurkishNet, 30.0);
      expect(student.tytMathNet, 25.0);
      expect(student.tytSocialNet, 15.0);
      expect(student.tytScienceNet, 20.0);
      expect(student.aytMathNet, 20.0);
      expect(student.aytPhysicsNet, 15.0);
      expect(student.aytChemistryNet, 10.0);
      expect(student.aytBiologyNet, 12.0);
      expect(student.tytTotalScore, 90.0);
      expect(student.aytTotalScore, 57.0);
      expect(student.totalScore, 147.0);
      expect(student.rank, 1000);
      expect(student.percentile, 85.5);
      expect(student.preferredCities, ['İstanbul', 'Ankara']);
      expect(student.preferredUniversityTypes, ['Devlet']);
      expect(student.budgetPreference, 'medium');
      expect(student.scholarshipPreference, true);
      expect(student.interestAreas, ['Mühendislik', 'Teknoloji']);
    });

    test('StudentModel toJson creates correct JSON', () {
      const student = StudentModel(
        id: 1,
        name: 'Test Student',
        email: 'test@example.com',
        phone: '05551234567',
        classLevel: '12',
        examType: 'TYT+AYT',
        fieldType: 'SAY',
        tytTurkishNet: 30.0,
        tytMathNet: 25.0,
        tytSocialNet: 15.0,
        tytScienceNet: 20.0,
        aytMathNet: 20.0,
        aytPhysicsNet: 15.0,
        aytChemistryNet: 10.0,
        aytBiologyNet: 12.0,
        preferredCities: ['İstanbul', 'Ankara'],
        preferredUniversityTypes: ['Devlet'],
        budgetPreference: 'medium',
        scholarshipPreference: true,
        interestAreas: ['Mühendislik', 'Teknoloji'],
      );

      final json = student.toJson();

      expect(json['name'], 'Test Student');
      expect(json['email'], 'test@example.com');
      expect(json['phone'], '05551234567');
      expect(json['class_level'], '12');
      expect(json['exam_type'], 'TYT+AYT');
      expect(json['field_type'], 'SAY');
      expect(json['tyt_turkish_net'], 30.0);
      expect(json['tyt_math_net'], 25.0);
      expect(json['tyt_social_net'], 15.0);
      expect(json['tyt_science_net'], 20.0);
      expect(json['ayt_math_net'], 20.0);
      expect(json['ayt_physics_net'], 15.0);
      expect(json['ayt_chemistry_net'], 10.0);
      expect(json['ayt_biology_net'], 12.0);
      expect(json['preferred_cities'], ['İstanbul', 'Ankara']);
      expect(json['preferred_university_types'], ['Devlet']);
      expect(json['budget_preference'], 'medium');
      expect(json['scholarship_preference'], true);
      expect(json['interest_areas'], ['Mühendislik', 'Teknoloji']);
    });

    test('StudentModel copyWith creates correct copy', () {
      const original = StudentModel(
        name: 'Original Name',
        classLevel: '12',
        examType: 'TYT+AYT',
        fieldType: 'SAY',
        tytTurkishNet: 30.0,
      );

      final copy = original.copyWith(
        name: 'Updated Name',
        tytTurkishNet: 35.0,
      );

      expect(copy.name, 'Updated Name');
      expect(copy.classLevel, '12'); // Unchanged
      expect(copy.examType, 'TYT+AYT'); // Unchanged
      expect(copy.fieldType, 'SAY'); // Unchanged
      expect(copy.tytTurkishNet, 35.0); // Changed
    });
  });
}
