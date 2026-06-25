/// PULSE — i-Willink's mobile-first canonical design system for Flutter.
///
/// PULSE is the [ADR-018] mobile-first source of truth for i-Willink app UI.
/// Design tokens are not hand-mirrored here: they are code-generated from the
/// published `@willink-labs/tokens` DTCG JSON contract, which keeps web
/// (`@willink-labs/*` React) and mobile (this package) at parity from a single
/// token SSOT.
///
/// Stage 0 ships the package skeleton only — the [PulseTheme] factory returns a
/// Material 3 baseline `ThemeData`. Component widgets (`Pulse*`) and
/// codegen'd token classes land in subsequent stages; see the README and
/// `docs/adr/0001-pulse-mobile-first-architecture.md`.
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:pulse_theme/pulse_theme.dart';
///
/// MaterialApp(
///   theme: PulseTheme.light(),
///   // Re-brand via standard Material 3 copyWith — every future Pulse* widget
///   // reads colors from Theme.of(context).colorScheme, so overrides flow
///   // through automatically:
///   // theme: PulseTheme.light().copyWith(
///   //   colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
///   // ),
///   home: ...,
/// );
/// ```
library;

import 'package:flutter/material.dart';

/// Entry point for the PULSE Material 3 theme.
///
/// Stage 0 exposes a single [PulseTheme.light] factory returning a Material 3
/// baseline `ThemeData`. It is intentionally a thin stub: the canonical PULSE
/// `ColorScheme`, `TextTheme`, component themes and `ThemeExtension`s are
/// derived from the `@willink-labs/tokens` DTCG contract via codegen in a
/// later stage. Consumers customize the brand color the standard Material way
/// (`ThemeData.copyWith(colorScheme: ...)`).
class PulseTheme {
  const PulseTheme._();

  /// Light (default) PULSE baseline.
  ///
  /// Stage 0 returns a vanilla Material 3 light `ThemeData`
  /// (`useMaterial3: true`). Token-derived overrides are added once the
  /// codegen pipeline from `@willink-labs/tokens` is wired up.
  static ThemeData light() {
    // TODO(stage-1): replace the seed below with the codegen'd PULSE
    // ColorScheme derived from @willink-labs/tokens (primitive + semantic
    // DTCG JSON). Do not hand-edit token values here — see CONTRIBUTING.md.
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
      ),
    );
  }
}
