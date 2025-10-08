import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/student_form_provider.dart';
import '../../data/models/student_model.dart';

class StudentFormStep2 extends ConsumerWidget {
  const StudentFormStep2({super.key});

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
            'TYT Netleri',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'TYT sınavındaki net sayılarınızı girin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // TYT Turkish
          TextFormField(
            initialValue: student.tytTurkishNet > 0 ? student.tytTurkishNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Türkçe Neti (Max: 40)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 40) {
                formNotifier.updateField('tytTurkishNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // TYT Math
          TextFormField(
            initialValue: student.tytMathNet > 0 ? student.tytMathNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Matematik Neti (Max: 40)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 40) {
                formNotifier.updateField('tytMathNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // TYT Social
          TextFormField(
            initialValue: student.tytSocialNet > 0 ? student.tytSocialNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Sosyal Bilimler Neti (Max: 20)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 20) {
                formNotifier.updateField('tytSocialNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // TYT Science
          TextFormField(
            initialValue: student.tytScienceNet > 0 ? student.tytScienceNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Fen Bilimleri Neti (Max: 20)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 20) {
                formNotifier.updateField('tytScienceNet', net);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // TYT Total Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TYT Toplam Net:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_calculateTytTotal(student).toStringAsFixed(1)} net',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTytTotal(StudentModel student) {
    return student.tytTurkishNet + 
           student.tytMathNet + 
           student.tytSocialNet + 
           student.tytScienceNet;
  }
}
