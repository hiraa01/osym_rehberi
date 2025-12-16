import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import 'add_exam_attempt_page.dart';

class ExamAttemptsPage extends StatefulWidget {
  const ExamAttemptsPage({super.key});

  @override
  State<ExamAttemptsPage> createState() => _ExamAttemptsPageState();
}

class _ExamAttemptsPageState extends State<ExamAttemptsPage>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  List<dynamic> _attempts = [];
  bool _isLoading = true;
  int? _studentId;
  int? _lastKnownStudentId; // Son bilinen student_id'yi takip et

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAttempts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa görünür olduğunda student_id değişikliğini kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndReloadIfNeeded();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama foreground'a geldiğinde verileri yenile
    if (state == AppLifecycleState.resumed) {
      _checkAndReloadIfNeeded();
    }
  }

  // Student ID değiştiyse veya sayfa tekrar açıldıysa verileri yenile
  Future<void> _checkAndReloadIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStudentId = prefs.getInt('student_id');

      // Student ID değiştiyse veya ilk kez yükleniyorsa yenile
      if (currentStudentId != _lastKnownStudentId) {
        _lastKnownStudentId = currentStudentId;
        await _loadAttempts();
      }
    } catch (e) {
      debugPrint('Error checking student ID: $e');
    }
  }

  // Yerel cache'den denemeleri yükle (student_id'ye özel)
  Future<void> _loadCachedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');

      if (studentId != null) {
        // ✅ Student ID'ye özel cache key
        final cacheKey = 'exam_attempts_cache_$studentId';
        final cachedJson = prefs.getString(cacheKey);

        if (cachedJson != null) {
          final cached = jsonDecode(cachedJson) as List;
          if (mounted) {
            setState(() {
              _attempts = cached;
              _studentId = studentId; // Student ID'yi de kaydet
              _isLoading = false;
            });
          }
        }
      } else {
        // Student ID yoksa cache'i temizle (farklı kullanıcı olabilir)
        _clearOldCache(prefs);
      }
    } catch (e) {
      debugPrint('Error loading cached attempts: $e');
    }
  }

  // Eski cache'leri temizle (farklı kullanıcı için)
  Future<void> _clearOldCache(SharedPreferences prefs) async {
    try {
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('exam_attempts_cache_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing old cache: $e');
    }
  }

  // Denemeleri yerel cache'e kaydet (student_id'ye özel)
  Future<void> _saveAttemptsToCache(List<dynamic> attempts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');

      if (studentId != null) {
        // ✅ Student ID'ye özel cache key
        final cacheKey = 'exam_attempts_cache_$studentId';
        await prefs.setString(cacheKey, jsonEncode(attempts));
      }
    } catch (e) {
      debugPrint('Error saving attempts to cache: $e');
    }
  }

  Future<void> _loadAttempts() async {
    // Önce yerel cache'den yükle (hızlı görüntüleme için)
    await _loadCachedAttempts();

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStudentId = prefs.getInt('student_id');

      // Student ID yoksa veya değiştiyse cache'i temizle
      if (currentStudentId == null) {
        await _clearOldCache(prefs);
        if (mounted) {
          setState(() {
            _attempts = [];
            _studentId = null;
            _isLoading = false;
          });
        }
        return;
      }

      // Student ID değiştiyse cache'i temizle
      if (_studentId != null && _studentId != currentStudentId) {
        await _clearOldCache(prefs);
      }

      _studentId = currentStudentId;
      _lastKnownStudentId =
          currentStudentId; // Son bilinen student_id'yi kaydet

      // Backend'den güncel verileri yükle (retry mekanizması ile)
      final response = await _apiService.getStudentAttempts(_studentId!);
      final attempts = response.data['attempts'] ?? [];

      // Yerel cache'e kaydet
      await _saveAttemptsToCache(attempts);

      if (mounted) {
        setState(() {
          _attempts = attempts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attempts from backend: $e');

      // Kullanıcıya bilgi ver (sadece connection hataları için)
      if (mounted &&
          (e.toString().contains('Connection closed') ||
              e.toString().contains('unknown') ||
              e.toString().contains('timeout'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sunucuya bağlanılamadı. Cache\'deki veriler gösteriliyor.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Backend hatası olsa bile cache'deki veriler gösterildi
      // Ancak student_id yoksa veya değiştiyse boş liste göster
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final currentStudentId = prefs.getInt('student_id');
        if (currentStudentId == null || currentStudentId != _studentId) {
          setState(() {
            _attempts = [];
            _studentId = null;
          });
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Denemelerim',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddExamAttemptPage(),
                    ),
                  );
                  if (result == true) {
                    _loadAttempts();
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Deneme Ekle',
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attempts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAttempts,
                  child: _buildAttemptsList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Henüz deneme eklenmemiş',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'İlk denemenizi ekleyerek başlayın ve performansınızı takip edin',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddExamAttemptPage(),
                  ),
                );
                if (result == true) {
                  _loadAttempts();
                }
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Deneme Ekle'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attempts.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final attempt = _attempts[index];
        final attemptName = attempt['name'] ??
            'Deneme ${attempt['attempt_number'] ?? index + 1}';
        final tytNet = (attempt['tyt_turkish_net'] ?? 0.0) +
            (attempt['tyt_math_net'] ?? 0.0) +
            (attempt['tyt_social_net'] ?? 0.0) +
            (attempt['tyt_science_net'] ?? 0.0);
        final aytNet = (attempt['ayt_math_net'] ?? 0.0) +
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
            (attempt['ayt_foreign_language_net'] ?? 0.0);
        final tytScore = attempt['tyt_score']?.toDouble() ?? 0.0;
        final aytScore = attempt['ayt_score']?.toDouble() ?? 0.0;
        final totalScore = attempt['total_score']?.toDouble() ?? 0.0;
        final totalNet = tytNet + aytNet;
        final examDate = attempt['exam_date'] != null
            ? DateTime.tryParse(attempt['exam_date'].toString())
            : null;
        final dateStr = examDate != null
            ? '${examDate.day} ${_getMonthName(examDate.month)} ${examDate.year}'
            : '';

        // TYT veya AYT hangisi daha yüksekse ona göre badge
        final hasTyt = tytNet > 0;
        final hasAyt = aytNet > 0;
        final examType =
            hasTyt && hasAyt ? 'TYT+AYT' : (hasTyt ? 'TYT' : 'AYT');

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              // Detay sayfasına git
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                attemptName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                examType,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (hasTyt)
                          Text(
                            'TYT Net: ${tytNet.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        if (hasTyt && hasAyt) const SizedBox(height: 2),
                        if (hasAyt)
                          Text(
                            'AYT Net: ${aytNet.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        if (hasTyt || hasAyt) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Toplam Net: ${totalNet.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasTyt && tytScore > 0)
                        Text(
                          'TYT Puan: ${tytScore.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (hasAyt && aytScore > 0) ...[
                        if (hasTyt && tytScore > 0) const SizedBox(height: 4),
                        Text(
                          'AYT Puan: ${aytScore.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (totalScore > 0) ...[
                        if ((hasTyt && tytScore > 0) || (hasAyt && aytScore > 0))
                          const SizedBox(height: 4),
                        Text(
                          'Toplam Puan: ${totalScore.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month - 1];
  }
}
