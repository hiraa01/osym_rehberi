import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recommendation_model.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/recommendation_filter_bottom_sheet.dart';
import './recommendation_detail_page.dart';

class RecommendationListPage extends ConsumerStatefulWidget {
  final int studentId;

  const RecommendationListPage({
    super.key,
    required this.studentId,
  });

  @override
  ConsumerState<RecommendationListPage> createState() =>
      _RecommendationListPageState();
}

class _RecommendationListPageState extends ConsumerState<RecommendationListPage> {
  String _selectedType = 'Tümü';
  String _selectedSort = 'Skor';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tercih Önerileri'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _generateRecommendations(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          if (_selectedType != 'Tümü' || _selectedSort != 'Skor')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedType != 'Tümü')
                    Chip(
                      label: Text('Tür: $_selectedType'),
                      onDeleted: () {
                        setState(() {
                          _selectedType = 'Tümü';
                        });
                      },
                    ),
                  if (_selectedSort != 'Skor')
                    Chip(
                      label: Text('Sıralama: $_selectedSort'),
                      onDeleted: () {
                        setState(() {
                          _selectedSort = 'Skor';
                        });
                      },
                    ),
                ],
              ),
            ),

          // Recommendations List
          Expanded(
            child: _buildRecommendationsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateRecommendations,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Yeni Öneriler'),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Öneriler oluşturuluyor...'),
          ],
        ),
      );
    }

    // Not: API verisi ile değiştirilecek
    final recommendations = _getMockRecommendations();

    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz öneri bulunmuyor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yapay zeka destekli öneriler oluşturmak için butona tıklayın',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateRecommendations,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Önerileri Oluştur'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return RecommendationCard(
          recommendation: recommendation,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecommendationDetailPage(
                  studentId: widget.studentId,
                  recommendationId: recommendation.id!,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RecommendationFilterBottomSheet(
        selectedType: _selectedType,
        selectedSort: _selectedSort,
        onApply: (type, sort) {
          setState(() {
            _selectedType = type;
            _selectedSort = sort;
          });
        },
      ),
    );
  }

  void _generateRecommendations() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yeni öneriler oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  List<RecommendationModel> _getMockRecommendations() {
    final mockData = [
      {
        'id': 1,
        'student_id': widget.studentId,
        'department_id': 1,
        'compatibility_score': 85.5,
        'success_probability': 90.0,
        'preference_score': 75.0,
        'final_score': 85.0,
        'recommendation_reason':
            'Yüksek başarı olasılığı, Puanınız bölümün taban puanından yüksek, Yüksek uyumluluk',
        'is_safe_choice': true,
        'is_dream_choice': false,
        'is_realistic_choice': false,
        'department': {
          'name': 'Bilgisayar Mühendisliği',
          'field_type': 'SAY',
          'university': {
            'name': 'İstanbul Teknik Üniversitesi',
            'city': 'İstanbul',
            'university_type': 'Devlet'
          },
          'min_score': 450.0,
          'min_rank': 1500,
          'quota': 120,
          'tuition_fee': 0.0,
          'has_scholarship': false,
          'language': 'Türkçe'
        }
      },
      {
        'id': 2,
        'student_id': widget.studentId,
        'department_id': 2,
        'compatibility_score': 78.0,
        'success_probability': 75.0,
        'preference_score': 80.0,
        'final_score': 77.5,
        'recommendation_reason':
            'Orta başarı olasılığı, Puanınız bölümün taban puanına yakın, Tercihlerinize uygun',
        'is_safe_choice': false,
        'is_dream_choice': false,
        'is_realistic_choice': true,
        'department': {
          'name': 'Elektrik Mühendisliği',
          'field_type': 'SAY',
          'university': {
            'name': 'Boğaziçi Üniversitesi',
            'city': 'İstanbul',
            'university_type': 'Devlet'
          },
          'min_score': 480.0,
          'min_rank': 800,
          'quota': 80,
          'tuition_fee': 0.0,
          'has_scholarship': false,
          'language': 'Türkçe'
        }
      },
      {
        'id': 3,
        'student_id': widget.studentId,
        'department_id': 3,
        'compatibility_score': 65.0,
        'success_probability': 45.0,
        'preference_score': 70.0,
        'final_score': 60.0,
        'recommendation_reason':
            'Düşük başarı olasılığı, Puanınız bölümün taban puanından düşük, Kısmen tercihlerinize uygun',
        'is_safe_choice': false,
        'is_dream_choice': true,
        'is_realistic_choice': false,
        'department': {
          'name': 'Endüstri Mühendisliği',
          'field_type': 'EA',
          'university': {
            'name': 'Orta Doğu Teknik Üniversitesi',
            'city': 'Ankara',
            'university_type': 'Devlet'
          },
          'min_score': 460.0,
          'min_rank': 1200,
          'quota': 100,
          'tuition_fee': 0.0,
          'has_scholarship': false,
          'language': 'Türkçe'
        }
      },
    ];
    return mockData.map((json) => RecommendationModel.fromJson(json)).toList();
  }
}
