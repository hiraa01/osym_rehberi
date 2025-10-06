import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class UniversitiesPage extends ConsumerWidget {
  const UniversitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üniversiteler'),
      ),
      body: const Center(
        child: Text('Üniversiteler sayfası - Geliştiriliyor'),
      ),
    );
  }
}
