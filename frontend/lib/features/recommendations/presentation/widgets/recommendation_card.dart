import 'package:flutter/material.dart';
import '../../data/models/recommendation_model.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationModel recommendation;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with score and type
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getScoreColor(recommendation.finalScore).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: _getScoreColor(recommendation.finalScore),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.departmentName ?? 'Bilinmeyen Bölüm',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.universityName ?? 'Bilinmeyen Üniversite',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(recommendation.isSafeChoice,
                                  recommendation.isDreamChoice, recommendation.isRealisticChoice)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTypeText(recommendation.isSafeChoice,
                              recommendation.isDreamChoice, recommendation.isRealisticChoice),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getTypeColor(recommendation.isSafeChoice,
                                recommendation.isDreamChoice, recommendation.isRealisticChoice),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recommendation.finalScore.toStringAsFixed(1)} puan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(recommendation.finalScore),
                            ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Department Info
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.school,
                    recommendation.fieldType ?? 'N/A',
                    _getFieldColor(recommendation.fieldType),
                  ),
                  const SizedBox(width: 8),
                  if (recommendation.city != null)
                    _buildInfoChip(
                      context,
                      Icons.location_on,
                      recommendation.city!,
                      Colors.blue,
                    ),
                  const SizedBox(width: 8),
                  if (recommendation.universityType != null)
                    _buildInfoChip(
                      context,
                      Icons.business,
                      recommendation.universityType!,
                      _getUniversityTypeColor(recommendation.universityType),
                    ),
                  if (recommendation.hasScholarship == true) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      context,
                      Icons.star,
                      'Burslu',
                      Colors.orange,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Score Breakdown
              Row(
                children: [
                  Expanded(
                    child: _buildScoreInfo(
                      context,
                      'Uyumluluk',
                      recommendation.compatibilityScore.toStringAsFixed(1),
                      Icons.handshake,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildScoreInfo(
                      context,
                      'Başarı Olasılığı',
                      '${recommendation.successProbability.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildScoreInfo(
                      context,
                      'Tercih Skoru',
                      recommendation.preferenceScore.toStringAsFixed(1),
                      Icons.favorite,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Recommendation Reason
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Öneri Sebebi',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[600],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation.recommendationReason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),

              if (recommendation.minScore != null || recommendation.minRank != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (recommendation.minScore != null)
                      Expanded(
                        child: _buildDetailInfo(
                          context,
                          'Taban Puan',
                          '${recommendation.minScore}',
                          Icons.trending_up,
                        ),
                      ),
                    if (recommendation.minRank != null)
                      Expanded(
                        child: _buildDetailInfo(
                          context,
                          'Taban Sıralama',
                          '${recommendation.minRank}',
                          Icons.leaderboard,
                        ),
                      ),
                    if (recommendation.quota != null)
                      Expanded(
                        child: _buildDetailInfo(
                          context,
                          'Kontenjan',
                          '${recommendation.quota}',
                          Icons.people,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInfo(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailInfo(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
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
    if (isSafe) return 'Güvenli';
    if (isDream) return 'Hayal';
    if (isRealistic) return 'Gerçekçi';
    return 'Genel';
  }

  Color _getFieldColor(String? fieldType) {
    switch (fieldType) {
      case 'SAY':
        return Colors.blue;
      case 'EA':
        return Colors.green;
      case 'SÖZ':
        return Colors.orange;
      case 'DİL':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getUniversityTypeColor(String? type) {
    switch (type) {
      case 'Devlet':
        return Colors.blue;
      case 'Vakıf':
        return Colors.green;
      case 'Özel':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
