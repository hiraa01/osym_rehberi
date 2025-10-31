import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/new_theme.dart';
import 'features/auth/presentation/pages/auth_check_page.dart';

void main() {
  // Error handling ekleyelim
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  runApp(
    const ProviderScope(
      child: OsymRehberiApp(),
    ),
  );
}

class OsymRehberiApp extends StatelessWidget {
  const OsymRehberiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ÖSYM Rehberi',
      debugShowCheckedModeBanner: false,
      theme: NewTheme.getLightTheme(),
      darkTheme: NewTheme.getDarkTheme(),
      home: const AuthCheckPage(),
    );
  }
}
