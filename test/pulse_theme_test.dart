import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  group('PulseTheme', () {
    test('light() returns a Material 3 light ThemeData', () {
      final theme = PulseTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('light() is stable across calls (same core fields)', () {
      final a = PulseTheme.light();
      final b = PulseTheme.light();
      expect(a.useMaterial3, b.useMaterial3);
      expect(a.brightness, b.brightness);
      expect(a.colorScheme.primary, b.colorScheme.primary);
    });

    testWidgets('light() can drive a MaterialApp without error',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.light(),
          home: const Scaffold(body: Center(child: Text('PULSE'))),
        ),
      );
      expect(find.text('PULSE'), findsOneWidget);
    });
  });
}
