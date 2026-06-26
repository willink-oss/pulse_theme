// Tests for PulseProgressIndicator (1.4.0).
//
// Cover determinate value passthrough + color contract (primary fill /
// surfaceContainerHighest track), the indeterminate (null value) mode,
// default sizing (8dp, fully rounded), overrides, ColorScheme copyWith
// flow-through, and the semanticsLabel passthrough.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme ?? PulseTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  group('PulseProgressIndicator — determinate', () {
    testWidgets('passes value through to LinearProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PulseProgressIndicator(value: 0.65)));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, equals(0.65));
    });

    testWidgets('fill uses primary + track uses surfaceContainerHighest', (
      tester,
    ) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        wrap(const PulseProgressIndicator(value: 0.4), theme: theme),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.color, equals(theme.colorScheme.primary));
      expect(
        bar.backgroundColor,
        equals(theme.colorScheme.surfaceContainerHighest),
      );
    });
  });

  group('PulseProgressIndicator — indeterminate', () {
    testWidgets('null value renders an animating indeterminate bar', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PulseProgressIndicator()));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);

      // Indeterminate bars animate forever — pump a few frames (no
      // pumpAndSettle) and assert the widget is still mounted and live.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
    });
  });

  group('PulseProgressIndicator — sizing', () {
    testWidgets('defaults to 8dp height + fully rounded corners', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PulseProgressIndicator(value: 0.5)));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.minHeight, equals(8));
      // rounded-full: radius = minHeight / 2.
      expect(bar.borderRadius, equals(BorderRadius.circular(4)));
      expect(
        tester.getSize(find.byType(LinearProgressIndicator)).height,
        equals(8),
      );
    });

    testWidgets('custom minHeight + borderRadius are respected', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PulseProgressIndicator(
            value: 0.5,
            minHeight: 4,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.minHeight, equals(4));
      expect(bar.borderRadius, equals(BorderRadius.circular(1)));
    });
  });

  group('PulseProgressIndicator — ColorScheme override', () {
    testWidgets('respects copyWith(colorScheme: ...) override', (tester) async {
      final overridden = PulseTheme.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      );

      await tester.pumpWidget(
        wrap(const PulseProgressIndicator(value: 0.8), theme: overridden),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.color, equals(overridden.colorScheme.primary));
      expect(
        bar.backgroundColor,
        equals(overridden.colorScheme.surfaceContainerHighest),
      );
    });
  });

  group('PulseProgressIndicator — semantics', () {
    testWidgets('semanticsLabel is exposed to assistive tech', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          const PulseProgressIndicator(
            value: 0.25,
            semanticsLabel: 'Upload progress',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Upload progress'), findsOneWidget);
      handle.dispose();
    });
  });
}
