import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';

import '../../../../core/router/app_router.dart';

@RoutePage()
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ÖSYM Rehberi'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yapay Zeka Destekli\nÜniversite Öneri Sistemi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Profilinizi oluşturun, deneme sonuçlarınızı girin ve size en uygun bölümleri keşfedin!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Hızlı İşlemler',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButton(
              context,
              icon: Icons.person_add,
              title: 'Profil Oluştur',
              subtitle: 'Yeni öğrenci profili oluşturun',
              onTap: () => context.router.push(const CreateStudentRoute()),
            ),
            
            const SizedBox(height: 12),
            
            _buildActionButton(
              context,
              icon: Icons.analytics,
              title: 'Tercih Önerileri',
              subtitle: 'Size uygun bölümleri görün',
              onTap: () {
                // TODO: Navigate to recommendations with student selection
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Önce bir profil oluşturun'),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            _buildActionButton(
              context,
              icon: Icons.school,
              title: 'Üniversiteler',
              subtitle: 'Üniversite ve bölümleri keşfedin',
              onTap: () => context.router.push(const UniversitiesRoute()),
            ),
            
            const SizedBox(height: 12),
            
            _buildActionButton(
              context,
              icon: Icons.search,
              title: 'Bölüm Ara',
              subtitle: 'Bölümleri filtreleyerek arayın',
              onTap: () => context.router.push(const DepartmentsRoute()),
            ),
            
            const Spacer(),
            
            // Info Card
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sistem YÖK Atlas verilerini kullanarak size en uygun tercih önerilerini sunar.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
