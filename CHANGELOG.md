# Changelog

All notable changes to `pulse_theme` will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows strict [SemVer 2.0](https://semver.org/). It is pre-1.0
(`0.x`): the public API is not frozen until `1.0.0`, but versioning is
otherwise strict SemVer per [ADR-018] — `0.x` here means "foundation in
progress", not "minor bumps may break".

## [0.6.0] — 2026-07-31

API decisions being taken deliberately **before** the `1.0.0` freeze —
the ones that stop being fixable once the public surface is frozen.

### Added — a re-brand entry point that actually works

`PulseTheme.light()` / `dark()` now accept optional `colorScheme` and
`brandTokens`, and the schemes they default to are exposed as
`PulseTheme.lightColorScheme` / `darkColorScheme`.

```dart
PulseTheme.light(
  colorScheme: PulseTheme.lightColorScheme.copyWith(primary: brandBlue),
  brandTokens: PulseBrandTokens.pulse.copyWith(brandGlow: brandBlue),
)
```

This replaces `PulseTheme.light().copyWith(colorScheme: ...)`, which **does not
work** and was previously documented as if it did. `ThemeData.copyWith`
replaces the `colorScheme` field, but the component themes were already built
from the old scheme, and Material reads those — so a re-branded app split in
half: `Pulse*` widgets followed the new brand while plain `TextButton` /
`FilledButton` / `Chip` / `TextField` kept painting DS violet. The adoption
guide called this out as unverified; it is now verified, pinned by a test, and
it is the reason a cancel button renders violet inside a blue-branded app.

- `dialogTheme` is now part of the projection (surface + `radiusLg`). Dialogs
  were the one common surface PULSE did not theme at all.

### Fixed — dark `inversePrimary` was invisible

`inversePrimary` was left unset, so Material fell back to `onPrimary` — white.
In dark mode `inverseSurface` is the *light* ink (`#F8FAFC`), which put a plain
SnackBar's action label at **1.05:1**. Both schemes now set the slot from the
brand ladder: `brand-400` in light (6.56:1 on `#0F172A`) and `brand-600` in
dark (5.45:1 on `#F8FAFC`). Same class of bug as the dark `onError` fix in
`0.5.0` — a slot whose light-mode value cannot be reused once the surfaces
flip. Locked by `test/a11y_contrast_test.dart`.

`surfaceTint` is likewise now set explicitly. Its value is unchanged (it
already resolved to `primary`), but it is part of the contract instead of an
inherited default.

### Added — the ThemeData contract is now test-locked

`test/theme_contract_test.dart` pins all 11 component themes property by
property, the `ColorScheme` slots Material derives rather than PULSE projecting
them, and the boundary between the 7 `TextTheme` sizes PULSE owns and the
Material 3 typography it inherits.

This closes a real gap rather than adding ceremony: the only production
consumer uses **zero** `Pulse*` components — it installs the theme and renders
raw Material widgets under it — and that surface had no assertions anywhere.
The goldens do not cover it either, since they only render `Pulse*` components.

### Changed — BREAKING: one button shape across the DS

`PulseButton` painted 8px rounded rectangles while `PulseTheme`'s button themes
painted `StadiumBorder` pills — so the DS rendered two different buttons, and
which one an app got depended on whether it reached for `PulseButton` or a
plain `FilledButton`. `PulseEmptyState` and `PulseErrorState` made the split
visible *inside* PULSE, since their CTAs are plain Material buttons.

`filledButtonTheme`, `elevatedButtonTheme` and `outlinedButtonTheme` now use
`PulsePrimitives.radiusMd`, matching `PulseButton` and the web DS. Apps that
render raw Material buttons under `PulseTheme` will see their buttons change
from pills to 8px rounded rectangles.

### Changed — BREAKING: component copy is English by default, with presets

`PulseErrorState`'s defaults were hard-coded Japanese, which is a surprising
thing for a package published in English to render. All of its strings are now
nullable and fall back to a `PulseStrings` theme extension:

```dart
MaterialApp(theme: PulseTheme.light(strings: PulseStrings.ja));
```

- **Added** `PulseStrings` with `en` (the default) and `ja` presets, plus
  `PulseStrings.of(context)`. Construct your own for another language.
- **Added** `PulseErrorState.copyLabel`. The copy button's label was the one
  string that was not a parameter at all, so it could not be localized without
  forking.
- An explicitly passed argument always wins; under a non-PULSE theme the
  widget falls back to `PulseStrings.en`.

### Changed — BREAKING: `PulseEmptyState` icon slots take a `Widget`

`icon` and `actionIcon` were `IconData`, which locked empty states out of
illustrations and brand marks — the exact thing empty states tend to want — and
disagreed with `PulseButton`, whose icon slots are already `Widget?`.

```diff
-PulseEmptyState(icon: Icons.inbox, ...)
+PulseEmptyState(icon: const Icon(Icons.inbox), ...)
```

A bare `Icon(...)` still inherits the 80px size and `onSurfaceVariant` color
from the widget's `IconTheme`, so rendering is unchanged.

### Fixed — components

- **`PulseSnackBar` ignored dark mode for `success` and `warning`.** Both read
  the light `PulseSemantics` tokens unconditionally, so a dark snack bar showed
  light-mode green/amber; `PulseSemanticsDark.success` / `.warning` had zero
  references anywhere. They now flip with the theme. `info` and `error` read
  the `ColorScheme` and follow a re-brand; `success` and `warning`
  deliberately do not — green meaning "succeeded" should not change with an
  app's brand.

- **`PulseLoadingState` silently dropped its caption below 17px.** The layout
  was chosen by `size <= 16`, so `PulseLoadingState(message: '…', size: 16)`
  rendered no message and no error. `size` is now only the spinner's edge
  length; the bare layout belongs to the `.inline` constructor. This also stops
  that threshold from freezing into the 1.0 contract.

- **`PulseSectionCard`** drew `radiusMd` while its own dartdoc and the sibling
  `cardTheme` said `radiusLg` — now `radiusLg`. Its shadow was a hand-coded
  5%-black that never darkened in dark mode, where the card and the scaffold
  are both `surface` and the shadow is the only thing separating them; it now
  uses the theme's `PulseBrandTokens.shadowSoft`, which carries a dark variant.

- **`PulseSectionCard`'s tappable trailing area was not a button.** A bare
  `GestureDetector` gave it no button role for assistive tech and no 48dp
  minimum target, contradicting the D1/D2 hardening the rest of the package
  passes. It is now a real `InkWell` under `Semantics(button: true)` with the
  48dp minimum, and stays inert when `onTrailingTap` is null.

- The declared Flutter lower bound was `>=3.22.0`, but `lib/` uses
  `Color.withValues`, which shipped in 3.27. The Dart bound already forced a
  newer Flutter, so nothing was broken — but it was wrong metadata to freeze
  into 1.0. Now `>=3.27.0`.

### Changed — BREAKING: `PulseButton` styles on two axes

`PulseButtonVariant` described *structure* (`filled` / `outline` / `ghost`) but
also carried one *tone* (`danger`), so a destructive action was locked to the
highest-emphasis shape. In Dart 3 that is not fixable after a freeze: adding a
value to a public enum turns every consumer's exhaustive `switch` into a
compile error, so `dangerOutline` could never have shipped as a minor release.

The axes are now separate and fully orthogonal — all six combinations are
valid, and neither axis leaks into the other.

```diff
-PulseButton(variant: PulseButtonVariant.danger, ...)
+PulseButton(tone: PulseButtonTone.danger, ...)
```

- **Removed** `PulseButtonVariant.danger`. The enum is now `filled` / `outline`
  / `ghost` only.
- **Added** `PulseButtonTone` (`brand` / `danger`) and `PulseButton.tone`,
  defaulting to `brand` — so every call site that did not use `danger` is
  unchanged, and the rendered output for the other three variants is identical.
- `variant: outline` / `ghost` with `tone: danger` are new combinations that
  previously had to be hand-built by the caller. The adoption guide's "not in
  PULSE yet" row for them is retired.
- Glow stays a property of `filled` (either tone); `outline` / `ghost` never
  glow. The `ghost` hover/pressed wash follows the tone: `primaryContainer`
  (the `brandSoft` token) for `brand`, and the accent at 12% for `danger`,
  since the token contract has no danger equivalent and `errorContainer` is a
  slot `PulseTheme` deliberately leaves unset.

### Added

- `PulseButton.label(String, ...)` — shorthand for the common text-only button,
  equivalent to `PulseButton(child: Text(...))`. Not `const` (it builds the
  label widget). This makes the migration from a `label: String` app button a
  1:1 rename rather than a type change.

### Fixed

- `PulseButton` painted its corner radius from a hard-coded `8` at four sites
  instead of `PulsePrimitives.radiusMd`. The values were identical, so nothing
  moves — but a change to the `radius.md` token would not have propagated, and
  the token-codegen gate only diffs the generated file, so nothing would have
  caught it.
- `test/golden/pulse_golden_test.dart`'s header claimed CI goldens are
  platform-independent and could be regenerated locally with
  `--update-goldens`. They are not: anti-aliasing differs between arm64 and the
  x64 Linux runner by more than the diff threshold, which is why the committed
  PNGs are Linux-generated. The comment now says so and points at the
  `golden-update` workflow.

## [0.5.1] — 2026-07-30

### Fixed — documentation

Two dartdoc references did not resolve, so they rendered as broken links in the
API reference published on pub.dev rather than as the text they were meant to be.
`dart doc` now reports **0 warnings and 0 errors** (was 2 warnings).

- `lib/pulse_theme.dart` — `[ADR-018]` was written as a doc reference, but
  ADR-018 is an architecture document in the private crew repo, not a Dart
  symbol. It is now plain code text (`` `ADR-018` ``).
- `lib/src/components/pulse_snack_bar.dart` — `[ScaffoldMessenger.showSnackBar]`
  named the wrong type. `showSnackBar` lives on `ScaffoldMessengerState`, not on
  `ScaffoldMessenger`; the same file already referenced it correctly further
  down. Now `[ScaffoldMessengerState.showSnackBar]`.

No code, no API and no behaviour changed — doc comments only. `^0.5.0` consumers
pick this up on `pub upgrade`.

### Note — first tag-driven release

`0.5.0` was published by hand, because pub.dev cannot enable automated
publishing for a package that does not exist yet. `0.5.1` is therefore the first
version published by `.github/workflows/publish.yml` through the pub.dev Trusted
Publisher (GitHub Actions OIDC) — the path every release from here on uses.

## [0.5.0] — 2026-07-28

### Added — first pub.dev release

`0.5.0` is the **first published release of `pulse_theme` on pub.dev**, under
the verified publisher **`i-willink.com`**. Everything up to and including
`0.4.0` was developed in-repo and consumed via a git ref — those versions were
never published and remain here purely as history.

Install:

```yaml
dependencies:
  pulse_theme: ^0.5.0
```

### Added — component API

Three additive component capabilities, folded into `0.5.0` so the first
published version already carries them (see *why* below).

- **`PulseButtonVariant.danger`** — solid destructive variant for delete /
  revoke / cancel-subscription actions. Same shape, padding, radius and accent
  glow as `filled`, so the two read as peers; only the accent differs. It is
  built from `colorScheme.error` / `colorScheme.onError` rather than the fixed
  `PulseSemantics.danger` token, so a consumer's
  `PulseTheme.light().copyWith(colorScheme: ...)` re-tints it exactly the way it
  already re-tints `filled` — a re-branded app does not get a stranded red
  button.
- **`PulseButton.isLoading`** (`bool`, default `false`) and
  **`PulseButton.loadingSemanticsLabel`** (`String?`) — an in-flight state that
  is **distinct from disabled**. The button stays at full opacity (it is still
  the live affordance; only `onPressed: null` dims to 0.5) but stops accepting
  taps and swaps its label for a centered `CircularProgressIndicator` sized to
  the variant's font size. **The label is still laid out, invisibly, so the
  button keeps its width** — submitting a form no longer makes the layout jump
  under the user's finger. A loading button reports as *disabled* to assistive
  tech (it cannot be activated), so pass `loadingSemanticsLabel` to name the
  in-flight state. The invisible label stays in the semantics tree, so the
  button keeps its accessible name regardless — without the argument a screen
  reader announces just the button's own text, with it the text plus the state.
  Same fallback spirit as `PulseLoadingState.semanticsLabel`, which falls back
  to its `message`.
- **`PulseSnackBarVariant.warning`** — sits between `success` and `error`, using
  `Icons.warning_amber_rounded` tinted with the `PulseSemantics.warning` token
  (amber `#D97706`), the same fixed-token convention `success` already follows.
  Reach for `warning` when the action **went through but needs attention**
  (partial sync, approaching a limit, stale data) and for `error` when the
  action **did not happen**.

### Added

- **`example/`** — a runnable gallery app covering all 9 components
  (`PulseButton`, `PulseEmptyState`, `PulseErrorState`, `PulseLoadingState`,
  `PulseSectionCard`, `PulseTabBar`, `PulseBottomSheet`, `PulseSnackBar`,
  `PulseProgressIndicator`) in both `PulseTheme.light()` and
  `PulseTheme.dark()`. Also surfaces as the **Example** tab on pub.dev. Its
  smoke test (render every tab, drive the bottom-sheet → snack-bar round trip)
  runs in CI, so a published example cannot silently rot.
- **`doc/adoption.md`** — adoption guide for i-Willink apps (install, the
  `AppTheme` / `AppSpacing` wiring pattern, and the `willink_theme` →
  `pulse_theme` symbol mapping).
- **`doc/releasing.md`** — the release procedure (version bump → changelog →
  tag → automated publish) and the manual first-publish exception.
- **`topics`** and **`platforms`** declared in `pubspec.yaml`. Platform support
  is the full set (Android, iOS, Linux, macOS, Web, Windows) — the package is
  pure Dart/Flutter with no platform channels and no `dart:io` / `dart:ffi` /
  `dart:html` usage.

### Changed

- **README** rewritten for a published package — pub.dev version badge,
  `pub add` install instructions, and an adoption section replacing the
  git-ref-based setup notes.
- **`.github/workflows/publish.yml`** is now **idempotent**: it skips the
  publish step when the version already exists on pub.dev, so re-running a
  release (or tagging a version that was published manually) no longer fails
  the workflow.

### Fixed — accessibility

- **Dark-mode `onError` is now the dark background ink (`#020617`), not white.**
  `PulseButtonVariant.danger` is the first and only consumer of the
  (`error`, `onError`) pair, and in dark mode `error` is the lighter red-500
  (`#EF4444`): white on it is **3.76:1**, below WCAG AA 4.5:1 for the button's
  `w600` 14/16/18px label (none of those sizes reaches the 18.66px "large bold
  text" threshold that would allow 3:1). Inking it with `PulseSemanticsDark.bg`
  gives **5.36:1** and matches Material 3's own dark convention. Light mode is
  unchanged (white on red-600 = 4.83:1). `PulseSemanticsDark.brandFg` itself is
  untouched — only the `ColorScheme` slot in the hand-written
  `lib/src/pulse_theme.dart` changed. Consumers who prefer white on a darker
  red can still do `copyWith(colorScheme: cs.copyWith(error: ..., onError: ...))`.
  New `test/a11y_contrast_test.dart` locks every (accent, on-accent) pair the
  solid button variants paint, in both modes.

### Fixed — packaging

- `test/golden/failures/` is now `.gitignore`d. `dart pub publish` bundles every
  file under the package root except what `.gitignore` / `.pubignore` excludes —
  *untracked is not excluded* — so a local failing golden run (which alchemist
  always produces on macOS, where the Linux-generated goldens cannot match
  bit-for-bit) would otherwise have baked four diff PNGs into the published
  archive permanently. `--dry-run` does not warn about this.

### Note — why the component API lands in `0.5.0`

An audit of PULSE's largest internal consumer (**fit-ai**) found that swapping
its existing widgets for `Pulse*` without these three would be a **feature
regression**: its `AppButton` uses `isLoading` at ~30 call sites, its feedback
helper exposes a `showWarning(...)` severity PULSE could not express, and it has
a destructive button style with no PULSE equivalent. Since `0.5.0` is the first
version to reach pub.dev and nothing is published yet, they are folded into it
rather than deferred to a `0.6.0` — a design system whose first release still
forces every app to keep its own button wrapper has not actually replaced
anything.

### Note — API surface

Everything above is **additive**: no symbol was renamed or removed, and both new
`PulseButton` parameters default to the `0.4.0` behaviour, so existing call
sites compile unchanged. The one caveat is `PulseSnackBarVariant.warning` —
adding an enum value makes an *exhaustive* `switch` over `PulseSnackBarVariant`
non-exhaustive. No published version ever exposed the three-value enum, so no
pub.dev consumer can be affected by it.

Be aware that in Dart's pre-1.0 caret semantics, **`^0.5.0` means
`>=0.5.0 <0.6.0`** — a `0.6.0` release will *not* be picked up automatically.
Per the SemVer policy above, the public API is not frozen until `1.0.0`, so
pin with the caret and read this changelog before bumping the minor.

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
