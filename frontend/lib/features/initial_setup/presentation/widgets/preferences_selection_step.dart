import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/searchable_dropdown.dart';
import '../../../auth/data/providers/auth_service.dart';
import '../../../universities/data/providers/university_api_provider.dart'
    as university_providers;

class PreferencesSelectionStep extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onPreferencesCompleted;
  final VoidCallback onBack;
  final String departmentType;
  final List<Map<String, double>> examScores; // Tüm deneme netleri

  const PreferencesSelectionStep({
    super.key,
    required this.onPreferencesCompleted,
    required this.onBack,
    required this.departmentType,
    this.examScores = const [],
  });

  @override
  ConsumerState<PreferencesSelectionStep> createState() =>
      _PreferencesSelectionStepState();
}

class _PreferencesSelectionStepState
    extends ConsumerState<PreferencesSelectionStep> {
  final List<String> _selectedCities = [];
  final List<String> _selectedDepartments = [];
  String? _selectedFieldType; // 'SAY', 'EA', 'SÖZ', 'DİL'
  String? _selectedUniversityType; // 'devlet', 'vakıf', 'açıköğretim'
  String _selectedProgramType = 'lisans'; // ✅ CRITICAL FIX: Varsayılan değer 'lisans' (null olmamalı)

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Alan türünü parent'tan al
    _selectedFieldType = widget.departmentType;
  }

  // ✅ 1. VERİ TEMİZLEME VE NORMALİZASYON FONKSİYONU
  /// Bölüm adındaki parantez içlerini ve fazlalıkları temizler
  /// Örnek: "Bilgisayar Mühendisliği (İngilizce) (Burslu)" -> "Bilgisayar Mühendisliği"
  /// Örnek: "Adalet (Açıköğretim)" -> "Adalet"
  String _normalizeDeptName(String rawName) {
    if (rawName.isEmpty) return rawName;
    
    String normalized = rawName.trim();
    
    // ✅ Parantez içlerini temizle (tüm parantez türleri: (), [], {}, 「」)
    normalized = normalized
        .replaceAll(RegExp(r'\s*\([^)]*\)\s*', caseSensitive: false), '') // ()
        .replaceAll(RegExp(r'\s*\[[^\]]*\]\s*', caseSensitive: false), '') // []
        .replaceAll(RegExp(r'\s*\{[^}]*\}\s*', caseSensitive: false), '') // {}
        .trim();
    
    // ✅ Yaygın ekleri temizle
    final suffixes = [
      ' (Burslu)',
      ' (İÖ)',
      ' (İkinci Öğretim)',
      ' (KKTC)',
      ' (Açıköğretim)',
      ' (Uzaktan Öğretim)',
      ' (İngilizce)',
      ' (İng.)',
      ' (İng)',
      ' (İÖ)',
      ' (İkinci Öğretim)',
      ' (İkinci Öğretim)',
      ' (İÖ)',
      ' (İngilizce)',
      ' (İng.)',
      ' (İng)',
    ];
    
    for (final suffix in suffixes) {
      if (normalized.toLowerCase().endsWith(suffix.toLowerCase())) {
        normalized = normalized.substring(0, normalized.length - suffix.length).trim();
      }
    }
    
    // ✅ Fazla boşlukları temizle
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return normalized.isEmpty ? rawName : normalized;
  }

  // ✅ 2. KATI FİLTRELEME MANTIĞI (_getFilteredDepartments)
  /// Katı kurallarla filtreleme: Program Türü -> Alan Türü -> Üniversite Türü -> Unique & Normalize
  List<String> _getFilteredDepartments(List<Map<String, dynamic>> allDepartments) {
    // 1. Kullanıcı seçimlerini al
    final isLisans = _selectedProgramType == 'lisans'; // Lisans mı?
    final selectedField = _selectedFieldType; // SAY, EA, SOZ, DIL

    // 2. Ham listeyi filtrele
    var filtered = allDepartments.where((dept) {
      // A. İSİM TEMİZLİĞİ (Parantez içlerini yoksayarak karşılaştırma için)
      // (Bunu listede gösterirken yapacaksın, filtrede ham veriye bak)

      // B. SÜRE VE TÜR KONTROLÜ (EN KRİTİK KISIM)
      final duration = dept['duration'] as int?;
      final fieldType = (dept['field_type'] as String?)?.toUpperCase();

      if (isLisans) {
        // LİSANS İÇİN KURALLAR:

        // 1. Süre 4 yıl veya üzeri OLMALI (Veri null ise 4 kabul etme, ele)
        if (duration != null && duration < 4) return false;

        // 2. Puan türü ASLA 'TYT' OLMAMALI (Çünkü TYT önlisanstır)
        if (fieldType == 'TYT') return false;
      } else {
        // ÖNLİSANS İÇİN KURALLAR:

        // 1. Süre 2 yıl OLMALI
        if (duration != null && duration > 2) return false;

        // 2. Puan türü ZORUNLU OLARAK 'TYT' OLMALI (Önlisans için TYT zorunlu)
        if (fieldType != 'TYT') return false;
      }

      // C. ALAN TÜRÜ KONTROLÜ (SAY, EA, vb.)
      // Eğer Lisans seçiliyse ve bir alan (SAY) seçildiyse:
      if (isLisans && selectedField != null && selectedField.isNotEmpty) {
        // Bölümün türü, seçilen türle AYNEN EŞLEŞMELİ.
        // "SAY" seçtiyse "EA" gelmemeli.
        if (fieldType != selectedField.toUpperCase()) return false;
      }

      // D. ÜNİVERSİTE TÜRÜ FİLTRESİ
      if (_selectedUniversityType != null && _selectedUniversityType!.isNotEmpty) {
        // University bilgisini al (nested veya flat olabilir)
        final university = dept['university'] as Map<String, dynamic>?;
        final universityType = university?['university_type'] as String? ?? 
                               dept['university_type'] as String?;
        
        // ✅ Backend'den gelen değerler: 'state', 'foundation', 'private'
        if (_selectedUniversityType == 'devlet') {
          // Devlet: university_type == 'state' (backend formatı)
          if (universityType?.toLowerCase() != 'state') {
            return false;
          }
        } else if (_selectedUniversityType == 'vakıf') {
          // Vakıf: university_type == 'foundation' (backend formatı)
          if (universityType?.toLowerCase() != 'foundation') {
            return false;
          }
        } else if (_selectedUniversityType == 'açıköğretim') {
          // Açıköğretim: university_type == 'open_education' veya 'open' veya 'açıköğretim'
          final uniTypeLower = universityType?.toLowerCase() ?? '';
          if (!(uniTypeLower == 'open_education' || 
                uniTypeLower == 'open' || 
                uniTypeLower == 'açıköğretim')) {
            return false;
          }
        }
      }
      
      // E. DERECE TÜRÜ KONTROLÜ (degree_type)
      final degreeType = dept['degree_type'] as String?;
      if (isLisans) {
        // Lisans: degree_type == 'Bachelor'
        if (degreeType != null && degreeType.toLowerCase() != 'bachelor') {
          return false;
        }
      } else {
        // Önlisans: degree_type == 'Associate'
        if (degreeType != null && degreeType.toLowerCase() != 'associate') {
          return false;
        }
      }

      return true;
    }).toList();

    // 3. TEKİLLEŞTİRME (DISTINCT BY NAME)
    // Aynı isimden (örn: "Bilgisayar Mühendisliği") sadece 1 tane kalsın.
    final uniqueNames = <String>{};
    final uniqueList = <String>[];
    
    for (var dept in filtered) {
      // İsimdeki (İngilizce), (Burslu) gibi kısımları temizleyerek kontrol et
      final rawName = dept['name'] as String? ?? 
                     dept['program_name'] as String? ?? 
                     '';
      
      if (rawName.isEmpty) continue;
      
      final cleanName = _normalizeDeptName(rawName);
      
      if (uniqueNames.add(cleanName.toLowerCase())) {
        uniqueList.add(cleanName); // Sadece ilkini ekle
      }
    }

    // 4. SIRALA
    uniqueList.sort();
    return uniqueList;
  }

  Future<void> _complete() async {
    if (_selectedCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir şehir seçiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir bölüm seçiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final userName = prefs.getString('user_name') ?? 'Öğrenci';

      if (userId != null) {
        // Son denemenin netlerini kullan (veya ilk deneme netlerini)
        final latestScores = widget.examScores.isNotEmpty
            ? widget.examScores.last
            : <String, double>{};

        // Öğrenci profili oluştur - Backend şemasına uygun format
        debugPrint('🟢 Creating student profile...');
        final studentResponse = await _apiService.createStudent({
          'name': userName,
          'email': null,
          'phone': null,
          'class_level': '12',
          'exam_type': 'TYT+AYT',
          'field_type': _selectedFieldType ?? 'SAY',
          // TYT Netleri
          'tyt_turkish_net': latestScores['tyt_turkish_net'] ?? 0.0,
          'tyt_math_net': latestScores['tyt_math_net'] ?? 0.0,
          'tyt_social_net': latestScores['tyt_social_net'] ?? 0.0,
          'tyt_science_net': latestScores['tyt_science_net'] ?? 0.0,
          // AYT Netleri
          'ayt_math_net': latestScores['ayt_math_net'] ?? 0.0,
          'ayt_physics_net': latestScores['ayt_physics_net'] ?? 0.0,
          'ayt_chemistry_net': latestScores['ayt_chemistry_net'] ?? 0.0,
          'ayt_biology_net': latestScores['ayt_biology_net'] ?? 0.0,
          'ayt_literature_net': latestScores['ayt_literature_net'] ?? 0.0,
          'ayt_history1_net': latestScores['ayt_history1_net'] ?? 0.0,
          'ayt_geography1_net': latestScores['ayt_geography1_net'] ?? 0.0,
          'ayt_philosophy_net': latestScores['ayt_philosophy_net'] ?? 0.0,
          'ayt_history2_net': latestScores['ayt_history2_net'] ?? 0.0,
          'ayt_geography2_net': latestScores['ayt_geography2_net'] ?? 0.0,
          'ayt_religion_net': latestScores['ayt_religion_net'] ?? 0.0,
          'ayt_foreign_language_net':
              latestScores['ayt_foreign_language_net'] ?? 0.0,
          // Tercihler
          'preferred_cities': _selectedCities,
          'preferred_university_types': _selectedUniversityType != null
              ? [_selectedUniversityType]
              : null,
          'preferred_departments': _selectedDepartments,
          'budget_preference': null,
          'scholarship_preference': false,
          'interest_areas': null,
        });

        // ✅ Response formatını kontrol et ve Student ID'yi kaydet
        debugPrint('🟢 Student response status: ${studentResponse.statusCode}');
        debugPrint(
            '🟢 Student response data type: ${studentResponse.data.runtimeType}');
        debugPrint('🟢 Student response data: ${studentResponse.data}');

        if (studentResponse.statusCode != 200 &&
            studentResponse.statusCode != 201) {
          throw Exception(
              'Öğrenci profili oluşturulamadı: Status ${studentResponse.statusCode}');
        }

        if (studentResponse.data == null) {
          throw Exception('Öğrenci profili oluşturulamadı: Response data null');
        }

        // Response Map veya direkt Student objesi olabilir
        final responseData = studentResponse.data;
        int? studentId;

        if (responseData is Map<String, dynamic>) {
          studentId = responseData['id'] as int?;
        } else {
          // Direkt Student objesi ise (backend'den dönen format)
          studentId = (responseData as dynamic).id as int?;
        }

        if (studentId == null) {
          debugPrint('🔴 Student ID is null! Response: $responseData');
          throw Exception('Öğrenci ID alınamadı');
        }

        debugPrint('🟢 Student ID saved: $studentId');
        await prefs.setInt('student_id', studentId);

        debugPrint(
            '🟢 Preferred departments saved to database: $_selectedDepartments');

        // Tüm denemeleri kaydet
        for (int i = 0; i < widget.examScores.length; i++) {
          final examScores = widget.examScores[i];
          try {
            await _apiService.createExamAttempt({
              'student_id': studentId,
              'exam_name': 'Deneme ${i + 1}',
              'exam_date': DateTime.now().toIso8601String(),
              'tyt_turkish_net': examScores['tyt_turkish_net'] ?? 0.0,
              'tyt_math_net': examScores['tyt_math_net'] ?? 0.0,
              'tyt_social_net': examScores['tyt_social_net'] ?? 0.0,
              'tyt_science_net': examScores['tyt_science_net'] ?? 0.0,
              'ayt_math_net': examScores['ayt_math_net'] ?? 0.0,
              'ayt_physics_net': examScores['ayt_physics_net'] ?? 0.0,
              'ayt_chemistry_net': examScores['ayt_chemistry_net'] ?? 0.0,
              'ayt_biology_net': examScores['ayt_biology_net'] ?? 0.0,
              'ayt_literature_net': examScores['ayt_literature_net'] ?? 0.0,
              'ayt_history1_net': examScores['ayt_history1_net'] ?? 0.0,
              'ayt_geography1_net': examScores['ayt_geography1_net'] ?? 0.0,
              'ayt_philosophy_net': examScores['ayt_philosophy_net'] ?? 0.0,
              'ayt_history2_net': examScores['ayt_history2_net'] ?? 0.0,
              'ayt_geography2_net': examScores['ayt_geography2_net'] ?? 0.0,
              'ayt_religion_net': examScores['ayt_religion_net'] ?? 0.0,
              'ayt_foreign_language_net':
                  examScores['ayt_foreign_language_net'] ?? 0.0,
            });
          } catch (e) {
            debugPrint('Error saving exam attempt ${i + 1}: $e');
          }
        }
      }

      // Kullanıcı setup tamamlandı olarak işaretle
      final authService = getAuthService(ApiService());
      await authService.updateUser(
        isInitialSetupCompleted: true,
      );

      final preferences = {
        'cities': _selectedCities,
        'departments': _selectedDepartments,
        'field_type': _selectedFieldType,
      };

      widget.onPreferencesCompleted(preferences);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(university_providers.cityListProvider);
    // ✅ Field type'a göre filtreli bölümler çek - SADECE field_type seçildiyse
    // ✅ Boş liste başlangıcı: Alan seçilmeden API isteği atılmasın
    // ✅ ÖNEMLİ: Önlisans seçildiyse TYT field_type'ı ile API çağrısı yap
    final effectiveFieldType = _selectedProgramType == 'onlisans' 
        ? 'TYT'  // Önlisans seçildiyse TYT kullan
        : _selectedFieldType;  // Lisans seçildiyse seçilen field_type'ı kullan
    
    final departmentsAsync = (effectiveFieldType != null && effectiveFieldType.isNotEmpty)
        ? ref.watch(university_providers
            .filteredDepartmentListByFieldProvider(effectiveFieldType))
        : null; // ✅ null döndür - API isteği atılmasın

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tercihleriniz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hangi şehirlerde ve hangi bölümlerde okumak istersiniz?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Şehir seçimi
          const Text(
            'Tercih Ettiğiniz Şehirler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          citiesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Şehirler yüklenemedi: $error'),
                  TextButton(
                    onPressed: () =>
                        ref.refresh(university_providers.cityListProvider),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
            data: (cities) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ Arama yapılabilir dropdown
                SearchableDropdown<String>(
                  items: cities
                      .where((c) => !_selectedCities.contains(c))
                      .toList(),
                  itemAsString: (item) => item,
                  hintText: 'Şehir ekle...',
                  searchHintText: 'Şehir ara (örn: ankara)',
                  onChanged: (city) {
                    if (city != null) {
                      setState(() => _selectedCities.add(city));
                    }
                  },
                ),
                if (_selectedCities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCities.map((city) {
                      return Chip(
                        label: Text(city),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _selectedCities.remove(city));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bölüm seçimi - Alan türü ayrımı
          const Text(
            'İlgilendiğiniz Bölümler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ Program Türü seçimi (Lisans/Önlisans) - ÖNCE PROGRAM TÜRÜ
          const Text(
            'Program Türü',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'lisans',
                label: Text('Lisans (4 Yıllık)'),
              ),
              ButtonSegment<String>(
                value: 'onlisans',
                label: Text('Önlisans (2 Yıllık)'),
              ),
            ],
            selected: {_selectedProgramType},
            onSelectionChanged: (Set<String> newSelection) {
              if (newSelection.isNotEmpty) {
                setState(() {
                  _selectedProgramType = newSelection.first;
                  _selectedFieldType = null; // Alan türünü temizle
                  _selectedDepartments.clear(); // Bölümleri temizle
                  _selectedUniversityType = null; // Üniversite türünü de temizle
                  
                  // ✅ Önlisans seçildiyse field_type'ı TYT yap
                  if (_selectedProgramType == 'onlisans') {
                    _selectedFieldType = 'TYT';
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // ✅ Alan türü seçimi - Program türüne göre
          if (_selectedProgramType == 'onlisans') ...[
            // Önlisans seçildiyse sadece TYT göster
            const Text(
              'Alan Türü (Önlisans için TYT)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'TYT (Temel Yeterlilik Testi)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ] else ...[
            // Lisans seçildiyse SAY/EA/SÖZ/DİL göster
            const Text(
              'Alan Türü',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['SAY', 'EA', 'SÖZ', 'DİL'].map((field) {
                final isSelected = _selectedFieldType == field;
                return ChoiceChip(
                  label: Text(field),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFieldType = selected ? field : null;
                      _selectedDepartments.clear(); // Bölümleri temizle
                      _selectedUniversityType = null; // Üniversite türünü de temizle
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),


          // ✅ Üniversite türü seçimi (Alan türü seçildikten sonra)
          if (_selectedFieldType != null && _selectedFieldType!.isNotEmpty) ...[
            const Text(
              'Üniversite Türü',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                {'label': 'Devlet', 'value': 'devlet'},
                {'label': 'Vakıf', 'value': 'vakıf'},
                {'label': 'Açıköğretim', 'value': 'açıköğretim'},
              ].map((type) {
                final isSelected = _selectedUniversityType == type['value'];
                return ChoiceChip(
                  label: Text(type['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedUniversityType = selected ? type['value'] : null;
                      _selectedDepartments.clear(); // Bölümleri temizle
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ✅ Bölüm seçimi - Sadece field_type seçildiyse göster
          if (departmentsAsync == null) ...[
            // ✅ Alan türü seçilmediğinde uyarı mesajı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lütfen önce bir alan türü (SAY, EA, SÖZ, DİL) veya program türü (Lisans/Önlisans) seçin.',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            departmentsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Bölümler yüklenemedi: $error'),
                    TextButton(
                      onPressed: () {
                        if (_selectedFieldType != null &&
                            _selectedFieldType!.isNotEmpty) {
                          ref.invalidate(university_providers
                              .filteredDepartmentListByFieldProvider(
                                  _selectedFieldType));
                        }
                      },
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
              data: (departments) {
                // ✅ 2. KATI FİLTRELEME MANTIĞI (_getFilteredDepartments)
                final filteredDepartments = _getFilteredDepartments(departments);

                final availableDepartments = filteredDepartments
                    .where((d) => !_selectedDepartments.contains(d))
                    .toList();

                // Durum mesajı
                String hintText = 'Bölüm ekle...';
                if (availableDepartments.isEmpty) {
                  hintText = 'Bu kriterlere uygun bölüm bulunamadı';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ✅ Arama yapılabilir dropdown
                    SearchableDropdown<String>(
                      items: availableDepartments,
                      itemAsString: (item) => item,
                      hintText: hintText,
                      searchHintText: 'Bölüm ara (örn: bilgisayar)',
                      onChanged: (String? dept) {
                        if (dept != null) {
                          setState(() => _selectedDepartments.add(dept));
                        }
                      },
                    ),
                    if (_selectedDepartments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedDepartments.map((deptName) {
                          return Chip(
                            label: Text(deptName),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(
                                  () => _selectedDepartments.remove(deptName));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                );
              },
            ),
          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Geri'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _complete,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Tamamla',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
