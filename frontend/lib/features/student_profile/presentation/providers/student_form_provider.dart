import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/student_model.dart';
import '../../data/providers/student_api_provider.dart';

part 'student_form_provider.g.dart';

// The state of our form
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
    Object? error,
    bool clearError = false,
    int? currentStep,
  }) {
    return StudentFormState(
      student: student ?? this.student,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error?.toString(),
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

// The notifier for our form, using the new Riverpod Generator syntax
@riverpod
class StudentForm extends _$StudentForm {
  @override
  StudentFormState build() {
    return const StudentFormState(
      student: StudentModel(
        name: '',
        classLevel: '12',
        examType: 'TYT+AYT',
        fieldType: 'SAY',
      ),
    );
  }

  void updateField(String field, dynamic value) {
    StudentModel updatedStudent = state.student;

    switch (field) {
      case 'name':
        updatedStudent = state.student.copyWith(name: value as String);
        break;
      case 'email':
        updatedStudent = state.student.copyWith(email: value as String?);
        break;
      case 'phone':
        updatedStudent = state.student.copyWith(phone: value as String?);
        break;
      case 'classLevel':
        updatedStudent = state.student.copyWith(classLevel: value as String);
        break;
      case 'examType':
        updatedStudent = state.student.copyWith(examType: value as String);
        break;
      case 'fieldType':
        updatedStudent = state.student.copyWith(fieldType: value as String);
        break;
      case 'tytTurkishNet':
        updatedStudent = state.student.copyWith(tytTurkishNet: value as double);
        break;
      case 'tytMathNet':
        updatedStudent = state.student.copyWith(tytMathNet: value as double);
        break;
      case 'tytSocialNet':
        updatedStudent = state.student.copyWith(tytSocialNet: value as double);
        break;
      case 'tytScienceNet':
        updatedStudent = state.student.copyWith(tytScienceNet: value as double);
        break;
      case 'aytMathNet':
        updatedStudent = state.student.copyWith(aytMathNet: value as double);
        break;
      case 'aytPhysicsNet':
        updatedStudent = state.student.copyWith(aytPhysicsNet: value as double);
        break;
      case 'aytChemistryNet':
        updatedStudent = state.student.copyWith(aytChemistryNet: value as double);
        break;
      case 'aytBiologyNet':
        updatedStudent = state.student.copyWith(aytBiologyNet: value as double);
        break;
      case 'aytLiteratureNet':
        updatedStudent = state.student.copyWith(aytLiteratureNet: value as double);
        break;
      case 'aytHistory1Net':
        updatedStudent = state.student.copyWith(aytHistory1Net: value as double);
        break;
      case 'aytGeography1Net':
        updatedStudent = state.student.copyWith(aytGeography1Net: value as double);
        break;
      case 'aytPhilosophyNet':
        updatedStudent = state.student.copyWith(aytPhilosophyNet: value as double);
        break;
      case 'aytHistory2Net':
        updatedStudent = state.student.copyWith(aytHistory2Net: value as double);
        break;
      case 'aytGeography2Net':
        updatedStudent = state.student.copyWith(aytGeography2Net: value as double);
        break;
      case 'aytForeignLanguageNet':
        updatedStudent = state.student.copyWith(aytForeignLanguageNet: value as double);
        break;
      case 'preferredCities':
        updatedStudent = state.student.copyWith(preferredCities: value as List<String>?);
        break;
      case 'preferredUniversityTypes':
        updatedStudent = state.student.copyWith(preferredUniversityTypes: value as List<String>?);
        break;
      case 'budgetPreference':
        updatedStudent = state.student.copyWith(budgetPreference: value as String?);
        break;
      case 'scholarshipPreference':
        updatedStudent = state.student.copyWith(scholarshipPreference: value as bool);
        break;
      case 'interestAreas':
        updatedStudent = state.student.copyWith(interestAreas: value as List<String>?);
        break;
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

  Future<bool> submitForm() async {
    if (state.student.name.isEmpty) {
      state = state.copyWith(error: 'Ad soyad gereklidir', isLoading: false);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final studentCreationNotifier = ref.read(studentCreationProvider.notifier);
      final createdStudent = await studentCreationNotifier.createStudent(state.student);
      
      // If successful, update state and indicate success
      state = state.copyWith(isLoading: false, student: createdStudent);
      return true;
    } catch (e) {
      // If any error occurs during creation, update the state with the error
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const StudentFormState(
      student: StudentModel(
        name: '',
        classLevel: '12',
        examType: 'TYT+AYT',
        fieldType: 'SAY',
      ),
    );
  }
}
