# Contributing to PULSE (`pulse_theme`)

Thanks for your interest in contributing! / コントリビュート歓迎です。

PULSE is i-Willink's **mobile-first** canonical design system for Flutter. We
aim for a small, well-curated, touch-first component set rather than feature
parity with larger systems — quality over coverage.

---

## Clean-room rule (read this first)

PULSE's widgets are **clean-room implementations**.

- ✅ **Allowed:** porting / re-branding i-Willink's own MIT-licensed Flutter
  design-system code from
  [`willink-oss/willink-design-system`](https://github.com/willink-oss/willink-design-system)
  `packages/flutter_theme` (`Willink*` → `Pulse*`).
- ❌ **Forbidden:** referencing, copying, importing, or otherwise lifting code
  from **private** i-Willink app repositories — in particular
  `willink-labs/fit-ai`. You may look at a fit-ai **screenshot** to understand
  the intended look, but you must **not** read or reuse its source.

If in doubt, implement from the Material 3 + DTCG token contract, not from
existing app code.

---

## Token rule — codegen only, never hand-edit

Design tokens are **not** authored in this repo. The single source of truth is
the published `@willink-labs/tokens` DTCG JSON (`primitive.json` +
`semantic.json`). PULSE's Dart token classes are **code-generated** from that
contract.

- Do **not** hand-edit generated token files, and do not hand-mirror hex /
  radius / motion values into Dart.
- A token change starts in `@willink-labs/tokens` (the web + mobile SSOT), then
  flows into PULSE via the codegen step.
- Note: `spacing` / `typography` are not yet in the `@willink-labs/tokens`
  contract; adding them upstream is a prerequisite for the corresponding PULSE
  codegen.

---

## Component checklist (when adding a new `Pulse*` widget)

Every widget is **day-1 required** to ship all three test layers — they are part
of the Definition-of-Done, not a follow-up:

- [ ] Widget file under `lib/src/components/<component>.dart`, `Pulse*`-named.
- [ ] Reads colors from `Theme.of(context).colorScheme` (no hard-coded hex).
- [ ] **Golden test** — visual snapshot (`matchesGoldenFile`).
- [ ] **Semantics test** — accessibility tree assertion
      (`SemanticsTester` / `meetsGuideline`).
- [ ] **TextScaler test** — renders correctly under a large text scale factor
      (e.g. `MediaQuery` with `TextScaler.linear(2.0)`), no overflow.
- [ ] CHANGELOG entry in `CHANGELOG.md`.
- [ ] Clean-room confirmed: no fit-ai (or other private) source consulted.

`flutter analyze` (0 issues) + `flutter test` + `dart pub publish --dry-run`
must all pass before a PR is mergeable.

---

## Pull requests

- Branch off `main`. Branch name: `<type>/<short-description>`
  (e.g. `feat/pulse-button`, `chore/token-codegen`).
- Conventional Commits prefix: `feat:` / `fix:` / `docs:` / `chore:` /
  `refactor:` / `test:` / `ci:`.
- One logical change per PR. Rebase-merge keeps the linear history.
- Reference the related Issue (`Closes #N`) if applicable.
- Include a **Verification** section in the PR body: the commands you ran
  (`flutter analyze` / `flutter test` / `dart pub publish --dry-run`) and their
  outcomes.

---

## Release process

PULSE versions **independently** (strict SemVer 2.0). A release PR bumps
`pubspec.yaml` + `CHANGELOG.md`; a tag `vX.Y.Z` (or `pulse-vX.Y.Z`) publishes to
pub.dev via OIDC Trusted Publisher once that is configured. Stable promotion is
human-gated.

---

By contributing you agree that your contributions will be licensed under the
MIT License (see [LICENSE](LICENSE)).
