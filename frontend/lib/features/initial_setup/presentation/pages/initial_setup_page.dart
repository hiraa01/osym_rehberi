import 'package:flutter/material.dart';

import '../widgets/department_type_selection_step.dart';
import '../widgets/exam_count_selection_step.dart';
import '../widgets/exam_scores_input_step.dart';
import '../widgets/preferences_selection_step.dart';
import '../../../main_layout/presentation/pages/main_layout_page.dart';

class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({super.key});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4; // Bölüm tipi seçimi eklendi

  String? _departmentType;
  int _examCount = 5;
  List<Map<String, double>>? _allExamScores; // Tüm denemelerin netleri

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlk Kurulum'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 1: Bölüm Tipi Seçimi
                DepartmentTypeSelectionStep(
                  initialType: _departmentType,
                  onTypeSelected: (type) {
                    setState(() => _departmentType = type);
                  },
                  onNext: _nextStep,
                ),
                // Step 2: Deneme Sayısı
                ExamCountSelectionStep(
                  initialCount: _examCount,
                  onCountSelected: (count) {
                    setState(() => _examCount = count);
                  },
                  onNext: _nextStep,
                ),
                // Step 3: Net Girişi
                Builder(
                  builder: (context) {
                    final deptType = _departmentType ?? 'SAY';
                    debugPrint('📝 Initial Setup: departmentType passed to ExamScoresInputStep: "$deptType"');
                    return ExamScoresInputStep(
                      examCount: _examCount,
                      departmentType: deptType,
                      onScoresCompleted: (scores) {
                        // Tüm deneme netlerini kaydet
                        setState(() => _allExamScores = scores);
                        _nextStep();
                      },
                      onBack: _previousStep,
                    );
                  },
                ),
                // Step 4: Tercihler
                PreferencesSelectionStep(
                  departmentType: _departmentType ?? 'SAY',
                  examScores: _allExamScores ?? [],
                  onPreferencesCompleted: (preferences) {
                    // Setup completed, go to main app
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const MainLayoutPage(),
                      ),
                    );
                  },
                  onBack: _previousStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

