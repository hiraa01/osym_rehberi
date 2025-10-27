import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../profile/presentation/widgets/update_goal_dialog.dart';
import '../../../universities/data/providers/university_api_provider.dart';
import '../../../../core/services/api_service.dart';
import 'university_swipe_page.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  String _targetDepartment = 'Henüz belirlenmedi';
  String _targetCity = '';
  int _selectedTab = 0; // 0: Bölümler, 1: Üniversiteler
  String _departmentSearchQuery = '';
  String _universitySearchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetDepartment = prefs.getString('target_department') ?? 'Henüz belirlenmedi';
      _targetCity = prefs.getString('target_city') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hedefim'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'Bölümler',
                    0,
                    Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTabButton(
                    'Üniversiteler',
                    1,
                    Icons.account_balance_outlined,
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: _selectedTab == 0
                ? _buildDepartmentsTab(context)
                : _buildUniversitiesTab(context),
          ),
          // Swipe butonu
          if (_selectedTab == 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UniversitySwipePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.swipe),
                label: const Text('Üniversiteleri Keşfet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.purple, width: 2)
              : Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.purple : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.purple : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDepartmentsTab(BuildContext context) {
    final departmentAsync = ref.watch(departmentListProvider);
    
    return departmentAsync.when(
      data: (departments) {
        // Filtreleme
        final filteredDepartments = departments.where((dept) {
          final query = _departmentSearchQuery.toLowerCase();
          return dept['program_name'].toString().toLowerCase().contains(query) ||
                 dept['faculty'].toString().toLowerCase().contains(query);
        }).toList();
        
        return Column(
          children: [
            // Arama barı
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Bölüm ara (örn: bilgisayar)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _departmentSearchQuery = value;
                  });
                },
              ),
            ),
            // Departman listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredDepartments.length,
                itemBuilder: (context, index) {
                  final dept = filteredDepartments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        child: const Icon(Icons.school, color: Colors.purple),
                      ),
                      title: Text(dept['program_name'] ?? 'Bilinmeyen Bölüm'),
                      subtitle: Text(
                        '${dept['faculty']} • ${dept['field_type']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showDepartmentDetails(context, dept),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Hata: $error')),
    );
  }
  
  Widget _buildUniversitiesTab(BuildContext context) {
    final universityAsync = ref.watch(universityListProvider);
    
    return universityAsync.when(
      data: (universities) {
        // Filtreleme
        final filteredUniversities = universities.where((uni) {
          final query = _universitySearchQuery.toLowerCase();
          return uni['name'].toString().toLowerCase().contains(query) ||
                 uni['city'].toString().toLowerCase().contains(query);
        }).toList();
        
        return Column(
          children: [
            // Arama barı
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Üniversite ara (örn: İstanbul)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _universitySearchQuery = value;
                  });
                },
              ),
            ),
            // Üniversite listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredUniversities.length,
                itemBuilder: (context, index) {
                  final uni = filteredUniversities[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.account_balance, color: Colors.blue),
                      ),
                      title: Text(uni['name'] ?? 'Bilinmeyen Üniversite'),
                      subtitle: Text(
                        '${uni['city']} • ${uni['university_type']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showUniversityDetails(context, uni),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Hata: $error')),
    );
  }
  
  void _showDepartmentDetails(BuildContext context, Map<String, dynamic> dept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dept['program_name'] ?? 'Bilinmeyen Bölüm'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Fakülte', dept['faculty'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Alan Türü', dept['field_type'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Eğitim Türü', dept['education_type'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Dil', dept['language'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Kontenjan', '${dept['total_quota'] ?? 0}'),
              _buildDetailRow('Min Puan (2024)', '${dept['min_score_2024'] ?? 'Belirtilmemiş'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
  
  void _showUniversityDetails(BuildContext context, Map<String, dynamic> uni) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(uni['name'] ?? 'Bilinmeyen Üniversite'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Şehir', uni['city'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Üniversite Türü', uni['university_type'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Kuruluş Yılı', '${uni['established_year'] ?? 'Belirtilmemiş'}'),
              if (uni['website'] != null)
                _buildDetailRow('Website', uni['website'] ?? 'Belirtilmemiş'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

