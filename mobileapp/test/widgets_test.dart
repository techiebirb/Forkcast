import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp/app_theme.dart';
import 'package:mobileapp/screens/history_screen.dart';
import 'package:mobileapp/widgets/fc_button.dart';
import 'package:mobileapp/widgets/fc_chips.dart';
import 'package:mobileapp/widgets/fc_form.dart';
import 'package:mobileapp/widgets/fc_icons.dart';
import 'package:mobileapp/widgets/fc_logo.dart';
import 'package:mobileapp/widgets/fc_surfaces.dart';
import 'package:mobileapp/widgets/fc_tab_bar.dart';
import 'package:mobileapp/widgets/fc_toggles.dart';

Widget _gallery() {
  final controller = TextEditingController(text: '650');
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const FcAppBar(
        title: 'Places for you',
        subtitle: 'Near you',
        subtitleIcon: FcIcons.mapPin,
      ),
      const FcWordmark(),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FcButton(label: 'Primary', onPressed: () {}),
          FcButton(
            label: 'Secondary',
            variant: FcButtonVariant.secondary,
            onPressed: () {},
          ),
          FcButton(
            label: 'Ghost',
            variant: FcButtonVariant.ghost,
            onPressed: () {},
          ),
          FcButton(
            label: 'Destructive',
            variant: FcButtonVariant.destructive,
            onPressed: () {},
          ),
          const FcButton(label: 'Disabled', onPressed: null),
          FcButton(label: 'Loading', loading: true, onPressed: () {}),
          FcButton(
            label: 'Account',
            variant: FcButtonVariant.ghost,
            iconOnly: true,
            icon: FcIcons.user,
            onPressed: () {},
          ),
        ],
      ),
      FcButton(
        label: 'Search restaurants',
        large: true,
        block: true,
        icon: FcIcons.magnifyingGlass,
        onPressed: () {},
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FcFilterChip(
              label: 'Peanuts', icon: FcIcons.acorn, onSelected: (_) {}),
          FcFilterChip(label: 'Shellfish', selected: true, onSelected: (_) {}),
          const DietTag(label: 'Halal'),
          const DietTag(label: 'No peanuts', kind: DietTagKind.allergy),
          const DietTag(label: 'Tree nuts', kind: DietTagKind.severe),
          const DietTag(label: 'Not kosher', kind: DietTagKind.conflict),
          const MatchBadge(status: MatchStatus.fits),
          const MatchBadge(status: MatchStatus.swap),
          const MatchBadge(status: MatchStatus.no, small: false),
        ],
      ),
      const ConfidenceLabel(verified: true),
      const ConfidenceLabel(verified: false, date: 'Oct 12'),
      const Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          MacroChip(value: '660', unit: 'cal'),
          MacroChip(value: '45 g', unit: 'protein', kind: MacroChipKind.target),
          MacroChip.missing('fat not listed'),
          MacroChip(value: '20 g', unit: 'fat', large: true),
        ],
      ),
      FcSeg(
        options: const ['Per meal', 'Per day'],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
      FcCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(child: Text('Saffron & Salt')),
            BookmarkToggle(pressed: true, onPressed: () {}),
            BookmarkToggle(pressed: false, onPressed: () {}),
          ],
        ),
      ),
      Row(
        children: [
          FcNumberField(
            controller: controller,
            unit: 'cal',
            semanticLabel: 'Calories',
          ),
          FcSwitch(value: true, onChanged: (_) {}, semanticLabel: 'Halal'),
          FcSwitch(value: false, onChanged: (_) {}, semanticLabel: 'Kosher'),
        ],
      ),
      const FcProgressBar(value: 0.58, semanticLabel: 'Waking up the server'),
      const ListState(kind: ListStateKind.loading, rows: 2),
      const ListState(
        kind: ListStateKind.empty,
        title: 'Nothing matched nearby',
        body: 'Try loosening your preferences.',
        actionLabel: 'Edit preferences',
      ),
      const ListState(
        kind: ListStateKind.error,
        title: "Couldn't load places",
        body: 'Check your connection and try again.',
        actionLabel: 'Try again',
      ),
      const FcLogoMark(size: 56),
    ],
  );
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'widget gallery renders without errors (${dark ? 'dark' : 'light'})',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? buildDarkTheme() : buildLightTheme(),
          home: Scaffold(body: SafeArea(child: _gallery())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Fits you'), findsOneWidget);
      expect(find.text("Doesn't fit"), findsOneWidget);
    });
  }

  test('fcNum drops a trailing .0', () {
    expect(fcNum(660), '660');
    expect(fcNum(12.0), '12');
    expect(fcNum(12.5), '12.5');
  });

  test('savedTimeLabel reads like the design', () {
    final now = DateTime(2026, 10, 25, 12, 0);
    expect(savedTimeLabel(now.subtract(const Duration(seconds: 20)), now: now),
        'just now');
    expect(savedTimeLabel(now.subtract(const Duration(minutes: 5)), now: now),
        '5 min ago');
    expect(savedTimeLabel(now.subtract(const Duration(hours: 2)), now: now),
        '2 h ago');
    // 2 hours ago but across midnight is still "2 h ago", not "Yesterday".
    final early = DateTime(2026, 10, 25, 1, 0);
    expect(
        savedTimeLabel(DateTime(2026, 10, 24, 23, 0), now: early), '2 h ago');
    expect(savedTimeLabel(DateTime(2026, 10, 24, 9, 0), now: now), 'Yesterday');
    expect(
        savedTimeLabel(DateTime(2026, 10, 22, 9, 0), now: now), '3 days ago');
    expect(savedTimeLabel(DateTime(2026, 10, 12, 9, 0), now: now), 'Oct 12');
    expect(savedTimeLabel(null, now: now), '');
  });

  test('history entries group by day', () {
    final now = DateTime(2026, 10, 25, 12, 0);
    expect(historyGroupLabel(DateTime(2026, 10, 25, 8, 0), now: now), 'Today');
    expect(historyGroupLabel(DateTime(2026, 10, 24, 23, 0), now: now),
        'Yesterday');
    expect(historyGroupLabel(DateTime(2026, 10, 22, 9, 0), now: now),
        'Earlier this week');
    expect(
        historyGroupLabel(DateTime(2026, 10, 12, 9, 0), now: now), 'Earlier');
    expect(historyGroupLabel(null, now: now), 'Earlier');
  });

  testWidgets('tab bar shows four labelled tabs and reports taps',
      (tester) async {
    FcTab? tapped;
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      tapped = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            bottomNavigationBar: FcTabBar(
              current: FcTab.saved,
              onSelect: (tab) => tapped = tab,
            ),
          ),
        ),
      );
      for (final label in ['Home', 'Saved', 'History', 'Settings']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('History'));
      expect(tapped, FcTab.history);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('theme control with icons renders in both themes',
      (tester) async {
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      var picked = -1;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: FcSeg(
              options: const ['System', 'Light', 'Dark'],
              icons: const [FcIcons.circleHalf, FcIcons.sun, FcIcons.moon],
              selectedIndex: 0,
              onChanged: (index) => picked = index,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Dark'));
      expect(picked, 2);
    }
  });
}
