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
}
