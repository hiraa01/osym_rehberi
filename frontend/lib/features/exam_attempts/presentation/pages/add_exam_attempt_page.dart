import 'dart:convert';
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

  String _selectedDepartmentType = 'SAY'; // SAY, EA, SÖZ, DİL
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
                  ButtonSegment(value: 'SÖZ', label: Text('SÖZ')),
                  ButtonSegment(value: 'DİL', label: Text('DİL')),
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
      case 'SÖZ':
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
            _buildQuestionInput('Tarih-2', 'ayt_history2_net', 11),
            _buildQuestionInput('Coğrafya-2', 'ayt_geography2_net', 11),
            _buildQuestionInput('Felsefe', 'ayt_philosophy_net', 12),
            _buildQuestionInput('Din Kültürü', 'ayt_religion_net', 6),
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
      case 'DİL':
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
            _buildQuestionInput('Yabancı Dil', 'ayt_foreign_language_net', 80),
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
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calculate,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Net Hesaplaması',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Net: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                net.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                            maxLength: maxQuestions.toString().length,
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
                              counterText: '', // Sayaç metnini gizle
                            ),
                            validator: (value) {
                              final intValue = int.tryParse(value ?? '') ?? 0;
                              if (intValue > maxQuestions) {
                                return 'Maksimum $maxQuestions olabilir';
                              }
                              return null;
                            },
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
                            maxLength: maxQuestions.toString().length,
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
                              counterText: '', // Sayaç metnini gizle
                            ),
                            validator: (value) {
                              final intValue = int.tryParse(value ?? '') ?? 0;
                              if (intValue > maxQuestions) {
                                return 'Maksimum $maxQuestions olabilir';
                              }
                              return null;
                            },
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
          // Deneme sayısını al (retry mekanizması ile)
          try {
            // ✅ attempt_number backend tarafında otomatik hesaplanıyor - göndermeye gerek yok
            // Deneme kaydet (retry mekanizması ile)
            final response = await _apiService.createExamAttempt({
              'student_id': studentId,
              'exam_name': _examNameController.text.trim().isEmpty
                  ? 'Deneme'
                  : _examNameController.text.trim(), // ✅ Deneme adı eklendi
              'exam_date': DateTime.now().toIso8601String(),
              ...nets,
            });

            // ✅ Yeni denemeyi cache'e ekle (student_id'ye özel)
            try {
              final prefs = await SharedPreferences.getInstance();
              final cacheKey = 'exam_attempts_cache_$studentId';
              final cachedJson = prefs.getString(cacheKey);

              if (cachedJson != null) {
                final cached = jsonDecode(cachedJson) as List;
                // Backend'den yeni denemeyi al ve cache'e ekle
                final newAttempt = response.data as Map<String, dynamic>;
                cached.add(newAttempt);
                await prefs.setString(cacheKey, jsonEncode(cached));
              } else {
                // Cache yoksa, yeni denemeyi tek başına kaydet
                final newAttempt = response.data as Map<String, dynamic>;
                await prefs.setString(cacheKey, jsonEncode([newAttempt]));
              }
            } catch (_) {
              // Cache güncelleme hatası - önemli değil
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deneme başarıyla kaydedildi!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            }
          } catch (e) {
            // Deneme sayısını alırken hata
            debugPrint('Error getting attempt count: $e');
            // Devam et - attempt_number = 1 olarak ayarla
            final attemptNumber = 1;

            // Deneme kaydet (retry mekanizması ile)
            final response = await _apiService.createExamAttempt({
              'student_id': studentId,
              'attempt_number': attemptNumber,
              'exam_name': _examNameController.text.trim().isEmpty
                  ? 'Deneme $attemptNumber'
                  : _examNameController.text.trim(),
              'exam_date': DateTime.now().toIso8601String(),
              ...nets,
            });

            // Cache'e ekle
            try {
              final prefs = await SharedPreferences.getInstance();
              final cacheKey = 'exam_attempts_cache_$studentId';
              final newAttempt = response.data as Map<String, dynamic>;
              await prefs.setString(cacheKey, jsonEncode([newAttempt]));
            } catch (_) {}

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deneme başarıyla kaydedildi!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            }
          }
        } else {
          throw Exception('Student ID bulunamadı');
        }
      } catch (e) {
        debugPrint('Save exam attempt error: $e');
        if (mounted) {
          String errorMessage = 'Deneme kaydedilemedi. ';
          if (e.toString().contains('Connection closed') ||
              e.toString().contains('unknown')) {
            errorMessage +=
                'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';
          } else if (e.toString().contains('timeout')) {
            errorMessage +=
                'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
          } else {
            errorMessage += 'Hata: ${e.toString()}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
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
