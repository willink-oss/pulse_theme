// Component-harden coverage (D2 Semantics + D4 TextScaler robustness).
//
// D1 (PulseButton 48dp tap target) lives in pulse_button_test.dart.
// D3 (golden / visual regression) is a separate follow-up (cross-platform
// golden infra) — see CHANGELOG.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: PulseTheme.light(), home: Scaffold(body: child));

  bool hasSemantics(WidgetTester t, Finder scope, bool Function(Semantics) p) =>
      t
          .widgetList<Semantics>(
            find.descendant(of: scope, matching: find.byType(Semantics)),
          )
          .any(p);

  group('D2 — Semantics', () {
    testWidgets('PulseLoadingState exposes a screen-reader label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const PulseLoadingState.inline(semanticsLabel: '読み込み中')),
      );
      expect(find.bySemanticsLabel('読み込み中'), findsOneWidget);
    });

    testWidgets('PulseLoadingState falls back to message for its label', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PulseLoadingState(message: '同期中')));
      expect(find.bySemanticsLabel('同期中'), findsWidgets);
    });

    testWidgets('PulseErrorState is a live region', (tester) async {
      await tester.pumpWidget(wrap(const PulseErrorState(title: '失敗')));
      expect(
        hasSemantics(
          tester,
          find.byType(PulseErrorState),
          (s) => s.properties.liveRegion ?? false,
        ),
        isTrue,
      );
    });

    testWidgets('PulseSectionCard title is a header', (tester) async {
      await tester.pumpWidget(
        wrap(const PulseSectionCard(title: '週次', child: Text('body'))),
      );
      expect(
        hasSemantics(
          tester,
          find.byType(PulseSectionCard),
          (s) => s.properties.header ?? false,
        ),
        isTrue,
      );
    });

    testWidgets('PulseBottomSheet title is a header', (tester) async {
      await tester.pumpWidget(
        wrap(const PulseBottomSheet(title: 'フィルター', child: Text('body'))),
      );
      expect(
        hasSemantics(
          tester,
          find.byType(PulseBottomSheet),
          (s) => s.properties.header ?? false,
        ),
        isTrue,
      );
    });
  });

  group('D4 — TextScaler robustness (no overflow)', () {
    Widget scaled(Widget child, double scale) => MaterialApp(
      theme: PulseTheme.light(),
      home: Builder(
        builder:
            (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(body: child),
            ),
      ),
    );

    final cases = <String, Widget>{
      'PulseButton': PulseButton(onPressed: () {}, child: const Text('保存する')),
      'PulseLoadingState': const PulseLoadingState(message: '読み込んでいます…'),
      // Render EmptyState WITH its CTA (its primary documented usage) so the
      // overflow-prone full layout is exercised.
      'PulseEmptyState': PulseEmptyState(
        icon: Icons.inbox,
        title: 'まだ記録がありません',
        description: '最初のワークアウトを記録してみましょう',
        actionLabel: '記録を始める',
        onAction: () {},
      ),
      'PulseErrorState': PulseErrorState(
        title: '読み込みに失敗しました',
        message: '時間をおいて再試行してください',
        onRetry: () {},
      ),
      'PulseSectionCard': const PulseSectionCard(
        title: '今週のトレーニング実績',
        child: Text('内容'),
      ),
    };

    for (final scale in <double>[2.0, 3.0]) {
      cases.forEach((name, widget) {
        testWidgets('$name has no overflow at TextScaler ${scale}x', (
          tester,
        ) async {
          // Pin the smallest supported phone viewport so the no-overflow
          // assertion reflects real small-screen + max-text-scale conditions
          // (the 800x600 test default is desktop-shaped and hides overflow).
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          // No pumpAndSettle: PulseLoadingState animates forever. Overflow is
          // a layout-time error already surfaced by pumpWidget's first frame.
          await tester.pumpWidget(scaled(widget, scale));
          expect(
            tester.takeException(),
            isNull,
            reason: '$name overflowed at ${scale}x text scale',
          );
        });
      });
    }
  });
}
