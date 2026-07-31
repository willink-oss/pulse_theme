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
        icon: const Icon(Icons.inbox),
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
      // The three the D4 table originally skipped. A tab bar in particular
      // divides a fixed width between its labels, so it is the most likely of
      // the nine to overflow once text triples in size.
      'PulseTabBar': const DefaultTabController(
        length: 3,
        child: PulseTabBar(
          tabs: [Tab(text: '概要'), Tab(text: 'トレーニング履歴'), Tab(text: '設定')],
        ),
      ),
      'PulseProgressIndicator': const PulseProgressIndicator(
        value: 0.65,
        semanticsLabel: 'アップロード中',
      ),
      // The sheet's own content, laid out as PulseBottomSheet lays it out.
      // `show()` needs a route, which the harness below drives separately.
      'PulseBottomSheet content': const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('この操作は取り消せません'),
          SizedBox(height: PulseSpacing.md),
          Text('本当に削除してよろしいですか？'),
        ],
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

  // The 48dp tap-target guideline was only asserted for PulseButton. Every
  // other interactive affordance PULSE renders — the snack bar's action, the
  // tab bar's tabs, the bottom sheet's drag handle — went unchecked, and a
  // control too small to hit reliably is an accessibility defect whether or
  // not it is a button widget.
  group('D1 — 48dp tap targets beyond PulseButton', () {
    testWidgets('PulseTabBar tabs meet the guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          const DefaultTabController(
            length: 3,
            child: PulseTabBar(
              tabs: [Tab(text: '概要'), Tab(text: '履歴'), Tab(text: '設定')],
            ),
          ),
        ),
      );
      // meetsGuideline passes vacuously when there is nothing tappable to
      // measure, so prove the tabs are present AND interactive first —
      // otherwise this test would stay green if PulseTabBar rendered nothing.
      expect(find.text('概要'), findsOneWidget);
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();
      expect(DefaultTabController.of(tester.element(find.text('設定'))).index, 2);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('PulseSnackBar action meets the guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.light(),
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => Center(
                    child: ElevatedButton(
                      onPressed:
                          () => PulseSnackBar.show(
                            context,
                            message: '同期に失敗しました',
                            actionLabel: '再試行',
                            onAction: () {},
                          ),
                      child: const Text('show'),
                    ),
                  ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text('再試行'), findsOneWidget);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();

      // Let the snack bar's auto-dismiss timer fire so no timer outlives the
      // test.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('PulseBottomSheet content meets the guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.light(),
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => Center(
                    child: ElevatedButton(
                      onPressed:
                          () => PulseBottomSheet.show<void>(
                            context,
                            builder:
                                (_) => PulseBottomSheet(
                                  title: '確認',
                                  child: PulseButton(
                                    onPressed: () {},
                                    child: const Text('削除する'),
                                  ),
                                ),
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
      expect(find.text('削除する'), findsOneWidget);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  // PulseBottomSheet cannot go in the D4 table above because it needs a route.
  // Its content still has to survive 3x text on a small phone — a sheet that
  // overflows is worse than a screen that does, since it cannot be scrolled
  // away from.
  group('D4 — TextScaler robustness for route-driven surfaces', () {
    for (final scale in <double>[2.0, 3.0]) {
      testWidgets('PulseBottomSheet has no overflow at TextScaler ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: PulseTheme.light(),
            home: Builder(
              builder:
                  (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: Scaffold(
                      body: Builder(
                        builder:
                            (inner) => Center(
                              child: ElevatedButton(
                                onPressed:
                                    () => PulseBottomSheet.show<void>(
                                      inner,
                                      builder:
                                          (_) => PulseBottomSheet(
                                            title: 'アカウントを削除しますか？',
                                            child: PulseButton(
                                              onPressed: () {},
                                              child: const Text('削除する'),
                                            ),
                                          ),
                                    ),
                                child: const Text('open'),
                              ),
                            ),
                      ),
                    ),
                  ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'PulseBottomSheet overflowed at ${scale}x text scale',
        );
      });
    }
  });
}
