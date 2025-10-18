import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';

class AddExamAttemptPage extends StatefulWidget {
  const AddExamAttemptPage({super.key});

  @override
  State<AddExamAttemptPage> createState() => _AddExamAttemptPageState();
}

class _AddExamAttemptPageState extends State<AddExamAttemptPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  
  String _selectedDepartmentType = 'SAY';
  final Map<String, Map<String, int>> _answers = {}; // correct/wrong answers
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentFieldType();
  }

  // ✅ Öğrencinin field_type'ını yükle
  Future<void> _loadStudentFieldType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');
      
      if (studentId != null) {
        final response = await _apiService.getStudent(studentId);
        final fieldType = response.data['field_type'] as String?;
        if (fieldType != null && mounted) {
          setState(() {
            _selectedDepartmentType = fieldType;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading field_type: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _examNameController.dispose();
    super.dispose();
  }

  // Net hesaplama: Net = Doğru - (Yanlış / 4)
  double _calculateNet(String key) {
    final correct = _answers[key]?['correct'] ?? 0;
    final wrong = _answers[key]?['wrong'] ?? 0;
    return correct - (wrong / 4.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Yeni Deneme Ekle'),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Deneme Ekle'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Deneme Adı
              TextFormField(
                controller: _examNameController,
                decoration: const InputDecoration(
                  labelText: 'Deneme Adı',
                  hintText: 'Örn: TYT Deneme 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen deneme adını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Bölüm Tipi Seçimi
              const Text(
                'Bölüm Türü',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'SAY', label: Text('SAY')),
                  ButtonSegment(value: 'EA', label: Text('EA')),
                  ButtonSegment(value: 'SOZ', label: Text('SÖZ')),
                  ButtonSegment(value: 'DIL', label: Text('DİL')),
                ],
                selected: {_selectedDepartmentType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedDepartmentType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 32),

              // TYT Netleri
              const Text(
                'TYT Soruları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuestionInput('Türkçe', 'tyt_turkish_net', 40),
              _buildQuestionInput('Matematik', 'tyt_math_net', 40),
              _buildQuestionInput('Sosyal Bilimler', 'tyt_social_net', 20),
              _buildQuestionInput('Fen Bilimleri', 'tyt_science_net', 20),
              const SizedBox(height: 24),

              // AYT Netleri
              _buildAYTSection(),
              const SizedBox(height: 32),

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _isSaving ? null : _saveExamAttempt,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAYTSection() {
    switch (_selectedDepartmentType) {
      case 'SAY':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'AYT Soruları (Sayısal)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuestionInput('Matematik', 'ayt_math_net', 40),
            _buildQuestionInput('Fizik', 'ayt_physics_net', 14),
            _buildQuestionInput('Kimya', 'ayt_chemistry_net', 13),
            _buildQuestionInput('Biyoloji', 'ayt_biology_net', 13),
          ],
        );
      case 'SOZ':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'AYT Soruları (Sözel)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuestionInput('Edebiyat', 'ayt_literature_net', 24),
            _buildQuestionInput('Tarih-1', 'ayt_history1_net', 10),
            _buildQuestionInput('Coğrafya-1', 'ayt_geography1_net', 6),
          ],
        );
      case 'EA':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'AYT Soruları (Eşit Ağırlık)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuestionInput('Matematik', 'ayt_math_net', 40),
            _buildQuestionInput('Edebiyat', 'ayt_literature_net', 24),
            _buildQuestionInput('Tarih-1', 'ayt_history1_net', 10),
            _buildQuestionInput('Coğrafya-1', 'ayt_geography1_net', 6),
          ],
        );
      case 'DIL':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'AYT Soruları (Dil)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuestionInput('Yabancı Dil', 'ayt_language_net', 80),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuestionInput(String label, String key, int maxQuestions) {
    return StatefulBuilder(
      builder: (context, setCardState) {
        final correct = _answers[key]?['correct'] ?? 0;
        final wrong = _answers[key]?['wrong'] ?? 0;
        final net = _calculateNet(key);
    
        return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ders adı ve net
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Net: ${net.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Doğru ve Yanlış inputları
            Row(
              children: [
                // Doğru
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doğru',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: correct > 0 ? correct.toString() : '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: '/$maxQuestions',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          final correctValue = int.tryParse(value) ?? 0;
                          if (correctValue <= maxQuestions) {
                            setCardState(() {
                              _answers[key] = {
                                'correct': correctValue,
                                'wrong': _answers[key]?['wrong'] ?? 0,
                              };
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Yanlış
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yanlış',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: wrong > 0 ? wrong.toString() : '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: '/$maxQuestions',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          final wrongValue = int.tryParse(value) ?? 0;
                          if (wrongValue <= maxQuestions) {
                            setCardState(() {
                              _answers[key] = {
                                'correct': _answers[key]?['correct'] ?? 0,
                                'wrong': wrongValue,
                              };
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  void _saveExamAttempt() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        int? studentId = prefs.getInt('student_id');
        
        // Net'leri hesapla
        final Map<String, double> nets = {};
        _answers.forEach((key, value) {
          nets[key] = _calculateNet(key);
        });
        
        // Eğer student_id yoksa, önce student oluştur
        if (studentId == null) {
          final userId = prefs.getInt('user_id');
          if (userId != null) {
            try {
              final studentResponse = await _apiService.createStudent({
                'user_id': userId,
                'name': prefs.getString('user_name') ?? 'Öğrenci',
                'school': 'Lise',
                'grade': 12,
                'class_level': '12',
                'exam_type': 'TYT+AYT',
                'field_type': _selectedDepartmentType,
                ...nets,
              });
              studentId = studentResponse.data['id'] as int;
              await prefs.setInt('student_id', studentId);
            } catch (e) {
              debugPrint('Student creation error: $e');
            }
          }
        }
        
        if (studentId != null) {
          // Deneme sayısını al
          final attemptsResponse = await _apiService.getStudentAttempts(studentId);
          final attempts = attemptsResponse.data['attempts'] ?? [];
          final attemptNumber = attempts.length + 1;
          
          // Deneme kaydet
          await _apiService.createExamAttempt({
            'student_id': studentId,
            'attempt_number': attemptNumber,
            'exam_name': _examNameController.text.trim(),  // ✅ Deneme adı eklendi
            'exam_type': 'TYT-AYT',
            'exam_date': DateTime.now().toIso8601String(),
            ...nets,
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Deneme başarıyla kaydedildi!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('Student ID bulunamadı');
        }
      } catch (e) {
        debugPrint('Save exam attempt error: $e');
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
          setState(() => _isSaving = false);
        }
      }
    }
  }
}
