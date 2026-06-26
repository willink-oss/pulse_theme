// Contract tests for the code-generated tokens (lib/src/tokens/pulse_tokens.dart).
//
// These lock the DTCG → Dart *symbol mapping and value conversion* so a change
// to the emitter that silently renames a member or mis-converts a unit fails
// here. Parity with the upstream @willink-labs/tokens SSOT is a separate, hard
// CI gate (token-codegen-gate) that regenerates from the published contract.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  group('PulsePrimitives — color / radius / duration / easing', () {
    test('color hex → Color(0xFF..)', () {
      expect(PulsePrimitives.brand600, const Color(0xFF7C3AED));
      expect(PulsePrimitives.neutral950, const Color(0xFF020617));
      expect(PulsePrimitives.blue600, const Color(0xFF2563EB));
    });

    test('radius dimension rem/px → logical px double', () {
      expect(PulsePrimitives.radiusSm, 4.0); // 0.25rem
      expect(PulsePrimitives.radiusLg, 12.0); // 0.75rem
      expect(PulsePrimitives.radiusXl, 16.0); // 1rem
      expect(PulsePrimitives.radiusFull, 9999.0); // 9999px
    });

    test('duration ms → Duration; easing cubic-bezier → Cubic', () {
      expect(PulsePrimitives.durationFast, const Duration(milliseconds: 150));
      expect(PulsePrimitives.durationSlow, const Duration(milliseconds: 400));
      expect(PulsePrimitives.easingStandard, const Cubic(0.2, 0, 0, 1));
      expect(PulsePrimitives.easingEmphasized, const Cubic(0.3, 0, 0, 1.1));
    });
  });

  group('Scale symbol mapping', () {
    test(
      'PulseSpacing — bare member; numeric-leading step spelled (2xl→xxl)',
      () {
        expect(PulseSpacing.xs, 4.0);
        expect(PulseSpacing.md, 16.0);
        expect(PulseSpacing.xl, 32.0);
        expect(PulseSpacing.xxl, 48.0); // 2xl → xxl, 3rem → 48px
      },
    );

    test('PulseFontSize — prefixed member; digit kept (2xl→fontSize2xl)', () {
      expect(PulseFontSize.fontSizeXs, 12.0); // 0.75rem
      expect(PulseFontSize.fontSizeBase, 16.0); // 1rem
      expect(PulseFontSize.fontSize2xl, 24.0); // 1.5rem
      expect(PulseFontSize.fontSize3xl, 30.0); // 1.875rem
    });
  });

  group('PulseSemantics (light) — aliases folded to primitive refs', () {
    test('hyphen-compound role → camelCase identifier', () {
      expect(PulseSemantics.fgStrong, PulsePrimitives.neutral800);
      expect(PulseSemantics.fgFaint, PulsePrimitives.neutral300);
      expect(PulseSemantics.surfaceInvertedFg, PulsePrimitives.neutral50);
      expect(PulseSemantics.brandSoftFg, PulsePrimitives.brand700);
      expect(PulseSemantics.accentCyan, PulsePrimitives.cyan500);
    });

    test('group shorthand {color.brand} → brand600', () {
      expect(PulseSemantics.ring, PulsePrimitives.brand600);
    });

    test('literal value → Color literal', () {
      expect(PulseSemantics.bg, const Color(0xFFFFFFFF));
      expect(PulseSemantics.brandFg, const Color(0xFFFFFFFF));
    });
  });

  group('PulseSemanticsDark — willink.dark extension flips', () {
    test('flipping roles take the dark value', () {
      expect(PulseSemanticsDark.bg, PulsePrimitives.neutral950);
      expect(PulseSemanticsDark.fg, PulsePrimitives.neutral50);
      expect(PulseSemanticsDark.border, PulsePrimitives.neutral800);
      expect(PulseSemanticsDark.brandHover, PulsePrimitives.brand500);
      expect(PulseSemanticsDark.brandSoft, PulsePrimitives.brand950);
      expect(PulseSemanticsDark.danger, PulsePrimitives.red500);
    });

    test('mode-invariant roles equal their light value', () {
      expect(PulseSemanticsDark.brand, PulseSemantics.brand);
      expect(PulseSemanticsDark.brandFg, PulseSemantics.brandFg);
      expect(PulseSemanticsDark.brandGlow, PulseSemantics.brandGlow);
      expect(PulseSemanticsDark.accentCyan, PulseSemantics.accentCyan);
      expect(PulseSemanticsDark.ring, PulseSemantics.ring);
    });
  });
}
