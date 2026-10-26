import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.suggestions = const []});

  final String message;
  final int? statusCode;

  /// Free usernames the server offers when a signup name is already taken.
  final List<String> suggestions;

  @override
  String toString() => message;
}

class HomePayload {
  HomePayload({
    required this.username,
    required this.preferences,
    required this.restaurants,
    required this.saved,
  });

  final String? username;
  final UserPreferences preferences;
  final List<RestaurantRecommendation> restaurants;
  final SavedData saved;
}

class SearchPayload {
  SearchPayload({
    required this.preferences,
    required this.restaurants,
    this.filters = const SearchFilters.none(),
    this.cuisines = const [],
    this.error,
  });

  final UserPreferences preferences;
  final List<RestaurantRecommendation> restaurants;
  final SearchFilters filters;
  final List<String> cuisines;
  final String? error;
}

class CheckPayload {
  CheckPayload({
    required this.preferences,
    required this.menuItems,
    required this.restaurants,
    this.error,
  });

  final UserPreferences preferences;
  final List<FoodItem> menuItems;
  final List<RestaurantRecommendation> restaurants;
  final String? error;
}

class ApiClient {
  late final Dio _dio;
  late final CookieJar _cookieJar;

  /// Flips to true when the server rejects a request as unauthenticated
  /// after the user was signed in.
  final ValueNotifier<bool> sessionExpired = ValueNotifier(false);

  /// True while the server looks like it is cold-starting (Render free tier).
  final ValueNotifier<bool> serverWaking = ValueNotifier(false);

  static const _authPaths = {'/api/login', '/api/signup', '/login', '/healthz'};

  static const _sleepAfter = Duration(minutes: 14);
  static const _wakingDelay = Duration(seconds: 3);
  static const _wakeRetryEvery = Duration(seconds: 3);
  static const _wakeGiveUp = Duration(seconds: 120);

  DateTime? _lastResponseAt;
  Future<bool>? _warmup;

  bool get _maybeAsleep =>
      _lastResponseAt == null ||
      DateTime.now().difference(_lastResponseAt!) > _sleepAfter;

  bool get _onRender => apiBaseUrl.contains('onrender.com');

  /// Render's spin-up page comes from its proxy (HTML, 502/503, or missing the
  /// `x-render-origin-server` header our app always sets).
  bool _isWakeResponse(Response<dynamic> response) {
    if (!_onRender) {
      return false;
    }
    final status = response.statusCode ?? 0;
    if (status == 502 || status == 503) {
      return true;
    }
    final type = response.headers.value('content-type') ?? '';
    if (type.startsWith('text/html')) {
      return true;
    }
    return response.headers.value('x-render-origin-server') == null;
  }

  void _markAwake() {
    _lastResponseAt = DateTime.now();
    serverWaking.value = false;
  }

  /// Retries a request that hit Render's wake-up page until it succeeds or
  /// [_wakeGiveUp] passes.
  Future<void> _retryWhileWaking(
    RequestOptions options,
    Response<dynamic> wakeResponse,
    dynamic handler,
  ) async {
    serverWaking.value = true;
    final started = (options.extra['wakeStart'] as DateTime?) ?? DateTime.now();
    if (DateTime.now().difference(started) > _wakeGiveUp) {
      serverWaking.value = false;
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          message: 'The server is taking too long to start. '
              'Please try again in a moment.',
        ),
      );
      return;
    }
    await Future<void>.delayed(_wakeRetryEvery);
    options.extra['wakeStart'] = started;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (error) {
      serverWaking.value = false;
      handler.reject(error);
    }
  }

  Future<void> init() async {
    final supportDir = await getApplicationSupportDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${supportDir.path}/cookies'),
    );
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // After a long idle, ping /healthz first so the wait is shown as a
          // wake-up, not as a slow request.
          if (options.path != '/healthz') {
            await wakeIfIdle();
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final response = error.response;
          if (response != null && _isWakeResponse(response)) {
            _retryWhileWaking(error.requestOptions, response, handler);
            return;
          }
          handler.next(error);
        },
        onResponse: (response, handler) {
          if (_isWakeResponse(response)) {
            _retryWhileWaking(response.requestOptions, response, handler);
            return;
          }
          _markAwake();
          if (response.statusCode == 401 &&
              !_authPaths.contains(response.requestOptions.path)) {
            sessionExpired.value = true;
            sessionExpired.value = false;
          }
          handler.next(response);
        },
      ),
    );
  }

  /// Wakes up a sleeping cloud instance. Never throws.
  Future<bool> ping() async {
    try {
      final response = await _dio.get(
        '/healthz',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// If the server may be asleep (nothing heard for [_sleepAfter]), pings
  /// /healthz until it answers, flipping [serverWaking] on if that takes more
  /// than [_wakingDelay]. Concurrent callers share one wake-up. Returns false
  /// if the server never answered. Never throws.
  Future<bool> wakeIfIdle() {
    if (!_maybeAsleep) {
      return Future.value(true);
    }
    return _warmup ??= _wake().whenComplete(() => _warmup = null);
  }

  Future<bool> _wake() async {
    final timer = Timer(_wakingDelay, () => serverWaking.value = true);
    try {
      final deadline = DateTime.now().add(_wakeGiveUp);
      while (DateTime.now().isBefore(deadline)) {
        if (await ping()) {
          return true;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      return false;
    } finally {
      timer.cancel();
      serverWaking.value = false;
    }
  }

  Future<void> clearCookies() => _cookieJar.deleteAll();

  Never _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      throw ApiException(
        isProduction
            ? "Can't reach Forkcast right now. Check your connection and try again."
            : 'Could not reach the server at $apiBaseUrl. '
                'Is Flask running, and did you use the emulator host URL?',
      );
    }
    if (error.type == DioExceptionType.receiveTimeout) {
      throw ApiException(
        'This is taking longer than usual. Please try again in a moment.',
      );
    }
    final data = error.response?.data;
    if (data is Map) {
      final message = data['error']?.toString();
      if (message != null && message.isNotEmpty) {
        throw ApiException(message, statusCode: error.response?.statusCode);
      }
    }
    throw ApiException(
      error.message ?? 'Network request failed.',
      statusCode: error.response?.statusCode,
    );
  }

  Future<Response<dynamic>> _get(String path) async {
    try {
      return await _dio.get(path);
    } on DioException catch (error) {
      _mapDioError(error);
    }
  }

  Future<Response<dynamic>> _post(String path, {Object? data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (error) {
      _mapDioError(error);
    }
  }

  Future<bool> isAuthenticated() async {
    final response = await _get('/login');
    _throwIfServerError(response);
    if (response.statusCode == 401) {
      return false;
    }
    final data = _asMap(response.data);
    return data['authenticated'] == true;
  }

  Future<String> login(String username, String password) async {
    final response = await _post(
      '/api/login',
      data: {'username': username, 'password': password},
    );
    return _readUsername(response);
  }

  Future<String> signup(String username, String password) async {
    final response = await _post(
      '/api/signup',
      data: {'username': username, 'password': password},
    );
    return _readUsername(response);
  }

  Future<void> logout() async {
    final response = await _post('/api/logout');
    _throwIfError(response);
  }

  Future<HomePayload> getHome() async {
    final response = await _get('/');
    _throwIfError(response);
    final data = _asMap(response.data);
    return HomePayload(
      username: data['username']?.toString(),
      preferences: UserPreferences.fromJson(_asMap(data['preferences'])),
      restaurants: _restaurants(data['restaurants']),
      saved: SavedData.fromJson(_asMap(data['saved'])),
    );
  }

  Future<SavedData> getSaved() async {
    final response = await _get('/api/saved');
    _throwIfError(response);
    return SavedData.fromJson(_asMap(response.data));
  }

  Future<SavedData> setFavoriteRestaurant(
    RestaurantRecommendation restaurant, {
    required bool favorite,
  }) async {
    final response = await _post(
      '/api/favorites/restaurants',
      data: {
        'action': favorite ? 'add' : 'remove',
        'restaurant': restaurant.toJson(),
      },
    );
    _throwIfError(response);
    return SavedData.fromJson(_asMap(response.data));
  }

  Future<SavedData> setFavoriteMeal(
    String restaurantName,
    String restaurantAddress,
    FoodItem item, {
    required bool favorite,
  }) async {
    final response = await _post(
      '/api/favorites/meals',
      data: {
        'action': favorite ? 'add' : 'remove',
        'restaurant_name': restaurantName,
        'restaurant_address': restaurantAddress,
        'item': item.toJson(),
      },
    );
    _throwIfError(response);
    return SavedData.fromJson(_asMap(response.data));
  }

  Future<SavedData> clearHistory() async {
    final response = await _post('/api/history/clear');
    _throwIfError(response);
    return SavedData.fromJson(_asMap(response.data));
  }

  /// [applyToSearch] asks Gemini to look for places that fit [filters]
  /// ("Search again"); otherwise the filters are only saved.
  Future<SearchPayload> searchRestaurants(
    UserPreferences preferences, {
    SearchFilters? filters,
    bool applyToSearch = false,
  }) async {
    final response = await _post(
      '/search-restaurants',
      data: {
        ...preferences.toJson(),
        if (filters != null) 'filters': filters.toJson(),
        if (applyToSearch) 'apply_filters_to_search': true,
      },
    );
    _throwIfServerError(response);
    final data = _asMap(response.data);
    final error = data['error']?.toString();
    if (response.statusCode != null &&
        response.statusCode! >= 400 &&
        response.statusCode != 401) {
      throw ApiException(
        _messageFrom(data) ?? 'Could not search restaurants.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 401) {
      throw ApiException('Authentication required.', statusCode: 401);
    }
    return SearchPayload(
      preferences: UserPreferences.fromJson(_asMap(data['preferences'])),
      restaurants: _restaurants(data['restaurants']),
      filters: SearchFilters.fromJson(_asMap(data['filters'])),
      cuisines: (data['cuisines'] is List)
          ? (data['cuisines'] as List).map((e) => e.toString()).toList()
          : const [],
      error: error,
    );
  }

  Future<CheckPayload> getCheckRestaurant() async {
    final response = await _get('/check-restaurant');
    _throwIfError(response);
    return _parseCheck(response.data);
  }

  Future<CheckPayload> checkRestaurant(UserPreferences preferences) async {
    final response = await _post(
      '/check-restaurant',
      data: preferences.toJson(),
    );
    _throwIfServerError(response);
    if (response.statusCode == 401) {
      throw ApiException('Authentication required.', statusCode: 401);
    }
    return _parseCheck(response.data);
  }

  Future<List<MapPlace>> searchPlaces({
    required double latitude,
    required double longitude,
    String query = '',
    int radiusMeters = 2500,
  }) async {
    final response = await _post(
      '/api/places/search',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'query': query,
        'radius_meters': radiusMeters,
      },
    );
    _throwIfError(response);
    final data = _asMap(response.data);
    final raw = data['places'];
    if (raw is! List) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map(
          (item) => MapPlace.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<MapPlace> verifyPlace(String placeId) async {
    final response = await _post(
      '/api/places/details',
      data: {'place_id': placeId},
    );
    _throwIfError(response);
    final data = _asMap(response.data);
    final place = data['place'];
    if (place is! Map) {
      throw ApiException('Could not verify that restaurant.');
    }
    return MapPlace.fromJson(
      place.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  CheckPayload _parseCheck(dynamic raw) {
    final data = _asMap(raw);
    return CheckPayload(
      preferences: UserPreferences.fromJson(_asMap(data['preferences'])),
      menuItems: _foodItems(data['menu_items']),
      restaurants: _restaurants(data['restaurants']),
      error: data['error']?.toString(),
    );
  }

  String _readUsername(Response<dynamic> response) {
    _throwIfServerError(response);
    final data = _asMap(response.data);
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw ApiException(
        _messageFrom(data) ?? 'Request failed.',
        statusCode: response.statusCode,
        suggestions: (data['suggestions'] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList(),
      );
    }
    return (data['username'] ?? '').toString();
  }

  void _throwIfError(Response<dynamic> response) {
    _throwIfServerError(response);
    if (response.statusCode != null && response.statusCode! >= 400) {
      final data = _asMap(response.data);
      throw ApiException(
        _messageFrom(data) ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    }
  }

  void _throwIfServerError(Response<dynamic> response) {
    if (response.statusCode != null && response.statusCode! >= 500) {
      final data = _asMap(response.data);
      throw ApiException(
        _messageFrom(data) ?? 'Server error.',
        statusCode: response.statusCode,
      );
    }
  }

  String? _messageFrom(Map<String, dynamic> data) {
    final error = data['error'];
    return error?.toString();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return {};
  }

  List<RestaurantRecommendation> _restaurants(dynamic value) {
    if (value is! List) {
      return [];
    }
    return value
        .whereType<Map>()
        .map((item) => RestaurantRecommendation.fromJson(
              item.map((key, v) => MapEntry(key.toString(), v)),
            ))
        .toList();
  }

  List<FoodItem> _foodItems(dynamic value) {
    if (value is! List) {
      return [];
    }
    return value
        .whereType<Map>()
        .map((item) => FoodItem.fromJson(
              item.map((key, v) => MapEntry(key.toString(), v)),
            ))
        .toList();
  }
}
