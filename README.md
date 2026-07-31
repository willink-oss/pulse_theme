# PULSE — `pulse_theme`

[![pub package](https://img.shields.io/pub/v/pulse_theme.svg)](https://pub.dev/packages/pulse_theme)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**PULSE is i-Willink's mobile-first canonical design system for Flutter.** It is
the single front door for app UI: a Material 3 `ThemeData` factory, a token
layer code-generated from the published `@willink-labs/tokens` contract, and a
set of `Pulse*` components built mobile-first.

> **Status — Stage 2 (components), on pub.dev.** `PulseTheme.light()` /
> `PulseTheme.dark()` are real Material 3 themes projecting the code-generated
> token layer (`PulsePrimitives` / `PulseSemantics` / `PulseSpacing` /
> `PulseFontSize` / `PulseShadows`), and the first 9 `Pulse*` components ship on
> the violet baseline: `PulseButton`, `PulseEmptyState`, `PulseErrorState`,
> `PulseLoadingState`, `PulseSectionCard`, `PulseTabBar`, `PulseBottomSheet`,
> `PulseSnackBar`, `PulseProgressIndicator`. **`0.5.0` is the first release
> published to [pub.dev](https://pub.dev/packages/pulse_theme)** — components are
> hardened (48dp tap targets, `Semantics`, `TextScaler` robustness) and covered
> by golden / visual-regression tests in CI. `PulseButton` styles on two
> independent axes — `variant` (`filled` / `outline` / `ghost`) × `tone`
> (`brand` / `danger`) — plus a non-dimming `isLoading` state, and
> `PulseSnackBar` covers `info` / `success` / `warning` / `error`. The public API
> is not frozen until `1.0.0`.

Architecture of record: [ADR-018] (i-willink-crew) and
[`doc/adr/0001-pulse-mobile-first-architecture.md`](doc/adr/0001-pulse-mobile-first-architecture.md).

---

## Why PULSE (mobile-first)

i-Willink ships both web and mobile. The web design system
([`willink-oss/willink-design-system`](https://github.com/willink-oss/willink-design-system),
the `@willink-labs/*` npm packages — React + Tailwind preset) stays exactly as
it is. PULSE is the **mobile-first** half of the same system: it is designed
for touch-first, app-shaped UI rather than ported down from desktop.

Both halves consume **one** token source of truth, so a color or radius change
is made once and both web and mobile inherit it.

```
              @willink-labs/tokens  (DTCG JSON — single source of truth)
              primitive.json + semantic.json — published on npm
                        │
            ┌───────────┴────────────┐
            │                        │
      (web, unchanged)         (mobile, PULSE)
   @willink-labs/* React      pulse_theme (this repo)
   + Tailwind preset          Dart classes are CODEGEN'd from the
   (consumes tokens)          published DTCG JSON — never hand-mirrored
```

### Token source of truth

Tokens are **not** duplicated into this repo. The DTCG JSON published as
`@willink-labs/tokens` (`primitive.json` + `semantic.json`) is the SSOT, and
PULSE's Dart token classes are **code-generated** from it. This replaces the
old "hand-written Dart mirror" approach (which could silently drift) with a
codegen step driven by the published token contract — the same single source
the web side reads.

> The codegen step is [`tool/generate_tokens.mjs`](tool/generate_tokens.mjs); CI
> (`token-codegen-gate`) regenerates from the published contract and fails on
> any drift. Covered today: `color` (primitive + semantic, incl. dark via the
> `willink.dark` extension), `radius`, `duration`, `easing`, `spacing`,
> `font-size`, `shadow` (→ `PulseShadows`). Only the semantic `motion` / `easing`
> role groups remain deferred (they pair with the future component-animation
> layer).

---

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:pulse_theme/pulse_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: PulseTheme.light(),
      darkTheme: PulseTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: Text('PULSE'))),
    );
  }
}
```

Token classes are exported for direct use, e.g. `PulseSpacing.md`,
`PulseFontSize.fontSizeLg`, `PulseSemantics.brand`.

### Customizing the brand color

Hand the factory your own `ColorScheme`. Start from `PulseTheme.lightColorScheme`
so every slot you do not care about keeps its token value:

```dart
final theme = PulseTheme.light(
  colorScheme: PulseTheme.lightColorScheme.copyWith(
    primary: const Color(0xFF2E7BFF),
  ),
);
```

> **Do not use `PulseTheme.light().copyWith(colorScheme: ...)` for this.**
> `ThemeData.copyWith` replaces the `colorScheme` field, but the component
> themes (`filledButtonTheme`, `textButtonTheme`, `inputDecorationTheme`, …)
> were already *built* from the old scheme, and Material reads those. The
> result is a split app: `Pulse*` widgets resolve
> `Theme.of(context).colorScheme` at build time and switch to your brand, while
> a plain `TextButton` or `FilledButton` keeps painting DS violet. That is not
> hypothetical — it is what makes a cancel button render violet inside a
> blue-branded app. `PulseTheme.light(colorScheme: ...)` builds the component
> themes from your scheme instead, so both halves agree.

The non-Material extras (glow, gradients) live in a `PulseBrandTokens`
extension rather than the `ColorScheme`, so re-brand them in the same call or a
blue CTA keeps a violet glow:

```dart
final theme = PulseTheme.light(
  colorScheme: PulseTheme.lightColorScheme.copyWith(primary: brandBlue),
  brandTokens: PulseBrandTokens.pulse.copyWith(brandGlow: brandBlue),
);
```

This is also why `PulseButtonTone.danger` is built from `colorScheme.error`
(and not from the fixed `PulseSemantics.danger` token): an overridden scheme
re-tints the destructive button the same way it re-tints the primary one.

### Install

```yaml
# pubspec.yaml
dependencies:
  pulse_theme: ^0.6.0
```

…or let pub add the current constraint for you:

```sh
flutter pub add pulse_theme
```

Published on [pub.dev](https://pub.dev/packages/pulse_theme) under the
`i-willink.com` verified publisher.

---

## Adopting PULSE in your app

PULSE is the default UI front door for i-Willink Flutter apps. Adoption is
**additive**: one hosted dependency, one `MaterialApp` wiring change, then the
`Pulse*` components. No app-side token table, no theme fork — a token change in
`@willink-labs/tokens` reaches your app through a normal `pub upgrade`.

### 3 steps

**1. Add the dependency**

```sh
flutter pub add pulse_theme
```

**2. Wire the theme into `MaterialApp`**

```dart
import 'package:pulse_theme/pulse_theme.dart';

MaterialApp(
  theme: PulseTheme.light(),
  darkTheme: PulseTheme.dark(),
  themeMode: ThemeMode.system,
  home: const HomePage(),
);
```

**3. Use the `Pulse*` components and the token layer**

```dart
PulseSectionCard(
  title: 'Today',
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: PulseSpacing.sm),
    child: PulseButton(
      onPressed: _save,
      variant: PulseButtonVariant.filled,
      size: PulseButtonSize.medium,
      leadingIcon: const Icon(Icons.check),
      isLoading: _saving,
      loadingSemanticsLabel: 'Saving',
      child: const Text('Save'),
    ),
  ),
);
```

`isLoading` is its own state, not a flavour of disabled: the button keeps full
opacity, refuses taps, and stays exactly as wide as it was with its label, so a
form submit never makes the layout jump. It does report as disabled to assistive
tech, which is why `loadingSemanticsLabel` exists — it names the *state*
("Saving"). The button's own label stays in the semantics tree either way, so a
busy button is never nameless: without the argument a screen reader still
announces "Save", with it "Save, Saving".

Destructive actions get their own *tone* — orthogonal to the variant, so you
choose how much emphasis a destructive action deserves without giving up its
colour. "It went through, but look at it" gets its own snack bar:

```dart
// Prominent: solid red.
PulseButton(
  onPressed: _delete,
  tone: PulseButtonTone.danger,
  leadingIcon: const Icon(Icons.delete_outline),
  child: const Text('Delete'),
);

// Same meaning, quieter: red border and label only.
PulseButton.label(
  'Delete',
  onPressed: _delete,
  variant: PulseButtonVariant.outline,
  tone: PulseButtonTone.danger,
);

PulseSnackBar.show(
  context,
  message: 'Synced 8 of 10 items',
  description: 'Two records were skipped — retry when you are back online.',
  variant: PulseSnackBarVariant.warning,
);
```

Use `warning` when the action happened but needs attention, and `error` when it
did not happen at all.

App-local wrappers (`AppTheme` / `AppSpacing`) keep working — point them at
`PulseTheme.light()` and `PulseSpacing.*` and every existing call site stays
untouched.

### Where to go next

- **Adoption guide** (per-app checklist, `willink_theme` symbol mapping, theme
  override recipes): [doc/adoption.md](doc/adoption.md)
- **Runnable sample app**: [example/](example/)
- **Architecture of record**:
  [`doc/adr/0001-pulse-mobile-first-architecture.md`](doc/adr/0001-pulse-mobile-first-architecture.md)

---

## Relationship to the rest of the design system

| Surface | Package(s) | Status |
|---|---|---|
| **Tokens (SSOT)** | `@willink-labs/tokens` (DTCG JSON, npm) | unchanged — the single source both sides read |
| **Web** | `@willink-labs/react` / `@willink-labs/tailwind-preset` (React 42 comp) | unchanged — not renamed |
| **Mobile (canonical)** | **`pulse_theme`** (this repo) | new — PULSE mobile-first DS |
| Mobile (legacy) | `willink_theme` (pub.dev) | **discontinued** — superseded by PULSE |

### Migration from `willink_theme`

PULSE supersedes the legacy `willink_theme` package (`Willink*` symbols), which
is now **discontinued**. The only real consumer of `willink_theme` is
**clubhouse** (pinned `^1.5.0`, two files under `lib/theme`), and it is on a
**Phase 0** release track — its migration to PULSE is **non-breaking and
happens after that Phase 0 ship**, not before. fit-ai (mobile) already left
`willink_theme` and is unaffected. No consumer needs to act on PULSE today.

When an app is ready, the dependency swap is:

```yaml
dependencies:
  # willink_theme: ^1.5.0   ← remove
  pulse_theme: ^0.6.0
```

The symbol port is a 1:1 rename with identical argument shapes —
`WillinkTheme.willink()` → `PulseTheme.light()`,
`WillinkTheme.willinkDark()` → `PulseTheme.dark()`,
`WillinkSpacing.*` → `PulseSpacing.*` (same `xs`/`sm`/`md`/`lg`/`xl`/`xxl`
values), `Willink<Component>` → `Pulse<Component>`. The full table lives in
[doc/adoption.md](doc/adoption.md).

The component port (`Willink*` → `Pulse*`) is a **clean-room re-brand of
i-Willink's own MIT-licensed `flutter_theme` code**. Private app code
(notably fit-ai) is never lifted — see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Versioning

Strict [SemVer 2.0](https://semver.org/). PULSE versions **independently** of
the `@willink-labs/*` npm group and of the legacy `willink_theme` package
(per [ADR-018]). `0.5.0` is the **first version published to pub.dev** (`0.4.0`
and earlier were repo-only cuts and never shipped to the registry, but stay in
[CHANGELOG.md](CHANGELOG.md) as history).

**[doc/stability.md](doc/stability.md) is the contract**: what the `1.0.0`
freeze will cover, what it deliberately will not, how enum additions and
deprecations are handled, why every public class is `final`, and how
`@willink-labs/tokens` versions map onto this package's. Read it before
depending on anything not listed as covered.

Two things worth knowing up front:

- **The public API is not frozen until `1.0.0`**, and below 1.0 a *minor* bump
  may break you (`0.6 → 0.7`). Pub's caret agrees: `^0.7.0` means
  `>=0.7.0 <0.8.0`.
- **Adding a value to a `Pulse*` enum ships in a minor release.** Do not write
  exhaustive `switch` expressions over them.

Releases are cut from a `v<version>` git tag — see
[CHANGELOG.md](CHANGELOG.md) for the per-version history.

## License

MIT — see [LICENSE](LICENSE).

[ADR-018]: https://github.com/i-willink/i-willink-crew
