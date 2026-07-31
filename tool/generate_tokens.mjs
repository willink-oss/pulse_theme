#!/usr/bin/env node
/**
 * Generate `lib/src/tokens/pulse_tokens.dart` from the @willink-labs/tokens
 * DTCG JSON contract (primitive.json + semantic.json).
 *
 * PULSE does NOT author or hand-mirror tokens. The single source of truth is
 * the published @willink-labs/tokens package — the same contract the web side
 * (`@willink-labs/*`) consumes — so web ↔ mobile stay at parity from one SSOT.
 * This emitter is the mobile analogue of the web's
 * `packages/css-tokens/scripts/generate.mjs`; the `isLeaf` predicate,
 * leaf-walking, and alias resolution are ported/adapted from that file
 * (`flatten` → the shallow `eachLeaf`/`eachColorGroup` walkers here; both repos
 * are i-Willink MIT code).
 *
 * Inputs (default → the npm-resolved contract; the lockfile pins the version):
 *   node_modules/@willink-labs/tokens/src/primitive.json
 *   node_modules/@willink-labs/tokens/src/semantic.json
 * Override the input directory with PULSE_TOKENS_DIR (local pre-publish dev
 * against the workspace checkout). The CI parity gate runs with NO override so
 * it always reads the published contract.
 *
 * Output (default → the committed Dart file):
 *   ../lib/src/tokens/pulse_tokens.dart
 * Override with PULSE_TOKENS_OUT so the parity gate can emit to a temp path and
 * byte-compare without clobbering the committed file.
 *
 * Scope. This emits the token classes that map 1:1 from a DTCG leaf:
 *   - PulsePrimitives    color scales + radius + duration + easing
 *   - PulseSemantics     light semantic color roles (aliases folded to primitives)
 *   - PulseSemanticsDark dark semantic color roles ($extensions["willink.dark"])
 *   - PulseSpacing       spacing scale (rem → logical px doubles)
 *   - PulseFontSize      font-size scale (rem → logical px doubles)
 *   - PulseShadows       shadow scale (CSS box-shadow → List<BoxShadow>; light +
 *                        `*Dark` for leaves carrying a willink.dark extension)
 *
 * Intentionally deferred (documented, not forgotten):
 *   - semantic `motion` / `easing` role groups → wired when component animations
 *     consume role-based timing (primitive duration / easing ARE emitted now).
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const tokensDir = process.env.PULSE_TOKENS_DIR
  ? path.resolve(process.env.PULSE_TOKENS_DIR)
  : path.resolve(__dirname, "node_modules/@willink-labs/tokens/src");

const outFile = process.env.PULSE_TOKENS_OUT
  ? path.resolve(process.env.PULSE_TOKENS_OUT)
  : path.resolve(__dirname, "../lib/src/tokens/pulse_tokens.dart");

const primitive = readJson("primitive.json");
const semantic = readJson("semantic.json");

// ---------------------------------------------------------------------------
// Coverage guard.
//
// The emitter reads named groups. Anything the DTCG contract adds that is not
// named here is simply never visited — no error, no warning, and the summary
// at the bottom counts only what it already knew about. So a new token
// category arriving in a tokens MINOR (icon sizes, z-index, breakpoints…)
// would vanish silently, and the token-codegen-gate would stay green because
// the generated Dart genuinely did not change.
//
// Fail instead. A new group must be either emitted or explicitly deferred, and
// deciding which is a review conversation, not a default.
// ---------------------------------------------------------------------------
const EMITTED = {
  primitive: ["color", "radius", "duration", "easing", "spacing", "font-size", "shadow"],
  semantic: ["color"],
};
// Deferred on purpose — see the file header. Listed, not ignored, so the set of
// known-unprojected groups stays visible.
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
        `  A new DTCG group is never a no-op. Either project it into a Dart ` +
        `class and add it to EMITTED, or decide it is out of scope for now ` +
        `and add it to DEFERRED (with a note in the file header saying why).\n` +
        `  Doing nothing would drop it silently: the generated Dart would be ` +
        `unchanged, so the token-codegen-gate would pass.\n`,
    );
    process.exit(1);
  }
}

function readJson(name) {
  const p = path.join(tokensDir, name);
  if (!fs.existsSync(p)) {
    console.error(
      `\n  pulse_tokens codegen: cannot find ${name} in ${tokensDir}.\n` +
        `  Run \`npm --prefix tool ci\` first, or point PULSE_TOKENS_DIR at a\n` +
        `  checkout of @willink-labs/tokens/src.\n`,
    );
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

// --- DTCG helpers (ported from web generate.mjs) -------------------------------

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

function isAlias(value) {
  return (
    typeof value === "string" && value.startsWith("{") && value.endsWith("}")
  );
}

// --- naming -------------------------------------------------------------------

/** Capitalize the first character (digits are left untouched). */
function cap(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

/** Hyphen-compound DTCG key → camelCase Dart identifier (`fg-strong` → `fgStrong`). */
function camel(key) {
  return key
    .split("-")
    .map((part, i) => (i === 0 ? part : cap(part)))
    .join("");
}

/**
 * Bare scale member for PulseSpacing — must be a valid Dart identifier with no
 * prefix. Numeric-leading scale steps are spelled out to mirror the existing
 * `WillinkSpacing.xxl` convention: `2xl` → `xxl`, `3xl` → `xxxl`.
 */
function spacingMember(key) {
  const m = key.match(/^(\d+)xl$/);
  if (m) return "x".repeat(Number(m[1])) + "l";
  return key;
}

/** Prefixed scale member for PulseFontSize — `xs` → `fontSizeXs`, `2xl` → `fontSize2xl`. */
function fontSizeMember(key) {
  return `fontSize${cap(key)}`;
}

// --- value conversion ---------------------------------------------------------

/** `#7c3aed` → `Color(0xFF7C3AED)` (and the rare 8-digit `#rrggbbaa`). */
function colorLiteral(hex) {
  let h = hex.replace("#", "").toUpperCase();
  if (h.length === 3) {
    h = h
      .split("")
      .map((c) => c + c)
      .join("");
  }
  if (h.length === 6) return `Color(0xFF${h})`;
  if (h.length === 8) return `Color(0x${h})`;
  throw new Error(`Unsupported color literal: ${hex}`);
}

/** Format a JS number as a Dart `double` literal (integers keep a `.0`). */
function dartDouble(n) {
  const r = Math.round(n * 1e6) / 1e6;
  return Number.isInteger(r) ? `${r}.0` : `${r}`;
}

/**
 * DTCG dimension → logical pixels (Flutter's unit). The web emits rem; Flutter
 * has no rem, so we resolve against the CSS root default (1rem = 16px), the
 * same 16 the React/Tailwind side renders. `9999px` (radius.full) passes
 * through as 9999.
 */
function dimensionPx(value) {
  if (typeof value !== "string") {
    throw new Error(`Unsupported dimension: ${value}`);
  }
  if (value.endsWith("rem")) return parseFloat(value) * 16;
  if (value.endsWith("px")) return parseFloat(value);
  throw new Error(`Unsupported dimension unit: ${value}`);
}

/** `150ms` → `150` (integer milliseconds). */
function durationMs(value) {
  const m = value.match(/^(\d+)ms$/);
  if (!m) throw new Error(`Unsupported duration: ${value}`);
  return Number(m[1]);
}

/** `cubic-bezier(0.2, 0, 0, 1)` → `0.2, 0, 0, 1` (Dart `Cubic` args). */
function cubicArgs(value) {
  const m = value.match(/^cubic-bezier\(([^)]+)\)$/);
  if (!m) throw new Error(`Unsupported easing: ${value}`);
  return m[1]
    .split(",")
    .map((s) => s.trim())
    .join(", ");
}

/**
 * Resolve a semantic color value to its Dart expression.
 *   `#ffffff`            → literal `Color(0xFFFFFFFF)`
 *   `{color.neutral.900}`→ `PulsePrimitives.neutral900` (alias folded, no dup)
 *   `{color.brand}`      → `PulsePrimitives.brand600` (group shorthand → -600,
 *                          mirroring the web `--color-brand: …-600` convention)
 */
function colorExpr(value) {
  if (!isAlias(value)) return colorLiteral(value);
  const segments = value.slice(1, -1).split(".");
  if (segments[0] !== "color") {
    throw new Error(`Unsupported semantic alias (non-color): ${value}`);
  }
  const rest = segments.slice(1);
  if (rest.length === 1) rest.push("600"); // group shorthand
  if (rest.length !== 2) {
    throw new Error(`Unsupported color alias depth: ${value}`);
  }
  return `PulsePrimitives.${rest[0]}${rest[1]}`;
}

/** `rgba(124, 58, 237, 0.3)` / `rgb(...)` → Dart ARGB literal `0x4D7C3AED`. */
function rgbaToArgb(rgba) {
  const m = rgba.match(/^rgba?\(([^)]+)\)$/);
  if (!m) throw new Error(`Unsupported color: ${rgba}`);
  const parts = m[1].split(",").map((s) => s.trim());
  const [r, g, b] = parts.slice(0, 3).map(Number);
  const a = parts.length > 3 ? Number(parts[3]) : 1;
  const hex = (n) => Math.round(n).toString(16).toUpperCase().padStart(2, "0");
  return `0x${hex(a * 255)}${hex(r)}${hex(g)}${hex(b)}`;
}

/** One CSS shadow `0 4px 20px -2px rgba(..)` → `{x,y,blur,spread,argb}`. */
function parseSingleShadow(s) {
  const m = s
    .trim()
    .match(
      /^(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+(rgba?\([^)]+\))$/,
    );
  if (!m) throw new Error(`Unsupported shadow: ${s}`);
  return {
    x: Number(m[1]),
    y: Number(m[2]),
    blur: Number(m[3]),
    spread: Number(m[4]),
    argb: rgbaToArgb(m[5]),
  };
}

/** A DTCG shadow `$value` (comma-separated layers) → array of parsed shadows. */
function parseShadow(value) {
  const layers = [];
  let depth = 0;
  let cur = "";
  for (const ch of value) {
    if (ch === "(") depth++;
    else if (ch === ")") depth--;
    if (ch === "," && depth === 0) {
      layers.push(cur);
      cur = "";
    } else {
      cur += ch;
    }
  }
  if (cur.trim()) layers.push(cur);
  return layers.map(parseSingleShadow);
}


// --- emit ---------------------------------------------------------------------

const ind = "  ";
const lines = [];
const push = (s = "") => lines.push(s);

push("// GENERATED FILE — DO NOT EDIT BY HAND.");
push("//");
push("// Source of truth: @willink-labs/tokens (DTCG JSON — primitive.json +");
push("// semantic.json), the same contract the web `@willink-labs/*` packages");
push("// consume. Regenerate with `node tool/generate_tokens.mjs` after the");
push("// upstream tokens change; the version is pinned by tool/package-lock.json.");
push("//");
push("// CI (token-codegen-gate) re-runs this emitter against the published");
push("// contract and fails on any drift from this committed output — so a");
push("// hand-edit here, or a stale regenerate, breaks the build. See");
push("// CONTRIBUTING.md > \"Token rule — codegen only, never hand-edit\".");
push("");
push("import 'package:flutter/widgets.dart';");
push("");

// ---- PulsePrimitives ----
push("/// Primitive (raw) tokens — fixed across the design system; meaningless on");
push("/// their own. Consumers normally use [PulseSemantics] or the [PulseTheme]");
push("/// factories instead of referencing primitives directly.");
push("class PulsePrimitives {");
push(`${ind}const PulsePrimitives._();`);

eachColorGroup(primitive.color, (member, leaf) => {
  push(`${ind}static const Color ${member} = ${colorLiteral(leaf.$value)};`);
});

push("");
push(`${ind}// Radius (logical px).`);
eachLeaf(primitive.radius, (key, leaf) => {
  push(
    `${ind}static const double radius${cap(key)} = ${dartDouble(dimensionPx(leaf.$value))};`,
  );
});

push("");
push(`${ind}// Duration.`);
eachLeaf(primitive.duration, (key, leaf) => {
  push(
    `${ind}static const Duration duration${cap(key)} = Duration(milliseconds: ${durationMs(leaf.$value)});`,
  );
});

push("");
push(`${ind}// Easing curves.`);
eachLeaf(primitive.easing, (key, leaf) => {
  push(`${ind}static const Cubic easing${cap(key)} = Cubic(${cubicArgs(leaf.$value)});`);
});
push("}");
push("");

// ---- PulseSpacing ----
push("/// Spacing scale (logical px) — paddings / gaps / margins. Mirrors the web");
push("/// `--spacing-*` scale so layouts stay consistent across web and mobile.");
push("class PulseSpacing {");
push(`${ind}const PulseSpacing._();`);
eachLeaf(primitive.spacing, (key, leaf) => {
  push(
    `${ind}static const double ${spacingMember(key)} = ${dartDouble(dimensionPx(leaf.$value))};`,
  );
});
push("}");
push("");

// ---- PulseFontSize ----
push("/// Font-size scale (logical px) — mirrors the web `--font-size-*` type");
push("/// scale (`text-xs` … `text-3xl`). Wired into [PulseTheme]'s `TextTheme`.");
push("class PulseFontSize {");
push(`${ind}const PulseFontSize._();`);
eachLeaf(primitive["font-size"], (key, leaf) => {
  push(
    `${ind}static const double ${fontSizeMember(key)} = ${dartDouble(dimensionPx(leaf.$value))};`,
  );
});
push("}");
push("");

// ---- PulseShadows ----
// Emitted in `dart format` style (every BoxShadow multi-line with trailing
// commas) so `dart format` is a no-op on the generated file and the
// token-codegen-gate byte-diff stays stable.
function emitShadowList(member, layers) {
  push(`${ind}static const List<BoxShadow> ${member} = [`);
  for (const l of layers) {
    push(`${ind}${ind}BoxShadow(`);
    push(`${ind}${ind}${ind}color: Color(${l.argb}),`);
    push(`${ind}${ind}${ind}offset: Offset(${l.x}, ${l.y}),`);
    push(`${ind}${ind}${ind}blurRadius: ${l.blur},`);
    push(`${ind}${ind}${ind}spreadRadius: ${l.spread},`);
    push(`${ind}${ind}),`);
  }
  push(`${ind}];`);
}

push("/// Elevation / glow shadows — the primitive `shadow` scale parsed from CSS");
push("/// box-shadow into `List<BoxShadow>`. `*Dark` variants come from the");
push("/// `willink.dark` extension (ADR-0013); brand-tinted `glow` is mode-invariant.");
push("class PulseShadows {");
push(`${ind}const PulseShadows._();`);
eachLeaf(primitive.shadow, (key, leaf) => {
  emitShadowList(camel(key), parseShadow(leaf.$value));
  const dark = leaf.$extensions?.["willink.dark"];
  if (dark) emitShadowList(`${camel(key)}Dark`, parseShadow(dark.$value));
});
push("}");
push("");

// ---- PulseSemantics (light) ----
push("/// Semantic color roles (light) — named by role, not by hue. Aliases in");
push("/// the DTCG source are folded to their [PulsePrimitives] reference so a");
push("/// value is never duplicated. This is the default i-Willink mapping.");
push("class PulseSemantics {");
push(`${ind}const PulseSemantics._();`);
eachLeaf(semantic.color, (key, leaf) => {
  push(`${ind}static const Color ${camel(key)} = ${colorExpr(leaf.$value)};`);
});
push("}");
push("");

// ---- PulseSemanticsDark ----
push("/// Semantic color roles (dark) — the `$extensions[\"willink.dark\"]` flip of");
push("/// [PulseSemantics] (ADR-0013). Roles without a dark extension are");
push("/// mode-invariant and resolve to the same value as the light role.");
push("class PulseSemanticsDark {");
push(`${ind}const PulseSemanticsDark._();`);
eachLeaf(semantic.color, (key, leaf) => {
  const dark = leaf.$extensions?.["willink.dark"];
  const value = dark ? dark.$value : leaf.$value;
  push(`${ind}static const Color ${camel(key)} = ${colorExpr(value)};`);
});
push("}");
push("");

/**
 * Emit color primitives in source order. JS iterates integer-like keys
 * ("50".."950") in ascending numeric order, which matches the JSON, and
 * string group keys in insertion order — so the output is deterministic.
 */
function eachColorGroup(colorTree, fn) {
  for (const [group, shades] of Object.entries(colorTree)) {
    if (group.startsWith("$")) continue;
    eachLeaf(shades, (shade, leaf) => fn(`${group}${shade}`, leaf));
  }
}

// trimEnd + single trailing newline so the output matches `dart format`.
const output = lines.join("\n").trimEnd() + "\n";
fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, output);

const keyCount = (group) =>
  Object.keys(group).filter((k) => !k.startsWith("$")).length;
let primitiveColors = 0;
eachColorGroup(primitive.color, () => primitiveColors++);
console.log(
  `Generated ${outFile}\n` +
    `  ${primitiveColors} primitive colors · ` +
    `${keyCount(primitive.spacing)} spacing · ` +
    `${keyCount(primitive["font-size"])} font-size · ` +
    `${keyCount(primitive.shadow)} shadow`,
);
