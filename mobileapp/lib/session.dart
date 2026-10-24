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
  String? username;
  UserPreferences preferences = UserPreferences();
  List<RestaurantRecommendation> restaurants = [];
  List<FoodItem> menuItems = [];

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
  }

  @override
  void dispose() {
    api.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  Future<void> bootstrap() async {
    api.ping(); // fire and forget: wakes a cold-started server
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

  Future<String?> searchRestaurants(UserPreferences next) async {
    final result = await api.searchRestaurants(next);
    preferences = result.preferences;
    restaurants = result.restaurants;
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
    return result.error;
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
