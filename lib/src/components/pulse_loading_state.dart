import 'package:flutter/material.dart';

import '../tokens/pulse_tokens.dart';

/// Centered loading indicator with optional caption.
///
/// Three variants for different contexts:
/// - default: 40px spinner + optional message (full-screen loading)
/// - `PulseLoadingState.compact()`: 24px spinner (inline within sections)
/// - `PulseLoadingState.inline()`: 16px spinner with no padding (inside
///   buttons / list rows / dense layouts)
///
/// ```dart
/// asyncData.when(
///   data: (d) => MyContent(d),
///   loading: () => const PulseLoadingState(message: '読み込み中...'),
///   error: (err, _) => PulseErrorState(error: err),
/// )
/// ```
final class PulseLoadingState extends StatelessWidget {
  const PulseLoadingState({
    super.key,
    this.message,
    this.size = 40,
    this.semanticsLabel,
  }) : _inline = false;

  /// Compact variant (24px) for use inside sections that already have a
  /// surrounding header / card.
  const PulseLoadingState.compact({
    super.key,
    this.message,
    this.semanticsLabel,
  }) : size = 24,
       _inline = false;

  /// Inline variant (16px) with no padding — fits inside buttons, list rows
  /// or dense layouts. Always has `message: null`.
  const PulseLoadingState.inline({super.key, this.semanticsLabel})
    : message = null,
      size = 16,
      _inline = true;

  /// Optional caption shown below the spinner. Ignored in [inline].
  final String? message;

  /// Spinner edge length in logical pixels. Purely a size — it no longer
  /// selects the layout.
  final double size;

  /// Whether to render the bare, padding-less layout. Set only by [inline].
  ///
  /// The layout used to be chosen by `size <= 16`, so
  /// `PulseLoadingState(message: '...', size: 16)` dropped its caption with no
  /// error — and that threshold would have frozen into the 1.0 contract.
  final bool _inline;

  /// Screen-reader announcement for the spinner. Falls back to [message]; set
  /// this explicitly for the inline / message-less variants so assistive tech
  /// still announces that work is in progress.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_inline) {
      // Inline: no padding, no message — just the spinner.
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
          semanticsLabel: semanticsLabel ?? message,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size <= 24 ? 2.5 : 3,
              color: theme.colorScheme.primary,
              semanticsLabel: semanticsLabel ?? message,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: PulseSpacing.lg),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
