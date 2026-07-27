// Tests for PulseSnackBar (1.3.0).
//
// Cover variant icon/accent contracts (info / success / warning / error),
// description rendering, action callback, ColorScheme override flow-through,
// and the floating + rounded-border surface shape.

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
              builder:
                  (context) => FilledButton(
                    onPressed:
                        () => PulseSnackBar.show(
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
    testWidgets('uses surface background + primary-tinted info icon', (
      tester,
    ) async {
      final theme = PulseTheme.light();
      await showSnackBar(tester, message: '通知', theme: theme);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(theme.colorScheme.surface));

      final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
      expect(icon.color, equals(theme.colorScheme.primary));
    });
  });

  group('PulseSnackBar — success variant', () {
    testWidgets('check icon uses PulseSemantics.success accent', (
      tester,
    ) async {
      await showSnackBar(
        tester,
        message: '保存しました',
        variant: PulseSnackBarVariant.success,
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
      expect(icon.color, equals(PulseSemantics.success));
      expect(find.text('保存しました'), findsOneWidget);
    });
  });

  group('PulseSnackBar — warning variant', () {
    testWidgets('warning icon uses PulseSemantics.warning (amber-600) accent', (
      tester,
    ) async {
      await showSnackBar(
        tester,
        message: '一部だけ同期しました',
        variant: PulseSnackBarVariant.warning,
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.warning_amber_rounded),
      );
      // Fixed semantic token — same flavour as success (not colorScheme).
      expect(icon.color, equals(PulseSemantics.warning));
      expect(icon.color, equals(PulsePrimitives.amber600));
      expect(icon.color, equals(const Color(0xFFD97706)));
      expect(find.text('一部だけ同期しました'), findsOneWidget);
    });

    testWidgets('accent stays the fixed token under a ColorScheme override', (
      tester,
    ) async {
      // Unlike info/error (colorScheme-driven), warning is a fixed token, so
      // re-branding must not move it.
      final overridden = PulseTheme.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      );

      await showSnackBar(
        tester,
        message: 'Almost at the limit',
        variant: PulseSnackBarVariant.warning,
        theme: overridden,
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.warning_amber_rounded),
      );
      expect(icon.color, equals(PulseSemantics.warning));
    });

    testWidgets('renders description and fires the action callback', (
      tester,
    ) async {
      var reviewed = false;
      final theme = PulseTheme.light();
      await showSnackBar(
        tester,
        message: '一部だけ同期しました',
        description: '未同期の項目を確認してください',
        variant: PulseSnackBarVariant.warning,
        actionLabel: '確認',
        onAction: () => reviewed = true,
        theme: theme,
      );

      final description = tester.widget<Text>(find.text('未同期の項目を確認してください'));
      expect(
        description.style!.color,
        equals(theme.colorScheme.onSurfaceVariant),
      );

      // Description sits below the message, as with the other variants.
      final messageRect = tester.getRect(find.text('一部だけ同期しました'));
      final descriptionRect = tester.getRect(find.text('未同期の項目を確認してください'));
      expect(descriptionRect.top, greaterThan(messageRect.bottom - 1));

      await tester.tap(find.text('確認'));
      await tester.pumpAndSettle();
      expect(reviewed, isTrue);
    });

    testWidgets('keeps the neutral surface shape of the other variants', (
      tester,
    ) async {
      final theme = PulseTheme.light();
      await showSnackBar(
        tester,
        message: '一部だけ同期しました',
        variant: PulseSnackBarVariant.warning,
        theme: theme,
      );

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(theme.colorScheme.surface));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
      final shape = snackBar.shape! as RoundedRectangleBorder;
      expect(shape.side.color, equals(theme.colorScheme.outline));
    });
  });

  group('PulseSnackBar — variant distinction', () {
    // One icon per variant: warning must never leak into (or be shadowed by)
    // info / success / error.
    const iconOf = <PulseSnackBarVariant, IconData>{
      PulseSnackBarVariant.info: Icons.info_outline,
      PulseSnackBarVariant.success: Icons.check_circle_outline,
      PulseSnackBarVariant.warning: Icons.warning_amber_rounded,
      PulseSnackBarVariant.error: Icons.error_outline,
    };

    for (final variant in PulseSnackBarVariant.values) {
      testWidgets('${variant.name} renders only its own icon', (tester) async {
        await showSnackBar(tester, message: 'msg', variant: variant);

        for (final entry in iconOf.entries) {
          expect(
            find.byIcon(entry.value),
            entry.key == variant ? findsOneWidget : findsNothing,
            reason:
                '${variant.name} should render ${iconOf[variant]} only, '
                'but ${entry.value} did not match.',
          );
        }
      });
    }
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

      final description = tester.widget<Text>(find.text('時間をおいて再試行してください'));
      expect(
        description.style!.color,
        equals(theme.colorScheme.onSurfaceVariant),
      );

      // Description sits below the message.
      final messageRect = tester.getRect(find.text('保存に失敗しました'));
      final descriptionRect = tester.getRect(find.text('時間をおいて再試行してください'));
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
      expect(snackBar.backgroundColor, equals(overridden.colorScheme.surface));

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
      },
    );
  });

  group('PulseSnackBar — surface shape', () {
    testWidgets('floating behavior + 12px radius + outline border', (
      tester,
    ) async {
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

  group('PulseSnackBarVariant — enum contract', () {
    test('declares info, success, warning, error in severity order', () {
      // Order is part of the public API (index is used by switch tables and
      // serialized payloads): warning sits between success and error.
      expect(PulseSnackBarVariant.values, <PulseSnackBarVariant>[
        PulseSnackBarVariant.info,
        PulseSnackBarVariant.success,
        PulseSnackBarVariant.warning,
        PulseSnackBarVariant.error,
      ]);
      expect(PulseSnackBarVariant.warning.index, 2);
    });
  });
}
