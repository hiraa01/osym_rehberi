import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/providers/university_api_provider.dart';
import '../widgets/department_filter_bottom_sheet.dart';

class DepartmentListPage extends ConsumerStatefulWidget {
  const DepartmentListPage({super.key});

  @override
  ConsumerState<DepartmentListPage> createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends ConsumerState<DepartmentListPage> {
  String _selectedField = 'Tümü';
  String _selectedCity = 'Tümü';
  String _selectedType = 'Tümü';
  String _searchQuery = '';

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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Bölüm ara...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.pink),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter Chips
          if (_selectedField != 'Tümü' ||
              _selectedCity != 'Tümü' ||
              _selectedType != 'Tümü')
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
    final field = _selectedField == 'Tümü' ? null : _selectedField;
    final city = _selectedCity == 'Tümü' ? null : _selectedCity;
    final type = _selectedType == 'Tümü' ? null : _selectedType;

    final departmentsAsync = ref.watch(
      filteredDepartmentListProvider(
        DepartmentFilterParams(
          fieldType: field,
          city: city,
          universityType: type,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        ),
      ),
    );

    return departmentsAsync.when(
      data: (departments) {
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

        // Aynı bölüm isimlerini grupla (burslu olanlar ayrı, normal olanlar tek kartta)
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final dept in departments) {
          final name =
              (dept['program_name'] as String? ?? dept['name'] as String? ?? '')
                  .trim();
          if (name.isEmpty) continue;
          final hasScholarship = (dept['has_scholarship'] as bool? ?? false);
          // Burslu olanlar ayrı grup, normal olanlar tek grup
          final key = hasScholarship
              ? '${name.toLowerCase()}|burslu'
              : name.toLowerCase();
          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(dept);
        }

        final groupList = grouped.entries.map((e) {
          final firstDept = e.value.first;
          final displayName = firstDept['program_name'] as String? ??
              firstDept['name'] as String? ??
              '';
          final hasScholarship =
              (firstDept['has_scholarship'] as bool? ?? false);
          final finalName =
              hasScholarship ? '$displayName (Burslu)' : displayName;
          return _DepartmentGroup(name: finalName, items: e.value);
        }).toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupList.length,
          cacheExtent: 500,
          itemBuilder: (context, index) {
            final group = groupList[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: Colors.pink.withValues(alpha: 0.2),
                  child: Text(
                    group.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${group.items.length} üniversitede bulunuyor',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.star_border, color: Colors.pink),
                  onPressed: () => _addDepartmentToPreferences(group.name),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DepartmentGroupPage(
                      group: group,
                      onFavorite: () => _addDepartmentToPreferences(group.name),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Bölümler yüklenemedi')),
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

  Future<void> _addDepartmentToPreferences(String deptName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');
      if (studentId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Önce giriş yapın.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final key = 'preferred_departments_$studentId';
      final existing = prefs.getString(key);
      final List<String> current = existing != null
          ? List<String>.from(jsonDecode(existing) as List)
          : [];
      if (!current.contains(deptName)) {
        current.add(deptName);
        await prefs.setString(key, jsonEncode(current));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deptName tercihlere eklendi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DepartmentGroup {
  final String name;
  final List<Map<String, dynamic>> items;

  _DepartmentGroup({required this.name, required this.items});
}

class DepartmentGroupPage extends StatelessWidget {
  final _DepartmentGroup group;
  final VoidCallback onFavorite;

  const DepartmentGroupPage({
    super.key,
    required this.group,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.pink),
            onPressed: () {
              onFavorite();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${group.name} tercihlere eklendi'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: group.items.length,
        itemBuilder: (context, index) {
          final item = group.items[index];
          final uniName = item['university_name'] as String? ?? 'Üniversite';
          final city = item['city'] as String? ?? '-';
          final field = item['field_type'] as String? ?? '-';
          final minScore = item['min_score']?.toString() ?? '-';
          final minRank = item['min_rank']?.toString() ?? '-';
          final language = item['language'] as String? ?? '';
          final scholarship =
              (item['has_scholarship'] as bool? ?? false) ? 'Burslu' : '—';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                child: Text(
                  uniName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                uniName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$city • $field • Dil: $language',
                style: TextStyle(color: Colors.grey[400]),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Taban: $minScore',
                      style: const TextStyle(color: Colors.white)),
                  Text('Sıralama: $minRank',
                      style: const TextStyle(color: Colors.white)),
                  Text(
                    scholarship,
                    style: TextStyle(
                      fontSize: 12,
                      color: scholarship == 'Burslu'
                          ? Colors.green
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
