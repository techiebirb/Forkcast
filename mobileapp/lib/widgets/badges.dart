import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// "Fits you" / "Fits with a swap" / "Doesn't fit". Always icon + words.
class MatchBadge extends StatelessWidget {
  const MatchBadge({super.key, required this.status, this.small = true});

  /// 'fits', 'swap' or 'no'.
  final String status;
  final bool small;

  static String labelFor(String status) => switch (status) {
        'fits' => 'Fits you',
        'swap' => 'Fits with a swap',
        _ => "Doesn't fit",
      };

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final (IconData icon, Color fg, Color bg) = switch (status) {
      'fits' => (PhosphorIconsRegular.checkCircle, c.success, c.successSoft),
      'swap' => (PhosphorIconsRegular.swap, c.warning, c.warningSoft),
      _ => (PhosphorIconsRegular.xCircle, c.danger, c.dangerSoft),
    };
    final style = (small ? context.text.labelMedium : context.text.labelLarge)!
        .copyWith(color: fg);
    return Container(
      constraints: BoxConstraints(minHeight: small ? 24 : 28),
      padding: EdgeInsets.fromLTRB(small ? 6 : 8, 2, small ? 8 : 10, 2),
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 16 : 18, color: fg),
          SizedBox(width: small ? 4 : 6),
          Flexible(child: Text(labelFor(status), style: style)),
        ],
      ),
    );
  }
}

/// Neutral nutrition chip: bold value, secondary unit. Never red/green.
class MacroChip extends StatelessWidget {
  const MacroChip({
    super.key,
    required this.value,
    required this.unit,
    this.target = false,
    this.large = false,
  }) : missing = null;

  /// Dashed chip for a value the menu does not list ("fat not listed").
  const MacroChip.missing(String label, {super.key})
      : missing = label,
        value = '',
        unit = '',
        target = false,
        large = false;

  final String value;
  final String unit;
  final bool target;
  final bool large;
  final String? missing;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final base = (large ? context.text.bodyMedium : context.text.bodySmall)!
        .copyWith(color: c.textSecondary, fontWeight: FontWeight.w500)
        .tabular;
    final child = missing != null
        ? Text(missing!, style: base)
        : Text.rich(
            TextSpan(children: [
              TextSpan(
                text: value,
                style: base.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: large ? 16 : null,
                ),
              ),
              TextSpan(text: ' $unit'),
            ]),
            style: base,
          );
    final padding = EdgeInsets.symmetric(
      horizontal: large ? 14 : 10,
      vertical: large ? 6 : 4,
    );
    if (missing != null) {
      return CustomPaint(
        painter: _DashedPillPainter(c.borderStrong),
        child: Padding(padding: padding, child: child),
      );
    }
    return Container(
      constraints: BoxConstraints(minHeight: large ? 36 : 28),
      padding: padding,
      decoration: ShapeDecoration(
        color: target ? Colors.transparent : c.surfaceSunken,
        shape: StadiumBorder(
          side: BorderSide(
            color: target ? c.borderStrong : Colors.transparent,
          ),
        ),
      ),
      child: child,
    );
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
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter old) => old.color != color;
}

enum TagKind { neutral, preference, allergy, severe }

/// Tags for preferences ("Halal"), allergies ("No peanuts") and warnings.
class FcTag extends StatelessWidget {
  const FcTag({
    super.key,
    required this.label,
    this.icon,
    this.kind = TagKind.neutral,
    this.small = true,
  });

  /// Allergy tag with the icon the design system picks for [allergen].
  factory FcTag.allergy(String label, {String? allergen, bool warn = false}) =>
      FcTag(
        label: label,
        kind: TagKind.allergy,
        icon: warn
            ? PhosphorIconsRegular.warning
            : allergenIcon(allergen ?? label),
      );

  final String label;
  final IconData? icon;
  final TagKind kind;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final (Color bg, Color fg, Color border, Color iconColor) = switch (kind) {
      TagKind.allergy => (c.dangerSoft, c.danger, c.danger, c.danger),
      TagKind.severe => (c.danger, c.onDanger, c.danger, c.onDanger),
      TagKind.preference => (
          c.surfaceSunken,
          c.textPrimary,
          Colors.transparent,
          c.accent
        ),
      TagKind.neutral => (
          c.surfaceSunken,
          c.textPrimary,
          Colors.transparent,
          c.textSecondary
        ),
    };
    final style = (small ? context.text.bodySmall : context.text.bodyMedium)!
        .copyWith(
          color: fg,
          fontWeight: kind == TagKind.severe ? FontWeight.w600 : FontWeight.w500,
        )
        .tabular;
    return Semantics(
      label: kind == TagKind.allergy ? 'Allergy: $label' : null,
      excludeSemantics: kind == TagKind.allergy,
      child: Container(
        constraints: BoxConstraints(minHeight: small ? 26 : 32),
        padding: EdgeInsets.fromLTRB(small ? 8 : 10, 2, small ? 10 : 12, 2),
        decoration: ShapeDecoration(
          color: bg,
          shape: StadiumBorder(side: BorderSide(color: border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: small ? 16 : 18, color: iconColor),
              SizedBox(width: small ? 4 : 6),
            ],
            Flexible(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}

/// Icons the design system pairs with common allergens.
IconData allergenIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('nut') || n.contains('peanut')) return PhosphorIconsRegular.acorn;
  if (n.contains('shellfish') || n.contains('shrimp') || n.contains('prawn')) {
    return PhosphorIconsRegular.shrimp;
  }
  if (n.contains('fish')) return PhosphorIconsRegular.fish;
  if (n.contains('egg')) return PhosphorIconsRegular.egg;
  if (n.contains('dairy') || n.contains('milk') || n.contains('lactose')) {
    return PhosphorIconsRegular.cheese;
  }
  if (n.contains('gluten') || n.contains('wheat')) {
    return PhosphorIconsRegular.bread;
  }
  return PhosphorIconsRegular.warning;
}

/// "Verified by restaurant" or "Based on menu description".
class ConfidenceLabel extends StatelessWidget {
  const ConfidenceLabel({super.key, required this.source});

  /// 'restaurant' or 'description'.
  final String source;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final verified = source == 'restaurant';
    final color = verified ? c.info : c.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified ? PhosphorIconsRegular.sealCheck : PhosphorIconsRegular.fileText,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            verified ? 'Verified by restaurant' : 'Based on menu description',
            style: context.text.bodySmall!.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// "$$" with the unused "$$" greyed out.
class PriceLevel extends StatelessWidget {
  const PriceLevel({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final l = level.clamp(1, 4);
    final style = context.text.bodyMedium!.tabular.copyWith(letterSpacing: 0.3);
    return Semantics(
      label: 'Price $l of 4',
      excludeSemantics: true,
      child: Text.rich(TextSpan(children: [
        TextSpan(
          text: r'$' * l,
          style: style.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(
          text: r'$' * (4 - l),
          style: style.copyWith(color: c.textDisabled),
        ),
      ])),
    );
  }
}

/// Metadata line: "Indian · $$ · 11 min · 0.5 mi". Null parts are skipped.
class MetaLine extends StatelessWidget {
  const MetaLine({
    super.key,
    this.cuisine,
    this.priceLevel,
    this.walkMinutes,
    this.distanceMiles,
    this.extra = const [],
  });

  final String? cuisine;
  final int? priceLevel;
  final int? walkMinutes;
  final double? distanceMiles;
  final List<String> extra;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final style = context.text.bodyMedium!.tabular.copyWith(
      color: c.textSecondary,
    );
    final parts = <Widget>[
      if (cuisine != null && cuisine!.isNotEmpty) Text(cuisine!, style: style),
      if (priceLevel != null) PriceLevel(level: priceLevel!),
      if (walkMinutes != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(PhosphorIconsRegular.personSimpleWalk,
              size: 16, color: c.textSecondary),
          const SizedBox(width: 2),
          Text('$walkMinutes min', style: style),
        ]),
      if (distanceMiles != null)
        Text('${distanceMiles!.toStringAsFixed(1)} mi', style: style),
      for (final e in extra) Text(e, style: style),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) ExcludeSemantics(child: Text('·', style: style)),
          parts[i],
        ],
      ],
    );
  }
}

/// Small secondary hint with a leading icon.
class FcHint extends StatelessWidget {
  const FcHint({
    super.key,
    required this.text,
    this.icon = PhosphorIconsRegular.info,
    this.color,
  });

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.fc.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: FcSpace.s2),
        ],
        Expanded(
          child: Text(text, style: context.text.bodySmall!.copyWith(color: fg)),
        ),
      ],
    );
  }
}
