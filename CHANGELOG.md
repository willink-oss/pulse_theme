# Changelog

All notable changes to `pulse_theme` will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows strict [SemVer 2.0](https://semver.org/). **The public API
is frozen as of `1.0.0`** — what that covers, and what it deliberately does not,
is defined in [doc/stability.md](doc/stability.md).

## [1.0.0] — 2026-08-03

_Generated from `@willink-labs/tokens` 2.0.0._

**The API freeze.** The public Dart surface is identical to `1.0.0-rc.1` —
no symbol was added, renamed, or removed between them. What changed is the
brand, which the token contract owns and versions separately, and the new web
binding, which adds a package rather than altering this one.

### Added — PULSE outside Flutter (`@willink-labs/pulse`)

- **New npm package, published from this repo** (`web/`): PULSE's tokens and
  semantic layer as `--pulse-*` CSS custom properties, with no dependencies and
  no build step. Ships `pulse.css` (light + dark, OS preference plus an explicit
  `data-pulse-theme` override that wins in both directions), single-mode
  `pulse.light.css` / `pulse.dark.css` for apps with exactly one appearance, and
  `tokens.js` / `.d.ts` / `.json` for code that needs resolved values. Consumers:
  Next.js (`import "@willink-labs/pulse/pulse.css"`), Electron, WordPress, plain
  HTML.
- **`tool/generate_css.mjs`** — the web emitter. Reads the same input directory
  and the same `PULSE_TOKENS_DIR` override as `generate_tokens.mjs`, so the two
  bindings cannot be generated from different sources by accident, and carries
  the same coverage guard (a new DTCG group must be emitted or explicitly
  deferred — never silently skipped).
- **What the CSS carries that `@willink-labs/css-tokens` does not**: the
  semantic radius roles (`--pulse-radius-control` / `-surface` / `-sheet` /
  `-pill` / `-inset`) and the mobile-first `--pulse-tap-target-min`. Those are
  PULSE's own decisions, absent from the token contract, which is why PULSE has
  to be what publishes them. Everything is `--pulse-`-prefixed, so both packages
  can be loaded into one document.
- **`test/web_parity_test.dart`** — proves the two bindings agree. It parses the
  emitted CSS, resolves its `var()` chains the way a browser would, and asserts
  every value equals its Dart constant, including the five radius roles that are
  hand-written on both sides. A completeness assertion fails if the stylesheet
  defines a property the test does not check, so a new token cannot slip past
  the comparison by simply not being listed. Neither per-binding drift gate can
  catch cross-binding divergence — both could drift the same way and stay green —
  which is the gap this closes.
- **CI `css-codegen-gate`** — regenerates `web/dist` from the published contract
  and fails on drift, plus a check that the emitter produced no untracked files
  (`git diff` reports nothing for an untracked path, so generated output outside
  git would ship to npm unreviewed).
- **`.github/workflows/publish-web.yml`** — npm publish on the same `v*` tag
  that publishes to pub.dev, via OIDC Trusted Publisher with provenance. Routes
  pre-releases off the `latest` dist-tag, and refuses a first publish that is a
  pre-release, because npm bootstraps `latest` to the only published version
  regardless of `--tag`.

> **Not yet done, and it blocks the npm release:** npmjs.com cannot configure a
> trusted publisher for a package that does not exist, so the first version of
> `@willink-labs/pulse` must be published by hand — and, per the guard above,
> must be a stable version rather than an rc.

### Changed — the default brand is fit-ai blue

- Replaced the violet `brand-50`–`brand-950` ramp with one built from **fit-ai's
  own brand tokens**, reproduced exactly at the two steps fit-ai defines:
  `brand-500` = `#2E7BFF` (fit-ai `brand.primary`) and `brand-600` = `#1D5FD0`
  (fit-ai `brand.primaryDeep`). The other nine steps are generated along the
  single OKLCH hue both anchors share (H = 260.6), so the ramp is one continuous
  scale rather than two palettes stitched together. The generated shadow glow
  uses `brand-600` at 30% alpha, matching the SSOT shadow token.
- `brand-600` is the primary action rather than fit-ai's headline `#2E7BFF`
  because white text on the latter reaches only **3.89:1** — below WCAG AA.
  fit-ai itself ships `primary: #2E7BFF / onPrimary: white` and carries that
  shortfall; PULSE uses the deeper anchor fit-ai already defines for the case.
  White on `#1D5FD0` is **5.83:1**. fit-ai's headline colour keeps its identity
  role at `brand-500`: glow, ring, dark-mode hover, and the `secondary` fill,
  which pairs with dark ink at 5.18:1.
- Changed the primary surface gradient to `brand-600` → `brand-700`; white
  foregrounds clear 4.5:1 across the full gradient (5.83:1 / 7.79:1).
- Adapted the dark Material scheme to `brand-400` (`#5F9DFF`) with
  `neutral-950` ink. Filled controls and primary text on the dark surface both
  clear WCAG AA (7.45:1).
- Fixed the example gallery to `ThemeMode.light`; it now demonstrates the
  package default directly instead of carrying a local palette override.
- `PulsePrimitives.blue600` stays Tailwind's `#2563EB` and a test asserts it
  differs from `brand600`. While the brand was violet, "brand" and "blue" were
  obviously different things; now that the brand is itself blue, that assertion
  is what stops the palette collapsing into a single hue.

Both prerequisites are met: `@willink-labs/tokens` 2.0.0 is published
(willink-design-system#202), this package pins it, and regenerating from the
published contract produces byte-identical output to what is committed here.
The Linux CI goldens were regenerated on the runner and six of the eight
changed — the two that did not are the neutral-only surfaces, which is a small
confirmation that the recolor went exactly where it should have.

## [1.0.0-rc.1] — 2026-07-31

_Generated from `@willink-labs/tokens` 1.9.0._

**Release candidate for the API freeze.** Nothing in `1.0.0` is planned to
differ from this except the version string. Prereleases are not resolved by a
caret constraint, so pin it exactly to try it:

```yaml
dependencies:
  pulse_theme: 1.0.0-rc.1
```

[`doc/stability.md`](doc/stability.md) is what is being frozen. Read it before
depending on anything it does not list as covered.

### Why now

An adversarial review of the whole public surface ran before this tag: four
independent lenses (exported API, observable behaviour, consumer fit, docs
truth) produced 40 candidate findings, and each non-minor one was handed to a
separate agent whose instruction was to refute it. **19 of 29 were refuted, and
none of the survivors was breaking-if-late** — nothing found requires a `2.0`
to fix later. That is the evidence the surface is ready to freeze; the
survivors are below.

### Changed — paired arguments now assert instead of dropping silently

`PulseEmptyState` accepted an `actionLabel` with no `onAction` and simply
rendered no button. `PulseSectionCard` accepted `trailing` / `onTrailingTap`
with no `title` and rendered neither — leaving a callback that could never
fire, while `onTrailingTap`'s own dartdoc promised a real button. Both now
assert, matching the contract `PulseSnackBar` has always had for the same
pairing.

This is the one review finding that had to land **before** the tag. Adding
these asserts after `1.0.0` would turn debug builds that currently render
(silently, wrongly) into crashes — an observable behaviour change on a frozen
constructor.

### Fixed — documentation that had gone false

`doc/adoption.md` is the complete API reference and had drifted from the
surface it documents:

- `PulseEmptyState.actionIcon` was typed `IconData?` (it is `Widget?` since
  `0.6.0`), and the sample below it, `icon: Icons.inbox`, **did not compile**.
- The whole `PulseErrorState` table was wrong: `title` / `retryLabel` /
  `copySuccessMessage` were listed as non-null `String` with hardcoded Japanese
  defaults. They are `String?` resolving through `PulseStrings`, whose default
  is **English**. The table told a Japanese consumer their defaults were
  already Japanese, so they would have shipped English copy. `copyLabel` was
  missing entirely, and the l10n workaround it prescribed had been obsolete
  since `PulseStrings` landed.
- It still claimed the warning snack bar shows light-mode amber in dark
  (fixed in `0.6.0`), and referenced `PulseButtonVariant.danger` twice — an
  enum value removed in `0.6.0`.
- Three documents and `.gitignore` still told contributors the golden suite is
  expected to fail locally. It has passed since `0.7.0`. **A release checklist
  that pre-authorises a red suite is how a real regression ships**, so that
  line is gone.
- The Flutter floor read `>=3.22.0` in three places (corrected to `>=3.27.0` in
  `0.6.0`), and `CONTRIBUTING.md` claimed the `shadow` token group is deferred
  from codegen when it has been emitted since Stage 2.

### Fixed — the example asserted re-branding instead of showing it

`example/lib/main.dart` and `example/README.md` both told readers to re-brand
with `PulseTheme.light().copyWith(colorScheme: ...)` — the anti-pattern
`0.6.0` replaced — and the gallery never re-branded at all.

The gallery now has a **live brand toggle** in its app bar, and its smoke test
asserts the override reaches `filledButtonTheme` and not merely the
`ColorScheme`. That is precisely the half `copyWith` leaves behind, and it is
what paints the CTAs on the empty and error tabs.

### Documented — two behaviours that are now contract

- `PulseProgressIndicator`'s range check is an `assert`, so it is stripped in
  release. Flutter then clamps silently: a release build fed React-scale values
  (0–100) renders and announces 100% for everything from 1 upward — the exact
  mistake the assert message predicts, invisible in the build where nobody is
  watching a console.
- `PulseLoadingState.size` still steps the stroke weight at 24 (2.5 below, 3
  above). The `0.6.0` notes said the size-as-layout-switch threshold was
  removed; its stroke twin survived, and is now named rather than left as a
  surprise half a logical pixel wide.

### Known, deferred to 1.x

`PulseButton`'s filled glow is cast from the 48dp tap-target box rather than
the painted button — measured overhang 22px at `small`, 12px at `medium`, 2px
at `large`, so a small button glows from a rectangle 85% taller than itself.

The clean fix requires separating the visual button from its tap target, and
the only lever for that (`tapTargetSize.shrinkWrap`) also removes the semantics
expansion the 48dp accessibility guarantee is measured on. Trading a documented
a11y promise for a shadow's geometry, unrehearsed, on the eve of a freeze is
the wrong order of risk. Pixels are explicitly outside the freeze, so this is a
`1.x` fix and the code says so where it happens.

### Added in this cycle — `PulseRadius` (was queued as 0.9.0, never released separately)

### Added — `PulseRadius`, a semantic layer over the radius scale

`PulsePrimitives` holds the raw scale (`radiusSm` … `radiusFull`); `PulseRadius`
holds the decisions made with it — *what kind of thing* is being rounded.

```dart
PulseRadius.control  //  8 — buttons, text fields
PulseRadius.surface  // 12 — cards, dialogs, snack bars
PulseRadius.sheet    // 16 — bottom sheets (edge-anchored, so a step larger)
PulseRadius.pill     //      chips, drag handles
PulseRadius.inset    //  4 — small affordances inside another surface
```

Two things about it are deliberate:

- **Every role is one PULSE actually paints.** None was invented to round out
  the set — a role nothing uses is a guess frozen into the public API, the same
  mistake as freezing a partial primitive ladder.
- **It references the primitives rather than restating their numbers**, so it
  cannot drift from the scale. If the SSOT moves `radius.lg`, `surface` moves
  with it. Locked by a test asserting identity, not equality of literals.

Every radius the DS paints now goes through these roles, so the names are
proven by use rather than asserted. Purely a rename — the goldens came back
unchanged.

Hand-written rather than generated, because the DTCG contract has a
`primitive.radius` scale but no semantic radius group. If it gains one, this
file is replaced by generated output and these member names are the contract
that generation has to satisfy.

### Added — the `PulsePrimitives` policy is now written down

`doc/stability.md` states that the raw palette is **append-only**: its colour
ladders are deliberately incomplete (`neutral`/`brand`/`blue` have 11 steps,
`green` 5, `red`/`amber` 2, `cyan`/`pink` 1 — exactly the steps the semantic
roles reference), steps are added as the SSOT grows, and none is removed or
renamed without a major. A gap in a ladder is not a promise that the step is
coming.

### Fixed

- The `0.8.0` heading in this file still read "unreleased" when `0.8.0` was
  published, so the shipped archive documented itself as unreleased. Dated, and
  `doc/releasing.md` now has the step.

## [0.8.0] — 2026-07-31

### Added — a written stability policy

[`doc/stability.md`](doc/stability.md) states what the `1.0.0` freeze will
cover and what it deliberately will not. Until now the only promise on record
was "strict SemVer, not frozen until 1.0.0", which says nothing about the
questions that actually come up: is a visual change breaking? what happens when
Flutter moves the typescale? how long does a deprecation live? can I `implements`
your widget?

Some of it is a commitment we had not made before:

- **The `ThemeData` contract is covered by the freeze.** That is the surface
  most consumers actually depend on — an app can use `PulseTheme` with zero
  `Pulse*` widgets and still be broken by a change to it.
- **The accessibility guarantees are covered.** Regressing an asserted contrast
  ratio or tap-target minimum is breaking, even though nothing fails to
  compile.
- **Adding an enum value ships in a minor release**, with the reasoning stated
  and the mitigation spelled out (don't write exhaustive switches). The
  alternative — every new variant waiting for a major — would mean a design
  system that cannot grow between majors.
- **A visual change caused by a Flutter upgrade is not our breaking change**,
  because our `TextTheme` sets `fontSize` on seven roles and inherits
  everything else from Material 3.
- **Goldens guarantee layout and solid colours, not letterforms or shadows** —
  they run with text flattened and shadows off so they compare across machines.
  Stated as a limit of the promise rather than left to be discovered.
- **A deprecation lives at least one minor release**, is never removed in a
  patch, and must ship with a described migration.

### Changed — BREAKING: every public class is `final` or `abstract final`

`Pulse*` classes can no longer be `implements`ed, `extends`ed or mixed in.

This is what makes "adding an optional parameter is a minor release" actually
true. On an ordinary open Dart class, adding *any* member breaks anyone who
`implements` it — so the additive-evolution promise the rest of this package
relies on was not something it could keep. All 18 public classes were plain
`class` until now.

Static-only namespaces (`PulseTheme`, `PulseSnackBar`, and the six generated
token classes) are `abstract final`; widgets and theme extensions are `final`.
Compose rather than inherit: wrap a `Pulse*` widget, or build brand tokens with
`PulseBrandTokens.pulse.copyWith(...)`.

### Added — token provenance in the changelog

Each release now records the `@willink-labs/tokens` version its
`lib/src/tokens/` was generated from, so "which token contract is inside this
release" is answerable from the CHANGELOG alone. Backfilled for `0.5.1`–`0.7.0`
(all 1.9.0).

## [0.7.0] — 2026-07-31

_Generated from `@willink-labs/tokens` 1.9.0._

Quality infrastructure, so that "no visual or behavioural regressions within
`1.x`" is a claim the repository can actually back.

### Added — accessibility coverage for the components that had none

The 48dp tap-target guideline was asserted for `PulseButton` and nothing else,
and the TextScaler no-overflow suite covered 5 of 9 components. A control too
small to hit reliably is a defect whether or not it is a button widget.

- **Tap targets** now checked for `PulseTabBar`'s tabs, `PulseSnackBar`'s
  action, and `PulseBottomSheet`'s content. Each test first proves the target
  actually exists and responds — `meetsGuideline` passes vacuously when there
  is nothing tappable to measure, so a test that only called it could stay
  green while the widget rendered nothing.
- **TextScaler 2× / 3× at 360×640** now also covers `PulseTabBar` (the most
  overflow-prone of the nine: it divides a fixed width between labels),
  `PulseProgressIndicator`, and `PulseBottomSheet` — the last driven through a
  real route, since a sheet that overflows cannot be scrolled away from.

Coverage is now 195 tests, up from 126 at `0.6.0`'s start.

### Added — CI gates for the claims this package already makes

Two things were checked by hand "sometimes", and both had already regressed
unnoticed: two broken dartdoc references shipped in `0.5.0`, and a file in
`lib/` shipped unformatted in `0.6.0`. A check that runs after the release is
not a gate.

- **`dart format --set-exit-if-changed`** on every PR. `flutter analyze` is
  clean on unformatted code, so nothing in the pipeline noticed.
- **`dart doc` reference check.** Note that `dart doc --dry-run` **exits 0 even
  when it reports warnings** — verified, not assumed — so the obvious
  `run: dart doc --dry-run` would have been a gate that could never fail. The
  step parses the summary line, and fails closed if that line is missing, so a
  future change to dart doc's output format is a loud failure rather than a
  silent pass.
- **pana, pinned to `0.23.15`, at `--exit-code-threshold 0`.** The score must
  stay 160/160. Pinning matters for the same reason the Flutter version is
  pinned: an unpinned pana release that reweights a check would turn CI red on
  a PR that changed nothing.

### Fixed — formatting regression from 0.6.0

`lib/src/components/pulse_error_state.dart` did not match `dart format` as run
by the Dart SDK this repo pins, and pana 0.23.15 deducted 10 points for it
locally (150/160 → 160/160 after the fix).

Worth stating precisely, because it is not what it first looked like: **pub.dev
scored `0.6.0` at 160/160 regardless.** Its analyzer runs a different SDK, and
`dart format`'s output is SDK-dependent, so the deduction never reached the
published score. The gate is still worth having — it keeps the repository
consistent with its own pinned toolchain, which is what the CI pins exist to
guarantee — but no published score was harmed.

### Security — the release path

- **Every third-party action is now pinned by commit SHA.** A tag can be
  repointed by whoever owns the action; a SHA cannot. This matters most for
  `publish.yml`, which is the job holding the OIDC identity allowed to push to
  pub.dev.
- **Added `SECURITY.md`** with a private reporting channel and the scope that
  actually applies to a package with no runtime dependencies and no I/O: the
  supply chain, not the widgets.
- **Added `.github/dependabot.yml`** for github-actions, pub (root + example),
  and the `tool/` npm ecosystem. The last one closes a structural gap: the
  token contract is pinned exactly by `tool/package-lock.json` and the
  token-codegen gate verifies against *that pin*, so a new
  `@willink-labs/tokens` release was invisible to CI forever — drift by
  staleness. Dependabot is the missing bump signal. Pinning by SHA has the same
  shape: a pin that nothing ever updates is a stale dependency by another name.

### Fixed — the token generator dropped unknown groups silently

`tool/generate_tokens.mjs` reads named token groups. Anything the DTCG contract
added that it did not know about was never visited — no error, no warning — and
because the generated Dart genuinely did not change, the token-codegen gate
stayed green. A new category arriving in a tokens MINOR (icon sizes, z-index,
breakpoints) would simply have vanished.

The generator now fails on any group that is neither emitted nor explicitly
deferred. Verified by injecting one: it exits 1 with an actionable message.

### Added — visual coverage for dark mode and three uncovered components

Dark mode had **no** golden coverage at all, which is where every colour bug
this package has shipped actually lived: white-on-red `onError` (`0.5.0`), the
invisible `inversePrimary` and the snack bar that never flipped its
success/warning tokens (`0.6.0`), and a section-card shadow that stayed at 5%
black on a surface the same colour as the scaffold behind it.

- `pulse_button_dark` — every variant × tone under `PulseTheme.dark()`.
- `pulse_states_dark` — empty / error / section card in dark.
- `pulse_tab_bar` — light and dark.
- `pulse_loading` — all three `PulseLoadingState` variants.
- `pulse_progress` now covers 0%, 65%, 100% **and** indeterminate, which is a
  different paint path entirely (no `value`).

`PulseSnackBar` and `PulseBottomSheet` remain uncovered **on purpose**, and the
golden file says so: both are overlay/route-driven, so snapshotting them means
leaving an auto-dismiss timer and an entrance route in flight at teardown.
Their colours and structure are asserted directly by their widget tests. A
named gap beats a test that fails for reasons unrelated to its subject.

### Fixed — the golden suite was red on checkout

Running `flutter test` on an Apple-silicon machine failed two golden files
against the Linux-generated PNGs, which teaches contributors to ignore a red
suite — the opposite of what a regression net is for.

Measured rather than guessed (2026-07-31, arm64 vs the x64 goldens):

| golden              | pixels differing | of those, >32/255 | max delta |
|---------------------|------------------|-------------------|-----------|
| `pulse_button_dark` | 0.70%            | 22 px (0.014%)    | 119/255   |
| `pulse_loading`     | 0.78%            | 0 px              | 3/255     |

That is edge noise, not a rendering difference — the spinner's arc never
exceeds 3/255, and the dark button's large deltas are 22 pixels on the boundary
between a near-black surface and a saturated fill, where half a pixel of
coverage is worth ~119.

The threshold is now **conditional on where the test runs**: `0.005` on CI,
which compares the goldens against the architecture that produced them and so
has no host variation to absorb, and `0.01` off CI. The local run is advisory,
CI is authoritative — the honest division, since only CI shares the generating
architecture. `PULSE_SKIP_GOLDENS=1` skips the comparison for a host that
diverges further; it cannot silence CI.

## [0.6.0] — 2026-07-31

_Generated from `@willink-labs/tokens` 1.9.0._

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

_Generated from `@willink-labs/tokens` 1.9.0._

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
