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

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Alan türünü parent'tan al
    _selectedFieldType = widget.departmentType;
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
    // ✅ Field type'a göre filtreli bölümler çek
    final departmentsAsync =
        _selectedFieldType != null && _selectedFieldType!.isNotEmpty
            ? ref.watch(university_providers
                .filteredDepartmentListByFieldProvider(_selectedFieldType))
            : ref.watch(university_providers.departmentListProvider);

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

          // Alan türü seçimi
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
                    _selectedUniversityType =
                        null; // Üniversite türünü de temizle
                  });
                },
              );
            }).toList(),
          ),
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
                      } else {
                        ref.invalidate(
                            university_providers.departmentListProvider);
                      }
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
            data: (departments) {
              // ✅ Backend'den zaten field_type'a göre filtrelenmiş geliyor
              // Sadece bölüm adlarını çıkar ve unique yap
              debugPrint('🟢 Departments loaded: ${departments.length}');

              // ✅ Sadece bölüm adlarını çıkar (üniversite adı olmadan)
              final filteredDepartments = departments
                  .map((dept) {
                    final name = dept['name'] as String? ??
                        dept['program_name'] as String? ??
                        '';

                    // ✅ Bölüm adını temizle - sadece bölüm adını göster
                    // Backend'den gelen name zaten sadece bölüm adını içeriyor
                    // Ama bazı bölümler "Adana Tıp Fakültesi" gibi şehir adı içerebilir
                    String cleanName = name;

                    // Şehir adlarını çıkar (81 il listesi)
                    final turkishCities = [
                      'Adana',
                      'Adıyaman',
                      'Afyonkarahisar',
                      'Ağrı',
                      'Aksaray',
                      'Amasya',
                      'Ankara',
                      'Antalya',
                      'Ardahan',
                      'Artvin',
                      'Aydın',
                      'Balıkesir',
                      'Bartın',
                      'Batman',
                      'Bayburt',
                      'Bilecik',
                      'Bingöl',
                      'Bitlis',
                      'Bolu',
                      'Burdur',
                      'Bursa',
                      'Çanakkale',
                      'Çankırı',
                      'Çorum',
                      'Denizli',
                      'Diyarbakır',
                      'Düzce',
                      'Edirne',
                      'Elazığ',
                      'Erzincan',
                      'Erzurum',
                      'Eskişehir',
                      'Gaziantep',
                      'Giresun',
                      'Gümüşhane',
                      'Hakkari',
                      'Hatay',
                      'Iğdır',
                      'Isparta',
                      'İstanbul',
                      'İzmir',
                      'Kahramanmaraş',
                      'Karabük',
                      'Karaman',
                      'Kars',
                      'Kastamonu',
                      'Kayseri',
                      'Kırıkkale',
                      'Kırklareli',
                      'Kırşehir',
                      'Kilis',
                      'Kocaeli',
                      'Konya',
                      'Kütahya',
                      'Malatya',
                      'Manisa',
                      'Mardin',
                      'Mersin',
                      'Muğla',
                      'Muş',
                      'Nevşehir',
                      'Niğde',
                      'Ordu',
                      'Osmaniye',
                      'Rize',
                      'Sakarya',
                      'Samsun',
                      'Siirt',
                      'Sinop',
                      'Sivas',
                      'Şanlıurfa',
                      'Şırnak',
                      'Tekirdağ',
                      'Tokat',
                      'Trabzon',
                      'Tunceli',
                      'Uşak',
                      'Van',
                      'Yalova',
                      'Yozgat',
                      'Zonguldak'
                    ];

                    // ✅ Şehir adlarını ve ilçe adlarını çıkar
                    // Önce şehir adlarını kontrol et
                    for (final city in turkishCities) {
                      // Case-insensitive kontrol
                      if (cleanName
                          .toLowerCase()
                          .startsWith(city.toLowerCase())) {
                        cleanName = cleanName.substring(city.length).trim();
                        break;
                      }
                    }

                    // İlçe adlarını da temizle (örnek: "Kadıköy", "Beşiktaş", "Çankaya" vb.)
                    final districts = [
                      'Kadıköy',
                      'Beşiktaş',
                      'Çankaya',
                      'Şişli',
                      'Beyoğlu',
                      'Üsküdar',
                      'Bakırköy',
                      'Maltepe',
                      'Pendik',
                      'Kartal',
                      'Ataşehir',
                      'Sarıyer',
                      'Beylikdüzü',
                      'Başakşehir',
                      'Esenyurt',
                      'Sultangazi',
                      'Gaziosmanpaşa',
                      'Kağıthane',
                      'Zeytinburnu',
                      'Fatih',
                      'Eminönü',
                      'Taksim',
                      'Levent',
                      'Maslak',
                      'Etiler',
                      'Nişantaşı',
                      'Ortaköy',
                      'Bebek',
                      'Arnavutköy',
                      'Sarıgöl',
                      'Yenimahalle',
                      'Mamak',
                      'Keçiören',
                      'Altındağ',
                      'Sincan',
                      'Polatlı',
                      'Beypazarı',
                      'Ayaş',
                      'Gölbaşı',
                      'Haymana',
                      'Nallıhan',
                      'Kızılcahamam',
                      'Çubuk',
                      'Elmadağ',
                      'Kalecik',
                      'Bala',
                      'Şereflikoçhisar',
                      'Akyurt',
                      'Güdül',
                      'Evren',
                      'Kazan',
                      'Pursaklar',
                      'Aksaray',
                      'Ereğli',
                      'Karapınar',
                      'Bor',
                      'Ulukışla',
                      'Çiftlik',
                      'Gülağaç',
                      'Ortaköy',
                      'Güzelyurt',
                      'Sarıyahşi',
                      'Ağaçören',
                      'Göksun',
                      'Andırın',
                      'Çağlayancerit',
                      'Ekinözü',
                      'Elbistan',
                      'Nurhak',
                      'Pazarcık',
                      'Türkoğlu',
                      'Afşin',
                      'Dulkadiroğlu',
                      'Onikişubat',
                      'Merkez',
                      'İlçe',
                      'Mahalle'
                    ];

                    for (final district in districts) {
                      if (cleanName
                          .toLowerCase()
                          .contains(district.toLowerCase())) {
                        cleanName = cleanName
                            .replaceAll(
                                RegExp(district, caseSensitive: false), '')
                            .trim();
                      }
                    }

                    // "Fakültesi", "Üniversitesi", "Üniversite", "Yüksekokulu" gibi kelimeleri temizle
                    cleanName = cleanName
                        .replaceAll(
                            RegExp(
                                r'\s*(Fakültesi|Üniversitesi|Üniversite|Yüksekokulu|Yüksek Okulu|Meslek Yüksekokulu|MYO)\s*',
                                caseSensitive: false),
                            '')
                        .trim();

                    // Eğer temizlenmiş ad boşsa orijinal adı kullan
                    return cleanName.isNotEmpty ? cleanName : name;
                  })
                  .where((name) => name.isNotEmpty)
                  .toList() // ✅ Tüm bölümleri göster (unique yapma - backend'den gelen tüm bölümler)
                ..sort(); // ✅ Alfabetik sırala

              debugPrint(
                  '🟢 Filtered departments: ${filteredDepartments.length}');

              final availableDepartments = filteredDepartments
                  .where((d) => !_selectedDepartments.contains(d))
                  .toList();

              // Durum mesajı
              String hintText = 'Önce alan türü seçin...';
              if (_selectedFieldType != null) {
                hintText = 'Bölüm ekle...';
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
                    onChanged: _selectedFieldType != null
                        ? (String? dept) {
                            if (dept != null) {
                              setState(() => _selectedDepartments.add(dept));
                            }
                          }
                        : (String? dept) {}, // Empty function instead of null
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
