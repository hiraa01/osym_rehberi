import 'package:flutter/material.dart';
import '../../data/models/department_model.dart';

class DepartmentCard extends StatelessWidget {
  final DepartmentModel department;
  final VoidCallback? onTap;

  const DepartmentCard({
    super.key,
    required this.department,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getFieldColor(department.fieldType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFieldIcon(department.fieldType),
                      color: _getFieldColor(department.fieldType),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        if (department.universityName != null)
                          Text(
                            department.universityName!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        const SizedBox(height: 4),
                        if (department.city != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                department.city!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.school,
                    department.fieldType,
                    _getFieldColor(department.fieldType),
                  ),
                  const SizedBox(width: 8),
                  if (department.language != null)
                    _buildInfoChip(
                      context,
                      Icons.language,
                      department.language!,
                      Colors.blue,
                    ),
                  const SizedBox(width: 8),
                  if (department.hasScholarship)
                    _buildInfoChip(
                      context,
                      Icons.star,
                      'Burslu',
                      Colors.orange,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (department.minScore != null)
                    Expanded(
                      child: _buildScoreInfo(
                        context,
                        'Taban Puan',
                        '${department.minScore}',
                        Icons.trending_up,
                      ),
                    ),
                  if (department.minRank != null)
                    Expanded(
                      child: _buildScoreInfo(
                        context,
                        'Taban Sıralama',
                        '${department.minRank}',
                        Icons.leaderboard,
                      ),
                    ),
                  if (department.quota != null)
                    Expanded(
                      child: _buildScoreInfo(
                        context,
                        'Kontenjan',
                        '${department.quota}',
                        Icons.people,
                      ),
                    ),
                ],
              ),
              if (department.tuitionFee != null && department.tuitionFee! > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Yıllık Ücret: ${department.tuitionFee!.toStringAsFixed(0)} TL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, Color color) {
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

  Widget _buildScoreInfo(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getFieldColor(String fieldType) {
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

  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'SAY':
        return Icons.calculate;
      case 'EA':
        return Icons.balance;
      case 'SÖZ':
        return Icons.menu_book;
      case 'DİL':
        return Icons.translate;
      default:
        return Icons.school;
    }
  }
}
