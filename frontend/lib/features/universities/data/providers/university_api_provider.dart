import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';

// ✅ CRITICAL FIX: keepAlive ile cache tutsun, sonsuz döngüyü önlemek için
// University list provider - Map dönüşü için
final universityListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  // ✅ CRITICAL FIX: keepAlive ile provider'ı cache'le
  ref.keepAlive();
  
  return (() async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    // ✅ Tüm üniversiteleri çek (limit 1000) - preferred cities filtresi provider seviyesinde değil, filtered provider'da uygulanıyor
    final response = await apiService.getUniversities(limit: 1000);
    
    // 🔍 DEBUG: Raw API Response
    debugPrint('🔍 DEBUG: Universities API Response Type: ${response.data.runtimeType}');
    debugPrint('🔍 DEBUG: Universities API Status Code: ${response.statusCode}');
    
    // ✅ Status code kontrolü
    if (response.statusCode != 200) {
      debugPrint('🔴 Universities API error: Status ${response.statusCode}');
      throw Exception('Üniversiteler yüklenemedi: Status ${response.statusCode}');
    }
    
    if (response.data == null) {
      debugPrint('🔴 Universities API: response.data is null');
      throw Exception('Üniversiteler yüklenemedi: Response data null');
    }
    
    debugPrint('🟢 Universities response type: ${response.data.runtimeType}');
    
    // ✅ Backend formatı: List[UniversityResponse] (direkt liste) veya {"universities": [...]}
    List<dynamic> universitiesList = [];
    
    if (response.data is Map) {
      final dataMap = response.data as Map<String, dynamic>;
      debugPrint('🟢 Response is Map, keys: ${dataMap.keys}');
      
      if (dataMap['universities'] != null) {
        final universitiesData = dataMap['universities'];
        if (universitiesData is List) {
          universitiesList = universitiesData;
          debugPrint('🟢 Found ${universitiesList.length} universities in Map');
        } else {
          debugPrint('🔴 universities value is not a List, type: ${universitiesData.runtimeType}');
          throw Exception('Üniversiteler yüklenemedi: universities değeri List değil');
        }
      } else {
        debugPrint('🔴 Map does not contain "universities" key');
        throw Exception('Üniversiteler yüklenemedi: Beklenmeyen format (Map without universities key)');
      }
    } else if (response.data is List) {
      universitiesList = response.data as List;
      debugPrint('🟢 Response is List, length: ${universitiesList.length}');
    } else {
      throw Exception('Üniversiteler yüklenemedi: Beklenmeyen format (${response.data.runtimeType})');
    }
    
    final universities = universitiesList
        .map((university) => university as Map<String, dynamic>)
        .toList();
    
    debugPrint('🟢 Universities loaded: ${universities.length}');
    return universities;
  } on DioException catch (e, stackTrace) {
    debugPrint('🔴 DioException in universityListProvider: $e');
    debugPrint('🔴 Error type: ${e.type}');
    debugPrint('🔴 Stack trace: $stackTrace');
    
    // Timeout hataları için özel mesaj
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      debugPrint('⏱️ Timeout error - universities API took too long');
      throw Exception('Üniversiteler yüklenirken zaman aşımı oluştu. Lütfen tekrar deneyin.');
    }
    
    // Connection hataları için özel mesaj
    if (e.type == DioExceptionType.connectionError) {
      debugPrint('🔌 Connection error - cannot reach server');
      throw Exception('Sunucuya bağlanılamadı. WiFi bağlantınızı kontrol edin.');
    }
    
    rethrow;
  } catch (e, stackTrace) {
    debugPrint('🔴 Error in universityListProvider: $e');
    debugPrint('🔴 Stack trace: $stackTrace');
    rethrow;
  }
  })();
});

// ✅ CRITICAL FIX: keepAlive ile cache tutsun, sonsuz döngüyü önlemek için
// Department list provider - Map dönüşü için (pagination ile)
final departmentListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  // ✅ CRITICAL FIX: keepAlive ile provider'ı cache'le
  ref.keepAlive();
  
  return (() async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    // ✅ OPTIMIZED: Tüm bölümleri çek - default 2000 kayıt (tüm veriler gelsin)
    final response = await apiService.getDepartments(limit: 2000);

    // 🔍 DEBUG: Raw API Response
    debugPrint('🔍 DEBUG: Departments API Response Type: ${response.data.runtimeType}');
    debugPrint('🔍 DEBUG: Departments API Status Code: ${response.statusCode}');
    if (response.data is Map) {
      debugPrint('🔍 DEBUG: Departments Response is Map, keys: ${(response.data as Map).keys.toList()}');
    } else if (response.data is List) {
      debugPrint('🔍 DEBUG: Departments Response is List, length: ${(response.data as List).length}');
    }

    // ✅ Status code kontrolü
    if (response.statusCode != 200) {
      debugPrint('🔴 Departments API error: Status ${response.statusCode}');
      throw Exception('Bölümler yüklenemedi: Status ${response.statusCode}');
    }

    // ✅ Response formatını kontrol et
    if (response.data == null) {
      debugPrint('🔴 Departments API: response.data is null');
      throw Exception('Bölümler yüklenemedi: Response data null');
    }
    
    debugPrint('🟢 Departments response type: ${response.data.runtimeType}');
    
    // ✅ Backend formatı: List[DepartmentWithUniversityResponse] (direkt liste) veya {"departments": [...]}
    List<dynamic> departmentsList = [];
    
    if (response.data is Map) {
      final dataMap = response.data as Map<String, dynamic>;
      debugPrint('🟢 Response is Map, keys: ${dataMap.keys}');
      
      // Hata mesajı kontrolü
      if (dataMap.containsKey('detail')) {
        throw Exception(dataMap['detail'] ?? 'Bölümler yüklenemedi');
      }
      
      // Departments key'i varsa
      if (dataMap['departments'] != null) {
        final departmentsData = dataMap['departments'];
        if (departmentsData is List) {
          departmentsList = departmentsData;
          debugPrint('🟢 Found ${departmentsList.length} departments in Map');
        } else {
          debugPrint('🔴 departments value is not a List, type: ${departmentsData.runtimeType}');
          throw Exception('Bölümler yüklenemedi: departments değeri List değil');
        }
      } else {
        debugPrint('🔴 Map does not contain "departments" key');
        throw Exception('Bölümler yüklenemedi: Beklenmeyen format (Map without departments key)');
      }
    } else if (response.data is List) {
      departmentsList = response.data as List;
      debugPrint('🟢 Response is List, length: ${departmentsList.length}');
    } else {
      throw Exception('Beklenmeyen response formatı: ${response.data.runtimeType}');
    }
    
    final departments = departmentsList
        .map((department) => department as Map<String, dynamic>)
        .toList();
    
    debugPrint('🟢 Departments loaded: ${departments.length}');
    return departments;
  } on DioException catch (e, stackTrace) {
    debugPrint('🔴 DioException in departmentListProvider: $e');
    debugPrint('🔴 Error type: ${e.type}');
    debugPrint('🔴 Stack trace: $stackTrace');
    
    // Timeout hataları için özel mesaj
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      debugPrint('⏱️ Timeout error - departments API took too long');
      throw Exception('Bölümler yüklenirken zaman aşımı oluştu. Lütfen tekrar deneyin.');
    }
    
    // Connection hataları için özel mesaj
    if (e.type == DioExceptionType.connectionError) {
      debugPrint('🔌 Connection error - cannot reach server');
      throw Exception('Sunucuya bağlanılamadı. WiFi bağlantınızı kontrol edin.');
    }
    
    rethrow;
  } catch (e, stackTrace) {
    debugPrint('🔴 Error in departmentListProvider: $e');
    debugPrint('🔴 Stack trace: $stackTrace');
    rethrow;
  }
  })();
});

// ✅ Field type'a göre filtreli bölümler provider'ı
final filteredDepartmentListByFieldProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, fieldType) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    // ✅ Field type varsa filtreli API kullan
    if (fieldType != null && fieldType.isNotEmpty) {
      // ✅ ÖNEMLİ: TYT seçildiyse degree_type=Associate gönder
      String? degreeType;
      if (fieldType == 'TYT') {
        degreeType = 'Associate'; // Önlisans için Associate
      }
      
      final response = await apiService.getDepartmentsFiltered(
        fieldType: fieldType,
        degreeType: degreeType, // ✅ Backend'e degree_type gönder
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

// ✅ Unique (normalize edilmiş) bölüm listesi provider'ı
final uniqueDepartmentListProvider = FutureProvider.family<List<Map<String, dynamic>>, UniqueDepartmentParams>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    final response = await apiService.getUniqueDepartments(
      universityType: params.universityType,
      fieldType: params.fieldType,
    );
    
    if (response.data == null) {
      throw Exception('Unique bölümler yüklenemedi: Response data null');
    }
    
    if (response.data is! List) {
      throw Exception('Unique bölümler yüklenemedi: Beklenmeyen format');
    }
    
    final uniqueDepartments = (response.data as List)
        .map((dept) => dept as Map<String, dynamic>)
        .toList();
    
    debugPrint('🟢 Unique departments loaded: ${uniqueDepartments.length}');
    return uniqueDepartments;
  } catch (e) {
    debugPrint('🔴 Unique department loading error: $e');
    rethrow;
  }
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
        (ref, params) {
  // ✅ CRITICAL FIX: keepAlive ile provider'ı cache'le
  ref.keepAlive();
  
  return (() async {
  final universities = await ref.watch(universityListProvider.future);

  return universities.where((university) {
    // ✅ Öncelik: Tercih edilen şehirler filtresi
    // Eğer tercih edilen şehirler varsa ve kullanıcı özel bir şehir seçmemişse,
    // sadece tercih edilen şehirlerdeki üniversiteleri göster
    if (params.preferredCities != null && 
        params.preferredCities!.isNotEmpty && 
        params.city == null) {
      final universityCity = university['city'] as String? ?? '';
      if (!params.preferredCities!.contains(universityCity)) {
        return false;
      }
    }
    
    // City filter (kullanıcı özel bir şehir seçmişse)
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
  })();
});

// ✅ CRITICAL FIX: keepAlive ile cache tutsun, sonsuz döngüyü önlemek için
final filteredDepartmentListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DepartmentFilterParams>(
        (ref, params) {
  // ✅ CRITICAL FIX: keepAlive ile provider'ı cache'le
  ref.keepAlive();
  
  return (() async {
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
  })();
});

// Data classes
class UniversityFilterParams {
  final String? city;
  final String? type;
  final String? searchQuery;
  final List<String>? preferredCities; // ✅ Öğrencinin tercih ettiği şehirler

  UniversityFilterParams({
    this.city,
    this.type,
    this.searchQuery,
    this.preferredCities,
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

// ✅ Unique departments için parametreler
class UniqueDepartmentParams {
  final String? universityType; // devlet, vakif
  final String? fieldType; // SAY, EA, SÖZ, DİL

  UniqueDepartmentParams({
    this.universityType,
    this.fieldType,
  });
}
