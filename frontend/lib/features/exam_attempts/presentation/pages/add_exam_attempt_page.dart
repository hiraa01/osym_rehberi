import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/data/providers/auth_service.dart';
import '../../../student_profile/presentation/pages/student_create_page.dart';

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
    _checkStudentIdAndLoad();
  }

  // ✅ GUARD: Student ID kontrolü - yoksa profil oluşturma sayfasına yönlendir
  Future<void> _checkStudentIdAndLoad() async {
    try {
      final authService = getAuthService(_apiService);
      
      // Önce cache'den kontrol et
      int? studentId = await authService.getStudentId();
      
      // Eğer student_id yoksa, backend'den bulmaya çalış
      if (studentId == null) {
        debugPrint('⚠️ No student_id in cache, trying to load from backend...');
        studentId = await authService.ensureStudentId();
      }
      
      // Hala yoksa, kullanıcıyı profil oluşturma sayfasına yönlendir
      if (studentId == null) {
        debugPrint('⚠️ Student ID not found, redirecting to profile creation page...');
        if (mounted) {
          // Kısa bir gecikme ile yönlendir (UI render için)
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const StudentCreatePage(),
              ),
            );
            // Kullanıcıya bilgi ver
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Deneme eklemek için önce profil oluşturmalısınız.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        return;
      }
      
      // Student ID bulundu, field_type'ı yükle
      await _loadStudentFieldType();
    } catch (e) {
      debugPrint('Error checking student ID: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

              // ✅ Alan Türü Bilgisi (Sadece Göster, Değiştirilemez)
              if (_selectedDepartmentType.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alan Türü: $_selectedDepartmentType',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

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
        // ✅ AUTO-REPAIR: Student ID'yi garanti et (her kayıt öncesi taze kontrol)
        final authService = getAuthService(_apiService);
        
        // Önce cache'den kontrol et
        int? studentId = await authService.getStudentId();
        
        // Cache'de yoksa veya geçersizse, backend'den taze olarak çek
        if (studentId == null) {
          debugPrint('⚠️ No student_id in cache, ensuring from backend...');
          studentId = await authService.ensureStudentId();
        } else {
          // Cache'de varsa, backend'den doğrula (sessizce)
          try {
            await _apiService.getStudent(studentId);
            debugPrint('✅ Cached student_id is valid: $studentId');
          } catch (_) {
            // Cache'deki ID geçersiz, backend'den taze çek
            debugPrint('⚠️ Cached student_id is invalid, refreshing from backend...');
            studentId = await authService.ensureStudentId();
          }
        }

        if (studentId == null) {
          // Student ID oluşturulamadı - kullanıcıyı profil oluşturma sayfasına yönlendir
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Deneme eklemek için önce profil oluşturmalısınız.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            // Kullanıcıyı profil oluşturma sayfasına yönlendir
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const StudentCreatePage(),
              ),
            );
          }
          return;
        }

        // Net'leri hesapla
        final Map<String, double> nets = {};
        _answers.forEach((key, value) {
          nets[key] = _calculateNet(key);
        });

        // Deneme sayısını al (retry mekanizması ile)
        try {
            // ✅ attempt_number backend tarafında otomatik hesaplanıyor - göndermeye gerek yok
            // Deneme kaydet (retry mekanizması ile)
            // ✅ attempt_number backend'de otomatik hesaplanıyor - göndermeye gerek yok
            // ✅ field_type backend'de öğrenciden alınıyor - göndermeye gerek yok
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
              // ✅ Backend'den dönen response'u al
              final attemptData = response.data as Map<String, dynamic>;
              
              // ✅ TYT ve AYT netlerini hesapla
              final tytTotalNet = (attemptData['tyt_turkish_net'] ?? 0.0) +
                  (attemptData['tyt_math_net'] ?? 0.0) +
                  (attemptData['tyt_social_net'] ?? 0.0) +
                  (attemptData['tyt_science_net'] ?? 0.0);
              
              final aytTotalNet = (attemptData['ayt_math_net'] ?? 0.0) +
                  (attemptData['ayt_physics_net'] ?? 0.0) +
                  (attemptData['ayt_chemistry_net'] ?? 0.0) +
                  (attemptData['ayt_biology_net'] ?? 0.0) +
                  (attemptData['ayt_literature_net'] ?? 0.0) +
                  (attemptData['ayt_history1_net'] ?? 0.0) +
                  (attemptData['ayt_geography1_net'] ?? 0.0) +
                  (attemptData['ayt_philosophy_net'] ?? 0.0) +
                  (attemptData['ayt_history2_net'] ?? 0.0) +
                  (attemptData['ayt_geography2_net'] ?? 0.0) +
                  (attemptData['ayt_religion_net'] ?? 0.0) +
                  (attemptData['ayt_foreign_language_net'] ?? 0.0);
              
              // ✅ Puanları al
              final tytScore = (attemptData['tyt_score'] ?? 0.0).toDouble();
              final aytScore = (attemptData['ayt_score'] ?? 0.0).toDouble();
              final totalScore = (attemptData['total_score'] ?? 0.0).toDouble();
              
              // ✅ Sonuç dialogunu göster
              _showResultDialog(
                context,
                tytTotalNet: tytTotalNet,
                aytTotalNet: aytTotalNet,
                tytScore: tytScore,
                aytScore: aytScore,
                totalScore: totalScore,
              );
            }
          } catch (e) {
            // Deneme kaydetme hatası
            debugPrint('Error creating exam attempt: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deneme kaydedilirken hata oluştu: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
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

  void _showResultDialog(
    BuildContext context, {
    required double tytTotalNet,
    required double aytTotalNet,
    required double tytScore,
    required double aytScore,
    required double totalScore,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Deneme Başarıyla Kaydedildi!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TYT Bilgileri
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TYT Sonuçları',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TYT Toplam Net:'),
                        Text(
                          tytTotalNet.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TYT Puanı:'),
                        Text(
                          tytScore.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // AYT Bilgileri
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AYT Sonuçları',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AYT Toplam Net:'),
                        Text(
                          aytTotalNet.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AYT Puanı:'),
                        Text(
                          aytScore.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Toplam Puan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Toplam Puan:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      totalScore.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialog'u kapat
              Navigator.of(context).pop(true); // Sayfayı kapat
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
