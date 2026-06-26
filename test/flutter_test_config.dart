import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:pulse_theme/pulse_theme.dart';

/// Alchemist config for PULSE golden tests.
///
/// Only **CI goldens** run (text flattened to blocks, shadows disabled) so the
/// snapshots are stable across host font rendering — platform goldens are
/// disabled. A small [CiGoldensConfig.diffThreshold] absorbs the residual
/// sub-pixel anti-aliasing of vector edges (rounded corners / borders) that can
/// differ across CPU architecture (arm64 dev → x64 CI) while still catching
/// real visual regressions. Goldens render under [PulseTheme.light]; non-golden
/// tests are unaffected by this wrapper.
///
/// Regenerate after an intentional visual change:
///   flutter test --update-goldens
/// (use the Flutter version pinned in the `flutter-gate` CI job so committed
/// goldens match what CI verifies).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: PulseTheme.light(),
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: const CiGoldensConfig(diffThreshold: 0.005),
    ),
    run: testMain,
  );
}
