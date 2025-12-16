import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../data/models/university_model.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/providers/university_api_provider.dart';
import '../../../../core/services/api_service.dart';
import '../widgets/university_card.dart';
import '../widgets/university_filter_bottom_sheet.dart';

class UniversityListPage extends ConsumerStatefulWidget {
  const UniversityListPage({super.key});

  @override
  ConsumerState<UniversityListPage> createState() => _UniversityListPageState();
}

class _UniversityListPageState extends ConsumerState<UniversityListPage> {
  String _selectedCity = 'Tümü';
  String _selectedType = 'Tümü';
  String _searchQuery = '';
  List<String>? _preferredCities;
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadPreferredCities();
  }

  Future<void> _loadPreferredCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');
      
      if (studentId != null) {
        final apiService = ApiService();
        final response = await apiService.getStudent(studentId);
        
        if (response.statusCode == 200 && response.data != null) {
          final studentData = response.data as Map<String, dynamic>;
          final preferredCities = studentData['preferred_cities'];
          
          if (preferredCities != null) {
            List<String> cities;
            if (preferredCities is String) {
              // JSON string ise parse et
              cities = List<String>.from(jsonDecode(preferredCities));
            } else if (preferredCities is List) {
              cities = List<String>.from(preferredCities);
            } else {
              cities = [];
            }
            
            setState(() {
              _preferredCities = cities;
              _isLoadingPreferences = false;
            });
            
            debugPrint('🟢 Preferred cities loaded: $_preferredCities');
          } else {
            setState(() {
              _preferredCities = null;
              _isLoadingPreferences = false;
            });
            debugPrint('⚠️ No preferred cities found');
          }
        } else {
          setState(() {
            _preferredCities = null;
            _isLoadingPreferences = false;
          });
        }
      } else {
        setState(() {
          _preferredCities = null;
          _isLoadingPreferences = false;
        });
        debugPrint('⚠️ No student_id found');
      }
    } catch (e) {
      debugPrint('🔴 Error loading preferred cities: $e');
      setState(() {
        _preferredCities = null;
        _isLoadingPreferences = false;
      });
    }
  }

  Widget _buildBody(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        return Column(
          children: [
            // ✅ Tercih edilen şehirler bilgi kartı
            if (_preferredCities != null && _preferredCities!.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tercih ettiğiniz şehirlerdeki üniversiteler gösteriliyor: ${_preferredCities!.join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Search Bar
            Padding(
              padding: ResponsiveUtils.getResponsivePadding(context),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Üniversite ara...',
                    prefixIcon: Icon(
                      Icons.search,
                      size: ResponsiveUtils.getResponsiveIconSize(context, 24),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getResponsiveSpacing(context, 16),
                      vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
          
              // Filter Chips
              if (_selectedCity != 'Tümü' || _selectedType != 'Tümü')
                Padding(
                  padding: ResponsiveUtils.getResponsiveHorizontalPadding(context),
                  child: Wrap(
                    spacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
                    children: [
                      if (_selectedCity != 'Tümü')
                        Chip(
                          label: Text('Şehir: $_selectedCity'),
                          onDeleted: () {
                            setState(() {
                              _selectedCity = 'Tümü';
                            });
                          },
                        ),
                      if (_selectedType != 'Tümü')
                        Chip(
                          label: Text('Tür: $_selectedType'),
                          onDeleted: () {
                            setState(() {
                              _selectedType = 'Tümü';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              
            // University List
            Expanded(
              child: _buildUniversityList(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üniversiteler'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      // ✅ Tercih edilen şehirler bilgisi
      body: _isLoadingPreferences
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildUniversityList(BuildContext context) {
    // ✅ Öğrencinin tercih ettiği şehirleri kullan
    // Eğer tercih edilen şehirler varsa, sadece onları göster
    // Eğer yoksa veya "Tümü" seçilmişse, tüm üniversiteleri göster
    String? cityFilter;
    
    if (_preferredCities != null && _preferredCities!.isNotEmpty) {
      // Tercih edilen şehirler varsa ve kullanıcı "Tümü" seçmemişse
      if (_selectedCity == 'Tümü') {
        // Tercih edilen şehirlerden birini seç (ilk şehir)
        // Ama aslında tüm tercih edilen şehirlerdeki üniversiteleri göstermek için
        // provider'ı güncellememiz gerekiyor
        cityFilter = null; // Tüm tercih edilen şehirleri göstermek için null
      } else {
        // Kullanıcı özel bir şehir seçmişse, onu kullan
        cityFilter = _selectedCity;
      }
    } else {
      // Tercih edilen şehir yoksa, normal filtreleme
      cityFilter = _selectedCity == 'Tümü' ? null : _selectedCity;
    }
    
    // Gerçek API verilerini kullan
    final universitiesAsync = ref.watch(filteredUniversityListProvider(
      UniversityFilterParams(
        city: cityFilter,
        type: _selectedType == 'Tümü' ? null : _selectedType,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        preferredCities: _preferredCities, // ✅ Tercih edilen şehirleri ekle
      ),
    ));
    
    return universitiesAsync.when(
      data: (universities) {
        if (universities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: ResponsiveUtils.getResponsiveIconSize(context, 64),
                  color: Colors.grey,
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                Text(
                  'Üniversite bulunamadı',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                Text(
                  'Filtreleri değiştirerek tekrar deneyin',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  ),
                ),
              ],
            ),
          );
        }

        return ResponsiveBuilder(
          builder: (context, deviceType) {
            if (deviceType == DeviceType.mobile) {
              // Mobile: List view
              return ListView.builder(
                padding: ResponsiveUtils.getResponsivePadding(context),
                itemCount: universities.length,
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  final universityData = universities[index];
                  final university = UniversityModel.fromJson(universityData);
                  return UniversityCard(
                    university: university,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${university.name} detayı henüz hazır değil'),
                        ),
                      );
                    },
                  );
                },
              );
            } else {
              // Tablet/Desktop: Grid view
              return GridView.builder(
                padding: ResponsiveUtils.getResponsivePadding(context),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveUtils.getGridColumns(context),
                  crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                  mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                  childAspectRatio: 1.2,
                ),
                itemCount: universities.length,
                itemBuilder: (context, index) {
                  final universityData = universities[index];
                  final university = UniversityModel.fromJson(universityData);
                  return UniversityCard(
                    university: university,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${university.name} detayı henüz hazır değil'),
                        ),
                      );
                    },
                  );
                },
              );
            }
          },
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
            Text(
              'Üniversiteler yükleniyor...',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveUtils.getResponsiveIconSize(context, 64),
              color: Colors.red,
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
            Text(
              'Üniversiteler yüklenirken hata oluştu',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
            Text(
              error.toString(),
              style: TextStyle(
                color: Colors.grey,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UniversityFilterBottomSheet(
        selectedCity: _selectedCity,
        selectedType: _selectedType,
        onApply: (city, type) {
          setState(() {
            _selectedCity = city;
            _selectedType = type;
          });
        },
      ),
    );
  }

}
