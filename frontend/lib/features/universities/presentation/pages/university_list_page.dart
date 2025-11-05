import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/university_model.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/providers/university_api_provider.dart';
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
      ),
    );
  }

  Widget _buildUniversityList(BuildContext context) {
    // Gerçek API verilerini kullan
    final universitiesAsync = ref.watch(filteredUniversityListProvider(
      UniversityFilterParams(
        city: _selectedCity == 'Tümü' ? null : _selectedCity,
        type: _selectedType == 'Tümü' ? null : _selectedType,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
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
                  final universityData = universities[index];
                  final university = UniversityModel.fromJson(universityData);
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
