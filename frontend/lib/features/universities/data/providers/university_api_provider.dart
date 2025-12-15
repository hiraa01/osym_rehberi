import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';

// ✅ autoDispose: Her kullanıcı için fresh data, cache yok!
// University list provider - Map dönüşü için
final universityListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getUniversities();

  return (response.data as List)
      .map((university) => university as Map<String, dynamic>)
      .toList();
});

// Department list provider - Map dönüşü için (pagination ile)
final departmentListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    // ✅ OPTIMIZED: Tüm bölümleri çek - default 2000 kayıt (tüm veriler gelsin)
    final response = await apiService.getDepartments(limit: 2000);

    // ✅ Response formatını kontrol et
    if (response.data == null) {
      throw Exception('Bölümler yüklenemedi: Response data null');
    }
    
    // ✅ Map ise hata mesajı olabilir
    if (response.data is Map) {
      final errorData = response.data as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Bölümler yüklenemedi');
    }
    
    // ✅ List ise parse et
    if (response.data is List) {
      final departments = (response.data as List)
          .map((department) => department as Map<String, dynamic>)
          .toList();
      debugPrint('🟢 Departments loaded: ${departments.length}');
      return departments;
    }
    
    throw Exception('Beklenmeyen response formatı: ${response.data.runtimeType}');
  } catch (e) {
    debugPrint('🔴 Department loading error: $e');
    rethrow;
  }
});

// ✅ Field type'a göre filtreli bölümler provider'ı
final filteredDepartmentListByFieldProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, fieldType) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    // ✅ Field type varsa filtreli API kullan
    if (fieldType != null && fieldType.isNotEmpty) {
      final response = await apiService.getDepartmentsFiltered(
        fieldType: fieldType,
        limit: 2000, // Tüm bölümler gelsin
      );
      
      // ✅ Response formatını kontrol et
      if (response.data == null) {
        throw Exception('Bölümler yüklenemedi: Response data null');
      }
      
      // ✅ Map ise hata mesajı olabilir, List ise başarılı
      if (response.data is Map) {
        final errorData = response.data as Map<String, dynamic>;
        throw Exception(errorData['detail'] ?? 'Bölümler yüklenemedi');
      }
      
      // ✅ List ise parse et
      if (response.data is List) {
        return (response.data as List)
            .map((department) => department as Map<String, dynamic>)
            .toList();
      }
      
      throw Exception('Beklenmeyen response formatı: ${response.data.runtimeType}');
    } else {
      // Field type yoksa tüm bölümleri çek
      final response = await apiService.getDepartments(limit: 2000);
      
      // ✅ Response formatını kontrol et
      if (response.data == null) {
        throw Exception('Bölümler yüklenemedi: Response data null');
      }
      
      if (response.data is Map) {
        final errorData = response.data as Map<String, dynamic>;
        throw Exception(errorData['detail'] ?? 'Bölümler yüklenemedi');
      }
      
      if (response.data is List) {
        return (response.data as List)
            .map((department) => department as Map<String, dynamic>)
            .toList();
      }
      
      throw Exception('Beklenmeyen response formatı: ${response.data.runtimeType}');
    }
  } catch (e) {
    // Hata durumunda boş liste döndür ve hatayı logla
    debugPrint('🔴 Department loading error: $e');
    rethrow; // Hata yukarıya fırlatılsın ki UI'da gösterilebilsin
  }
});

// City list provider
final cityListProvider = FutureProvider<List<String>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getCities();

  // ✅ Response formatını kontrol et
  if (response.data == null) {
    throw Exception('Şehirler yüklenemedi: Response data null');
  }
  
  if (response.data is! List) {
    throw Exception('Şehirler yüklenemedi: Beklenmeyen format');
  }

  // Backend zaten Türkçe karakterlere uygun sıralı döndürüyor (81 il + KKTC + diğerleri)
  // ✅ Frontend'de de duplicate temizleme yap (case-insensitive ve Türkçe karakter normalize)
  final rawCities = List<String>.from(response.data as List);
  final seen = <String>{};
  final uniqueCities = <String>[];
  
  // ✅ Normalize fonksiyonu
  String normalizeCity(String city) {
    return city
        .toLowerCase()
        .trim()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('Ç', 'c')
        .replaceAll('Ğ', 'g')
        .replaceAll('İ', 'i')
        .replaceAll('Ö', 'o')
        .replaceAll('Ş', 's')
        .replaceAll('Ü', 'u');
  }
  
  for (final city in rawCities) {
    final normalized = normalizeCity(city);
    
    // ✅ Eğer normalize edilmiş versiyonu daha önce görülmüşse, ekleme
    if (!seen.contains(normalized)) {
      seen.add(normalized);
      uniqueCities.add(city);
    } else {
      debugPrint('⚠️ Duplicate şehir kaldırıldı: "$city" (normalize: "$normalized")');
    }
  }
  
  debugPrint('🟢 Frontend: ${rawCities.length} şehirden ${uniqueCities.length} unique şehir');
  
  final cities = uniqueCities;
  
  // ✅ Debug: Kaç şehir geldi?
  debugPrint('🟢 Cities loaded: ${cities.length}');
  if (cities.length < 80) {
    debugPrint('⚠️ Warning: Expected 81+ cities, got ${cities.length}');
  }
  
  return cities;
});

// Field type list provider
final fieldTypeListProvider = FutureProvider<List<String>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getFieldTypes();

  return List<String>.from(response.data);
});

// University type list provider
final universityTypeListProvider = FutureProvider<List<String>>((ref) async {
  final universities = await ref.watch(universityListProvider.future);

  // Üniversite türlerini unique olarak çıkar
  final types = universities
      .map((uni) => uni['university_type'] as String? ?? '')
      .where((type) => type.isNotEmpty)
      .toSet()
      .toList();

  return types;
});

// Filtered university list provider - autoDispose eklendi
final filteredUniversityListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, UniversityFilterParams>(
        (ref, params) async {
  final universities = await ref.watch(universityListProvider.future);

  return universities.where((university) {
    // City filter
    if (params.city != null &&
        params.city!.isNotEmpty &&
        university['city'] != params.city) {
      return false;
    }

    // Type filter
    if (params.type != null &&
        params.type!.isNotEmpty &&
        university['university_type'] != params.type) {
      return false;
    }

    // Search filter
    if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
      final query = params.searchQuery!.toLowerCase();
      final name = (university['name'] as String? ?? '').toLowerCase();
      final city = (university['city'] as String? ?? '').toLowerCase();
      if (!name.contains(query) && !city.contains(query)) {
        return false;
      }
    }

    return true;
  }).toList();
});

// Filtered department list provider - autoDispose eklendi
final filteredDepartmentListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DepartmentFilterParams>(
        (ref, params) async {
  final departments = await ref.watch(departmentListProvider.future);

  return departments.where((department) {
    // Field filter
    if (params.fieldType != null &&
        params.fieldType!.isNotEmpty &&
        department['field_type'] != params.fieldType) {
      return false;
    }

    // City filter
    if (params.city != null &&
        params.city!.isNotEmpty &&
        department['city'] != params.city) {
      return false;
    }

    // Search filter
    if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
      final query = params.searchQuery!.toLowerCase();
      final programName =
          (department['program_name'] as String? ?? '').toLowerCase();
      final name = (department['name'] as String? ?? '').toLowerCase();
      final universityName =
          (department['university_name'] as String? ?? '').toLowerCase();
      final city = (department['city'] as String? ?? '').toLowerCase();
      if (!programName.contains(query) &&
          !name.contains(query) &&
          !universityName.contains(query) &&
          !city.contains(query)) {
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
