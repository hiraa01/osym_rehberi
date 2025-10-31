import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import 'add_exam_attempt_page.dart';

class ExamAttemptsPage extends StatefulWidget {
  const ExamAttemptsPage({super.key});

  @override
  State<ExamAttemptsPage> createState() => _ExamAttemptsPageState();
}

class _ExamAttemptsPageState extends State<ExamAttemptsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _attempts = [];
  bool _isLoading = true;
  int? _studentId;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  // Yerel cache'den denemeleri yükle
  Future<void> _loadCachedAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('exam_attempts_cache');
      if (cachedJson != null) {
        final cached = jsonDecode(cachedJson) as List;
        if (mounted) {
          setState(() {
            _attempts = cached;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cached attempts: $e');
    }
  }

  // Denemeleri yerel cache'e kaydet
  Future<void> _saveAttemptsToCache(List<dynamic> attempts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('exam_attempts_cache', jsonEncode(attempts));
    } catch (e) {
      debugPrint('Error saving attempts to cache: $e');
    }
  }

  Future<void> _loadAttempts() async {
    // Önce yerel cache'den yükle (hızlı görüntüleme için)
    await _loadCachedAttempts();
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _studentId = prefs.getInt('student_id');
      
      if (_studentId != null) {
        // Backend'den güncel verileri yükle
        final response = await _apiService.getStudentAttempts(_studentId!);
        final attempts = response.data['attempts'] ?? [];
        
        // Yerel cache'e kaydet
        await _saveAttemptsToCache(attempts);
        
        if (mounted) {
          setState(() {
            _attempts = attempts;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading attempts from backend: $e');
      // Backend hatası olsa bile cache'deki veriler gösterildi
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deneme Sonuçlarım'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddExamAttemptPage(),
                ),
              );
              if (result == true) {
                _loadAttempts(); // Yenile
              }
            },
            icon: const Icon(Icons.add),
            tooltip: 'Deneme Ekle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attempts.isEmpty
              ? _buildEmptyState()
              : _buildAttemptsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_rounded,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz deneme eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk denemenizi ekleyerek başlayın',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddExamAttemptPage(),
                ),
              );
              if (result == true) {
                _loadAttempts();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Deneme Ekle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attempts.length,
      cacheExtent: 500, // ✅ Render edilmemiş widget'lar için cache
      itemBuilder: (context, index) {
        final attempt = _attempts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                '#${attempt['attempt_number'] ?? index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            title: Text(
              'Deneme ${attempt['attempt_number'] ?? index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'TYT: ${attempt['tyt_score']?.toStringAsFixed(2) ?? '0.00'} | '
              'AYT: ${attempt['ayt_score']?.toStringAsFixed(2) ?? '0.00'}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${attempt['total_score']?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Text(
                  'Toplam',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

