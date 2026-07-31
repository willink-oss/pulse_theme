import 'package:flutter/material.dart';

import '../tokens/pulse_tokens.dart';

/// Centered empty-state composition: icon + title + optional description + CTA.
///
/// Use whenever a screen has no data to show — instead of leaving an empty
/// page, present a clear next step.
///
/// ```dart
/// PulseEmptyState(
///   icon: const Icon(Icons.fitness_center),
///   title: 'まだトレーニング記録がありません',
///   description: '最初のワークアウトを記録してみましょう',
///   actionLabel: '記録を始める',
///   onAction: () => context.push('/workout/new'),
/// )
/// ```
///
/// Colors derive from `Theme.of(context).colorScheme` (icon = onSurfaceVariant,
/// title = onSurfaceVariant, description = outline) so the widget adapts to a
/// consumer's ColorScheme override automatically.
final class PulseEmptyState extends StatelessWidget {
  const PulseEmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.description,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be provided together — a label with no '
         'handler renders nothing at all.',
       );

  /// Symbol shown above the title, rendered at 80px in
  /// `colorScheme.onSurfaceVariant`.
  ///
  /// A `Widget` rather than an `IconData` — matching `PulseButton`'s icon
  /// slots — so an empty state can show an illustration or a brand mark, not
  /// only a Material glyph. A bare `Icon(...)` inherits the size and color.
  final Widget icon;

  /// Primary message explaining what's missing.
  final String title;

  /// Optional supporting copy below the title.
  final String? description;

  /// CTA label. If null, no button is rendered.
  ///
  /// Must be given together with [onAction]; passing one without the other is
  /// an assertion error rather than a silently missing button. Same pairing
  /// contract as `PulseSnackBar.show`.
  final String? actionLabel;

  /// Tap handler for the CTA. Required whenever [actionLabel] is set.
  final VoidCallback? onAction;

  /// Optional leading icon for the CTA. Defaults to `Icon(Icons.add)`.
  final Widget? actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Scroll-when-overflows / center-when-fits: at large accessibility text
    // scales (e.g. iOS AX5 ~3x) the content scrolls instead of clipping with a
    // RenderFlex overflow stripe on small phones (D4).
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconTheme.merge(
                        data: IconThemeData(
                          size: 80,
                          color: colors.onSurfaceVariant,
                        ),
                        child: icon,
                      ),
                      const SizedBox(height: PulseSpacing.xl),
                      Text(
                        title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: PulseSpacing.sm),
                        Text(
                          description!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: PulseSpacing.xxl),
                        FilledButton.icon(
                          onPressed: onAction,
                          icon: actionIcon ?? const Icon(Icons.add),
                          label: Text(actionLabel!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
