import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/student_api_provider.dart';

class StudentDetailPage extends ConsumerWidget {
  final int studentId;

  const StudentDetailPage({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci Detayı'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Düzenleme sayfası yakında eklenecek'),
                ),
              );
            },
          ),
        ],
      ),
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(studentDetailProvider(studentId)),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (student) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentDetailProvider(studentId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Öğrenci Bilgileri Card
                _buildInfoCard(
                  context,
                  title: 'Öğrenci Bilgileri',
                  icon: Icons.person,
                  children: [
                    _buildInfoRow('Ad Soyad', student.name),
                    _buildInfoRow('Alan', _getFieldTypeLabel(student.fieldType)),
                    _buildInfoRow('Sınıf', student.classLevel),
                    _buildInfoRow('Sınav Türü', student.examType),
                    _buildInfoRow(
                      'Tercih Edilen Şehirler',
                      student.preferredCities?.join(', ') ?? 'Belirtilmemiş',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // TYT Skorları Card
                _buildInfoCard(
                  context,
                  title: 'TYT Skorları',
                  icon: Icons.school,
                  children: [
                    _buildScoreSection(
                      context,
                      title: 'TYT Net Puanları',
                      scores: [
                        _ScoreItem('Türkçe', student.tytTurkishNet, 40),
                        _ScoreItem('Matematik', student.tytMathNet, 40),
                        _ScoreItem('Sosyal', student.tytSocialNet, 20),
                        _ScoreItem('Fen', student.tytScienceNet, 20),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildTotalScoreRow(
                      context,
                      'TYT Puanı',
                      student.tytTotalScore,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // AYT Skorları Card
                _buildInfoCard(
                  context,
                  title: 'AYT Skorları',
                  icon: Icons.grade,
                  children: [
                    _buildAYTScores(context, student),
                    const Divider(height: 24),
                    _buildTotalScoreRow(
                      context,
                      'AYT Puanı',
                      student.aytTotalScore,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Toplam Puan ve Sıralama Card
                _buildInfoCard(
                  context,
                  title: 'Toplam Puan ve Sıralama',
                  icon: Icons.analytics,
                  children: [
                    _buildTotalScoreRow(
                      context,
                      'Toplam Puan',
                      student.totalScore,
                      isMain: true,
                    ),
                    const SizedBox(height: 16),
                    _buildRankRow(context, 'Sıralama', student.rank),
                    const SizedBox(height: 8),
                    _buildPercentileRow(
                      context,
                      'Yüzdelik Dilim',
                      student.percentile,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tercihler Card
                if (student.preferredUniversityTypes?.isNotEmpty == true ||
                    student.interestAreas?.isNotEmpty == true)
                  _buildInfoCard(
                    context,
                    title: 'Tercihler',
                    icon: Icons.favorite,
                    children: [
                      if (student.preferredUniversityTypes?.isNotEmpty == true)
                        _buildInfoRow(
                          'Üniversite Türü',
                          student.preferredUniversityTypes!.join(', '),
                        ),
                      if (student.interestAreas?.isNotEmpty == true)
                        _buildInfoRow(
                          'İlgi Alanları',
                          student.interestAreas!.join(', '),
                        ),
                      if (student.scholarshipPreference == true)
                        _buildInfoRow('Burs', 'Tercih ediyor'),
                      if (student.budgetPreference != null)
                        _buildInfoRow(
                          'Bütçe',
                          _getBudgetLabel(student.budgetPreference!),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(
    BuildContext context, {
    required String title,
    required List<_ScoreItem> scores,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...scores.map((score) => _buildProgressBar(
              context,
              label: score.label,
              value: score.value ?? 0,
              maxValue: score.maxValue,
            )),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context, {
    required String label,
    required double value,
    required double maxValue,
  }) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    final color = _getScoreColor(percentage);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(
                '${value.toStringAsFixed(1)} / $maxValue',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAYTScores(BuildContext context, dynamic student) {
    final fieldType = student.fieldType;
    List<_ScoreItem> scores = [];

    if (fieldType == 'SAY') {
      scores = [
        _ScoreItem('Matematik', student.aytMathNet, 40),
        _ScoreItem('Fizik', student.aytPhysicsNet, 14),
        _ScoreItem('Kimya', student.aytChemistryNet, 13),
        _ScoreItem('Biyoloji', student.aytBiologyNet, 13),
      ];
    } else if (fieldType == 'EA') {
      scores = [
        _ScoreItem('Matematik', student.aytMathNet, 40),
        _ScoreItem('Edebiyat', student.aytLiteratureNet, 24),
        _ScoreItem('Tarih 1', student.aytHistory1Net, 10),
        _ScoreItem('Coğrafya 1', student.aytGeography1Net, 6),
      ];
    } else if (fieldType == 'SÖZ') {
      scores = [
        _ScoreItem('Edebiyat', student.aytLiteratureNet, 24),
        _ScoreItem('Tarih 1', student.aytHistory1Net, 10),
        _ScoreItem('Coğrafya 1', student.aytGeography1Net, 6),
        _ScoreItem('Felsefe', student.aytPhilosophyNet, 12),
      ];
    } else if (fieldType == 'DİL') {
      scores = [
        _ScoreItem('Yabancı Dil', student.aytForeignLanguageNet, 80),
      ];
    }

    return _buildScoreSection(
      context,
      title: 'AYT Net Puanları (${_getFieldTypeLabel(fieldType)})',
      scores: scores,
    );
  }

  Widget _buildTotalScoreRow(
    BuildContext context,
    String label,
    double? score, {
    bool isMain = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMain
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 16 : 14,
              fontWeight: isMain ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          Text(
            score?.toStringAsFixed(2) ?? '0.00',
            style: TextStyle(
              fontSize: isMain ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(BuildContext context, String label, int? rank) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Sıralama',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            rank != null ? rank.toString() : 'Hesaplanmadı',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentileRow(
    BuildContext context,
    String label,
    double? percentile,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Yüzdelik Dilim',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            percentile != null ? '%${percentile.toStringAsFixed(1)}' : 'Hesaplanmadı',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.lightGreen;
    if (percentage >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getFieldTypeLabel(String fieldType) {
    switch (fieldType) {
      case 'SAY':
        return 'Sayısal';
      case 'EA':
        return 'Eşit Ağırlık';
      case 'SÖZ':
        return 'Sözel';
      case 'DİL':
        return 'Dil';
      default:
        return fieldType;
    }
  }

  String _getBudgetLabel(String budget) {
    switch (budget) {
      case 'low':
        return 'Düşük';
      case 'medium':
        return 'Orta';
      case 'high':
        return 'Yüksek';
      default:
        return budget;
    }
  }
}

class _ScoreItem {
  final String label;
  final double? value;
  final double maxValue;

  _ScoreItem(this.label, this.value, this.maxValue);
}
