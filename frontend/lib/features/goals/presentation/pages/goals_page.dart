import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../universities/data/providers/university_api_provider.dart';
import 'university_swipe_page.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  int _selectedTab = 0; // 0: Bölümler, 1: Üniversiteler
  String _departmentSearchQuery = '';
  String _universitySearchQuery = '';
  String _selectedFieldType = 'SAY'; // Filtre için seçili alan türü

  @override
  void initState() {
    super.initState();
  }

  Widget _buildFilterChip(String label, String value, {IconData? icon}) {
    final isSelected = _selectedFieldType == value;
    final theme = Theme.of(context);
    return FilterChip(
      label: icon != null ? Icon(icon, size: 18) : Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFieldType = selected ? value : 'SAY';
        });
      },
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _selectedTab == 0 ? 'Bölümler' : 'Üniversiteler',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Bar - Stitch Style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'Bölümler',
                    0,
                    Icons.school,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    'Üniversiteler',
                    1,
                    Icons.account_balance,
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
          // Alt butonlar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UniversitySwipePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.school, size: 20),
                    label: const Text('Üniversiteleri Keşfet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Rehber koç sayfasına git
                    },
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
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
          final deptName = (dept['name'] ?? dept['program_name'] ?? '')
              .toString()
              .toLowerCase();
          final uniName =
              (dept['university']?['name'] ?? '').toString().toLowerCase();
          final fieldType = dept['field_type']?.toString() ?? '';
          final matchesQuery =
              deptName.contains(query) || uniName.contains(query);
          final matchesFieldType =
              _selectedFieldType == 'ALL' || fieldType == _selectedFieldType;
          return matchesQuery && matchesFieldType;
        }).toList();

        return Column(
          children: [
            // Arama barı - Stitch Style
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Bölüm veya üniversite ara...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {
                    _departmentSearchQuery = value;
                  });
                },
              ),
            ),
            // Filtre butonları - Stitch Style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Sayısal', 'SAY'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Eşit Ağırlık', 'EA'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sözel', 'SÖZ'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Dil', 'DİL'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Filtre', 'ALL', icon: Icons.filter_list),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Departman listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredDepartments.length,
                cacheExtent: 500, // ✅ Render edilmemiş widget'lar için cache
                itemBuilder: (context, index) {
                  final dept = filteredDepartments[index];
                  final uni = dept['university'] as Map<String, dynamic>?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          (uni?['name'] ?? 'Ü').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        dept['name'] ??
                            dept['program_name'] ??
                            'Bilinmeyen Bölüm',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          uni?['name'] ?? 'Bilinmeyen Üniversite',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.star_border,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Favori ekle/kaldır özelliği eklenecek
                        },
                      ),
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
                cacheExtent: 500, // ✅ Render edilmemiş widget'lar için cache
                itemBuilder: (context, index) {
                  final uni = filteredUniversities[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.05),
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance,
                              color: Colors.blue, size: 22),
                        ),
                        title: Text(
                          uni['name'] ?? 'Bilinmeyen Üniversite',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${uni['city']} • ${uni['university_type']}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        onTap: () => _showUniversityDetails(context, uni),
                      ),
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
    final uni = dept['university'] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dept['name'] ?? dept['program_name'] ?? 'Bilinmeyen Bölüm'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Üniversite', uni?['name'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Şehir', uni?['city'] ?? 'Belirtilmemiş'),
              _buildDetailRow(
                  'Alan Türü', dept['field_type'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Dil', dept['language'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Süre', '${dept['duration'] ?? 4} yıl'),
              _buildDetailRow('Kontenjan', '${dept['quota'] ?? 0}'),
              _buildDetailRow(
                  'Min Puan', dept['min_score']?.toString() ?? 'Belirtilmemiş'),
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
              _buildDetailRow(
                  'Üniversite Türü', uni['university_type'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Kuruluş Yılı',
                  '${uni['established_year'] ?? 'Belirtilmemiş'}'),
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
