import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:pulse_theme/pulse_theme.dart';

/// Alchemist config for PULSE golden tests.
///
/// Only **CI goldens** run (text flattened to blocks, shadows disabled) so the
/// snapshots are stable across host font rendering — platform goldens are
/// disabled. What goldens therefore guarantee is **layout and solid colors,
/// not letterforms or shadows**; that exclusion is deliberate and belongs in
/// the stability statement, not in the "someday" pile.
///
/// ## Why the diff threshold depends on where you are
///
/// The committed PNGs are generated on the x64 Linux runner by the
/// `golden-update` workflow, never locally. **On CI they are therefore
/// compared against the machine that produced them**, so any difference at all
/// is a real change and the threshold stays where it has always been: 0.005.
///
/// Off CI they are compared on a different CPU architecture, where the
/// anti-aliasing of curves and high-contrast edges genuinely differs. Measured
/// on Apple silicon against the Linux goldens (2026-07-31):
///
/// | golden              | pixels differing | of those, >32/255 | max delta |
/// |---------------------|------------------|-------------------|-----------|
/// | `pulse_button_dark` | 0.70%            | 22 px (0.014%)    | 119/255   |
/// | `pulse_loading`     | 0.78%            | 0 px              | 3/255     |
///
/// That is edge noise, not a rendering difference: the spinner's arc never
/// exceeds 3/255, and the dark button's large deltas are 22 pixels sitting on
/// the boundary between a near-black surface and a saturated fill, where a
/// half-pixel of coverage is worth ~119. Both land just above 0.005, which is
/// why the suite used to be red out of the box on the maintainer's own machine
/// — and a suite that is red on checkout teaches people to ignore it.
///
/// So off CI the threshold is [_localDiffThreshold]. That makes the local run
/// advisory and CI authoritative, which is the honest division: only CI can
/// hold the strict line, because only CI shares the generating architecture.
///
/// `PULSE_SKIP_GOLDENS=1` skips the comparison entirely — for a host that
/// diverges past even the local threshold. It cannot silence CI.
///
/// Regenerate after an intentional visual change:
///
/// ```sh
/// gh workflow run golden-update.yml --ref <branch>
/// # then download the `ci-goldens` artifact and commit it
/// ```
///
/// Never `flutter test --update-goldens`: that writes the *host's* raster, and
/// on Apple silicon it would commit goldens CI cannot reproduce.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: PulseTheme.light(),
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: CiGoldensConfig(
        enabled: _runGoldens,
        diffThreshold: _isCi ? _ciDiffThreshold : _localDiffThreshold,
      ),
    ),
    run: testMain,
  );
}

/// Set by GitHub Actions, and by essentially every other CI provider.
final bool _isCi = Platform.environment.containsKey('CI');

/// Whether to compare golden snapshots at all.
///
/// Opt-out only, and never on CI: `PULSE_SKIP_GOLDENS` must not be able to
/// silence the gate that protects `main`.
final bool _runGoldens =
    _isCi || Platform.environment['PULSE_SKIP_GOLDENS'] != '1';

/// Strict: the goldens were produced on this architecture.
const double _ciDiffThreshold = 0.005;

/// Absorbs the measured cross-architecture edge noise (see the table above),
/// with headroom above the 0.78% worst case. A regression that repaints a
/// component still moves far more than 1% of a scenario grid.
const double _localDiffThreshold = 0.01;
