import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp/models.dart';
import 'package:mobileapp/theme/app_theme.dart';
import 'package:mobileapp/theme/tokens.dart';
import 'package:mobileapp/widgets/widgets.dart';

Widget _wrap(Widget child, Brightness b) => MaterialApp(
      theme: buildAppTheme(b),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: 358, child: child),
        ),
      ),
    );

final _item = FoodItem(
  name: 'Lamb Seekh Kebab Wrap',
  description: 'Spiced lamb kebab in sesame-topped naan.',
  calories: 720,
  proteins: 38,
  carbs: 60,
  fat: 0,
  price: r'$14.00',
  matchStatus: 'swap',
  matchReason: 'Ask for plain naan to skip the sesame.',
  allergens: const ['Sesame'],
);

void main() {
  for (final b in Brightness.values) {
    group('$b', () {
      testWidgets('theme exposes design tokens', (t) async {
        await t.pumpWidget(_wrap(const SizedBox(), b));
        final ctx = t.element(find.byType(Scaffold));
        final c = ctx.fc;
        expect(c, b == Brightness.dark ? FcColors.dark : FcColors.light);
        expect(Theme.of(ctx).scaffoldBackgroundColor, c.bg);
      });

      testWidgets('match badges show words for every status', (t) async {
        await t.pumpWidget(_wrap(
          const Column(children: [
            MatchBadge(status: 'fits'),
            MatchBadge(status: 'swap'),
            MatchBadge(status: 'no'),
          ]),
          b,
        ));
        expect(find.text('Fits you'), findsOneWidget);
        expect(find.text('Fits with a swap'), findsOneWidget);
        expect(find.text("Doesn't fit"), findsOneWidget);
      });

      testWidgets('menu item card renders macros, allergen and reason',
          (t) async {
        await t.pumpWidget(_wrap(
          MenuItemCard(item: _item, saved: false, onSave: () {}),
          b,
        ));
        expect(find.textContaining('720', findRichText: true), findsOneWidget);
        expect(find.text('fat not listed'), findsOneWidget);
        expect(find.text('Contains sesame'), findsOneWidget);
        expect(find.text('Fits with a swap'), findsOneWidget);
        expect(find.text('Based on menu description'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('restaurant card toggles favorite', (t) async {
        var taps = 0;
        await t.pumpWidget(_wrap(
          RestaurantCard(
            restaurant: RestaurantRecommendation(
              name: 'Saffron & Salt',
              address: '112 E 14th St',
              cuisine: 'Indian',
              whyItMatches: 'Halal kitchen.',
              priceLevel: 2,
              walkMinutes: 11,
              distanceMiles: 0.5,
            ),
            favorite: false,
            onFavorite: () => taps++,
            onCheck: () {},
          ),
          b,
        ));
        await t.tap(find.byType(FavButton));
        expect(taps, 1);
        expect(find.text('Check this restaurant'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('states and logo render', (t) async {
        await t.pumpWidget(_wrap(
          const Column(children: [
            ForkcastWordmark(),
            StateView(title: 'Nothing matched', body: 'Try again', error: true),
            FcProgress(value: 0.5),
            StepsList(steps: [
              ('Found the menu', FcStep.done),
              ('Estimating macros', FcStep.current),
              ('Checking halal', FcStep.waiting),
            ]),
            SkeletonList(rows: 2),
          ]),
          b,
        ));
        await t.pump(const Duration(milliseconds: 200));
        expect(find.text('Nothing matched'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    });
  }
}
