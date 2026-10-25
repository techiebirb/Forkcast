import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../models.dart';
import '../session.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await SessionScope.of(context).refreshSaved();
      } catch (error) {
        if (mounted) {
          showApiError(context, error);
        }
      }
    });
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

  Future<void> _check(RestaurantRecommendation restaurant) async {
    final session = SessionScope.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final error = await session.checkRestaurant(
        session.preferences.copyWith(restaurantName: restaurant.name),
      );
      if (!mounted) {
        return;
      }
      if (error != null && error.isNotEmpty) {
        showApiError(context, error);
      }
      router.push('/check-restaurant');
    } catch (error) {
      if (mounted) {
        showApiError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _openHistory(HistoryEntry entry) {
    SessionScope.of(context).openHistoryEntry(entry);
    context.push('/check-restaurant');
  }

  Future<void> _confirmClear() async {
    final session = SessionScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('Your favorites will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(session.clearHistory);
    }
  }

  String _ago(DateTime? time) {
    if (time == null) {
      return '';
    }
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} h ago';
    }
    return '${diff.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final saved = session.saved;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved'),
          actions: [
            if (saved.history.isNotEmpty)
              IconButton(
                tooltip: 'Clear history',
                onPressed: _confirmClear,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Favorites'), Tab(text: 'History')],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _favorites(context, session),
                _history(context, session),
              ],
            ),
            if (_busy) const LoadingBarrier(message: 'Loading information...'),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _favorites(BuildContext context, SessionController session) {
    final saved = session.saved;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('Restaurants', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (saved.favoriteRestaurants.isEmpty)
          _empty(context, 'Star a restaurant from the search results to save it here.')
        else
          ...saved.favoriteRestaurants.map(
            (restaurant) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove from favorites',
                          onPressed: () => _run(
                            () => session.toggleFavoriteRestaurant(restaurant),
                          ),
                          icon: const Icon(Icons.star),
                        ),
                      ],
                    ),
                    if (restaurant.address.isNotEmpty)
                      Text(
                        restaurant.address,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : () => _check(restaurant),
                      child: const Text('Check this restaurant'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Meals', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (saved.favoriteMeals.isEmpty)
          _empty(context, 'Bookmark a menu item to keep its macros here.')
        else
          ...saved.favoriteMeals.map(
            (meal) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meal.item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove from favorites',
                          onPressed: () => _run(
                            () => session.toggleFavoriteMeal(
                              RestaurantRecommendation(
                                name: meal.restaurantName,
                                address: meal.restaurantAddress,
                              ),
                              meal.item,
                            ),
                          ),
                          icon: const Icon(Icons.bookmark),
                        ),
                      ],
                    ),
                    Text(
                      meal.restaurantName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MacroChip('Calories', meal.item.calories.toString()),
                        _MacroChip('Protein', '${meal.item.proteins} g'),
                        _MacroChip('Carbs', '${meal.item.carbs} g'),
                        _MacroChip('Fat', '${meal.item.fat} g'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _history(BuildContext context, SessionController session) {
    final saved = session.saved;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (saved.history.isEmpty)
          _empty(context, 'Restaurants you check will show up here so you can reopen them instantly.')
        else
          ...saved.history.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(entry.restaurant.name),
                subtitle: Text(
                  [
                    '${entry.menuItems.length} items',
                    _ago(entry.checkedAt),
                  ].where((part) => part.isNotEmpty).join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openHistory(entry),
              ),
            ),
          ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
