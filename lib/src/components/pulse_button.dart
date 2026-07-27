import 'package:flutter/material.dart';

/// Visual style of [PulseButton].
///
/// Mirrors the React DS `Button` variant tokens.
enum PulseButtonVariant {
  /// Solid primary background with brand glow shadow.
  filled,

  /// Transparent background with primary-colored border + text.
  outline,

  /// Transparent background with primary-colored text only.
  /// Hover/pressed shows a `primaryContainer` overlay.
  ghost,

  /// Solid `colorScheme.error` background — destructive actions (delete,
  /// revoke, cancel-subscription). Same shape and weight as [filled] so the
  /// two read as peers; only the accent differs.
  ///
  /// Reads `colorScheme.error` rather than the fixed `PulseSemantics.danger`
  /// token so that a consumer's `copyWith(colorScheme: ...)` re-tints it, the
  /// same way [filled] tracks `colorScheme.primary`.
  danger,
}

/// Size axis of [PulseButton]. Drives padding + font size.
enum PulseButtonSize {
  /// 12×6 padding, 14px text.
  small,

  /// 16×10 padding, 16px text. Default.
  medium,

  /// 24×14 padding, 18px text.
  large,
}

/// Material 3 brand-aware button.
///
/// Mirrors the React DS `Button` component shape:
/// ```dart
/// PulseButton(
///   onPressed: () => save(),
///   variant: PulseButtonVariant.filled,
///   size: PulseButtonSize.medium,
///   leadingIcon: const Icon(Icons.check),
///   child: const Text('保存'),
/// )
/// ```
///
/// Colors derive from `Theme.of(context).colorScheme`, so overriding the
/// scheme (`PulseTheme.light().copyWith(colorScheme: ...)`) re-brands the
/// button automatically.
///
/// Passing `onPressed: null` auto-disables the button (opacity 0.5 + no ripple).
///
/// [isLoading] is a separate state from disabled: the button stays at full
/// opacity (it is still the active affordance) but swaps its label for a
/// spinner and stops accepting taps.
class PulseButton extends StatelessWidget {
  const PulseButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.variant = PulseButtonVariant.filled,
    this.size = PulseButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = false,
    this.isLoading = false,
    this.loadingSemanticsLabel,
  });

  /// Tap handler. When `null`, the button is rendered in a disabled state
  /// (opacity 0.5 + no ripple).
  final VoidCallback? onPressed;

  /// Label content. Typically a [Text], but any widget is accepted.
  final Widget child;

  /// Visual variant. Defaults to [PulseButtonVariant.filled].
  final PulseButtonVariant variant;

  /// Size variant. Defaults to [PulseButtonSize.medium].
  final PulseButtonSize size;

  /// Optional icon shown to the left of [child] (8px gap).
  final Widget? leadingIcon;

  /// Optional icon shown to the right of [child] (8px gap).
  final Widget? trailingIcon;

  /// Whether the button should fill the available horizontal width.
  final bool fullWidth;

  /// Shows a spinner in place of the label and stops accepting taps, without
  /// dimming the button — use it while the action this button triggers is in
  /// flight.
  ///
  /// The button keeps the width it had with its label, so submitting a form
  /// does not make the layout jump.
  final bool isLoading;

  /// Screen-reader announcement for the [isLoading] spinner (e.g. `'保存中'`).
  ///
  /// While loading the button reports as disabled to assistive tech — it
  /// cannot be activated — so without this the *state* change is silent.
  /// The button's **name** is never lost: the invisible label stays in the
  /// semantics tree, so a busy button without this argument still announces
  /// its own text (e.g. `'保存する'`), and with it announces both. Same
  /// fallback spirit as `PulseLoadingState.semanticsLabel`, which falls back
  /// to its `message`.
  final String? loadingSemanticsLabel;

  EdgeInsets get _padding {
    switch (size) {
      case PulseButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case PulseButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case PulseButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  double get _fontSize {
    switch (size) {
      case PulseButtonSize.small:
        return 14;
      case PulseButtonSize.medium:
        return 16;
      case PulseButtonSize.large:
        return 18;
    }
  }

  /// Whether this variant paints a filled accent background. The other
  /// variants tint text / border only.
  bool get _isSolid =>
      variant == PulseButtonVariant.filled ||
      variant == PulseButtonVariant.danger;

  /// The accent this variant is built from — `error` for [danger], otherwise
  /// `primary`. Both come from the `ColorScheme`, so a consumer's
  /// `copyWith(colorScheme: ...)` re-brands every variant.
  Color _accent(ColorScheme colors) =>
      variant == PulseButtonVariant.danger ? colors.error : colors.primary;

  /// Foreground drawn on top of [_accent].
  Color _foreground(ColorScheme colors) =>
      _isSolid
          ? (variant == PulseButtonVariant.danger
              ? colors.onError
              : colors.onPrimary)
          : _accent(colors);

  /// Swaps the label for a spinner while keeping the button exactly as wide as
  /// it was — the invisible label is still laid out, so submitting a form does
  /// not resize the button under the user's finger.
  ///
  /// The label also keeps its **semantics**. A busy button is still an
  /// interactive element and must have an accessible name: hiding the label
  /// would leave a screen reader announcing an unnamed disabled button, so the
  /// user could not tell *which* control went away. [loadingSemanticsLabel] is
  /// announced in addition to that name, not instead of it.
  Widget _busy(Widget label, Color foreground) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // `alwaysIncludeSemantics` is load-bearing: RenderOpacity drops its
        // child's semantics at alpha 0, which would make the button nameless.
        Opacity(opacity: 0, alwaysIncludeSemantics: true, child: label),
        SizedBox(
          width: _fontSize,
          height: _fontSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: foreground,
            semanticsLabel: loadingSemanticsLabel,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _accent(colors);
    final foreground = _foreground(colors);

    // Disabled and loading are distinct states. Both drop the tap handler, but
    // only disabled dims: a loading button is still the live affordance.
    final dimmed = onPressed == null && !isLoading;
    final effectiveOnPressed = isLoading ? null : onPressed;

    final textStyle = TextStyle(
      fontSize: _fontSize,
      fontWeight: FontWeight.w600,
      color: foreground,
    );

    final label = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 8)],
        DefaultTextStyle.merge(style: textStyle, child: child),
        if (trailingIcon != null) ...[const SizedBox(width: 8), trailingIcon!],
      ],
    );

    final content = isLoading ? _busy(label, foreground) : label;

    Widget button;
    switch (variant) {
      case PulseButtonVariant.filled:
      case PulseButtonVariant.danger:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: foreground,
            disabledBackgroundColor: accent,
            disabledForegroundColor: foreground,
            padding: _padding,
            // Keep the visual compact (minimumSize.zero) but let Material's
            // default `padded` tap-target expand the gesture + semantics area to
            // the 48dp a11y minimum (do NOT use shrinkWrap — it disables that).
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: content,
        );
        break;
      case PulseButtonVariant.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            disabledForegroundColor: accent,
            side: BorderSide(color: accent, width: 1.5),
            padding: _padding,
            // Keep the visual compact (minimumSize.zero) but let Material's
            // default `padded` tap-target expand the gesture + semantics area to
            // the 48dp a11y minimum (do NOT use shrinkWrap — it disables that).
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: content,
        );
        break;
      case PulseButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: accent,
            disabledForegroundColor: accent,
            backgroundColor: Colors.transparent,
            padding: _padding,
            // Keep the visual compact (minimumSize.zero) but let Material's
            // default `padded` tap-target expand the gesture + semantics area to
            // the 48dp a11y minimum (do NOT use shrinkWrap — it disables that).
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered)) {
                return colors.primaryContainer;
              }
              return null;
            }),
          ),
          child: content,
        );
        break;
    }

    // IconTheme so leading/trailing Icon widgets inherit the right color/size
    // even when callers pass a bare `Icon(...)` without explicit color.
    Widget result = IconTheme.merge(
      data: IconThemeData(color: foreground, size: _fontSize + 2),
      child: button,
    );

    if (_isSolid && !dimmed) {
      // Accent glow: the variant's own accent at 30% alpha. Uses the
      // ColorScheme (not PulseBrandTokens) so the glow tracks a consumer's
      // override (PulseTheme.light().copyWith(colorScheme: ...)).
      result = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: result,
      );
    }

    if (dimmed) {
      result = Opacity(opacity: 0.5, child: result);
    }

    if (fullWidth) {
      result = SizedBox(width: double.infinity, child: result);
    }

    return result;
  }
}
