# Security policy

## Reporting a vulnerability

Please report security issues privately rather than opening a public issue:

- **Preferred:** [open a private security advisory](https://github.com/willink-oss/pulse_theme/security/advisories/new)
- **Email:** yutaro_shirai@i-willink.com

Please include the affected version, what you observed, and how to reproduce
it. We aim to acknowledge within five business days.

## Supported versions

`pulse_theme` is pre-1.0. Fixes land on the latest published version only —
there are no long-term support branches. Once `1.0.0` ships, the supported
range will be stated here.

## Scope

`pulse_theme` is a Flutter UI package with no runtime dependency beyond the
Flutter SDK itself, and it performs no I/O: no network calls, no file access,
no platform channels. The realistic security surface is therefore not the
rendered widgets but the **supply chain** — what ends up inside the archive
published to pub.dev, and what can push to it.

Things we consider in scope:

- Anything that could place unintended content into the published archive.
- Weaknesses in the release path (see below).
- A dependency of the package or of its build tooling.

Things that are *not* vulnerabilities: visual defects, accessibility gaps, and
API design complaints. Those are ordinary issues — please file them normally.

## How releases are protected

- **Publishing is tag-driven only.** Manual publishing is disabled on pub.dev,
  so `dart pub publish` is rejected by the server. The only path to a release
  is a `v{{version}}` tag on this repository, which authenticates to pub.dev as
  a Trusted Publisher via GitHub Actions OIDC — no long-lived credential exists
  to steal.
- **The publish job checks that the tag and `pubspec.yaml` agree**, and refuses
  to republish a version already on pub.dev.
- **Every third-party action is pinned by commit SHA**, not by a mutable tag.
  A tag can be repointed by whoever owns the action; a SHA cannot. This matters
  most in the publish workflow, which is the job holding the OIDC identity that
  can push to pub.dev. Dependabot keeps those pins moving deliberately.
- **The token pipeline is verified, not trusted.** `lib/src/tokens/` is
  generated from the published `@willink-labs/tokens` contract, pinned exactly
  by `tool/package-lock.json`, and CI regenerates and diffs it on every change.
