import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';
import 'models.dart';

class SessionController extends ChangeNotifier {
  SessionController(this.api) {
    api.sessionExpired.addListener(_onSessionExpired);
  }

  final ApiClient api;

  bool ready = false;
  bool authenticated = false;

  /// Signed in, but an older account that still has to add and verify an email.
  bool needsEmail = false;
  String? startupError;
  String? username;
  String? email;

  /// Light, dark, or follow the phone. Kept on the device, not the account.
  ThemeMode themeMode = ThemeMode.system;

  /// Set while the Check screen shows a menu reopened from History, so it can
  /// say when the check happened. Cleared when a fresh check starts.
  HistoryEntry? reopenedFrom;
  UserPreferences preferences = UserPreferences();
  List<RestaurantRecommendation> restaurants = [];
  List<FoodItem> menuItems = [];
  SavedData saved = SavedData();

  static String _key(String value) => value.trim().toLowerCase();

  bool isFavoriteRestaurant(String name) =>
      saved.favoriteRestaurants.any((item) => _key(item.name) == _key(name));

  bool isFavoriteMeal(String restaurantName, String itemName) =>
      saved.favoriteMeals.any(
        (meal) =>
            _key(meal.restaurantName) == _key(restaurantName) &&
            _key(meal.item.name) == _key(itemName),
      );

  Future<void> refreshSaved() async {
    saved = await api.getSaved();
    notifyListeners();
  }

  Future<void> toggleFavoriteRestaurant(
    RestaurantRecommendation restaurant,
  ) async {
    saved = await api.setFavoriteRestaurant(
      restaurant,
      favorite: !isFavoriteRestaurant(restaurant.name),
    );
    notifyListeners();
  }

  Future<void> toggleFavoriteMeal(
    RestaurantRecommendation restaurant,
    FoodItem item,
  ) async {
    saved = await api.setFavoriteMeal(
      restaurant.name,
      restaurant.address,
      item,
      favorite: !isFavoriteMeal(restaurant.name, item.name),
    );
    notifyListeners();
  }

  Future<void> clearHistory() async {
    saved = await api.clearHistory();
    notifyListeners();
  }

  /// Shows a saved menu on the check screen without calling Gemini again.
  void openHistoryEntry(HistoryEntry entry) {
    reopenedFrom = entry;
    menuItems = entry.menuItems;
    rememberRestaurant(entry.restaurant);
    preferences = preferences.copyWith(restaurantName: entry.restaurant.name);
    notifyListeners();
  }

  void _onSessionExpired() {
    if (!api.sessionExpired.value || !authenticated) {
      return;
    }
    _clearLocal();
    notifyListeners();
  }

  void _clearLocal() {
    authenticated = false;
    needsEmail = false;
    username = null;
    email = null;
    reopenedFrom = null;
    preferences = UserPreferences();
    restaurants = [];
    menuItems = [];
    saved = SavedData();
    filters = const SearchFilters.none();
    cuisines = [];
  }

  @override
  void dispose() {
    api.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  Future<File?> _themeFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/theme_mode.txt');
    } catch (_) {
      return null;
    }
  }

  /// Reads the saved theme choice. Call before the first frame.
  Future<void> loadThemeMode() async {
    try {
      final file = await _themeFile();
      if (file != null && await file.exists()) {
        themeMode = switch ((await file.readAsString()).trim()) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }
    } catch (_) {
      // Fall back to following the phone.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    try {
      final file = await _themeFile();
      await file?.writeAsString(mode.name);
    } catch (_) {
      // The choice still applies for this session.
    }
  }

  Future<void> retryStartup() async {
    startupError = null;
    ready = false;
    notifyListeners();
    await bootstrap();
  }

  Future<void> bootstrap() async {
    // Wait out a Render cold start before touching the session, so a slow
    // wake-up is never mistaken for being signed out.
    final awake = await api.wakeIfIdle();
    if (!awake) {
      startupError = "Couldn't reach Forkcast. Check your connection and "
          'try again.';
      ready = true;
      notifyListeners();
      return;
    }
    try {
      final auth = await api.currentAuth();
      authenticated = auth != null;
      if (auth != null) {
        await _finishAuth(auth);
      }
    } catch (_) {
      authenticated = false;
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> refreshHome() async {
    final home = await api.getHome();
    username = home.username;
    email = home.email;
    preferences = home.preferences;
    restaurants = home.restaurants;
    saved = home.saved;
    authenticated = true;
    notifyListeners();
  }

  /// Records a successful sign-in, then loads the home data unless the
  /// account still has to add an email.
  Future<void> _finishAuth(AuthResult auth) async {
    username = auth.username;
    authenticated = true;
    needsEmail = auth.needsEmail;
    if (needsEmail) {
      notifyListeners();
      return;
    }
    await refreshHome();
  }

  /// [identifier] is a username or an email.
  Future<void> login(String identifier, String password) async =>
      _finishAuth(await api.login(identifier, password));

  Future<void> verifySignup(String email, String code) async =>
      _finishAuth(await api.verifySignup(email, code));

  Future<void> resetPassword(
    String identifier,
    String code,
    String newPassword,
  ) async =>
      _finishAuth(await api.resetPassword(identifier, code, newPassword));

  Future<void> verifyEmail(String email, String code) async {
    await api.verifyEmail(email, code);
    needsEmail = false;
    await refreshHome();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // Sign out locally even if the server can't be reached.
    } finally {
      await api.clearCookies();
      _clearLocal();
      notifyListeners();
    }
  }

  /// Search filters. The server returns the full pool, and the app narrows it
  /// here so changing a filter is instant.
  SearchFilters filters = const SearchFilters.none();
  List<String> cuisines = [];

  List<RestaurantRecommendation> get filteredRestaurants =>
      filters.apply(restaurants);

  void setFilters(SearchFilters next) {
    filters = next;
    notifyListeners();
  }

  /// [applyToSearch] runs a new Gemini search that takes [filters] into
  /// account, for when the current pool has nothing that fits.
  Future<String?> searchRestaurants(
    UserPreferences next, {
    bool applyToSearch = false,
  }) async {
    final result = await api.searchRestaurants(
      next,
      filters: filters,
      applyToSearch: applyToSearch,
    );
    preferences = result.preferences;
    restaurants = result.restaurants;
    cuisines = result.cuisines;
    notifyListeners();
    return result.error;
  }

  Future<String?> checkRestaurant(UserPreferences next) async {
    final remembered = List<RestaurantRecommendation>.from(restaurants);
    final result = await api.checkRestaurant(next);
    preferences = result.preferences;
    restaurants = result.restaurants;
    menuItems = result.menuItems;
    final chosen = next.restaurantName.trim();
    if (chosen.isNotEmpty) {
      final existing = remembered.where((item) => item.name.trim() == chosen);
      for (final item in existing) {
        if (!restaurants
            .any((restaurant) => restaurant.name.trim() == chosen)) {
          restaurants = [item, ...restaurants];
        }
      }
    }
    notifyListeners();
    if (menuItems.isNotEmpty) {
      refreshSaved().catchError((_) {});
    }
    return result.error;
  }

  /// Gets the Check screen ready to load [restaurant]: clears the previous
  /// menu and points the preferences at it. Keeps the restaurant in the
  /// remembered list (without reordering it if it is already there) so the
  /// header has its address and links while the menu loads.
  void beginCheck(RestaurantRecommendation restaurant) {
    final cleaned = restaurant.name.trim();
    reopenedFrom = null;
    menuItems = [];
    preferences = preferences.copyWith(restaurantName: cleaned);
    if (cleaned.isNotEmpty &&
        !restaurants.any((item) => item.name.trim() == cleaned)) {
      restaurants = [restaurant, ...restaurants];
    }
    notifyListeners();
  }

  void setPreferences(UserPreferences next) {
    preferences = next;
    notifyListeners();
  }

  void rememberRestaurant(RestaurantRecommendation restaurant) {
    final cleaned = restaurant.name.trim();
    if (cleaned.isEmpty) {
      return;
    }
    final next = [
      restaurant,
      ...restaurants.where((item) => item.name.trim() != cleaned),
    ];
    restaurants = next;
    notifyListeners();
  }

  Future<List<MapPlace>> searchPlaces({
    required double latitude,
    required double longitude,
    String query = '',
    int radiusMeters = 2500,
  }) {
    return api.searchPlaces(
      latitude: latitude,
      longitude: longitude,
      query: query,
      radiusMeters: radiusMeters,
    );
  }

  Future<MapPlace> verifyPlace(String placeId) {
    return api.verifyPlace(placeId);
  }
}
