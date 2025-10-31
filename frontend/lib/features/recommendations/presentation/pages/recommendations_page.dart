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
        title: const Text('Tercih Önerilerim'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('PDF Olarak Dışa Aktar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Excel Olarak Dışa Aktar'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.share),
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
            // Bilgi Kartı
            Card(
              color: Colors.blue.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Puanlarınıza ve tercihlerinize göre size özel üniversite önerileri',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filtreler
            Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final citiesAsync = ref.watch(cityListProvider);
                    return citiesAsync.when(
                      data: (cities) {
                        final allCities = ['Tüm Şehirler', ...cities];
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Şehir',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: allCities.map((city) {
                            return DropdownMenuItem(
                              value: city == 'Tüm Şehirler' ? 'all' : city,
                              child: Text(city),
                            );
                          }).toList(),
                          value: _selectedCity,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCity = value);
                            }
                          },
                        );
                      },
                      loading: () => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Şehir',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [DropdownMenuItem(value: 'all', child: Text('Yükleniyor...'))],
                        value: 'all',
                        onChanged: null,
                      ),
                      error: (error, stack) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Şehir',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [DropdownMenuItem(value: 'all', child: Text('Hata'))],
                        value: 'all',
                        onChanged: null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final universityTypesAsync = ref.watch(universityTypeListProvider);
                    return universityTypesAsync.when(
                      data: (types) {
                        final allTypes = ['Tümü', ...types];
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Üniversite Türü',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: allTypes.map((type) {
                            return DropdownMenuItem(
                              value: type == 'Tümü' ? 'all' : type,
                              child: Text(type),
                            );
                          }).toList(),
                          value: _selectedType,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedType = value);
                            }
                          },
                        );
                      },
                      loading: () => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Üniversite Türü',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [DropdownMenuItem(value: 'all', child: Text('Yükleniyor...'))],
                        value: 'all',
                        onChanged: null,
                      ),
                      error: (error, stack) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Üniversite Türü',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [DropdownMenuItem(value: 'all', child: Text('Hata'))],
                        value: 'all',
                        onChanged: null,
                      ),
                    );
                  },
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
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: InkWell(
                                          onTap: () {},
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade100,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '${finalScore.toStringAsFixed(0)}% Uyum',
                                                        style: TextStyle(
                                                          color: Colors.green.shade700,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    IconButton(
                                                      onPressed: () => _toggleBookmark(recId),
                                                      icon: Icon(
                                                        isBookmarked
                                                            ? Icons.bookmark
                                                            : Icons.bookmark_border,
                                                        color: isBookmarked
                                                            ? Theme.of(context).primaryColor
                                                            : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                const SizedBox(height: 12),
                                Text(
                                  dept?['name'] ?? 'Bilinmeyen Bölüm',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  uni?['name'] ?? 'Bilinmeyen Üniversite',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      Icons.location_on,
                                      uni?['city'] ?? '-',
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      Icons.school,
                                      uni?['university_type'] ?? '-',
                                      Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      Icons.trending_up,
                                      dept?['min_score']?.toStringAsFixed(1) ?? '-',
                                      Colors.purple,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

