# ADR-0001: PULSE — mobile-first design system architecture

- **Status:** Accepted
- **Date:** 2026-06-25
- **Repo:** `willink-oss/pulse_theme`
- **Upstream context:** i-Willink-crew **ADR-018** (org-level decision to make
  PULSE the mobile-first canonical DS).

## Context

i-Willink ships both web and mobile UI. The web design system
(`willink-oss/willink-design-system` — `@willink-labs/*` npm: React + Tailwind
preset) is mature and stays as-is. The mobile side has been served by
`willink_theme` (the `flutter_theme` package, `Willink*` symbols), which (a) was
web-derived rather than designed mobile-first and (b) **hand-mirrored** token
values into Dart, which can silently drift from the canonical tokens.

We want a mobile-first canonical DS that keeps strict web↔mobile parity from a
single token source.

## Decision

1. **Mobile-first canonical DS.** PULSE (`pulse_theme`, `Pulse*` symbols) is the
   new canonical Flutter design system, designed touch-first. The web DS is
   **not** renamed and keeps shipping the `@willink-labs/*` packages.

2. **Single token SSOT = `@willink-labs/tokens` (DTCG JSON).** Tokens are not
   duplicated into PULSE. The published `@willink-labs/tokens` `primitive.json`
   + `semantic.json` remain the single source of truth that **both** web and
   mobile read.

3. **Tokens → Dart by codegen, not by hand.** PULSE's Dart token classes are
   **code-generated** from the published DTCG JSON. This upgrades the previous
   "hand-written mirror" (drift-prone) into a "public-token-contract → codegen"
   pipeline. Generated files are never hand-edited.
   - Current contract: `primitive.json` = `color / radius / duration / easing /
     shadow`; `semantic.json` = `color / motion / easing`. `spacing` and
     `typography` are **absent** and must be added to `@willink-labs/tokens`
     before the corresponding PULSE codegen can exist.

4. **Clean-room provenance.** Component widgets are clean-room implementations.
   Porting i-Willink's own **MIT-licensed** `flutter_theme` code
   (`Willink*` → `Pulse*`) is allowed; lifting code from **private** app repos
   — notably `willink-labs/fit-ai` — is **forbidden** (screenshot reference
   only). See `CONTRIBUTING.md`.

5. **Independent versioning.** PULSE follows strict SemVer 2.0 and versions
   independently of the `@willink-labs/*` npm group and of the legacy
   `willink_theme` package. Pre-1.0 (`0.x`) is the foundation phase; the public
   API freezes at `1.0.0`.

6. **Legacy retirement, non-breaking.** `willink_theme` is **discontinued**.
   Its only real consumer, **clubhouse** (`willink_theme ^1.5.0`, two
   `lib/theme` files), is on a Phase 0 release track and migrates to PULSE
   **non-breakingly after** that Phase 0 ship. fit-ai (mobile) already left
   `willink_theme` and is non-contact.

## Consequences

- **+** One token SSOT for web and mobile; a token change is made once and
  codegen propagates it — no manual Dart mirror to drift.
- **+** Mobile-first widget design (golden + semantics + textScaler tests are
  day-1 DoD per `CONTRIBUTING.md`).
- **+** Clean MIT provenance; no private (fit-ai) code in an OSS package.
- **−** Requires upstreaming `spacing` / `typography` into `@willink-labs/tokens`
  before those PULSE tokens can be generated.
- **−** Two Flutter packages coexist briefly (`willink_theme` discontinued but
  live for clubhouse) until the post-Phase-0 migration completes.

## Stage 0 scope (this cut)

Package skeleton + `PulseTheme.light()` Material 3 stub + CI flutter-gate +
this ADR. No components and no token codegen yet — those are Stage 1+.
