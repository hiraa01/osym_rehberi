import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../universities/data/providers/university_api_provider.dart';

class UpdateGoalDialog extends ConsumerStatefulWidget {
  const UpdateGoalDialog({super.key});

  @override
  ConsumerState<UpdateGoalDialog> createState() => _UpdateGoalDialogState();
}

class _UpdateGoalDialogState extends ConsumerState<UpdateGoalDialog> {
  String? _selectedDepartment;
  String? _selectedCity;
  String? _selectedUniversity;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hedef Bölümümü Değiştir'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final departmentsAsync = ref.watch(departmentListProvider);
                return departmentsAsync.when(
                  data: (departments) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Bölüm',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      isExpanded: true,
                      items: departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept.name,
                          child: Text(dept.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      value: _selectedDepartment,
                      onChanged: (value) {
                        setState(() => _selectedDepartment = value);
                      },
                    );
                  },
                  loading: () => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Bölüm',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [DropdownMenuItem(value: 'loading', child: Text('Yükleniyor...'))],
                    value: 'loading',
                    onChanged: null,
                  ),
                  error: (error, stack) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Bölüm',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [DropdownMenuItem(value: 'error', child: Text('Hata'))],
                    value: 'error',
                    onChanged: null,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final citiesAsync = ref.watch(cityListProvider);
                return citiesAsync.when(
                  data: (cities) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Şehir',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      isExpanded: true,
                      items: cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      value: _selectedCity,
                      onChanged: (value) {
                        setState(() => _selectedCity = value);
                      },
                    );
                  },
                  loading: () => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [DropdownMenuItem(value: 'loading', child: Text('Yükleniyor...'))],
                    value: 'loading',
                    onChanged: null,
                  ),
                  error: (error, stack) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [DropdownMenuItem(value: 'error', child: Text('Hata'))],
                    value: 'error',
                    onChanged: null,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final universitiesAsync = ref.watch(universityListProvider);
                return universitiesAsync.when(
                  data: (universities) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Üniversite (Opsiyonel)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.apartment),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      isExpanded: true,
                      items: universities.map((uni) {
                        return DropdownMenuItem(
                          value: uni.name,
                          child: Text(uni.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      value: _selectedUniversity,
                      onChanged: (value) {
                        setState(() => _selectedUniversity = value);
                      },
                    );
                  },
                  loading: () => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Üniversite (Opsiyonel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.apartment),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [DropdownMenuItem(value: 'loading', child: Text('Yükleniyor...'))],
                    value: 'loading',
                    onChanged: null,
                  ),
                  error: (error, stack) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Üniversite (Opsiyonel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.apartment),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [DropdownMenuItem(value: 'error', child: Text('Hata'))],
                    value: 'error',
                    onChanged: null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _selectedDepartment != null && _selectedCity != null && !_isSaving
              ? () async {
                  setState(() => _isSaving = true);
                  
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('target_department', _selectedDepartment!);
                    await prefs.setString('target_city', _selectedCity!);
                    if (_selectedUniversity != null) {
                      await prefs.setString('target_university', _selectedUniversity!);
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hedef bölüm güncellendi!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                }
              : null,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}

