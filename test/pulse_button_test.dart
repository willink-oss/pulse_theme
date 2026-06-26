// Tests for PulseButton.
//
// Cover variant color contracts (filled / outline / ghost), disabled state
// behavior, ColorScheme override, leading-icon layout, and the 48dp a11y
// tap-target guideline.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme ?? PulseTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  group('PulseButton — filled variant', () {
    testWidgets('uses primary background + onPrimary text color', (
      tester,
    ) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        wrap(
          PulseButton(onPressed: () {}, child: const Text('保存')),
          theme: theme,
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style!;
      final bg = style.backgroundColor!.resolve(<WidgetState>{});
      final fg = style.foregroundColor!.resolve(<WidgetState>{});
      expect(bg, equals(theme.colorScheme.primary));
      expect(fg, equals(theme.colorScheme.onPrimary));
    });

    testWidgets('tap fires handler', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          PulseButton(onPressed: () => tapped = true, child: const Text('OK')),
        ),
      );
      await tester.tap(find.text('OK'));
      expect(tapped, isTrue);
    });
  });

  group('PulseButton — outline variant', () {
    testWidgets('border uses primary color', (tester) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        wrap(
          PulseButton(
            variant: PulseButtonVariant.outline,
            onPressed: () {},
            child: const Text('キャンセル'),
          ),
          theme: theme,
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final style = button.style!;
      final side = style.side!.resolve(<WidgetState>{});
      expect(side!.color, equals(theme.colorScheme.primary));
    });
  });

  group('PulseButton — ghost variant', () {
    testWidgets('uses transparent background + primary text', (tester) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        wrap(
          PulseButton(
            variant: PulseButtonVariant.ghost,
            onPressed: () {},
            child: const Text('スキップ'),
          ),
          theme: theme,
        ),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      final style = button.style!;
      final bg = style.backgroundColor!.resolve(<WidgetState>{});
      final fg = style.foregroundColor!.resolve(<WidgetState>{});
      expect(bg, equals(Colors.transparent));
      expect(fg, equals(theme.colorScheme.primary));
    });
  });

  group('PulseButton — disabled', () {
    testWidgets('opacity 0.5 + tap does not fire when onPressed null', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(const PulseButton(onPressed: null, child: Text('Disabled'))),
      );

      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, equals(0.5));

      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      // Ignore the tap silently — disabled buttons swallow taps.
      expect(tapped, isFalse);
    });
  });

  group('PulseButton — ColorScheme override', () {
    testWidgets('respects copyWith(colorScheme: ...) override', (tester) async {
      // Migration path replacing the old per-brand factories: consumers
      // override ColorScheme to change the brand color.
      final overridden = PulseTheme.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      );

      await tester.pumpWidget(
        wrap(
          PulseButton(onPressed: () {}, child: const Text('Go')),
          theme: overridden,
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final bg = button.style!.backgroundColor!.resolve(<WidgetState>{});
      expect(bg, equals(overridden.colorScheme.primary));
    });
  });

  group('PulseButton — dark theme (dark)', () {
    testWidgets('filled keeps mode-invariant brand-600 bg + white text', (
      tester,
    ) async {
      // ADR-0013: brand identity does not flip — a filled button is the
      // same violet on a neutral-950 surface.
      await tester.pumpWidget(
        wrap(
          PulseButton(onPressed: () {}, child: const Text('保存')),
          theme: PulseTheme.dark(),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style!;
      final bg = style.backgroundColor!.resolve(<WidgetState>{});
      final fg = style.foregroundColor!.resolve(<WidgetState>{});
      expect(bg, equals(PulsePrimitives.brand600));
      expect(fg, equals(const Color(0xFFFFFFFF)));
    });

    testWidgets('ghost overlay uses the dark brand-950 container', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PulseButton(
            variant: PulseButtonVariant.ghost,
            onPressed: () {},
            child: const Text('スキップ'),
          ),
          theme: PulseTheme.dark(),
        ),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      final overlay = button.style!.overlayColor!.resolve(<WidgetState>{
        WidgetState.pressed,
      });
      // primaryContainer flips brand-100 → brand-950 under dark.
      expect(overlay, equals(PulsePrimitives.brand950));
    });
  });

  group('PulseButton — a11y (48dp tap target, D1)', () {
    for (final size in PulseButtonSize.values) {
      testWidgets('${size.name} meets the Android 48dp tap-target guideline', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          wrap(
            PulseButton(onPressed: () {}, size: size, child: const Text('OK')),
          ),
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('PulseButton — icon layout', () {
    testWidgets('leadingIcon sits before label with 8px gap', (tester) async {
      await tester.pumpWidget(
        wrap(
          PulseButton(
            onPressed: () {},
            leadingIcon: const Icon(Icons.check, key: ValueKey('lead')),
            child: const Text('完了'),
          ),
        ),
      );

      // 8px SizedBox spacer must exist between icon and label.
      final spacers = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((s) => s.width == 8 && s.height == null);
      expect(spacers, isNotEmpty);

      // Icon center x should be less than label center x (i.e. on the left).
      final iconRect = tester.getRect(find.byKey(const ValueKey('lead')));
      final labelRect = tester.getRect(find.text('完了'));
      expect(iconRect.center.dx, lessThan(labelRect.center.dx));
    });
  });
}
