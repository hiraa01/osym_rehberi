import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/export_service.dart';
import '../../../universities/data/providers/university_api_provider.dart';

class RecommendationsPage extends ConsumerStatefulWidget {
  const RecommendationsPage({super.key});

  @override
  ConsumerState<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _recommendations = [];
  bool _isLoading = true;
  String _selectedCity = 'all';
  String _selectedType = 'all';
  Set<int> _bookmarkedIds = {};
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_recommendations') ?? [];
    setState(() {
      _bookmarkedIds = bookmarks.map((e) => int.tryParse(e) ?? 0).toSet();
    });
  }

  Future<void> _toggleBookmark(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final isBookmarked = _bookmarkedIds.contains(id);
    setState(() {
      if (isBookmarked) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
    await prefs.setStringList(
      'bookmarked_recommendations',
      _bookmarkedIds.map((e) => e.toString()).toList(),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isBookmarked ? 'Kaydedildi!' : 'Kayıttan kaldırıldı',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _handleExport(String format) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentName = prefs.getString('user_name') ?? 'Öğrenci';
      
      // Öğrenci tercihlerini al
      final studentId = prefs.getInt('student_id');
      if (studentId == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Önce öğrenci profili oluşturun'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final studentResponse = await _apiService.getStudent(studentId);
      final preferredCities = List<String>.from(studentResponse.data['preferred_cities'] ?? []);
      final fieldType = studentResponse.data['field_type'] ?? 'SAY';
      
      // Bölümleri alan türüne göre filtrele
      final departmentsResponse = await _apiService.getDepartments();
      final allDepartments = (departmentsResponse.data as List)
          .map((dept) => dept['name'] as String)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      
      if (format == 'pdf') {
        await ExportService.exportPreferencesToPDF(
          cities: preferredCities,
          departments: allDepartments,
          fieldType: fieldType,
          studentName: studentName,
        );
      } else if (format == 'excel') {
        await ExportService.exportPreferencesToExcel(
          cities: preferredCities,
          departments: allDepartments,
          fieldType: fieldType,
          studentName: studentName,
        );
      }
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Tercih listesi ${format.toUpperCase()} olarak dışa aktarıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Dışa aktarma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecommendations({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');
      
      if (studentId != null) {
        // ✅ Yeniden hesaplama için önce eski önerileri temizle
        if (forceRefresh) {
          try {
            await _apiService.clearStudentRecommendations(studentId);
            debugPrint('✅ Eski öneriler temizlendi, yeni öneriler hesaplanıyor...');
          } catch (e) {
            debugPrint('⚠️ Eski öneriler temizlenirken hata (devam ediliyor): $e');
          }
        }
        
        final response = await _apiService.generateRecommendations(studentId, limit: 50);
        if (mounted) {
          setState(() {
            // Backend direkt liste döndürüyor (List[RecommendationResponse])
            final newRecommendations = response.data is List ? response.data : [];
            _recommendations = List.from(newRecommendations); // ✅ Yeni liste oluştur
            _isLoading = false;
          });
          
          // Debug: Hangi şehirlerde öneriler var?
          final citiesInRecommendations = <String>{};
          for (final rec in _recommendations) {
            final dept = rec['department'] as Map<String, dynamic>?;
            final university = dept?['university'] as Map<String, dynamic>?;
            final city = university?['city']?.toString() ?? 'Bilinmiyor';
            citiesInRecommendations.add(city);
          }
          debugPrint('✅ ${_recommendations.length} öneri yüklendi');
          debugPrint('📍 Önerilerde bulunan şehirler: ${citiesInRecommendations.toList()..sort()}');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Önce bir öğrenci profili oluşturun'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Recommendations error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öneriler yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Şehir ismini normalize et (Türkçe karakterleri düzelt, küçük harfe çevir, trim et)
  String _normalizeCityName(String city) {
    if (city.isEmpty) return '';
    
    // Türkçe karakterleri İngilizce karşılıklarına çevir
    String normalized = city
        .toLowerCase()
        .trim()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('İ', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('Ç', 'c');
    
    return normalized;
  }

  List<dynamic> get _filteredRecommendations {
    if (_selectedCity == 'all' && _selectedType == 'all') {
      return _recommendations; // Filtre yoksa tümünü döndür
    }
    
    final normalizedSelectedCity = _selectedCity != 'all' 
        ? _normalizeCityName(_selectedCity) 
        : '';
    
    return _recommendations.where((rec) {
      // Backend response: {department: {university: {...}}}
      final dept = rec['department'] as Map<String, dynamic>?;
      final university = dept?['university'] as Map<String, dynamic>?;
      final city = university?['city']?.toString() ?? '';
      final universityType = university?['university_type']?.toString() ?? '';
      
      // ✅ Şehir eşleştirmesi: Normalize edilmiş eşleşme
      bool matchesCity = _selectedCity == 'all';
      if (!matchesCity && city.isNotEmpty && normalizedSelectedCity.isNotEmpty) {
        final normalizedCity = _normalizeCityName(city);
        matchesCity = normalizedCity == normalizedSelectedCity || 
                     normalizedCity.contains(normalizedSelectedCity) ||
                     normalizedSelectedCity.contains(normalizedCity);
      }
      
      // ✅ Üniversite türü eşleştirmesi
      bool matchesType = _selectedType == 'all' || 
          universityType.toLowerCase().contains(_selectedType.toLowerCase());
      
      return matchesCity && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tercih Asistanım',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Ayarlar sayfasına git
            },
          ),
        ],
      ),
      body: _isLoading && _recommendations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Öneriler hesaplanıyor...\nBu işlem birkaç dakika sürebilir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Bilgi Kartı - Stitch Style
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Puanlarınıza ve tercihlerinize göre size özel üniversite önerileri',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filtreler - Stitch Style
            Row(
              children: [
                Expanded(
                  child: Consumer(
                  builder: (context, ref, child) {
                    final citiesAsync = ref.watch(cityListProvider);
                    return citiesAsync.when(
                      data: (cities) {
                          return OutlinedButton.icon(
                            onPressed: () => _showCityFilter(context, cities),
                            icon: const Icon(Icons.location_city, size: 18),
                            label: Text(
                              _selectedCity == 'all' ? 'Şehir Filtrele' : _selectedCity,
                              style: const TextStyle(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                        );
                      },
                        loading: () => OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Şehir Filtrele'),
                      ),
                        error: (_, __) => OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Şehir Filtrele'),
                      ),
                    );
                  },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer(
                  builder: (context, ref, child) {
                    final universityTypesAsync = ref.watch(universityTypeListProvider);
                    return universityTypesAsync.when(
                      data: (types) {
                          return OutlinedButton.icon(
                            onPressed: () => _showUniversityTypeFilter(context, types),
                            icon: const Icon(Icons.school, size: 18),
                            label: Text(
                              _selectedType == 'all' ? 'Üniversite Filtrele' : _selectedType,
                              style: const TextStyle(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                        );
                      },
                        loading: () => OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Üniversite Filtrele'),
                      ),
                        error: (_, __) => OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Üniversite Filtrele'),
                      ),
                    );
                  },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Öneriler Listesi
            Text(
              'Önerilen Bölümler (${_filteredRecommendations.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Gerçek Öneriler
            _filteredRecommendations.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Henüz öneri bulunmuyor'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredRecommendations.length,
                    cacheExtent: 500, // ✅ Render edilmemiş widget'lar için cache
                    itemBuilder: (context, index) {
                                      final rec = _filteredRecommendations[index];
                                      final dept = rec['department'] as Map<String, dynamic>?;
                                      final uni = dept?['university'] as Map<String, dynamic>?;
                                      final finalScore = (rec['final_score'] ?? rec['compatibility_score'] ?? 0.0).toDouble();
                                      final recId = rec['id'] ?? index;
                                      final isBookmarked = _bookmarkedIds.contains(recId);
                                      
                                      // Üniversite görseli URL'i (varsa)
                                      final imageUrl = uni?['image_url']?.toString() ?? 
                                          'https://images.unsplash.com/photo-1505761671935-60b3a7427bad?auto=format&fit=crop&w=800&q=80';
                                      final compatibilityPercent = (finalScore * 100).toInt();
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                              // Üniversite görseli
                                              Stack(
                                                  children: [
                                                    Container(
                                                    height: 180,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        image: NetworkImage(imageUrl),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  // Uyumluluk yüzdesi badge
                                                  Positioned(
                                                    top: 12,
                                                    right: 12,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '%$compatibilityPercent Uyumlu',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              // İçerik
                                              Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                Text(
                                  dept?['name'] ?? 'Bilinmeyen Bölüm',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                                      '${uni?['name'] ?? 'Bilinmeyen Üniversite'}, ${dept?['faculty'] ?? 'Fakülte'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Şehir: ${uni?['city'] ?? '-'}, Puan Türü: ${dept?['field_type'] ?? '-'}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                    ),
                                  ],
                                ),
                                              ),
                                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () async {
                await _loadRecommendations(forceRefresh: true);
              },
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Yeniden Hesaplanıyor...' : 'Yeniden Hesapla'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCityFilter(BuildContext context, List<String> cities) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Şehir Seçin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tüm Şehirler'),
                leading: Radio<String>(
                  value: 'all',
                  groupValue: _selectedCity,
                  onChanged: (value) {
                    setState(() => _selectedCity = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ...cities.map((city) {
                return ListTile(
                  title: Text(city),
                  leading: Radio<String>(
                    value: city,
                    groupValue: _selectedCity,
                    onChanged: (value) {
                      setState(() => _selectedCity = value!);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showUniversityTypeFilter(BuildContext context, List<String> types) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Üniversite Türü Seçin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tümü'),
                leading: Radio<String>(
                  value: 'all',
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ...types.map((type) {
                return ListTile(
                  title: Text(type),
                  leading: Radio<String>(
                    value: type,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

