import 'package:flutter/material.dart';

class RecommendationFilterBottomSheet extends StatefulWidget {
  final String selectedType;
  final String selectedSort;
  final Function(String type, String sort) onApply;

  const RecommendationFilterBottomSheet({
    super.key,
    required this.selectedType,
    required this.selectedSort,
    required this.onApply,
  });

  @override
  State<RecommendationFilterBottomSheet> createState() => _RecommendationFilterBottomSheetState();
}

class _RecommendationFilterBottomSheetState extends State<RecommendationFilterBottomSheet> {
  late String _selectedType;
  late String _selectedSort;

  final List<String> _types = [
    'Tümü',
    'Güvenli Tercih',
    'Gerçekçi Tercih',
    'Hayal Tercihi',
  ];

  final List<String> _sortOptions = [
    'Skor',
    'Başarı Olasılığı',
    'Uyumluluk',
    'Tercih Skoru',
    'Taban Puan',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedSort = widget.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Öneri Filtreleri',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Type Filter
          Text(
            'Öneri Türü',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Sort Filter
          Text(
            'Sıralama',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sortOptions.map((sort) {
              final isSelected = _selectedSort == sort;
              return FilterChip(
                label: Text(sort),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSort = sort;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedType, _selectedSort);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Filtreleri Uygula',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
