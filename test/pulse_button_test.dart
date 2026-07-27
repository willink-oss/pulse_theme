// Tests for PulseButton.
//
// Cover variant color contracts (filled / outline / ghost / danger), disabled
// vs. loading state behavior, ColorScheme override, leading-icon layout, and
// the 48dp a11y tap-target guideline.

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

  group('PulseButton — danger variant', () {
    /// Every accent glow painted above [scope] (the button subtree is wrapped
    /// in a DecoratedBox when the variant is solid and not dimmed).
    Iterable<BoxShadow> glowsAround(WidgetTester tester, Finder scope) => tester
        .widgetList<DecoratedBox>(
          find.ancestor(of: scope, matching: find.byType(DecoratedBox)),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .expand((d) => d.boxShadow ?? const <BoxShadow>[]);

    testWidgets('renders a FilledButton with error / onError colors', (
      tester,
    ) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        wrap(
          PulseButton(
            variant: PulseButtonVariant.danger,
            onPressed: () {},
            child: const Text('削除'),
          ),
          theme: theme,
        ),
      );

      // danger is a peer of filled — same Material button, different accent.
      expect(find.byType(FilledButton), findsOneWidget);
      final style =
          tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      final bg = style.backgroundColor!.resolve(<WidgetState>{});
      final fg = style.foregroundColor!.resolve(<WidgetState>{});
      expect(bg, equals(theme.colorScheme.error));
      expect(fg, equals(theme.colorScheme.onError));
      // …and NOT the filled accent, otherwise the assertion above would pass
      // for a variant that silently fell back to primary.
      expect(bg, isNot(equals(theme.colorScheme.primary)));
    });

    testWidgets('glow tracks the error accent at 30% alpha', (tester) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        wrap(
          PulseButton(
            variant: PulseButtonVariant.danger,
            onPressed: () {},
            child: const Text('削除'),
          ),
          theme: theme,
        ),
      );

      final glows = glowsAround(tester, find.byType(FilledButton));
      expect(
        glows.any(
          (s) =>
              s.color == theme.colorScheme.error.withValues(alpha: 0.3) &&
              s.blurRadius == 16 &&
              s.offset == const Offset(0, 4) &&
              s.spreadRadius == -2,
        ),
        isTrue,
        reason: 'danger should glow like filled, with the error accent',
      );
    });

    testWidgets('follows copyWith(colorScheme:) — not a fixed token', (
      tester,
    ) async {
      // Proof that danger reads colorScheme.error rather than the frozen
      // PulseSemantics.danger token: re-branding the scheme re-tints it.
      const brandError = Color(0xFF9F1239);
      const brandOnError = Color(0xFFFFF1F2);
      expect(brandError, isNot(equals(PulseSemantics.danger)));

      final base = PulseTheme.light();
      final rebranded = base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          error: brandError,
          onError: brandOnError,
        ),
      );

      await tester.pumpWidget(
        wrap(
          PulseButton(
            variant: PulseButtonVariant.danger,
            onPressed: () {},
            child: const Text('削除'),
          ),
          theme: rebranded,
        ),
      );

      final style =
          tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      expect(
        style.backgroundColor!.resolve(<WidgetState>{}),
        equals(brandError),
      );
      expect(
        style.foregroundColor!.resolve(<WidgetState>{}),
        equals(brandOnError),
      );
    });

    testWidgets('tap fires handler', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          PulseButton(
            variant: PulseButtonVariant.danger,
            onPressed: () => tapped = true,
            child: const Text('削除'),
          ),
        ),
      );

      await tester.tap(find.text('削除'));
      expect(tapped, isTrue);
    });
  });

  group('PulseButton — isLoading', () {
    testWidgets('shows exactly one spinner in place of the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PulseButton(
            onPressed: () {},
            isLoading: true,
            child: const Text('保存する'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // The label is still laid out (that is what preserves the width) but is
      // painted at opacity 0 — while staying in the semantics tree, so the
      // busy button keeps its accessible name.
      expect(find.text('保存する'), findsOneWidget);
      final labelOpacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('保存する'), matching: find.byType(Opacity)),
      );
      expect(labelOpacity.opacity, equals(0));
      expect(
        labelOpacity.alwaysIncludeSemantics,
        isTrue,
        reason:
            'RenderOpacity drops its child semantics at alpha 0; without '
            'alwaysIncludeSemantics the loading button would have no name',
      );
    });

    testWidgets('swallows taps even though onPressed is non-null', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          PulseButton(
            onPressed: () => tapped = true,
            isLoading: true,
            child: const Text('保存する'),
          ),
        ),
      );

      await tester.tap(find.byType(PulseButton), warnIfMissed: false);
      await tester.pump();
      expect(
        tapped,
        isFalse,
        reason: 'a loading button must not re-submit the in-flight action',
      );
    });

    testWidgets('is NOT dimmed — loading and disabled are distinct states', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PulseButton(
            onPressed: () {},
            isLoading: true,
            child: const Text('保存する'),
          ),
        ),
      );

      // No dimming wrapper above the Material button (the Opacity(0) that
      // hides the label lives *inside* it).
      expect(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );

      // Contrast: a genuinely disabled button (no loading) does dim to 0.5.
      await tester.pumpWidget(
        wrap(const PulseButton(onPressed: null, child: Text('保存する'))),
      );
      final dim = tester.widget<Opacity>(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(dim.opacity, equals(0.5));
    });

    testWidgets('keeps the glow while loading', (tester) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        wrap(
          PulseButton(
            onPressed: () {},
            isLoading: true,
            child: const Text('保存する'),
          ),
          theme: theme,
        ),
      );

      final glows = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byType(FilledButton),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .expand((d) => d.boxShadow ?? const <BoxShadow>[]);
      expect(
        glows.any(
          (s) => s.color == theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
        isTrue,
      );
    });

    for (final size in PulseButtonSize.values) {
      testWidgets('${size.name} keeps its width when the spinner appears', (
        tester,
      ) async {
        // The headline guarantee: submitting a form must not resize the button
        // under the user's finger.
        await tester.pumpWidget(
          wrap(
            PulseButton(
              onPressed: () {},
              size: size,
              child: const Text('保存する'),
            ),
          ),
        );
        final idle = tester.getSize(find.byType(PulseButton));

        await tester.pumpWidget(
          wrap(
            PulseButton(
              onPressed: () {},
              size: size,
              isLoading: true,
              child: const Text('保存する'),
            ),
          ),
        );
        final busy = tester.getSize(find.byType(PulseButton));

        expect(
          busy.width,
          equals(idle.width),
          reason: '${size.name} button width jumped when isLoading flipped',
        );
      });
    }

    testWidgets('spinner is sized to the label font size', (tester) async {
      // small=14 / medium=16 / large=18 — the spinner occupies the space the
      // text glyphs would have.
      const expected = <PulseButtonSize, double>{
        PulseButtonSize.small: 14,
        PulseButtonSize.medium: 16,
        PulseButtonSize.large: 18,
      };
      for (final entry in expected.entries) {
        await tester.pumpWidget(
          wrap(
            PulseButton(
              onPressed: () {},
              size: entry.key,
              isLoading: true,
              child: const Text('保存する'),
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(CircularProgressIndicator)),
          equals(Size(entry.value, entry.value)),
          reason: '${entry.key.name} spinner box',
        );
      }
    });

    testWidgets('loadingSemanticsLabel reaches the spinner', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          PulseButton(
            onPressed: () {},
            isLoading: true,
            loadingSemanticsLabel: '保存中',
            child: const Text('保存する'),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.semanticsLabel, equals('保存中'));
      // …and it is announced *in addition to* the button's own name, not
      // instead of it.
      final data =
          tester.getSemantics(find.byType(FilledButton)).getSemanticsData();
      expect(data.label, contains('保存中'));
      expect(data.label, contains('保存する'));
      handle.dispose();
    });

    testWidgets('keeps an accessible name when loadingSemanticsLabel is null', (
      tester,
    ) async {
      // Regression: hiding the label from assistive tech left the busy button
      // with label="" — an interactive element with no accessible name, so a
      // screen-reader user could not tell which control had gone quiet.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          PulseButton(
            onPressed: () {},
            isLoading: true,
            child: const Text('保存する'),
          ),
        ),
      );

      final data =
          tester.getSemantics(find.byType(FilledButton)).getSemanticsData();
      expect(
        data.label,
        isNot(isEmpty),
        reason: 'a loading button must never be nameless',
      );
      expect(data.label, contains('保存する'));
      // It still reports as a *disabled button* — that part of the contract is
      // unchanged; only the name was being lost.
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });
  });

  group('PulseButton — a11y regression (D1) for danger / loading', () {
    for (final size in PulseButtonSize.values) {
      testWidgets('danger ${size.name} meets the 48dp tap-target guideline', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          wrap(
            PulseButton(
              variant: PulseButtonVariant.danger,
              onPressed: () {},
              size: size,
              child: const Text('削除'),
            ),
          ),
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }

    for (final size in PulseButtonSize.values) {
      testWidgets('loading ${size.name} still reserves a 48dp target', (
        tester,
      ) async {
        // androidTapTargetGuideline only inspects nodes that expose a tap
        // action, and a loading button reports as disabled — so it would pass
        // vacuously. Measure the laid-out Material tap target instead.
        await tester.pumpWidget(
          wrap(
            PulseButton(
              onPressed: () {},
              size: size,
              isLoading: true,
              child: const Text('保存する'),
            ),
          ),
        );

        final target = tester.getSize(find.byType(FilledButton));
        expect(target.height, greaterThanOrEqualTo(48.0));
        expect(target.width, greaterThanOrEqualTo(48.0));
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
