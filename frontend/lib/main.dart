import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OsymRehberiApp(),
    ),
  );
}

class OsymRehberiApp extends StatefulWidget {
  const OsymRehberiApp({super.key});

  @override
  State<OsymRehberiApp> createState() => _OsymRehberiAppState();
}

class _OsymRehberiAppState extends State<OsymRehberiApp> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ÖSYM Rehberi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.config(),
    );
  }
}
