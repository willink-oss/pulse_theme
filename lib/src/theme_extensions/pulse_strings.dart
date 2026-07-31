// ThemeExtension carrying the user-visible copy that PULSE components ship
// defaults for. Set it once on the theme and every component picks it up,
// the same way PulseBrandTokens carries the non-Material brand values.
//
// This is deliberately NOT a full localization system. It covers only the
// strings PULSE itself has to render when the caller does not supply one —
// today that is PulseErrorState. An app with real l10n should keep passing its
// own translated strings per call site; this exists so that a component
// rendering *without* an explicit label does not hard-code one language.

import 'package:flutter/material.dart';

/// Default copy for `Pulse*` components that render text of their own.
///
/// PULSE ships [en] (the default) and [ja]. Select one when building the
/// theme:
///
/// ```dart
/// MaterialApp(
///   theme: PulseTheme.light(strings: PulseStrings.ja),
/// );
/// ```
///
/// Any component argument you pass explicitly always wins — these are the
/// fallbacks, not an override. For a language PULSE does not ship, construct
/// your own:
///
/// ```dart
/// const de = PulseStrings(
///   errorTitle: 'Ein Fehler ist aufgetreten',
///   errorRetryLabel: 'Erneut versuchen',
///   errorCopyLabel: 'Fehler kopieren',
///   errorCopiedMessage: 'Fehlerdetails kopiert',
/// );
/// ```
@immutable
final class PulseStrings extends ThemeExtension<PulseStrings> {
  const PulseStrings({
    required this.errorTitle,
    required this.errorRetryLabel,
    required this.errorCopyLabel,
    required this.errorCopiedMessage,
  });

  /// Headline of `PulseErrorState` when no `title` is passed.
  final String errorTitle;

  /// Label of `PulseErrorState`'s retry button.
  final String errorRetryLabel;

  /// Label of `PulseErrorState`'s copy-to-clipboard button.
  final String errorCopyLabel;

  /// Snack bar shown after `PulseErrorState` copies the error to the
  /// clipboard.
  final String errorCopiedMessage;

  /// English copy — the default attached by `PulseTheme.light()` / `dark()`.
  static const PulseStrings en = PulseStrings(
    errorTitle: 'Something went wrong',
    errorRetryLabel: 'Retry',
    errorCopyLabel: 'Copy error',
    errorCopiedMessage: 'Error details copied',
  );

  /// Japanese copy — these were the hard-coded defaults through `0.5.1`.
  static const PulseStrings ja = PulseStrings(
    errorTitle: 'エラーが発生しました',
    errorRetryLabel: '再試行',
    errorCopyLabel: 'エラーをコピー',
    errorCopiedMessage: 'エラー内容をコピーしました',
  );

  /// The strings in scope at [context], falling back to [en] when the theme
  /// carries no [PulseStrings] — e.g. under a plain `ThemeData`.
  static PulseStrings of(BuildContext context) =>
      Theme.of(context).extension<PulseStrings>() ?? en;

  @override
  PulseStrings copyWith({
    String? errorTitle,
    String? errorRetryLabel,
    String? errorCopyLabel,
    String? errorCopiedMessage,
  }) {
    return PulseStrings(
      errorTitle: errorTitle ?? this.errorTitle,
      errorRetryLabel: errorRetryLabel ?? this.errorRetryLabel,
      errorCopyLabel: errorCopyLabel ?? this.errorCopyLabel,
      errorCopiedMessage: errorCopiedMessage ?? this.errorCopiedMessage,
    );
  }

  /// Text cannot be interpolated, so it snaps at the animation's midpoint —
  /// the same convention `PulseBrandTokens` uses for its shadow lists.
  @override
  PulseStrings lerp(covariant ThemeExtension<PulseStrings>? other, double t) {
    if (other is! PulseStrings) return this;
    return t < 0.5 ? this : other;
  }
}
