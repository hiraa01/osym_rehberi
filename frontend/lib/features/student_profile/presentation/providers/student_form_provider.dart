import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_model.dart';
import '../../data/providers/student_api_provider.dart';

// ✅ Build runner GEREKTIRMEZ - Basit StateNotifier pattern

// Form State
class StudentFormState {
  final StudentModel student;
  final bool isLoading;
  final String? error;
  final int currentStep;

  const StudentFormState({
    required this.student,
    this.isLoading = false,
    this.error,
    this.currentStep = 0,
  });

  StudentFormState copyWith({
    StudentModel? student,
    bool? isLoading,
    String? error,
    int? currentStep,
  }) {
    return StudentFormState(
      student: student ?? this.student,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

// Form Notifier (StateNotifier kullanmadan basit bir sınıf)
class StudentFormNotifier extends Notifier<StudentFormState> {
  @override
  StudentFormState build() {
    return StudentFormState(
      student: const StudentModel(
        name: '',
        classLevel: '11',
        examType: 'YKS',
        fieldType: 'SAY',
      ),
    );
  }

  void updateStudent(StudentModel student) {
    state = state.copyWith(student: student);
  }

  void updateName(String name) {
    state = state.copyWith(
      student: state.student.copyWith(name: name),
    );
  }

  void updateFieldType(String fieldType) {
    state = state.copyWith(
      student: state.student.copyWith(fieldType: fieldType),
    );
  }

  void updateClassLevel(String classLevel) {
    state = state.copyWith(
      student: state.student.copyWith(classLevel: classLevel),
    );
  }

  void updateExamType(String examType) {
    state = state.copyWith(
      student: state.student.copyWith(examType: examType),
    );
  }

  // Dinamik field update metodu (form widget'ları için)
  void updateField(String fieldName, dynamic value) {
    final currentStudent = state.student;
    StudentModel updatedStudent;

    switch (fieldName) {
      case 'name':
        updatedStudent = currentStudent.copyWith(name: value as String);
        break;
      case 'email':
        updatedStudent = currentStudent.copyWith(email: value as String?);
        break;
      case 'phone':
        updatedStudent = currentStudent.copyWith(phone: value as String?);
        break;
      case 'classLevel':
        updatedStudent = currentStudent.copyWith(classLevel: value as String);
        break;
      case 'examType':
        updatedStudent = currentStudent.copyWith(examType: value as String);
        break;
      case 'fieldType':
        updatedStudent = currentStudent.copyWith(fieldType: value as String);
        break;
      case 'tytTurkishNet':
        updatedStudent = currentStudent.copyWith(tytTurkishNet: value as double);
        break;
      case 'tytMathNet':
        updatedStudent = currentStudent.copyWith(tytMathNet: value as double);
        break;
      case 'tytSocialNet':
        updatedStudent = currentStudent.copyWith(tytSocialNet: value as double);
        break;
      case 'tytScienceNet':
        updatedStudent = currentStudent.copyWith(tytScienceNet: value as double);
        break;
      case 'aytMathNet':
        updatedStudent = currentStudent.copyWith(aytMathNet: value as double);
        break;
      case 'aytPhysicsNet':
        updatedStudent = currentStudent.copyWith(aytPhysicsNet: value as double);
        break;
      case 'aytChemistryNet':
        updatedStudent = currentStudent.copyWith(aytChemistryNet: value as double);
        break;
      case 'aytBiologyNet':
        updatedStudent = currentStudent.copyWith(aytBiologyNet: value as double);
        break;
      case 'aytLiteratureNet':
        updatedStudent = currentStudent.copyWith(aytLiteratureNet: value as double);
        break;
      case 'aytHistory1Net':
        updatedStudent = currentStudent.copyWith(aytHistory1Net: value as double);
        break;
      case 'aytGeography1Net':
        updatedStudent = currentStudent.copyWith(aytGeography1Net: value as double);
        break;
      case 'aytPhilosophyNet':
        updatedStudent = currentStudent.copyWith(aytPhilosophyNet: value as double);
        break;
      case 'aytHistory2Net':
        updatedStudent = currentStudent.copyWith(aytHistory2Net: value as double);
        break;
      case 'aytGeography2Net':
        updatedStudent = currentStudent.copyWith(aytGeography2Net: value as double);
        break;
      case 'aytForeignLanguageNet':
        updatedStudent = currentStudent.copyWith(aytForeignLanguageNet: value as double);
        break;
      case 'preferredCities':
        updatedStudent = currentStudent.copyWith(preferredCities: value as List<String>?);
        break;
      case 'preferredUniversityTypes':
        updatedStudent = currentStudent.copyWith(preferredUniversityTypes: value as List<String>?);
        break;
      case 'budgetPreference':
        updatedStudent = currentStudent.copyWith(budgetPreference: value as String?);
        break;
      case 'scholarshipPreference':
        updatedStudent = currentStudent.copyWith(scholarshipPreference: value as bool);
        break;
      case 'interestAreas':
        updatedStudent = currentStudent.copyWith(interestAreas: value as List<String>?);
        break;
      default:
        return; // Bilinmeyen field, güncelleme yapma
    }

    state = state.copyWith(student: updatedStudent);
  }

  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> submitForm() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final creationService = ref.read(studentCreationServiceProvider);
      final createdStudent = await creationService.createStudent(state.student);
      state = state.copyWith(
        student: createdStudent,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

// Provider
final studentFormProvider = NotifierProvider<StudentFormNotifier, StudentFormState>(
  StudentFormNotifier.new,
);
