class UserPreferences {
  UserPreferences({
    this.calories,
    this.proteins,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.targetsPer = 'meal',
    this.halal = false,
    this.kosher = false,
    this.allergies = const [],
    this.restaurantName = '',
    this.latitude,
    this.longitude,
  });

  final double? calories;
  final double? proteins;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugar;

  /// 'meal' or 'day': what the macro targets apply to.
  final String targetsPer;
  final bool halal;
  final bool kosher;
  final List<String> allergies;
  final String restaurantName;
  final String? latitude;
  final String? longitude;

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return UserPreferences();
    }
    return UserPreferences(
      calories: _toDouble(json['calories']),
      proteins: _toDouble(json['proteins']),
      carbs: _toDouble(json['carbs']),
      fat: _toDouble(json['fat']),
      fiber: _toDouble(json['fiber']),
      sugar: _toDouble(json['sugar']),
      targetsPer: json['targets_per'] == 'day' ? 'day' : 'meal',
      halal: json['halal'] == true,
      kosher: json['kosher'] == true,
      allergies: (json['allergies'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      restaurantName: (json['restaurant_name'] ?? '').toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }

  UserPreferences copyWith({
    double? calories,
    double? proteins,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    String? targetsPer,
    bool? halal,
    bool? kosher,
    List<String>? allergies,
    String? restaurantName,
    String? latitude,
    String? longitude,
    bool clearCalories = false,
    bool clearProteins = false,
    bool clearCarbs = false,
    bool clearFat = false,
    bool clearFiber = false,
    bool clearSugar = false,
  }) {
    return UserPreferences(
      calories: clearCalories ? null : (calories ?? this.calories),
      proteins: clearProteins ? null : (proteins ?? this.proteins),
      carbs: clearCarbs ? null : (carbs ?? this.carbs),
      fat: clearFat ? null : (fat ?? this.fat),
      fiber: clearFiber ? null : (fiber ?? this.fiber),
      sugar: clearSugar ? null : (sugar ?? this.sugar),
      targetsPer: targetsPer ?? this.targetsPer,
      halal: halal ?? this.halal,
      kosher: kosher ?? this.kosher,
      allergies: allergies ?? this.allergies,
      restaurantName: restaurantName ?? this.restaurantName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'targets_per': targetsPer,
      'halal': halal,
      'kosher': kosher,
      'allergies': allergies.join(', '),
      'restaurant_choice': restaurantName,
      'restaurant_name': restaurantName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

enum SearchSort { fit, distance, price }

/// Result filters. Same rules as `apply_filters` on the server: a place with
/// an unknown distance, price or open status is kept rather than hidden.
class SearchFilters {
  const SearchFilters({
    this.maxMiles,
    this.priceLevels = const [],
    this.openNow = false,
    this.cuisines = const [],
    this.sort = SearchSort.fit,
  });

  const SearchFilters.none() : this();

  final double? maxMiles;
  final List<int> priceLevels;
  final bool openNow;
  final List<String> cuisines;
  final SearchSort sort;

  /// Number of narrowing filters on (sort isn't counted).
  int get activeCount =>
      (maxMiles != null ? 1 : 0) +
      (priceLevels.isNotEmpty ? 1 : 0) +
      (openNow ? 1 : 0) +
      (cuisines.isNotEmpty ? 1 : 0);

  bool get isActive => activeCount > 0;

  SearchFilters copyWith({
    double? maxMiles,
    bool clearMaxMiles = false,
    List<int>? priceLevels,
    bool? openNow,
    List<String>? cuisines,
    SearchSort? sort,
  }) {
    return SearchFilters(
      maxMiles: clearMaxMiles ? null : (maxMiles ?? this.maxMiles),
      priceLevels: priceLevels ?? this.priceLevels,
      openNow: openNow ?? this.openNow,
      cuisines: cuisines ?? this.cuisines,
      sort: sort ?? this.sort,
    );
  }

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    final levels = json['price_levels'];
    final cuisines = json['cuisines'];
    final sort = (json['sort'] ?? 'fit').toString();
    return SearchFilters(
      maxMiles: _toDouble(json['max_miles']),
      priceLevels: levels is List
          ? levels.map((e) => _toDouble(e)?.round()).whereType<int>().toList()
          : const [],
      openNow: json['open_now'] == true,
      cuisines: cuisines is List
          ? cuisines.map((e) => e.toString()).toList()
          : const [],
      sort: SearchSort.values.firstWhere(
        (value) => value.name == sort,
        orElse: () => SearchSort.fit,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'max_miles': maxMiles,
        'price_levels': priceLevels,
        'open_now': openNow,
        'cuisines': cuisines,
        'sort': sort.name,
      };

  List<RestaurantRecommendation> apply(List<RestaurantRecommendation> all) {
    final wanted = cuisines.map((c) => c.toLowerCase()).toSet();
    final kept = all.where((r) {
      final miles = r.distanceMiles;
      if (maxMiles != null && miles != null && miles > maxMiles!) {
        return false;
      }
      final level = r.priceLevel;
      if (priceLevels.isNotEmpty &&
          level != null &&
          !priceLevels.contains(level)) {
        return false;
      }
      if (openNow && r.openNow == false) {
        return false;
      }
      if (wanted.isNotEmpty && !wanted.contains(r.cuisine.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
    int byNullable(num? a, num? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    switch (sort) {
      case SearchSort.distance:
        kept.sort((a, b) => byNullable(a.distanceMiles, b.distanceMiles));
      case SearchSort.price:
        kept.sort((a, b) => byNullable(a.priceLevel, b.priceLevel));
      case SearchSort.fit:
        break;
    }
    return kept;
  }
}

class RestaurantRecommendation {
  RestaurantRecommendation({
    required this.name,
    this.address = '',
    this.cuisine = '',
    this.whyItMatches = '',
    this.possibleIdeas = '',
    this.website = '',
    this.doordashUrl = '',
    this.placeId = '',
    this.mapsUrl = '',
    this.priceLevel,
    this.latitude,
    this.longitude,
    this.distanceMiles,
    this.walkMinutes,
    this.openNow,
  });

  final String name;
  final String address;
  final String cuisine;
  final String whyItMatches;
  final String possibleIdeas;
  final String website;
  final String doordashUrl;

  /// Set by the server from Google Places; empty for unverified entries.
  final String placeId;
  final String mapsUrl;

  /// 1 to 4 ($ to $$$$), or null if unknown.
  final int? priceLevel;
  final double? latitude;
  final double? longitude;
  final double? distanceMiles;
  final int? walkMinutes;

  /// From Google Places; null when unknown.
  final bool? openNow;

  factory RestaurantRecommendation.fromJson(Map<String, dynamic> json) {
    return RestaurantRecommendation(
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      cuisine: (json['cuisine'] ?? '').toString(),
      whyItMatches: (json['why_it_matches'] ?? '').toString(),
      possibleIdeas: (json['possible_ideas'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      doordashUrl: (json['doordash_url'] ?? '').toString(),
      placeId: (json['place_id'] ?? '').toString(),
      mapsUrl: (json['maps_url'] ?? '').toString(),
      priceLevel: _toDouble(json['price_level'])?.round(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      distanceMiles: _toDouble(json['distance_miles']),
      walkMinutes: _toDouble(json['walk_minutes'])?.round(),
      openNow: json['open_now'] is bool ? json['open_now'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'cuisine': cuisine,
      'why_it_matches': whyItMatches,
      'possible_ideas': possibleIdeas,
      'website': website,
      'doordash_url': doordashUrl,
      'place_id': placeId,
      'maps_url': mapsUrl,
      'price_level': priceLevel,
      'latitude': latitude,
      'longitude': longitude,
      'distance_miles': distanceMiles,
      'walk_minutes': walkMinutes,
      'open_now': openNow,
    };
  }

  /// DoorDash store URLs can't be verified, so link to a search by name.
  String get doordashSearchUrl {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return 'https://www.doordash.com/search/store/${Uri.encodeComponent(trimmed)}/';
  }

  String get googleMapsUrl {
    if (mapsUrl.isNotEmpty) {
      return mapsUrl;
    }
    final query = [name, address].where((part) => part.trim().isNotEmpty).join(' ');
    if (query.isEmpty) {
      return '';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
  }
}

class MapPlace {
  MapPlace({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.businessStatus = 'OPERATIONAL',
    this.openNow,
    this.rating,
    this.website = '',
    this.mapsUrl = '',
    this.nextOpenTime,
    this.nextCloseTime,
    this.distanceMiles,
    this.walkMinutes,
  });

  final String placeId;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String businessStatus;
  final bool? openNow;
  final double? rating;
  final String website;
  final String mapsUrl;

  /// RFC 3339 timestamps from Places, used for "Open until 10 PM".
  final DateTime? nextOpenTime;
  final DateTime? nextCloseTime;
  final double? distanceMiles;
  final int? walkMinutes;

  factory MapPlace.fromJson(Map<String, dynamic> json) {
    return MapPlace(
      placeId: (json['place_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
      address: (json['address'] ?? '').toString(),
      businessStatus: (json['business_status'] ?? 'OPERATIONAL').toString(),
      openNow: json['open_now'] is bool ? json['open_now'] as bool : null,
      rating: _toDouble(json['rating']),
      website: (json['website'] ?? '').toString(),
      mapsUrl: (json['maps_url'] ?? '').toString(),
      nextOpenTime: DateTime.tryParse((json['next_open_time'] ?? '').toString()),
      nextCloseTime: DateTime.tryParse((json['next_close_time'] ?? '').toString()),
      distanceMiles: _toDouble(json['distance_miles']),
      walkMinutes: _toDouble(json['walk_minutes'])?.round(),
    );
  }

  RestaurantRecommendation toRecommendation() {
    return RestaurantRecommendation(
      name: name,
      address: address,
      website: website,
      placeId: placeId,
      mapsUrl: mapsUrl,
      latitude: latitude,
      longitude: longitude,
      distanceMiles: distanceMiles,
      walkMinutes: walkMinutes,
    );
  }
}

class FoodItem {
  FoodItem({
    required this.name,
    this.quantity = '1 serving',
    this.ingredients = const [],
    this.calories = 0,
    this.proteins = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.description = '',
    this.price,
    this.matchStatus = 'fits',
    this.matchReason = '',
    this.allergens = const [],
    this.dietFlags = const [],
    this.source = 'description',
  });

  final String name;
  final String quantity;
  final List<String> ingredients;
  final double calories;
  final double proteins;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final String description;
  final String? price;

  /// 'fits', 'swap' or 'no'.
  final String matchStatus;
  final String matchReason;
  final List<String> allergens;
  final List<String> dietFlags;

  /// 'restaurant' (published by the restaurant) or 'description' (estimated).
  final String source;

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] ?? '1 serving').toString(),
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      calories: _toDouble(json['calories']) ?? 0,
      proteins: _toDouble(json['proteins']) ?? 0,
      carbs: _toDouble(json['carbs']) ?? 0,
      fat: _toDouble(json['fat']) ?? 0,
      fiber: _toDouble(json['fiber']) ?? 0,
      sugar: _toDouble(json['sugar']) ?? 0,
      description: (json['description'] ?? '').toString(),
      price: (json['price'] ?? '').toString().trim().isEmpty
          ? null
          : json['price'].toString(),
      matchStatus: const {'fits', 'swap', 'no'}.contains(json['match_status'])
          ? json['match_status'] as String
          : 'fits',
      matchReason: (json['match_reason'] ?? '').toString(),
      allergens: (json['allergens'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      dietFlags: (json['diet_flags'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      source: json['source'] == 'restaurant' ? 'restaurant' : 'description',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'ingredients': ingredients,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'description': description,
      'price': price,
      'match_status': matchStatus,
      'match_reason': matchReason,
      'allergens': allergens,
      'diet_flags': dietFlags,
      'source': source,
    };
  }
}

class FavoriteMeal {
  FavoriteMeal({
    required this.restaurantName,
    required this.item,
    this.restaurantAddress = '',
  });

  final String restaurantName;
  final String restaurantAddress;
  final FoodItem item;

  factory FavoriteMeal.fromJson(Map<String, dynamic> json) {
    return FavoriteMeal(
      restaurantName: (json['restaurant_name'] ?? '').toString(),
      restaurantAddress: (json['restaurant_address'] ?? '').toString(),
      item: FoodItem.fromJson(_stringMap(json['item'])),
    );
  }
}

class HistoryEntry {
  HistoryEntry({
    required this.restaurant,
    required this.menuItems,
    this.checkedAt,
  });

  final RestaurantRecommendation restaurant;
  final List<FoodItem> menuItems;
  final DateTime? checkedAt;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      restaurant: RestaurantRecommendation.fromJson(
        _stringMap(json['restaurant']),
      ),
      menuItems: (json['menu_items'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => FoodItem.fromJson(_stringMap(item)))
          .toList(),
      checkedAt: DateTime.tryParse((json['checked_at'] ?? '').toString()),
    );
  }
}

class SavedData {
  SavedData({
    this.favoriteRestaurants = const [],
    this.favoriteMeals = const [],
    this.history = const [],
  });

  final List<RestaurantRecommendation> favoriteRestaurants;
  final List<FavoriteMeal> favoriteMeals;
  final List<HistoryEntry> history;

  factory SavedData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SavedData();
    }
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) build) {
      return (json[key] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => build(_stringMap(item)))
          .toList();
    }

    return SavedData(
      favoriteRestaurants:
          parse('favorite_restaurants', RestaurantRecommendation.fromJson),
      favoriteMeals: parse('favorite_meals', FavoriteMeal.fromJson),
      history: parse('history', HistoryEntry.fromJson),
    );
  }
}

Map<String, dynamic> _stringMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return {};
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
