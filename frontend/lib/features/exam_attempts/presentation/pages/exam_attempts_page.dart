import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/stitch_theme.dart';
import 'add_exam_attempt_page.dart';
import 'exam_detail_page.dart';

/// Denemeler Sayfası - HTML Tasarımına Göre Yeniden Yapılandırıldı
/// Based on: frontend/stitch_anasayfa/denemeler_sayfası/code.html
class ExamAttemptsPage extends StatefulWidget {
  const ExamAttemptsPage({super.key});

  @override
  State<ExamAttemptsPage> createState() => _ExamAttemptsPageState();
}

class _ExamAttemptsPageState extends State<ExamAttemptsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _attempts = [];
  bool _isLoading = true;
  double _avgTyt = 0.0;
  double _avgAyt = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');

      if (studentId != null) {
        final response = await _apiService.getStudentAttempts(studentId);
        List<dynamic> attempts = [];

        if (response.statusCode == 200 && response.data != null) {
          // ✅ Backend formatı: {attempts: [...], total: ...} veya direkt List
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            attempts = data['attempts'] as List? ?? [];
            debugPrint('✅ Exam Attempts loaded: ${attempts.length} attempts from Map format');
          } else if (response.data is List) {
            attempts = response.data as List;
            debugPrint('✅ Exam Attempts loaded: ${attempts.length} attempts from List format');
          } else {
            debugPrint('⚠️ Exam Attempts: Unknown data format: ${response.data.runtimeType}');
          }
        } else {
          debugPrint('⚠️ Exam Attempts: Response status: ${response.statusCode}, data: ${response.data}');
        }

        // Ortalamaları hesapla
        if (attempts.isNotEmpty) {
          double totalTyt = 0.0;
          double totalAyt = 0.0;
          int count = 0;

          for (var attempt in attempts) {
            final tytNet = ((attempt['tyt_turkish_net'] ?? 0.0) +
                (attempt['tyt_math_net'] ?? 0.0) +
                (attempt['tyt_social_net'] ?? 0.0) +
                (attempt['tyt_science_net'] ?? 0.0));
            final aytNet = ((attempt['ayt_math_net'] ?? 0.0) +
                (attempt['ayt_physics_net'] ?? 0.0) +
                (attempt['ayt_chemistry_net'] ?? 0.0) +
                (attempt['ayt_biology_net'] ?? 0.0) +
                (attempt['ayt_literature_net'] ?? 0.0) +
                (attempt['ayt_history1_net'] ?? 0.0) +
                (attempt['ayt_geography1_net'] ?? 0.0) +
                (attempt['ayt_philosophy_net'] ?? 0.0) +
                (attempt['ayt_history2_net'] ?? 0.0) +
                (attempt['ayt_geography2_net'] ?? 0.0) +
                (attempt['ayt_religion_net'] ?? 0.0) +
                (attempt['ayt_foreign_language_net'] ?? 0.0));

            if (tytNet > 0 || aytNet > 0) {
              totalTyt += tytNet;
              totalAyt += aytNet;
              count++;
            }
          }

          if (count > 0) {
            _avgTyt = totalTyt / count;
            _avgAyt = totalAyt / count;
          }
        }

        // Cache'e kaydet
        final cacheKey = 'exam_attempts_cache_$studentId';
        await prefs.setString(cacheKey, jsonEncode(attempts));

        if (mounted) {
          setState(() {
            _attempts = attempts;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _attempts = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading attempts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteExamAttempt(Map<String, dynamic> attempt) async {
    try {
      final attemptId = attempt['id'] as int?;
      if (attemptId == null) return;

      await _apiService.deleteExamAttempt(attemptId);

      // Cache'den de sil
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');
      if (studentId != null) {
        final cacheKey = 'exam_attempts_cache_$studentId';
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          final cached = jsonDecode(cachedJson) as List;
          cached.removeWhere((item) => item['id'] == attemptId);
          await prefs.setString(cacheKey, jsonEncode(cached));
        }
      }

      await _loadAttempts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deneme başarıyla silindi')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting attempt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> attempt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emin misin?'),
        content: const Text('Bu deneme silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteExamAttempt(attempt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? StitchTheme.backgroundDark : StitchTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Header - HTML Tasarımına Göre
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? StitchTheme.backgroundDark : StitchTheme.surfaceLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.of(context).pop(),
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'Denemelerim',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: StitchTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // ✅ Main Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadAttempts,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Ortalama TYT ve AYT Kartları
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: StitchTheme.primary.withValues(alpha: 0.05),
                                      border: Border.all(
                                        color: StitchTheme.primary.withValues(alpha: 0.1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Ortalama TYT',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _avgTyt.toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: StitchTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: StitchTheme.primary.withValues(alpha: 0.05),
                                      border: Border.all(
                                        color: StitchTheme.primary.withValues(alpha: 0.1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Ortalama AYT',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _avgAyt.toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: StitchTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ✅ Son Denemeler Başlığı
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Son Denemeler',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Tümünü Gör',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: StitchTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ✅ Deneme Listesi
                            if (_attempts.isEmpty)
                              _buildEmptyState(isDark)
                            else
                              ..._attempts.map((attempt) {
                                return _buildAttemptCard(attempt, isDark);
                              }),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      // ✅ FAB Butonu - HTML Tasarımına Göre
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddExamAttemptPage()),
          );
          if (result == true) {
            _loadAttempts();
          }
        },
        backgroundColor: StitchTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAttemptCard(Map<String, dynamic> attempt, bool isDark) {
    final attemptName = attempt['exam_name'] as String? ?? 
                        attempt['name'] as String? ?? 
                        'Deneme';
    
    // TYT Net hesapla
    final tytNet = ((attempt['tyt_turkish_net'] ?? 0.0) +
        (attempt['tyt_math_net'] ?? 0.0) +
        (attempt['tyt_social_net'] ?? 0.0) +
        (attempt['tyt_science_net'] ?? 0.0));
    
    // AYT Net hesapla
    final aytNet = ((attempt['ayt_math_net'] ?? 0.0) +
        (attempt['ayt_physics_net'] ?? 0.0) +
        (attempt['ayt_chemistry_net'] ?? 0.0) +
        (attempt['ayt_biology_net'] ?? 0.0) +
        (attempt['ayt_literature_net'] ?? 0.0) +
        (attempt['ayt_history1_net'] ?? 0.0) +
        (attempt['ayt_geography1_net'] ?? 0.0) +
        (attempt['ayt_philosophy_net'] ?? 0.0) +
        (attempt['ayt_history2_net'] ?? 0.0) +
        (attempt['ayt_geography2_net'] ?? 0.0) +
        (attempt['ayt_religion_net'] ?? 0.0) +
        (attempt['ayt_foreign_language_net'] ?? 0.0));
    
    final totalNet = tytNet + aytNet;
    final totalScore = (attempt['total_score'] ?? 0.0).toDouble();
    
    // Tarih formatı
    String dateStr = '';
    if (attempt['exam_date'] != null) {
      try {
        final date = DateTime.parse(attempt['exam_date'].toString());
        dateStr = DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
      } catch (e) {
        dateStr = attempt['exam_date'].toString();
      }
    }
    
    // Badge rengi (TYT veya AYT)
    final hasTyt = tytNet > 0;
    final hasAyt = aytNet > 0;
    final badgeColor = hasTyt && hasAyt
        ? StitchTheme.primary
        : (hasTyt ? StitchTheme.primary : const Color(0xFF26A69A));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? StitchTheme.surfaceDark : StitchTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ✅ Sol tarafta renkli çizgi
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hasTyt && hasAyt ? 'TYT+AYT' : (hasTyt ? 'TYT' : 'AYT'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (dateStr.isNotEmpty)
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            attemptName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          totalNet.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                        Text(
                          'Net',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[100],
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 18,
                          color: badgeColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Puan: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        Text(
                          totalScore.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Sil Butonu
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.red,
                            onPressed: () => _showDeleteConfirmation(attempt),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Detay Butonu
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[50],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            color: isDark ? Colors.grey[400] : Colors.grey[400],
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExamDetailPage(attempt: attempt),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: isDark ? StitchTheme.surfaceDark.withValues(alpha: 0.5) : Colors.grey[50]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? StitchTheme.surfaceDark : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome,
              color: StitchTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Daha fazla veri, daha iyi öneriler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yapay zekanın seni daha iyi tanıması için deneme sonuçlarını girmeyi unutma.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
