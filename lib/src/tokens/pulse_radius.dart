// Semantic corner radii.
//
// Hand-written, unlike its siblings in this directory. The DTCG contract has a
// `primitive.radius` scale but no *semantic* radius group, so there is nothing
// to generate from. This file names the roles PULSE itself paints and points
// each at a primitive — it never restates a value, so it cannot drift from the
// scale.
//
// If the SSOT gains a semantic radius group, this file is replaced by generated
// output and the member names here are the contract that generation has to
// satisfy.

import 'pulse_tokens.dart';

/// Corner radii by role — *what kind of thing* is being rounded.
///
/// [PulsePrimitives] holds the raw scale (`radiusSm` … `radiusFull`); this
/// holds the decisions made with it. Prefer these when building a surface that
/// should look like it belongs to PULSE, and reach for the primitive only when
/// you deliberately want a value the DS has no role for.
///
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     color: Theme.of(context).colorScheme.surface,
///     borderRadius: BorderRadius.circular(PulseRadius.surface),
///   ),
/// )
/// ```
///
/// Every role below is one PULSE actually paints — none was invented to round
/// out the set. That is deliberate: a role nothing uses is a guess frozen into
/// the public API.
abstract final class PulseRadius {
  const PulseRadius._();

  /// Things a finger operates: buttons, text fields, segmented controls. 8px.
  ///
  /// Painted by `PulseButton` and by every button and input theme
  /// `PulseTheme` projects.
  static const double control = PulsePrimitives.radiusMd;

  /// Surfaces that host content: cards, dialogs, snack bars, section cards.
  /// 12px.
  ///
  /// One step larger than [control] so a card reads as the container and the
  /// button as the thing inside it.
  static const double surface = PulsePrimitives.radiusLg;

  /// Surfaces anchored to a screen edge — bottom sheets. 16px.
  ///
  /// Larger than [surface] on purpose: only two corners are visible, so the
  /// same radius would read as tighter than it does on a floating card.
  static const double sheet = PulsePrimitives.radiusXl;

  /// Fully rounded: chips, drag handles, pills. Effectively a stadium.
  static const double pill = PulsePrimitives.radiusFull;

  /// Small affordances *inside* another surface — a splash on a trailing
  /// action, a swatch. 4px.
  ///
  /// Deliberately smaller than [control] so a nested touch target does not
  /// compete with the control that contains it.
  static const double inset = PulsePrimitives.radiusSm;
}
