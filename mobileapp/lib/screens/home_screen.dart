import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../location.dart';
import '../models.dart';
import '../session.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_chips.dart';
import '../widgets/fc_form.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_logo.dart';
import '../widgets/fc_surfaces.dart';

/// Allergens offered as one-tap chips. The key is what is stored (lowercase).
const _commonAllergies = <(String, String, IconData?)>[
  ('peanuts', 'Peanuts', FcIcons.acorn),
  ('tree nuts', 'Tree nuts', FcIcons.acorn),
  ('shellfish', 'Shellfish', FcIcons.shrimp),
  ('fish', 'Fish', FcIcons.fish),
  ('egg', 'Egg', FcIcons.egg),
  ('dairy', 'Dairy', FcIcons.cheese),
  ('gluten', 'Gluten', FcIcons.bread),
];

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _calories = TextEditingController();
  late final TextEditingController _proteins = TextEditingController();
  late final TextEditingController _carbs = TextEditingController();
  late final TextEditingController _fat = TextEditingController();
  late final TextEditingController _fiber = TextEditingController();
  late final TextEditingController _sugar = TextEditingController();
  final TextEditingController _allergyInput = TextEditingController();

  late final List<TextEditingController> _macroControllers = [
    _calories,
    _proteins,
    _carbs,
    _fat,
    _fiber,
    _sugar,
  ];

  List<String> _allergies = [];
  String _targetsPer = 'meal';
  bool _halal = false;
  bool _kosher = false;
  bool _searching = false;

  /// True when preferences were already saved before this visit.
  bool _hadSaved = false;
  bool _loadedPrefs = false;

  @override
  void initState() {
    super.initState();
    for (final controller in _macroControllers) {
      controller.addListener(_onFormChanged);
    }
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
    _allergies = List.of(prefs.allergies);
    _targetsPer = prefs.targetsPer;
    _halal = prefs.halal;
    _kosher = prefs.kosher;
    _hadSaved = _hasAnyTarget;
  }

  @override
  void dispose() {
    for (final controller in _macroControllers) {
      controller.dispose();
    }
    _allergyInput.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _macroText(double? value) => value == null ? '' : fcNum(value);

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim());

  /// Something to search on: a macro target, a diet, or an allergy.
  bool get _hasAnyTarget =>
      _macroControllers.any((c) => _parse(c) != null) ||
      _halal ||
      _kosher ||
      _allergies.isNotEmpty;

  UserPreferences _fromForm(
    SessionController session, {
    String? latitude,
    String? longitude,
    String? restaurantName,
  }) {
    return UserPreferences(
      calories: _parse(_calories),
      proteins: _parse(_proteins),
      carbs: _parse(_carbs),
      fat: _parse(_fat),
      fiber: _parse(_fiber),
      sugar: _parse(_sugar),
      targetsPer: _targetsPer,
      halal: _halal,
      kosher: _kosher,
      allergies: _allergies,
      restaurantName: restaurantName ?? session.preferences.restaurantName,
      latitude: latitude ?? session.preferences.latitude,
      longitude: longitude ?? session.preferences.longitude,
    );
  }

  /// Gets the location, stores the form as the current preferences, and opens
  /// the results screen, which runs the search itself.
  Future<void> _search() async {
    if (_searching) {
      return;
    }
    final session = SessionScope.of(context);
    final router = GoRouter.of(context);
    setState(() => _searching = true);
    try {
      final coords = await requireLocation();
      session.setPreferences(
        _fromForm(session, latitude: coords.$1, longitude: coords.$2),
      );
      if (mounted) {
        router.push('/search-restaurants');
      }
    } catch (error) {
      if (mounted) {
        showApiError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _openMapPicker() {
    final session = SessionScope.of(context);
    session.setPreferences(_fromForm(session, restaurantName: ''));
    context.push('/pick-restaurant');
  }

  void _toggleAllergy(String key, bool selected) {
    setState(() {
      if (selected) {
        if (!_allergies.contains(key)) {
          _allergies = [..._allergies, key];
        }
      } else {
        _allergies = _allergies.where((item) => item != key).toList();
      }
    });
  }

  void _addAllergyFromInput() {
    final added = _allergyInput.text
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty && !_allergies.contains(item));
    if (added.isEmpty) {
      _allergyInput.clear();
      return;
    }
    setState(() {
      _allergies = [..._allergies, ...added];
      _allergyInput.clear();
    });
  }

  String get _summaryLine {
    final parts = <String>[];
    final cal = _parse(_calories);
    final protein = _parse(_proteins);
    if (cal != null) {
      parts.add('${fcNum(cal)} cal');
    }
    if (protein != null) {
      parts.add('${fcNum(protein)} g protein');
    }
    final others =
        [_carbs, _fat, _fiber, _sugar].where((c) => _parse(c) != null).length;
    if (others > 0) {
      parts.add('+$others ${others == 1 ? 'target' : 'targets'}');
    }
    if (_halal) {
      parts.add('Halal');
    }
    if (_kosher) {
      parts.add('Kosher');
    }
    if (_allergies.isNotEmpty) {
      parts.add(
        '${_allergies.length} ${_allergies.length == 1 ? 'allergy' : 'allergies'}',
      );
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final canSearch = _hasAnyTarget;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            const FcAppBar(
              showBack: false,
              titleWidget: FcWordmark(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s4,
                  FcSpace.s2,
                  FcSpace.s4,
                  FcSpace.s6,
                ),
                children: [
                  _header(c),
                  const SizedBox(height: FcSpace.s6),
                  _macrosSection(c),
                  const SizedBox(height: FcSpace.s6),
                  _dietSection(c),
                  const SizedBox(height: FcSpace.s6),
                  _allergySection(c),
                ],
              ),
            ),
            _footer(c, canSearch),
          ],
        ),
      ),
    );
  }

  Widget _header(FcColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            _hadSaved ? 'Your preferences' : 'Set up your preferences',
            style: FcText.title.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(height: FcSpace.s1),
        if (_hadSaved)
          Row(
            children: [
              FcIcon(FcIcons.check, size: 16, color: c.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Saved. We use these for every search.',
                  style: FcText.bodySm.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          )
        else
          Text(
            "Add what you're aiming for. We rank places and dishes by how "
            'close they get.',
            style: FcText.bodySm.copyWith(color: c.textSecondary),
          ),
      ],
    );
  }

  Widget _sectionTitle(FcColors c, String text) => Semantics(
        header: true,
        child: Text(text, style: FcText.heading.copyWith(color: c.textPrimary)),
      );

  Widget _macrosSection(FcColors c) {
    final rows = <(String, TextEditingController, String)>[
      ('Calories', _calories, 'cal'),
      ('Protein', _proteins, 'g'),
      ('Carbs', _carbs, 'g'),
      ('Fat', _fat, 'g'),
      ('Fiber', _fiber, 'g'),
      ('Sugar', _sugar, 'g'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: FcSpace.s3,
          children: [
            _sectionTitle(c, 'Macro targets'),
            SizedBox(
              width: 196,
              child: FcSeg(
                options: const ['Per meal', 'Per day'],
                selectedIndex: _targetsPer == 'day' ? 1 : 0,
                semanticLabel: 'Targets apply',
                onChanged: (index) => setState(
                  () => _targetsPer = index == 1 ? 'day' : 'meal',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: FcSpace.s3),
        FcCard(
          clip: true,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(color: c.border, height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FcSpace.s4,
                    FcSpace.s2,
                    FcSpace.s2,
                    FcSpace.s2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          rows[i].$1,
                          style: FcText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      FcNumberField(
                        controller: rows[i].$2,
                        unit: rows[i].$3,
                        semanticLabel: rows[i].$1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: FcSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: FcIcon(FcIcons.info, size: 16, color: c.textSecondary),
            ),
            const SizedBox(width: FcSpace.s2),
            Expanded(
              child: Text(
                'Leave a field as Any to skip it. Macros for each dish are '
                'estimates.',
                style: FcText.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dietRow(
    FcColors c, {
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FcSpace.s4,
        FcSpace.s3,
        FcSpace.s3,
        FcSpace.s3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ExcludeSemantics(
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
                    description,
                    style: FcText.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: FcSpace.s3),
          FcSwitch(
            value: value,
            onChanged: onChanged,
            semanticLabel: title,
          ),
        ],
      ),
    );
  }

  Widget _dietSection(FcColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'Dietary'),
        const SizedBox(height: FcSpace.s3),
        FcCard(
          clip: true,
          child: Column(
            children: [
              _dietRow(
                c,
                title: 'Halal',
                description: 'Only places that serve halal',
                value: _halal,
                onChanged: (value) => setState(() => _halal = value),
              ),
              Divider(color: c.border, height: 1, thickness: 1),
              _dietRow(
                c,
                title: 'Kosher',
                description: 'Only places that serve kosher',
                value: _kosher,
                onChanged: (value) => setState(() => _kosher = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _allergySection(FcColors c) {
    final commonKeys = _commonAllergies.map((item) => item.$1).toSet();
    final custom = _allergies.where((item) => !commonKeys.contains(item));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'Allergies'),
        const SizedBox(height: FcSpace.s1),
        Text(
          'We hide dishes that list these. Tap to add or remove.',
          style: FcText.bodySm.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: FcSpace.s3),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.only(left: FcSpace.s3, right: FcSpace.s1),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(FcRadius.input),
            border: Border.all(color: c.borderStrong),
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  textField: true,
                  label: 'Add an allergy',
                  child: TextField(
                    controller: _allergyInput,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addAllergyFromInput(),
                    cursorColor: c.accent,
                    style: FcText.body.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: 'Add another, like sesame',
                      hintStyle: FcText.body.copyWith(color: c.textSecondary),
                    ),
                  ),
                ),
              ),
              FcButton(
                label: 'Add',
                variant: FcButtonVariant.ghost,
                onPressed: _addAllergyFromInput,
              ),
            ],
          ),
        ),
        const SizedBox(height: FcSpace.s3),
        Wrap(
          spacing: FcSpace.s2,
          runSpacing: FcSpace.s2,
          children: [
            for (final (key, label, icon) in _commonAllergies)
              FcFilterChip(
                label: label,
                icon: icon,
                selected: _allergies.contains(key),
                onSelected: (selected) => _toggleAllergy(key, selected),
              ),
            for (final key in custom)
              FcFilterChip(
                label: _capitalize(key),
                selected: true,
                onSelected: (selected) => _toggleAllergy(key, selected),
              ),
          ],
        ),
      ],
    );
  }

  Widget _footer(FcColors c, bool canSearch) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        FcSpace.s4,
        FcSpace.s4,
        FcSpace.s4,
        FcSpace.s4,
      ),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: FcSpace.s2),
            child: Text(
              canSearch
                  ? _summaryLine
                  : 'Add a target or a dietary filter to search.',
              textAlign: TextAlign.center,
              style: FcText.tabular(FcText.caption).copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
          FcButton(
            label: 'Search restaurants',
            large: true,
            block: true,
            icon: FcIcons.magnifyingGlass,
            loading: _searching,
            onPressed: canSearch && !_searching ? _search : null,
          ),
          const SizedBox(height: FcSpace.s2),
          FcButton(
            label: 'Check a specific restaurant',
            large: true,
            block: true,
            variant: FcButtonVariant.secondary,
            icon: FcIcons.storefront,
            onPressed: _searching ? null : _openMapPicker,
          ),
        ],
      ),
    );
  }
}
