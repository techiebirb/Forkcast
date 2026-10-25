import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../location.dart';
import '../models.dart';
import '../session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _calories;
  late final TextEditingController _proteins;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _fiber;
  late final TextEditingController _sugar;
  late final TextEditingController _allergies;
  bool _halal = false;
  bool _kosher = false;
  bool _busy = false;
  String _busyMessage = 'Loading...';

  bool _loadedPrefs = false;

  @override
  void initState() {
    super.initState();
    _calories = TextEditingController();
    _proteins = TextEditingController();
    _carbs = TextEditingController();
    _fat = TextEditingController();
    _fiber = TextEditingController();
    _sugar = TextEditingController();
    _allergies = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedPrefs) {
      return;
    }
    _loadedPrefs = true;
    final prefs = SessionScope.of(context).preferences;
    _calories.text = _macroText(prefs.calories);
    _proteins.text = _macroText(prefs.proteins);
    _carbs.text = _macroText(prefs.carbs);
    _fat.text = _macroText(prefs.fat);
    _fiber.text = _macroText(prefs.fiber);
    _sugar.text = _macroText(prefs.sugar);
    _allergies.text = prefs.allergies.join(', ');
    _halal = prefs.halal;
    _kosher = prefs.kosher;
  }

  @override
  void dispose() {
    _calories.dispose();
    _proteins.dispose();
    _carbs.dispose();
    _fat.dispose();
    _fiber.dispose();
    _sugar.dispose();
    _allergies.dispose();
    super.dispose();
  }

  String _macroText(double? value) {
    if (value == null) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  UserPreferences _fromForm(
    SessionController session, {
    String? latitude,
    String? longitude,
    String? restaurantName,
  }) {
    return UserPreferences(
      calories: double.tryParse(_calories.text.trim()),
      proteins: double.tryParse(_proteins.text.trim()),
      carbs: double.tryParse(_carbs.text.trim()),
      fat: double.tryParse(_fat.text.trim()),
      fiber: double.tryParse(_fiber.text.trim()),
      sugar: double.tryParse(_sugar.text.trim()),
      halal: _halal,
      kosher: _kosher,
      allergies: _allergies.text
          .split(',')
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toList(),
      restaurantName: restaurantName ?? session.preferences.restaurantName,
      latitude: latitude ?? session.preferences.latitude,
      longitude: longitude ?? session.preferences.longitude,
    );
  }

  Future<void> _search() async {
    final session = SessionScope.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _busy = true;
      _busyMessage = 'Finding nearby restaurants...';
    });
    try {
      final coords = await requireLocation();
      final error = await session.searchRestaurants(
        _fromForm(session, latitude: coords.$1, longitude: coords.$2),
      );
      if (!mounted) {
        return;
      }
      if (error != null && error.isNotEmpty) {
        showApiError(context, error);
      }
      router.push('/search-restaurants');
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

  void _openMapPicker() {
    final session = SessionScope.of(context);
    session.setPreferences(_fromForm(session, restaurantName: ''));
    context.push('/pick-restaurant');
  }

  Future<void> _logout() async {
    await SessionScope.of(context).logout();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu preferences'),
        actions: [
          IconButton(
            tooltip: 'Saved',
            onPressed: () => context.push('/saved'),
            icon: const Icon(Icons.bookmark_border),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Signed in as ${session.username ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Set macro targets, then search nearby restaurants or pick one on the map.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Macros',
                hint: 'Optional targets. Leave blank for any.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MacroField(controller: _calories, label: 'Calories (kcal)'),
                    _MacroField(controller: _proteins, label: 'Proteins (g)'),
                    _MacroField(controller: _carbs, label: 'Carbs (g)'),
                    _MacroField(controller: _fat, label: 'Fat (g)'),
                    _MacroField(controller: _fiber, label: 'Fiber (g)'),
                    _MacroField(controller: _sugar, label: 'Sugar (g)'),
                  ],
                ),
              ),
              _SectionCard(
                title: 'Dietary restrictions',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Halal'),
                      value: _halal,
                      onChanged: (value) => setState(() => _halal = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kosher'),
                      value: _kosher,
                      onChanged: (value) => setState(() => _kosher = value),
                    ),
                  ],
                ),
              ),
              _SectionCard(
                title: 'Custom allergies',
                hint: 'Comma-separated. Values are stored in lowercase.',
                child: TextField(
                  controller: _allergies,
                  decoration: const InputDecoration(
                    labelText: 'Allergies',
                    hintText: 'e.g. peanuts, shellfish, garlic',
                  ),
                ),
              ),
              FilledButton(
                onPressed: _busy ? null : _search,
                child: const Text('Search restaurants'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _openMapPicker,
                child: const Text('Check a specific restaurant'),
              ),
            ],
          ),
          if (_busy) LoadingBarrier(message: _busyMessage),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.hint});

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MacroField extends StatelessWidget {
  const _MacroField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, hintText: 'Any'),
      ),
    );
  }
}
