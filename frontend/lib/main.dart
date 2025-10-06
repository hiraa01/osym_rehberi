import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(
    const ProviderScope(
      child: OsymRehberiApp(),
    ),
  );
}

class OsymRehberiApp extends ConsumerWidget {
  const OsymRehberiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = GetIt.instance<AppRouter>();
    
    return MaterialApp.router(
      title: 'ÖSYM Rehberi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter.config(),
    );
  }
}
