import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class RecommendationDetailPage extends ConsumerWidget {
  final int studentId;
  final int recommendationId;

  const RecommendationDetailPage({
    super.key,
    required this.studentId,
    required this.recommendationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual data from API
    final recommendation = _getMockRecommendation();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öneri Detayı'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareRecommendation(context, recommendation),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getScoreColor(recommendation['finalScore'])
                                .withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.analytics,
                            color: _getScoreColor(recommendation['finalScore']),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation['departmentName'],
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recommendation['universityName'],
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                  recommendation['isSafeChoice'],
                                  recommendation['isDreamChoice'],
                                  recommendation['isRealisticChoice'],
                                ).withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getTypeText(
                                  recommendation['isSafeChoice'],
                                  recommendation['isDreamChoice'],
                                  recommendation['isRealisticChoice'],
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getTypeColor(
                                    recommendation['isSafeChoice'],
                                    recommendation['isDreamChoice'],
                                    recommendation['isRealisticChoice'],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${recommendation['finalScore'].toStringAsFixed(1)} puan',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(recommendation['finalScore']),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Score Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skor Detayları',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreDetail(
                            context,
                            'Uyumluluk',
                            '${recommendation['compatibilityScore'].toStringAsFixed(1)}',
                            Icons.handshake,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildScoreDetail(
                            context,
                            'Başarı Olasılığı',
                            '${recommendation['successProbability'].toStringAsFixed(1)}%',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildScoreDetail(
                            context,
                            'Tercih Skoru',
                            '${recommendation['preferenceScore'].toStringAsFixed(1)}',
                            Icons.favorite,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Department Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bölüm Bilgileri',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(context, 'Alan Türü', recommendation['fieldType']),
                    _buildInfoRow(context, 'Şehir', recommendation['city']),
                    _buildInfoRow(context, 'Üniversite Türü', recommendation['universityType']),
                    _buildInfoRow(context, 'Dil', recommendation['language']),
                    if (recommendation['minScore'] != null)
                      _buildInfoRow(context, 'Taban Puan', '${recommendation['minScore']}'),
                    if (recommendation['minRank'] != null)
                      _buildInfoRow(context, 'Taban Sıralama', '${recommendation['minRank']}'),
                    if (recommendation['quota'] != null)
                      _buildInfoRow(context, 'Kontenjan', '${recommendation['quota']}'),
                    if (recommendation['tuitionFee'] != null && recommendation['tuitionFee'] > 0)
                      _buildInfoRow(
                          context, 'Yıllık Ücret', '${recommendation['tuitionFee'].toStringAsFixed(0)} TL'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendation Reason
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Öneri Sebebi',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recommendation['recommendationReason'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
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

  Widget _buildScoreDetail(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Text(
            ': $value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _shareRecommendation(BuildContext context, Map<String, dynamic> recommendation) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paylaşım özelliği henüz hazır değil'),
      ),
    );
  }

  Map<String, dynamic> _getMockRecommendation() {
    return {
      'id': recommendationId,
      'studentId': studentId,
      'departmentId': 1,
      'compatibilityScore': 85.5,
      'successProbability': 90.0,
      'preferenceScore': 75.0,
      'finalScore': 85.0,
      'recommendationReason':
          'Bu bölüm size yüksek başarı olasılığı sunuyor. Puanınız bölümün taban puanından oldukça yüksek ve alan uyumluluğunuz mükemmel. Ayrıca tercih ettiğiniz şehirde bulunuyor ve bütçenize uygun. Bu tercih güvenli bir seçim olarak değerlendirilebilir.',
      'isSafeChoice': true,
      'isDreamChoice': false,
      'isRealisticChoice': false,
      'departmentName': 'Bilgisayar Mühendisliği',
      'fieldType': 'SAY',
      'universityName': 'İstanbul Teknik Üniversitesi',
      'city': 'İstanbul',
      'universityType': 'Devlet',
      'minScore': 450.0,
      'minRank': 1500,
      'quota': 120,
      'tuitionFee': 0.0,
      'hasScholarship': false,
      'language': 'Türkçe',
    };
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getTypeColor(bool isSafe, bool isDream, bool isRealistic) {
    if (isSafe) return Colors.green;
    if (isDream) return Colors.orange;
    if (isRealistic) return Colors.blue;
    return Colors.grey;
  }

  String _getTypeText(bool isSafe, bool isDream, bool isRealistic) {
    if (isSafe) return 'Güvenli Tercih';
    if (isDream) return 'Hayal Tercihi';
    if (isRealistic) return 'Gerçekçi Tercih';
    return 'Genel';
  }
}
