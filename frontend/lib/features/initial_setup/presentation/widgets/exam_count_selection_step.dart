import 'package:flutter/material.dart';

class ExamCountSelectionStep extends StatefulWidget {
  final int initialCount;
  final Function(int) onCountSelected;
  final VoidCallback onNext;

  const ExamCountSelectionStep({
    super.key,
    required this.initialCount,
    required this.onCountSelected,
    required this.onNext,
  });

  @override
  State<ExamCountSelectionStep> createState() => _ExamCountSelectionStepState();
}

class _ExamCountSelectionStepState extends State<ExamCountSelectionStep> {
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_rounded,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          const Text(
            'Kaç Deneme Girişi Yapacaksınız?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yaptığınız deneme sınavlarının netlerini girerek sistemin sizi daha iyi tanımasını sağlayın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          
          // Count selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _selectedCount > 1
                    ? () {
                        setState(() => _selectedCount--);
                        widget.onCountSelected(_selectedCount);
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 40,
              ),
              const SizedBox(width: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$_selectedCount',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _selectedCount < 20
                    ? () {
                        setState(() => _selectedCount++);
                        widget.onCountSelected(_selectedCount);
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 40,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Deneme sayısı: $_selectedCount',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Devam',
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

