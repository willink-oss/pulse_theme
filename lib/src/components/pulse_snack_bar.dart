import 'package:flutter/material.dart';

import '../tokens/pulse_tokens.dart';

/// Semantic variant of [PulseSnackBar].
///
/// Mirrors the React DS `toast` semantics (`toast.success(...)` /
/// `toast.error(...)` / plain `toast(...)`).
enum PulseSnackBarVariant {
  /// Neutral notification. Info icon tinted `colorScheme.primary`. Default.
  info,

  /// Positive confirmation. Check icon tinted [PulseSemantics.success].
  success,

  /// Failure feedback. Error icon tinted `colorScheme.error`.
  error,
}

/// Material 3 brand-aware snack bar helper.
///
/// Mirrors the React DS `Toast` (a brand-styled wrapper over sonner) as a
/// thin wrapper over [ScaffoldMessenger.showSnackBar]:
/// ```dart
/// PulseSnackBar.show(
///   context,
///   message: '保存しました',
///   variant: PulseSnackBarVariant.success,
/// );
///
/// PulseSnackBar.show(
///   context,
///   message: '保存に失敗しました',
///   description: '時間をおいて再試行してください',
///   variant: PulseSnackBarVariant.error,
///   actionLabel: '再試行',
///   onAction: () => save(),
/// );
/// ```
///
/// Like the React toast, the surface stays neutral (`colorScheme.surface`
/// background, `outline` border, 12px radius, floating) and the semantics are
/// carried by the leading icon color — `primary` / [PulseSemantics.success]
/// / `error` — so the snack bar follows any brand the consumer configures via
/// `copyWith(colorScheme: ...)` automatically.
///
/// Reuses Material 3 SnackBar timing and queueing — no custom queue logic.
class PulseSnackBar {
  const PulseSnackBar._();

  /// Builds the brand-styled [SnackBar] and shows it via the nearest
  /// [ScaffoldMessenger]. Returns the controller from
  /// [ScaffoldMessengerState.showSnackBar] (await `closed` to react to
  /// dismissal).
  ///
  /// [actionLabel] and [onAction] must be provided together; when set, a
  /// [SnackBarAction] in `colorScheme.primary` is appended.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    String? description,
    PulseSnackBarVariant variant = PulseSnackBarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    assert(
      (actionLabel == null) == (onAction == null),
      'actionLabel and onAction must be provided together.',
    );

    final colors = Theme.of(context).colorScheme;

    final (IconData icon, Color accent) = switch (variant) {
      PulseSnackBarVariant.info => (Icons.info_outline, colors.primary),
      PulseSnackBarVariant.success => (
          Icons.check_circle_outline,
          PulseSemantics.success,
        ),
      PulseSnackBarVariant.error => (Icons.error_outline, colors.error),
    };

    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surface,
        elevation: 3,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulsePrimitives.radiusLg),
          side: BorderSide(color: colors.outline),
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: colors.primary,
                onPressed: onAction!,
              ),
        content: Row(
          children: [
            Icon(icon, size: 20, color: accent),
            // 8px icon ↔ label gap — same convention as PulseButton.
            const SizedBox(width: PulseSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: PulseSpacing.xs),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
