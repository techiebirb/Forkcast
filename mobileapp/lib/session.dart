import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';

class SessionController extends ChangeNotifier {
  SessionController(this.api) {
    api.sessionExpired.addListener(_onSessionExpired);
  }

  final ApiClient api;

  bool ready = false;
  bool authenticated = false;
  String? startupError;
  String? username;
  UserPreferences preferences = UserPreferences();
  List<RestaurantRecommendation> restaurants = [];
  List<FoodItem> menuItems = [];
  SavedData saved = SavedData();

  static String _key(String value) => value.trim().toLowerCase();

  bool isFavoriteRestaurant(String name) => saved.favoriteRestaurants
      .any((item) => _key(item.name) == _key(name));

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
    username = null;
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
      authenticated = await api.isAuthenticated();
      if (authenticated) {
        await refreshHome();
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
    preferences = home.preferences;
    restaurants = home.restaurants;
    saved = home.saved;
    authenticated = true;
    notifyListeners();
  }

  Future<void> login(String name, String password) async {
    username = await api.login(name, password);
    authenticated = true;
    await refreshHome();
  }

  Future<void> signup(String name, String password) async {
    username = await api.signup(name, password);
    authenticated = true;
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
        if (!restaurants.any((restaurant) => restaurant.name.trim() == chosen)) {
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
