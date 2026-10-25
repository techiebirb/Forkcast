import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../models.dart';
import '../session.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_cards.dart';
import '../widgets/fc_chips.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_surfaces.dart';
import '../widgets/fc_toggles.dart';
import 'check_screen.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// How long ago a history entry was checked: "just now", "5 min ago",
/// "2 h ago", "Yesterday", "3 d ago", then a date like "Oct 18".
String savedTimeLabel(DateTime? time, {DateTime? now}) {
  if (time == null) {
    return '';
  }
  final current = now ?? DateTime.now();
  final local = time.toLocal();
  final diff = current.difference(local);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} h ago';
  }
  final today = DateTime(current.year, current.month, current.day);
  final thatDay = DateTime(local.year, local.month, local.day);
  final days = today.difference(thatDay).inDays;
  if (days <= 1) {
    return 'Yesterday';
  }
  if (days < 7) {
    return '$days d ago';
  }
  return '${_months[local.month - 1]} ${local.day}';
}

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  int _tab = 0;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await SessionScope.of(context).refreshSaved();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        showApiError(context, error);
      }
    }
  }

  void _check(RestaurantRecommendation restaurant) {
    context.push('/check-restaurant', extra: CheckRequest(restaurant));
  }

  void _openHistory(HistoryEntry entry) {
    SessionScope.of(context).openHistoryEntry(entry);
    context.push('/check-restaurant');
  }

  Future<void> _confirmClear() async {
    final session = SessionScope.of(context);
    final confirmed = await showFcSheet<bool>(
      context,
      (sheetContext) => FcSheet(
        title: 'Clear history?',
        body: 'Your favorites will not be affected.',
        actions: [
          FcButton(
            label: 'Cancel',
            large: true,
            variant: FcButtonVariant.secondary,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
          FcButton(
            label: 'Clear',
            large: true,
            variant: FcButtonVariant.destructive,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(session.clearHistory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final session = SessionScope.of(context);
    final saved = session.saved;
    final nothingYet = saved.favoriteRestaurants.isEmpty &&
        saved.favoriteMeals.isEmpty &&
        saved.history.isEmpty;

    final Widget content;
    if (_loading && nothingYet) {
      content = const ListState(kind: ListStateKind.loading, rows: 4);
    } else if (_failed && nothingYet) {
      content = FcCard(
        child: ListState(
          kind: ListStateKind.error,
          title: "Couldn't load your saved items",
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: _refresh,
        ),
      );
    } else {
      content = _tab == 0
          ? _favorites(c, session)
          : _history(c, session);
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            FcAppBar(
              title: 'Saved',
              backLabel: 'Back to Home',
              actions: [
                if (_tab == 1 && saved.history.isNotEmpty)
                  FcButton(
                    label: 'Clear history',
                    variant: FcButtonVariant.ghost,
                    iconOnly: true,
                    icon: FcIcons.trash,
                    onPressed: _confirmClear,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FcSpace.s4,
                FcSpace.s1,
                FcSpace.s4,
                0,
              ),
              child: FcSeg(
                options: const ['Favorites', 'History'],
                selectedIndex: _tab,
                semanticLabel: 'Saved',
                onChanged: (index) => setState(() => _tab = index),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s4,
                  FcSpace.s6,
                  FcSpace.s4,
                  FcSpace.s8,
                ),
                children: [content],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(FcColors c, String text, [int? count]) => Semantics(
        header: true,
        child: Text(
          count == null ? text : '$text · $count',
          style: FcText.tabular(FcText.heading).copyWith(color: c.textPrimary),
        ),
      );

  Widget _emptyCard(FcColors c, IconData icon, String title, String body) {
    return FcCard(
      padding: const EdgeInsets.all(FcSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surfaceSunken,
            ),
            child: Center(child: FcIcon(icon, size: 20, color: c.textSecondary)),
          ),
          const SizedBox(width: FcSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FcText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  body,
                  style: FcText.bodySm.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footnote(FcColors c, String text) => Padding(
        padding: const EdgeInsets.only(top: FcSpace.s6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: FcText.tabular(FcText.caption).copyWith(
            color: c.textSecondary,
          ),
        ),
      );

  Widget _favorites(FcColors c, SessionController session) {
    final saved = session.saved;
    final restaurants = saved.favoriteRestaurants;
    final meals = saved.favoriteMeals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(c, 'Restaurants', restaurants.isEmpty ? null : restaurants.length),
        const SizedBox(height: FcSpace.s3),
        if (restaurants.isEmpty)
          _emptyCard(
            c,
            FcIcons.star,
            'No restaurants saved yet',
            'Star a restaurant from the search results to save it here.',
          )
        else
          for (var i = 0; i < restaurants.length; i++) ...[
            if (i > 0) const SizedBox(height: FcSpace.s3),
            RestaurantCard(
              restaurant: restaurants[i],
              favorite: true,
              showReason: false,
              showAddress: true,
              onFavorite: () => _run(
                () => session.toggleFavoriteRestaurant(restaurants[i]),
              ),
              onCheck: () => _check(restaurants[i]),
            ),
          ],
        const SizedBox(height: FcSpace.s6),
        _heading(c, 'Meals', meals.isEmpty ? null : meals.length),
        const SizedBox(height: FcSpace.s3),
        if (meals.isEmpty)
          _emptyCard(
            c,
            FcIcons.bookmark,
            'No meals saved yet',
            'Bookmark a menu item to keep its macros here.',
          )
        else
          for (var i = 0; i < meals.length; i++) ...[
            if (i > 0) const SizedBox(height: FcSpace.s3),
            _MealCard(
              meal: meals[i],
              onRemove: () => _run(
                () => session.toggleFavoriteMeal(
                  RestaurantRecommendation(
                    name: meals[i].restaurantName,
                    address: meals[i].restaurantAddress,
                  ),
                  meals[i].item,
                ),
              ),
            ),
          ],
        if (restaurants.isNotEmpty || meals.isNotEmpty)
          _footnote(c, 'Newest first · up to 100 favorites'),
      ],
    );
  }

  Widget _history(FcColors c, SessionController session) {
    final history = session.saved.history;
    if (history.isEmpty) {
      return const FcCard(
        child: ListState(
          kind: ListStateKind.empty,
          icon: FcIcons.storefront,
          title: 'No history yet',
          body: 'Restaurants you check will show up here so you can reopen '
              'them instantly.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FcCard(
          clip: true,
          child: Column(
            children: [
              for (var i = 0; i < history.length; i++) ...[
                if (i > 0) Divider(color: c.border, height: 1, thickness: 1),
                _HistoryRow(
                  entry: history[i],
                  when: savedTimeLabel(history[i].checkedAt),
                  onTap: () => _openHistory(history[i]),
                ),
              ],
            ],
          ),
        ),
        _footnote(
          c,
          'Your 20 most recent checks. Opening one shows the saved results '
          'right away.',
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.when,
    required this.onTap,
  });

  final HistoryEntry entry;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final count = entry.menuItems.length;
    final meta = [
      '$count ${count == 1 ? 'item' : 'items'}',
      if (when.isNotEmpty) when,
    ].join(' · ');
    return Semantics(
      button: true,
      label: '${entry.restaurant.name}, $meta',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.restaurant.name,
                        style: FcText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        meta,
                        style: FcText.tabular(FcText.bodySm).copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FcIcon(FcIcons.caretRight, size: 20, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A saved dish: name, restaurant and price, macros, and its verdict.
class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onRemove});

  final FavoriteMeal meal;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final item = meal.item;
    final status = matchStatusFrom(item.matchStatus);
    final sub = [
      meal.restaurantName,
      if (item.price != null) item.price!,
    ].join(' · ');
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          item.name,
                          style: FcText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        sub,
                        style: FcText.tabular(FcText.bodySm).copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: FcSpace.s1,
                  runSpacing: FcSpace.s1,
                  children: [
                    MacroChip(value: fcNum(item.calories), unit: 'cal'),
                    MacroChip(value: '${fcNum(item.proteins)} g', unit: 'protein'),
                    MacroChip(value: '${fcNum(item.carbs)} g', unit: 'carbs'),
                    MacroChip(value: '${fcNum(item.fat)} g', unit: 'fat'),
                  ],
                ),
                if (item.matchReason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: FcSpace.s2,
                    runSpacing: FcSpace.s1,
                    children: [
                      MatchBadge(status: status),
                      Text(
                        item.matchReason,
                        style: FcText.bodySm.copyWith(color: c.textPrimary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: FcSpace.s1,
            right: FcSpace.s1,
            child: BookmarkToggle(pressed: true, onPressed: onRemove),
          ),
        ],
      ),
    );
  }
}
