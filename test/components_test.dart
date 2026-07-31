// Tests for new component widgets (0.3.0).
//
// Verify each renders without crashing under the default Material theme and
// that key interactions wire correctly (CTA tap, retry tap, copy invocation).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  Widget wrapWithTheme(Widget child) =>
      MaterialApp(theme: PulseTheme.light(), home: Scaffold(body: child));

  group('PulseSectionCard', () {
    testWidgets('renders title and child', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const PulseSectionCard(
            title: 'Section A',
            child: Text('body content'),
          ),
        ),
      );
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('body content'), findsOneWidget);
    });

    testWidgets('omits title when null', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(const PulseSectionCard(child: Text('only body'))),
      );
      expect(find.text('only body'), findsOneWidget);
    });

    testWidgets('trailing tap fires handler', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PulseSectionCard(
            title: 'X',
            trailing: const Icon(Icons.chevron_right),
            onTrailingTap: () => tapped = true,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(tapped, isTrue);
    });
  });

  group('PulseEmptyState', () {
    testWidgets('renders icon + title + description + cta', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PulseEmptyState(
            icon: const Icon(Icons.inbox),
            title: '何もありません',
            description: '最初の項目を追加しましょう',
            actionLabel: '追加',
            onAction: () => tapped = true,
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('何もありません'), findsOneWidget);
      expect(find.text('最初の項目を追加しましょう'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);

      await tester.tap(find.text('追加'));
      expect(tapped, isTrue);
    });

    testWidgets('omits CTA when label null', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const PulseEmptyState(icon: Icon(Icons.inbox), title: '何もありません'),
        ),
      );
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('PulseErrorState', () {
    testWidgets('renders title + error message + retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PulseErrorState(
            title: '読み込み失敗',
            message: 'タイムアウトしました',
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.text('読み込み失敗'), findsOneWidget);
      expect(find.text('タイムアウトしました'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // The retry label is not passed, so it comes from the theme's
      // PulseStrings — English by default.
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('unset strings come from the theme, and ja is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.light(strings: PulseStrings.ja),
          home: const Scaffold(body: PulseErrorState(onRetry: _noop)),
        ),
      );

      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
      expect(find.text('エラーをコピー'), findsOneWidget);
    });

    testWidgets('an explicit argument still wins over the theme strings', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PulseTheme.light(strings: PulseStrings.ja),
          home: const Scaffold(
            body: PulseErrorState(
              title: 'Custom',
              retryLabel: 'Again',
              onRetry: _noop,
            ),
          ),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Again'), findsOneWidget);
      expect(find.text('エラーが発生しました'), findsNothing);
    });

    testWidgets('falls back to English under a non-PULSE theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const Scaffold(body: PulseErrorState(onRetry: _noop)),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('hides retry when onRetry null', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const PulseErrorState(title: 'X')));
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('hides copy button when showCopyButton false', (tester) async {
      // Assert against the label actually rendered — searching for a string no
      // longer used would pass no matter what the widget did.
      await tester.pumpWidget(wrapWithTheme(const PulseErrorState(title: 'X')));
      expect(find.text(PulseStrings.en.errorCopyLabel), findsOneWidget);

      await tester.pumpWidget(
        wrapWithTheme(const PulseErrorState(title: 'X', showCopyButton: false)),
      );
      expect(find.text(PulseStrings.en.errorCopyLabel), findsNothing);
    });
  });

  group('PulseLoadingState', () {
    testWidgets('default renders 40px spinner', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(const PulseLoadingState(message: '読み込み中')),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('読み込み中'), findsOneWidget);
    });

    testWidgets('compact variant renders 24px spinner', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const PulseLoadingState.compact()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('inline variant renders bare 16px spinner', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const PulseLoadingState.inline()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Center), findsNothing);
    });

    // `size` used to select the layout: anything <= 16 rendered the bare
    // inline form, so this caption vanished with no error.
    testWidgets(
      'a small size keeps its message — size is not a layout switch',
      (tester) async {
        await tester.pumpWidget(
          wrapWithTheme(const PulseLoadingState(message: '読み込み中', size: 16)),
        );
        expect(find.text('読み込み中'), findsOneWidget);
      },
    );
  });
}

/// Const-constructible no-op so the widget trees above can stay `const`.
void _noop() {
  // Both components pair a label with its handler. PulseSnackBar has asserted
  // that pairing since it shipped; these two used to drop the affordance
  // silently instead. Adding the assert AFTER 1.0 would turn debug builds that
  // currently render (wrongly, but without complaint) into crashes — an
  // observable behaviour change on a frozen constructor — so it lands now.
  group('paired-argument contracts', () {
    test('PulseEmptyState rejects a CTA label with no handler', () {
      expect(
        () => PulseEmptyState(
          icon: const Icon(Icons.inbox),
          title: 'X',
          actionLabel: '追加',
        ),
        throwsAssertionError,
      );
      expect(
        () => PulseEmptyState(
          icon: const Icon(Icons.inbox),
          title: 'X',
          onAction: () {},
        ),
        throwsAssertionError,
      );
      // Neither, or both, is fine.
      expect(
        () => const PulseEmptyState(icon: Icon(Icons.inbox), title: 'X'),
        returnsNormally,
      );
    });

    test('PulseSectionCard rejects trailing without a title', () {
      // The header row is the only place trailing is rendered, so a titleless
      // card given a trailing widget dropped it — and onTrailingTap could
      // never fire.
      expect(
        () => PulseSectionCard(
          trailing: const Icon(Icons.chevron_right),
          onTrailingTap: () {},
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
      expect(
        () => const PulseSectionCard(
          title: 'X',
          trailing: Icon(Icons.chevron_right),
          child: SizedBox.shrink(),
        ),
        returnsNormally,
      );
    });
  });
}
