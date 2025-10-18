import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../models/student_model.dart';

// ✅ Build runner GEREKTIRMEZ - Basit provider pattern

// Student List Provider
final studentListProvider = FutureProvider.autoDispose<List<StudentModel>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getStudents();
  return (response.data as List)
      .map((student) => StudentModel.fromJson(student))
      .toList();
});

// Student Detail Provider  
final studentDetailProvider = FutureProvider.autoDispose.family<StudentModel, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getStudent(studentId);
  return StudentModel.fromJson(response.data);
});

// Student Creation Service (basit StateNotifier yerine direkt fonksiyon)
final studentCreationServiceProvider = Provider<StudentCreationService>((ref) {
  return StudentCreationService(ref.read(apiServiceProvider));
});

class StudentCreationService {
  final ApiService _apiService;
  
  StudentCreationService(this._apiService);
  
  Future<StudentModel> createStudent(StudentModel student) async {
    final response = await _apiService.createStudent(student.toJson());
    return StudentModel.fromJson(response.data);
  }
  
  Future<StudentModel> updateStudent(int id, StudentModel student) async {
    final response = await _apiService.updateStudent(id, student.toJson());
    return StudentModel.fromJson(response.data);
  }
  
  Future<void> deleteStudent(int id) async {
    await _apiService.deleteStudent(id);
  }
  
  Future<Map<String, dynamic>> calculateScores(int id) async {
    final response = await _apiService.calculateScores(id);
    return response.data['scores'] as Map<String, dynamic>;
  }
}
