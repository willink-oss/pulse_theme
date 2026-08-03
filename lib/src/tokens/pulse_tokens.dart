// GENERATED FILE — DO NOT EDIT BY HAND.
//
// Source of truth: @willink-labs/tokens (DTCG JSON — primitive.json +
// semantic.json), the same contract the web `@willink-labs/*` packages
// consume. Regenerate with `node tool/generate_tokens.mjs` after the
// upstream tokens change; the version is pinned by tool/package-lock.json.
//
// CI (token-codegen-gate) re-runs this emitter against the published
// contract and fails on any drift from this committed output — so a
// hand-edit here, or a stale regenerate, breaks the build. See
// CONTRIBUTING.md > "Token rule — codegen only, never hand-edit".

import 'package:flutter/widgets.dart';

/// Primitive (raw) tokens — fixed across the design system; meaningless on
/// their own. Consumers normally use [PulseSemantics] or the [PulseTheme]
/// factories instead of referencing primitives directly.
abstract final class PulsePrimitives {
  const PulsePrimitives._();
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  static const Color neutral950 = Color(0xFF020617);
  static const Color brand50 = Color(0xFFF0F6FF);
  static const Color brand100 = Color(0xFFDBEAFF);
  static const Color brand200 = Color(0xFFBDD9FF);
  static const Color brand300 = Color(0xFF94BFFF);
  static const Color brand400 = Color(0xFF5F9DFF);
  static const Color brand500 = Color(0xFF2E7BFF);
  static const Color brand600 = Color(0xFF1D5FD0);
  static const Color brand700 = Color(0xFF144DAD);
  static const Color brand800 = Color(0xFF113F8E);
  static const Color brand900 = Color(0xFF113573);
  static const Color brand950 = Color(0xFF0B2045);
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);
  static const Color blue950 = Color(0xFF172554);
  static const Color green50 = Color(0xFFECFDF5);
  static const Color green100 = Color(0xFFD1FAE5);
  static const Color green500 = Color(0xFF10B981);
  static const Color green600 = Color(0xFF059669);
  static const Color green700 = Color(0xFF047857);
  static const Color cyan500 = Color(0xFF06B6D4);
  static const Color pink500 = Color(0xFFEC4899);
  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  // Radius (logical px).
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 9999.0;

  // Duration.
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationBase = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // Easing curves.
  static const Cubic easingStandard = Cubic(0.2, 0, 0, 1);
  static const Cubic easingEmphasized = Cubic(0.3, 0, 0, 1.1);
}

/// Spacing scale (logical px) — paddings / gaps / margins. Mirrors the web
/// `--spacing-*` scale so layouts stay consistent across web and mobile.
abstract final class PulseSpacing {
  const PulseSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Font-size scale (logical px) — mirrors the web `--font-size-*` type
/// scale (`text-xs` … `text-3xl`). Wired into [PulseTheme]'s `TextTheme`.
abstract final class PulseFontSize {
  const PulseFontSize._();
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 30.0;
}

/// Elevation / glow shadows — the primitive `shadow` scale parsed from CSS
/// box-shadow into `List<BoxShadow>`. `*Dark` variants come from the
/// `willink.dark` extension (ADR-0013); brand-tinted `glow` is mode-invariant.
abstract final class PulseShadows {
  const PulseShadows._();
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 4),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];
  static const List<BoxShadow> softDark = [
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 4),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];
  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: Color(0x80000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];
  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x4D1D5FD0),
      offset: Offset(0, 0),
      blurRadius: 20,
      spreadRadius: -5,
    ),
  ];
}

/// Semantic color roles (light) — named by role, not by hue. Aliases in
/// the DTCG source are folded to their [PulsePrimitives] reference so a
/// value is never duplicated. This is the default i-Willink mapping.
abstract final class PulseSemantics {
  const PulseSemantics._();
  static const Color bg = Color(0xFFFFFFFF);
  static const Color fg = PulsePrimitives.neutral900;
  static const Color muted = PulsePrimitives.neutral500;
  static const Color fgStrong = PulsePrimitives.neutral800;
  static const Color fgEmphasis = PulsePrimitives.neutral700;
  static const Color fgSecondary = PulsePrimitives.neutral600;
  static const Color fgSubtle = PulsePrimitives.neutral400;
  static const Color fgFaint = PulsePrimitives.neutral300;
  static const Color border = PulsePrimitives.neutral200;
  static const Color surfaceSubtle = PulsePrimitives.neutral50;
  static const Color surfaceMuted = PulsePrimitives.neutral100;
  static const Color track = PulsePrimitives.neutral200;
  static const Color surfaceInverted = PulsePrimitives.neutral900;
  static const Color surfaceInvertedFg = PulsePrimitives.neutral50;
  static const Color ring = PulsePrimitives.brand600;
  static const Color brand = PulsePrimitives.brand600;
  static const Color brandFg = Color(0xFFFFFFFF);
  static const Color brandGlow = PulsePrimitives.brand500;
  static const Color brandHover = PulsePrimitives.brand700;
  static const Color brandActive = PulsePrimitives.brand800;
  static const Color brandSoft = PulsePrimitives.brand100;
  static const Color brandSoftFg = PulsePrimitives.brand700;
  static const Color accentCyan = PulsePrimitives.cyan500;
  static const Color accentPink = PulsePrimitives.pink500;
  static const Color success = PulsePrimitives.green600;
  static const Color warning = PulsePrimitives.amber600;
  static const Color danger = PulsePrimitives.red600;
}

/// Semantic color roles (dark) — the `$extensions["willink.dark"]` flip of
/// [PulseSemantics] (ADR-0013). Roles without a dark extension are
/// mode-invariant and resolve to the same value as the light role.
abstract final class PulseSemanticsDark {
  const PulseSemanticsDark._();
  static const Color bg = PulsePrimitives.neutral950;
  static const Color fg = PulsePrimitives.neutral50;
  static const Color muted = PulsePrimitives.neutral400;
  static const Color fgStrong = PulsePrimitives.neutral100;
  static const Color fgEmphasis = PulsePrimitives.neutral200;
  static const Color fgSecondary = PulsePrimitives.neutral300;
  static const Color fgSubtle = PulsePrimitives.neutral500;
  static const Color fgFaint = PulsePrimitives.neutral600;
  static const Color border = PulsePrimitives.neutral800;
  static const Color surfaceSubtle = PulsePrimitives.neutral900;
  static const Color surfaceMuted = PulsePrimitives.neutral800;
  static const Color track = PulsePrimitives.neutral700;
  static const Color surfaceInverted = PulsePrimitives.neutral100;
  static const Color surfaceInvertedFg = PulsePrimitives.neutral900;
  static const Color ring = PulsePrimitives.brand600;
  static const Color brand = PulsePrimitives.brand600;
  static const Color brandFg = Color(0xFFFFFFFF);
  static const Color brandGlow = PulsePrimitives.brand500;
  static const Color brandHover = PulsePrimitives.brand500;
  static const Color brandActive = PulsePrimitives.brand400;
  static const Color brandSoft = PulsePrimitives.brand950;
  static const Color brandSoftFg = PulsePrimitives.brand300;
  static const Color accentCyan = PulsePrimitives.cyan500;
  static const Color accentPink = PulsePrimitives.pink500;
  static const Color success = PulsePrimitives.green500;
  static const Color warning = PulsePrimitives.amber500;
  static const Color danger = PulsePrimitives.red500;
}
