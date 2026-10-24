class UserPreferences {
  UserPreferences({
    this.calories,
    this.proteins,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
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

class RestaurantRecommendation {
  RestaurantRecommendation({
    required this.name,
    this.address = '',
    this.cuisine = '',
    this.whyItMatches = '',
    this.possibleIdeas = '',
    this.website = '',
    this.doordashUrl = '',
  });

  final String name;
  final String address;
  final String cuisine;
  final String whyItMatches;
  final String possibleIdeas;
  final String website;
  final String doordashUrl;

  factory RestaurantRecommendation.fromJson(Map<String, dynamic> json) {
    return RestaurantRecommendation(
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      cuisine: (json['cuisine'] ?? '').toString(),
      whyItMatches: (json['why_it_matches'] ?? '').toString(),
      possibleIdeas: (json['possible_ideas'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      doordashUrl: (json['doordash_url'] ?? '').toString(),
    );
  }

  String get googleMapsUrl {
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
    );
  }

  RestaurantRecommendation toRecommendation() {
    return RestaurantRecommendation(
      name: name,
      address: address,
      website: website,
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
    );
  }
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
