import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/university_model.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../widgets/university_card.dart';
import '../widgets/university_filter_bottom_sheet.dart';

@RoutePage()
class UniversityListPage extends ConsumerStatefulWidget {
  const UniversityListPage({super.key});

  @override
  ConsumerState<UniversityListPage> createState() => _UniversityListPageState();
}

class _UniversityListPageState extends ConsumerState<UniversityListPage> {
  String _selectedCity = 'Tümü';
  String _selectedType = 'Tümü';

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
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          return Column(
            children: [
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
                    // TODO: Implement search functionality
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
      ),
    );
  }

  Widget _buildUniversityList(BuildContext context) {
    // TODO: Replace with actual data from API
    final universities = _getMockUniversities();
    
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
            itemBuilder: (context, index) {
              final university = universities[index];
              return UniversityCard(
                university: university,
                onTap: () {
                  // TODO: Navigate to university detail
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
              final university = universities[index];
              return UniversityCard(
                university: university,
                onTap: () {
                  // TODO: Navigate to university detail
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

  List<UniversityModel> _getMockUniversities() {
    final mockData = [
      {
        'id': 1,
        'name': 'İstanbul Teknik Üniversitesi',
        'city': 'İstanbul',
        'university_type': 'Devlet',
        'website': 'https://www.itu.edu.tr',
        'logo_url': '',
        'description': 'Türkiye\'nin en köklü teknik üniversitesi',
      },
      {
        'id': 2,
        'name': 'Boğaziçi Üniversitesi',
        'city': 'İstanbul',
        'university_type': 'Devlet',
        'website': 'https://www.boun.edu.tr',
        'logo_url': '',
        'description': 'Türkiye\'nin en prestijli üniversitelerinden biri',
      },
      {
        'id': 3,
        'name': 'Orta Doğu Teknik Üniversitesi',
        'city': 'Ankara',
        'university_type': 'Devlet',
        'website': 'https://www.metu.edu.tr',
        'logo_url': '',
        'description': 'Türkiye\'nin önde gelen teknik üniversitesi',
      },
      {
        'id': 4,
        'name': 'Koç Üniversitesi',
        'city': 'İstanbul',
        'university_type': 'Vakıf',
        'website': 'https://www.ku.edu.tr',
        'logo_url': '',
        'description': 'Türkiye\'nin önde gelen vakıf üniversitesi',
      },
      {
        'id': 5,
        'name': 'Sabancı Üniversitesi',
        'city': 'İstanbul',
        'university_type': 'Vakıf',
        'website': 'https://www.sabanciuniv.edu',
        'logo_url': '',
        'description': 'İnovatif eğitim anlayışı ile öne çıkan üniversite',
      },
    ];
    return mockData.map((json) => UniversityModel.fromJson(json)).toList();
  }
}
