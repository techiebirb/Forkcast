import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _busy = false;

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

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final restaurants = session.restaurants;
    final prefs = session.preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('Search restaurants')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved preferences', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _PrefRow('Calories', prefs.calories?.toString() ?? 'Any'),
                      _PrefRow('Proteins', prefs.proteins == null ? 'Any' : '${prefs.proteins} g'),
                      _PrefRow('Carbs', prefs.carbs == null ? 'Any' : '${prefs.carbs} g'),
                      _PrefRow('Fat', prefs.fat == null ? 'Any' : '${prefs.fat} g'),
                      _PrefRow('Fiber', prefs.fiber == null ? 'Any' : '${prefs.fiber} g'),
                      _PrefRow('Sugar', prefs.sugar == null ? 'Any' : '${prefs.sugar} g'),
                      _PrefRow('Halal', prefs.halal ? 'Yes' : 'No'),
                      _PrefRow('Kosher', prefs.kosher ? 'Yes' : 'No'),
                      _PrefRow('Allergies', prefs.allergies.isEmpty ? 'None' : prefs.allergies.join(', ')),
                      _PrefRow(
                        'Location',
                        (prefs.latitude != null && prefs.longitude != null)
                            ? '${prefs.latitude}, ${prefs.longitude}'
                            : 'Not provided',
                      ),
                    ],
                  ),
                ),
              ),
              if (restaurants.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SkeletonLine(),
                        const SizedBox(height: 10),
                        const _SkeletonLine(width: 220),
                        const SizedBox(height: 10),
                        const _SkeletonLine(width: 160),
                        const SizedBox(height: 16),
                        Text(
                          'No restaurant results yet. Submit Search Restaurants from preferences.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...restaurants.map(
                  (restaurant) => Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(restaurant.name, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (restaurant.cuisine.isNotEmpty) restaurant.cuisine,
                              restaurant.address.isEmpty ? 'Address unavailable' : restaurant.address,
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          Text(restaurant.whyItMatches),
                          if (restaurant.possibleIdeas.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'What might work: ${restaurant.possibleIdeas}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: _busy ? null : () => _check(restaurant),
                            child: const Text('Check this restaurant'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_busy) const LoadingBarrier(message: 'Loading information...'),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2D8C8),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
