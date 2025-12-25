import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recommendation_model.dart';
import '../../data/providers/recommendation_api_provider.dart';
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
    final recommendationsAsync = ref.watch(recommendationListProvider(widget.studentId));

    return recommendationsAsync.when(
      data: (recommendations) {
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

        // Filtreleme ve sıralama
        List<RecommendationModel> filteredRecommendations = recommendations;
        
        if (_selectedType != 'Tümü') {
          filteredRecommendations = filteredRecommendations.where((rec) {
            if (_selectedType == 'Güvenli') return rec.isSafeChoice;
            if (_selectedType == 'Hayal') return rec.isDreamChoice;
            if (_selectedType == 'Gerçekçi') return rec.isRealisticChoice;
            return true;
          }).toList();
        }

        if (_selectedSort == 'Skor') {
          filteredRecommendations.sort((a, b) => b.finalScore.compareTo(a.finalScore));
        } else if (_selectedSort == 'Uyumluluk') {
          filteredRecommendations.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
        } else if (_selectedSort == 'Başarı Olasılığı') {
          filteredRecommendations.sort((a, b) => b.successProbability.compareTo(a.successProbability));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRecommendations.length,
          itemBuilder: (context, index) {
            final recommendation = filteredRecommendations[index];
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
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Öneriler yükleniyor...'),
          ],
        ),
      ),
      error: (error, stack) {
        debugPrint('🔴 Error loading recommendations: $error');
        debugPrint('🔴 Stack: $stack');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Öneriler yüklenirken hata oluştu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(recommendationListProvider(widget.studentId));
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
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

  void _generateRecommendations() async {
    try {
      // Provider'ı invalidate et ve yeniden yükle
      ref.invalidate(recommendationListProvider(widget.studentId));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Öneriler yeniden oluşturuluyor...'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('🔴 Error generating recommendations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
