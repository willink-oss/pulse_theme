import 'package:flutter/material.dart';

import '../theme_extensions/pulse_brand_tokens.dart';
import '../tokens/pulse_tokens.dart';

/// Section-shaped surface that hosts grouped content under an optional title.
///
/// Mirrors the React DS `Card` compound (`<Card><CardHeader>...</Card>`)
/// but in a single Flutter widget that takes `title` + optional `trailing`.
/// Background is `Theme.of(context).colorScheme.surface`, corner radius is
/// [PulsePrimitives.radiusLg], and the shadow comes from the theme's
/// [PulseBrandTokens.shadowSoft] so it darkens in dark mode.
///
/// ```dart
/// PulseSectionCard(
///   title: '今週のトレーニング',
///   trailing: const Icon(Icons.chevron_right),
///   onTrailingTap: () => context.push('/weekly'),
///   child: const Column(children: [...]),
/// )
/// ```
final class PulseSectionCard extends StatelessWidget {
  const PulseSectionCard({
    required this.child,
    super.key,
    this.title,
    this.trailing,
    this.onTrailingTap,
    this.padding,
    this.margin,
  });

  /// Content rendered inside the card body. Required.
  final Widget child;

  /// Optional section title shown at the top of the card.
  final String? title;

  /// Optional widget shown right of the title (e.g. chevron, "more" link).
  /// Ignored when [title] is null.
  final Widget? trailing;

  /// Tap handler for [trailing]. When set, the trailing area becomes a real
  /// button: it reports as one to assistive tech and is padded out to the 48dp
  /// minimum tap target. When null, [trailing] is rendered as inert decoration.
  final VoidCallback? onTrailingTap;

  /// Inner content padding. Defaults to [PulseSpacing.lg] on all sides
  /// (top adjusted when [title] is present, since the title already provides
  /// vertical breathing room).
  final EdgeInsetsGeometry? padding;

  /// Outer margin around the card. Defaults to [PulseSpacing.lg] on all sides.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: margin ?? const EdgeInsets.all(PulseSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        // radiusLg, matching `cardTheme` and this widget's own documentation.
        // The code said radiusMd until 0.6.0, so the DS drew section cards at a
        // different radius than the Material Card it is the sibling of.
        borderRadius: BorderRadius.circular(PulsePrimitives.radiusLg),
        // The shadow used to be a hand-coded 5%-black, which never darkened in
        // dark mode — where the card and the scaffold are both `surface`, so
        // the shadow is the *only* thing separating them. PulseShadows.softDark
        // (carried per-mode by the brand tokens) is the token for exactly this.
        boxShadow:
            theme.extension<PulseBrandTokens>()?.shadowSoft ??
            PulseShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PulseSpacing.lg,
                PulseSpacing.lg,
                PulseSpacing.lg,
                PulseSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title!,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null)
                    if (onTrailingTap == null)
                      trailing!
                    else
                      Semantics(
                        button: true,
                        child: InkWell(
                          onTap: onTrailingTap,
                          borderRadius: BorderRadius.circular(
                            PulsePrimitives.radiusSm,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            child: Center(
                              widthFactor: 1,
                              heightFactor: 1,
                              child: trailing,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          Padding(
            padding:
                padding ??
                EdgeInsets.fromLTRB(
                  PulseSpacing.lg,
                  title != null ? 0 : PulseSpacing.lg,
                  PulseSpacing.lg,
                  PulseSpacing.lg,
                ),
            child: child,
          ),
        ],
      ),
    );
  }
}
