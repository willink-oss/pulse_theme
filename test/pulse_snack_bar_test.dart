// Tests for PulseSnackBar (1.3.0).
//
// Cover variant icon/accent contracts (info / success / error), description
// rendering, action callback, ColorScheme override flow-through, and the
// floating + rounded-border surface shape.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  /// Pumps a host app with an 'open' button that triggers
  /// [PulseSnackBar.show] with the given params, taps it, and settles.
  Future<void> showSnackBar(
    WidgetTester tester, {
    required String message,
    String? description,
    PulseSnackBarVariant variant = PulseSnackBarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? PulseTheme.light(),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => FilledButton(
                onPressed: () => PulseSnackBar.show(
                  context,
                  message: message,
                  description: description,
                  variant: variant,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('PulseSnackBar — info variant (default)', () {
    testWidgets('uses surface background + primary-tinted info icon',
        (tester) async {
      final theme = PulseTheme.light();
      await showSnackBar(tester, message: '通知', theme: theme);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(theme.colorScheme.surface));

      final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
      expect(icon.color, equals(theme.colorScheme.primary));
    });
  });

  group('PulseSnackBar — success variant', () {
    testWidgets('check icon uses PulseSemantics.success accent',
        (tester) async {
      await showSnackBar(
        tester,
        message: '保存しました',
        variant: PulseSnackBarVariant.success,
      );

      final icon =
          tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
      expect(icon.color, equals(PulseSemantics.success));
      expect(find.text('保存しました'), findsOneWidget);
    });
  });

  group('PulseSnackBar — error variant', () {
    testWidgets('error icon uses colorScheme.error', (tester) async {
      final theme = PulseTheme.light();
      await showSnackBar(
        tester,
        message: '保存に失敗しました',
        variant: PulseSnackBarVariant.error,
        theme: theme,
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, equals(theme.colorScheme.error));
    });
  });

  group('PulseSnackBar — description', () {
    testWidgets('renders below message in onSurfaceVariant', (tester) async {
      final theme = PulseTheme.light();
      await showSnackBar(
        tester,
        message: '保存に失敗しました',
        description: '時間をおいて再試行してください',
        variant: PulseSnackBarVariant.error,
        theme: theme,
      );

      final description =
          tester.widget<Text>(find.text('時間をおいて再試行してください'));
      expect(
        description.style!.color,
        equals(theme.colorScheme.onSurfaceVariant),
      );

      // Description sits below the message.
      final messageRect = tester.getRect(find.text('保存に失敗しました'));
      final descriptionRect =
          tester.getRect(find.text('時間をおいて再試行してください'));
      expect(descriptionRect.top, greaterThan(messageRect.bottom - 1));
    });
  });

  group('PulseSnackBar — action', () {
    testWidgets('action label tap fires callback', (tester) async {
      var retried = false;
      await showSnackBar(
        tester,
        message: '保存に失敗しました',
        variant: PulseSnackBarVariant.error,
        actionLabel: '再試行',
        onAction: () => retried = true,
      );

      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });
  });

  group('PulseSnackBar — ColorScheme override', () {
    testWidgets('respects copyWith(colorScheme: ...) override', (tester) async {
      // Same migration contract as PulseButton: consumers override
      // ColorScheme to change the brand color and the snack bar follows.
      final overridden = PulseTheme.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      );

      await showSnackBar(tester, message: 'Done', theme: overridden);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        snackBar.backgroundColor,
        equals(overridden.colorScheme.surface),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
      expect(icon.color, equals(overridden.colorScheme.primary));
    });
  });

  group('PulseSnackBar — dark theme (dark)', () {
    testWidgets(
        'surface flips to neutral-950 with neutral-800 border + light text',
        (tester) async {
      await showSnackBar(
        tester,
        message: '保存しました',
        description: '同期が完了しました',
        theme: PulseTheme.dark(),
      );

      // ADR-0013 surface flips: bg → neutral-950, border → neutral-800.
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(PulsePrimitives.neutral950));
      final shape = snackBar.shape! as RoundedRectangleBorder;
      expect(shape.side.color, equals(PulsePrimitives.neutral800));

      // fg → neutral-50, muted (onSurfaceVariant) → neutral-400.
      final message = tester.widget<Text>(find.text('保存しました'));
      expect(message.style!.color, equals(PulsePrimitives.neutral50));
      final description = tester.widget<Text>(find.text('同期が完了しました'));
      expect(description.style!.color, equals(PulsePrimitives.neutral400));
    });
  });

  group('PulseSnackBar — surface shape', () {
    testWidgets('floating behavior + 12px radius + outline border',
        (tester) async {
      final theme = PulseTheme.light();
      await showSnackBar(tester, message: '通知', theme: theme);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));

      final shape = snackBar.shape! as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        equals(BorderRadius.circular(PulsePrimitives.radiusLg)),
      );
      expect(shape.side.color, equals(theme.colorScheme.outline));
    });
  });
}
