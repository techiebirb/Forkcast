import 'package:flutter/material.dart';

import '../models.dart';
import '../theme/fc_tokens.dart';
import 'fc_button.dart';
import 'fc_chips.dart';
import 'fc_form.dart';
import 'fc_icons.dart';
import 'fc_surfaces.dart';

const List<double?> _distanceMiles = [null, 0.5, 1, 3, 5, 10];
const List<String> _distanceShort = ['Any', '½', '1', '3', '5', '10'];
const List<String> _distanceSpoken = [
  'Any distance',
  'Half a mile',
  '1 mile',
  '3 miles',
  '5 miles',
  '10 miles',
];
const List<String> _priceSpoken = [
  '\$, inexpensive',
  '\$\$, moderate',
  '\$\$\$, pricey',
  '\$\$\$\$, expensive',
];

String _miles(double value) => value == 0.5 ? '½' : fcNum(value);

String _sortName(SearchSort sort) => switch (sort) {
      SearchSort.fit => 'Best fit',
      SearchSort.distance => 'Nearest',
      SearchSort.price => 'Cheapest',
    };

/// Wording for the results count line: "best fit first", "nearest first".
String searchSortPhrase(SearchSort sort) => switch (sort) {
      SearchSort.fit => 'best fit first',
      SearchSort.distance => 'nearest first',
      SearchSort.price => 'cheapest first',
    };

/// Short tag-sized descriptions of the filters that are on, for the
/// "no places match" state.
List<String> describeFilters(SearchFilters filters) => [
      if (filters.maxMiles != null) 'Within ${_miles(filters.maxMiles!)} mi',
      for (final level in ([...filters.priceLevels]..sort())) '\$' * level,
      if (filters.openNow) 'Open now',
      ...filters.cuisines,
    ];

/// Horizontally scrolling filter row: Filters (opens the sheet), Distance and
/// Price (open the sheet), Open now (toggles), Sort (opens the sheet), Clear.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.onOpenSheet,
  });

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final count = filters.activeCount;
    final distanceSet = filters.maxMiles != null;
    final priceSet = filters.priceLevels.isNotEmpty;
    final prices = ([...filters.priceLevels]..sort())
        .map((level) => '\$' * level)
        .join(' ');

    final chips = <Widget>[
      FcFilterChip(
        label: 'Filters',
        icon: FcIcons.slidersHorizontal,
        badgeCount: count,
        onSelected: (_) => onOpenSheet(),
      ),
      Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: FcSpace.s1),
        color: c.border,
      ),
      FcFilterChip(
        label: distanceSet
            ? 'Distance: ${_miles(filters.maxMiles!)} mi'
            : 'Distance',
        semanticLabel: distanceSet
            ? 'Distance: within ${_miles(filters.maxMiles!)} '
                '${filters.maxMiles == 1 ? 'mile' : 'miles'}'
            : 'Distance: any',
        selected: distanceSet,
        trailingIcon: FcIcons.caretDown,
        onSelected: (_) => onOpenSheet(),
      ),
      FcFilterChip(
        label: priceSet ? 'Price: $prices' : 'Price',
        semanticLabel: priceSet ? 'Price: $prices' : 'Price: any',
        selected: priceSet,
        trailingIcon: FcIcons.caretDown,
        onSelected: (_) => onOpenSheet(),
      ),
      FcFilterChip(
        label: 'Open now',
        icon: filters.openNow ? FcIcons.check : null,
        selected: filters.openNow,
        onSelected: (value) => onChanged(filters.copyWith(openNow: value)),
      ),
      FcFilterChip(
        label: 'Sort: ${_sortName(filters.sort)}',
        trailingIcon: FcIcons.caretDown,
        onSelected: (_) => onOpenSheet(),
      ),
      if (count > 0)
        FcButton(
          label: 'Clear',
          variant: FcButtonVariant.ghost,
          onPressed: () =>
              onChanged(const SearchFilters.none().copyWith(sort: filters.sort)),
        ),
    ];

    return Semantics(
      container: true,
      label: 'Filter places',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: FcSpace.s2),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens the filters sheet. Resolves to the chosen filters, or null if it was
/// dismissed. [all] is the full pool, used for the live "Show N places" count.
Future<SearchFilters?> showSearchFilterSheet(
  BuildContext context, {
  required SearchFilters initial,
  required List<RestaurantRecommendation> all,
  required List<String> cuisines,
}) {
  final c = context.fc;
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim,
    elevation: 0,
    builder: (_) =>
        _FilterSheet(initial: initial, all: all, cuisines: cuisines),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.all,
    required this.cuisines,
  });

  final SearchFilters initial;
  final List<RestaurantRecommendation> all;
  final List<String> cuisines;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchFilters _draft = widget.initial;

  int get _matchCount => _draft.apply(widget.all).length;

  void _togglePrice(int level, bool on) {
    final next = {..._draft.priceLevels};
    on ? next.add(level) : next.remove(level);
    setState(() => _draft = _draft.copyWith(priceLevels: next.toList()..sort()));
  }

  void _toggleCuisine(String name, bool on) {
    final next = [..._draft.cuisines]
      ..removeWhere((item) => item.toLowerCase() == name.toLowerCase());
    if (on) {
      next.add(name);
    }
    setState(() => _draft = _draft.copyWith(cuisines: next));
  }

  bool _cuisineOn(String name) =>
      _draft.cuisines.any((item) => item.toLowerCase() == name.toLowerCase());

  Widget _sectionHead(FcColors c, String title, {String? meta}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: FcText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
        if (meta != null)
          Text(
            meta,
            style: FcText.tabular(FcText.caption).copyWith(
              color: c.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _divider(FcColors c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: FcSpace.s5),
        child: Divider(height: 1, thickness: 1, color: c.border),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final distanceIndex = _distanceMiles.indexOf(_draft.maxMiles);
    final count = _matchCount;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: 'Filters',
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(FcRadius.sheet),
            ),
            boxShadow: c.shadowRaised,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: FcSpace.s2),
                    decoration: BoxDecoration(
                      color: c.borderStrong,
                      borderRadius: BorderRadius.circular(FcRadius.pill),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FcSpace.s5,
                    FcSpace.s2,
                    FcSpace.s2,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filters',
                          style: FcText.wordmark.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      FcButton(
                        label: 'Close filters',
                        icon: FcIcons.x,
                        iconOnly: true,
                        variant: FcButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      FcSpace.s5,
                      FcSpace.s3,
                      FcSpace.s5,
                      FcSpace.s5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHead(
                          c,
                          'Distance',
                          meta: _draft.maxMiles == null
                              ? null
                              : 'Within ${_miles(_draft.maxMiles!)} mi',
                        ),
                        const SizedBox(height: FcSpace.s3),
                        FcSeg(
                          options: _distanceShort,
                          optionLabels: _distanceSpoken,
                          semanticLabel: 'Distance',
                          selectedIndex: distanceIndex < 0 ? 0 : distanceIndex,
                          onChanged: (index) => setState(() {
                            final miles = _distanceMiles[index];
                            _draft = miles == null
                                ? _draft.copyWith(clearMaxMiles: true)
                                : _draft.copyWith(maxMiles: miles);
                          }),
                        ),
                        _divider(c),
                        _sectionHead(c, 'Price', meta: 'Pick any that work'),
                        const SizedBox(height: FcSpace.s3),
                        Row(
                          children: [
                            for (var level = 1; level <= 4; level++) ...[
                              if (level > 1) const SizedBox(width: FcSpace.s2),
                              Expanded(
                                child: FcFilterChip(
                                  label: '\$' * level,
                                  semanticLabel: _priceSpoken[level - 1],
                                  icon: _draft.priceLevels.contains(level)
                                      ? FcIcons.check
                                      : null,
                                  selected: _draft.priceLevels.contains(level),
                                  onSelected: (on) => _togglePrice(level, on),
                                ),
                              ),
                            ],
                          ],
                        ),
                        _divider(c),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Open now',
                                    style: FcText.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Hide places that are closed right now',
                                    style: FcText.bodySm.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FcSwitch(
                              value: _draft.openNow,
                              semanticLabel: 'Open now',
                              onChanged: (on) => setState(
                                () => _draft = _draft.copyWith(openNow: on),
                              ),
                            ),
                          ],
                        ),
                        if (widget.cuisines.isNotEmpty) ...[
                          _divider(c),
                          _sectionHead(
                            c,
                            'Cuisine',
                            meta: 'From these results',
                          ),
                          const SizedBox(height: FcSpace.s3),
                          Wrap(
                            spacing: FcSpace.s2,
                            runSpacing: FcSpace.s2,
                            children: [
                              for (final name in widget.cuisines)
                                FcFilterChip(
                                  label: name,
                                  selected: _cuisineOn(name),
                                  onSelected: (on) => _toggleCuisine(name, on),
                                ),
                            ],
                          ),
                        ],
                        _divider(c),
                        _sectionHead(c, 'Sort by'),
                        const SizedBox(height: FcSpace.s3),
                        FcSeg(
                          options: [
                            for (final sort in SearchSort.values)
                              _sortName(sort),
                          ],
                          semanticLabel: 'Sort by',
                          selectedIndex: _draft.sort.index,
                          onChanged: (index) => setState(
                            () => _draft = _draft.copyWith(
                              sort: SearchSort.values[index],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    FcSpace.s4,
                    FcSpace.s3,
                    FcSpace.s4,
                    FcSpace.s4,
                  ),
                  child: Row(
                    children: [
                      FcButton(
                        label: 'Reset',
                        large: true,
                        variant: FcButtonVariant.secondary,
                        onPressed: _draft.isActive ||
                                _draft.sort != SearchSort.fit
                            ? () => setState(
                                  () => _draft = const SearchFilters.none(),
                                )
                            : null,
                      ),
                      const SizedBox(width: FcSpace.s2),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: FcButton(
                            label: 'Show $count ${count == 1 ? 'place' : 'places'}',
                            large: true,
                            block: true,
                            onPressed: () => Navigator.of(context).pop(_draft),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when filters hide every place in the pool. Offers a fresh search
/// that takes the filters into account, or clearing them.
class FilteredEmptyState extends StatelessWidget {
  const FilteredEmptyState({
    super.key,
    required this.filters,
    required this.onSearchAgain,
    required this.onClear,
    this.searching = false,
  });

  final SearchFilters filters;
  final VoidCallback onSearchAgain;
  final VoidCallback onClear;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final tags = describeFilters(filters);
    return Semantics(
      container: true,
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: c.borderStrong,
          radius: FcRadius.card,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(FcRadius.card),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FcSpace.s6,
            vertical: FcSpace.s8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(bottom: FcSpace.s2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accentSoft,
                ),
                child: Center(
                  child: FcIcon(
                    FcIcons.slidersHorizontal,
                    size: 28,
                    color: c.accent,
                  ),
                ),
              ),
              Text(
                'No places match these filters',
                textAlign: TextAlign.center,
                style: FcText.heading.copyWith(color: c.textPrimary),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: FcSpace.s2),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: FcSpace.s1,
                  runSpacing: FcSpace.s1,
                  children: [
                    for (final tag in tags)
                      Container(
                        constraints: const BoxConstraints(minHeight: 26),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: ShapeDecoration(
                          color: c.surfaceSunken,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          tag,
                          style: FcText.tabular(FcText.caption).copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: FcSpace.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 288),
                child: Text(
                  "Try a wider distance or more price levels, or search "
                  "again and we'll look for places that fit.",
                  textAlign: TextAlign.center,
                  style: FcText.bodySm.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(height: FcSpace.s4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FcButton(
                      label: 'Search again with these filters',
                      icon: FcIcons.magnifyingGlass,
                      block: true,
                      loading: searching,
                      onPressed: onSearchAgain,
                    ),
                    const SizedBox(height: FcSpace.s2),
                    FcButton(
                      label: 'Clear filters',
                      variant: FcButtonVariant.secondary,
                      block: true,
                      onPressed: searching ? null : onClear,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
