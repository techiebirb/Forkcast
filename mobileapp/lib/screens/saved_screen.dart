import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../models.dart';
import '../session.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_cards.dart';
import '../widgets/fc_chips.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_surfaces.dart';
import '../widgets/fc_toggles.dart';
import 'check_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
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

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final session = SessionScope.of(context);
    final saved = session.saved;
    final nothingYet =
        saved.favoriteRestaurants.isEmpty && saved.favoriteMeals.isEmpty;

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
    } else if (nothingYet) {
      content = ListState(
        kind: ListStateKind.empty,
        icon: FcIcons.bookmark,
        title: 'Nothing saved yet',
        body: 'Tap the bookmark on any restaurant.',
        actionLabel: 'Search restaurants',
        onAction: () => context.go('/'),
      );
    } else {
      content = _favorites(c, session);
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const FcAppBar(title: 'Saved', showBack: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s4,
                  FcSpace.s2,
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
            child:
                Center(child: FcIcon(icon, size: 20, color: c.textSecondary)),
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
        _heading(
            c, 'Restaurants', restaurants.isEmpty ? null : restaurants.length),
        const SizedBox(height: FcSpace.s3),
        if (restaurants.isEmpty)
          _emptyCard(
            c,
            FcIcons.bookmark,
            'No restaurants saved yet',
            'Tap the bookmark on any restaurant.',
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
          _footnote(c, 'Only what you bookmark · newest first · up to 100'),
      ],
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
                    MacroChip(
                        value: '${fcNum(item.proteins)} g', unit: 'protein'),
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
            child: BookmarkToggle(
              pressed: true,
              onPressed: onRemove,
              name: item.name,
            ),
          ),
        ],
      ),
    );
  }
}
