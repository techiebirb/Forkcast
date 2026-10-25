import 'package:flutter/material.dart';

import '../theme/fc_tokens.dart';
import 'fc_icons.dart';

/// Whole numbers print without a decimal; everything else gets one place.
String fcNum(num value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) {
    return rounded.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

/// Tappable pill that toggles a filter, such as an allergen. 44px tall.
class FcFilterChip extends StatelessWidget {
  const FcFilterChip({
    super.key,
    required this.label,
    required this.onSelected,
    this.selected = false,
    this.icon,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final fg = selected ? c.accentPressed : c.textPrimary;
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? c.accent : c.borderStrong),
    );
    return Semantics(
      button: true,
      selected: selected,
      enabled: onSelected != null,
      label: label,
      excludeSemantics: true,
      onTap: onSelected == null ? null : () => onSelected!(!selected),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kFcTargetMin),
        child: Material(
          color: selected ? c.accentSoft : c.surfaceRaised,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onSelected == null ? null : () => onSelected!(!selected),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: FcSpace.s2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    FcIcon(icon!, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(label, style: FcText.label.copyWith(color: fg)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum DietTagKind {
  /// A confirmed or requested diet, like Halal. Neutral fill, accent icon.
  preference,

  /// A conflict with one of the user's allergies.
  allergy,

  /// A severe allergy. Solid danger fill.
  severe,

  /// A diet conflict, like "Not kosher". Danger tint.
  conflict,
}

/// Read-only tag for diets and allergens. Never relies on color alone: the
/// icon and the words carry the meaning.
class DietTag extends StatelessWidget {
  const DietTag({
    super.key,
    required this.label,
    this.kind = DietTagKind.preference,
    this.icon,
    this.small = true,
  });

  final String label;
  final DietTagKind kind;
  final IconData? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    Color bg;
    Color fg;
    Color border = Colors.transparent;
    IconData glyph;
    switch (kind) {
      case DietTagKind.preference:
        bg = c.surfaceSunken;
        fg = c.textPrimary;
        glyph = icon ?? FcIcons.check;
      case DietTagKind.allergy:
        bg = c.dangerSoft;
        fg = c.danger;
        border = c.danger;
        glyph = icon ?? FcIcons.warning;
      case DietTagKind.severe:
        bg = c.danger;
        fg = c.onDanger;
        glyph = icon ?? FcIcons.warning;
      case DietTagKind.conflict:
        bg = c.dangerSoft;
        fg = c.danger;
        glyph = icon ?? FcIcons.xCircle;
    }
    final style = (small ? FcText.caption : FcText.bodySm.copyWith(
      fontWeight: FontWeight.w500,
    ))
        .copyWith(
      color: fg,
      fontWeight: kind == DietTagKind.severe ? FontWeight.w600 : null,
    );
    final prefix = switch (kind) {
      DietTagKind.severe => 'Severe: ',
      _ => '',
    };
    final spoken = switch (kind) {
      DietTagKind.allergy => 'Allergy: $label',
      DietTagKind.severe => 'Severe allergy: $label',
      _ => label,
    };
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minHeight: small ? 26 : 32),
        padding: EdgeInsets.fromLTRB(
          small ? 8 : 10,
          small ? 2 : 4,
          small ? 10 : 12,
          small ? 2 : 4,
        ),
        decoration: ShapeDecoration(
          color: bg,
          shape: StadiumBorder(side: BorderSide(color: border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FcIcon(
              glyph,
              size: 16,
              color: kind == DietTagKind.preference ? c.accent : fg,
            ),
            SizedBox(width: small ? 4 : 6),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (prefix.isNotEmpty)
                      TextSpan(
                        text: prefix,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    TextSpan(text: label),
                  ],
                ),
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MatchStatus { fits, swap, no }

MatchStatus matchStatusFrom(String value) => switch (value) {
      'swap' => MatchStatus.swap,
      'no' => MatchStatus.no,
      _ => MatchStatus.fits,
    };

/// Verdict for a dish: Fits you, Fits with a swap, Doesn't fit.
class MatchBadge extends StatelessWidget {
  const MatchBadge({super.key, required this.status, this.small = true});

  final MatchStatus status;
  final bool small;

  static String labelFor(MatchStatus status) => switch (status) {
        MatchStatus.fits => 'Fits you',
        MatchStatus.swap => 'Fits with a swap',
        MatchStatus.no => "Doesn't fit",
      };

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final (bg, fg, glyph) = switch (status) {
      MatchStatus.fits => (c.successSoft, c.success, FcIcons.checkCircle),
      MatchStatus.swap => (c.warningSoft, c.warning, FcIcons.swap),
      MatchStatus.no => (c.dangerSoft, c.danger, FcIcons.xCircle),
    };
    return Semantics(
      label: labelFor(status),
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minHeight: small ? 24 : 28),
        padding: EdgeInsets.fromLTRB(small ? 6 : 8, 2, small ? 8 : 10, 2),
        decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FcIcon(glyph, size: 16, color: fg),
            SizedBox(width: small ? 4 : 6),
            Text(
              labelFor(status),
              style: (small ? FcText.caption : FcText.label).copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a dish's numbers came from: the restaurant or an AI estimate.
class ConfidenceLabel extends StatelessWidget {
  const ConfidenceLabel({super.key, required this.verified, this.date});

  /// True when the restaurant published the nutrition values.
  final bool verified;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final color = verified ? c.info : c.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FcIcon(
          verified ? FcIcons.sealCheck : FcIcons.info,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: verified
                  ? 'Verified by restaurant'
                  : 'Based on menu description',
              children: [
                if (date != null)
                  TextSpan(
                    text: ' · $date',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            style: FcText.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

enum MacroChipKind {
  /// An estimate on a food card. Sunken fill.
  estimate,

  /// One of the user's targets. Outline only.
  target,

  /// A value the menu did not list. Dashed outline.
  missing,
}

/// A macro value like "45 g protein". Always neutral: fit is shown by the
/// match badge, never by chip color.
class MacroChip extends StatelessWidget {
  const MacroChip({
    super.key,
    required this.value,
    required this.unit,
    this.kind = MacroChipKind.estimate,
    this.large = false,
  });

  /// A chip for a value that was not listed, e.g. "fat not listed".
  const MacroChip.missing(String text, {super.key})
      : value = '',
        unit = text,
        kind = MacroChipKind.missing,
        large = false;

  final String value;
  final String unit;
  final MacroChipKind kind;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final base = large ? FcText.bodySm : FcText.caption;
    final pad = large
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
    final child = Text.rich(
      TextSpan(
        children: [
          if (value.isNotEmpty)
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                fontSize: large ? 16 : null,
              ),
            ),
          if (value.isNotEmpty) const TextSpan(text: ' '),
          TextSpan(text: unit),
        ],
      ),
      style: FcText.tabular(base).copyWith(
        color: c.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
    final label = value.isEmpty ? unit : '$value $unit';
    final box = switch (kind) {
      MacroChipKind.estimate => Container(
          constraints: BoxConstraints(minHeight: large ? 36 : 28),
          padding: pad,
          decoration: ShapeDecoration(
            color: c.surfaceSunken,
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
      MacroChipKind.target => Container(
          constraints: BoxConstraints(minHeight: large ? 36 : 28),
          padding: pad,
          decoration: ShapeDecoration(
            shape: StadiumBorder(side: BorderSide(color: c.borderStrong)),
          ),
          child: child,
        ),
      MacroChipKind.missing => CustomPaint(
          foregroundPainter: _DashedPillPainter(c.borderStrong),
          child: Container(
            constraints: BoxConstraints(minHeight: large ? 36 : 28),
            padding: pad,
            child: child,
          ),
        ),
    };
    return Semantics(label: label, excludeSemantics: true, child: box);
  }
}

class _DashedPillPainter extends CustomPainter {
  _DashedPillPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular(size.height / 2),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 3), paint);
        distance += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter old) => old.color != color;
}
