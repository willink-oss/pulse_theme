/// PULSE — i-Willink's mobile-first canonical design system for Flutter.
///
/// PULSE is the `ADR-018` mobile-first source of truth for i-Willink app UI.
/// Design tokens are **not** hand-mirrored here: [PulsePrimitives],
/// [PulseSemantics] / [PulseSemanticsDark], [PulseSpacing] and [PulseFontSize]
/// are code-generated from the published `@willink-labs/tokens` DTCG JSON
/// contract — the same source the web (`@willink-labs/*` React) consumes — so
/// web and mobile stay at parity from a single token SSOT.
///
/// [PulseTheme.light] / [PulseTheme.dark] return Material 3 `ThemeData` whose
/// `ColorScheme`, `TextTheme` and component themes are a faithful projection of
/// that token contract. The first 9 `Pulse*` components ship on the violet
/// baseline (see the exports below); each reads colors from
/// `Theme.of(context).colorScheme`, so a `copyWith` brand override flows
/// through. See the README and `doc/adr/0001-pulse-mobile-first-architecture.md`.
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:pulse_theme/pulse_theme.dart';
///
/// MaterialApp(
///   theme: PulseTheme.light(),
///   darkTheme: PulseTheme.dark(),
///   themeMode: ThemeMode.system,
///   // Re-brand via standard Material 3 copyWith — every Pulse* widget reads
///   // colors from Theme.of(context).colorScheme, so overrides flow through:
///   // theme: PulseTheme.light().copyWith(
///   //   colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
///   // ),
///   home: ...,
/// );
/// ```
library;

export 'src/components/pulse_bottom_sheet.dart' show PulseBottomSheet;
export 'src/components/pulse_button.dart'
    show PulseButton, PulseButtonSize, PulseButtonTone, PulseButtonVariant;
export 'src/components/pulse_empty_state.dart' show PulseEmptyState;
export 'src/components/pulse_error_state.dart' show PulseErrorState;
export 'src/components/pulse_loading_state.dart' show PulseLoadingState;
export 'src/components/pulse_progress_indicator.dart'
    show PulseProgressIndicator;
export 'src/components/pulse_section_card.dart' show PulseSectionCard;
export 'src/components/pulse_snack_bar.dart'
    show PulseSnackBar, PulseSnackBarVariant;
export 'src/components/pulse_tab_bar.dart' show PulseTabBar;
export 'src/pulse_theme.dart' show PulseTheme;
export 'src/theme_extensions/pulse_brand_tokens.dart' show PulseBrandTokens;
export 'src/tokens/pulse_tokens.dart'
    show
        PulsePrimitives,
        PulseSemantics,
        PulseSemanticsDark,
        PulseSpacing,
        PulseFontSize,
        PulseShadows;
