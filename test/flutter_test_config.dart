import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:pulse_theme/pulse_theme.dart';

/// Alchemist config for PULSE golden tests.
///
/// Only **CI goldens** run (fonts flattened to blocks, shadows disabled) so the
/// snapshots are deterministic across macOS-dev and Linux-CI — platform goldens
/// (which depend on host font rendering) are disabled. Goldens render under
/// [PulseTheme.light]. Non-golden tests are unaffected by this wrapper.
///
/// Regenerate after an intentional visual change:
///   flutter test --update-goldens
/// (use the Flutter version pinned in the `golden-gate` CI job so committed
/// goldens match what CI verifies).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: PulseTheme.light(),
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
