import 'package:flutter/material.dart';

import '../tokens/pulse_tokens.dart';

/// Material 3 brand-aware modal bottom sheet.
///
/// Mirrors the React DS `Sheet` (`<SheetContent side="bottom">` — mobile
/// action sheet) as a thin wrapper over Material 3 [showModalBottomSheet].
/// Open it with the static [show] helper; the optional [PulseBottomSheet]
/// widget provides a minimal title + body content scaffold:
/// ```dart
/// final saved = await PulseBottomSheet.show<bool>(
///   context,
///   builder: (context) => PulseBottomSheet(
///     title: 'フィルター',
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: [
///         const FilterForm(),
///         PulseButton(
///           fullWidth: true,
///           onPressed: () => Navigator.pop(context, true),
///           child: const Text('適用'),
///         ),
///       ],
///     ),
///   ),
/// );
/// ```
///
/// Colors derive from `Theme.of(context).colorScheme` (sheet surface =
/// `surface`, drag handle = `outlineVariant`, title = `onSurface`) so the
/// sheet follows any brand the consumer configures via
/// `copyWith(colorScheme: ...)` automatically. The barrier is black at 50%
/// alpha, matching the React Sheet overlay (`bg-black/50`); the top corners
/// use [PulsePrimitives.radiusXl] (16px — the DS radius feel, instead of
/// the Material 3 default 28px).
final class PulseBottomSheet extends StatelessWidget {
  const PulseBottomSheet({required this.child, super.key, this.title});

  /// Body content rendered inside the sheet. Required.
  final Widget child;

  /// Optional title shown above [child] (18px / w600, mirrors the React DS
  /// `SheetTitle`).
  final String? title;

  /// Opens a brand-styled modal bottom sheet and resolves with the value
  /// passed to `Navigator.pop(context, value)` (or `null` when dismissed
  /// via barrier tap / drag-down).
  ///
  /// Thin wrapper over [showModalBottomSheet]: [isScrollControlled],
  /// [isDismissible], [enableDrag] and [useSafeArea] pass straight through
  /// (same contract and defaults). [builder] typically returns a
  /// [PulseBottomSheet], but any widget is accepted.
  ///
  /// When [showDragHandle] is `true` (default), a 32×4 rounded drag handle
  /// tinted with `colorScheme.outlineVariant` is rendered above the content.
  /// (Material's built-in handle is bypassed because [showModalBottomSheet]
  /// exposes no per-call color parameter.)
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool showDragHandle = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useSafeArea = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      backgroundColor: colors.surface,
      // React Sheet overlay parity: fixed inset-0 bg-black/50.
      barrierColor: Colors.black.withValues(alpha: 0.5),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PulsePrimitives.radiusXl),
        ),
      ),
      showDragHandle: false,
      builder: (sheetContext) {
        final content = builder(sheetContext);
        if (!showDragHandle) {
          return content;
        }
        // Manual drag handle (M3 spec size 32×4) so the color can follow
        // colorScheme.outlineVariant. Drag-to-dismiss itself is owned by
        // the route via [enableDrag], independent of the handle.
        final handleColor = Theme.of(sheetContext).colorScheme.outlineVariant;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: PulseSpacing.md,
                bottom: PulseSpacing.sm,
              ),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(
                    PulsePrimitives.radiusFull,
                  ),
                ),
              ),
            ),
            Flexible(child: content),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PulseSpacing.lg,
          PulseSpacing.sm,
          PulseSpacing.lg,
          PulseSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Semantics(
                header: true,
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: PulseSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
