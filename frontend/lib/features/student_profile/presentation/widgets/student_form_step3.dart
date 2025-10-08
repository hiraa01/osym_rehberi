import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/student_form_provider.dart';
import '../../data/models/student_model.dart';

class StudentFormStep3 extends ConsumerWidget {
  const StudentFormStep3({super.key});

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
            'AYT Netleri',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'AYT sınavındaki net sayılarınızı girin (sadece girdiğiniz dersler)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // AYT Math
          TextFormField(
            initialValue: student.aytMathNet > 0 ? student.aytMathNet.toString() : '',
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
                formNotifier.updateField('aytMathNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT Physics
          TextFormField(
            initialValue: student.aytPhysicsNet > 0 ? student.aytPhysicsNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Fizik Neti (Max: 14)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 14) {
                formNotifier.updateField('aytPhysicsNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT Chemistry
          TextFormField(
            initialValue: student.aytChemistryNet > 0 ? student.aytChemistryNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Kimya Neti (Max: 13)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 13) {
                formNotifier.updateField('aytChemistryNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT Biology
          TextFormField(
            initialValue: student.aytBiologyNet > 0 ? student.aytBiologyNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Biyoloji Neti (Max: 13)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 13) {
                formNotifier.updateField('aytBiologyNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT Literature
          TextFormField(
            initialValue: student.aytLiteratureNet > 0 ? student.aytLiteratureNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Edebiyat Neti (Max: 24)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 24) {
                formNotifier.updateField('aytLiteratureNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT History 1
          TextFormField(
            initialValue: student.aytHistory1Net > 0 ? student.aytHistory1Net.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Tarih 1 Neti (Max: 10)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 10) {
                formNotifier.updateField('aytHistory1Net', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT Geography 1
          TextFormField(
            initialValue: student.aytGeography1Net > 0 ? student.aytGeography1Net.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Coğrafya 1 Neti (Max: 6)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 6) {
                formNotifier.updateField('aytGeography1Net', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT Philosophy
          TextFormField(
            initialValue: student.aytPhilosophyNet > 0 ? student.aytPhilosophyNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Felsefe Neti (Max: 12)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 12) {
                formNotifier.updateField('aytPhilosophyNet', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT History 2
          TextFormField(
            initialValue: student.aytHistory2Net > 0 ? student.aytHistory2Net.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Tarih 2 Neti (Max: 11)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 11) {
                formNotifier.updateField('aytHistory2Net', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT Geography 2
          TextFormField(
            initialValue: student.aytGeography2Net > 0 ? student.aytGeography2Net.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Coğrafya 2 Neti (Max: 11)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 11) {
                formNotifier.updateField('aytGeography2Net', net);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // AYT Foreign Language
          TextFormField(
            initialValue: student.aytForeignLanguageNet > 0 ? student.aytForeignLanguageNet.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Yabancı Dil Neti (Max: 80)',
              hintText: '0.0',
              border: OutlineInputBorder(),
              suffixText: 'net',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final net = double.tryParse(value) ?? 0.0;
              if (net <= 80) {
                formNotifier.updateField('aytForeignLanguageNet', net);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // AYT Total Display
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
                  'AYT Toplam Net:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_calculateAytTotal(student).toStringAsFixed(1)} net',
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

  double _calculateAytTotal(StudentModel student) {
    return student.aytMathNet + 
           student.aytPhysicsNet + 
           student.aytChemistryNet + 
           student.aytBiologyNet +
           student.aytLiteratureNet +
           student.aytHistory1Net +
           student.aytGeography1Net +
           student.aytPhilosophyNet +
           student.aytHistory2Net +
           student.aytGeography2Net +
           student.aytForeignLanguageNet;
  }
}
