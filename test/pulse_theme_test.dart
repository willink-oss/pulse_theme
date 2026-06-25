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

    test('dark() returns a Material 3 dark ThemeData', () {
      final theme = PulseTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('light() is stable across calls (same core fields)', () {
      final a = PulseTheme.light();
      final b = PulseTheme.light();
      expect(a.useMaterial3, b.useMaterial3);
      expect(a.brightness, b.brightness);
      expect(a.colorScheme.primary, b.colorScheme.primary);
    });

    group('ColorScheme is a projection of the semantic tokens', () {
      test('light slots map to PulseSemantics roles', () {
        final cs = PulseTheme.light().colorScheme;
        expect(cs.primary, PulseSemantics.brand);
        expect(cs.onPrimary, PulseSemantics.brandFg);
        expect(cs.primaryContainer, PulseSemantics.brandSoft);
        expect(cs.onPrimaryContainer, PulseSemantics.brandSoftFg);
        expect(cs.surface, PulseSemantics.bg);
        expect(cs.onSurface, PulseSemantics.fg);
        expect(cs.onSurfaceVariant, PulseSemantics.muted);
        expect(cs.outline, PulseSemantics.border);
        expect(cs.error, PulseSemantics.danger);
      });

      test('dark slots map to PulseSemanticsDark roles', () {
        final cs = PulseTheme.dark().colorScheme;
        expect(cs.surface, PulseSemanticsDark.bg); // neutral-950
        expect(cs.onSurface, PulseSemanticsDark.fg); // neutral-50
        expect(cs.outline, PulseSemanticsDark.border); // neutral-800
        // Brand identity is mode-invariant.
        expect(cs.primary, PulseSemantics.brand);
      });
    });

    test('TextTheme sizes come from PulseFontSize', () {
      final tt = PulseTheme.light().textTheme;
      expect(tt.bodyLarge?.fontSize, PulseFontSize.fontSizeBase);
      expect(tt.bodyMedium?.fontSize, PulseFontSize.fontSizeSm);
      expect(tt.bodySmall?.fontSize, PulseFontSize.fontSizeXs);
      expect(tt.titleLarge?.fontSize, PulseFontSize.fontSizeXl);
      expect(tt.headlineMedium?.fontSize, PulseFontSize.fontSize3xl);
    });

    testWidgets('light() drives a MaterialApp without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.light(),
          home: const Scaffold(body: Center(child: Text('PULSE'))),
        ),
      );
      expect(find.text('PULSE'), findsOneWidget);
    });

    testWidgets('dark() drives a MaterialApp without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.light(),
          darkTheme: PulseTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: Center(child: Text('PULSE'))),
        ),
      );
      expect(find.text('PULSE'), findsOneWidget);
    });
  });
}
