import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/pulse_tokens.dart';

/// Centered error display with optional copy-to-clipboard and retry.
///
/// Use as the error branch of `AsyncValue.when` / `FutureBuilder` etc.
/// Layout: icon (48px) + title (bodyLarge) + message (bodySmall) +
/// copy button (TextButton.icon) + retry (FilledButton).
///
/// ```dart
/// asyncData.when(
///   data: (d) => MyContent(d),
///   loading: () => const PulseLoadingState(),
///   error: (err, _) => PulseErrorState(
///     title: '読み込みに失敗しました',
///     error: err,
///     onRetry: () => ref.refresh(myProvider),
///   ),
/// )
/// ```
///
/// Colors come from `Theme.of(context).colorScheme` — icon = error.
class PulseErrorState extends StatelessWidget {
  const PulseErrorState({
    super.key,
    this.title = 'エラーが発生しました',
    this.message,
    this.error,
    this.onRetry,
    this.retryLabel = '再試行',
    this.showCopyButton = true,
    this.copySuccessMessage = 'エラー内容をコピーしました',
  });

  /// Headline. Defaults to a generic Japanese error string; pass a
  /// localized value for production use.
  final String title;

  /// Optional explanation. If null, falls back to `error.toString()`.
  /// Pass a user-friendly message when [error] would be too technical.
  final String? message;

  /// Underlying error for clipboard copy. Not displayed when [message] is set.
  final Object? error;

  /// Tap handler for the retry button. If null, the button is hidden.
  final VoidCallback? onRetry;

  /// Localized retry label.
  final String retryLabel;

  /// When true (default), shows a TextButton that copies `title + message`
  /// to the system clipboard.
  final bool showCopyButton;

  /// SnackBar copy-success message.
  final String copySuccessMessage;

  String get _errorText {
    final detail = message ?? error?.toString() ?? '';
    return detail.isEmpty ? title : '$title\n$detail';
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _errorText));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copySuccessMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasDetail = message != null || error != null;

    // Scroll-when-overflows / center-when-fits so the content degrades
    // gracefully (scrolls) instead of clipping at large text scales (D4).
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    constraints.hasBoundedHeight ? constraints.maxHeight : 0,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(PulseSpacing.xxl),
                  // liveRegion: announce the error (title + detail) to assistive
                  // tech when this state appears in place of content.
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colors.error,
                        ),
                        const SizedBox(height: PulseSpacing.lg),
                        Text(
                          title,
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (hasDetail) ...[
                          const SizedBox(height: PulseSpacing.sm),
                          Text(
                            message ?? error.toString(),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (showCopyButton) ...[
                          const SizedBox(height: PulseSpacing.md),
                          TextButton.icon(
                            onPressed: () => _copy(context),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('エラーをコピー'),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (onRetry != null) ...[
                          const SizedBox(height: PulseSpacing.xl),
                          FilledButton(
                            onPressed: onRetry,
                            child: Text(retryLabel),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
