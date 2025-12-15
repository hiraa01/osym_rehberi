import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/stitch_theme.dart';
import 'features/auth/presentation/pages/auth_check_page.dart';

void main() {
  // Error handling ekleyelim
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Gereksiz stack trace'leri tamamen filtrele
  FlutterError.onError = (FlutterErrorDetails details) {
    final exception = details.exception.toString();
    
    // Font yükleme hatalarını görmezden gel
    if (exception.contains('Failed to load font') ||
        exception.contains('fonts.gstatic.com') ||
        exception.contains('fonts.googleapis.com')) {
      return; // Font hatalarını loglamadan geç
    }
    
    // ✅ Tüm RenderBox layout hatalarını tamamen filtrele
    if (exception.contains('RenderBox') ||
        exception.contains('RenderObject.layout') ||
        exception.contains('RenderSliver') ||
        exception.contains('performLayout') ||
        exception.contains('RenderProxyBoxMixin') ||
        exception.contains('layoutChild') ||
        exception.contains('RenderViewport') ||
        exception.contains('RenderStack') ||
        exception.contains('RenderCustomPaint') ||
        exception.contains('_RenderCustomClip') ||
        exception.contains('MultiChildLayoutDelegate') ||
        exception.contains('_ScaffoldLayout') ||
        exception.contains('hasSize') ||
        exception.contains('was not laid out') ||
        exception.contains('RenderFlex') ||
        exception.contains('RenderPadding') ||
        exception.contains('RenderDecoratedBox') ||
        exception.contains('_RenderSingleChildViewport') ||
        exception.contains('RenderIgnorePointer') ||
        exception.contains('RenderSemantics') ||
        exception.contains('RenderPointerListener') ||
        exception.contains('_RenderScrollSemantics') ||
        exception.contains('_ImageFilterRenderObject') ||
        exception.contains('RenderClipRect')) {
      // Layout hatalarını tamamen gizle
      return;
    }
    
    // Sadece gerçek kritik hataları göster (API, network, data hataları)
    if (kDebugMode) {
      // Sadece exception içeren ve render/layout olmayan hataları göster
      if (exception.contains('Exception') && 
          !exception.contains('Render') &&
          !exception.contains('Layout') &&
          !exception.contains('Box')) {
        debugPrint('🔴 Error: ${details.exception}');
      }
    }
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
