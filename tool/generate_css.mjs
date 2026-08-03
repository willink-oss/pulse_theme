#!/usr/bin/env node
/**
 * Generate the `@willink-labs/pulse` CSS custom-property layer from the
 * @willink-labs/tokens DTCG JSON contract (primitive.json + semantic.json).
 *
 * This is the *web* sibling of `generate_tokens.mjs`. Both emitters read the
 * SAME input directory and the SAME `PULSE_TOKENS_DIR` override, so the Dart
 * binding and the CSS binding cannot be generated from different sources by
 * accident — one regenerate updates both, and `test/web_parity_test.dart`
 * proves the two outputs agree value-for-value.
 *
 * Why this exists at all, given @willink-labs/css-tokens already emits CSS
 * variables from the same SSOT: css-tokens is a flat projection of the *raw*
 * contract. PULSE adds decisions the contract does not carry — the semantic
 * radius roles (control / surface / sheet / pill / inset, see
 * `lib/src/tokens/pulse_radius.dart`) and the mobile-first tap-target minimum.
 * Those live only in PULSE, so PULSE has to be the thing that publishes them.
 * Everything a consumer can already get from css-tokens is emitted here under
 * the `--pulse-` prefix so the two can coexist in one document without
 * colliding.
 *
 * Inputs (default → the npm-resolved contract; the lockfile pins the version):
 *   node_modules/@willink-labs/tokens/src/primitive.json
 *   node_modules/@willink-labs/tokens/src/semantic.json
 * Override the input directory with PULSE_TOKENS_DIR (local pre-publish dev
 * against the workspace checkout). The CI parity gate runs with NO override so
 * it always reads the published contract.
 *
 * Outputs (default → the committed package; override the dir with PULSE_CSS_OUT
 * so the parity gate can emit to a temp path and byte-compare):
 *   ../web/dist/pulse.css        light + dark (media query + explicit attribute)
 *   ../web/dist/pulse.light.css  light only — apps that never go dark
 *   ../web/dist/pulse.dark.css   dark only — apps that are always dark
 *   ../web/dist/tokens.js        resolved values as data (ESM)
 *   ../web/dist/tokens.d.ts      types for the above
 *
 * Aliases: the CSS keeps DTCG aliases as `var(--pulse-…)` references rather
 * than folding them to a literal (which is what the Dart emitter must do —
 * Dart has no late binding). That is what makes a consumer override cascade:
 *
 *   :root { --pulse-color-brand: #f0883e; }   → also moves --pulse-color-ring
 *
 * Known limit, stated rather than papered over: an override of
 * `--pulse-color-brand` does NOT move `--pulse-color-brand-hover`, because the
 * contract points that role at the numeric step `{color.brand.700}`, not at the
 * role. Deriving a whole scale from one input needs the OKLCH `color-mix` the
 * Tailwind preset does at render time; replicating it here would put a value in
 * the CSS that the Dart binding cannot reproduce, and the parity test exists
 * precisely to stop that. Consumers wanting full scale derivation should
 * override the numeric steps too, or use @willink-labs/tailwind-preset.
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const tokensDir = process.env.PULSE_TOKENS_DIR
  ? path.resolve(process.env.PULSE_TOKENS_DIR)
  : path.resolve(__dirname, "node_modules/@willink-labs/tokens/src");

const outDir = process.env.PULSE_CSS_OUT
  ? path.resolve(process.env.PULSE_CSS_OUT)
  : path.resolve(__dirname, "../web/dist");

const primitive = readJson("primitive.json");
const semantic = readJson("semantic.json");

// ---------------------------------------------------------------------------
// PULSE-owned semantics.
//
// These are NOT in the DTCG contract — they are PULSE's own decisions, and this
// object is the web half of them. The Dart half is hand-written in
// `lib/src/tokens/pulse_radius.dart` (the contract has no semantic radius
// group, so there is nothing to generate from on either side).
//
// Two hand-written halves is exactly the drift risk the codegen exists to kill,
// so it is not left on trust: `test/web_parity_test.dart` parses the CSS
// emitted here and asserts each role equals its `PulseRadius` counterpart. If
// the SSOT ever grows a semantic radius group, both halves are replaced by
// generated output and these names are the contract generation has to satisfy.
// ---------------------------------------------------------------------------
const RADIUS_ROLES = {
  // role      → primitive radius step (must match PulseRadius)
  control: "md",
  surface: "lg",
  sheet: "xl",
  pill: "full",
  inset: "sm",
};

// The mobile-first contract PULSE components are built to: every interactive
// target is at least this big. Dart spells the same number inline at each
// `minWidth`/`minHeight` (see pulse_button.dart / pulse_section_card.dart);
// the parity test pins the two together so a change to one is a failing build.
const TAP_TARGET_MIN_PX = 48;

// ---------------------------------------------------------------------------
// Coverage guard — same discipline as generate_tokens.mjs.
//
// The emitter reads named groups, so a token category added by a tokens MINOR
// would be silently skipped and the drift gate would stay green (the output
// genuinely did not change). Fail instead: a new group must be either emitted
// or explicitly deferred.
// ---------------------------------------------------------------------------
const EMITTED = {
  primitive: ["color", "radius", "duration", "easing", "spacing", "font-size", "shadow"],
  semantic: ["color"],
};
// Deferred on purpose, matching the Dart emitter: the semantic motion / easing
// role groups pair with the component-animation layer that neither binding
// ships yet. Listed, not ignored.
const DEFERRED = {
  primitive: [],
  semantic: ["motion", "easing"],
};

for (const [name, tree] of [["primitive", primitive], ["semantic", semantic]]) {
  const known = new Set([...EMITTED[name], ...DEFERRED[name]]);
  const unknown = Object.keys(tree).filter(
    (k) => !k.startsWith("$") && !known.has(k),
  );
  if (unknown.length > 0) {
    console.error(
      `\nERROR: ${name}.json has token group(s) this generator does not know ` +
        `about: ${unknown.join(", ")}\n\n` +
        `  A new DTCG group is never a no-op. Either project it into CSS and ` +
        `add it to EMITTED, or decide it is out of scope for now and add it ` +
        `to DEFERRED (with a note in the file header saying why).\n` +
        `  Doing nothing would drop it silently: the generated CSS would be ` +
        `unchanged, so the css-codegen-gate would pass.\n`,
    );
    process.exit(1);
  }
}

function readJson(name) {
  const p = path.join(tokensDir, name);
  if (!fs.existsSync(p)) {
    console.error(
      `\n  pulse css codegen: cannot find ${name} in ${tokensDir}.\n` +
        `  Run \`npm --prefix tool ci\` first, or point PULSE_TOKENS_DIR at a\n` +
        `  checkout of @willink-labs/tokens/src.\n`,
    );
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

// --- DTCG helpers (shared shape with generate_tokens.mjs) ---------------------

function isLeaf(node) {
  return (
    typeof node === "object" &&
    node !== null &&
    "$value" in node &&
    "$type" in node
  );
}

/** Walk a DTCG group and call `fn(key, leaf)` for each leaf in source order. */
function eachLeaf(group, fn) {
  for (const [key, value] of Object.entries(group ?? {})) {
    if (key.startsWith("$")) continue;
    if (typeof value !== "object" || value === null) continue;
    if (isLeaf(value)) fn(key, value);
  }
}

/**
 * Emit color primitives in source order — same determinism argument as the Dart
 * emitter: JS iterates integer-like keys ("50".."950") ascending and string
 * keys in insertion order, both matching the JSON.
 */
function eachColorGroup(colorTree, fn) {
  for (const [group, shades] of Object.entries(colorTree)) {
    if (group.startsWith("$")) continue;
    eachLeaf(shades, (shade, leaf) => fn(group, shade, leaf));
  }
}

function isAlias(value) {
  return (
    typeof value === "string" && value.startsWith("{") && value.endsWith("}")
  );
}

// --- value conversion ---------------------------------------------------------

const VAR_PREFIX = "--pulse";

/** `#7C3AED` → `#7c3aed`; CSS is emitted lowercase for stable byte-diffs. */
function cssColor(hex) {
  let h = hex.replace("#", "").toLowerCase();
  if (h.length === 3) {
    h = h
      .split("")
      .map((c) => c + c)
      .join("");
  }
  if (h.length !== 6 && h.length !== 8) {
    throw new Error(`Unsupported color literal: ${hex}`);
  }
  return `#${h}`;
}

/**
 * Split a DTCG color alias into its `[group, shade]`.
 *   `{color.neutral.900}` → ["neutral", "900"]
 *   `{color.brand}`       → ["brand", "600"]  (group shorthand — the same
 *                           `--color-brand: …-600` convention the web preset
 *                           uses, and the same fold the Dart emitter applies)
 *
 * The one-segment case is special: `{color.brand}` as a *semantic* alias means
 * the role `--pulse-color-brand`, not the scale step, whenever a role by that
 * name exists — that is what makes `ring` follow a consumer's brand override.
 * The caller decides; this only parses.
 */
function parseColorAlias(value) {
  const segments = value.slice(1, -1).split(".");
  if (segments[0] !== "color") {
    throw new Error(`Unsupported semantic alias (non-color): ${value}`);
  }
  return segments.slice(1);
}

/**
 * Semantic color value → CSS. Aliases stay as `var()` references so a consumer
 * `:root` override cascades into every dependent role.
 */
function semanticColorValue(value, roleNames) {
  if (!isAlias(value)) return cssColor(value);
  const rest = parseColorAlias(value);
  if (rest.length === 1) {
    // `{color.brand}` — point at the role when one exists (late binding), else
    // fall back to the scale shorthand the contract means.
    return roleNames.has(rest[0])
      ? `var(${VAR_PREFIX}-color-${rest[0]})`
      : `var(${VAR_PREFIX}-color-${rest[0]}-600)`;
  }
  if (rest.length !== 2) {
    throw new Error(`Unsupported color alias depth: ${value}`);
  }
  return `var(${VAR_PREFIX}-color-${rest[0]}-${rest[1]})`;
}

/** Resolve an alias all the way to a literal — for the `tokens.js` data export. */
function resolveColor(value, seen = new Set()) {
  if (!isAlias(value)) return cssColor(value);
  if (seen.has(value)) throw new Error(`Cyclic color alias: ${value}`);
  seen.add(value);
  const rest = parseColorAlias(value);
  const [group, shade] = rest.length === 1 ? [rest[0], "600"] : rest;
  const leaf = primitive.color?.[group]?.[shade];
  if (!leaf) throw new Error(`Unresolvable color alias: ${value}`);
  return resolveColor(leaf.$value, seen);
}

/**
 * DTCG dimension → CSS length. `rem` passes through unchanged (the web's own
 * unit — it is what makes the scale respond to the user's browser font size),
 * `px` passes through. The Dart side resolves rem against 16 because Flutter
 * has no rem; `dimensionPx` here exists only so the parity test and the data
 * export can compare the two in one unit.
 */
function cssDimension(value) {
  if (typeof value !== "string") {
    throw new Error(`Unsupported dimension: ${value}`);
  }
  if (value.endsWith("rem") || value.endsWith("px")) return value;
  throw new Error(`Unsupported dimension unit: ${value}`);
}

/** Same rem→px resolution the Dart emitter uses (1rem = 16px). */
function dimensionPx(value) {
  if (value.endsWith("rem")) return parseFloat(value) * 16;
  if (value.endsWith("px")) return parseFloat(value);
  throw new Error(`Unsupported dimension unit: ${value}`);
}

// --- emit ---------------------------------------------------------------------

const roleNames = new Set(
  Object.keys(semantic.color).filter((k) => !k.startsWith("$")),
);

const HEADER = [
  "/*",
  " * GENERATED FILE — DO NOT EDIT BY HAND.",
  " *",
  " * @willink-labs/pulse — the web binding of PULSE, i-Willink's design system.",
  " *",
  " * Source of truth: @willink-labs/tokens (DTCG JSON), the same contract the",
  " * Flutter package `pulse_theme` (pub.dev) is generated from. Regenerate with",
  " * `node tool/generate_css.mjs`; CI (css-codegen-gate) re-runs the emitter and",
  " * fails on any drift from this committed output, and test/web_parity_test.dart",
  " * asserts these values equal their Dart counterparts.",
  " */",
];

/** Emit the mode-invariant scales — identical in light and dark. */
function scaleBlock() {
  const out = [];
  out.push("  /* Color primitives — the raw scales. Prefer the semantic roles below. */");
  eachColorGroup(primitive.color, (group, shade, leaf) => {
    out.push(`  ${VAR_PREFIX}-color-${group}-${shade}: ${cssColor(leaf.$value)};`);
  });

  out.push("");
  out.push("  /* Radius — raw scale. */");
  eachLeaf(primitive.radius, (key, leaf) => {
    out.push(`  ${VAR_PREFIX}-radius-${key}: ${cssDimension(leaf.$value)};`);
  });

  out.push("");
  out.push("  /* Radius — semantic roles: *what kind of thing* is being rounded. */");
  out.push("  /* PULSE's own decisions; mirrors PulseRadius in the Flutter binding. */");
  for (const [role, step] of Object.entries(RADIUS_ROLES)) {
    out.push(`  ${VAR_PREFIX}-radius-${role}: var(${VAR_PREFIX}-radius-${step});`);
  }

  out.push("");
  out.push("  /* Spacing scale — paddings / gaps / margins. */");
  eachLeaf(primitive.spacing, (key, leaf) => {
    out.push(`  ${VAR_PREFIX}-space-${key}: ${cssDimension(leaf.$value)};`);
  });

  out.push("");
  out.push("  /* Type scale. */");
  eachLeaf(primitive["font-size"], (key, leaf) => {
    out.push(`  ${VAR_PREFIX}-text-${key}: ${cssDimension(leaf.$value)};`);
  });

  out.push("");
  out.push("  /* Motion. */");
  eachLeaf(primitive.duration, (key, leaf) => {
    out.push(`  ${VAR_PREFIX}-duration-${key}: ${leaf.$value};`);
  });
  eachLeaf(primitive.easing, (key, leaf) => {
    out.push(`  ${VAR_PREFIX}-easing-${key}: ${leaf.$value};`);
  });

  out.push("");
  out.push("  /* Mobile-first contract: the minimum size of anything a finger operates. */");
  out.push(`  ${VAR_PREFIX}-tap-target-min: ${TAP_TARGET_MIN_PX}px;`);
  return out;
}

/** Emit the mode-dependent values — semantic color roles + shadows. */
function modeBlock(mode) {
  const out = [];
  out.push(`  /* Semantic color roles (${mode}) — named by role, not by hue. */`);
  eachLeaf(semantic.color, (key, leaf) => {
    const dark = leaf.$extensions?.["willink.dark"];
    const value = mode === "dark" && dark ? dark.$value : leaf.$value;
    out.push(`  ${VAR_PREFIX}-color-${key}: ${semanticColorValue(value, roleNames)};`);
  });

  out.push("");
  out.push(`  /* Shadows (${mode}). */`);
  eachLeaf(primitive.shadow, (key, leaf) => {
    const dark = leaf.$extensions?.["willink.dark"];
    const value = mode === "dark" && dark ? dark.$value : leaf.$value;
    out.push(`  ${VAR_PREFIX}-shadow-${key}: ${value};`);
  });
  return out;
}

function wrap(selector, body) {
  return [`${selector} {`, ...body, "}"];
}

// ---- pulse.light.css / pulse.dark.css ----
//
// One `:root` block, no media query, no attribute: for an app that is only ever
// one mode. agentdeck (Electron, always dark) is the reason the dark-only file
// exists — shipping the full file would make it carry a light theme it can
// never show.
function singleModeSheet(mode) {
  return [
    ...HEADER,
    "",
    `/* ${mode}-only build: no media query, no attribute switching. Use this when`,
    " * the app has exactly one appearance. For automatic light/dark, use",
    " * pulse.css instead. */",
    ...wrap(":root", [...scaleBlock(), "", ...modeBlock(mode)]),
    "",
  ].join("\n");
}

// ---- pulse.css ----
//
// Light is the base. Dark arrives two ways and BOTH are emitted, because either
// one alone is a bug:
//   - `@media (prefers-color-scheme: dark)` respects the OS setting, but an app
//     with its own theme switch cannot force light back on.
//   - `[data-pulse-theme="dark"]` respects an in-app switch, but does nothing
//     for a user who never touches it.
// The attribute rules come last and are more specific, so an explicit choice
// wins over the OS in both directions.
function fullSheet() {
  const light = modeBlock("light");
  const dark = modeBlock("dark");
  return [
    ...HEADER,
    "",
    "/* Light is the base; dark follows the OS unless the document opts out with",
    " * data-pulse-theme=\"light\". An explicit data-pulse-theme always wins. */",
    ...wrap(":root", [...scaleBlock(), "", ...light]),
    "",
    "@media (prefers-color-scheme: dark) {",
    ...wrap('  :root:not([data-pulse-theme="light"])', dark.map((l) => (l ? `  ${l}` : l))),
    "}",
    "",
    ...wrap(':root[data-pulse-theme="dark"]', dark),
    "",
    ...wrap(':root[data-pulse-theme="light"]', light),
    "",
  ].join("\n");
}

// ---- tokens.js / tokens.d.ts ----
//
// The CSS keeps aliases as `var()` for cascade; this data export resolves them
// to literals instead, because a consumer reading tokens programmatically (a
// test, a canvas renderer, a theme-switch script) needs the value, not the
// reference. Both come from the same walk, so they cannot disagree.
function dataExports() {
  const scale = {};
  eachColorGroup(primitive.color, (group, shade, leaf) => {
    scale[`${VAR_PREFIX}-color-${group}-${shade}`] = cssColor(leaf.$value);
  });
  eachLeaf(primitive.radius, (key, leaf) => {
    scale[`${VAR_PREFIX}-radius-${key}`] = cssDimension(leaf.$value);
  });
  for (const [role, step] of Object.entries(RADIUS_ROLES)) {
    scale[`${VAR_PREFIX}-radius-${role}`] = cssDimension(primitive.radius[step].$value);
  }
  eachLeaf(primitive.spacing, (key, leaf) => {
    scale[`${VAR_PREFIX}-space-${key}`] = cssDimension(leaf.$value);
  });
  eachLeaf(primitive["font-size"], (key, leaf) => {
    scale[`${VAR_PREFIX}-text-${key}`] = cssDimension(leaf.$value);
  });
  eachLeaf(primitive.duration, (key, leaf) => {
    scale[`${VAR_PREFIX}-duration-${key}`] = leaf.$value;
  });
  eachLeaf(primitive.easing, (key, leaf) => {
    scale[`${VAR_PREFIX}-easing-${key}`] = leaf.$value;
  });
  scale[`${VAR_PREFIX}-tap-target-min`] = `${TAP_TARGET_MIN_PX}px`;

  const modeMap = (mode) => {
    const m = {};
    eachLeaf(semantic.color, (key, leaf) => {
      const dark = leaf.$extensions?.["willink.dark"];
      const value = mode === "dark" && dark ? dark.$value : leaf.$value;
      m[`${VAR_PREFIX}-color-${key}`] = resolveColor(value);
    });
    eachLeaf(primitive.shadow, (key, leaf) => {
      const dark = leaf.$extensions?.["willink.dark"];
      m[`${VAR_PREFIX}-shadow-${key}`] = mode === "dark" && dark ? dark.$value : leaf.$value;
    });
    return m;
  };

  const light = modeMap("light");
  const dark = modeMap("dark");
  const stringify = (o) =>
    "{\n" +
    Object.entries(o)
      .map(([k, v]) => `  ${JSON.stringify(k)}: ${JSON.stringify(v)},`)
      .join("\n") +
    "\n}";

  const js = [
    "// GENERATED FILE — DO NOT EDIT BY HAND. See tool/generate_css.mjs.",
    "//",
    "// Resolved token values as data. The CSS keeps DTCG aliases as var()",
    "// references so consumer overrides cascade; these are the same tokens with",
    "// every alias followed to a literal, for code that needs the value itself.",
    "",
    "/** Mode-invariant tokens: scales, semantic radius roles, tap-target minimum. */",
    `export const pulseScaleTokens = ${stringify(scale)};`,
    "",
    "/** Semantic roles + shadows, light appearance. */",
    `export const pulseLightTokens = ${stringify(light)};`,
    "",
    "/** Semantic roles + shadows, dark appearance. */",
    `export const pulseDarkTokens = ${stringify(dark)};`,
    "",
  ].join("\n");

  const names = [
    ...Object.keys(scale),
    ...Object.keys(light),
  ];
  const ts = [
    "// GENERATED FILE — DO NOT EDIT BY HAND. See tool/generate_css.mjs.",
    "",
    "/** Every custom property @willink-labs/pulse defines. */",
    "export type PulseTokenName =",
    ...names.map((n) => `  | ${JSON.stringify(n)}`),
    "  ;",
    "",
    "export declare const pulseScaleTokens: Readonly<Record<PulseTokenName, string>>;",
    "export declare const pulseLightTokens: Readonly<Record<PulseTokenName, string>>;",
    "export declare const pulseDarkTokens: Readonly<Record<PulseTokenName, string>>;",
    "",
  ].join("\n");

  // The same data as `tokens.js`, in a form something other than a JS runtime
  // can read. `test/web_parity_test.dart` is the first such consumer: it
  // resolves the var() chains in the CSS itself (so the test exercises the
  // artifact consumers actually load) and then checks this export agrees —
  // which is the only coverage the data export would otherwise have.
  const json =
    JSON.stringify({ scale, light, dark }, null, 2) + "\n";

  return { js, ts, json, count: names.length };
}

const { js, ts, json, count } = dataExports();
const files = {
  "pulse.css": fullSheet(),
  "pulse.light.css": singleModeSheet("light"),
  "pulse.dark.css": singleModeSheet("dark"),
  "tokens.js": js,
  "tokens.d.ts": ts,
  "tokens.json": json,
};

fs.mkdirSync(outDir, { recursive: true });
for (const [name, content] of Object.entries(files)) {
  fs.writeFileSync(path.join(outDir, name), content.trimEnd() + "\n");
}

const keyCount = (group) =>
  Object.keys(group).filter((k) => !k.startsWith("$")).length;
let primitiveColors = 0;
eachColorGroup(primitive.color, () => primitiveColors++);
console.log(
  `Generated ${Object.keys(files).length} files in ${outDir}\n` +
    `  ${primitiveColors} primitive colors · ` +
    `${keyCount(semantic.color)} semantic roles · ` +
    `${Object.keys(RADIUS_ROLES).length} radius roles · ` +
    `${keyCount(primitive.spacing)} spacing · ` +
    `${keyCount(primitive["font-size"])} font-size · ` +
    `${count} custom properties`,
);
