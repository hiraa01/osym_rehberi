import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/stitch_theme.dart';
import 'features/auth/presentation/pages/auth_check_page.dart';

void main() {
  // Error handling ekleyelim
  WidgetsFlutterBinding.ensureInitialized();

  // Font yükleme hatalarını engelle
  FlutterError.onError = (FlutterErrorDetails details) {
    // Font yükleme hatalarını görmezden gel
    if (details.exception.toString().contains('Failed to load font') ||
        details.exception.toString().contains('fonts.gstatic.com')) {
      return; // Font hatalarını loglamadan geç
    }
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
      theme: StitchTheme.getLightTheme(),
      darkTheme: StitchTheme.getDarkTheme(),
      home: const AuthCheckPage(),
    );
  }
}
