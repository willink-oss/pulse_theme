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

## Or skip the CSS entirely

If you just want components, add the second stylesheet and use class names — no
build step, no plugin, no JavaScript, any framework:

```ts
import "@willink-labs/pulse/pulse.css";
import "@willink-labs/pulse/components.css";
```

```tsx
<button className="pulse-btn">保存する</button>
<button className="pulse-btn pulse-btn--outline">下書き</button>
<button className="pulse-btn pulse-btn--danger">削除</button>

<div className="pulse-card">
  <h3 className="pulse-card__title">セクションカード</h3>
  <p className="pulse-card__body">…</p>
</div>

<div className="pulse-alert pulse-alert--success">保存しました</div>
<input className="pulse-input" aria-invalid={!!error} />
<span className="pulse-badge">NEW</span>
```

These are the **same nine components the Flutter package ships**, expressed as
CSS — sizes, radii, and variant axes taken from the Dart source, so
`pulse-btn pulse-btn--outline pulse-btn--danger` is the same design decision as
`PulseButton(variant: outline, tone: danger)`.

| class | mirrors |
| --- | --- |
| `.pulse-btn` `--outline` `--ghost` `--danger` `--sm` `--lg` | `PulseButton` (variant × tone × size, plus `aria-busy` loading) |
| `.pulse-card` | `PulseSectionCard` |
| `.pulse-alert` `--success` `--warning` `--error` | `PulseSnackBar` |
| `.pulse-tabs` | `PulseTabBar` |
| `.pulse-progress` | `PulseProgressIndicator` |
| `.pulse-spinner` `--compact` `--inline` | `PulseLoadingState` |
| `.pulse-state` `--error` | `PulseEmptyState` / `PulseErrorState` |
| `.pulse-sheet` | `PulseBottomSheet` (put it on a `<dialog>`) |
| `.pulse-input` `.pulse-label` `.pulse-badge` | web-only — no Flutter counterpart yet |

**They carry no behaviour.** A tab strip is styling for markup whose
`aria-selected` you drive; a sheet is a styled `<dialog>`, so the browser gives
you the focus trap and Escape handling. When you need behaviour — roving
tabindex, portals, controlled state — reach for
[`@willink-labs/react`](https://www.npmjs.com/package/@willink-labs/react),
which wraps Radix. The two are different tiers on purpose, the way DaisyUI and
shadcn/ui are.

Every interactive class meets the 48px tap-target minimum, and does it the way
the Flutter components do — by expanding the *hit area* with a pseudo-element
rather than inflating the painted box, so a small button stays visually small
and is still comfortably tappable. Focus is always visible, and every animation
is disabled under `prefers-reduced-motion`. Everything is `pulse-`-prefixed, so
it drops into a page already running DaisyUI, Bootstrap, or plain Tailwind
without colliding.

## Or use it through Tailwind

```css
/* app/globals.css */
@import "tailwindcss";
@import "@willink-labs/pulse/pulse.css";
@import "@willink-labs/pulse/tailwind.css";
```

```tsx
<button className="bg-brand text-brand-fg rounded-control px-md min-h-tap">
  保存する
</button>
<div className="bg-surface-subtle rounded-surface p-lg shadow-soft">…</div>
```

The bridge uses `@theme inline`, which makes Tailwind emit
`var(--pulse-color-brand)` into the utility instead of resolving it to a hex at
build time. That is the point: the value stays a live reference, so
`data-pulse-theme="dark"` and your own `:root` overrides still move it. A plain
`@theme` would bake today's light value into `.bg-brand` and the utility would
silently stop following the appearance.

`rounded-control` / `rounded-surface` / `min-h-tap` are the reason to reach for
this rather than hand-rolling a theme block: they say *what* is being rounded
and *what* the target minimum is, rather than restating numbers.

> **Do not import this alongside `@willink-labs/tailwind-preset`.** Both claim
> `--color-brand`, so both produce `bg-brand`. It is not broken — the later
> import wins, deterministically — but the middle of the ramp will not match,
> because the preset derives its scale from one input via OKLCH `color-mix`
> while these are literals: at step 500 that is `#2e7bff` (fit-ai's headline
> colour) here versus `#4279d9` there. Step 600, the anchor, always agrees.
> Use the preset if you are consuming `@willink-labs/react`, whose components
> are styled against it; use this if PULSE is your system.

## Style with the variables directly

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
| One panel dark inside a light page | `<div data-pulse-theme="dark">` |
| App is *only ever* dark | Import `@willink-labs/pulse/dark.css` instead |
| App is *only ever* light | Import `@willink-labs/pulse/light.css` instead |

The attribute always wins over the OS, in both directions, and it works on **any
element** — not just `<html>`. Custom properties inherit, so the attribute
re-declares the semantic roles on whatever carries it and every descendant picks
them up. That is what lets a marketing page put a dark hero inside a light
document without a second stylesheet.

The single-mode builds carry no media query and no attribute rules at all — use
them when the app has exactly one appearance, so it does not ship a theme it can
never show.

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
