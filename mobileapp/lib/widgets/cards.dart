import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'badges.dart';

String fmtNum(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// Star (restaurants) or bookmark (meals) toggle in a 44pt icon button.
class FavButton extends StatelessWidget {
  const FavButton({
    super.key,
    required this.selected,
    required this.onPressed,
    this.meal = false,
  });

  final bool selected;
  final bool meal;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final IconData icon = meal
        ? (selected
            ? PhosphorIconsFill.bookmarkSimple
            : PhosphorIconsRegular.bookmarkSimple)
        : (selected ? PhosphorIconsFill.star : PhosphorIconsRegular.star);
    return Semantics(
      toggled: selected,
      child: IconButton(
        isSelected: selected,
        onPressed: onPressed,
        tooltip: selected
            ? 'Remove from favorites'
            : (meal ? 'Save this meal' : 'Add to favorites'),
        icon: Icon(icon),
      ),
    );
  }
}

/// Bordered surface card with the design's 16 radius.
class FcCard extends StatelessWidget {
  const FcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FcSpace.s4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(FcRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Restaurant suggestion / favorite card.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.favorite,
    required this.onFavorite,
    required this.onCheck,
    this.showAddress = false,
  });

  final RestaurantRecommendation restaurant;
  final bool favorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onCheck;
  final bool showAddress;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final r = restaurant;
    return FcCard(
      padding: EdgeInsets.zero,
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
                  child: Icon(
                    r.name.length.isEven
                        ? PhosphorIconsRegular.bowlFood
                        : PhosphorIconsRegular.forkKnife,
                    size: 24,
                    color: c.accent,
                  ),
                ),
                const SizedBox(width: FcSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: Text(r.name, style: context.text.titleMedium),
                      ),
                      const SizedBox(height: FcSpace.s2),
                      MetaLine(
                        cuisine: r.cuisine,
                        priceLevel: r.priceLevel,
                        walkMinutes: r.walkMinutes,
                        distanceMiles: r.distanceMiles,
                      ),
                      if (showAddress && r.address.isNotEmpty) ...[
                        const SizedBox(height: FcSpace.s2),
                        AddressLine(r.address),
                      ],
                      if (!showAddress && r.whyItMatches.isNotEmpty) ...[
                        const SizedBox(height: FcSpace.s2),
                        Text(
                          r.whyItMatches,
                          style: context.text.bodyMedium!.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: FcSpace.s3),
                      Semantics(
                        label: 'Check ${r.name}',
                        button: true,
                        excludeSemantics: true,
                        child: OutlinedButton(
                          onPressed: onCheck,
                          child: const Text('Check this restaurant'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: FcSpace.s2,
            right: FcSpace.s2,
            child: FavButton(selected: favorite, onPressed: onFavorite),
          ),
        ],
      ),
    );
  }
}

class AddressLine extends StatelessWidget {
  const AddressLine(this.address, {super.key});

  final String address;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(PhosphorIconsRegular.mapPin,
              size: 16, color: c.textSecondary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            address,
            style: context.text.bodyMedium!.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Macro chips for a dish. Zero values the menu didn't list are shown as
/// dashed "… not listed" chips.
class MacroRow extends StatelessWidget {
  const MacroRow({super.key, required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    Widget chip(double v, String unit, String name, {bool grams = true}) {
      if (v <= 0 && name != 'cal') return MacroChip.missing('$name not listed');
      return MacroChip(
        value: grams ? '${fmtNum(v)} g' : fmtNum(v),
        unit: name,
      );
    }

    return Semantics(
      label: 'Estimated macros',
      child: Wrap(
        spacing: FcSpace.s1,
        runSpacing: FcSpace.s1,
        children: [
          chip(item.calories, '', 'cal', grams: false),
          chip(item.proteins, 'g', 'protein'),
          chip(item.carbs, 'g', 'carbs'),
          chip(item.fat, 'g', 'fat'),
        ],
      ),
    );
  }
}

/// A dish on the Check screen and in Saved meals.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.saved,
    required this.onSave,
    this.subtitle,
    this.compact = false,
  });

  final FoodItem item;
  final bool saved;
  final VoidCallback? onSave;

  /// Shown under the name instead of the price (e.g. "Saffron & Salt · $15").
  final String? subtitle;

  /// Saved-meal style: no description, allergens or confidence label.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final price = item.price;
    const gap = SizedBox(height: FcSpace.s2);
    return FcCard(
      padding: const EdgeInsets.fromLTRB(
        FcSpace.s4,
        FcSpace.s2,
        FcSpace.s2,
        FcSpace.s4,
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: FcSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: context.text.titleSmall),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: context.text.bodyMedium!.tabular
                              .copyWith(color: c.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (subtitle == null && price != null && price.isNotEmpty)
                  Text(price, style: context.text.titleSmall!.tabular),
                Transform.translate(
                  offset: const Offset(FcSpace.s2, 0),
                  child: FavButton(
                    meal: true,
                    selected: saved,
                    onPressed: onSave,
                  ),
                ),
              ],
            ),
            if (!compact && item.description.isNotEmpty) ...[
              Text(
                item.description,
                style: context.text.bodyMedium!.copyWith(
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: FcSpace.s3),
            ] else
              const SizedBox(height: FcSpace.s1),
            MacroRow(item: item),
            if (!compact && item.allergens.isNotEmpty) ...[
              gap,
              Wrap(
                spacing: FcSpace.s1,
                runSpacing: FcSpace.s1,
                children: [
                  for (final a in item.allergens)
                    FcTag.allergy('Contains ${a.toLowerCase()}', allergen: a),
                ],
              ),
            ],
            gap,
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: FcSpace.s2,
              runSpacing: FcSpace.s1,
              children: [
                MatchBadge(status: item.matchStatus),
                if (item.matchReason.isNotEmpty)
                  Text(
                    item.matchReason,
                    style: context.text.bodyMedium!.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
            if (!compact) ...[
              gap,
              ConfidenceLabel(source: item.source),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Matching your preferences · Edit" card with target tags.
class PrefsSummaryCard extends StatelessWidget {
  const PrefsSummaryCard({
    super.key,
    required this.prefs,
    required this.onEdit,
    this.title = 'Matching your preferences',
    this.allMacros = false,
  });

  final UserPreferences prefs;
  final VoidCallback onEdit;
  final String title;

  /// Show all four macro targets as outlined chips (Check screen) instead of
  /// calories + protein tags (Search screen).
  final bool allMacros;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chips = <Widget>[];
    void target(double? v, String unit, String name) {
      if (v == null) return;
      final value = unit.isEmpty ? fmtNum(v) : '${fmtNum(v)} $unit';
      chips.add(allMacros
          ? MacroChip(value: value, unit: name, target: true)
          : FcTag(label: '$value $name'));
    }

    target(prefs.calories, '', 'cal');
    target(prefs.proteins, 'g', 'protein');
    if (allMacros) {
      target(prefs.carbs, 'g', 'carbs');
      target(prefs.fat, 'g', 'fat');
    }
    if (prefs.halal) {
      chips.add(const FcTag(
        label: 'Halal',
        kind: TagKind.preference,
        icon: PhosphorIconsRegular.check,
      ));
    }
    if (prefs.kosher) {
      chips.add(const FcTag(
        label: 'Kosher',
        kind: TagKind.preference,
        icon: PhosphorIconsRegular.check,
      ));
    }
    for (final a in prefs.allergies) {
      chips.add(FcTag.allergy('No ${a.toLowerCase()}', allergen: a));
    }

    return Semantics(
      label: 'Your preferences',
      container: true,
      child: FcCard(
        padding: const EdgeInsets.fromLTRB(FcSpace.s4, 0, FcSpace.s2, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.text.bodySmall!.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
            if (chips.isEmpty)
              Text(
                'No targets set',
                style: context.text.bodyMedium!.copyWith(
                  color: c.textSecondary,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: FcSpace.s2),
                child: Wrap(
                  spacing: FcSpace.s1,
                  runSpacing: FcSpace.s1,
                  children: chips,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
