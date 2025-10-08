import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/api_service.dart';
import '../models/student_model.dart';

part 'student_api_provider.g.dart';

// Data classes
class StudentListParams {
  final int skip;
  final int limit;

  StudentListParams({
    this.skip = 0,
    this.limit = 100,
  });
}

class StudentListResponse {
  final List<StudentModel> students;
  final int total;
  final int page;
  final int size;

  StudentListResponse({
    required this.students,
    required this.total,
    required this.page,
    required this.size,
  });

  factory StudentListResponse.fromJson(Map<String, dynamic> json) {
    return StudentListResponse(
      students: (json['students'] as List)
          .map((student) => StudentModel.fromJson(student))
          .toList(),
      total: json['total'],
      page: json['page'],
      size: json['size'],
    );
  }
}

// API Providers using the new Riverpod Generator syntax

@riverpod
Future<StudentListResponse> studentList(Ref ref, StudentListParams params) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getStudents(
    skip: params.skip,
    limit: params.limit,
  );
  return StudentListResponse.fromJson(response.data);
}

@riverpod
Future<StudentModel> studentDetail(Ref ref, int studentId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getStudent(studentId);
  return StudentModel.fromJson(response.data);
}

@Riverpod(keepAlive: true)
class StudentCreation extends _$StudentCreation {
  @override
  AsyncValue<StudentModel?> build() => const AsyncData(null);

  Future<StudentModel> createStudent(StudentModel student) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.createStudent(student.toJson());
      final createdStudent = StudentModel.fromJson(response.data);
      state = AsyncValue.data(createdStudent);
      return createdStudent;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
class StudentUpdate extends _$StudentUpdate {
  @override
  AsyncValue<StudentModel?> build() => const AsyncData(null);

  Future<StudentModel> updateStudent(int id, StudentModel student) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.updateStudent(id, student.toJson());
      final updatedStudent = StudentModel.fromJson(response.data);
      state = AsyncValue.data(updatedStudent);
      return updatedStudent;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
class StudentDeletion extends _$StudentDeletion {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  Future<void> deleteStudent(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteStudent(id);
      return true;
    });
  }
}

@Riverpod(keepAlive: true)
class ScoreCalculation extends _$ScoreCalculation {
  @override
  AsyncValue<Map<String, dynamic>?> build() => const AsyncData(null);

  Future<void> calculateScores(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.calculateScores(id);
      return response.data['scores'];
    });
  }
}
