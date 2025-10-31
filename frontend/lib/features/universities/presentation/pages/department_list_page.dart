import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/department_model.dart';
import '../widgets/department_card.dart';
import '../widgets/department_filter_bottom_sheet.dart';
import './department_detail_page.dart';

class DepartmentListPage extends ConsumerStatefulWidget {
  const DepartmentListPage({super.key});

  @override
  ConsumerState<DepartmentListPage> createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends ConsumerState<DepartmentListPage> {
  String _selectedField = 'Tümü';
  String _selectedCity = 'Tümü';
  String _selectedType = 'Tümü';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bölümler'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Bölüm ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          
          // Filter Chips
          if (_selectedField != 'Tümü' || _selectedCity != 'Tümü' || _selectedType != 'Tümü')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedField != 'Tümü')
                    Chip(
                      label: Text('Alan: $_selectedField'),
                      onDeleted: () {
                        setState(() {
                          _selectedField = 'Tümü';
                        });
                      },
                    ),
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
          
          // Department List
          Expanded(
            child: _buildDepartmentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentList() {
    // TODO: Replace with actual data from API
    final departments = _getMockDepartments();
    
    if (departments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Bölüm bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Filtreleri değiştirerek tekrar deneyin',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: departments.length,
      cacheExtent: 500, // ✅ Render edilmemiş widget'lar için cache
      itemBuilder: (context, index) {
        final department = departments[index];
        return DepartmentCard(
          department: department,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DepartmentDetailPage(
                  departmentId: department.id ?? 0,
                ),
              ),
            );
          },
        );
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
      builder: (context) => DepartmentFilterBottomSheet(
        selectedField: _selectedField,
        selectedCity: _selectedCity,
        selectedType: _selectedType,
        onApply: (field, city, type) {
          setState(() {
            _selectedField = field;
            _selectedCity = city;
            _selectedType = type;
          });
        },
      ),
    );
  }

  List<DepartmentModel> _getMockDepartments() {
    final mockData = [
      {
        'id': 1,
        'name': 'Bilgisayar Mühendisliği',
        'field_type': 'SAY',
        'university_id': 1,
        'universityName': 'İstanbul Teknik Üniversitesi',
        'city': 'İstanbul',
        'min_score': 450.0,
        'min_rank': 1500,
        'quota': 120,
        'tuition_fee': 0.0,
        'has_scholarship': false,
        'language': 'Türkçe',
      },
      {
        'id': 2,
        'name': 'Elektrik Mühendisliği',
        'field_type': 'SAY',
        'university_id': 2,
        'universityName': 'Boğaziçi Üniversitesi',
        'city': 'İstanbul',
        'min_score': 480.0,
        'min_rank': 800,
        'quota': 80,
        'tuition_fee': 0.0,
        'has_scholarship': false,
        'language': 'Türkçe',
      },
      {
        'id': 3,
        'name': 'Endüstri Mühendisliği',
        'field_type': 'EA',
        'university_id': 3,
        'universityName': 'Orta Doğu Teknik Üniversitesi',
        'city': 'Ankara',
        'min_score': 460.0,
        'min_rank': 1200,
        'quota': 100,
        'tuition_fee': 0.0,
        'has_scholarship': false,
        'language': 'Türkçe',
      },
      {
        'id': 4,
        'name': 'İşletme',
        'field_type': 'EA',
        'university_id': 4,
        'universityName': 'Koç Üniversitesi',
        'city': 'İstanbul',
        'min_score': 420.0,
        'min_rank': 2000,
        'quota': 60,
        'tuition_fee': 85000.0,
        'has_scholarship': true,
        'language': 'İngilizce',
      },
      {
        'id': 5,
        'name': 'Psikoloji',
        'field_type': 'EA',
        'university_id': 5,
        'universityName': 'Sabancı Üniversitesi',
        'city': 'İstanbul',
        'min_score': 440.0,
        'min_rank': 1800,
        'quota': 40,
        'tuition_fee': 90000.0,
        'has_scholarship': true,
        'language': 'İngilizce',
      },
    ];
    return mockData.map((json) => DepartmentModel.fromJson(json)).toList();
  }
}
