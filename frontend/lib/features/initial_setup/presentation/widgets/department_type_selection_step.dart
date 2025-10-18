import 'package:flutter/material.dart';

class DepartmentTypeSelectionStep extends StatefulWidget {
  final String? initialType;
  final Function(String) onTypeSelected;
  final VoidCallback onNext;

  const DepartmentTypeSelectionStep({
    super.key,
    this.initialType,
    required this.onTypeSelected,
    required this.onNext,
  });

  @override
  State<DepartmentTypeSelectionStep> createState() => _DepartmentTypeSelectionStepState();
}

class _DepartmentTypeSelectionStepState extends State<DepartmentTypeSelectionStep> {
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  final List<Map<String, dynamic>> _departmentTypes = [
    {
      'id': 'EA',
      'name': 'Eşit Ağırlık (EA)',
      'description': 'Hukuk, İktisat, İşletme vb.',
      'icon': Icons.balance,
      'color': Colors.blue,
    },
    {
      'id': 'SÖZ',
      'name': 'Sözel (SÖZ)',
      'description': 'Türk Dili, Tarih, Coğrafya vb.',
      'icon': Icons.menu_book,
      'color': Colors.orange,
    },
    {
      'id': 'SAY',
      'name': 'Sayısal (SAY)',
      'description': 'Mühendislik, Tıp, Fen Bilimleri vb.',
      'icon': Icons.calculate,
      'color': Colors.green,
    },
    {
      'id': 'DİL',
      'name': 'Dil (DİL)',
      'description': 'İngilizce, Almanca, Fransızca vb.',
      'icon': Icons.language,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hangi Bölüm Türünü Hedefliyorsunuz?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Netleriniz buna göre değerlendirilecektir',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _departmentTypes.length,
              itemBuilder: (context, index) {
                final type = _departmentTypes[index];
                final isSelected = _selectedType == type['id'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedType = type['id']);
                      widget.onTypeSelected(type['id']);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? type['color'] : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected 
                            ? type['color'].withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: type['color'].withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              type['icon'],
                              color: type['color'],
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? type['color'] : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: type['color'],
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedType != null ? widget.onNext : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Devam Et',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

