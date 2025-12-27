import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../universities/data/providers/university_api_provider.dart';
import '../../../universities/presentation/pages/university_discover_page.dart';
import '../../../student_profile/data/providers/student_api_provider.dart';

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


  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 DEBUG: GoalsPage build called');
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
          // Tab Content - ✅ CRITICAL FIX: IndexedStack ile cache'leme + AutomaticKeepAliveClientMixin
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _DepartmentsTabWidget(
                  searchQuery: _departmentSearchQuery,
                  selectedFieldType: _selectedFieldType,
                  onSearchChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _departmentSearchQuery = value;
                      });
                    }
                  },
                  onFieldTypeChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _selectedFieldType = value;
                      });
                    }
                  },
                ),
                _UniversitiesTabWidget(
                  searchQuery: _universitySearchQuery,
                  onSearchChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _universitySearchQuery = value;
                      });
                    }
                  },
                ),
              ],
            ),
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
                    onPressed: () async {
                      // ✅ Öğrencinin tercih ettiği şehirleri al
                      List<String>? preferredCities;
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final studentId = prefs.getInt('student_id');
                        if (studentId != null) {
                          final studentAsync =
                              ref.read(studentDetailProvider(studentId));
                          await studentAsync.when(
                            data: (student) {
                              preferredCities = student.preferredCities;
                              return null;
                            },
                            loading: () => null,
                            error: (_, __) => null,
                          );
                        }
                      } catch (e) {
                        debugPrint('🔴 Error loading preferred cities: $e');
                      }

                      // ✅ UniversityDiscoverPage'e tercih edilen şehirleri gönder
                      // ✅ BuildContext async gap kontrolü
                      if (!mounted) return;
                      final navigatorContext = context;
                      Navigator.of(navigatorContext).push(
                        MaterialPageRoute(
                          builder: (_) => UniversityDiscoverPage(
                            preferredCities: preferredCities,
                          ),
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
        if (mounted) {
          setState(() {
            _selectedTab = index;
          });
        }
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

}

// ✅ CRITICAL FIX: Ayrı StatefulWidget + AutomaticKeepAliveClientMixin ile sonsuz döngüyü önle
class _DepartmentsTabWidget extends ConsumerStatefulWidget {
  final String searchQuery;
  final String selectedFieldType;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFieldTypeChanged;

  const _DepartmentsTabWidget({
    required this.searchQuery,
    required this.selectedFieldType,
    required this.onSearchChanged,
    required this.onFieldTypeChanged,
  });

  @override
  ConsumerState<_DepartmentsTabWidget> createState() => _DepartmentsTabWidgetState();
}

class _DepartmentsTabWidgetState extends ConsumerState<_DepartmentsTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Tab değiştiğinde state'i koru

  @override
  void initState() {
    super.initState();
    // ✅ CRITICAL FIX: Sayfa ilk açıldığında veriyi bir kere iste
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider'ı tetiklemek için ref.read ile oku (FutureProvider otomatik tetiklenir)
      ref.read(departmentListProvider);
      debugPrint('🟢 _DepartmentsTabWidget: Provider tetiklendi');
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ AutomaticKeepAliveClientMixin için gerekli
    
    // ✅ CRITICAL FIX: Provider'ı sadece bir kere watch et, cache'i kullan
    final departmentAsync = ref.watch(departmentListProvider);

    return departmentAsync.when(
      data: (departments) {
        // Filtreleme
        final filteredDepartments = departments.where((dept) {
          final query = widget.searchQuery.toLowerCase();
          final deptName = (dept['name'] ?? dept['program_name'] ?? '')
              .toString()
              .toLowerCase();
          final uniName =
              (dept['university']?['name'] ?? '').toString().toLowerCase();
          final fieldType = dept['field_type']?.toString() ?? '';
          final matchesQuery =
              deptName.contains(query) || uniName.contains(query);
          final matchesFieldType =
              widget.selectedFieldType == 'ALL' || fieldType == widget.selectedFieldType;
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
                onChanged: widget.onSearchChanged,
              ),
            ),
            // Filtre butonları - Stitch Style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 'Sayısal', 'SAY'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Eşit Ağırlık', 'EA'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Sözel', 'SÖZ'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Dil', 'DİL'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Filtre', 'ALL', icon: Icons.filter_list),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Departman listesi
            Expanded(
              child: filteredDepartments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Filtrelere uygun bölüm bulunamadı',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Arama terimini veya filtreleri değiştirmeyi deneyin',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredDepartments.length,
                      cacheExtent:
                          500, // ✅ Render edilmemiş widget'lar için cache
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
                                (uni?['name'] ?? 'Ü')
                                    .substring(0, 1)
                                    .toUpperCase(),
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
      error: (error, stack) {
        debugPrint('🔴 Error loading departments: $error');
        debugPrint('🔴 Stack: $stack');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Bölümler yüklenirken hata oluştu',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(departmentListProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildFilterChip(BuildContext context, String label, String value, {IconData? icon}) {
    final isSelected = widget.selectedFieldType == value;
    final theme = Theme.of(context);
    return FilterChip(
      label: icon != null ? Icon(icon, size: 18) : Text(label),
      selected: isSelected,
      onSelected: (selected) {
        widget.onFieldTypeChanged(selected ? value : 'SAY');
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
}

// ✅ CRITICAL FIX: Ayrı StatefulWidget + AutomaticKeepAliveClientMixin ile sonsuz döngüyü önle
class _UniversitiesTabWidget extends ConsumerStatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _UniversitiesTabWidget({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  ConsumerState<_UniversitiesTabWidget> createState() => _UniversitiesTabWidgetState();
}

class _UniversitiesTabWidgetState extends ConsumerState<_UniversitiesTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Tab değiştiğinde state'i koru

  @override
  void initState() {
    super.initState();
    // ✅ CRITICAL FIX: Sayfa ilk açıldığında veriyi bir kere iste
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider'ı tetiklemek için ref.read ile oku (FutureProvider otomatik tetiklenir)
      // filteredUniversityListProvider zaten universityListProvider'a bağlı, sadece base provider'ı tetiklemek yeterli
      ref.read(universityListProvider);
      debugPrint('🟢 _UniversitiesTabWidget: Provider tetiklendi');
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ AutomaticKeepAliveClientMixin için gerekli
    
    // ✅ CRITICAL FIX: Provider'ı sadece bir kere watch et, cache'i kullan
    final universityAsync = ref.watch(universityListProvider);

    return universityAsync.when(
      data: (universities) {
        // Filtreleme
        final filteredUniversities = universities.where((uni) {
          final query = widget.searchQuery.toLowerCase();
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
                onChanged: widget.onSearchChanged,
              ),
            ),
            // Üniversite listesi
            Expanded(
              child: filteredUniversities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Filtrelere uygun üniversite bulunamadı',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Arama terimini veya filtreleri değiştirmeyi deneyin',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUniversities.length,
                      cacheExtent:
                          500, // ✅ Render edilmemiş widget'lar için cache
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${uni['city']} • ${uni['university_type']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
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
      error: (error, stack) {
        debugPrint('🔴 Error loading departments: $error');
        debugPrint('🔴 Stack: $stack');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Bölümler yüklenirken hata oluştu',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(departmentListProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        );
      },
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
