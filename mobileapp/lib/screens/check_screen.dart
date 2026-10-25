import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../models.dart';
import '../session.dart';
import '../theme/fc_tokens.dart';
import '../widgets/ai_steps.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_cards.dart';
import '../widgets/fc_chips.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_surfaces.dart';
import '../widgets/fc_toggles.dart';
import '../widgets/food_item_card.dart';

/// Pass as the route `extra` to make the Check screen load a fresh menu for
/// [restaurant]. Without it the screen shows the menu already in the session
/// (a reopened history entry).
class CheckRequest {
  const CheckRequest(this.restaurant);

  final RestaurantRecommendation restaurant;
}

enum _CheckPhase { loading, results, noMenu, error }

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key, this.request});

  final CheckRequest? request;

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  _CheckPhase _phase = _CheckPhase.loading;
  int _step = 0;
  Timer? _stepTimer;

  bool _started = false;

  // Inherited widgets can't be read in initState, so the first look at the
  // session happens here.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final request = widget.request;
    if (request == null) {
      final empty = SessionScope.of(context).menuItems.isEmpty;
      _phase = empty ? _CheckPhase.noMenu : _CheckPhase.results;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(request));
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  List<String> _stepLabels(UserPreferences prefs) {
    final diets = [
      if (prefs.halal) 'halal',
      if (prefs.kosher) 'kosher',
    ].join(' and ');
    return [
      'Finding the menu',
      'Estimating macros',
      if (prefs.allergies.isNotEmpty)
        'Checking ${_andList(prefs.allergies)}',
      if (diets.isNotEmpty) 'Checking $diets',
    ];
  }

  static String _andList(List<String> items) {
    if (items.length <= 1) {
      return items.join();
    }
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  Future<void> _load(CheckRequest request) async {
    final session = SessionScope.of(context);
    session.beginCheck(request.restaurant);
    setState(() {
      _phase = _CheckPhase.loading;
      _step = 0;
    });
    // The steps advance on a timer so the wait reads as progress. They name
    // what the AI is doing, never an invented count.
    final last = _stepLabels(session.preferences).length - 1;
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _step < last) {
        setState(() => _step++);
      }
    });
    try {
      final error = await session.checkRestaurant(session.preferences);
      if (!mounted) {
        return;
      }
      setState(() {
        if (error != null && error.isNotEmpty) {
          _phase = _CheckPhase.error;
        } else if (session.menuItems.isEmpty) {
          _phase = _CheckPhase.noMenu;
        } else {
          _phase = _CheckPhase.results;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _phase = _CheckPhase.error);
      }
    } finally {
      _stepTimer?.cancel();
    }
  }

  RestaurantRecommendation _active(SessionController session) {
    final name = session.preferences.restaurantName.trim();
    for (final restaurant in session.restaurants) {
      if (restaurant.name.trim() == name) {
        return restaurant;
      }
    }
    return RestaurantRecommendation(name: name);
  }

  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        showApiError(context, error);
      }
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      showApiError(context, 'Could not open that link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final session = SessionScope.of(context);
    final active = _active(session);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            const FcAppBar(backLabel: 'Back to results'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s4,
                  0,
                  FcSpace.s4,
                  FcSpace.s8,
                ),
                children: [
                  _header(c, session, active),
                  const SizedBox(height: 20),
                  ..._body(c, session, active),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(FcColors c, SessionController session, RestaurantRecommendation r) {
    final hasName = r.name.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  hasName ? r.name : 'No restaurant selected',
                  style: FcText.title.copyWith(color: c.textPrimary),
                ),
              ),
            ),
            if (hasName)
              FavoriteToggle(
                pressed: session.isFavoriteRestaurant(r.name),
                onPressed: () => _guarded(
                  () => session.toggleFavoriteRestaurant(r),
                ),
              ),
          ],
        ),
        const SizedBox(height: FcSpace.s2),
        RestaurantMeta(restaurant: r),
        if (r.address.isNotEmpty) ...[
          const SizedBox(height: FcSpace.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: FcIcon(FcIcons.mapPin, size: 16, color: c.textSecondary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.address,
                  style: FcText.bodySm.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ],
        if (hasName) ...[
          const SizedBox(height: FcSpace.s3),
          Wrap(
            spacing: FcSpace.s2,
            runSpacing: FcSpace.s2,
            children: [
              if (r.googleMapsUrl.isNotEmpty)
                FcButton(
                  label: 'Google Maps',
                  variant: FcButtonVariant.secondary,
                  onPressed: () => _openLink(r.googleMapsUrl),
                ),
              if (r.website.isNotEmpty)
                FcButton(
                  label: 'Website',
                  variant: FcButtonVariant.secondary,
                  onPressed: () => _openLink(r.website),
                ),
              if (r.doordashUrl.isNotEmpty)
                FcButton(
                  label: 'DoorDash',
                  variant: FcButtonVariant.secondary,
                  onPressed: () => _openLink(r.doordashUrl),
                ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _body(
    FcColors c,
    SessionController session,
    RestaurantRecommendation active,
  ) {
    switch (_phase) {
      case _CheckPhase.loading:
        return [
          Semantics(
            liveRegion: true,
            container: true,
            child: FcCard(
              padding: const EdgeInsets.all(FcSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FcSpinner(size: 18, color: c.accent),
                      const SizedBox(width: FcSpace.s3),
                      Text(
                        'Reading the menu for you',
                        style: FcText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FcSpace.s3),
                  AiSteps(
                    steps: _stepLabels(session.preferences),
                    current: _step,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const ListState(kind: ListStateKind.loading, rows: 3),
        ];
      case _CheckPhase.error:
        return [
          FcCard(
            child: ListState(
              kind: ListStateKind.error,
              title: "Couldn't check this menu",
              body: 'Check your connection and try again. The quick links '
                  'above still work.',
              actionLabel: widget.request == null ? null : 'Try again',
              onAction: widget.request == null
                  ? null
                  : () => _load(widget.request!),
            ),
          ),
        ];
      case _CheckPhase.noMenu:
        return [
          FcCard(
            child: ListState(
              kind: ListStateKind.empty,
              title: 'No menu found online',
              body: "We couldn't find a menu we can read for "
                  '${active.name.isEmpty ? 'this restaurant' : active.name}. '
                  'Try their website or DoorDash, or ask staff about your '
                  'allergies.',
              actionLabel: 'Back to results',
              onAction: () => context.pop(),
            ),
          ),
        ];
      case _CheckPhase.results:
        return _results(c, session, active);
    }
  }

  List<Widget> _results(
    FcColors c,
    SessionController session,
    RestaurantRecommendation active,
  ) {
    final items = session.menuItems;
    final groups = <(String, MatchStatus)>[
      ('Fits you', MatchStatus.fits),
      ('Fits with a swap', MatchStatus.swap),
      ("Doesn't fit", MatchStatus.no),
    ];
    return [
      PrefSummaryCard(
        preferences: session.preferences,
        title: 'Checking against',
        style: PrefSummaryStyle.targets,
        onEdit: () => context.go('/'),
      ),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: FcIcon(FcIcons.info, size: 16, color: c.textSecondary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Macros are AI estimates from the menu, not lab values. Ask '
              'staff about allergies before you order.',
              style: FcText.caption.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
      for (final (title, status) in groups) ...[
        ..._group(c, session, active, title, status, items),
      ],
    ];
  }

  List<Widget> _group(
    FcColors c,
    SessionController session,
    RestaurantRecommendation active,
    String title,
    MatchStatus status,
    List<FoodItem> items,
  ) {
    final inGroup =
        items.where((item) => matchStatusFrom(item.matchStatus) == status);
    if (inGroup.isEmpty) {
      return const [];
    }
    return [
      const SizedBox(height: 20),
      Semantics(
        header: true,
        child: Text(
          '$title · ${inGroup.length}',
          style: FcText.tabular(FcText.heading).copyWith(
            color: c.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: FcSpace.s3),
      for (final item in inGroup) ...[
        FoodItemCard(
          item: item,
          favorite: session.isFavoriteMeal(active.name, item.name),
          onFavorite: () => _guarded(
            () => session.toggleFavoriteMeal(active, item),
          ),
        ),
        const SizedBox(height: FcSpace.s3),
      ],
    ];
  }
}
