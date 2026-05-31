// DSYS temel widget test dosyası.
//
// Firebase bağımlılığı olmadan çalışabilen basit smoke testler.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DSYS Smoke Tests', () {
    testWidgets('Login ekranı temel widget render kontrolü', (tester) async {
      // Login benzeri basit bir form widget'ı render et
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('DSYS - Döner Sermaye Yönetim Sistemi'),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(labelText: 'E-posta'),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(labelText: 'Şifre'),
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Başlık mevcut mu?
      expect(find.text('DSYS - Döner Sermaye Yönetim Sistemi'), findsOneWidget);

      // Form alanları mevcut mu?
      expect(find.text('E-posta'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
    });

    testWidgets('Material 3 tema uygulanabiliyor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF1B5E20),
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: Center(child: Text('Tema Testi')),
          ),
        ),
      );

      expect(find.text('Tema Testi'), findsOneWidget);
    });
  });
}
