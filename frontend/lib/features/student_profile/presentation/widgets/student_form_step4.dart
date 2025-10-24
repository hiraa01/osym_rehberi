import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/student_form_provider.dart';
import '../../../universities/data/providers/university_api_provider.dart';

class StudentFormStep4 extends ConsumerWidget {
  const StudentFormStep4({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(studentFormProvider);
    final formNotifier = ref.read(studentFormProvider.notifier);
    final student = formState.student;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tercihler',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Üniversite tercihlerinizi belirtin (isteğe bağlı)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Preferred Cities
          Text(
            'Tercih Edilen Şehirler',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildCityChips(context, student.preferredCities ?? [], formNotifier),
          const SizedBox(height: 24),
          
          // Preferred University Types
          Text(
            'Tercih Edilen Üniversite Türleri',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildUniversityTypeChips(context, student.preferredUniversityTypes ?? [], formNotifier),
          ),
          const SizedBox(height: 24),
          
          // Budget Preference
          DropdownButtonFormField<String>(
            value: student.budgetPreference,
            decoration: const InputDecoration(
              labelText: 'Bütçe Tercihi',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Belirtmek istemiyorum')),
              DropdownMenuItem(value: 'low', child: Text('Düşük (0-20.000 TL)')),
              DropdownMenuItem(value: 'medium', child: Text('Orta (20.000-50.000 TL)')),
              DropdownMenuItem(value: 'high', child: Text('Yüksek (50.000+ TL)')),
            ],
            onChanged: (value) {
              formNotifier.updateField('budgetPreference', value);
            },
          ),
          const SizedBox(height: 16),
          
          // Scholarship Preference
          SwitchListTile(
            title: const Text('Burs Tercihi'),
            subtitle: const Text('Burslu bölümleri tercih ederim'),
            value: student.scholarshipPreference,
            onChanged: (value) {
              formNotifier.updateField('scholarshipPreference', value);
            },
          ),
          const SizedBox(height: 24),
          
          // Interest Areas
          Text(
            'İlgi Alanları',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildInterestAreaChips(context, student.interestAreas ?? [], formNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChips(BuildContext context, List<String> selectedCities, formNotifier) {
    return Consumer(
      builder: (context, ref, child) {
        final citiesAsync = ref.watch(cityListProvider);
        return citiesAsync.when(
          data: (cities) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cities.map((city) {
                final isSelected = selectedCities.contains(city);
                return FilterChip(
                  label: Text(city),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newCities = List<String>.from(selectedCities);
                    if (selected) {
                      newCities.add(city);
                    } else {
                      newCities.remove(city);
                    }
                    formNotifier.updateField('preferredCities', newCities);
                  },
                );
              }).toList(),
            );
          },
          loading: () => const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text('Yükleniyor...'),
                selected: false,
                onSelected: null,
              ),
            ],
          ),
          error: (error, stack) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text('Hata: $error'),
                selected: false,
                onSelected: null,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildUniversityTypeChips(BuildContext context, List<String> selectedTypes, formNotifier) {
    final types = [
      {'value': 'devlet', 'label': 'Devlet Üniversitesi'},
      {'value': 'vakif', 'label': 'Vakıf Üniversitesi'},
      {'value': 'ozel', 'label': 'Özel Üniversite'},
    ];
    
    return types.map((type) {
      final isSelected = selectedTypes.contains(type['value']);
      return FilterChip(
        label: Text(type['label']!),
        selected: isSelected,
        onSelected: (selected) {
          final newTypes = List<String>.from(selectedTypes);
          if (selected) {
            newTypes.add(type['value']!);
          } else {
            newTypes.remove(type['value']!);
          }
          formNotifier.updateField('preferredUniversityTypes', newTypes);
        },
      );
    }).toList();
  }

  List<Widget> _buildInterestAreaChips(BuildContext context, List<String> selectedAreas, formNotifier) {
    final areas = [
      'Mühendislik', 'Tıp', 'Hukuk', 'İktisat', 'İşletme', 'Psikoloji', 'Eğitim',
      'Sanat', 'Spor', 'Teknoloji', 'Sosyal Bilimler', 'Fen Bilimleri', 'Sağlık'
    ];
    
    return areas.map((area) {
      final isSelected = selectedAreas.contains(area);
      return FilterChip(
        label: Text(area),
        selected: isSelected,
        onSelected: (selected) {
          final newAreas = List<String>.from(selectedAreas);
          if (selected) {
            newAreas.add(area);
          } else {
            newAreas.remove(area);
          }
          formNotifier.updateField('interestAreas', newAreas);
        },
      );
    }).toList();
  }
}
