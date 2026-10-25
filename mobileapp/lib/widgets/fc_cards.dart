import 'package:flutter/material.dart';

import '../models.dart';
import '../theme/fc_tokens.dart';
import 'fc_button.dart';
import 'fc_chips.dart';
import 'fc_icons.dart';
import 'fc_surfaces.dart';
import 'fc_toggles.dart';

/// Which look the macro targets take inside [PrefSummaryCard].
enum PrefSummaryStyle {
  /// Small neutral tags ("650 cal"), for the restaurant search.
  tags,

  /// Outlined target chips, for checking a restaurant against macros.
  targets,
}

/// "Matching your preferences" / "Checking against": a read-only recap of the
/// user's targets, diets and allergies with an Edit link.
class PrefSummaryCard extends StatelessWidget {
  const PrefSummaryCard({
    super.key,
    required this.preferences,
    required this.title,
    required this.onEdit,
    this.style = PrefSummaryStyle.tags,
  });

  final UserPreferences preferences;
  final String title;
  final VoidCallback onEdit;
  final PrefSummaryStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final p = preferences;
    final macros = <(double?, String)>[
      (p.calories, 'cal'),
      (p.proteins, 'protein'),
      (p.carbs, 'carbs'),
      (p.fat, 'fat'),
      (p.fiber, 'fiber'),
      (p.sugar, 'sugar'),
    ];
    final chips = <Widget>[];
    for (final (value, name) in macros) {
      if (value == null) {
        continue;
      }
      final text = name == 'cal' ? fcNum(value) : '${fcNum(value)} g';
      if (style == PrefSummaryStyle.targets) {
        chips.add(
          MacroChip(value: text, unit: name, kind: MacroChipKind.target),
        );
      } else {
        chips.add(_PlainTag('$text $name'));
      }
    }
    if (p.halal) {
      chips.add(const DietTag(label: 'Halal'));
    }
    if (p.kosher) {
      chips.add(const DietTag(label: 'Kosher'));
    }
    for (final allergy in p.allergies) {
      chips.add(DietTag(label: 'No $allergy', kind: DietTagKind.allergy));
    }

    return FcCard(
      padding: const EdgeInsets.fromLTRB(
        FcSpace.s4,
        FcSpace.s2,
        FcSpace.s2,
        FcSpace.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: FcText.caption.copyWith(color: c.textSecondary),
                ),
              ),
              FcButton(
                label: 'Edit',
                variant: FcButtonVariant.ghost,
                onPressed: onEdit,
              ),
            ],
          ),
          if (chips.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: FcSpace.s2),
              child: Text(
                'No targets set. Any restaurant can match.',
                style: FcText.bodySm.copyWith(color: c.textSecondary),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: FcSpace.s2),
              child: Wrap(spacing: FcSpace.s1, runSpacing: FcSpace.s1, children: chips),
            ),
        ],
      ),
    );
  }
}

class _PlainTag extends StatelessWidget {
  const _PlainTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: ShapeDecoration(
        color: c.surfaceSunken,
        shape: const StadiumBorder(),
      ),
      child: Text(
        text,
        style: FcText.tabular(FcText.caption).copyWith(color: c.textPrimary),
      ),
    );
  }
}

/// Meta line for a restaurant: cuisine · $$ · walk time · distance. Parts
/// without data are left out.
class RestaurantMeta extends StatelessWidget {
  const RestaurantMeta({super.key, required this.restaurant});

  final RestaurantRecommendation restaurant;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final r = restaurant;
    final parts = <Widget>[];
    if (r.cuisine.isNotEmpty) {
      parts.add(Text(r.cuisine));
    }
    final level = r.priceLevel;
    if (level != null && level >= 1 && level <= 4) {
      parts.add(
        Semantics(
          label: 'Price $level of 4',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '\$' * level,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '\$' * (4 - level),
                  style: TextStyle(color: c.textDisabled),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (r.walkMinutes != null) {
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FcIcon(FcIcons.walk, size: 16, color: c.textSecondary),
            const SizedBox(width: 2),
            Text('${r.walkMinutes} min'),
          ],
        ),
      );
    }
    if (r.distanceMiles != null) {
      parts.add(Text('${fcNum(r.distanceMiles!)} mi'));
    }
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }
    return DefaultTextStyle(
      style: FcText.tabular(FcText.bodySm).copyWith(color: c.textSecondary),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: FcSpace.s1,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const Text('·'),
            parts[i],
          ],
        ],
      ),
    );
  }
}

/// A restaurant suggestion: thumb, name, meta, why it matches, and the check
/// button. Suggestions never show menus or macros.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.favorite,
    required this.onFavorite,
    required this.onCheck,
    this.showReason = true,
    this.showAddress = false,
    this.checking = false,
  });

  final RestaurantRecommendation restaurant;
  final bool favorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onCheck;
  final bool showReason;

  /// Show the street address with a pin (used on the Saved screen).
  final bool showAddress;

  /// The check for this card is in flight.
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final r = restaurant;
    final icon = r.name.hashCode.isEven ? FcIcons.bowlFood : FcIcons.forkKnife;
    return FcCard(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(FcSpace.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(FcRadius.input),
                  ),
                  child: Center(
                    child: FcIcon(icon, size: 24, color: c.accent),
                  ),
                ),
                const SizedBox(width: FcSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 36),
                        child: Semantics(
                          header: true,
                          child: Text(
                            r.name,
                            style: FcText.heading.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: FcSpace.s2),
                      RestaurantMeta(restaurant: r),
                      if (showAddress && r.address.isNotEmpty) ...[
                        const SizedBox(height: FcSpace.s2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: FcIcon(
                                FcIcons.mapPin,
                                size: 16,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                r.address,
                                style: FcText.bodySm.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (showReason && r.whyItMatches.isNotEmpty) ...[
                        const SizedBox(height: FcSpace.s2),
                        Text(
                          r.whyItMatches,
                          style: FcText.bodySm.copyWith(color: c.textPrimary),
                        ),
                      ],
                      const SizedBox(height: FcSpace.s3),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Semantics(
                          label: 'Check ${r.name}',
                          button: true,
                          excludeSemantics: true,
                          onTap: onCheck,
                          child: FcButton(
                            label: 'Check this restaurant',
                            variant: FcButtonVariant.secondary,
                            loading: checking,
                            onPressed: onCheck,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: FcSpace.s1,
            right: FcSpace.s1,
            child: FavoriteToggle(pressed: favorite, onPressed: onFavorite),
          ),
        ],
      ),
    );
  }
}
