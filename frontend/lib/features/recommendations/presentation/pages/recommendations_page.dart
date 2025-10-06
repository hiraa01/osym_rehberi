import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class RecommendationsPage extends ConsumerWidget {
  final int studentId;
  
  const RecommendationsPage({
    super.key,
    @PathParam('studentId') required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tercih Önerileri'),
      ),
      body: Center(
        child: Text('Öneriler sayfası - Öğrenci ID: $studentId - Geliştiriliyor'),
      ),
    );
  }
}
