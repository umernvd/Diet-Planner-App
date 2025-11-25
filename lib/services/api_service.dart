import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/food_item.dart';

/// Network-backed API service. Contains integrations for OpenFoodFacts and TheMealDB.
class ApiService {
  ApiService._private();
  static final ApiService instance = ApiService._private();

  /// Public default constructor kept for compatibility with existing code
  /// that instantiates `ApiService()`; returns the singleton instance.
  factory ApiService() => instance;

  final http.Client _http = http.Client();

  // -------------------- OpenFoodFacts --------------------
  /// Search OpenFoodFacts for foods matching [query]. Returns zero or more
  /// normalized [FoodItem]s. Uses the world.openfoodfacts.org search endpoint.
  Future<List<FoodItem>> searchFoods(String query) async {
    final q = query.trim();
    if (q.isEmpty || q.length < 2) return [];

    try {
      final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
        'search_terms': q,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '30',
      });

      final resp = await _http
          .get(uri)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Search request timed out'),
          );

      if (resp.statusCode != 200) return [];

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final products = (json['products'] as List<dynamic>?) ?? [];

      final items = products
          .map((p) => _foodItemFromOpenFoodFacts(p as Map<String, dynamic>))
          .whereType<FoodItem>()
          .where((item) => item.name.isNotEmpty && item.calories >= 0)
          .toList();

      return items;
    } catch (e) {
      // Log error and return empty list instead of throwing
      return [];
    }
  }

  /// Lookup a single product by barcode using OpenFoodFacts. Returns null when
  /// not found or on error.
  Future<FoodItem?> fetchFoodByBarcode(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(clean)) return null;

    try {
      final uri = Uri.https(
        'world.openfoodfacts.org',
        '/api/v0/product/$clean.json',
      );

      final resp = await _http
          .get(uri)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Barcode lookup timed out'),
          );

      if (resp.statusCode == 404 || resp.statusCode != 200) return null;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final status = json['status'];

      if (status == 0 || status == '0') return null;

      final product = json['product'] as Map<String, dynamic>?;
      if (product == null || product.isEmpty) return null;

      return _foodItemFromOpenFoodFacts(product);
    } catch (e) {
      // Log error and return null instead of throwing
      return null;
    }
  }

  FoodItem? _foodItemFromOpenFoodFacts(Map<String, dynamic> product) {
    try {
      final code = (product['code'] ?? product['_id'] ?? '').toString().trim();

      // Try multiple name fields with fallbacks
      String name =
          (product['product_name'] ??
                  product['product_name_en'] ??
                  product['generic_name'] ??
                  product['generic_name_en'] ??
                  '')
              .toString()
              .trim();

      // Skip products without valid name or code
      if (name.isEmpty && code.isEmpty) return null;
      if (name.isEmpty) name = 'Product $code';

      final nutriments = (product['nutriments'] ?? {}) as Map<String, dynamic>;

      // Parse energy with multiple fallbacks
      double kcalPer100g = 0.0;
      if (nutriments.containsKey('energy-kcal_100g')) {
        kcalPer100g =
            (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0.0;
      } else if (nutriments.containsKey('energy_100g')) {
        // energy_100g may be in kJ — convert to kcal (1 kcal = 4.184 kJ)
        final energy = (nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0;
        kcalPer100g = energy / 4.184;
      } else if (nutriments.containsKey('energy-kcal')) {
        kcalPer100g = (nutriments['energy-kcal'] as num?)?.toDouble() ?? 0.0;
      }

      // Parse macronutrients with fallbacks
      double protein100 =
          (nutriments['proteins_100g'] as num?)?.toDouble() ??
          (nutriments['protein_100g'] as num?)?.toDouble() ??
          (nutriments['proteins'] as num?)?.toDouble() ??
          0.0;

      double carbs100 =
          (nutriments['carbohydrates_100g'] as num?)?.toDouble() ??
          (nutriments['carbohydrates_value'] as num?)?.toDouble() ??
          (nutriments['carbohydrates'] as num?)?.toDouble() ??
          0.0;

      double fat100 =
          (nutriments['fat_100g'] as num?)?.toDouble() ??
          (nutriments['fat'] as num?)?.toDouble() ??
          0.0;

      // Determine serving size (try nutriments serving or product['serving_size'])
      double servingGrams = 100.0;
      final servingStr = product['serving_size']?.toString() ?? '';
      if (servingStr.isNotEmpty) {
        // Try to parse a number (e.g. "100g" or "250 ml")
        final numMatch = RegExp(r"([0-9]+\.?[0-9]*)").firstMatch(servingStr);
        if (numMatch != null) {
          servingGrams =
              double.tryParse(numMatch.group(1) ?? '') ?? servingGrams;
        }
      } else if (nutriments.containsKey('serving_size')) {
        final s = nutriments['serving_size'];
        if (s is num) servingGrams = s.toDouble();
      }

      // Validate parsed values
      if (kcalPer100g < 0) kcalPer100g = 0.0;
      if (protein100 < 0) protein100 = 0.0;
      if (carbs100 < 0) carbs100 = 0.0;
      if (fat100 < 0) fat100 = 0.0;
      if (servingGrams <= 0) servingGrams = 100.0;

      final calories = kcalPer100g * (servingGrams / 100.0);
      final id = code.isNotEmpty ? code : 'off_${name.hashCode}';

      return FoodItem(
        id: id,
        name: name,
        calories: calories,
        protein: protein100 * (servingGrams / 100.0),
        carbs: carbs100 * (servingGrams / 100.0),
        fat: fat100 * (servingGrams / 100.0),
        servingSizeGrams: servingGrams,
      );
    } catch (e) {
      // Log error but don't crash
      return null;
    }
  }

  // -------------------- TheMealDB (recipes) --------------------
  /// Search recipes by name using TheMealDB. Returns a list of maps with
  /// raw recipe JSON; UI can render details. For convenience this returns a
  /// simplified map with id, name and thumbnail.
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final uri = Uri.https('www.themealdb.com', '/api/json/v1/1/search.php', {
      's': q,
    });
    final resp = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final meals = (json['meals'] as List<dynamic>?) ?? [];
    return meals.map((m) {
      final map = m as Map<String, dynamic>;
      return {
        'id': map['idMeal'],
        'name': map['strMeal'],
        'thumbnail': map['strMealThumb'],
        'raw': map,
      };
    }).toList();
  }

  // -------------------- Scaffolds for paid/freemium APIs --------------------
  // The following methods are placeholders for USDA, Nutritionix and Edamam.
  // They expect API keys to be provided through your app configuration.

  /// Example placeholder for USDA FoodData Central search. Requires API key.
  Future<List<Map<String, dynamic>>> usdaSearch(
    String query, {
    required String apiKey,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': apiKey,
      'query': q,
      'pageSize': '20',
    });
    try {
      final resp = await _http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final foods = (json['foods'] as List<dynamic>?) ?? [];
      return foods.map((f) {
        final m = f as Map<String, dynamic>;
        // collect some nutrients
        final nutrients = <String, double>{};
        for (final n in (m['foodNutrients'] as List<dynamic>?) ?? []) {
          final nut = n as Map<String, dynamic>;
          final name = (nut['nutrientName'] ?? '').toString().toLowerCase();
          final value = (nut['value'] as num?)?.toDouble() ?? 0.0;
          if (name.contains('energy') || name.contains('kcal')) {
            nutrients['calories'] = value;
          }
          if (name.contains('protein')) {
            nutrients['protein'] = value;
          }
          if (name.contains('carbohydrate')) {
            nutrients['carbs'] = value;
          }
          if (name.contains('lipid') || name.contains('fat')) {
            nutrients['fat'] = value;
          }
        }
        return {
          'fdcId': m['fdcId'],
          'description': m['description'] ?? m['description'] ?? '',
          'brandOwner': m['brandOwner'],
          'nutrients': nutrients,
          'raw': m,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Placeholder for Nutritionix natural language nutrition lookup.
  Future<Map<String, dynamic>?> nutritionixNatural(
    String text, {
    required String appId,
    required String appKey,
  }) async {
    final uri = Uri.https('trackapi.nutritionix.com', '/v2/natural/nutrients');
    try {
      final resp = await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-app-id': appId,
              'x-app-key': appKey,
            },
            body: jsonEncode({'query': text}),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return json;
    } catch (_) {
      return null;
    }
  }

  /// Placeholder for Edamam recipe / nutrition analysis.
  Future<Map<String, dynamic>?> edamamAnalyze(
    String ingredientsCsv, {
    required String appId,
    required String appKey,
  }) async {
    // ingredientsCsv is a comma-separated list of ingredient lines.
    final uri = Uri.https('api.edamam.com', '/api/nutrition-details', {
      'app_id': appId,
      'app_key': appKey,
    });
    try {
      final ingredients = ingredientsCsv
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final resp = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'title': 'Recipe', 'ingr': ingredients}),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return json;
    } catch (_) {
      return null;
    }
  }
}
