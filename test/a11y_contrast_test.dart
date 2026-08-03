// WCAG AA contrast lock for the (accent, on-accent) pairs PULSE components
// actually paint.
//
// Solid-fill pairs and brand text on the page surface are both locked. The
// latter covers outline/ghost button labels and the selected tab label — the
// reason PULSE adapts dark primary to a lighter generated brand step.
//
// The button label is `FontWeight.w600` at 14 / 16 / 18 logical px
// (`PulseButton._fontSize`). None of those reaches WCAG's 18.66px "large
// (bold) text" threshold, so the required ratio is 4.5:1 — not 3:1.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

/// WCAG 2.x relative luminance of one sRGB channel (already 0..1).
double _linearize(double channel) =>
    channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

/// WCAG 2.x relative luminance. Assumes fully opaque colors — every color in
/// the PULSE schemes is.
double _relativeLuminance(Color c) =>
    0.2126 * _linearize(c.r) +
    0.7152 * _linearize(c.g) +
    0.0722 * _linearize(c.b);

/// WCAG 2.x contrast ratio, 1.0 … 21.0.
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('contrastRatio — sanity anchors', () {
    test('black on white is 21:1 and a color against itself is 1:1', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
      expect(
        contrastRatio(PulsePrimitives.red500, PulsePrimitives.red500),
        closeTo(1, 0.001),
      );
    });
  });

  group('saturated ColorScheme fills meet WCAG AA (4.5:1)', () {
    // PulseButton reads primary/onPrimary and error/onError. Secondary and
    // tertiary are public Material slots, so lock those on-color pairs too.
    final pairs = <String, (Color, Color)>{
      'light filled  (primary/onPrimary)': (
        PulseTheme.light().colorScheme.primary,
        PulseTheme.light().colorScheme.onPrimary,
      ),
      'light danger  (error/onError)': (
        PulseTheme.light().colorScheme.error,
        PulseTheme.light().colorScheme.onError,
      ),
      'light secondary/onSecondary': (
        PulseTheme.light().colorScheme.secondary,
        PulseTheme.light().colorScheme.onSecondary,
      ),
      'light tertiary/onTertiary': (
        PulseTheme.light().colorScheme.tertiary,
        PulseTheme.light().colorScheme.onTertiary,
      ),
      'dark  filled  (primary/onPrimary)': (
        PulseTheme.dark().colorScheme.primary,
        PulseTheme.dark().colorScheme.onPrimary,
      ),
      'dark  danger  (error/onError)': (
        PulseTheme.dark().colorScheme.error,
        PulseTheme.dark().colorScheme.onError,
      ),
      'dark secondary/onSecondary': (
        PulseTheme.dark().colorScheme.secondary,
        PulseTheme.dark().colorScheme.onSecondary,
      ),
      'dark tertiary/onTertiary': (
        PulseTheme.dark().colorScheme.tertiary,
        PulseTheme.dark().colorScheme.onTertiary,
      ),
    };

    for (final entry in pairs.entries) {
      test('${entry.key} >= 4.5:1', () {
        final (fill, ink) = entry.value;
        expect(
          contrastRatio(fill, ink),
          greaterThanOrEqualTo(4.5),
          reason:
              '${entry.key}: ink ${ink.toARGB32().toRadixString(16)} on fill '
              '${fill.toARGB32().toRadixString(16)} is below WCAG AA for '
              'normal-size text. The PulseButton label is w600 at 14/16/18px, '
              'which is NOT WCAG "large text" (>=18.66px bold), so 3:1 does '
              'not apply.',
        );
      });
    }
  });

  group('brand text on surfaces meets WCAG AA (4.5:1)', () {
    final pairs = <String, (Color, Color)>{
      'light primary/surface': (
        PulseTheme.lightColorScheme.primary,
        PulseTheme.lightColorScheme.surface,
      ),
      'dark primary/surface': (
        PulseTheme.darkColorScheme.primary,
        PulseTheme.darkColorScheme.surface,
      ),
    };

    for (final entry in pairs.entries) {
      test('${entry.key} >= 4.5:1', () {
        final (ink, surface) = entry.value;
        expect(contrastRatio(ink, surface), greaterThanOrEqualTo(4.5));
      });
    }
  });

  test('white text clears AA at both brand-gradient endpoints', () {
    for (final endpoint in PulseBrandTokens.pulse.brandGradient.colors) {
      expect(
        contrastRatio(const Color(0xFFFFFFFF), endpoint),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  // `inversePrimary` is what Material paints an action label with on an
  // `inverseSurface` (a plain SnackBar action is the everyday case). PULSE sets
  // both slots, so both are its contract — and the pairing inverts between
  // modes, which is precisely what Material's single fallback cannot express.
  group('inverse surface pairs meet WCAG AA (4.5:1)', () {
    final pairs = <String, (Color, Color)>{
      'light (inverseSurface/inversePrimary)': (
        PulseTheme.lightColorScheme.inverseSurface,
        PulseTheme.lightColorScheme.inversePrimary,
      ),
      'dark  (inverseSurface/inversePrimary)': (
        PulseTheme.darkColorScheme.inverseSurface,
        PulseTheme.darkColorScheme.inversePrimary,
      ),
      'light (inverseSurface/onInverseSurface)': (
        PulseTheme.lightColorScheme.inverseSurface,
        PulseTheme.lightColorScheme.onInverseSurface,
      ),
      'dark  (inverseSurface/onInverseSurface)': (
        PulseTheme.darkColorScheme.inverseSurface,
        PulseTheme.darkColorScheme.onInverseSurface,
      ),
    };

    for (final entry in pairs.entries) {
      test('${entry.key} >= 4.5:1', () {
        final (fill, ink) = entry.value;
        expect(contrastRatio(fill, ink), greaterThanOrEqualTo(4.5));
      });
    }

    test('dark inversePrimary keeps a branded action color', () {
      expect(
        PulseTheme.darkColorScheme.inversePrimary,
        PulsePrimitives.brand600,
      );
      expect(
        PulseTheme.darkColorScheme.inversePrimary,
        isNot(PulseTheme.darkColorScheme.onPrimary),
      );
    });
  });

  group('dark danger regression (the pair that failed)', () {
    test('white on dark red-500 would fail — that is why onError is inked', () {
      // Guards the fix, not just the outcome: if dark `onError` is ever set
      // back to the white `brandFg` token, the pair test above fires and this
      // records why.
      expect(
        contrastRatio(PulseSemanticsDark.danger, PulseSemanticsDark.brandFg),
        lessThan(4.5),
      );
      expect(
        PulseTheme.dark().colorScheme.onError,
        isNot(const Color(0xFFFFFFFF)),
      );
    });
  });
}
