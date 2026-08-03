// Proves the Flutter binding and the web binding of PULSE carry the same
// values.
//
// `tool/generate_tokens.mjs` emits Dart and `tool/generate_css.mjs` emits CSS
// from one DTCG contract. Two emitters reading one source is only *supposed* to
// produce two agreeing outputs — nothing in the codegen enforces it, and the
// per-binding drift gates cannot: each compares an emitter against its own
// committed output, so both could drift the same way and stay green. This test
// is the cross-check, and it is the only thing standing behind the claim in the
// README that "a color changed in the token contract lands in the Flutter app
// and the Next.js app from one regenerate".
//
// It reads `web/dist/pulse.light.css` / `pulse.dark.css` — the artifacts a
// consumer actually loads — and resolves their `var()` chains the way a browser
// would, so a broken alias is a failure here rather than a surprise in
// somebody's app.
//
// The name mapping below is hand-written on purpose. It is the contract between
// the two bindings: `--pulse-radius-control` IS `PulseRadius.control`. Deriving
// it from the token JSON instead would make the test circular — it would agree
// with whatever the emitters did.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_theme/pulse_theme.dart';

// ---------------------------------------------------------------------------
// The contract: CSS custom property → Dart constant.
//
// Mode-dependent entries carry `[light, dark]`. Every `--pulse-*` property the
// stylesheet defines must appear in exactly one of these maps — `completeness`
// below fails otherwise, so a new token cannot slip past the parity check by
// simply not being listed.
// ---------------------------------------------------------------------------

const Map<String, Color> _primitiveColors = {
  '--pulse-color-neutral-50': PulsePrimitives.neutral50,
  '--pulse-color-neutral-100': PulsePrimitives.neutral100,
  '--pulse-color-neutral-200': PulsePrimitives.neutral200,
  '--pulse-color-neutral-300': PulsePrimitives.neutral300,
  '--pulse-color-neutral-400': PulsePrimitives.neutral400,
  '--pulse-color-neutral-500': PulsePrimitives.neutral500,
  '--pulse-color-neutral-600': PulsePrimitives.neutral600,
  '--pulse-color-neutral-700': PulsePrimitives.neutral700,
  '--pulse-color-neutral-800': PulsePrimitives.neutral800,
  '--pulse-color-neutral-900': PulsePrimitives.neutral900,
  '--pulse-color-neutral-950': PulsePrimitives.neutral950,
  '--pulse-color-brand-50': PulsePrimitives.brand50,
  '--pulse-color-brand-100': PulsePrimitives.brand100,
  '--pulse-color-brand-200': PulsePrimitives.brand200,
  '--pulse-color-brand-300': PulsePrimitives.brand300,
  '--pulse-color-brand-400': PulsePrimitives.brand400,
  '--pulse-color-brand-500': PulsePrimitives.brand500,
  '--pulse-color-brand-600': PulsePrimitives.brand600,
  '--pulse-color-brand-700': PulsePrimitives.brand700,
  '--pulse-color-brand-800': PulsePrimitives.brand800,
  '--pulse-color-brand-900': PulsePrimitives.brand900,
  '--pulse-color-brand-950': PulsePrimitives.brand950,
  '--pulse-color-blue-50': PulsePrimitives.blue50,
  '--pulse-color-blue-100': PulsePrimitives.blue100,
  '--pulse-color-blue-200': PulsePrimitives.blue200,
  '--pulse-color-blue-300': PulsePrimitives.blue300,
  '--pulse-color-blue-400': PulsePrimitives.blue400,
  '--pulse-color-blue-500': PulsePrimitives.blue500,
  '--pulse-color-blue-600': PulsePrimitives.blue600,
  '--pulse-color-blue-700': PulsePrimitives.blue700,
  '--pulse-color-blue-800': PulsePrimitives.blue800,
  '--pulse-color-blue-900': PulsePrimitives.blue900,
  '--pulse-color-blue-950': PulsePrimitives.blue950,
  '--pulse-color-green-50': PulsePrimitives.green50,
  '--pulse-color-green-100': PulsePrimitives.green100,
  '--pulse-color-green-500': PulsePrimitives.green500,
  '--pulse-color-green-600': PulsePrimitives.green600,
  '--pulse-color-green-700': PulsePrimitives.green700,
  '--pulse-color-cyan-500': PulsePrimitives.cyan500,
  '--pulse-color-pink-500': PulsePrimitives.pink500,
  '--pulse-color-sky-50': PulsePrimitives.sky50,
  '--pulse-color-sky-500': PulsePrimitives.sky500,
  '--pulse-color-red-500': PulsePrimitives.red500,
  '--pulse-color-red-600': PulsePrimitives.red600,
  '--pulse-color-amber-500': PulsePrimitives.amber500,
  '--pulse-color-amber-600': PulsePrimitives.amber600,
};

/// `[light, dark]` for every semantic color role.
const Map<String, List<Color>> _semanticColors = {
  '--pulse-color-bg': [PulseSemantics.bg, PulseSemanticsDark.bg],
  '--pulse-color-fg': [PulseSemantics.fg, PulseSemanticsDark.fg],
  '--pulse-color-muted': [PulseSemantics.muted, PulseSemanticsDark.muted],
  '--pulse-color-fg-strong': [
    PulseSemantics.fgStrong,
    PulseSemanticsDark.fgStrong,
  ],
  '--pulse-color-fg-emphasis': [
    PulseSemantics.fgEmphasis,
    PulseSemanticsDark.fgEmphasis,
  ],
  '--pulse-color-fg-secondary': [
    PulseSemantics.fgSecondary,
    PulseSemanticsDark.fgSecondary,
  ],
  '--pulse-color-fg-subtle': [
    PulseSemantics.fgSubtle,
    PulseSemanticsDark.fgSubtle,
  ],
  '--pulse-color-fg-faint': [
    PulseSemantics.fgFaint,
    PulseSemanticsDark.fgFaint,
  ],
  '--pulse-color-border': [PulseSemantics.border, PulseSemanticsDark.border],
  '--pulse-color-surface-subtle': [
    PulseSemantics.surfaceSubtle,
    PulseSemanticsDark.surfaceSubtle,
  ],
  '--pulse-color-surface-muted': [
    PulseSemantics.surfaceMuted,
    PulseSemanticsDark.surfaceMuted,
  ],
  '--pulse-color-track': [PulseSemantics.track, PulseSemanticsDark.track],
  '--pulse-color-surface-inverted': [
    PulseSemantics.surfaceInverted,
    PulseSemanticsDark.surfaceInverted,
  ],
  '--pulse-color-surface-inverted-fg': [
    PulseSemantics.surfaceInvertedFg,
    PulseSemanticsDark.surfaceInvertedFg,
  ],
  '--pulse-color-ring': [PulseSemantics.ring, PulseSemanticsDark.ring],
  '--pulse-color-brand': [PulseSemantics.brand, PulseSemanticsDark.brand],
  '--pulse-color-brand-fg': [
    PulseSemantics.brandFg,
    PulseSemanticsDark.brandFg,
  ],
  '--pulse-color-brand-glow': [
    PulseSemantics.brandGlow,
    PulseSemanticsDark.brandGlow,
  ],
  '--pulse-color-brand-hover': [
    PulseSemantics.brandHover,
    PulseSemanticsDark.brandHover,
  ],
  '--pulse-color-brand-active': [
    PulseSemantics.brandActive,
    PulseSemanticsDark.brandActive,
  ],
  '--pulse-color-brand-soft': [
    PulseSemantics.brandSoft,
    PulseSemanticsDark.brandSoft,
  ],
  '--pulse-color-brand-soft-fg': [
    PulseSemantics.brandSoftFg,
    PulseSemanticsDark.brandSoftFg,
  ],
  '--pulse-color-accent-cyan': [
    PulseSemantics.accentCyan,
    PulseSemanticsDark.accentCyan,
  ],
  '--pulse-color-accent-pink': [
    PulseSemantics.accentPink,
    PulseSemanticsDark.accentPink,
  ],
  '--pulse-color-success': [PulseSemantics.success, PulseSemanticsDark.success],
  '--pulse-color-warning': [PulseSemantics.warning, PulseSemanticsDark.warning],
  '--pulse-color-danger': [PulseSemantics.danger, PulseSemanticsDark.danger],
};

/// Dimensions, in logical pixels. The CSS carries `rem`; the Dart side resolved
/// it against 16 at generation time, and [_dimensionPx] applies the same 16 —
/// the one conversion constant the two bindings have to agree on.
const Map<String, double> _dimensions = {
  '--pulse-radius-sm': PulsePrimitives.radiusSm,
  '--pulse-radius-md': PulsePrimitives.radiusMd,
  '--pulse-radius-lg': PulsePrimitives.radiusLg,
  '--pulse-radius-xl': PulsePrimitives.radiusXl,
  '--pulse-radius-full': PulsePrimitives.radiusFull,
  // The semantic radius layer — hand-written on BOTH sides (the contract has no
  // semantic radius group to generate from), which makes these five the entries
  // most likely to drift and the reason this test exists at all.
  '--pulse-radius-control': PulseRadius.control,
  '--pulse-radius-surface': PulseRadius.surface,
  '--pulse-radius-sheet': PulseRadius.sheet,
  '--pulse-radius-pill': PulseRadius.pill,
  '--pulse-radius-inset': PulseRadius.inset,
  '--pulse-space-xs': PulseSpacing.xs,
  '--pulse-space-sm': PulseSpacing.sm,
  '--pulse-space-md': PulseSpacing.md,
  '--pulse-space-lg': PulseSpacing.lg,
  '--pulse-space-xl': PulseSpacing.xl,
  '--pulse-space-2xl': PulseSpacing.xxl,
  '--pulse-text-xs': PulseFontSize.fontSizeXs,
  '--pulse-text-sm': PulseFontSize.fontSizeSm,
  '--pulse-text-base': PulseFontSize.fontSizeBase,
  '--pulse-text-lg': PulseFontSize.fontSizeLg,
  '--pulse-text-xl': PulseFontSize.fontSizeXl,
  '--pulse-text-2xl': PulseFontSize.fontSize2xl,
  '--pulse-text-3xl': PulseFontSize.fontSize3xl,
  // The mobile-first contract. Dart spells this number inline at each
  // `minWidth` / `minHeight` (pulse_button.dart, pulse_section_card.dart)
  // rather than in a named constant, so this row is what keeps the CSS from
  // quietly promising a target size the widgets do not honour.
  '--pulse-tap-target-min': _tapTargetMin,
};

/// The 48dp minimum PULSE components are built to. Kept here, next to the
/// assertion that uses it, until the Dart side names it in its own API.
const double _tapTargetMin = 48;

const Map<String, Duration> _durations = {
  '--pulse-duration-fast': PulsePrimitives.durationFast,
  '--pulse-duration-base': PulsePrimitives.durationBase,
  '--pulse-duration-slow': PulsePrimitives.durationSlow,
};

const Map<String, Cubic> _easings = {
  '--pulse-easing-standard': PulsePrimitives.easingStandard,
  '--pulse-easing-emphasized': PulsePrimitives.easingEmphasized,
};

/// `[light, dark]`. `glow` is brand-tinted and mode-invariant — the contract
/// gives it no dark extension, so the Dart emitter never wrote a `glowDark`
/// and both entries point at the same list.
const Map<String, List<List<BoxShadow>>> _shadows = {
  '--pulse-shadow-soft': [PulseShadows.soft, PulseShadows.softDark],
  '--pulse-shadow-md': [PulseShadows.md, PulseShadows.mdDark],
  '--pulse-shadow-glow': [PulseShadows.glow, PulseShadows.glow],
};

// ---------------------------------------------------------------------------

void main() {
  final root = _repoRoot();
  final light = _CssRoot.parse(
    File('${root.path}/web/dist/pulse.light.css').readAsStringSync(),
  );
  final dark = _CssRoot.parse(
    File('${root.path}/web/dist/pulse.dark.css').readAsStringSync(),
  );

  group('web ↔ Flutter token parity', () {
    test('primitive colors', () {
      // Primitives are mode-invariant, so both sheets must carry them and both
      // must match. Checking only one would let the dark build drift.
      for (final sheet in [light, dark]) {
        _primitiveColors.forEach((name, expected) {
          expect(
            sheet.color(name),
            _hex(expected),
            reason: '$name disagrees with the Dart primitive',
          );
        });
      }
    });

    test('semantic color roles', () {
      _semanticColors.forEach((name, modes) {
        expect(
          light.color(name),
          _hex(modes[0]),
          reason: '$name (light) disagrees with PulseSemantics',
        );
        expect(
          dark.color(name),
          _hex(modes[1]),
          reason: '$name (dark) disagrees with PulseSemanticsDark',
        );
      });
    });

    test('dimensions — radius, spacing, type scale, tap target', () {
      for (final sheet in [light, dark]) {
        _dimensions.forEach((name, expected) {
          expect(
            _dimensionPx(sheet.resolve(name)),
            expected,
            reason: '$name disagrees with the Dart constant',
          );
        });
      }
    });

    test('durations and easing curves', () {
      _durations.forEach((name, expected) {
        expect(_durationMs(light.resolve(name)), expected.inMilliseconds);
      });
      _easings.forEach((name, expected) {
        final actual = _cubic(light.resolve(name));
        expect(
          [actual.a, actual.b, actual.c, actual.d],
          [expected.a, expected.b, expected.c, expected.d],
          reason: '$name disagrees with the Dart curve',
        );
      });
    });

    test('shadows', () {
      _shadows.forEach((name, modes) {
        expect(
          _shadowLayers(light.resolve(name)),
          _describeShadows(modes[0]),
          reason: '$name (light) disagrees with PulseShadows',
        );
        expect(
          _shadowLayers(dark.resolve(name)),
          _describeShadows(modes[1]),
          reason: '$name (dark) disagrees with PulseShadows',
        );
      });
    });

    test('completeness — every property in the CSS is covered above', () {
      // Without this, a token added to the contract would appear in the
      // stylesheet, be checked by nothing, and the suite would still be green.
      final claimed = <String>{
        ..._primitiveColors.keys,
        ..._semanticColors.keys,
        ..._dimensions.keys,
        ..._durations.keys,
        ..._easings.keys,
        ..._shadows.keys,
      };
      for (final sheet in [light, dark]) {
        expect(
          sheet.names.difference(claimed),
          isEmpty,
          reason:
              'The stylesheet defines properties this test does not check. '
              'Map each to its Dart constant above, or explain in a comment '
              'why the Flutter binding deliberately has no counterpart.',
        );
      }
      expect(
        claimed.difference(light.names),
        isEmpty,
        reason: 'This test claims properties the stylesheet does not define.',
      );
    });
  });

  group('web artifact self-consistency', () {
    test('pulse.css carries the same values as the single-mode builds', () {
      // Three files, one source — but they are three separate emissions, and a
      // consumer picks exactly one. If they disagreed, an app would look
      // different for choosing the dark-only build over the attribute.
      final full = File('${root.path}/web/dist/pulse.css').readAsStringSync();
      final base = _CssRoot.parse(full, selector: ':root');
      final darkBlock = _CssRoot.parse(
        full,
        selector: ':root[data-pulse-theme="dark"]',
        // The attribute block redeclares only what flips; the scales it
        // inherits from `:root` are carried over so var() chains resolve.
        inherit: base,
      );
      final lightBlock = _CssRoot.parse(
        full,
        selector: ':root[data-pulse-theme="light"]',
        inherit: base,
      );

      for (final name in light.names) {
        expect(base.resolve(name), light.resolve(name), reason: '$name (base)');
        expect(
          lightBlock.resolve(name),
          light.resolve(name),
          reason: '$name (data-pulse-theme="light")',
        );
      }
      for (final name in _semanticColors.keys.followedBy(_shadows.keys)) {
        expect(
          darkBlock.resolve(name),
          dark.resolve(name),
          reason: '$name (data-pulse-theme="dark")',
        );
      }
    });

    test('tokens.json agrees with the stylesheets', () {
      // The data export resolves aliases at generation time while the CSS keeps
      // them as var(). Both walks are supposed to reach the same value; this is
      // the only thing that checks the resolved one.
      final data =
          jsonDecode(
                File('${root.path}/web/dist/tokens.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final scale = (data['scale'] as Map).cast<String, String>();
      final lightData = (data['light'] as Map).cast<String, String>();
      final darkData = (data['dark'] as Map).cast<String, String>();

      scale.forEach((name, value) {
        expect(light.resolve(name), value, reason: 'tokens.json scale $name');
      });
      lightData.forEach((name, value) {
        expect(light.resolve(name), value, reason: 'tokens.json light $name');
      });
      darkData.forEach((name, value) {
        expect(dark.resolve(name), value, reason: 'tokens.json dark $name');
      });
    });
  });
}

// --- CSS reading --------------------------------------------------------------

/// The declarations of one `:root`-ish block, with `var()` resolution.
class _CssRoot {
  _CssRoot(this._declarations, this._inherit);

  final Map<String, String> _declarations;
  final _CssRoot? _inherit;

  /// Parse the block introduced by [selector]. Matching is on the selector at
  /// the start of a line, which is enough for a generated file and keeps this
  /// from becoming a CSS parser.
  static _CssRoot parse(
    String css, {
    String selector = ':root',
    _CssRoot? inherit,
  }) {
    final start = RegExp(
      '^${RegExp.escape(selector)}\\s*\\{',
      multiLine: true,
    ).firstMatch(css);
    if (start == null) {
      throw StateError('No `$selector {` block in the stylesheet');
    }
    final end = css.indexOf('\n}', start.end);
    if (end == -1) throw StateError('Unterminated `$selector` block');

    final declarations = <String, String>{};
    for (final line in css.substring(start.end, end).split('\n')) {
      final m = RegExp(r'^\s*(--[\w-]+)\s*:\s*(.+?);\s*$').firstMatch(line);
      if (m != null) declarations[m.group(1)!] = m.group(2)!.trim();
    }
    return _CssRoot(declarations, inherit);
  }

  Set<String> get names => _declarations.keys.toSet();

  String? _raw(String name) => _declarations[name] ?? _inherit?._raw(name);

  /// Follow `var(--x)` references the way the cascade would.
  String resolve(String name, [Set<String>? seen]) {
    final visited = seen ?? <String>{};
    if (!visited.add(name)) {
      throw StateError('Cyclic var() reference at $name');
    }
    final value = _raw(name);
    if (value == null) throw StateError('$name is not defined');
    final m = RegExp(r'^var\((--[\w-]+)\)$').firstMatch(value);
    return m == null ? value : resolve(m.group(1)!, visited);
  }

  String color(String name) => resolve(name);
}

/// The repo root, found from the test's own location so the test does not
/// depend on the working directory `flutter test` was invoked from.
Directory _repoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find the package root from ${dir.path}');
    }
    dir = parent;
  }
  return dir;
}

// --- value conversion ---------------------------------------------------------

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// The same 1rem = 16px the Dart emitter applied. `9999px` passes through.
double _dimensionPx(String value) {
  if (value.endsWith('rem')) {
    return double.parse(value.substring(0, value.length - 3)) * 16;
  }
  if (value.endsWith('px')) {
    return double.parse(value.substring(0, value.length - 2));
  }
  throw ArgumentError('Unsupported dimension: $value');
}

int _durationMs(String value) {
  final m = RegExp(r'^(\d+)ms$').firstMatch(value);
  if (m == null) throw ArgumentError('Unsupported duration: $value');
  return int.parse(m.group(1)!);
}

Cubic _cubic(String value) {
  final m = RegExp(r'^cubic-bezier\(([^)]+)\)$').firstMatch(value);
  if (m == null) throw ArgumentError('Unsupported easing: $value');
  final a = m.group(1)!.split(',').map((s) => double.parse(s.trim())).toList();
  return Cubic(a[0], a[1], a[2], a[3]);
}

/// A CSS box-shadow, normalised to the same strings [_describeShadows] produces
/// from Dart — comparing the descriptions gives a readable diff on failure
/// instead of "two lists are not equal".
List<String> _shadowLayers(String value) {
  final layers = <String>[];
  var depth = 0;
  final buffer = StringBuffer();
  for (final ch in value.split('')) {
    if (ch == '(') depth++;
    if (ch == ')') depth--;
    if (ch == ',' && depth == 0) {
      layers.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  if (buffer.toString().trim().isNotEmpty) layers.add(buffer.toString());

  return layers.map((layer) {
    final m = RegExp(
      // The unit is optional because CSS writes a bare `0` for a zero offset —
      // `0 4px 20px -2px rgba(...)` — and the token contract does exactly that.
      r'^(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+(-?[\d.]+)(?:px)?\s+'
      r'(-?[\d.]+)(?:px)?\s+rgba?\(([^)]+)\)$',
    ).firstMatch(layer.trim());
    if (m == null) throw ArgumentError('Unsupported shadow layer: $layer');
    final parts = m.group(5)!.split(',').map((s) => s.trim()).toList();
    final alpha = parts.length > 3 ? double.parse(parts[3]) : 1.0;
    final rgb =
        parts
            .take(3)
            .map((s) => int.parse(s).toRadixString(16).padLeft(2, '0'))
            .join();
    return '${m.group(1)},${m.group(2)} blur ${m.group(3)} '
        'spread ${m.group(4)} #$rgb @${alpha.toStringAsFixed(2)}';
  }).toList();
}

List<String> _describeShadows(List<BoxShadow> shadows) =>
    shadows.map((s) {
      final argb = s.color.toARGB32();
      final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
      final alpha = ((argb >> 24) & 0xFF) / 255;
      return '${_num(s.offset.dx)},${_num(s.offset.dy)} blur ${_num(s.blurRadius)} '
          'spread ${_num(s.spreadRadius)} #$rgb @${alpha.toStringAsFixed(2)}';
    }).toList();

/// `4.0` → `4`, so a Dart double and a CSS length describe the same layer.
String _num(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toString();
