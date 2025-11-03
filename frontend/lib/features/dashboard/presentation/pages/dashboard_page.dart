import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/api_service.dart';
import '../../../auth/data/providers/auth_service.dart';
import '../../../exam_attempts/presentation/pages/add_exam_attempt_page.dart';
import '../../../recommendations/presentation/pages/recommendations_page.dart';
import '../../../goals/presentation/pages/goals_page.dart';
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
  List<dynamic> _recommendations = []; // Tercih önerileri

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Cache'den denemeleri yükle ve dashboard'u hesapla
  void _calculateDashboardFromAttempts(List attempts) {
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
      _progressPercent = (_totalNetAverage / _targetTotalNet * 100).clamp(0.0, 100.0);
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
          final cached = jsonDecode(cachedJson) as List;
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
        final attemptsResponse = await _apiService.getStudentAttempts(studentId);
        final attempts = (attemptsResponse.data['attempts'] ?? []) as List;
        
        // Dashboard'u hesapla
        _calculateDashboardFromAttempts(attempts);
        
        // Tercih önerilerini yükle
        try {
          final recommendationsResponse = await _apiService.generateRecommendations(
            studentId,
            limit: 5, // İlk 5 öneri
          );
          _recommendations = recommendationsResponse.data as List;
        } catch (e) {
          debugPrint('Error loading recommendations: $e');
          _recommendations = [];
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

  @override
  Widget build(BuildContext context) {
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
              // Hoşgeldin kartı
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba, ${user?.name ?? 'Öğrenci'}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hedefinize ulaşmak için bugün neler yapacaksınız?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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

              // ✅ Tercihlerim Bölümü (Son Performansın altında)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyPreferencesPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite_outline,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tercihlerim',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Beğendiğiniz ve geçtiğiniz üniversiteleri görüntüleyin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
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
                    itemCount: _recommendations.length > 5 ? 5 : _recommendations.length,
                    itemBuilder: (context, index) {
                      final rec = _recommendations[index];
                      final dept = rec['department'] ?? {};
                      final uni = dept['university'] ?? {};
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RecommendationsPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          dept['name'] ?? 'Bilinmeyen Bölüm',
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
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
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
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
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
                                            color: Colors.purple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
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

  Widget _buildProgressCard(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.1),
              primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hedefe Yakınlık',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_progressPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progressPercent / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            // Mevcut ve hedef net
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ortalama Netim',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _totalNetAverage.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      'TYT: ${_tytAverage.toStringAsFixed(1)} | AYT: ${_aytAverage.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Hedef Net',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _targetTotalNet.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Motivasyon mesajı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _progressPercent >= 80
                        ? Icons.celebration
                        : _progressPercent >= 50
                            ? Icons.trending_up
                            : Icons.star_outline,
                    color: primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getMotivationMessage(_progressPercent),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMotivationMessage(double percent) {
    if (percent >= 90) {
      return 'Harika gidiyorsun! Hedefinize çok yakınsınız! 🎉';
    } else if (percent >= 70) {
      return 'Çok iyi! Hedefinize yaklaşıyorsunuz, devam edin! 💪';
    } else if (percent >= 50) {
      return 'İyi gidiyorsunuz! Düzenli çalışmaya devam edin! 📚';
    } else if (percent >= 30) {
      return 'Başlangıç iyiydi, biraz daha gayret gösterelim! 🚀';
    } else {
      return 'Her büyük yolculuk küçük adımlarla başlar! Devam edin! 🌟';
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
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

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
