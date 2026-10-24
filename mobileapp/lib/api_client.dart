import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class HomePayload {
  HomePayload({
    required this.username,
    required this.preferences,
    required this.restaurants,
  });

  final String? username;
  final UserPreferences preferences;
  final List<RestaurantRecommendation> restaurants;
}

class SearchPayload {
  SearchPayload({
    required this.preferences,
    required this.restaurants,
    this.error,
  });

  final UserPreferences preferences;
  final List<RestaurantRecommendation> restaurants;
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

  static const _authPaths = {'/api/login', '/api/signup', '/login', '/healthz'};

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
        onResponse: (response, handler) {
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

  Future<void> clearCookies() => _cookieJar.deleteAll();

  Never _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      throw ApiException(
        isProduction
            ? "Can't reach Menu Match right now. Check your connection and try again."
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
    );
  }

  Future<SearchPayload> searchRestaurants(UserPreferences preferences) async {
    final response = await _post(
      '/search-restaurants',
      data: preferences.toJson(),
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
