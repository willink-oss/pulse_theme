# `@willink-labs/pulse`

**PULSE as CSS custom properties.** This is the web binding of
[PULSE](https://github.com/willink-oss/pulse_theme), i-Willink's design system —
the same tokens the Flutter package [`pulse_theme`](https://pub.dev/packages/pulse_theme)
is built from, emitted as `--pulse-*` variables.

No dependencies, no build step, no framework. One stylesheet.

```bash
npm i @willink-labs/pulse
```

## Use it

**Next.js / any bundler** — import once, in the root layout:

```ts
// app/layout.tsx
import "@willink-labs/pulse/pulse.css";
```

**Plain HTML / Electron / WordPress** — link the file directly:

```html
<link rel="stylesheet" href="node_modules/@willink-labs/pulse/dist/pulse.css" />
```

Then style with the variables:

```css
.card {
  background: var(--pulse-color-surface-subtle);
  color: var(--pulse-color-fg);
  border: 1px solid var(--pulse-color-border);
  border-radius: var(--pulse-radius-surface);
  padding: var(--pulse-space-md);
  box-shadow: var(--pulse-shadow-soft);
}
.card button {
  min-height: var(--pulse-tap-target-min);
  border-radius: var(--pulse-radius-control);
  background: var(--pulse-color-brand);
  color: var(--pulse-color-brand-fg);
}
```

## Light and dark

`pulse.css` ships light as the base and dark two ways, because either alone is a
bug: the OS preference alone gives an in-app theme switch nothing to switch, and
an attribute alone ignores a user who never opens your settings.

| You want | Do this |
| --- | --- |
| Follow the OS | Nothing — `pulse.css` already does |
| Force dark, ignore OS | `<html data-pulse-theme="dark">` |
| Force light, ignore OS | `<html data-pulse-theme="light">` |
| App is *only ever* dark | Import `@willink-labs/pulse/dark.css` instead |
| App is *only ever* light | Import `@willink-labs/pulse/light.css` instead |

The attribute always wins over the OS, in both directions. The single-mode
builds carry no media query and no attribute rules at all — use them when the
app has exactly one appearance, so it does not ship a theme it can never show.

## Re-brand

Override the role on `:root`. Dependent roles follow, because the CSS keeps the
token contract's aliases as `var()` references rather than flattening them:

```css
:root {
  --pulse-color-brand: #f0883e;
}
/* --pulse-color-ring now follows too */
```

**What this does not do.** Overriding `--pulse-color-brand` does *not* move
`--pulse-color-brand-hover` / `-active` / `-soft`. Those roles point at numeric
steps (`--pulse-color-brand-700` and friends) in the token contract, not at the
role, so a single override cannot derive the whole ramp. Two honest options:

```css
/* 1. override the steps you actually use */
:root {
  --pulse-color-brand: #f0883e;
  --pulse-color-brand-hover: #d97528;
  --pulse-color-brand-active: #b85f1c;
}
```

2. Use [`@willink-labs/tailwind-preset`](https://www.npmjs.com/package/@willink-labs/tailwind-preset),
   which derives the ramp at render time with OKLCH `color-mix`. PULSE
   deliberately does not: a computed value here would be one the Flutter binding
   cannot reproduce, and cross-binding parity is the point of this package.

## Tokens as data

For code that needs the value rather than the reference — a canvas renderer, a
test, a theme-switch script — the same tokens are exported with every alias
resolved to a literal:

```ts
import { pulseScaleTokens, pulseLightTokens, pulseDarkTokens } from "@willink-labs/pulse";

pulseLightTokens["--pulse-color-brand"]; // "#2563eb"
pulseScaleTokens["--pulse-radius-surface"]; // "0.75rem"
```

## What's in it

| Group | Variables | Notes |
| --- | --- | --- |
| `--pulse-color-<scale>-<step>` | `neutral` `brand` `blue` `green` `cyan` `pink` `sky` `red` `amber`, 50–950 | raw scales; prefer the roles |
| `--pulse-color-<role>` | `bg` `fg` `border` `brand` `danger` `success` … | named by role, flips with the mode |
| `--pulse-radius-<step>` | `sm` `md` `lg` `xl` `full` | raw scale |
| `--pulse-radius-<role>` | `control` `surface` `sheet` `pill` `inset` | **PULSE's own** — see below |
| `--pulse-space-<step>` | `xs` `sm` `md` `lg` `xl` `2xl` | |
| `--pulse-text-<step>` | `xs` … `3xl` | `rem`, so it respects the user's font size |
| `--pulse-shadow-<step>` | `soft` `md` `glow` | `soft`/`md` flip with the mode |
| `--pulse-duration-*`, `--pulse-easing-*` | | |
| `--pulse-tap-target-min` | `48px` | the mobile-first contract |

### The radius roles

`--pulse-radius-control` (8px) is for things a finger operates — buttons,
inputs. `--pulse-radius-surface` (12px) is for things that *hold* content —
cards, dialogs. One step apart on purpose, so a card reads as the container and
the button as the thing inside it. `--pulse-radius-sheet` (16px) is for
screen-edge surfaces, `--pulse-radius-pill` for chips and handles, and
`--pulse-radius-inset` (4px) for small affordances *inside* another surface.

These are the roles PULSE actually paints; none was invented to round out the
set. They are the reason this package exists rather than pointing you at
[`@willink-labs/css-tokens`](https://www.npmjs.com/package/@willink-labs/css-tokens),
which is a flat projection of the raw token contract and has no semantic radius
layer. Both can coexist in one document — this package prefixes everything with
`--pulse-`.

## Generated, and checked

Nothing here is hand-written. `tool/generate_css.mjs` emits it from the
`@willink-labs/tokens` DTCG contract — the same input, read the same way, as the
Dart emitter that produces `PulsePrimitives` / `PulseSemantics` for the Flutter
package. Two gates keep that honest:

- **`css-codegen-gate`** re-runs the emitter in CI and fails on any drift from
  the committed output, so a hand-edit breaks the build.
- **`test/web_parity_test.dart`** parses this CSS and asserts each value equals
  its Dart counterpart — including the semantic radius roles, which are the one
  thing written by hand on both sides.

A color changed in the token contract lands in the Flutter app and the Next.js
app from one regenerate, and CI proves the two did not diverge.

## License

MIT © i-Willink
