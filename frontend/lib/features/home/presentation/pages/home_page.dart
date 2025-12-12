import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../student_profile/presentation/pages/student_create_page.dart';
import '../../../universities/presentation/pages/university_list_page.dart';
import '../../../universities/presentation/pages/department_list_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                                // TODO: Navigate to student selection first, then recommendations
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
}
