import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/tinder_theme.dart';
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
      theme: TinderTheme.getLightTheme(),
      darkTheme: TinderTheme.getDarkTheme(),
      home: const AuthCheckPage(),
    );
  }
}
