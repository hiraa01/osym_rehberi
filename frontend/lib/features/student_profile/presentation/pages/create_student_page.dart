import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class CreateStudentPage extends ConsumerWidget {
  const CreateStudentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Oluştur'),
      ),
      body: const Center(
        child: Text('Profil oluşturma sayfası - Geliştiriliyor'),
      ),
    );
  }
}
