// Visual-regression goldens (D3) via alchemist CI goldens.
//
// CI goldens are platform-independent (see test/flutter_test_config.dart), so a
// snapshot generated on macOS matches Linux CI. Regenerate after an intentional
// visual change with `flutter test --update-goldens`.

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() {
  goldenTest(
    'PulseButton — variants × sizes',
    fileName: 'pulse_button',
    builder:
        () => GoldenTestGroup(
          columns: 3,
          children: [
            for (final variant in PulseButtonVariant.values)
              for (final size in PulseButtonSize.values)
                GoldenTestScenario(
                  name: '${variant.name}/${size.name}',
                  child: PulseButton(
                    variant: variant,
                    size: size,
                    onPressed: () {},
                    child: const Text('ボタン'),
                  ),
                ),
          ],
        ),
  );

  // `isLoading` is a *layout* contract as much as a visual one: the label stays
  // laid out (invisible) behind the spinner so the button keeps the width it had
  // before submit. Each variant is rendered twice with the identical label —
  // idle next to loading — so a regression that shrinks the busy button to the
  // spinner's size shows up as two boxes of different widths in one row.
  goldenTest(
    'PulseButton — isLoading (width is preserved)',
    fileName: 'pulse_button_loading',
    // The spinner never settles, so alchemist's default `onlyPumpAndSettle`
    // would time out. Pump a single frame at a fixed offset instead: fake-async
    // time is deterministic, so every run captures the same arc. 400ms is past
    // the 200ms button/theme implicit animations (everything else is at rest)
    // and lands mid-sweep of the 1333ms indeterminate cycle — at t=0 the arc is
    // zero-length and the spinner would be invisible in the snapshot.
    pumpBeforeTest: pumpNTimes(1, const Duration(milliseconds: 400)),
    builder:
        () => GoldenTestGroup(
          // Two columns => one variant per row, idle | loading side by side.
          columns: 2,
          children: [
            for (final variant in PulseButtonVariant.values)
              for (final isLoading in [false, true])
                GoldenTestScenario(
                  name: '${variant.name}/${isLoading ? 'loading' : 'idle'}',
                  child: PulseButton(
                    variant: variant,
                    onPressed: () {},
                    isLoading: isLoading,
                    loadingSemanticsLabel: 'Submitting',
                    child: const Text('Submit'),
                  ),
                ),
          ],
        ),
  );

  goldenTest(
    'PulseProgressIndicator — determinate',
    fileName: 'pulse_progress',
    builder:
        () => GoldenTestGroup(
          columns: 1,
          children: [
            GoldenTestScenario(
              name: '65%',
              child: const SizedBox(
                width: 240,
                child: PulseProgressIndicator(value: 0.65),
              ),
            ),
          ],
        ),
  );

  goldenTest(
    'PULSE states (empty / error / section card)',
    fileName: 'pulse_states',
    builder:
        () => GoldenTestGroup(
          columns: 1,
          children: [
            GoldenTestScenario(
              name: 'empty',
              child: const SizedBox(
                width: 320,
                height: 380,
                child: PulseEmptyState(
                  icon: Icons.inbox,
                  title: 'まだ記録がありません',
                  description: '最初のワークアウトを記録してみましょう',
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'error',
              child: const SizedBox(
                width: 320,
                height: 320,
                child: PulseErrorState(
                  title: '読み込みに失敗しました',
                  message: '時間をおいて再試行してください',
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'section-card',
              child: const SizedBox(
                width: 320,
                child: PulseSectionCard(
                  title: '今週のトレーニング',
                  child: Text('内容がここに入ります'),
                ),
              ),
            ),
          ],
        ),
  );
}
