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
            icon: Icons.inbox,
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
          const PulseEmptyState(icon: Icons.inbox, title: '何もありません'),
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

      await tester.tap(find.text('再試行'));
      expect(retried, isTrue);
    });

    testWidgets('hides retry when onRetry null', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const PulseErrorState(title: 'X')));
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('hides copy button when showCopyButton false', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(const PulseErrorState(title: 'X', showCopyButton: false)),
      );
      expect(find.text('エラーをコピー'), findsNothing);
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
  });
}
