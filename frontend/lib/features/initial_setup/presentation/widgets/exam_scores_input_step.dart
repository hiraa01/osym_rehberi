import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExamScoresInputStep extends StatefulWidget {
  final int examCount;
  final String departmentType; // EA, SOZ, SAY, DIL
  final Function(List<Map<String, double>>) onScoresCompleted;
  final VoidCallback onBack;

  const ExamScoresInputStep({
    super.key,
    required this.examCount,
    required this.departmentType,
    required this.onScoresCompleted,
    required this.onBack,
  });

  @override
  State<ExamScoresInputStep> createState() => _ExamScoresInputStepState();
}

class _ExamScoresInputStepState extends State<ExamScoresInputStep> {
  final PageController _pageController = PageController();
  int _currentExamIndex = 0;
  late List<Map<String, double>> _allScores;

  @override
  void initState() {
    super.initState();
    _allScores = List.generate(
      widget.examCount,
      (_) => _getInitialScoresForFieldType(widget.departmentType),
    );
  }

  Map<String, double> _getInitialScoresForFieldType(String fieldType) {
    final baseScores = {
      'tyt_turkish_net': 0.0,
      'tyt_math_net': 0.0,
      'tyt_social_net': 0.0,
      'tyt_science_net': 0.0,
    };

    // Use a case-insensitive check for robustness
    final fieldTypeUpper = fieldType.toUpperCase();
    final normalizedType = fieldTypeUpper
        .replaceAll('Ö', 'O')
        .replaceAll('İ', 'I');

    if (normalizedType.startsWith('SAY')) {
      return {
        ...baseScores,
        'ayt_math_net': 0.0,
        'ayt_physics_net': 0.0,
        'ayt_chemistry_net': 0.0,
        'ayt_biology_net': 0.0,
      };
    } else if (normalizedType.startsWith('SOZ')) {
      return {
        ...baseScores,
        'ayt_literature_net': 0.0,
        'ayt_history1_net': 0.0,
        'ayt_geography1_net': 0.0,
        'ayt_history2_net': 0.0,
        'ayt_geography2_net': 0.0,
        'ayt_philosophy_net': 0.0,
        'ayt_religion_net': 0.0,
      };
    } else if (normalizedType.startsWith('EA')) {
      return {
        ...baseScores,
        'ayt_math_net': 0.0,
        'ayt_literature_net': 0.0,
        'ayt_history1_net': 0.0,
        'ayt_geography1_net': 0.0,
      };
    } else if (normalizedType.startsWith('DIL')) {
      return {
        ...baseScores,
        'ayt_foreign_language_net': 0.0,
      };
    } else {
      return baseScores;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextExam() {
    if (_currentExamIndex < widget.examCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentExamIndex++);
    } else {
      widget.onScoresCompleted(_allScores);
    }
  }

  void _previousExam() {
    if (_currentExamIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentExamIndex--);
    } else {
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deneme ${_currentExamIndex + 1} / ${widget.examCount}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((_currentExamIndex + 1) / widget.examCount * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.examCount,
            itemBuilder: (context, index) {
              return _buildExamScoreInput(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamScoreInput(int examIndex) {
    // Make the check case-insensitive for robustness
    final departmentTypeUpper = widget.departmentType.toUpperCase();
    
    // Normalize the type to handle Turkish characters properly
    final normalizedType = departmentTypeUpper
        .replaceAll('Ö', 'O')
        .replaceAll('İ', 'I');
    
    final showSayNetler = normalizedType.startsWith('SAY');
    final showSozNetler = normalizedType.startsWith('SOZ');
    final showEANetler = normalizedType.startsWith('EA');
    final showDilNetler = normalizedType.startsWith('DIL');
    
    // Debug: Type'ı yazdır
    debugPrint('🔍 Department Type: "${widget.departmentType}" -> Upper: "$departmentTypeUpper" -> Normalized: "$normalizedType"');
    debugPrint('🔍 showSozNetler: $showSozNetler');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TYT Netleri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNetInput('Türkçe', 'tyt_turkish_net', 40, examIndex),
          _buildNetInput('Matematik', 'tyt_math_net', 40, examIndex),
          _buildNetInput('Sosyal Bilimler', 'tyt_social_net', 20, examIndex),
          _buildNetInput('Fen Bilimleri', 'tyt_science_net', 20, examIndex),
          const SizedBox(height: 24),
          
          if (showSayNetler) ...[
            const Text(
              'AYT Netleri (Sayısal)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNetInput('Matematik', 'ayt_math_net', 40, examIndex),
            _buildNetInput('Fizik', 'ayt_physics_net', 14, examIndex),
            _buildNetInput('Kimya', 'ayt_chemistry_net', 13, examIndex),
            _buildNetInput('Biyoloji', 'ayt_biology_net', 13, examIndex),
          ] else if (showSozNetler) ...[
            const Text(
              'AYT Netleri (Sözel)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNetInput('Edebiyat', 'ayt_literature_net', 24, examIndex),
            _buildNetInput('Tarih-1', 'ayt_history1_net', 10, examIndex),
            _buildNetInput('Coğrafya-1', 'ayt_geography1_net', 6, examIndex),
            _buildNetInput('Tarih-2', 'ayt_history2_net', 11, examIndex),
            _buildNetInput('Coğrafya-2', 'ayt_geography2_net', 11, examIndex),
            _buildNetInput('Felsefe', 'ayt_philosophy_net', 12, examIndex),
            _buildNetInput('Din Kültürü', 'ayt_religion_net', 6, examIndex),
          ] else if (showEANetler) ...[
            const Text(
              'AYT Netleri (Eşit Ağırlık)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNetInput('Matematik', 'ayt_math_net', 40, examIndex),
            _buildNetInput('Edebiyat', 'ayt_literature_net', 24, examIndex),
            _buildNetInput('Tarih-1', 'ayt_history1_net', 10, examIndex),
            _buildNetInput('Coğrafya-1', 'ayt_geography1_net', 6, examIndex),
          ] else if (showDilNetler) ...[
            const Text(
              'AYT Netleri (Dil)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Correct the key for the language field
            _buildNetInput('Yabancı Dil', 'ayt_foreign_language_net', 80, examIndex),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (_currentExamIndex > 0 || examIndex == 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousExam,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Geri'),
                  ),
                ),
              if (_currentExamIndex > 0 || examIndex == 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextExam,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentExamIndex == widget.examCount - 1
                        ? 'Devam'
                        : 'Sonraki Deneme',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetInput(
    String label,
    String key,
    int maxQuestions,
    int examIndex,
  ) {
    final currentValue = _allScores[examIndex][key];
    final hasValue = currentValue != null && currentValue > 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: hasValue ? currentValue.toString() : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              maxLength: maxQuestions.toString().length + 3, 
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(color: Colors.grey[400]),
                suffixText: '/ $maxQuestions',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                counterText: '',
              ),
              validator: (value) {
                final netValue = double.tryParse(value ?? '') ?? 0.0;
                if (netValue > maxQuestions) {
                  return 'Maksimum $maxQuestions olabilir';
                }
                return null;
              },
              onChanged: (value) {
                final netValue = double.tryParse(value) ?? 0.0;
                if (netValue <= maxQuestions) {
                  setState(() {
                    _allScores[examIndex][key] = netValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}