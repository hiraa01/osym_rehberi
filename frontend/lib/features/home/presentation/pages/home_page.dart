import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../student_profile/presentation/pages/student_create_page.dart';
import '../../../student_profile/data/providers/student_api_provider.dart';
import '../../../universities/presentation/pages/university_list_page.dart';
import '../../../universities/presentation/pages/university_discover_page.dart';
import '../../../universities/presentation/pages/department_list_page.dart';
import '../../../recommendations/data/providers/recommendation_api_provider.dart';
import '../../../exam_attempts/data/providers/exam_attempt_api_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../recommendations/presentation/pages/recommendations_page.dart';
import '../../../exam_attempts/presentation/pages/exam_attempts_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int? _studentId;

  @override
  void initState() {
    super.initState();
    _loadStudentId();
    
    // ✅ CRITICAL FIX: Sayfa ilk açıldığında veriyi bir kere iste
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');
      
      if (studentId != null) {
        // ✅ Provider'ları tetiklemek için ref.read ile oku (FutureProvider otomatik tetiklenir)
        // Denemeler
        ref.read(examAttemptsListProvider(studentId));
        // ✅ Önerileri yükle
        ref.read(recommendationListProvider(studentId));
        // ✅ Öğrenci detayı
        ref.read(studentDetailProvider(studentId));
        // ✅ Tercihleri yükle (getStudentTargets API'si)
        try {
          final apiService = ApiService();
          await apiService.getStudentTargets(studentId);
        } catch (e) {
          debugPrint('⚠️ Error loading targets: $e');
        }
        debugPrint('🟢 HomePage: Tüm provider\'lar tetiklendi (attempts, recommendations, targets)');
      }
    });
  }

  Future<void> _loadStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getInt('student_id');
    if (mounted) {
      setState(() {
        _studentId = studentId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 Home Page Rebuild - studentId: $_studentId');
    
    // 🔍 DEBUG: Provider states (sadece log için, widget'ta tekrar watch edilecek)
    if (_studentId != null) {
      final examAttemptsAsync = ref.watch(examAttemptsListProvider(_studentId!));
      final recommendationsAsync = ref.watch(recommendationListProvider(_studentId!));
      final studentAsync = ref.watch(studentDetailProvider(_studentId!));
      
      debugPrint('🏠 Home Page - ExamAttempts AsyncValue state: ${examAttemptsAsync.runtimeType}');
      examAttemptsAsync.when(
        data: (data) => debugPrint('🏠 Home Page - ExamAttempts data length: ${data.length}'),
        loading: () => debugPrint('🏠 Home Page - ExamAttempts loading'),
        error: (e, s) => debugPrint('🏠 Home Page - ExamAttempts error: $e'),
      );
      
      debugPrint('🏠 Home Page - Recommendations AsyncValue state: ${recommendationsAsync.runtimeType}');
      recommendationsAsync.when(
        data: (data) => debugPrint('🏠 Home Page - Recommendations data length: ${data.length}'),
        loading: () => debugPrint('🏠 Home Page - Recommendations loading'),
        error: (e, s) => debugPrint('🏠 Home Page - Recommendations error: $e'),
      );
      
      debugPrint('🏠 Home Page - Student AsyncValue state: ${studentAsync.runtimeType}');
      studentAsync.when(
        data: (data) => debugPrint('🏠 Home Page - Student data: ${data.name}'),
        loading: () => debugPrint('🏠 Home Page - Student loading'),
        error: (e, s) => debugPrint('🏠 Home Page - Student error: $e'),
      );
    } else {
      debugPrint('🏠 Home Page - studentId is null, skipping provider checks');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ÖSYM Rehberi'),
        centerTitle: true,
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          return SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getMaxContentWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Card
                    Card(
                      child: Padding(
                        padding: ResponsiveUtils.getResponsivePadding(context),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school,
                              size: ResponsiveUtils.getResponsiveIconSize(
                                  context, 64),
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(
                                height: ResponsiveUtils.getResponsiveSpacing(
                                    context, 16)),
                            Text(
                              'Yapay Zeka Destekli\nÜniversite Öneri Sistemi',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 24),
                                  ),
                            ),
                            SizedBox(
                                height: ResponsiveUtils.getResponsiveSpacing(
                                    context, 8)),
                            Text(
                              'Profilinizi oluşturun, deneme sonuçlarınızı girin ve size en uygun bölümleri keşfedin!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 16),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context, 24)),

                    // ✅ Öğrenci Profil Bilgisi
                    _buildStudentInfoCard(context, ref),
                    SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context, 16)),

                    // ✅ Son Deneme Sonuçları
                    _buildLastExamAttemptCard(context, ref),
                    SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context, 16)),

                    // ✅ Öneriler
                    _buildRecommendationsCard(context, ref),
                    SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context, 16)),

                    // Quick Actions
                    Text(
                      'Hızlı İşlemler',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context, 18),
                              ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context, 16)),

                    // Action Buttons - Responsive Grid
                    ResponsiveBuilder(
                      builder: (context, deviceType) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount:
                              ResponsiveUtils.getGridColumns(context),
                          crossAxisSpacing:
                              ResponsiveUtils.getResponsiveSpacing(context, 12),
                          mainAxisSpacing:
                              ResponsiveUtils.getResponsiveSpacing(context, 12),
                          childAspectRatio:
                              deviceType == DeviceType.mobile ? 3.5 : 2.5,
                          children: [
                            _buildActionButton(
                              context,
                              icon: Icons.person_add,
                              title: 'Profil Oluştur',
                              subtitle: 'Yeni öğrenci profili oluşturun',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const StudentCreatePage(),
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              context,
                              icon: Icons.analytics,
                              title: 'Tercih Önerileri',
                              subtitle: 'Size uygun bölümleri görün',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Önce bir profil oluşturun'),
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              context,
                              icon: Icons.school,
                              title: 'Üniversiteler',
                              subtitle: 'Üniversite ve bölümleri keşfedin',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const UniversityListPage(),
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              context,
                              icon: Icons.explore,
                              title: 'Üniversiteleri Keşfet',
                              subtitle: 'Tinder tarzı üniversite keşfi',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const UniversityDiscoverPage(),
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              context,
                              icon: Icons.search,
                              title: 'Bölüm Ara',
                              subtitle: 'Bölümleri filtreleyerek arayın',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DepartmentListPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context, 24)),

                    // Info Card
                    Card(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Padding(
                        padding: ResponsiveUtils.getResponsivePadding(context),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).primaryColor,
                              size: ResponsiveUtils.getResponsiveIconSize(
                                  context, 24),
                            ),
                            SizedBox(
                                width: ResponsiveUtils.getResponsiveSpacing(
                                    context, 12)),
                            Expanded(
                              child: Text(
                                'Sistem YÖK Atlas verilerini kullanarak size en uygun tercih önerilerini sunar.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                              context, 14),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getResponsiveSpacing(context, 12)),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: ResponsiveUtils.getResponsiveIconSize(context, 24),
                ),
              ),
              SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 18),
                          ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context, 4)),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.7),
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 14),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Öğrenci Bilgisi Card
  Widget _buildStudentInfoCard(BuildContext context, WidgetRef ref) {
    if (_studentId == null) {
      return Card(
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add, color: Colors.blue, size: 32),
              const SizedBox(height: 8),
              Text(
                'Profil Oluşturun',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StudentCreatePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Profil Oluştur'),
              ),
            ],
          ),
        ),
      );
    }

    final studentAsync = ref.watch(studentDetailProvider(_studentId!));

    return studentAsync.when(
      data: (student) {
        return Card(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : 'Ö',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş geldin, ${student.name}!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 18),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.fieldType} • ${student.examType}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) {
        debugPrint('🔴 Error loading student: $error');
        debugPrint('🔴 Stack: $stack');
        return Card(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Öğrenci bilgileri yüklenemedi',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(studentDetailProvider(_studentId!));
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Son Deneme Sonuçları Card
  Widget _buildLastExamAttemptCard(BuildContext context, WidgetRef ref) {
    if (_studentId == null) {
      return const SizedBox.shrink();
    }

    final attemptsAsync = ref.watch(examAttemptsListProvider(_studentId!));

    return attemptsAsync.when(
      data: (attempts) {
        debugPrint('🟢 Exam attempts data received: ${attempts.length} items');
        if (attempts.isEmpty) {
          debugPrint('⚠️ Exam attempts list is empty');
          return Card(
            child: Padding(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined, color: Colors.blue, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Henüz deneme eklenmemiş',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExamAttemptsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Deneme Ekle'),
                  ),
                ],
              ),
            ),
          );
        }

        // En son denemeyi al
        final lastAttempt = attempts.first;
        debugPrint('🟢 Last attempt data: $lastAttempt');
        // ✅ Backend'den gelen toplam net değerlerini kullan (varsa), yoksa manuel hesapla
        final tytTotalNet = lastAttempt['tyt_total_net']?.toDouble();
        final aytTotalNet = lastAttempt['ayt_total_net']?.toDouble();

        final tytNet = tytTotalNet ??
            ((lastAttempt['tyt_turkish_net'] ?? 0.0) +
                (lastAttempt['tyt_math_net'] ?? 0.0) +
                (lastAttempt['tyt_social_net'] ?? 0.0) +
                (lastAttempt['tyt_science_net'] ?? 0.0));
        final aytNet = aytTotalNet ??
            ((lastAttempt['ayt_math_net'] ?? 0.0) +
                (lastAttempt['ayt_physics_net'] ?? 0.0) +
                (lastAttempt['ayt_chemistry_net'] ?? 0.0) +
                (lastAttempt['ayt_biology_net'] ?? 0.0) +
                (lastAttempt['ayt_literature_net'] ?? 0.0) +
                (lastAttempt['ayt_history1_net'] ?? 0.0) +
                (lastAttempt['ayt_geography1_net'] ?? 0.0) +
                (lastAttempt['ayt_philosophy_net'] ?? 0.0) +
                (lastAttempt['ayt_history2_net'] ?? 0.0) +
                (lastAttempt['ayt_geography2_net'] ?? 0.0) +
                (lastAttempt['ayt_religion_net'] ?? 0.0) +
                (lastAttempt['ayt_foreign_language_net'] ?? 0.0));

        final totalNet = tytNet + aytNet;
        final tytScore = lastAttempt['tyt_score']?.toDouble() ?? 0.0;
        final aytScore = lastAttempt['ayt_score']?.toDouble() ?? 0.0;
        final totalScore = lastAttempt['total_score']?.toDouble() ?? 0.0;

        final examDate = lastAttempt['exam_date'] != null
            ? DateTime.parse(lastAttempt['exam_date'])
            : null;
        final examName = lastAttempt['exam_name'] ?? 'Deneme';

        return Card(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExamAttemptsPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son Deneme Netlerin',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 18),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ExamAttemptsPage(),
                            ),
                          );
                        },
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),
                  SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context, 12)),
                  // İlk satır: Netler
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TYT Net',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            Text(
                              tytNet.toStringAsFixed(2),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AYT Net',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            Text(
                              aytNet.toStringAsFixed(2),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam Net',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            Text(
                              totalNet.toStringAsFixed(2),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context, 12)),
                  // İkinci satır: Puanlar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TYT Puan',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            Text(
                              tytScore > 0
                                  ? tytScore.toStringAsFixed(0)
                                  : '---',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AYT Puan',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            Text(
                              aytScore > 0
                                  ? aytScore.toStringAsFixed(0)
                                  : '---',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam Puan',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            Text(
                              totalScore > 0
                                  ? totalScore.toStringAsFixed(0)
                                  : '---',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (examDate != null) ...[
                    SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context, 8)),
                    Text(
                      '$examName - ${DateFormat('dd MMMM yyyy', 'tr_TR').format(examDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) {
        debugPrint('🔴 Error loading exam attempts: $error');
        debugPrint('🔴 Stack: $stack');
        return Card(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Deneme sonuçları yüklenemedi',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(examAttemptsListProvider(_studentId!));
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Öneriler Card
  Widget _buildRecommendationsCard(BuildContext context, WidgetRef ref) {
    if (_studentId == null) {
      debugPrint('⚠️ Home page: _studentId is null, skipping recommendations card');
      return const SizedBox.shrink();
    }

    debugPrint('🟢 Home page: Watching recommendationListProvider for studentId: $_studentId');
    final recommendationsAsync =
        ref.watch(recommendationListProvider(_studentId!));
    debugPrint('🟢 Home page: recommendationListProvider state: ${recommendationsAsync.runtimeType}');

    return recommendationsAsync.when(
      data: (recommendations) {
        debugPrint(
            '🟢 Home page: Received ${recommendations.length} recommendations');
        if (recommendations.isEmpty) {
          debugPrint('⚠️ Home page: Recommendations list is empty');
          return Card(
            child: Padding(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Henüz öneri bulunmuyor',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecommendationsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Önerileri Oluştur'),
                  ),
                ],
              ),
            ),
          );
        }

        // İlk 3 öneriyi göster
        final topRecommendations = recommendations.take(3).toList();

        return Card(
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
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tercih Önerileri',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 18),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecommendationsPage(),
                            ),
                          );
                        },
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),
                  SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context, 12)),
                  ...topRecommendations.map((rec) => Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              ResponsiveUtils.getResponsiveSpacing(context, 8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: rec.recommendationTypeColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(
                                width: ResponsiveUtils.getResponsiveSpacing(
                                    context, 12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.departmentName ?? 'Bölüm Adı Yok',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (rec.universityName != null)
                                    Text(
                                      '${rec.universityName} - ${rec.city ?? ""}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${rec.finalScore.toStringAsFixed(1)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: rec.recommendationTypeColor,
                                      ),
                                ),
                                Text(
                                  rec.recommendationType,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) {
        debugPrint('🔴 Error loading recommendations: $error');
        debugPrint('🔴 Stack: $stack');
        return Card(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Öneriler yüklenirken hata oluştu',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(recommendationListProvider(_studentId!));
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
