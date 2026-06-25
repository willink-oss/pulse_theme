# PULSE — `pulse_theme`

**PULSE is i-Willink's mobile-first canonical design system for Flutter.** It is
the single front door for app UI: a Material 3 `ThemeData` factory, a token
layer code-generated from the published `@willink-labs/tokens` contract, and
(from Stage 1) a set of `Pulse*` components built mobile-first.

> **Status — Stage 0 (foundation).** The package skeleton compiles and is
> analysis/test clean. `PulseTheme.light()` returns a Material 3 baseline.
> Components and the token codegen land in the next stages. **Not yet on
> pub.dev — `pub.dev/packages/pulse_theme` is _coming soon_.**

Architecture of record: [ADR-018] (i-willink-crew) and
[`docs/adr/0001-pulse-mobile-first-architecture.md`](docs/adr/0001-pulse-mobile-first-architecture.md).

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

> Today `@willink-labs/tokens` `primitive.json` exposes
> `color / radius / duration / easing / shadow`, and `semantic.json` exposes
> `color / motion / easing`. `spacing` and `typography` are **not yet** in the
> contract; adding them to `@willink-labs/tokens` is a prerequisite for the
> PULSE spacing/typography codegen (tracked for Stage 1).

---

## Quick start (Stage 0)

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
      home: const Scaffold(body: Center(child: Text('PULSE'))),
    );
  }
}
```

### Customizing the brand color

Re-brand via standard Material 3 `copyWith` — future `Pulse*` widgets read
colors from `Theme.of(context).colorScheme`, so overrides flow through
automatically:

```dart
final theme = PulseTheme.light().copyWith(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
);
```

### Install (once published)

```yaml
# pubspec.yaml — coming soon to pub.dev
dependencies:
  pulse_theme: ^0.1.0
```

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

The component port (`Willink*` → `Pulse*`) is a **clean-room re-brand of
i-Willink's own MIT-licensed `flutter_theme` code**. Private app code
(notably fit-ai) is never lifted — see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Versioning

Strict [SemVer 2.0](https://semver.org/). PULSE versions **independently** of
the `@willink-labs/*` npm group and of the legacy `willink_theme` package
(per [ADR-018]). `0.1.0` is the Stage-0 foundation cut; the public API is not
frozen until `1.0.0`.

## License

MIT — see [LICENSE](LICENSE).

[ADR-018]: https://github.com/i-willink/i-willink-crew
