import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/searchable_dropdown.dart';
import '../../../auth/data/providers/auth_service.dart';
import '../../../universities/data/providers/university_api_provider.dart';

class PreferencesSelectionStep extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onPreferencesCompleted;
  final VoidCallback onBack;

  const PreferencesSelectionStep({
    super.key,
    required this.onPreferencesCompleted,
    required this.onBack,
  });

  @override
  ConsumerState<PreferencesSelectionStep> createState() =>
      _PreferencesSelectionStepState();
}

class _PreferencesSelectionStepState
    extends ConsumerState<PreferencesSelectionStep> {
  final List<String> _selectedCities = [];
  final List<String> _selectedDepartments = [];
  String _fieldType = 'SAY'; // EA, SAY, SÖZ, DİL

  bool _isLoading = false;

  Future<void> _complete() async {
    if (_selectedCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir şehir seçiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir bölüm seçiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kullanıcı setup tamamlandı olarak işaretle
      final authService = getAuthService(ApiService());
      await authService.updateUser(
        isInitialSetupCompleted: true,
      );

      final preferences = {
        'cities': _selectedCities,
        'departments': _selectedDepartments,
        'field_type': _fieldType,
      };

      widget.onPreferencesCompleted(preferences);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(cityListProvider);
    final departmentsAsync = ref.watch(departmentListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tercihleriniz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hangi şehirlerde ve hangi bölümlerde okumak istersiniz?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Alan türü seçimi
          const Text(
            'Alan Türünüz',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['SAY', 'EA', 'SÖZ', 'DİL'].map((field) {
              final isSelected = _fieldType == field;
              return ChoiceChip(
                label: Text(field),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _fieldType = field;
                    _selectedDepartments.clear();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Şehir seçimi
          const Text(
            'Tercih Ettiğiniz Şehirler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          citiesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Şehirler yüklenemedi: $error'),
                  TextButton(
                    onPressed: () => ref.refresh(cityListProvider),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
            data: (cities) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ Arama yapılabilir dropdown
                SearchableDropdown<String>(
                  items: cities.where((c) => !_selectedCities.contains(c)).toList(),
                  itemAsString: (item) => item,
                  hintText: 'Şehir ekle...',
                  searchHintText: 'Şehir ara (örn: ankara)',
                  onChanged: (city) {
                    if (city != null) {
                      setState(() => _selectedCities.add(city));
                    }
                  },
                ),
                if (_selectedCities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCities.map((city) {
                      return Chip(
                        label: Text(city),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _selectedCities.remove(city));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bölüm seçimi
          const Text(
            'İlgilendiğiniz Bölümler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          departmentsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Bölümler yüklenemedi: $error'),
                  TextButton(
                    onPressed: () => ref.refresh(departmentListProvider),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
            data: (departments) {
              // Alan türüne göre bölümleri filtrele
              final filteredDepartments = departments
                  .where((dept) => dept.fieldType == _fieldType)
                  .map((dept) => dept.name)
                  .toSet()
                  .toList()
                ..sort(); // ✅ Alfabetik sırala

              final availableDepartments = filteredDepartments
                  .where((d) => !_selectedDepartments.contains(d))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ Arama yapılabilir dropdown
                  SearchableDropdown<String>(
                    items: availableDepartments,
                    itemAsString: (item) => item,
                    hintText: 'Bölüm ekle...',
                    searchHintText: 'Bölüm ara (örn: bilgisayar)',
                    onChanged: (dept) {
                      if (dept != null) {
                        setState(() => _selectedDepartments.add(dept));
                      }
                    },
                  ),
                  if (_selectedDepartments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedDepartments.map((deptName) {
                        return Chip(
                          label: Text(deptName),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() => _selectedDepartments.remove(deptName));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Geri'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _complete,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Tamamla',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

