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
class PulseLoadingState extends StatelessWidget {
  const PulseLoadingState({super.key, this.message, this.size = 40});

  /// Compact variant (24px) for use inside sections that already have a
  /// surrounding header / card.
  const PulseLoadingState.compact({super.key, this.message}) : size = 24;

  /// Inline variant (16px) with no padding — fits inside buttons, list rows
  /// or dense layouts. Always has `message: null`.
  const PulseLoadingState.inline({super.key})
    : message = null,
      size = 16;

  /// Optional caption shown below the spinner. Ignored in [inline].
  final String? message;

  /// Spinner edge length in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (size <= 16) {
      // Inline: no padding, no message — just the spinner.
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
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
