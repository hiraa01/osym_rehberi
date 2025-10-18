import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/searchable_dropdown.dart';
import '../../data/providers/university_api_provider.dart';

class DepartmentFilterBottomSheet extends ConsumerStatefulWidget {
  final String selectedField;
  final String selectedCity;
  final String selectedType;
  final Function(String field, String city, String type) onApply;

  const DepartmentFilterBottomSheet({
    super.key,
    required this.selectedField,
    required this.selectedCity,
    required this.selectedType,
    required this.onApply,
  });

  @override
  ConsumerState<DepartmentFilterBottomSheet> createState() => _DepartmentFilterBottomSheetState();
}

class _DepartmentFilterBottomSheetState extends ConsumerState<DepartmentFilterBottomSheet> {
  late String _selectedField;
  late String _selectedCity;
  late String _selectedType;

  final List<String> _fields = [
    'Tümü',
    'SAY',
    'EA',
    'SOZ',
    'DIL',
  ];

  final List<String> _types = [
    'Tümü',
    'devlet',
    'vakif',
  ];

  @override
  void initState() {
    super.initState();
    _selectedField = widget.selectedField;
    _selectedCity = widget.selectedCity;
    _selectedType = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Bölüm Filtreleri',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Field Filter
          Text(
            'Alan Türü',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fields.map((field) {
              final isSelected = _selectedField == field;
              return FilterChip(
                label: Text(_getFieldDisplayName(field)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedField = field;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // City Filter
          Text(
            'Şehir',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) {
              final citiesAsync = ref.watch(cityListProvider);
              return citiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Şehirler yüklenemedi'),
                data: (cities) {
                  final allCities = ['Tümü', ...cities];
                  return SearchableDropdown<String>(
                    items: allCities,
                    itemAsString: (item) => item,
                    selectedItem: _selectedCity,
                    hintText: 'Şehir seçiniz',
                    searchHintText: 'Şehir ara...',
                    onChanged: (city) {
                      if (city != null) {
                        setState(() => _selectedCity = city);
                      }
                    },
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Type Filter
          Text(
            'Üniversite Türü',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedField, _selectedCity, _selectedType);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Filtreleri Uygula',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'SAY':
        return 'SAY (Sayısal)';
      case 'EA':
        return 'EA (Eşit Ağırlık)';
      case 'SÖZ':
        return 'SÖZ (Sözel)';
      case 'DİL':
        return 'DİL (Dil)';
      default:
        return field;
    }
  }
}
