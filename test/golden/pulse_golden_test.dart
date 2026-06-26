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
