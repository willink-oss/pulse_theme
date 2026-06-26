// PulseTheme — Material 3 ThemeData factories for the PULSE design system.
//
// Light/dark `ColorScheme`s are a faithful projection of the semantic token
// contract: every slot maps to a role in `PulseSemantics` / `PulseSemanticsDark`
// (code-generated from `@willink-labs/tokens` — see `tokens/pulse_tokens.dart`).
// The `TextTheme` sizes come from `PulseFontSize`, and component radii from
// `PulsePrimitives`. Nothing here hand-mirrors a token value.
//
// Brand customization is the standard Material way — override the resulting
// `ColorScheme` with `copyWith(colorScheme: ColorScheme.fromSeed(...))`; every
// component theme below reads from `colorScheme`, so the override flows through.

import 'package:flutter/material.dart';

import 'theme_extensions/pulse_brand_tokens.dart';
import 'tokens/pulse_tokens.dart';

/// Material 3 [ThemeData] factory for the PULSE design system.
class PulseTheme {
  const PulseTheme._();

  /// PULSE light theme (the default — vibrant violet baseline).
  ///
  /// ```dart
  /// MaterialApp(theme: PulseTheme.light());
  /// ```
  static ThemeData light() => _base(_lightScheme, PulseBrandTokens.pulse);

  /// PULSE dark theme — the semantic flip of [light] (ADR-0013). Brand identity
  /// is mode-invariant (`primary` stays the same brand violet); surfaces and
  /// text flip to the dark neutral ladder.
  ///
  /// ```dart
  /// MaterialApp(
  ///   theme: PulseTheme.light(),
  ///   darkTheme: PulseTheme.dark(),
  ///   themeMode: ThemeMode.system,
  /// );
  /// ```
  static ThemeData dark() => _base(_darkScheme, PulseBrandTokens.pulseDark);

  // === ColorSchemes ===
  // Every slot is a semantic role. Slots Material requires but the DTCG
  // contract has no dedicated role for (text on a saturated fill) reuse
  // `brandFg` — the DS's "foreground on a saturated color" token (#ffffff).

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: PulseSemantics.brand,
    onPrimary: PulseSemantics.brandFg,
    primaryContainer: PulseSemantics.brandSoft,
    onPrimaryContainer: PulseSemantics.brandSoftFg,
    secondary: PulseSemantics.brandGlow,
    onSecondary: PulseSemantics.brandFg,
    secondaryContainer: PulseSemantics.brandSoft,
    onSecondaryContainer: PulseSemantics.brandSoftFg,
    tertiary: PulseSemantics.accentCyan,
    onTertiary: PulseSemantics.brandFg,
    error: PulseSemantics.danger,
    onError: PulseSemantics.brandFg,
    surface: PulseSemantics.bg,
    onSurface: PulseSemantics.fg,
    onSurfaceVariant: PulseSemantics.muted,
    surfaceContainerLowest: PulseSemantics.bg,
    surfaceContainerLow: PulseSemantics.surfaceSubtle,
    surfaceContainer: PulseSemantics.surfaceSubtle,
    surfaceContainerHigh: PulseSemantics.surfaceMuted,
    surfaceContainerHighest: PulseSemantics.track,
    outline: PulseSemantics.border,
    outlineVariant: PulseSemantics.border,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: PulseSemanticsDark.brand,
    onPrimary: PulseSemanticsDark.brandFg,
    primaryContainer: PulseSemanticsDark.brandSoft,
    onPrimaryContainer: PulseSemanticsDark.brandSoftFg,
    secondary: PulseSemanticsDark.brandGlow,
    onSecondary: PulseSemanticsDark.brandFg,
    secondaryContainer: PulseSemanticsDark.brandSoft,
    onSecondaryContainer: PulseSemanticsDark.brandSoftFg,
    tertiary: PulseSemanticsDark.accentCyan,
    onTertiary: PulseSemanticsDark.brandFg,
    error: PulseSemanticsDark.danger,
    onError: PulseSemanticsDark.brandFg,
    surface: PulseSemanticsDark.bg,
    onSurface: PulseSemanticsDark.fg,
    onSurfaceVariant: PulseSemanticsDark.muted,
    surfaceContainerLowest: PulseSemanticsDark.bg,
    surfaceContainerLow: PulseSemanticsDark.surfaceSubtle,
    surfaceContainer: PulseSemanticsDark.surfaceSubtle,
    surfaceContainerHigh: PulseSemanticsDark.surfaceMuted,
    surfaceContainerHighest: PulseSemanticsDark.track,
    outline: PulseSemanticsDark.border,
    outlineVariant: PulseSemanticsDark.border,
  );

  // === Type scale ===
  // Only `fontSize` is set (from PulseFontSize, the web `text-*` scale) so each
  // role keeps Material's default weight / letter-spacing; the partial theme is
  // merged onto Material's `Typography`. Display roles + label roles stay at
  // Material defaults — the 12–30 px scale is a body/heading scale, not a
  // large-display scale. Text colors are left null so they follow
  // `colorScheme.onSurface` in both modes.
  static const TextTheme _textTheme = TextTheme(
    headlineMedium: TextStyle(fontSize: PulseFontSize.fontSize3xl),
    headlineSmall: TextStyle(fontSize: PulseFontSize.fontSize2xl),
    titleLarge: TextStyle(fontSize: PulseFontSize.fontSizeXl),
    titleMedium: TextStyle(fontSize: PulseFontSize.fontSizeLg),
    bodyLarge: TextStyle(fontSize: PulseFontSize.fontSizeBase),
    bodyMedium: TextStyle(fontSize: PulseFontSize.fontSizeSm),
    bodySmall: TextStyle(fontSize: PulseFontSize.fontSizeXs),
  );

  /// Shared [ThemeData] assembly — every component theme derives from
  /// [colorScheme], so light and dark stay structurally identical. The
  /// [brandTokens] non-Material extension (gradients / glow / shadows) is
  /// attached so `Pulse*` widgets can read it via `Theme.of(context)`.
  static ThemeData _base(
    ColorScheme colorScheme,
    PulseBrandTokens brandTokens,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _textTheme,
      extensions: <ThemeExtension<dynamic>>[brandTokens],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulsePrimitives.radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulsePrimitives.radiusMd),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulsePrimitives.radiusMd),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulsePrimitives.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulsePrimitives.radiusMd),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        // surfaceContainerLow (not Highest): Highest maps to `track`, which
        // equals `border`/`outline` in light (both neutral-200), so the outline
        // would be invisible. Low (surfaceSubtle) stays distinct from outline in
        // both modes.
        backgroundColor: colorScheme.surfaceContainerLow,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulsePrimitives.radiusFull),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }
}
