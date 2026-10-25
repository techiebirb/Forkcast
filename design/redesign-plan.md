# Forkcast redesign — implementation plan

## Context

The Claude Design canvas "Forkcast app redesign" (https://claude.ai/artifact/2gE4kXZa8PyoY14xHQuTnJ) defines a new look for Forkcast: ~66 phone artboards (every screen in light + dark, including loading/empty/error states), a logo board, a shared-components board, a user-flow board, and an installed **Forkcast design system** (`project/ds/forkcast/tokens.json`, `components/bundle.css`, plus `project/forkcast-app.css`).

Today the Flutter app (`mobileapp/`) and Flask website (`flaskServer/`) use an older light-only palette (forest green on cream, Georgia serif, 12px-radius buttons) with hardcoded hex values and no dark mode. The good news: the app already has every screen in the design and the same routes (`/starting`, `/login`, `/signup`, `/`, `/search-restaurants`, `/pick-restaurant`, `/check-restaurant`, `/saved`), and the data the new screens need (match status/reason, allergens, diet flags, price, source, price level, walk time, distance, rating, open-now, `targetsPer`) is **already parsed in `mobileapp/lib/models.dart` and returned by the server, just never shown**. So this is mostly a reskin + surfacing existing data + new states, with very little backend work.

**Decisions (from you):** website gets a full reskin **plus a new Saved page**; theme **follows the device setting** (no toggle); work ships as **phased commits** on `claude/keen-faraday-upl1xi`.

## Design system summary (source of truth)

- **Colors:** 29 semantic tokens with light/dark values — `bg #f6f5f1/#151412`, `surface`, `surface-raised`, `surface-sunken`, `border`, `border-strong`, `text-primary/secondary/disabled`, `accent #3b6b4d/#8cbe9b` (herb green), `accent-pressed`, `accent-soft`, `on-accent`, `success` (Fits you), `warning` (Fits with a swap), `danger` (Doesn't fit / allergens), `info` (Verified by restaurant), `*-soft` fills, `scrim`, `map-land/road/park/water`.
- **Type:** Plus Jakarta Sans only (variable 200–800). Scale: display 32/40 700, title 24/32 700, heading 18/24 600, body 16/24, body-sm 14/20, label 14/20 600, caption 13/18 500. Tabular numerals on every number.
- **Space** 4/8/12/16/20/24/32/48 · **Radius** 6 / 12 input / 16 card / 24 sheet / pill for anything tappable · **Shadows** only on sheets and pins · **Touch targets** ≥44 · **Motion** 120ms / 280ms, `cubic-bezier(0.2,0,0,1)`, off under reduced motion.
- **Icons:** Phosphor (bookmark-simple, caret-left/right, check, fork-knife, bowl-food, info, magnifying-glass, map-pin, person-simple-walk, storefront, user, warning, x, x-circle, acorn, shrimp, fish, egg, cheese, bread) + a few inline SVGs (star, filled bookmark, trash, cloud-off).
- **Components** (from `bundle.css` / board "Shared components"): Button (primary/secondary/ghost/destructive/icon, lg, block), AppBar, Card, RestaurantCard, MenuItem card, MatchBadge (fits/swap/no), MacroChip (neutral, target, missing), DietTag (preference/allergy/severe), ConfidenceLabel (restaurant/description), FilterChip, Segmented control, Switch, TextField, Search box, BottomSheet, Map pin, Skeleton/ListState, State view (empty/error), Progress bar, Spinner, Steps list, Waking banner.

## Phase 0 — Pull design assets into the repo

1. Export from the canvas: `forkcast-app.css`, `ds/forkcast/components/bundle.css`, `tokens.json` (already downloaded to the scratchpad by the planning session; re-read with the Artifact tool if missing), and the logo SVG paths from `Logo.dc.html`.
2. Fonts: add `PlusJakartaSans-Variable.ttf` (Google Fonts, OFL) to `mobileapp/assets/fonts/` and the `.woff2` to `flaskServer/static/fonts/`.
3. Logo: save `forkcast-mark.svg`, `forkcast-icon-light.svg`, `forkcast-icon-dark.svg` to `mobileapp/assets/brand/` and `flaskServer/static/brand/`.
4. Keep `tokens.json` in the repo at `design/tokens.json` as the single source; both platforms' token files are hand-copied from it (header comment says so).

## Phase 1 — App foundation (`mobileapp/`)

- `pubspec.yaml`: add `fonts:` (Plus Jakarta Sans), `assets:` (brand), deps `phosphor_flutter`, `flutter_svg`; dev dep `flutter_launcher_icons`.
- **Replace `lib/app_theme.dart`** with `lib/theme/`:
  - `tokens.dart` — `FcColors extends ThemeExtension<FcColors>` with every color token, `FcColors.light` / `FcColors.dark`, `lerp`; plus `FcSpace`, `FcRadius`, `FcDuration`, `fcEase` constants.
  - `app_theme.dart` — `buildAppTheme(Brightness)` → `ThemeData` with: `ColorScheme` mapped from tokens (primary=accent, surface=surface, error=danger…), `textTheme` from the type scale (`fontFeatures: [FontFeature.tabularFigures()]` via a `FcText.num` helper), pill `FilledButton`/`OutlinedButton`/`TextButton` themes (min 44, lg 52), `InputDecorationTheme` (radius 12, `surface-raised` fill, `border-strong` edge, accent/danger focus), `CardTheme` (radius 16, hairline `border`, no elevation), `SegmentedButtonTheme`, `SwitchTheme`, `ChipTheme`, `BottomSheetTheme` (radius 24 top, `shadow-raised`), `SnackBarTheme`, `ProgressIndicatorTheme`, `AppBarTheme` (bg, no elevation, title 20/700).
  - `context.fc` extension for quick token access.
- `lib/app.dart` (`MenuApp`): pass `theme: buildAppTheme(light)`, `darkTheme: buildAppTheme(dark)`, `themeMode: ThemeMode.system`. Remove `Colors.white`/`black38`/`kAccent` hardcodes in `_WakingBanner` and `LoadingBarrier`.
- **Shared widgets** in `lib/widgets/` (one file each, mirroring the design components): `match_badge.dart`, `macro_chip.dart`, `diet_tag.dart`, `confidence_label.dart`, `price_level.dart`, `meta_line.dart` (cuisine · $$ · walk · distance), `restaurant_card.dart`, `menu_item_card.dart`, `prefs_summary_card.dart` ("Matching your preferences / Edit"), `state_view.dart` (empty/error with icon, title, body, action), `skeleton.dart` (pulse, static under reduced motion), `fc_progress.dart`, `steps_list.dart`, `forkcast_logo.dart` (SVG mark + wordmark), `fav_button.dart` (star / bookmark, `aria-pressed` → `Semantics(toggled:)`).
- Delete the duplicated `_MacroChip` in `check_screen.dart` and `saved_screen.dart` in favor of the shared one.

## Phase 2 — App screens (one commit per group)

Each screen: match the Light/Dark artboards; replace any hardcoded `Color(0x…)` with tokens.

| Screen file | Artboards | Notable changes |
|---|---|---|
| `screens/startup_screen.dart` + `_WakingBanner` in `app.dart` | Startup-Connecting/Waking/LongWait/Error, Banner-Home/Check | Logo mark; 0–3s spinner → waking with `FcProgress` toward 95% over 60s + elapsed counter → long-wait copy after 90s → error with Try again. Banner = accent strip docked above app bar, slides in 280ms, `IgnorePointer`, polite live region (counter announced every 15s). Timing already exists in `api_client.dart` `serverWaking`. |
| `login_screen.dart`, `signup_screen.dart` | Login, Login-Error, Signup, Signup-Error | No card wrapper; "Forkcast" wordmark, display headline, labeled fields, Show password toggle, inline field error (danger border + message) instead of snackbar. Signup-Error shows username **suggestions** (server already returns `suggestions` on 409 — surface them in `ApiException`). |
| `home_screen.dart` | Home-Empty, Home-Filled | App bar: "Forkcast" + Saved + Account icon buttons (account → sheet with username + Log out). "Your preferences" + saved hint. **Per meal / Per day** segmented control wired to `targetsPer` (currently dropped in `_fromForm` at `home_screen.dart:84-108` — fix). Macro card with 4 numeric fields (cal/protein/carbs/fat) + "More targets" disclosure for fiber/sugar (kept, not in design's main card). Halal/Kosher switches. Allergies: add-field + FilterChips (preset common allergens + custom) replacing the comma text field. Sticky footer: summary line + primary "Search restaurants" + secondary "Check a specific restaurant". |
| `search_screen.dart` | Search-Loading/Results/Empty/Error | App bar "Places for you" + "Near …" subtitle. `PrefsSummaryCard`. "N places · best fit first". `RestaurantCard` (thumb icon, name, star, meta line with price level/walk/distance, why-it-matches, secondary "Check this restaurant"). Skeleton loading, empty and error `StateView`s. |
| `map_pick_screen.dart` | Map-Searching/Results/Error | Floating search bar (back + search box + clear). Google Map with **custom style JSON** built from `map-*` tokens (light + dark, switched on brightness) and **custom numbered pin markers** (render `fc-pin` widget → `BitmapDescriptor`; selected = accent). Results in a `DraggableScrollableSheet` styled as `fc-sheet` (grab handle, "N results", rows with rating · Open/Closed until · distance, chevron). Error state in sheet. |
| `check_screen.dart` | Check-Loading/Results/NoMenu/Error | Header: title + star, meta line, address, Google Maps / Website / DoorDash secondary buttons. "Checking against" card (target macro chips, Halal tag, allergy DietTags, Edit link). AI disclaimer line. **Grouped by match**: "Fits you · N", "Fits with a swap · N", "Doesn't fit · N" (server already sorts). `MenuItemCard`: name, price, bookmark, description, macro chips (missing → dashed "fat not listed"), allergen tags, MatchBadge + reason, ConfidenceLabel. Loading = steps list ("Found the menu", "Estimating macros", "Checking <allergies>", "Checking halal") advanced on a timer while the request runs + skeleton cards (replaces `LoadingBarrier` here). |
| `saved_screen.dart` | Saved-Favorites/FavRestaurantsOnly/FavEmpty/Loading/Error/History/HistoryEmpty/ClearConfirm | Replace the AppBar `TabBar` with a segmented Favorites/History control under the app bar. Sections "Restaurants · N", "Meals · N", footer "Newest first · up to 100 favorites". History rows; "Clear history" (only when non-empty) → confirmation bottom sheet with destructive button. Loading skeleton + error StateView. |

## Phase 3 — App icon & splash

- `flutter_launcher_icons` config using `forkcast-icon-light.svg` → PNG 1024 (adaptive icon: accent bg + on-accent mark). Replace `android/.../mipmap-*` and `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
- Launch background `#f6f5f1` / dark `#151412` (`launch_background.xml`, `values-night`, `LaunchScreen.storyboard`).

## Phase 4 — Website foundation (`flaskServer/`)

- **New `templates/base.html`** — the shared `<head>` (viewport, title block, font preload, `tokens.css`, `components.css`, favicon from logo), app bar block, `{% block content %}`, waking-banner slot. Convert every page to `{% extends "base.html" %}` (no shared base exists today).
- **Drop Bootstrap** (CDN CSS + JS used only for the loader modal).
- **`static/tokens.css`** — copy `forkcast-app.css` `:root` token block; light by default, dark under `@media (prefers-color-scheme: dark)`; `@font-face` for local Plus Jakarta Sans.
- **`static/components.css`** — port `bundle.css` (`.fc-*`) and `forkcast-app.css` (`.fa-*`) classes verbatim-ish; they are already plain CSS, so the templates can use the same class names as the artboards. Replace `static/style.css` (keep only layout glue: `.page` container, responsive grid).
- **Layout:** phone width = the artboard layout; ≥768px = centered `max-width: 720px` column, search/saved restaurant cards in a 2-column grid at ≥1024px.
- **Icons:** `static/icons.svg` sprite of the Phosphor icons listed above (MIT) + the inline extras; `templates/_icon.html` macro `icon(name, size)`.
- **Jinja partials** mirroring app widgets: `_match_badge.html`, `_macro_chip.html`, `_diet_tag.html`, `_restaurant_card.html`, replace `_food_item_card.html` with `_menu_item_card.html`, `_state.html`, `_appbar.html` (replaces `_nav.html`).
- Replace `_gemini_loader.html` modal with the design's **steps loading card** (shown on submit, plain JS, no Bootstrap).
- Delete dead `templates/results.html`.

## Phase 5 — Website pages reskin

| Template | Route (`main.py`) | Changes |
|---|---|---|
| `login.html`, `signup.html` | `/login` :370, `/signup` :382, `/api/*` :393/:437 | Match Login/Signup artboards; inline errors; show signup `suggestions` (already passed on 409). |
| `home.html` | `/` :1150 | Home artboard: Per meal/day segmented radios (`targets_per`), 4 macro fields + "More targets" `<details>` (fiber/sugar), Halal/Kosher switches, allergy chips (checkbox chips + add field), keep the website-only Restaurant select/type card styled as a card, footer buttons. Keep existing geolocation JS. |
| `search_restaurants.html` | `/search-restaurants` :1169 | Search-Results artboard; skeleton/empty/error states. |
| `check_restaurant.html` | `/check-restaurant` :1275 | Check-Results artboard, grouped by match; NoMenu and Error states; keep the restaurant switcher. |

Pass the extra fields the templates now need from `main.py` (price level, walk/distance, match fields — already on the pydantic models, just make sure they reach the template context).

## Phase 6 — Website Saved page

- `main.py`: add `GET /saved` HTML route rendering `templates/saved.html` (reuse the payload builder behind `GET /api/saved` :1079). Tabs via `?tab=favorites|history`.
- Favorite buttons on search/check/saved pages: small `static/app.js` that POSTs JSON to existing `/api/favorites/restaurants` :1084 and `/api/favorites/meals` :1115 and toggles `aria-pressed`; `<form>` fallback without JS.
- Clear history: `<dialog>` confirm → POST `/api/history/clear` :1144.
- History row → `/check-restaurant` reusing saved results (check how the app reopens history without a new Gemini call in `session.dart` and mirror it server-side, e.g. `?history=<id>`).
- Add Saved icon link to the app bar.

## Verification

- **Flask:** run `python3 flaskServer/main.py` locally (needs the env vars from Render: Mongo URI, Gemini/Places keys — or stub). With the preinstalled Playwright, screenshot every page at 390×844 and 1280×800, in `colorScheme: 'light'` and `'dark'`, and compare side by side with the matching artboards. Check no console errors, no horizontal scroll at 390px, keyboard focus ring visible, contrast spot checks.
- **Flutter:** Flutter SDK is **not installed in this cloud container**, so `flutter analyze`, `flutter test`, and running on a device must happen on your machine (or we add a setup script installing Flutter). Add widget tests in `mobileapp/test/` for the shared widgets (MatchBadge, MacroChip, RestaurantCard, MenuItemCard) pumped in both themes, plus a golden test per screen state if you want pixel checks. Manually: toggle device dark mode, enable large text (200%) and reduce-motion, walk the flow Startup → Login → Home → Search / Map / Saved → Check.
- Each phase is its own commit; push to `claude/keen-faraday-upl1xi` after each phase passes its checks.

## Assumptions / open items

- Fiber and sugar targets stay (under "More targets"), since the server and models use them even though the design's Home card shows four.
- The design's map is illustrated; the app keeps real Google Maps, restyled with the design's map colors and pins. The website keeps its restaurant select/type field (no map), as today.
- The check-loading steps are cosmetic (timed), since the server returns one response with no progress events.
- Plus Jakarta Sans and Phosphor icons are open-source (OFL / MIT), fine to bundle.
