import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../models/student_model.dart';

// ✅ Build runner GEREKTIRMEZ - Basit provider pattern

// Student List Provider
final studentListProvider = FutureProvider<List<StudentModel>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    final response = await apiService.getStudents();
    
    if (response.statusCode != 200) {
      debugPrint('🔴 Students API error: Status ${response.statusCode}');
      return [];
    }
    
    if (response.data == null) {
      debugPrint('🔴 Students API: response.data is null');
      return [];
    }
    
    if (response.data is List) {
      return (response.data as List)
          .map((student) => StudentModel.fromJson(student as Map<String, dynamic>))
          .toList();
    }
    
    return [];
  } catch (e, stackTrace) {
    debugPrint('🔴 Error in studentListProvider: $e');
    debugPrint('🔴 Stack trace: $stackTrace');
    return [];
  }
});

// Student Detail Provider  
final studentDetailProvider = FutureProvider.family<StudentModel, int>((ref, studentId) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    final response = await apiService.getStudent(studentId);
    
    if (response.statusCode != 200) {
      debugPrint('🔴 Student Detail API error: Status ${response.statusCode}');
      debugPrint('🔴 Response data: ${response.data}');
      throw Exception('Failed to load student: Status ${response.statusCode}');
    }
    
    if (response.data == null) {
      debugPrint('🔴 Student Detail API: response.data is null');
      throw Exception('Student data is null');
    }
    
    debugPrint('🟢 Student Detail response type: ${response.data.runtimeType}');
    debugPrint('🟢 Student Detail response: ${response.data}');
    
    return StudentModel.fromJson(response.data as Map<String, dynamic>);
  } catch (e, stackTrace) {
    debugPrint('🔴 Error in studentDetailProvider: $e');
    debugPrint('🔴 Stack trace: $stackTrace');
    rethrow;
  }
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
