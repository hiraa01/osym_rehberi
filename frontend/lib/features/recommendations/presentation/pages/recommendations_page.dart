import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _recommendations = [];
  bool _isLoading = true;
  String _selectedCity = 'all';
  String _selectedType = 'all';
  Set<int> _bookmarkedIds = {};
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_recommendations') ?? [];
    setState(() {
      _bookmarkedIds = bookmarks.map((e) => int.tryParse(e) ?? 0).toSet();
    });
  }

  Future<void> _toggleBookmark(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final isBookmarked = _bookmarkedIds.contains(id);
    setState(() {
      if (isBookmarked) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
    await prefs.setStringList(
      'bookmarked_recommendations',
      _bookmarkedIds.map((e) => e.toString()).toList(),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isBookmarked ? 'Kaydedildi!' : 'Kayıttan kaldırıldı',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('student_id');
      
      if (studentId != null) {
        final response = await _apiService.generateRecommendations(studentId, limit: 50);
        setState(() {
          // Backend direkt liste döndürüyor (List[RecommendationResponse])
          _recommendations = response.data is List ? response.data : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Önce bir öğrenci profili oluşturun'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Recommendations error: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öneriler yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredRecommendations {
    return _recommendations.where((rec) {
      // Backend response: {department: {university: {...}}}
      final university = rec['department']?['university'];
      final city = university?['city']?.toString().toLowerCase() ?? '';
      final universityType = university?['university_type']?.toString().toLowerCase() ?? '';
      
      bool matchesCity = _selectedCity == 'all' || city.contains(_selectedCity.toLowerCase());
      bool matchesType = _selectedType == 'all' || universityType.contains(_selectedType.toLowerCase());
      
      return matchesCity && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tercih Önerilerim'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Bilgi Kartı
            Card(
              color: Colors.blue.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Puanlarınıza ve tercihlerinize göre size özel üniversite önerileri',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filtreler
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tüm Şehirler')),
                      DropdownMenuItem(value: 'istanbul', child: Text('İstanbul')),
                      DropdownMenuItem(value: 'ankara', child: Text('Ankara')),
                      DropdownMenuItem(value: 'izmir', child: Text('İzmir')),
                    ],
                    value: _selectedCity,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCity = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Üniversite Türü',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tümü')),
                      DropdownMenuItem(value: 'devlet', child: Text('Devlet')),
                      DropdownMenuItem(value: 'vakif', child: Text('Vakıf')),
                    ],
                    value: _selectedType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Öneriler Listesi
            Text(
              'Önerilen Bölümler (${_filteredRecommendations.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Gerçek Öneriler
            _filteredRecommendations.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Henüz öneri bulunmuyor'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredRecommendations.length,
                                    itemBuilder: (context, index) {
                                      final rec = _filteredRecommendations[index];
                                      final matchScore = (rec['match_score'] ?? 0.0) * 100;
                                      final recId = rec['id'] ?? index;
                                      final isBookmarked = _bookmarkedIds.contains(recId);
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: InkWell(
                                          onTap: () {},
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade100,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '${matchScore.toStringAsFixed(0)}% Uyum',
                                                        style: TextStyle(
                                                          color: Colors.green.shade700,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    IconButton(
                                                      onPressed: () => _toggleBookmark(recId),
                                                      icon: Icon(
                                                        isBookmarked
                                                            ? Icons.bookmark
                                                            : Icons.bookmark_border,
                                                        color: isBookmarked
                                                            ? Theme.of(context).primaryColor
                                                            : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                const SizedBox(height: 12),
                                Text(
                                  rec['department_name'] ?? 'Bölüm',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rec['university_name'] ?? 'Üniversite',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      Icons.location_on,
                                      rec['city'] ?? '-',
                                      Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      Icons.school,
                                      rec['university_type'] ?? '-',
                                      Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      Icons.trending_up,
                                      rec['base_score']?.toStringAsFixed(1) ?? '-',
                                      Colors.purple,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _loadRecommendations,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Yeniden Hesapla'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
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
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

