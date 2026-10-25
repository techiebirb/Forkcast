import 'package:flutter/material.dart';

import '../models.dart';
import '../theme/fc_tokens.dart';
import 'fc_chips.dart';
import 'fc_surfaces.dart';
import 'fc_toggles.dart';

/// One dish: name and price, description, estimated macros, conflict tags,
/// the verdict with its reason, and where the numbers came from.
class FoodItemCard extends StatelessWidget {
  const FoodItemCard({
    super.key,
    required this.item,
    required this.favorite,
    required this.onFavorite,
  });

  final FoodItem item;
  final bool favorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final status = matchStatusFrom(item.matchStatus);
    final blurb = item.description.isNotEmpty
        ? item.description
        : item.ingredients.join(', ');
    final macros = <Widget>[
      MacroChip(value: fcNum(item.calories), unit: 'cal'),
      MacroChip(value: '${fcNum(item.proteins)} g', unit: 'protein'),
      MacroChip(value: '${fcNum(item.carbs)} g', unit: 'carbs'),
      MacroChip(value: '${fcNum(item.fat)} g', unit: 'fat'),
      if (item.fiber > 0)
        MacroChip(value: '${fcNum(item.fiber)} g', unit: 'fiber'),
      if (item.sugar > 0)
        MacroChip(value: '${fcNum(item.sugar)} g', unit: 'sugar'),
    ];
    final flags = <Widget>[
      for (final allergen in item.allergens)
        DietTag(label: 'Contains $allergen', kind: DietTagKind.allergy),
      for (final flag in item.dietFlags)
        DietTag(label: flag, kind: DietTagKind.conflict),
    ];

    return FcCard(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(FcSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            item.name,
                            style: FcText.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (item.price != null) ...[
                        const SizedBox(width: FcSpace.s3),
                        Text(
                          item.price!,
                          style: FcText.tabular(FcText.body).copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (blurb.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    blurb,
                    style: FcText.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: FcSpace.s1,
                  runSpacing: FcSpace.s1,
                  children: macros,
                ),
                if (flags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: FcSpace.s1,
                    runSpacing: FcSpace.s1,
                    children: flags,
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: FcSpace.s2,
                  runSpacing: FcSpace.s1,
                  children: [
                    MatchBadge(status: status),
                    if (item.matchReason.isNotEmpty)
                      Text(
                        item.matchReason,
                        style: FcText.bodySm.copyWith(
                          color: status == MatchStatus.no
                              ? c.textSecondary
                              : c.textPrimary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ConfidenceLabel(verified: item.source == 'restaurant'),
              ],
            ),
          ),
          Positioned(
            top: FcSpace.s1,
            right: FcSpace.s1,
            child: BookmarkToggle(pressed: favorite, onPressed: onFavorite),
          ),
        ],
      ),
    );
  }
}
