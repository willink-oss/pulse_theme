// ThemeExtension that exposes non-Material brand tokens (glow / gradient /
// custom shadows). Material 3's ColorScheme alone cannot represent these.
//
// Ported (clean-room) from i-Willink's own MIT-licensed
// willink-design-system/packages/flutter_theme (Willink* → Pulse*). Shadows are
// no longer hand-coded here — they reference the code-generated PulseShadows.

import 'package:flutter/material.dart';

import '../tokens/pulse_tokens.dart';

/// Non-Material brand tokens carried alongside [ThemeData].
///
/// Access from a widget via:
/// ```dart
/// final brandTokens = Theme.of(context).extension<PulseBrandTokens>()!;
/// ```
@immutable
class PulseBrandTokens extends ThemeExtension<PulseBrandTokens> {
  const PulseBrandTokens({
    required this.brandGlow,
    required this.brandGradient,
    required this.subtleGradient,
    required this.aiGradient,
    required this.shadowSoft,
    required this.shadowGlow,
  });

  /// Brand glow color (used as a shadow color base for primary buttons).
  /// Mirrors the React DS `--shadow-glow` semantic token.
  final Color brandGlow;

  /// Hero / primary surface gradient. Mirrors `bg-gradient-primary` from the
  /// React DS preset (brand → blue diagonal).
  final LinearGradient brandGradient;

  /// Subtle background gradient (white → brand-50 → sky-50). Mirrors
  /// `bg-gradient-subtle`. Useful for hero sections and large surfaces that
  /// shouldn't overwhelm the foreground.
  final LinearGradient subtleGradient;

  /// AI-tech accent gradient (cyan → brand-500 → pink). Mirrors `bg-gradient-ai`.
  /// Reserved for "AI"-flavored UI moments — not for general use.
  final LinearGradient aiGradient;

  /// Soft default shadow (mirrors `--shadow-soft`).
  final List<BoxShadow> shadowSoft;

  /// Brand-tinted glow shadow (mirrors `--shadow-glow`).
  final List<BoxShadow> shadowGlow;

  @override
  PulseBrandTokens copyWith({
    Color? brandGlow,
    LinearGradient? brandGradient,
    LinearGradient? subtleGradient,
    LinearGradient? aiGradient,
    List<BoxShadow>? shadowSoft,
    List<BoxShadow>? shadowGlow,
  }) {
    return PulseBrandTokens(
      brandGlow: brandGlow ?? this.brandGlow,
      brandGradient: brandGradient ?? this.brandGradient,
      subtleGradient: subtleGradient ?? this.subtleGradient,
      aiGradient: aiGradient ?? this.aiGradient,
      shadowSoft: shadowSoft ?? this.shadowSoft,
      shadowGlow: shadowGlow ?? this.shadowGlow,
    );
  }

  @override
  PulseBrandTokens lerp(
    covariant ThemeExtension<PulseBrandTokens>? other,
    double t,
  ) {
    if (other is! PulseBrandTokens) return this;
    return PulseBrandTokens(
      brandGlow: Color.lerp(brandGlow, other.brandGlow, t)!,
      brandGradient:
          LinearGradient.lerp(brandGradient, other.brandGradient, t)!,
      subtleGradient:
          LinearGradient.lerp(subtleGradient, other.subtleGradient, t)!,
      aiGradient: LinearGradient.lerp(aiGradient, other.aiGradient, t)!,
      shadowSoft: t < 0.5 ? shadowSoft : other.shadowSoft,
      shadowGlow: t < 0.5 ? shadowGlow : other.shadowGlow,
    );
  }

  // === Default presets per mode ===
  // The subtle and AI gradients reuse the same primitive triplet across modes
  // (white → brand-50 → sky-50 / cyan → brand-500 → pink). Brand identity is
  // expressed through `brandGlow` and `brandGradient`.
  //
  // Mode-invariant pieces (ADR-0013): `brandGradient`, `aiGradient`, and
  // `shadowGlow` are shared between [pulse] and [pulseDark] — brand identity
  // does not flip. Only the white-anchored `subtleGradient` and the black-alpha
  // `shadowSoft` carry dark variants.

  static const LinearGradient _subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), PulsePrimitives.brand50, PulsePrimitives.sky50],
    stops: [0.0, 0.5, 1.0],
  );

  /// Dark counterpart of [_subtleGradient] — mirrors the preset's dark
  /// `bg-gradient-subtle` derivation: neutral-950 → brand-950 → neutral-900.
  /// The white / sky-50 anchors would pin a light tint under a dark root.
  static const LinearGradient _subtleGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      PulsePrimitives.neutral950,
      PulsePrimitives.brand950,
      PulsePrimitives.neutral900,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient _aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      PulsePrimitives.cyan500,
      PulsePrimitives.brand500,
      PulsePrimitives.pink500,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Hero gradient for the PULSE brand (brand-600 → blue-600 diagonal).
  /// Mode-invariant — shared by [pulse] and [pulseDark].
  static const LinearGradient _brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PulsePrimitives.brand600, PulsePrimitives.blue600],
    stops: [0.0, 1.0],
  );

  /// Default tokens for the PULSE (light) brand.
  static const PulseBrandTokens pulse = PulseBrandTokens(
    brandGlow: PulsePrimitives.brand500,
    brandGradient: _brandGradient,
    subtleGradient: _subtleGradient,
    aiGradient: _aiGradient,
    shadowSoft: PulseShadows.soft,
    shadowGlow: PulseShadows.glow,
  );

  /// Dark-mode tokens for the PULSE brand (ADR-0013).
  ///
  /// Brand identity is mode-invariant: [brandGlow], [brandGradient],
  /// [aiGradient], and [shadowGlow] are identical to [pulse]. Only the
  /// white-anchored pieces flip — [subtleGradient] moves to the dark surface
  /// ladder (neutral-950 → brand-950 → neutral-900) and [shadowSoft] raises its
  /// black alpha (`PulseShadows.softDark`).
  static const PulseBrandTokens pulseDark = PulseBrandTokens(
    brandGlow: PulsePrimitives.brand500,
    brandGradient: _brandGradient,
    subtleGradient: _subtleGradientDark,
    aiGradient: _aiGradient,
    shadowSoft: PulseShadows.softDark,
    shadowGlow: PulseShadows.glow,
  );
}
