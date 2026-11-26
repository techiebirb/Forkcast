# Forkcast

**Eat out without giving up your macros, your diet, or your allergy safety.**

Forkcast is a nutrition-aware restaurant finder. You tell it your macro targets, dietary restrictions and allergies. It finds real restaurants near you, then reads a restaurant's menu and sorts every dish into *fits you*, *fits with a swap*, or *doesn't fit*.

Forkcast was built for the Congressional App Challenge. The story behind it is in [Congressional App Question Answers](<Congressional App Question Answers.md>).

## Try it

**Download the latest release: https://github.com/techiebirb/Forkcast/releases/latest**

- **Android:** download the `.apk` and open it. You may need to allow installs from unknown sources.
- **iOS:** the `.ipa` is unsigned, so it has to be sideloaded (for example with AltStore or Sideloadly).
- No setup is needed. The app talks to the hosted server. If the server has been idle, the first launch can take up to about a minute while it wakes up, and the app shows a banner while it does.

## Features

- **Your targets:** calories, protein, carbs, fat, fiber and sugar, per meal or per day. Halal and kosher switches. One-tap allergy chips (peanuts, tree nuts, shellfish, fish, egg, dairy, gluten) plus any custom allergy you type.
- **Search restaurants:** uses your location. Google Places finds real restaurants within about 2 miles (it widens to 4 if there are fewer than 8). Gemini ranks them by how well they suit your diet and allergies, with a short "why it matches", and closer places get a boost.
- **Filters:** distance, price ($ to $$$$), open now, cuisine, and sort by fit, distance or price. Filtering happens on your device, so it's instant. "Search again" runs a new search with your filters applied.
- **Check a specific restaurant:** pick one on a Google Map (numbered pins, search box). Forkcast verifies with Google Places that it's an open food business.
- **Menu check:** Gemini, grounded with Google Search and Maps, returns 8 to 12 dishes with macros. Each dish gets a verdict, a one-line reason, which of *your* allergens it contains, diet warnings like "May not be halal", and whether the numbers were published by the restaurant or estimated from the menu description.
- **Order or visit:** quick links to Google Maps, the restaurant's website, and a DoorDash search.
- **Saved and History:** bookmark restaurants and individual dishes. Your last 20 checks are kept automatically. Reopen one, or tap "Check again".
- **Accounts:** sign up with an emailed 6-digit code, log in with a username or an email, reset your password by email. Older accounts without an email are asked to add and verify one.
- **Light, dark or system theme**, set in Settings and stored on the device.

> Macros are AI estimates from the menu, not lab values. Always ask restaurant staff about allergies before you order.

## How it works

```
 Flutter app ──HTTPS + session cookie──▶ Flask API (flaskServer/main.py)
                                            │
                  ┌─────────────┬───────────┼─────────────┐
                  ▼             ▼           ▼             ▼
           Google Places     Gemini      MongoDB        Brevo
           (real places)   (ranking +   (users, saved,  (verification
                            menu check)  history)        emails)
```

- **Places finds, Gemini ranks.** The restaurant list comes from Google Places, so every result is a real, open place. Gemini only ranks that list and writes the "why it matches" line. It is told not to invent menus or macros. If Gemini is overloaded, you still get the Places results, nearest first.
- **Macros come from one place.** Only the menu check estimates dish nutrition, and it prefers the restaurant's published nutrition facts when it can find them.
- **Gemini calls are resilient.** The server tries each model in `GEMINI_MODELS` in order, retries transient errors (503 and similar) with backoff, moves to the next model on quota errors, and pauses search/maps grounding for 10 minutes if a grounded call is rejected.
- **Everything is saved per user** in MongoDB: preferences, last results, bookmarks and history. Passwords are hashed, and verification codes are HMAC-hashed, expire after 15 minutes and allow 5 tries.
- **Two front ends, one backend.** The Flask routes serve JSON to the Flutter app. The same routes also render a basic web version with Jinja templates, but the app is the main client.

## Tech stack

| Part | Technology |
| --- | --- |
| App | Flutter, Dio with a persistent cookie jar, go_router, geolocator, google_maps_flutter, url_launcher |
| Design | Custom "Forkcast" design system, Plus Jakarta Sans, Phosphor icons, light and dark themes |
| Server | Python, Flask, gunicorn, Pydantic, requests |
| AI | Gemini through the `google-genai` SDK |
| Data | MongoDB (pymongo) |
| Places and maps | Google Places API (New), Google Maps |
| Email | Brevo HTTPS API |
| Hosting | Render |

## Repository layout

```
flaskServer/          Flask backend (single file: main.py)
  templates/          Jinja pages for the web version
  static/             CSS, JS, icon fonts for the web version
  Procfile            gunicorn start command for Render
  requirements.txt
mobileapp/            Flutter app
  lib/screens/        Home, search, check, map picker, saved, history, settings, auth
  lib/widgets/        Shared Forkcast components
  lib/theme/          Design tokens (colors, spacing, type)
  lib/api_client.dart Talks to the Flask API
  lib/session.dart    App state
.github/workflows/    iOS release build
```

## Run it yourself

You only need this if you want to develop Forkcast. To just try the app, see [Try it](#try-it).

### Server

You need Python 3, a MongoDB database, a Gemini API key and a Google Maps API key with the Places API (New) enabled.

```
cd flaskServer
python -m venv venv
venv\Scripts\activate          # macOS/Linux: source venv/bin/activate
pip install -r requirements.txt
python main.py                 # http://localhost:8080
```

Put your settings in `flaskServer/.env`:

| Variable | Purpose |
| --- | --- |
| `GEMINI_API_KEY` | Required for restaurant search and menu checks. |
| `GEMINI_MODELS` | Optional comma-separated models, tried in order. Default: `gemini-3.5-flash-lite,gemini-3.1-flash-lite,gemini-3.5-flash`. |
| `MONGO_URI` | Required for signup, login and all saved data. |
| `MONGO_DB_NAME` | Optional. Default: `nutrition_app`. |
| `GOOGLE_MAPS_API_KEY` | Required for Places search. In development it also falls back to `mobileapp/android/local.properties`. |
| `FLASK_SECRET_KEY` | Required in production. Development uses an insecure fallback key. |
| `BREVO_API_KEY`, `MAIL_FROM_EMAIL`, `MAIL_FROM_NAME` | Verification and reset emails. Required in production. Without a Brevo key in development, codes are printed in the server log. `MAIL_FROM_NAME` defaults to `Forkcast`. |
| `APP_ENV` | Set to `production` for secure cookies and strict startup checks. |
| `PORT` | Optional. Default: `8080`. |

In production, run it the way the `Procfile` does:

```
gunicorn -w 2 -t 180 -b 0.0.0.0:$PORT main:app
```

### App

```
cd mobileapp
flutter pub get
flutter run                                   # uses the hosted server
flutter run --dart-define=LOCAL_SERVER=true   # uses your local server
flutter run --dart-define=API_BASE_URL=http://<host>:8080   # any server
```

`LOCAL_SERVER=true` uses `10.0.2.2:8080` on the Android emulator and `127.0.0.1:8080` everywhere else.

The map screen needs a Google Maps key. On Android, set `GOOGLE_MAPS_API_KEY` in `mobileapp/android/local.properties` or as an environment variable. On iOS, set a `GOOGLE_MAPS_API_KEY` build setting, which `Info.plist` reads.

```
flutter analyze
flutter test
```

## Releases

Publishing a GitHub release runs the [iOS release workflow](.github/workflows/ios-release.yml), which builds an unsigned IPA against the hosted server and attaches it to the release.

## Credits

Forkcast was built by [techiebirb](https://github.com/techiebirb). Claude Code helped with debugging and planning, and Claude Design produced the look and feel. The backend, the email system, the database setup and the core of the app were written by hand. Details are in the [question answers](<Congressional App Question Answers.md>).

Fonts and icons: [Plus Jakarta Sans](mobileapp/assets/fonts/OFL.txt) (SIL OFL) and [Phosphor Icons](mobileapp/assets/fonts/Phosphor-LICENSE.txt) (MIT).

## License

[MIT](LICENSE) © 2026 techiebirb
