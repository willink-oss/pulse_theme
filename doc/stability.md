# Stability policy

What `pulse_theme` promises, and — just as importantly — what it does not.

This package follows [SemVer 2.0](https://semver.org/) strictly. Until `1.0.0`
the public API is not frozen and a **minor** bump may break you (`0.6 → 0.7`);
that is also how pub's caret works below 1.0, so `pulse_theme: ^0.7.0` resolves
to `>=0.7.0 <0.8.0` and will not pick up a breaking release on its own.

From `1.0.0`, everything under **Covered by the freeze** changes only in a major
release.

---

## Covered by the freeze

These are the promise. Changing any of them requires a major version.

| | |
|---|---|
| **Exported symbols** | Every name in `lib/pulse_theme.dart`. Removing or renaming one is breaking. |
| **Constructor signatures** | Removing a parameter, renaming it, making an optional one required, or changing its type. |
| **Enum values** | Removing or renaming a value. See [Adding enum values](#adding-enum-values) for additions. |
| **Widget behaviour a caller can observe** | Which callback fires, what a `Future` resolves to, whether a control accepts taps. |
| **The `ThemeData` contract** | The component themes and `ColorScheme` slots `PulseTheme.light()` / `dark()` project, pinned property-by-property in `test/theme_contract_test.dart`. This matters because the surface most consumers actually depend on is *the theme*, not the widgets: an app can use `PulseTheme` with zero `Pulse*` widgets and still be broken by a change here. |
| **Accessibility guarantees** | The contrast ratios, tap-target minimums, semantics roles and text-scale behaviour asserted in `test/a11y_contrast_test.dart` and `test/harden_test.dart`. Regressing one is a breaking change even though nothing fails to compile. |

## Not covered by the freeze

These can change in a minor or patch release. If you depend on one, pin it in
your own tests rather than expecting us to hold it.

- **Exact pixels.** Padding, radii and spacing are expressed in tokens, and a
  token value can change (see [Token versioning](#token-versioning-ssot--pulse_theme)).
  We treat a *visible* change as CHANGELOG-worthy, always. We do not treat it as
  major.
- **Anything inherited from Flutter.** See [Flutter support](#flutter-support).
- **Private API.** Everything under `lib/src/` that the barrel does not export.
  Importing it directly is unsupported.
- **The rendering of text glyphs and shadows.** Our goldens deliberately run
  with text flattened to blocks and shadows disabled, so they can be compared
  across machines. That means goldens guarantee **layout and solid colours** —
  they are not a promise about letterforms or shadow rendering, and a change
  there can reach you without any test failing here.

---

## Adding enum values

**A new enum value ships in a minor release.** Do not write exhaustive
`switch` expressions over `Pulse*` enums; add a `default` (or a wildcard
pattern) if you switch over one.

This is a deliberate trade, and it is worth being explicit about why. In Dart 3
a `switch` *expression* over an enum must be exhaustive, so adding a value is a
compile error for anyone who wrote one — technically breaking. The alternative
is to promise that every new variant, tone or semantic waits for a major
release, which for a design system means the DS cannot grow between majors.
We chose the growth, and we tell you how to be safe.

We do it as rarely as we can, and the axis split in `0.6.0` (`PulseButtonVariant`
× `PulseButtonTone`) exists precisely so that future additions land on the axis
they belong to instead of multiplying values on one enum.

## Extending our classes

**Every public class is `final` or `abstract final`.** You cannot `implements`,
`extends` or `with` them.

This is what makes the rest of this document honest. On an ordinary (open)
Dart class, adding *any* member is breaking for someone who `implements` it —
which would mean "we added an optional parameter" could not be a minor release.
Sealing the classes buys back the ability to grow the API additively.

Compose instead of inheriting: wrap a `Pulse*` widget in your own widget, and
build brand tokens with `PulseBrandTokens.pulse.copyWith(...)` rather than a
subclass.

## Deprecation

When something must go:

1. It is marked `@Deprecated('... Use X instead. Removed in 2.0.0.')` with a
   pointer to the replacement.
2. It keeps working for **at least one minor release**, and never disappears in
   a patch.
3. It is removed only in the next major.

A deprecation always appears in the CHANGELOG under **Deprecated**, with the
migration. If we cannot describe the migration, the deprecation is not ready.

---

## Flutter support

`pulse_theme` declares the minimum Flutter version it is *tested* against, and
CI pins **one exact version** (`3.44.2` today). Goldens are generated and
verified on that pin.

**PULSE's `ThemeData` is a partial projection.** `_textTheme` sets `fontSize` on
seven roles and nothing else; weights, letter spacing, and the entire
`display*` / `label*` families come from Flutter's Material 3 typography, as do
the `ColorScheme` slots we do not set. `test/theme_contract_test.dart` pins that
boundary explicitly so it is visible rather than assumed.

Consequently:

- **A visual change caused by a Flutter upgrade is not a `pulse_theme` breaking
  change.** If Flutter moves the M3 typescale, your text moves, and we did not
  ship anything.
- Bumping the CI pin is a normal PR: it regenerates goldens and states the
  visual delta in the CHANGELOG.
- Raising the *minimum* Flutter version is a minor release, and is called out
  in the CHANGELOG.

---

## Token versioning (SSOT → `pulse_theme`)

`lib/src/tokens/pulse_tokens.dart` is **generated**, not written. Its source is
the published `@willink-labs/tokens` DTCG contract, pinned exactly by
`tool/package-lock.json`, and CI regenerates and byte-compares it on every
change.

That means the generated Dart member names *are* public API, and they come
1:1 from the SSOT's JSON keys. So the SSOT's own semver has to map onto ours:

| Change upstream in `@willink-labs/tokens` | Effect here | `pulse_theme` release |
|---|---|---|
| New key (new colour step, new spacing step) | New `static const` appears | **minor** |
| Key renamed or removed | An exported member is renamed or removed | **major** |
| Value changed, key unchanged | Rendering changes; API does not | **minor**, with the visual delta in the CHANGELOG and regenerated goldens |
| New token *category* (icon sizes, z-index, …) | The generator **fails** until the category is either projected or explicitly deferred — it will not drop it silently | minor when projected |

### `PulsePrimitives` is append-only

The raw palette is exported, and its colour ladders are **deliberately
incomplete**: `neutral`, `brand` and `blue` have all 11 steps, but `green` has
5, `red` and `amber` have 2, `cyan` and `pink` have 1. That is not an
oversight and not a design — it is what the generator emits, which is exactly
the steps the semantic roles reference.

Since `1.0.0` those members are frozen like any other export:

- **Steps are added** as the SSOT grows (minor).
- **Steps are never removed or renamed** without a major.
- A gap in a ladder is not a promise that the step will arrive.

Prefer the semantic layers — [`PulseSemantics`](../lib/src/tokens/pulse_tokens.dart),
`PulseRadius`, `PulseSpacing` — and reach for a primitive only when you
deliberately want a value the DS has no role for. `PulseRadius.control` will
follow the DS's decision about what a button's corner should be;
`PulsePrimitives.radiusMd` will only ever be 8.

Every release records the `@willink-labs/tokens` version it was generated from,
so "which token contract is inside this release" is answerable from the
CHANGELOG alone.

---

## Reporting

Something behaving differently from this document is a bug — please
[open an issue](https://github.com/willink-oss/pulse_theme/issues). For security
reports see [SECURITY.md](../SECURITY.md).
