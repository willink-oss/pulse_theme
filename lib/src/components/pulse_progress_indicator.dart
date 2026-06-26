import 'package:flutter/material.dart';

/// Material 3 brand-aware linear progress indicator.
///
/// Mirrors the React DS `Progress` component (a Radix Progress wrapper):
/// ```dart
/// // Determinate — value in 0.0–1.0:
/// PulseProgressIndicator(value: 0.65)
///
/// // Indeterminate — omit value (or pass null):
/// const PulseProgressIndicator(semanticsLabel: 'アップロード中')
/// ```
///
/// **Value range**: Flutter-native `0.0–1.0` (`null` = indeterminate). The
/// React `Progress` uses the Radix `0–100` scale for the same prop — divide
/// by 100 when porting values across platforms.
///
/// Colors derive from `Theme.of(context).colorScheme` — fill = `primary`,
/// track = `surfaceContainerHighest` (brand-neutral, the Material 3
/// equivalent of the React track's `bg-neutral-200`) — so the bar follows
/// any brand the consumer configures via `copyWith(colorScheme: ...)`
/// automatically.
///
/// The bar is fully rounded by default (React DS `rounded-full`) and 8dp
/// tall (React DS `h-2`; Material 3's native default is 4dp — the DS
/// deliberately uses the chunkier React height for cross-platform parity).
/// Both are overridable via [borderRadius] / [minHeight].
///
/// Positioning vs. [PulseLoadingState]: use [PulseLoadingState] for
/// full-area loading *states* (centered spinner + optional caption replacing
/// the content); use [PulseProgressIndicator] for *inline* linear progress
/// inside otherwise-rendered UI — uploads, downloads, multi-step flows.
class PulseProgressIndicator extends StatelessWidget {
  const PulseProgressIndicator({
    super.key,
    this.value,
    this.minHeight = 8,
    this.borderRadius,
    this.semanticsLabel,
  }) : assert(
          value == null || (value >= 0.0 && value <= 1.0),
          'value must be null (indeterminate) or within 0.0–1.0; '
          'note the React Progress uses 0–100 — divide by 100 when porting.',
        );

  /// Progress fraction in `0.0–1.0`. When `null`, the indicator is
  /// indeterminate (continuous sweep animation) — the same nullable-value
  /// contract as both [LinearProgressIndicator] and the React `Progress`.
  final double? value;

  /// Bar thickness in logical pixels. Defaults to 8 (React DS `h-2`).
  final double minHeight;

  /// Corner radius. When `null` (default), the bar is fully rounded
  /// (`minHeight / 2`, the React DS `rounded-full` look).
  final BorderRadiusGeometry? borderRadius;

  /// Accessibility label announced by screen readers (the React example's
  /// `aria-label`). For determinate bars Flutter additionally reports the
  /// percentage automatically.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LinearProgressIndicator(
      value: value,
      minHeight: minHeight,
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHighest,
      borderRadius: borderRadius ?? BorderRadius.circular(minHeight / 2),
      semanticsLabel: semanticsLabel,
    );
  }
}
