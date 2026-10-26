import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../models.dart';
import '../session.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import 'check_screen.dart';
import '../widgets/fc_cards.dart';
import '../widgets/fc_filters.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_surfaces.dart';

enum _SearchPhase { loading, results, empty, error }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  _SearchPhase _phase = _SearchPhase.loading;
  bool _searchingAgain = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  /// Runs the restaurant search with the preferences Home just stored.
  Future<void> _search() async {
    final session = SessionScope.of(context);
    setState(() => _phase = _SearchPhase.loading);
    try {
      final error = await session.searchRestaurants(session.preferences);
      if (!mounted) {
        return;
      }
      setState(() {
        if (error != null && error.isNotEmpty) {
          _phase = _SearchPhase.error;
        } else if (session.restaurants.isEmpty) {
          _phase = _SearchPhase.empty;
        } else {
          _phase = _SearchPhase.results;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _phase = _SearchPhase.error);
      }
    }
  }

  /// "Search again": asks for new places that fit the current filters. The
  /// old results stay on screen while it runs.
  Future<void> _searchAgain() async {
    final session = SessionScope.of(context);
    setState(() => _searchingAgain = true);
    try {
      final error = await session.searchRestaurants(
        session.preferences,
        applyToSearch: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _searchingAgain = false;
        if (error != null && error.isNotEmpty) {
          _phase = _SearchPhase.error;
        } else if (session.restaurants.isEmpty) {
          _phase = _SearchPhase.empty;
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _searchingAgain = false);
        showApiError(context, error);
      }
    }
  }

  Future<void> _openFilters() async {
    final session = SessionScope.of(context);
    final next = await showSearchFilterSheet(
      context,
      initial: session.filters,
      all: session.restaurants,
      cuisines: session.cuisines,
    );
    if (next != null) {
      session.setFilters(next);
    }
  }

  /// The Check screen loads the menu itself, so it can show its progress.
  void _check(RestaurantRecommendation restaurant) {
    context.push('/check-restaurant', extra: CheckRequest(restaurant));
  }

  Future<void> _toggleFavorite(RestaurantRecommendation restaurant) async {
    try {
      await SessionScope.of(context).toggleFavoriteRestaurant(restaurant);
    } catch (error) {
      if (mounted) {
        showApiError(context, error);
      }
    }
  }

  void _editPreferences() => context.pop();

  static String _orList(List<String> items) {
    if (items.length <= 1) {
      return items.join();
    }
    return '${items.sublist(0, items.length - 1).join(', ')} or ${items.last}';
  }

  String _loadingDetail(UserPreferences prefs) {
    final diets = [
      if (prefs.halal) 'halal',
      if (prefs.kosher) 'kosher',
    ].join(' and ');
    final base = diets.isEmpty
        ? 'Looking for places nearby'
        : 'Looking for $diets spots nearby';
    final avoid = prefs.allergies.isEmpty
        ? ''
        : ' and leaving out places that rely on ${_orList(prefs.allergies)}';
    return '$base$avoid.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final session = SessionScope.of(context);
    final prefs = session.preferences;
    final restaurants = session.restaurants;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            const FcAppBar(
              title: 'Places for you',
              subtitle: 'Near you',
              subtitleIcon: FcIcons.mapPin,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s4,
                  FcSpace.s1,
                  FcSpace.s4,
                  FcSpace.s6,
                ),
                children: [
                  PrefSummaryCard(
                    preferences: prefs,
                    title: 'Matching your preferences',
                    onEdit: _editPreferences,
                  ),
                  const SizedBox(height: FcSpace.s4),
                  ..._body(c, prefs, restaurants, session),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    FcColors c,
    UserPreferences prefs,
    List<RestaurantRecommendation> restaurants,
    SessionController session,
  ) {
    switch (_phase) {
      case _SearchPhase.loading:
        return [
          Semantics(
            liveRegion: true,
            container: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: FcSpace.s1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: FcSpinner(color: c.accent),
                  ),
                  const SizedBox(width: FcSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finding places that fit your goals',
                          style: FcText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          _loadingDetail(prefs),
                          style: FcText.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FcSpace.s4),
          const ListState(kind: ListStateKind.loading, rows: 4),
        ];
      case _SearchPhase.error:
        return [
          FcCard(
            child: ListState(
              kind: ListStateKind.error,
              title: "Couldn't load places",
              body: 'Check your connection and try again.',
              actionLabel: 'Try again',
              onAction: _search,
            ),
          ),
        ];
      case _SearchPhase.empty:
        return [
          FcCard(
            child: ListState(
              kind: ListStateKind.empty,
              title: 'Nothing matched nearby',
              body: 'Try loosening your preferences, like raising your calorie '
                  'target or skipping protein. Allergy filters always stay on.',
              actionLabel: 'Edit preferences',
              onAction: _editPreferences,
            ),
          ),
        ];
      case _SearchPhase.results:
        final shown = session.filteredRestaurants;
        final filters = session.filters;
        return [
          SearchFilterBar(
            filters: filters,
            onChanged: session.setFilters,
            onOpenSheet: _openFilters,
          ),
          const SizedBox(height: FcSpace.s3),
          Semantics(
            liveRegion: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: filters.isActive
                        ? '${shown.length} of ${restaurants.length} places'
                        : '${restaurants.length} '
                            '${restaurants.length == 1 ? 'place' : 'places'}',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' · ${searchSortPhrase(filters.sort)}'),
                ],
              ),
              style: FcText.tabular(FcText.bodySm).copyWith(
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: FcSpace.s3),
          if (shown.isEmpty)
            FilteredEmptyState(
              filters: filters,
              searching: _searchingAgain,
              onSearchAgain: _searchAgain,
              onClear: () => session.setFilters(
                const SearchFilters.none().copyWith(sort: filters.sort),
              ),
            )
          else
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(height: FcSpace.s3),
              RestaurantCard(
                restaurant: shown[i],
                favorite: session.isFavoriteRestaurant(shown[i].name),
                onFavorite: () => _toggleFavorite(shown[i]),
                onCheck: () => _check(shown[i]),
              ),
            ],
        ];
    }
  }
}
