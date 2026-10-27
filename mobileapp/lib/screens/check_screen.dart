import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/food_item_card.dart';
import 'history_screen.dart' show savedTimeLabel;

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
  CheckRequest? _request;

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
    _request = request;
    if (request == null) {
      final empty = SessionScope.of(context).menuItems.isEmpty;
      _phase = empty ? _CheckPhase.noMenu : _CheckPhase.results;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(request));
    }
  }

  Future<void> _load(CheckRequest request) async {
    final session = SessionScope.of(context);
    session.beginCheck(request.restaurant);
    setState(() => _phase = _CheckPhase.loading);
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

  Widget _header(
      FcColors c, SessionController session, RestaurantRecommendation r) {
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
              BookmarkToggle(
                name: r.name,
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
              if (r.doordashSearchUrl.isNotEmpty)
                FcButton(
                  label: 'Find on DoorDash',
                  variant: FcButtonVariant.secondary,
                  onPressed: () => _openLink(r.doordashSearchUrl),
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
            label: 'Checking the menu',
            child: const ListState(kind: ListStateKind.loading, rows: 3),
          ),
        ];
      case _CheckPhase.error:
        return [
          FcCard(
            child: ListState(
              kind: ListStateKind.error,
              title: "Couldn't check this menu",
              body: 'Check your connection and try again. The quick links '
                  'above still work.',
              actionLabel: _request == null ? null : 'Try again',
              onAction: _request == null ? null : () => _load(_request!),
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
    final reopened = _request == null ? session.reopenedFrom : null;
    return [
      if (reopened != null) ...[
        _FromHistoryBanner(
          when: savedTimeLabel(reopened.checkedAt),
          onCheckAgain: () {
            final request = CheckRequest(reopened.restaurant);
            _request = request;
            _load(request);
          },
        ),
        const SizedBox(height: 20),
      ],
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

/// Shown on a check reopened from History: when it happened, and a way to
/// run it again.
class _FromHistoryBanner extends StatelessWidget {
  const _FromHistoryBanner({required this.when, required this.onCheckAgain});

  final String when;
  final VoidCallback onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final style = FcText.bodySm.copyWith(color: c.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FcSpace.s4,
        vertical: FcSpace.s3,
      ),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(FcRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FcIcon(
                  FcIcons.clockCounterClockwise,
                  size: 20,
                  color: c.textPrimary,
                ),
                const SizedBox(width: FcSpace.s2),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: style,
                      children: [
                        TextSpan(
                          text: 'From your history. ',
                          style: style.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: '${when.isEmpty ? '' : 'Checked $when. '}'
                              'The menu or your preferences may have changed.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FcSpace.s3),
          FcButton(
            label: 'Check again',
            variant: FcButtonVariant.secondary,
            icon: FcIcons.arrowClockwise,
            onPressed: onCheckAgain,
          ),
        ],
      ),
    );
  }
}
