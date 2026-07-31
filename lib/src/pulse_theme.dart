// PulseTheme — Material 3 ThemeData factories for the PULSE design system.
//
// Light/dark `ColorScheme`s are a faithful projection of the semantic token
// contract: every slot maps to a role in `PulseSemantics` / `PulseSemanticsDark`
// (code-generated from `@willink-labs/tokens` — see `tokens/pulse_tokens.dart`).
// The `TextTheme` sizes come from `PulseFontSize`, and component radii from
// `PulsePrimitives`. Nothing here hand-mirrors a token value.
//
// Brand customization goes through the factories' own `colorScheme` argument,
// NOT through `ThemeData.copyWith(colorScheme: ...)` — see the note on
// [PulseTheme.light]. The component themes below are built *from* the scheme
// they are handed, so they can only be correct if they are handed the right one.

import 'package:flutter/material.dart';

import 'theme_extensions/pulse_brand_tokens.dart';
import 'theme_extensions/pulse_strings.dart';
import 'tokens/pulse_radius.dart';
import 'tokens/pulse_tokens.dart';

/// Material 3 [ThemeData] factory for the PULSE design system.
abstract final class PulseTheme {
  const PulseTheme._();

  /// PULSE light theme (the default — vibrant violet baseline).
  ///
  /// ```dart
  /// MaterialApp(theme: PulseTheme.light());
  /// ```
  ///
  /// ## Re-branding
  ///
  /// Pass your own [colorScheme] — start from [lightColorScheme] so every slot
  /// you do not care about keeps its token value:
  ///
  /// ```dart
  /// MaterialApp(
  ///   theme: PulseTheme.light(
  ///     colorScheme: PulseTheme.lightColorScheme.copyWith(
  ///       primary: const Color(0xFF2E7BFF),
  ///     ),
  ///   ),
  /// );
  /// ```
  ///
  /// **Do not use `PulseTheme.light().copyWith(colorScheme: ...)` for this.**
  /// `ThemeData.copyWith` replaces the `colorScheme` field, but the component
  /// themes (`filledButtonTheme`, `textButtonTheme`, `inputDecorationTheme`, …)
  /// have already been *built* from the old scheme by then, and Material reads
  /// those — so a plain `TextButton` or `FilledButton` keeps painting the
  /// violet baseline while `Pulse*` widgets, which resolve
  /// `Theme.of(context).colorScheme` at build time, switch to your brand. That
  /// split is not hypothetical: it is what makes a cancel button render DS
  /// violet inside a blue-branded app.
  ///
  /// [brandTokens] re-brands the non-Material extras (glow, gradients) in the
  /// same call. They live in a [PulseBrandTokens] extension rather than the
  /// `ColorScheme`, so overriding only the scheme would leave a blue CTA with a
  /// violet glow:
  ///
  /// ```dart
  /// PulseTheme.light(
  ///   colorScheme: PulseTheme.lightColorScheme.copyWith(primary: brandBlue),
  ///   brandTokens: PulseBrandTokens.pulse.copyWith(brandGlow: brandBlue),
  /// );
  /// ```
  static ThemeData light({
    ColorScheme? colorScheme,
    PulseBrandTokens? brandTokens,
    PulseStrings? strings,
  }) => _base(
    colorScheme ?? lightColorScheme,
    brandTokens ?? PulseBrandTokens.pulse,
    strings ?? PulseStrings.en,
  );

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
  ///
  /// Takes the same [colorScheme] / [brandTokens] overrides as [light] — start
  /// from [darkColorScheme]. When you re-brand both modes, re-check contrast in
  /// dark separately: a brand color that clears WCAG AA on a light surface can
  /// fail on a dark one, which is why PULSE's own dark `onError` is the only
  /// slot that does not reuse `brandFg`.
  static ThemeData dark({
    ColorScheme? colorScheme,
    PulseBrandTokens? brandTokens,
    PulseStrings? strings,
  }) => _base(
    colorScheme ?? darkColorScheme,
    brandTokens ?? PulseBrandTokens.pulseDark,
    strings ?? PulseStrings.en,
  );

  // === ColorSchemes ===
  // Every slot is a semantic role. Slots Material requires but the DTCG
  // contract has no dedicated role for (text on a saturated fill) reuse
  // `brandFg` — the DS's "foreground on a saturated color" token (#ffffff) —
  // except where that would fail WCAG AA against the fill it sits on; see
  // dark `onError` below.

  /// The light `ColorScheme` PULSE projects from the token contract.
  ///
  /// Exposed so a re-brand can start from it and override only the slots it
  /// cares about — see [light].
  static const ColorScheme lightColorScheme = ColorScheme(
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
    // Material tints elevated surfaces with this. Left unset it falls back to
    // `primary`, i.e. the same value — set explicitly so the tint is part of
    // the token contract instead of an inherited Material default that a
    // re-brand could move without anyone deciding to.
    surfaceTint: PulseSemantics.brand,
    // Brand accent for content sitting ON `inverseSurface` (a Material SnackBar
    // action label is the common case). Unset, Material falls back to
    // `onPrimary` — white — which happens to read here (17.85:1 on the dark
    // inverse surface) but is invisible in dark mode; see the dark scheme.
    // Light's inverse surface is the dark ink, so the accent steps up the brand
    // ladder to stay legible: brand-400 on #0F172A is 6.56:1. The DTCG contract
    // has no semantic role for this slot, so it references the primitive
    // directly rather than inventing a semantic name here.
    inversePrimary: PulsePrimitives.brand400,
  );

  /// The dark `ColorScheme` PULSE projects from the token contract.
  ///
  /// Exposed so a re-brand can start from it and override only the slots it
  /// cares about — see [dark].
  static const ColorScheme darkColorScheme = ColorScheme(
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
    // The one slot that does NOT reuse `brandFg`. Dark `danger` is red-500
    // (#EF4444), a *lighter* red than the light-mode red-600, so white on it
    // is only 3.76:1 — below WCAG AA 4.5:1 for the w600 14/16/18px label
    // `PulseButton(variant: danger)` paints (none of those sizes reaches the
    // 18.66px "large text" threshold that would allow 3:1). Inking it with the
    // dark background instead gives 5.36:1, which is also Material 3's own
    // dark convention (dark on-color over a light error tone).
    // Locked by `test/a11y_contrast_test.dart`.
    onError: PulseSemanticsDark.bg,
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
    // Same reasoning as the light scheme's `surfaceTint`.
    surfaceTint: PulseSemanticsDark.brand,
    // The slot Material's fallback gets actively wrong here. In dark mode
    // `inverseSurface` is the *light* ink (#F8FAFC), so the inherited
    // `onPrimary` white would paint a SnackBar action at **1.05:1** — not dim,
    // invisible. The regular brand-600 is 5.45:1 against it. Same class of bug
    // as dark `onError` above: a slot whose light-mode value cannot simply be
    // reused after the surfaces flip.
    inversePrimary: PulsePrimitives.brand600,
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

  /// Corner shape for every themed Material button.
  ///
  /// Matches `PulseButton`, which paints `PulseRadius.control` directly.
  /// Before `0.6.0` these were `StadiumBorder`, so the DS rendered two button
  /// shapes: pills for plain Material buttons and 8px rounded rectangles for
  /// `Pulse*` ones — including inside `PulseEmptyState` / `PulseErrorState`,
  /// whose CTAs are plain Material buttons.
  static final RoundedRectangleBorder _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(PulseRadius.control),
  );

  /// Shared [ThemeData] assembly — every component theme derives from
  /// [colorScheme], so light and dark stay structurally identical. The
  /// [brandTokens] non-Material extension (gradients / glow / shadows) is
  /// attached so `Pulse*` widgets can read it via `Theme.of(context)`.
  static ThemeData _base(
    ColorScheme colorScheme,
    PulseBrandTokens brandTokens,
    PulseStrings strings,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _textTheme,
      extensions: <ThemeExtension<dynamic>>[brandTokens, strings],
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
          borderRadius: BorderRadius.circular(PulseRadius.surface),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: _buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: _buttonShape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: _buttonShape,
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
      // Dialogs were the one common surface PULSE did not theme at all, so they
      // fell back to Material's own radius and surface. Only structure is set
      // here — elevation and the text roles stay at Material 3 defaults, which
      // already resolve to this theme's `TextTheme`.
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseRadius.surface),
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
          borderRadius: BorderRadius.circular(PulseRadius.control),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulseRadius.control),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulseRadius.control),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulseRadius.control),
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
          borderRadius: BorderRadius.circular(PulseRadius.pill),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }
}
