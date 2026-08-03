// The ThemeData contract — what a consumer gets from installing PulseTheme
// *without* using a single Pulse* widget.
//
// This is the surface production actually depends on today: clubhouse consumes
// PulseTheme + PulseSpacing and renders raw Material widgets under them. None
// of it was asserted anywhere, so a refactor of `_base` could restyle every
// button in a consumer app with the whole suite still green, and the goldens
// would not notice either — they only render Pulse* components.
//
// These tests are deliberately literal. Their job is to make a change to the
// projected ThemeData show up in a diff and demand a CHANGELOG entry, which is
// what "the public API is frozen at 1.0" has to mean for a theme package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  final themes = <String, ThemeData>{
    'light': PulseTheme.light(),
    'dark': PulseTheme.dark(),
  };

  BorderRadius radiusOf(ShapeBorder? shape) =>
      (shape! as RoundedRectangleBorder).borderRadius as BorderRadius;

  themes.forEach((mode, theme) {
    final colors = theme.colorScheme;

    group('ThemeData contract ($mode) — component themes', () {
      test('appBarTheme is flat and surface-colored', () {
        final t = theme.appBarTheme;
        expect(t.backgroundColor, colors.surface);
        expect(t.foregroundColor, colors.onSurface);
        expect(t.elevation, 0);
        expect(t.scrolledUnderElevation, 0);
        expect(t.centerTitle, isFalse);
      });

      test('cardTheme uses radiusLg and clips its content', () {
        final t = theme.cardTheme;
        expect(t.color, colors.surface);
        expect(t.elevation, 1);
        expect(
          radiusOf(t.shape),
          BorderRadius.circular(PulsePrimitives.radiusLg),
        );
        expect(t.clipBehavior, Clip.antiAlias);
      });

      // Filled and elevated are intentionally identical: the DS has one solid
      // button, and an app reaching for ElevatedButton should not get a
      // different one by accident.
      final solidButtons = <String, ButtonStyle>{
        'filledButtonTheme': theme.filledButtonTheme.style!,
        'elevatedButtonTheme': theme.elevatedButtonTheme.style!,
      };
      solidButtons.forEach((name, s) {
        test('$name is the solid button', () {
          expect(s.backgroundColor!.resolve({}), colors.primary);
          expect(s.foregroundColor!.resolve({}), colors.onPrimary);
          expect(
            s.padding!.resolve({}),
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          );
          expect(s.textStyle!.resolve({})!.fontWeight, FontWeight.w700);
          expect(s.elevation!.resolve({}), 0);
        });
      });

      test('outlinedButtonTheme inks with onSurface, not the brand', () {
        final s = theme.outlinedButtonTheme.style!;
        expect(s.foregroundColor!.resolve({}), colors.onSurface);
        expect(s.side!.resolve({})!.color, colors.outline);
        expect(
          s.padding!.resolve({}),
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        );
        expect(s.textStyle!.resolve({})!.fontWeight, FontWeight.w700);
      });

      // One button shape across the DS. These were StadiumBorder until 0.6.0,
      // which meant a plain FilledButton was a pill while PulseButton — and
      // therefore the same app — drew 8px rounded rectangles.
      test('every themed button uses radiusMd, matching PulseButton', () {
        final expected = BorderRadius.circular(PulsePrimitives.radiusMd);
        final styles = <String, ButtonStyle>{
          'filled': theme.filledButtonTheme.style!,
          'elevated': theme.elevatedButtonTheme.style!,
          'outlined': theme.outlinedButtonTheme.style!,
        };
        styles.forEach((name, s) {
          final shape = s.shape!.resolve({})!;
          expect(shape, isA<RoundedRectangleBorder>(), reason: name);
          expect(
            (shape as RoundedRectangleBorder).borderRadius,
            expected,
            reason: '$name should match PulseButton',
          );
        });
      });

      // The one that renders a DS-blue cancel button inside a re-branded app
      // when the theme is built from the wrong scheme — see the re-brand group.
      test('textButtonTheme inks with primary', () {
        final s = theme.textButtonTheme.style!;
        expect(s.foregroundColor!.resolve({}), colors.primary);
        expect(
          s.padding!.resolve({}),
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        );
        expect(s.textStyle!.resolve({})!.fontWeight, FontWeight.w700);
      });

      test('dialogTheme is a radiusLg surface', () {
        final t = theme.dialogTheme;
        expect(t.backgroundColor, colors.surface);
        expect(
          radiusOf(t.shape),
          BorderRadius.circular(PulsePrimitives.radiusLg),
        );
      });

      test('inputDecorationTheme borders are radiusMd in all four states', () {
        final t = theme.inputDecorationTheme;
        expect(t.filled, isTrue);
        expect(t.fillColor, colors.surface);
        expect(
          t.contentPadding,
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        );

        final expected = BorderRadius.circular(PulsePrimitives.radiusMd);
        for (final (name, border) in <(String, InputBorder?)>[
          ('border', t.border),
          ('enabledBorder', t.enabledBorder),
          ('focusedBorder', t.focusedBorder),
          ('errorBorder', t.errorBorder),
        ]) {
          expect(
            (border! as OutlineInputBorder).borderRadius,
            expected,
            reason: '$name should use radiusMd',
          );
        }

        expect(
          (t.enabledBorder! as OutlineInputBorder).borderSide.color,
          colors.outline,
        );
        final focused = (t.focusedBorder! as OutlineInputBorder).borderSide;
        expect(focused.color, colors.primary);
        expect(focused.width, 2);
        expect(
          (t.errorBorder! as OutlineInputBorder).borderSide.color,
          colors.error,
        );

        // Left null on purpose: a labelStyle without an explicit fontSize lets
        // titleMedium's 18px leak into every field label, because Material's
        // InputDecorator reads titleMedium with no useMaterial3 guard.
        expect(t.labelStyle, isNull);
      });

      test('dividerTheme is a hairline that occupies no extra space', () {
        final t = theme.dividerTheme;
        expect(t.color, colors.outlineVariant);
        expect(t.thickness, 1);
        expect(t.space, 1);
      });

      test(
        'chipTheme sits on surfaceContainerLow so its outline stays visible',
        () {
          final t = theme.chipTheme;
          // Not surfaceContainerHighest: that maps to `track`, which equals
          // `border`/`outline` in light, so the outline would vanish.
          expect(t.backgroundColor, colors.surfaceContainerLow);
          expect(t.backgroundColor, isNot(colors.surfaceContainerHighest));
          expect(t.labelStyle!.color, colors.onSurface);
          expect(t.side!.color, colors.outline);
          expect(
            radiusOf(t.shape),
            BorderRadius.circular(PulsePrimitives.radiusFull),
          );
        },
      );

      test('progressIndicatorTheme tracks primary', () {
        expect(theme.progressIndicatorTheme.color, colors.primary);
      });

      test('scaffold background is the surface role', () {
        expect(theme.scaffoldBackgroundColor, colors.surface);
        expect(theme.useMaterial3, isTrue);
      });
    });

    group('ThemeData contract ($mode) — ColorScheme slots Material derives', () {
      // PULSE projects the roles the DTCG contract defines. The rest are
      // Material's own fallbacks, which means they are NOT token-controlled:
      // pinning them here marks exactly where the token contract stops, so a
      // Flutter upgrade that changes a fallback surfaces as a failure here
      // rather than as an unexplained color shift in a consumer app.
      test('unset slots fall back to their documented source', () {
        expect(colors.errorContainer, colors.error);
        expect(colors.onErrorContainer, colors.onError);
        expect(colors.inverseSurface, colors.onSurface);
        expect(colors.onInverseSurface, colors.surface);
        expect(colors.shadow, const Color(0xff000000));
        expect(colors.scrim, const Color(0xff000000));
      });

      test('surfaceTint is set explicitly, not inherited', () {
        // Same value as primary, so nothing moves — but it is now part of the
        // contract instead of a Material default a re-brand could shift.
        expect(colors.surfaceTint, colors.primary);
      });

      test('inversePrimary is set explicitly, not inherited from onPrimary', () {
        // Material's fallback is `onPrimary`, i.e. white in both modes, which
        // is invisible on the dark scheme's light inverse surface. Contrast is
        // asserted in a11y_contrast_test.dart.
        expect(colors.inversePrimary, isNot(colors.onPrimary));
      });
    });
  });

  group('ThemeData contract — the TextTheme boundary', () {
    // PULSE sets fontSize on 7 roles only. Everything else — weights, letter
    // spacing, and the display/label roles entirely — comes from Flutter's
    // Material 3 typography. That boundary is part of the 1.0 promise: a
    // Flutter upgrade that moves the M3 typescale moves these, and that is not
    // a pulse_theme breaking change.
    //
    // Read through Theme.of(context), never ThemeData.textTheme directly: the
    // typescale geometry is only merged in by ThemeData.localize(), so the raw
    // field reports null fontSize for roles PULSE does not set.
    testWidgets('PULSE owns 7 sizes; the rest are Flutter defaults', (
      tester,
    ) async {
      late TextTheme text;
      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.light(),
          home: Builder(
            builder: (context) {
              text = Theme.of(context).textTheme;
              return const SizedBox();
            },
          ),
        ),
      );

      // Owned by the token contract.
      expect(text.headlineMedium!.fontSize, PulseFontSize.fontSize3xl);
      expect(text.headlineSmall!.fontSize, PulseFontSize.fontSize2xl);
      expect(text.titleLarge!.fontSize, PulseFontSize.fontSizeXl);
      expect(text.titleMedium!.fontSize, PulseFontSize.fontSizeLg);
      expect(text.bodyLarge!.fontSize, PulseFontSize.fontSizeBase);
      expect(text.bodyMedium!.fontSize, PulseFontSize.fontSizeSm);
      expect(text.bodySmall!.fontSize, PulseFontSize.fontSizeXs);

      // Inherited from Material 3, pinned so a Flutter typescale change is
      // visible here first.
      expect(text.displayLarge!.fontSize, 57);
      expect(text.labelLarge!.fontSize, 14);
      expect(text.labelSmall!.fontSize, 11);
    });
  });

  group('re-branding', () {
    const brandTeal = Color(0xFF0F766E);

    testWidgets('PulseTheme.light(colorScheme:) reaches raw Material widgets', (
      tester,
    ) async {
      final theme = PulseTheme.light(
        colorScheme: PulseTheme.lightColorScheme.copyWith(primary: brandTeal),
      );

      // The component themes are built from the scheme that was handed in,
      // so a plain TextButton — the clubhouse cancel-button case — follows.
      expect(
        theme.textButtonTheme.style!.foregroundColor!.resolve({}),
        brandTeal,
      );
      expect(
        theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
        brandTeal,
      );
      expect(
        (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
            .borderSide
            .color,
        brandTeal,
      );

      // …and it survives all the way to a rendered widget.
      late Color rendered;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                rendered =
                    TextButtonTheme.of(
                      context,
                    ).style!.foregroundColor!.resolve({})!;
                return TextButton(onPressed: () {}, child: const Text('OK'));
              },
            ),
          ),
        ),
      );
      expect(rendered, brandTeal);
    });

    test('slots left alone keep their token values', () {
      final theme = PulseTheme.light(
        colorScheme: PulseTheme.lightColorScheme.copyWith(primary: brandTeal),
      );
      expect(theme.colorScheme.error, PulseSemantics.danger);
      expect(theme.colorScheme.surface, PulseSemantics.bg);
      expect(theme.colorScheme.onSurface, PulseSemantics.fg);
    });

    test('brandTokens re-brands the non-Material extras in the same call', () {
      final theme = PulseTheme.light(
        colorScheme: PulseTheme.lightColorScheme.copyWith(primary: brandTeal),
        brandTokens: PulseBrandTokens.pulse.copyWith(brandGlow: brandTeal),
      );
      expect(theme.extension<PulseBrandTokens>()!.brandGlow, brandTeal);
      // Not overridden, so it stays the preset.
      expect(
        theme.extension<PulseBrandTokens>()!.aiGradient,
        PulseBrandTokens.pulse.aiGradient,
      );
    });

    test('dark() takes the same overrides', () {
      final theme = PulseTheme.dark(
        colorScheme: PulseTheme.darkColorScheme.copyWith(primary: brandTeal),
      );
      expect(
        theme.textButtonTheme.style!.foregroundColor!.resolve({}),
        brandTeal,
      );
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, PulseSemanticsDark.bg);
    });

    // The trap this API exists to replace. Pinned rather than merely
    // documented: if a future Flutter made copyWith rebuild component themes,
    // this test fails and the warning in PulseTheme.light's dartdoc — and in
    // the adoption guide — has to be rewritten.
    test(
      'ThemeData.copyWith(colorScheme:) does NOT restyle component themes',
      () {
        final base = PulseTheme.light();
        final patched = base.copyWith(
          colorScheme: base.colorScheme.copyWith(primary: brandTeal),
        );

        expect(patched.colorScheme.primary, brandTeal);
        expect(
          patched.textButtonTheme.style!.foregroundColor!.resolve({}),
          PulseSemantics.brand,
          reason:
              'component themes were built before the copyWith, so they still '
              'carry the blue baseline — this is the bug PulseTheme.light('
              'colorScheme:) exists to avoid',
        );
      },
    );
  });
}
