import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/student_form_provider.dart';

class StudentFormStep1 extends ConsumerWidget {
  const StudentFormStep1({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(studentFormProvider);
    final formNotifier = ref.read(studentFormProvider.notifier);
    // Ensure hydration once when the widget builds
    // ignore: unused_result
    formNotifier.hydrateFromSession();
    final student = formState.student;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temel Bilgiler',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // Name Field
          TextFormField(
            initialValue: student.name,
            decoration: const InputDecoration(
              labelText: 'Ad Soyad *',
              hintText: 'Adınızı ve soyadınızı girin',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => formNotifier.updateField('name', value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ad soyad gereklidir';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Email Field
          TextFormField(
            initialValue: student.email ?? '',
            decoration: const InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@email.com',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => formNotifier.updateField('email', value.isEmpty ? null : value),
          ),
          const SizedBox(height: 16),
          
          // Phone Field
          TextFormField(
            initialValue: student.phone ?? '',
            decoration: const InputDecoration(
              labelText: 'Telefon',
              hintText: '0555 123 45 67',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 11,
            onChanged: (value) {
              // Only allow numbers
              final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (filtered.length <= 11) {
                formNotifier.updateField('phone', filtered.isEmpty ? null : filtered);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Class Level Dropdown
          DropdownButtonFormField<String>(
            initialValue: student.classLevel,
            decoration: const InputDecoration(
              labelText: 'Sınıf Seviyesi *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '12', child: Text('12. Sınıf')),
              DropdownMenuItem(value: 'mezun', child: Text('Mezun')),
            ],
            onChanged: (value) {
              if (value != null) {
                formNotifier.updateField('classLevel', value);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Exam Type Dropdown
          DropdownButtonFormField<String>(
            initialValue: student.examType,
            decoration: const InputDecoration(
              labelText: 'Sınav Türü *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'TYT', child: Text('Sadece TYT')),
              DropdownMenuItem(value: 'AYT', child: Text('Sadece AYT')),
              DropdownMenuItem(value: 'TYT+AYT', child: Text('TYT + AYT')),
            ],
            onChanged: (value) {
              if (value != null) {
                formNotifier.updateField('examType', value);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Field Type Dropdown
          DropdownButtonFormField<String>(
            initialValue: student.fieldType,
            decoration: const InputDecoration(
              labelText: 'Alan Türü *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'SAY', child: Text('SAY (Sayısal)')),
              DropdownMenuItem(value: 'EA', child: Text('EA (Eşit Ağırlık)')),
              DropdownMenuItem(value: 'SÖZ', child: Text('SÖZ (Sözel)')),
              DropdownMenuItem(value: 'DİL', child: Text('DİL (Dil)')),
            ],
            onChanged: (value) {
              if (value != null) {
                formNotifier.updateField('fieldType', value);
              }
            },
          ),
        ],
      ),
    );
  }
}
