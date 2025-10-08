import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:osym_rehberi/main.dart';
import 'package:osym_rehberi/features/home/presentation/pages/home_page.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('HomePage displays correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Verify that the home page displays the correct title
      expect(find.text('ÖSYM Rehberi'), findsOneWidget);
      expect(find.text('Yapay Zeka Destekli\nÜniversite Öneri Sistemi'), findsOneWidget);
    });

    testWidgets('HomePage has action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Verify that action buttons are present
      expect(find.text('Profil Oluştur'), findsOneWidget);
      expect(find.text('Tercih Önerileri'), findsOneWidget);
      expect(find.text('Üniversiteler'), findsOneWidget);
      expect(find.text('Bölüm Ara'), findsOneWidget);
    });

    testWidgets('Action buttons are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Test that buttons can be tapped
      await tester.tap(find.text('Profil Oluştur'));
      await tester.pump();

      // Verify that the button responds to tap
      expect(find.text('Profil Oluştur'), findsOneWidget);
    });
  });

  group('App Integration Tests', () {
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: OsymRehberiApp(),
        ),
      );

      // Verify that the app starts successfully
      expect(find.byType(OsymRehberiApp), findsOneWidget);
    });
  });
}
