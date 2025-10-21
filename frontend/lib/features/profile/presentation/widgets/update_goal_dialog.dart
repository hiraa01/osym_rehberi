import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateGoalDialog extends StatefulWidget {
  const UpdateGoalDialog({super.key});

  @override
  State<UpdateGoalDialog> createState() => _UpdateGoalDialogState();
}

class _UpdateGoalDialogState extends State<UpdateGoalDialog> {
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Bölüm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'bilgisayar',
                  child: Text('Bilgisayar Mühendisliği', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'elektrik',
                  child: Text('Elektrik-Elektronik Müh.', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'hukuk',
                  child: Text('Hukuk', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'tip',
                  child: Text('Tıp', overflow: TextOverflow.ellipsis),
                ),
              ],
              value: _selectedDepartment,
              onChanged: (value) {
                setState(() => _selectedDepartment = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Şehir',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'istanbul', child: Text('İstanbul', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'ankara', child: Text('Ankara', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'izmir', child: Text('İzmir', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'bursa', child: Text('Bursa', overflow: TextOverflow.ellipsis)),
              ],
              value: _selectedCity,
              onChanged: (value) {
                setState(() => _selectedCity = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Üniversite (Opsiyonel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.apartment),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'itu',
                  child: Text('İstanbul Teknik Ünv.', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'odtu',
                  child: Text('ODTÜ', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'bogazici',
                  child: Text('Boğaziçi Ünv.', overflow: TextOverflow.ellipsis),
                ),
              ],
              value: _selectedUniversity,
              onChanged: (value) {
                setState(() => _selectedUniversity = value);
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

