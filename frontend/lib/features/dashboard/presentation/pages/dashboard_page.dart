import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/api_service.dart';
import '../../../auth/data/providers/auth_service.dart';
import '../../../exam_attempts/presentation/pages/add_exam_attempt_page.dart';
import '../../../exam_attempts/presentation/pages/exam_attempts_page.dart';
import '../../../recommendations/presentation/pages/recommendations_page.dart';
import '../../../goals/presentation/pages/goals_page.dart';
import '../../../goals/presentation/pages/update_goal_page.dart';
import '../../../preferences/presentation/pages/my_preferences_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _totalAttempts = 0;
  double _totalNetAverage = 0.0; // Son 4 toplam net ortalaması
  double _tytAverage = 0.0; // Son 4 TYT ortalaması
  double _aytAverage = 0.0; // Son 4 AYT ortalaması
  final double _targetTotalNet = 100.0; // Hedef toplam net (TYT+AYT)
  double _progressPercent = 0.0; // Hedefe yakınlık yüzdesi
  List<Map<String, dynamic>> _recommendations = []; // Tercih önerileri
  Map<String, dynamic>? _lastAttempt;

  List<Map<String, dynamic>> _targetHighlights = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Cache'den denemeleri yükle ve dashboard'u hesapla
  void _calculateDashboardFromAttempts(List<Map<String, dynamic>> attempts) {
    _lastAttempt = attempts.isNotEmpty ? attempts.last : null;
    _totalAttempts = attempts.length;

    if (_totalAttempts > 0) {
      // Son 4 denemeyi al (varsa)
      final last4Attempts = attempts.length > 4
          ? attempts.sublist(attempts.length - 4)
          : attempts;

      double totalTyt = 0;
      double totalAyt = 0;

      for (var attempt in last4Attempts) {
        // TYT Net hesaplama
        final tytNet = (attempt['tyt_turkish_net'] ?? 0.0) +
            (attempt['tyt_math_net'] ?? 0.0) +
            (attempt['tyt_social_net'] ?? 0.0) +
            (attempt['tyt_science_net'] ?? 0.0);

        // AYT Net hesaplama (SAY için)
        final aytNet = (attempt['ayt_math_net'] ?? 0.0) +
            (attempt['ayt_physics_net'] ?? 0.0) +
            (attempt['ayt_chemistry_net'] ?? 0.0) +
            (attempt['ayt_biology_net'] ?? 0.0);

        totalTyt += tytNet;
        totalAyt += aytNet;
      }

      _tytAverage = totalTyt / last4Attempts.length;
      _aytAverage = totalAyt / last4Attempts.length;
      _totalNetAverage = _tytAverage + _aytAverage;

      // Hedefe yakınlık hesapla (%) - Net bazında
      _progressPercent =
          (_totalNetAverage / _targetTotalNet * 100).clamp(0.0, 100.0);
    } else {
      _tytAverage = 0.0;
      _aytAverage = 0.0;
      _totalNetAverage = 0.0;
      _progressPercent = 0.0;
    }
  }

  // Önce cache'den yükle (hızlı görüntüleme, student_id'ye özel)
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');

      if (studentId != null) {
        // ✅ Student ID'ye özel cache key
        final cacheKey = 'exam_attempts_cache_$studentId';
        final cachedJson = prefs.getString(cacheKey);

        if (cachedJson != null) {
          final cachedRaw = jsonDecode(cachedJson) as List;
          final cached = cachedRaw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(growable: false);
          _calculateDashboardFromAttempts(cached);
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached attempts for dashboard: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    // Önce cache'den yükle (hızlı görüntüleme)
    await _loadFromCache();

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');

      if (studentId != null) {
        // Backend'den güncel verileri yükle
        final attemptsResponse =
            await _apiService.getStudentAttempts(studentId);
        final attemptsRaw = (attemptsResponse.data['attempts'] ?? []) as List;
        final attempts = attemptsRaw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(growable: false);

        // Dashboard'u hesapla
        _calculateDashboardFromAttempts(attempts);

        // Tercih önerilerini yükle
        try {
          final recommendationsResponse =
              await _apiService.generateRecommendations(
            studentId,
            limit: 5, // İlk 5 öneri
          );
          final recsRaw = recommendationsResponse.data as List;
          _recommendations = recsRaw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(growable: false);

          // ✅ Story'leri önerilerden oluştur (en yüksek skorlu 3-5 üniversite)
          _targetHighlights = _recommendations.take(5).map((rec) {
            final university = rec['department']?['university'] ?? {};
            final department = rec['department'] ?? {};
            return {
              'name': university['name'] ?? department['name'] ?? 'Üniversite',
              'city': university['city'] ?? '',
              'image': university['logo_url'] ??
                  'https://images.unsplash.com/photo-1505761671935-60b3a7427bad?auto=format&fit=crop&w=1200&q=80',
              'university_id': university['id'],
              'department_id': department['id'],
              'compatibility': rec['compatibility_score'] ?? 0.0,
            };
          }).toList();

          // Eğer öneri yoksa, varsayılan story'leri göster
          if (_targetHighlights.isEmpty) {
            _targetHighlights = [
              {
                'name': 'Boğaziçi Üniversitesi',
                'city': 'İstanbul',
                'image':
                    'https://images.unsplash.com/photo-1505761671935-60b3a7427bad?auto=format&fit=crop&w=1200&q=80',
                'university_id': null,
              },
              {
                'name': 'ODTÜ',
                'city': 'Ankara',
                'image':
                    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1200&q=80',
                'university_id': null,
              },
              {
                'name': 'İTÜ',
                'city': 'İstanbul',
                'image':
                    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
                'university_id': null,
              },
            ];
          }
        } catch (e) {
          debugPrint('Error loading recommendations: $e');
          _recommendations = [];
          // Hata durumunda varsayılan story'leri göster
          _targetHighlights = [
            {
              'name': 'Boğaziçi Üniversitesi',
              'city': 'İstanbul',
              'image':
                  'https://images.unsplash.com/photo-1505761671935-60b3a7427bad?auto=format&fit=crop&w=1200&q=80',
              'university_id': null,
            },
          ];
        }
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      // Backend hatası olsa bile cache'deki veriler gösterildi
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
    final authService = getAuthService(ApiService());
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoşgeldin kartı - Modern MD3 style
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24.0), // More padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba, ${user?.name ?? 'Öğrenci'}!',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 12), // More spacing
                      Text(
                        'Hedefinize ulaşmak için bugün neler yapacaksınız?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Hedefe Yakınlık - Gelişim Göstergesi
              if (!_isLoading && _totalAttempts > 0) ...[
                _buildProgressCard(context),
                const SizedBox(height: 24),
              ],

              // İstatistikler
              const Text(
                'Son Performansım',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _totalAttempts > 4
                    ? 'Son 4 deneme ortalaması'
                    : 'Tüm denemeler ortalaması',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'TYT Net',
                                _tytAverage > 0
                                    ? _tytAverage.toStringAsFixed(1)
                                    : '-',
                                Icons.assignment_outlined,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'AYT Net',
                                _aytAverage > 0
                                    ? _aytAverage.toStringAsFixed(1)
                                    : '-',
                                Icons.assignment_outlined,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Toplam Net',
                                _totalNetAverage > 0
                                    ? _totalNetAverage.toStringAsFixed(1)
                                    : '-',
                                Icons.analytics_rounded,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Toplam Deneme',
                                _totalAttempts.toString(),
                                Icons.quiz_rounded,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // ✅ Tercihlerim Bölümü (Son Performansın altında) - Modern MD3 style
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // More rounded
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyPreferencesPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0), // More padding
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14), // More padding
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(16), // More rounded
                          ),
                          child: const Icon(
                            Icons.favorite_outline,
                            color: Colors.red,
                            size: 30, // Slightly larger
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tercihlerim',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 6), // More spacing
                              Text(
                                'Beğendiğiniz ve geçtiğiniz üniversiteleri görüntüleyin',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Tercih Önerileri Bölümü (Son Performansın altında)
              if (!_isLoading && _recommendations.isNotEmpty) ...[
                const Text(
                  'Tercih Önerilerim',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Size özel tercih önerileri',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendations.length > 5
                        ? 5
                        : _recommendations.length,
                    itemBuilder: (context, index) {
                      // ✅ Null kontrolü: Eğer recommendation null ise atla
                      if (index >= _recommendations.length) {
                        return const SizedBox.shrink();
                      }

                      final rec = _recommendations[index];

                      // ✅ Null-safe department ve university erişimi
                      final dept =
                          (rec['department'] as Map<String, dynamic>?) ??
                              <String, dynamic>{};
                      final uni =
                          (dept['university'] as Map<String, dynamic>?) ??
                              <String, dynamic>{};

                      // ✅ Bölüm ismi: 'name' alanını kullan (original_name değil)
                      final deptName =
                          dept['name'] as String? ?? 'Bilinmeyen Bölüm';

                      return Container(
                        width: 300, // Slightly wider
                        margin:
                            const EdgeInsets.only(right: 16), // More spacing
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // More rounded
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RecommendationsPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20), // More padding
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          deptName, // ✅ Temizlenmiş isim
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${(rec['final_score'] ?? 0.0).toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    uni['name'] ?? 'Bilinmeyen Üniversite',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${uni['city'] ?? 'Belirtilmemiş'} • ${dept['field_type'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // ✅ min_score gösterimi (null kontrolü ile)
                                  Text(
                                    'Puan: ${dept['min_score'] != null ? (dept['min_score'] as num).toStringAsFixed(2) : 'Puan Oluşmadı'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: dept['min_score'] != null
                                          ? Colors.green[700]
                                          : Colors.grey[500],
                                      fontWeight: dept['min_score'] != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      if (rec['is_safe_choice'] == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Güvenli',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      if (rec['is_safe_choice'] == true &&
                                          rec['is_dream_choice'] == true)
                                        const SizedBox(width: 4),
                                      if (rec['is_dream_choice'] == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Hayal',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.purple,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecommendationsPage(),
                      ),
                    );
                  },
                  child: const Text('Tüm Önerileri Gör'),
                ),
                const SizedBox(height: 24),
              ],

              // Hızlı Aksiyonlar
              const Text(
                'Hızlı İşlemler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActionCard(
                context,
                'Yeni Deneme Ekle',
                'Son yaptığınız denemenin netlerini girin',
                Icons.add_circle_outline,
                Colors.blue,
                () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddExamAttemptPage(),
                    ),
                  );
                  if (result == true && mounted) {
                    _loadDashboardData(); // Yenile
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildQuickActionCard(
                context,
                'Tercih Önerileri',
                'Size özel tercih önerilerini inceleyin',
                Icons.lightbulb_outline,
                Colors.purple,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecommendationsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildQuickActionCard(
                context,
                'Hedefimi Güncelle',
                'Hedef bölüm ve şehirlerinizi güncelleyin',
                Icons.edit_outlined,
                Colors.orange,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GoalsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildQuickActionCard(
                context,
                'Tercihlerim',
                'Beğendiğiniz ve geçtiğiniz üniversiteleri görüntüleyin',
                Icons.favorite_outline,
                Colors.red,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyPreferencesPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 80), // Bottom navbar için boşluk
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = getAuthService(ApiService());
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Icon(
              Icons.school,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Tercih Asistanım',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyPreferencesPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: _buildNewDashboard(context, user?.name),
        ),
      ),
    );
  }

  Widget _buildNewDashboard(BuildContext context, String? userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Selamlama - Basit metin
        _buildGreeting(userName),
        const SizedBox(height: 20),
        // ✅ Üniversite story'leri - Yuvarlak, renkli
        _buildHighlightStories(context),
        const SizedBox(height: 20),
        // ✅ Progress Card - Hedefe yakınlık
        _buildProgressCard(context),
        const SizedBox(height: 20),
        // ✅ Deneme durumu - Empty state veya son deneme
        _buildLastAttemptCard(context),
        const SizedBox(height: 20),
        // ✅ Hızlı İşlemler - 2x2 Grid
        _buildQuickActionsSection(context),
        const SizedBox(height: 80),
      ],
    );
  }

  // ✅ Basit selamlama - Görseldeki gibi
  Widget _buildGreeting(String? userName) {
    return Text(
      'Merhaba, ${userName ?? 'Kullanıcı'}!',
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // ✅ Story'ler - Görseldeki gibi yuvarlak, renkli, üniversite logoları
  Widget _buildHighlightStories(BuildContext context) {
    // Varsayılan story'ler (backend'den gelmezse)
    final defaultStories = [
      {
        'name': 'Boğaziçi',
        'color': const Color(0xFF2E7D32), // Koyu yeşil
        'logo': 'BU',
      },
      {
        'name': 'ODTÜ',
        'color': const Color(0xFF00695C), // Koyu teal
        'logo': 'odtu',
      },
      {
        'name': 'İTÜ',
        'color': const Color(0xFF2E7D32), // Koyu yeşil
        'logo': 'iTÜ',
      },
      {
        'name': 'Koç',
        'color': const Color(0xFF1565C0), // Koyu mavi
        'logo': 'K',
      },
    ];

    // Backend'den gelen story'leri kullan, yoksa varsayılanları göster
    final storiesToShow = _targetHighlights.isNotEmpty
        ? _targetHighlights.take(4).toList()
        : defaultStories;

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: storiesToShow.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = storiesToShow[index];
          final name = item['name'] as String? ?? '';

          // Renk belirleme (backend'den geliyorsa varsayılan, yoksa item'dan)
          Color circleColor;
          if (_targetHighlights.isNotEmpty) {
            // Backend'den gelen story'ler için renk belirle
            final colors = [
              const Color(0xFF2E7D32), // Boğaziçi - yeşil
              const Color(0xFF00695C), // ODTÜ - teal
              const Color(0xFF2E7D32), // İTÜ - yeşil
              const Color(0xFF1565C0), // Koç - mavi
            ];
            circleColor = colors[index % colors.length];
          } else {
            circleColor = item['color'] as Color? ?? Colors.blue;
          }

          return GestureDetector(
            onTap: () {
              final universityId = item['university_id'];
              if (universityId != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name detayları yakında eklenecek'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Yuvarlak story çemberi
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor,
                    border: Border.all(
                      color: circleColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _targetHighlights.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              item['image'] as String? ?? '',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  name
                                      .substring(
                                          0, name.length > 3 ? 3 : name.length)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            item['logo'] as String? ??
                                name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Üniversite adı
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Hızlı İşlemler - 2x2 Grid (Görseldeki gibi)
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            // 1. Yeni Deneme Ekle
            _buildQuickActionGridCard(
              context,
              'Yeni Deneme Ekle',
              Icons.add_circle_outline,
              Colors.blue,
              () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddExamAttemptPage(),
                  ),
                );
                if (result == true && mounted) {
                  _loadDashboardData();
                }
              },
            ),
            // 2. Tercih Önerileri
            _buildQuickActionGridCard(
              context,
              'Tercih Önerileri',
              Icons.lightbulb_outline,
              Colors.blue,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecommendationsPage(),
                  ),
                );
              },
            ),
            // 3. Hedefimi Güncelle
            _buildQuickActionGridCard(
              context,
              'Hedefimi Güncelle',
              Icons.refresh,
              Colors.blue,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UpdateGoalPage(),
                  ),
                );
              },
            ),
            // 4. Tercihlerim
            _buildQuickActionGridCard(
              context,
              'Tercihlerim',
              Icons.checklist,
              Colors.blue,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyPreferencesPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ✅ Grid için özel kart widget'ı
  Widget _buildQuickActionGridCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hedefe Yakınlık Skoru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressPercent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_progressPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Harika gidiyorsun, hedefe çok yakınsın!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastAttemptCard(BuildContext context) {
    if (_lastAttempt == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[900],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.pink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Henüz deneme eklenmedi. Başlamak için "Yeni Deneme Ekle"ye dokun.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final attempt = _lastAttempt!;
    final tytNet = (attempt['tyt_turkish_net'] ?? 0.0) +
        (attempt['tyt_math_net'] ?? 0.0) +
        (attempt['tyt_social_net'] ?? 0.0) +
        (attempt['tyt_science_net'] ?? 0.0);
    final aytNet = (attempt['ayt_math_net'] ?? 0.0) +
        (attempt['ayt_physics_net'] ?? 0.0) +
        (attempt['ayt_chemistry_net'] ?? 0.0) +
        (attempt['ayt_biology_net'] ?? 0.0);
    final examDate = attempt['exam_date'] != null
        ? DateTime.tryParse(attempt['exam_date'].toString())
        : null;
    String lastAttemptText = '';
    if (examDate != null) {
      final now = DateTime.now();
      final diff = now.difference(examDate);
      if (diff.inDays >= 1) {
        lastAttemptText = 'Son denemen ${diff.inDays} gün önce eklendi.';
      } else if (diff.inHours >= 1) {
        lastAttemptText = 'Son denemen ${diff.inHours} saat önce eklendi.';
      } else {
        lastAttemptText = 'Son denemen az önce eklendi.';
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Deneme Netlerin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'TYT: ${tytNet.toStringAsFixed(2)} | AYT: ${aytNet.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lastAttemptText.isNotEmpty
                  ? lastAttemptText
                  : 'Son denemen eklendi.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExamAttemptsPage(),
                    ),
                  );
                },
                child: const Text('Tümünü Gör'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withValues(alpha: 0.08),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[900],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
