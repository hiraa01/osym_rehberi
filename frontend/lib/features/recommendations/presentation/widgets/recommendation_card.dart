import 'package:flutter/material.dart';
import '../../data/models/recommendation_model.dart';

class RecommendationCard extends StatefulWidget {
  final RecommendationModel recommendation;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final departmentName = widget.recommendation.departmentName ?? 'Bilinmeyen Bölüm';
    final universityName = widget.recommendation.universityName ?? 'Bilinmeyen Üniversite';
    final minScore = widget.recommendation.minScore;
    final minRank = widget.recommendation.minRank;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      color: Colors.white, // ✅ DEBUG: Beyaz arka plan
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // ✅ DEBUG: Konsola yaz
          debugPrint('Karta tıklandı: $departmentName');
          if (widget.onTap != null) {
            widget.onTap!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ SOL TARAF: Üniversite Logosu veya İkon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.recommendation.universityName != null &&
                        widget.recommendation.universityName!.isNotEmpty
                    ? Icon(
                        Icons.school,
                        color: Colors.blue.shade700,
                        size: 32,
                      )
                    : Icon(
                        Icons.school,
                        color: Colors.grey.shade400,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 12),

              // ✅ ORTA KISIM: Bölüm Adı, Üniversite Adı, Puan ve Sıralama
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bölüm Adı (Kalın, max 2 satır)
                    Text(
                      departmentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Üniversite Adı (Gri, küçük font)
                    Text(
                      universityName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Puan ve Sıralama Bilgisi (Yan yana, ikonlu)
                    Row(
                      children: [
                        // Puan
                        if (minScore != null) ...[
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            minScore.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                          ),
                        ],
                        // Sıralama
                        if (minRank != null) ...[
                          if (minScore != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 16,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            Icons.bar_chart,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatRank(minRank),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                          ),
                        ],
                        // Eğer hiçbiri yoksa
                        if (minScore == null && minRank == null)
                          Text(
                            'Bilgi yok',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ✅ SAĞ TARAF: Hedefle Butonu (Bookmark)
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                onPressed: () {
                  // ✅ DEBUG: Konsola yaz
                  debugPrint('Hedefle butonuna basıldı');
                  setState(() {
                    _isBookmarked = !_isBookmarked;
                  });
                },
                tooltip: _isBookmarked ? 'Hedeflerden kaldır' : 'Hedefle',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Sıralama formatlama fonksiyonu
  String _formatRank(int rank) {
    if (rank >= 1000000) {
      return '${(rank / 1000000).toStringAsFixed(1)}M';
    } else if (rank >= 1000) {
      return '${(rank / 1000).toStringAsFixed(1)}K';
    }
    // Binlik ayırıcı ile göster (örn: 12.500)
    final rankStr = rank.toString();
    if (rankStr.length > 3) {
      return rankStr.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)}.',
      );
    }
    return rankStr;
  }
}
