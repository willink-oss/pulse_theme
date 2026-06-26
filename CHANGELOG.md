# Changelog

All notable changes to `pulse_theme` will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows strict [SemVer 2.0](https://semver.org/). It is pre-1.0
(`0.x`): the public API is not frozen until `1.0.0`, but versioning is
otherwise strict SemVer per [ADR-018] — `0.x` here means "foundation in
progress", not "minor bumps may break".

## [0.4.0] — 2026-06-26

### Changed — component harden (a11y / robustness)

- **D1 (a11y fix)**: `PulseButton` no longer disables Material's tap-target
  padding — every size/variant now meets the **48dp** minimum tap target
  (`MaterialTapTargetSize.padded`) while the visual stays compact.
- **D2 (Semantics)**: `PulseLoadingState` gains a `semanticsLabel` (spinner
  screen-reader announcement, falling back to `message`); `PulseErrorState` is
  a `liveRegion` (announced when it appears); `PulseSectionCard` and
  `PulseBottomSheet` titles are marked as headers.
- **D4 (TextScaler)**: `PulseEmptyState` and `PulseErrorState` now scroll
  (center-when-fits / scroll-when-overflows) instead of clipping with a
  RenderFlex overflow at large accessibility text scales. Regression tests
  assert no overflow at 2.0× and 3.0× on a 360×640 phone viewport with the
  full layouts (CTA / retry) rendered.

Test suite: **87 passing**.

### Added — release infrastructure

- `.github/workflows/publish.yml` — publishes to pub.dev on a `v*` tag via OIDC
  Trusted Publisher (analyze → test → dry-run → publish). The first publish
  needs a one-time pub.dev "Automated publishing" setup (org admin).

### Added — D3 visual regression (golden)

- Golden tests via **alchemist** CI goldens — fonts are flattened so snapshots
  are deterministic across macOS-dev and Linux-CI (`test/flutter_test_config.dart`
  runs CI goldens only). Covers `PulseButton` (variants × sizes),
  `PulseProgressIndicator`, and the empty / error / section-card states.
- CI Flutter is pinned to **3.44.2** because golden snapshots are
  Flutter-version sensitive; regenerate with `flutter test --update-goldens`
  and bump the pin together.

## [0.3.0] — 2026-06-26

### Added — Stage 2: component port (clean-room) + shadow codegen

Ports i-Willink's own MIT-licensed Flutter components (`Willink*` → `Pulse*`)
from `willink-design-system/packages/flutter_theme`. Visuals stay on the violet
baseline; brand values remain consumer-overridable. No private (fit-ai) source
consulted.

- **9 components**: `PulseButton` (+ `PulseButtonSize` / `PulseButtonVariant`),
  `PulseEmptyState`, `PulseErrorState`, `PulseLoadingState`, `PulseSectionCard`,
  `PulseTabBar`, `PulseBottomSheet`, `PulseSnackBar` (+ `PulseSnackBarVariant`),
  `PulseProgressIndicator`.
- **`PulseBrandTokens`** `ThemeExtension` (gradients / glow / shadows), attached
  to `PulseTheme.light()` (`pulse`) and `PulseTheme.dark()` (`pulseDark`). Read
  it via `Theme.of(context).extension<PulseBrandTokens>()`.
- **`PulseShadows`** added to codegen — the primitive `shadow` scale is now
  parsed from the DTCG CSS box-shadow values into `List<BoxShadow>`
  (`soft` / `softDark` / `md` / `mdDark` / `glow`); `PulseBrandTokens` consumes
  it instead of hand-coded rgba.
- Test suite expanded to **69 tests** (Stage-1b token/theme tests + ported
  component tests).

### Known follow-ups (tracked separately)

The components are a faithful port and inherit the legacy `willink_theme`
quality gaps — golden / Semantics / TextScaler coverage and the `PulseButton`
48 dp tap-target issue are deferred to the component-harden step (not a Stage-2
regression; the same state ships in `willink_theme` today).

## [0.2.0] — 2026-06-26

### Added — Stage 1b: Dart token codegen + real theme

The hand-mirror is gone. Token classes are now **code-generated** from the
published `@willink-labs/tokens` DTCG contract — the same SSOT the web side
consumes — so web and mobile stay at parity.

- `tool/generate_tokens.mjs` — emitter that reads `@willink-labs/tokens`
  (`primitive.json` + `semantic.json`) and generates
  `lib/src/tokens/pulse_tokens.dart`. Ports `isLeaf` / `flatten` /
  alias-resolution from the web `css-tokens` generator (i-Willink MIT code).
- Generated token classes: `PulsePrimitives` (color / radius / duration /
  easing), `PulseSemantics` + `PulseSemanticsDark` (semantic color roles,
  aliases folded to primitives, dark via `$extensions["willink.dark"]`),
  `PulseSpacing`, `PulseFontSize`.
- `PulseTheme.light()` is now a real theme — its `ColorScheme` is a projection
  of the semantic roles, `TextTheme` sizes come from `PulseFontSize`, and
  component radii from `PulsePrimitives`. Added `PulseTheme.dark()` (ADR-0013
  semantic flip).
- CI `token-codegen-gate` — regenerates from the published contract and fails
  on any drift from the committed Dart. Hard parity gate (no skip-when-JSON-
  unreachable escape hatch); replaces the legacy skippable sync test.

Deferred to later stages (documented in the emitter): the primitive `shadow`
group and semantic `motion` / `easing` role groups.

## [0.1.0] — 2026-06-25

### Added — Stage 0 foundation

Initial scaffold of **PULSE**, i-Willink's mobile-first canonical design
system for Flutter ([ADR-018]). Stage 0 establishes the package skeleton only;
components and token codegen follow in later stages.

- `pulse_theme` package skeleton (`pubspec.yaml`, MIT `LICENSE`, lints).
- `PulseTheme.light()` — Material 3 baseline `ThemeData` stub. Token-derived
  overrides are code-generated from `@willink-labs/tokens` in a later stage;
  the value is **not** hand-mirrored.
- CI `flutter-gate` (`flutter pub get` → `flutter analyze` → `flutter test` →
  `dart pub publish --dry-run`).
- `doc/adr/0001-pulse-mobile-first-architecture.md` recording the
  mobile-first stance, the `@willink-labs/tokens` SSOT + codegen contract, the
  clean-room (no-fit-ai-lift) rule, and independent versioning.

### Relationship to `willink_theme`

PULSE supersedes the legacy `willink_theme` package, now discontinued. No
consumer migration is required at Stage 0; clubhouse migrates non-breakingly
after its Phase 0 release.

[ADR-018]: https://github.com/i-willink/i-willink-crew
