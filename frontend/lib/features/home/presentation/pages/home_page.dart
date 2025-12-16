import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../student_profile/presentation/pages/student_create_page.dart';
import '../../../universities/presentation/pages/university_list_page.dart';
import '../../../universities/presentation/pages/university_discover_page.dart';
import '../../../universities/presentation/pages/department_list_page.dart';
import '../../../recommendations/data/providers/recommendation_api_provider.dart';
import '../../../exam_attempts/data/providers/exam_attempt_api_provider.dart';
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
                              size: ResponsiveUtils.getResponsiveIconSize(context, 64),
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                            Text(
                              'Yapay Zeka Destekli\nÜniversite Öneri Sistemi',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                            Text(
                              'Profilinizi oluşturun, deneme sonuçlarınızı girin ve size en uygun bölümleri keşfedin!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                    
                    // ✅ Son Deneme Sonuçları (eğer student_id varsa)
                    if (_studentId != null) ...[
                      _buildLastExamAttemptCard(context, ref),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                    ],
                    
                    // ✅ Öneriler (eğer student_id varsa)
                    if (_studentId != null) ...[
                      _buildRecommendationsCard(context, ref),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                    ],
                    
                    // Quick Actions
                    Text(
                      'Hızlı İşlemler',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),
            
                    // Action Buttons - Responsive Grid
                    ResponsiveBuilder(
                      builder: (context, deviceType) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: ResponsiveUtils.getGridColumns(context),
                          crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 12),
                          mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, 12),
                          childAspectRatio: deviceType == DeviceType.mobile ? 3.5 : 2.5,
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
                                    builder: (_) => const UniversityDiscoverPage(),
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
            
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                    
                    // Info Card
                    Card(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Padding(
                        padding: ResponsiveUtils.getResponsivePadding(context),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).primaryColor,
                              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
                            ),
                            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                            Expanded(
                              child: Text(
                                'Sistem YÖK Atlas verilerini kullanarak size en uygun tercih önerilerini sunar.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
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
                padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 12)),
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
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
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

  // ✅ Son Deneme Sonuçları Card
  Widget _buildLastExamAttemptCard(BuildContext context, WidgetRef ref) {
    if (_studentId == null) return const SizedBox.shrink();

    final attemptsAsync = ref.watch(examAttemptsListProvider(_studentId!));

    return attemptsAsync.when(
      data: (attempts) {
        if (attempts.isEmpty) {
          return const SizedBox.shrink();
        }

        // En son denemeyi al
        final lastAttempt = attempts.first;
        final tytNet = (lastAttempt['tyt_turkish_net'] ?? 0.0) +
            (lastAttempt['tyt_math_net'] ?? 0.0) +
            (lastAttempt['tyt_social_net'] ?? 0.0) +
            (lastAttempt['tyt_science_net'] ?? 0.0);
        final aytNet = (lastAttempt['ayt_math_net'] ?? 0.0) +
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
            (lastAttempt['ayt_foreign_language_net'] ?? 0.0);

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
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
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
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TYT Net',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              tytNet.toStringAsFixed(2),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              aytNet.toStringAsFixed(2),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (examDate != null) ...[
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
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
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  // ✅ Öneriler Card
  Widget _buildRecommendationsCard(BuildContext context, WidgetRef ref) {
    if (_studentId == null) return const SizedBox.shrink();

    final recommendationsAsync = ref.watch(recommendationListProvider(_studentId!));

    return recommendationsAsync.when(
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return const SizedBox.shrink();
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
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
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
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                  ...topRecommendations.map((rec) => Padding(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveUtils.getResponsiveSpacing(context, 8),
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
                        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.departmentName ?? 'Bölüm Adı Yok',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (rec.universityName != null)
                                Text(
                                  '${rec.universityName} - ${rec.city ?? ""}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: rec.recommendationTypeColor,
                              ),
                            ),
                            Text(
                              rec.recommendationType,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
