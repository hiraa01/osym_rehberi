import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../models/university_model.dart';
import '../models/department_model.dart';

// ✅ autoDispose: Her kullanıcı için fresh data, cache yok!
// University list provider
final universityListProvider = FutureProvider<List<UniversityModel>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getUniversities();
  
  return (response.data as List)
      .map((university) => UniversityModel.fromJson(university))
      .toList();
});

// Department list provider
final departmentListProvider = FutureProvider<List<DepartmentModel>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getDepartments();
  
  return (response.data as List)
      .map((department) => DepartmentModel.fromJson(department))
      .toList();
});

// City list provider
final cityListProvider = FutureProvider<List<String>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getCities();
  
  return List<String>.from(response.data);
});

// Field type list provider
final fieldTypeListProvider = FutureProvider<List<String>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getFieldTypes();
  
  return List<String>.from(response.data);
});

// Filtered university list provider - autoDispose eklendi
final filteredUniversityListProvider = FutureProvider.family<List<UniversityModel>, UniversityFilterParams>((ref, params) async {
  final universities = await ref.watch(universityListProvider.future);
  
  return universities.where((university) {
    // City filter
    if (params.city != null && params.city!.isNotEmpty && university.city != params.city) {
      return false;
    }
    
    // Type filter
    if (params.type != null && params.type!.isNotEmpty && university.universityType != params.type) {
      return false;
    }
    
    // Search filter
    if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
      final query = params.searchQuery!.toLowerCase();
      if (!university.name.toLowerCase().contains(query) &&
          !university.city.toLowerCase().contains(query)) {
        return false;
      }
    }
    
    return true;
  }).toList();
});

// Filtered department list provider - autoDispose eklendi
final filteredDepartmentListProvider = FutureProvider.family<List<DepartmentModel>, DepartmentFilterParams>((ref, params) async {
  final departments = await ref.watch(departmentListProvider.future);
  
  return departments.where((department) {
    // Field filter
    if (params.fieldType != null && params.fieldType!.isNotEmpty && department.fieldType != params.fieldType) {
      return false;
    }
    
    // City filter
    if (params.city != null && params.city!.isNotEmpty && department.city != params.city) {
      return false;
    }
    
    // Search filter
    if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
      final query = params.searchQuery!.toLowerCase();
      if (!department.name.toLowerCase().contains(query) &&
          !department.universityName!.toLowerCase().contains(query) &&
          !department.city!.toLowerCase().contains(query)) {
        return false;
      }
    }
    
    return true;
  }).toList();
});

// Data classes
class UniversityFilterParams {
  final String? city;
  final String? type;
  final String? searchQuery;

  UniversityFilterParams({
    this.city,
    this.type,
    this.searchQuery,
  });
}

class DepartmentFilterParams {
  final String? fieldType;
  final String? city;
  final String? universityType;
  final String? searchQuery;

  DepartmentFilterParams({
    this.fieldType,
    this.city,
    this.universityType,
    this.searchQuery,
  });
}
