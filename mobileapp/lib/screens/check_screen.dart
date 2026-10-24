import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../models.dart';

class CheckScreen extends StatelessWidget {
  const CheckScreen({super.key});

  RestaurantRecommendation _activeRestaurant(
    String name,
    List<RestaurantRecommendation> restaurants,
  ) {
    final cleaned = name.trim();
    for (final restaurant in restaurants) {
      if (restaurant.name.trim() == cleaned) {
        return restaurant;
      }
    }
    return RestaurantRecommendation(name: cleaned);
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showApiError(context, 'Could not open that link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final prefs = session.preferences;
    final items = session.menuItems;
    final restaurants = session.restaurants;
    final active = _activeRestaurant(prefs.restaurantName, restaurants);

    return Scaffold(
      appBar: AppBar(title: const Text('Check a restaurant')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prefs.restaurantName.isEmpty
                        ? 'No restaurant selected'
                        : prefs.restaurantName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (active.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      active.address,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Menu items parsed with Gemini structured output.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _PrefRow('Calories', prefs.calories?.toString() ?? 'Any'),
                  _PrefRow(
                    'Proteins',
                    prefs.proteins == null ? 'Any' : '${prefs.proteins} g',
                  ),
                  _PrefRow(
                    'Carbs',
                    prefs.carbs == null ? 'Any' : '${prefs.carbs} g',
                  ),
                  _PrefRow('Fat', prefs.fat == null ? 'Any' : '${prefs.fat} g'),
                  _PrefRow(
                    'Fiber',
                    prefs.fiber == null ? 'Any' : '${prefs.fiber} g',
                  ),
                  _PrefRow(
                    'Sugar',
                    prefs.sugar == null ? 'Any' : '${prefs.sugar} g',
                  ),
                  _PrefRow('Halal', prefs.halal ? 'Yes' : 'No'),
                  _PrefRow('Kosher', prefs.kosher ? 'Yes' : 'No'),
                  _PrefRow(
                    'Allergies',
                    prefs.allergies.isEmpty
                        ? 'None'
                        : prefs.allergies.join(', '),
                  ),
                  if (active.name.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (active.googleMapsUrl.isNotEmpty)
                          OutlinedButton(
                            onPressed: () =>
                                _openLink(context, active.googleMapsUrl),
                            child: const Text('Google Maps'),
                          ),
                        if (active.website.isNotEmpty)
                          OutlinedButton(
                            onPressed: () =>
                                _openLink(context, active.website),
                            child: const Text('Website'),
                          ),
                        if (active.doordashUrl.isNotEmpty)
                          OutlinedButton(
                            onPressed: () =>
                                _openLink(context, active.doordashUrl),
                            child: const Text('DoorDash'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'No menu items yet. Pick a restaurant from the map to load its menu.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ...items.map((item) => _FoodCard(item: item)),
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
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            Text(item.quantity, style: Theme.of(context).textTheme.bodySmall),
            if (item.ingredients.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.ingredients.join(', ')),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MacroChip('Calories', item.calories.toString()),
                _MacroChip('Protein', '${item.proteins} g'),
                _MacroChip('Carbs', '${item.carbs} g'),
                _MacroChip('Fat', '${item.fat} g'),
                _MacroChip('Fiber', '${item.fiber} g'),
                _MacroChip('Sugar', '${item.sugar} g'),
              ],
            ),
          ],
        ),
      ),
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
