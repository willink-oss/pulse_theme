// Tests for PulseBottomSheet (1.2.0).
//
// Cover the show() helper contract (open / pop value / barrier dismiss),
// brand color contracts (surface / top-rounded shape / drag handle), the
// title + child content scaffold, and ColorScheme override flow-through.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  /// Host app with an 'open' button that invokes [onTap] with a context
  /// below MaterialApp (required by showModalBottomSheet).
  Widget host({
    required void Function(BuildContext) onTap,
    ThemeData? theme,
  }) =>
      MaterialApp(
        theme: theme ?? PulseTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => onTap(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

  /// Finds the manual drag handle container (32×4) rendered by show().
  Finder dragHandleFinder() => find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints == BoxConstraints.tight(const Size(32, 4)),
      );

  group('PulseBottomSheet — rendering', () {
    testWidgets('show() opens the sheet with builder content + drag handle',
        (tester) async {
      await tester.pumpWidget(
        host(
          onTap: (context) => PulseBottomSheet.show<void>(
            context,
            builder: (context) => const Text('シート本文'),
          ),
        ),
      );

      expect(find.text('シート本文'), findsNothing);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('シート本文'), findsOneWidget);
      expect(dragHandleFinder(), findsOneWidget);
    });

    testWidgets('content scaffold renders title above child', (tester) async {
      await tester.pumpWidget(
        host(
          onTap: (context) => PulseBottomSheet.show<void>(
            context,
            builder: (context) => const PulseBottomSheet(
              title: 'フィルター',
              child: Text('Body'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('フィルター'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);

      // Title sits above the body content.
      final titleRect = tester.getRect(find.text('フィルター'));
      final bodyRect = tester.getRect(find.text('Body'));
      expect(titleRect.center.dy, lessThan(bodyRect.center.dy));
    });
  });

  group('PulseBottomSheet — brand colors', () {
    testWidgets('sheet surface uses colorScheme.surface + radiusXl top shape',
        (tester) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        host(
          theme: theme,
          onTap: (context) => PulseBottomSheet.show<void>(
            context,
            builder: (context) => const Text('Body'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, equals(theme.colorScheme.surface));
      expect(
        material.shape,
        equals(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(PulsePrimitives.radiusXl),
            ),
          ),
        ),
      );
    });

    testWidgets('drag handle uses outlineVariant color', (tester) async {
      final theme = PulseTheme.light();
      await tester.pumpWidget(
        host(
          theme: theme,
          onTap: (context) => PulseBottomSheet.show<void>(
            context,
            builder: (context) => const Text('Body'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final handle = tester.widget<Container>(dragHandleFinder());
      final decoration = handle.decoration! as BoxDecoration;
      expect(decoration.color, equals(theme.colorScheme.outlineVariant));
    });
  });

  group('PulseBottomSheet — interaction', () {
    testWidgets('resolves with the value passed to Navigator.pop',
        (tester) async {
      late Future<String?> result;
      await tester.pumpWidget(
        host(
          onTap: (context) {
            result = PulseBottomSheet.show<String>(
              context,
              builder: (context) => TextButton(
                onPressed: () => Navigator.pop(context, 'saved'),
                child: const Text('保存'),
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('保存'), findsNothing);
      expect(await result, equals('saved'));
    });

    testWidgets('barrier tap dismisses the sheet and resolves null',
        (tester) async {
      late Future<String?> result;
      await tester.pumpWidget(
        host(
          onTap: (context) {
            result = PulseBottomSheet.show<String>(
              context,
              builder: (context) => const Text('Body'),
            );
          },
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);

      // Top-left corner is outside the bottom-anchored sheet → barrier.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Body'), findsNothing);
      expect(await result, isNull);
    });
  });

  group('PulseBottomSheet — ColorScheme override', () {
    testWidgets('respects copyWith(colorScheme: ...) override',
        (tester) async {
      // Brand customization path: consumers override ColorScheme and the
      // sheet surface + drag handle follow automatically.
      final overridden = PulseTheme.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      );

      await tester.pumpWidget(
        host(
          theme: overridden,
          onTap: (context) => PulseBottomSheet.show<void>(
            context,
            builder: (context) => const Text('Body'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, equals(overridden.colorScheme.surface));

      final handle = tester.widget<Container>(dragHandleFinder());
      final decoration = handle.decoration! as BoxDecoration;
      expect(
        decoration.color,
        equals(overridden.colorScheme.outlineVariant),
      );
    });
  });
}
