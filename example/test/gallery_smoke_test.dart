// Smoke test — proves the gallery renders and its overlays work, so the
// published example is known-good rather than assumed-good.
//
// Note: the gallery always has a live spinner on screen (PulseLoadingState),
// so `pumpAndSettle()` would never return. Every wait here is an explicit
// `pump(duration)`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';
import 'package:pulse_theme_example/main.dart';

/// The gallery's vertical list (not the TabBarView's horizontal PageView).
Finder get _list =>
    find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable));

void main() {
  testWidgets('every tab renders its components', (tester) async {
    await tester.pumpWidget(const PulseExampleApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PULSE Gallery'), findsOneWidget);
    expect(find.byType(PulseTabBar), findsOneWidget);
    expect(find.byType(PulseButton), findsWidgets);

    // The ListView is lazy — scroll each card into view before asserting.
    //
    // Scroll by the card's *title*, not by widget type. `scrollUntilVisible`
    // has to work with a finder that is empty-then-exactly-one: it polls
    // `evaluate().isEmpty` on every drag (so a `.first` finder throws
    // "No element" on the very first poll) and finishes with
    // `ensureVisible(element(finder))`, which needs `single` (so a bare
    // `byType` finder throws "Too many elements" once the card is on screen and
    // renders two indicators). The section titles are unique, so they satisfy
    // both ends.
    await tester.scrollUntilVisible(
      find.text('PulseProgressIndicator'),
      300,
      scrollable: _list,
    );
    expect(find.byType(PulseProgressIndicator), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('PulseLoadingState'),
      300,
      scrollable: _list,
    );
    expect(find.byType(PulseLoadingState), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('BottomSheet を開く'),
      300,
      scrollable: _list,
    );
    expect(find.byType(PulseSectionCard), findsWidgets);

    await tester.tap(find.text('空状態'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PulseEmptyState), findsOneWidget);

    await tester.tap(find.text('エラー'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PulseErrorState), findsOneWidget);
  });

  testWidgets('bottom sheet returns its result to a snack bar', (tester) async {
    await tester.pumpWidget(const PulseExampleApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.text('BottomSheet を開く'),
      300,
      scrollable: _list,
    );

    await tester.tap(find.text('BottomSheet を開く'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PulseBottomSheet), findsOneWidget);

    await tester.tap(find.text('適用'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('フィルターを適用しました'), findsOneWidget);

    // Let the snack bar's auto-dismiss timer fire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the button matrix covers every variant × tone pair', (
    tester,
  ) async {
    await tester.pumpWidget(const PulseExampleApp());
    await tester.pump(const Duration(milliseconds: 300));

    // The matrix labels each row '<variant> / <tone>', so every row existing is
    // the proof it iterates both enums' `.values` rather than a hardcoded list.
    // The card is a single list child, so its whole subtree is built even where
    // it is clipped — no scrolling needed to find it.
    for (final variant in PulseButtonVariant.values) {
      for (final tone in PulseButtonTone.values) {
        expect(
          find.text('${variant.name} / ${tone.name}'),
          findsOneWidget,
          reason: 'the matrix should have a ${variant.name}/${tone.name} row',
        );
      }
    }

    // …plus one realistic destructive action, carrying the tone on the default
    // (filled) structure.
    final destructive = find.widgetWithText(PulseButton, '削除');
    expect(destructive, findsOneWidget);
    final button = tester.widget<PulseButton>(destructive);
    expect(button.tone, PulseButtonTone.danger);
    expect(button.variant, PulseButtonVariant.filled);
  });

  testWidgets('isLoading swaps the label for a spinner, same width', (
    tester,
  ) async {
    await tester.pumpWidget(const PulseExampleApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Unique text, so the finder is empty-then-exactly-one (see the note above).
    //
    // This card is close enough to the top that it is already *built* (just
    // clipped), so `scrollUntilVisible` skips its drag loop entirely and only
    // runs the closing `ensureVisible`, which jumps the scroll position without
    // pumping. Without the pump below, the layout is a frame stale and `tap`
    // computes an off-screen offset that hit-tests nothing.
    await tester.scrollUntilVisible(
      find.text('プロフィールを保存'),
      300,
      scrollable: _list,
    );
    await tester.pump();

    // The label stays in the tree while loading (invisible, but laid out), so
    // this finder resolves in both states — which is the point of the test.
    final button = find.widgetWithText(PulseButton, 'プロフィールを保存');
    final idleWidth = tester.getSize(button).width;

    await tester.tap(button);
    await tester.pump();

    final spinner = find.descendant(
      of: button,
      matching: find.byType(CircularProgressIndicator),
    );
    expect(spinner, findsOneWidget);
    expect(
      tester.widget<CircularProgressIndicator>(spinner).semanticsLabel,
      '保存中',
      reason: 'the spinner is what assistive tech announces while loading',
    );
    expect(
      tester.getSize(button).width,
      idleWidth,
      reason: 'the button must not resize when it starts loading',
    );

    // The demo's fake request resolves after 3s and reports via a snack bar.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(spinner, findsNothing);
    expect(find.text('プロフィールを保存しました'), findsOneWidget);
    expect(tester.getSize(button).width, idleWidth);

    // Let the snack bar's auto-dismiss timer fire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the warning snack bar launches from the gallery', (
    tester,
  ) async {
    await tester.pumpWidget(const PulseExampleApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.text('SnackBar: warning'),
      300,
      scrollable: _list,
    );
    // `scrollUntilVisible` ends on an unpumped `ensureVisible` jump — pump so
    // the tap below is computed against the settled layout.
    await tester.pump();

    await tester.tap(find.text('SnackBar: warning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('一部の項目を同期できませんでした'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    // Let the snack bar's auto-dismiss timer fire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  });
}
