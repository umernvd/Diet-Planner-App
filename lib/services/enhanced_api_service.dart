import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

import '../models/food_item.dart';

final Logger _logger = Logger();

/// Enhanced API Service with multiple public nutrition and recipe APIs
/// All APIs used are FREE and publicly accessible
///
/// Improvements:
/// - Retry logic for failed requests (up to 3 attempts)
/// - Better timeout handling (20 seconds with proper timeout exceptions)
/// - Rate limit detection and handling (HTTP 429)
/// - Enhanced nutrition data parsing with multiple fallback fields
/// - Input validation (barcode format, query length)
/// - Improved error logging with stack traces
/// - Data validation (positive values, non-empty names)
/// - Better null safety throughout
class EnhancedApiService {
  EnhancedApiService._private();
  static final EnhancedApiService instance = EnhancedApiService._private();
  final http.Client _http = http.Client();

  // OpenFoodFacts search with retry logic
  Future<List<FoodItem>> searchOpenFoodFacts(
    String query, {
    int retries = 2,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        String urlStr =
            'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(q)}&search_simple=1&action=process&json=1&page_size=30';
        if (kIsWeb) {
          urlStr = 'https://corsproxy.io/?${Uri.encodeComponent(urlStr)}';
        }
        final uri = Uri.parse(urlStr);
        _logger.d('Searching OpenFoodFacts (attempt ${attempt + 1}): $uri');

        final resp = await _http
            .get(uri)
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () =>
                  throw TimeoutException('Search request timed out'),
            );

        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final products = (json['products'] as List<dynamic>?) ?? [];
          final items = products
              .map((p) => _foodItemFromOpenFoodFacts(p as Map<String, dynamic>))
              .whereType<FoodItem>()
              .where((item) => item.name.isNotEmpty && item.calories >= 0)
              .toList();
          _logger.i('Found ${items.length} valid items from OpenFoodFacts');
          return items;
        } else if (resp.statusCode == 429) {
          // Rate limited - wait before retry
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        } else {
          _logger.w('OpenFoodFacts returned status ${resp.statusCode}');
          if (attempt == retries) return [];
        }
      } catch (e, stackTrace) {
        _logger.e(
          'OpenFoodFacts error (attempt ${attempt + 1}): $e',
          error: e,
          stackTrace: stackTrace,
        );
        if (attempt == retries) return [];
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    return [];
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
      double kcal = 0.0;
      if (nutriments.containsKey('energy-kcal_100g')) {
        kcal = (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0.0;
      } else if (nutriments.containsKey('energy_100g')) {
        // Convert from kJ to kcal (1 kcal = 4.184 kJ)
        final energy = (nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0;
        kcal = energy / 4.184;
      } else if (nutriments.containsKey('energy-kcal')) {
        kcal = (nutriments['energy-kcal'] as num?)?.toDouble() ?? 0.0;
      }

      // Parse macronutrients with fallbacks
      double protein =
          ((nutriments['proteins_100g'] ??
                      nutriments['protein_100g'] ??
                      nutriments['proteins'] ??
                      0.0)
                  as num)
              .toDouble();

      double carbs =
          ((nutriments['carbohydrates_100g'] ??
                      nutriments['carbohydrates'] ??
                      0.0)
                  as num)
              .toDouble();

      double fat = ((nutriments['fat_100g'] ?? nutriments['fat'] ?? 0.0) as num)
          .toDouble();

      // Parse serving size
      double servingGrams = 100.0;
      final servingStr = product['serving_size']?.toString() ?? '';
      if (servingStr.isNotEmpty) {
        final numMatch = RegExp(r'([0-9]+\.?[0-9]*)').firstMatch(servingStr);
        if (numMatch != null) {
          servingGrams = double.tryParse(numMatch.group(1) ?? '') ?? 100.0;
        }
      }

      // Validate parsed values
      if (kcal < 0) kcal = 0.0;
      if (protein < 0) protein = 0.0;
      if (carbs < 0) carbs = 0.0;
      if (fat < 0) fat = 0.0;
      if (servingGrams <= 0) servingGrams = 100.0;

      final id = code.isNotEmpty ? 'off_$code' : 'off_${name.hashCode}';

      return FoodItem(
        id: id,
        name: name,
        calories: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingSizeGrams: servingGrams,
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Parse error for product: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Lookup product by barcode with retry mechanism (FREE)
  Future<FoodItem?> fetchFoodByBarcode(
    String barcode, {
    int retries = 2,
  }) async {
    final clean = barcode.trim();
    if (clean.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(clean)) {
      _logger.w('Invalid barcode format: $barcode');
      return null;
    }

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        String urlStr =
            'https://world.openfoodfacts.org/api/v0/product/$clean.json';
        if (kIsWeb) {
          urlStr = 'https://corsproxy.io/?${Uri.encodeComponent(urlStr)}';
        }
        final uri = Uri.parse(urlStr);
        _logger.d('Barcode lookup (attempt ${attempt + 1}): $uri');

        final resp = await _http
            .get(uri)
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () =>
                  throw TimeoutException('Barcode lookup timed out'),
            );

        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final status = json['status'];

          if (status == 0 || status == '0') {
            _logger.i('Product not found for barcode: $clean');
            return null;
          }

          final product = json['product'] as Map<String, dynamic>?;
          if (product == null || product.isEmpty) {
            _logger.w('Empty product data for barcode: $clean');
            return null;
          }

          final item = _foodItemFromOpenFoodFacts(product);
          if (item != null) {
            _logger.i('Successfully found product: ${item.name}');
          }
          return item;
        } else if (resp.statusCode == 429) {
          // Rate limited
          _logger.w('Rate limited, waiting before retry');
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        } else if (resp.statusCode == 404) {
          _logger.i('Product not found (404) for barcode: $clean');
          return null;
        } else {
          _logger.w('Unexpected status code: ${resp.statusCode}');
          if (attempt == retries) return null;
        }
      } catch (e, stackTrace) {
        _logger.e(
          'Barcode lookup error (attempt ${attempt + 1}): $e',
          error: e,
          stackTrace: stackTrace,
        );
        if (attempt == retries) return null;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    return null;
  }

  // TheMealDB API with improved error handling
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];
      String urlStr =
          'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(q)}';
      if (kIsWeb) {
        urlStr = 'https://corsproxy.io/?${Uri.encodeComponent(urlStr)}';
      }
      final uri = Uri.parse(urlStr);
      _logger.d('Searching recipes: $uri');

      final resp = await _http
          .get(uri)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Recipe search timed out'),
          );

      if (resp.statusCode != 200) {
        _logger.w('Recipe search returned status ${resp.statusCode}');
        return [];
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final meals = (json['meals'] as List<dynamic>?) ?? [];

      return meals
          .map((m) {
            final map = m as Map<String, dynamic>;
            return {
              'id': map['idMeal'] ?? '',
              'name': map['strMeal'] ?? 'Unknown Recipe',
              'category': map['strCategory'] ?? 'Other',
              'thumbnail': map['strMealThumb'] ?? '',
            };
          })
          .where((recipe) => recipe['name'].toString().isNotEmpty)
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Recipe search error: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRandomRecipes({int count = 5}) async {
    try {
      final recipes = <Map<String, dynamic>>[];
      for (int i = 0; i < count; i++) {
        final uri = Uri.https('www.themealdb.com', '/api/json/v1/1/random.php');
        final resp = await _http.get(uri).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final meals = (json['meals'] as List<dynamic>?) ?? [];
          if (meals.isNotEmpty) {
            recipes.add({
              'id': meals[0]['idMeal'],
              'name': meals[0]['strMeal'],
            });
          }
        }
      }
      return recipes;
    } catch (e) {
      _logger.e('Random recipes error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecipesByCategory(
    String category,
  ) async {
    try {
      final uri = Uri.https('www.themealdb.com', '/api/json/v1/1/filter.php', {
        'c': category,
      });
      final resp = await _http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final meals = (json['meals'] as List<dynamic>?) ?? [];
      return meals
          .map((m) => {'id': m['idMeal'], 'name': m['strMeal']})
          .toList();
    } catch (e) {
      _logger.e('Category error: $e');
      return [];
    }
  }

  Future<List<FoodItem>> smartFoodSearch(
    String query, {
    String? calorieNinjasKey,
  }) async {
    return await searchOpenFoodFacts(query);
  }

  Future<List<Map<String, dynamic>>> smartRecipeSearch(
    String query, {
    String? edamamAppId,
    String? edamamAppKey,
  }) async {
    return await searchRecipes(query);
  }

  List<String> getRecipeCategories() => [
    'Beef',
    'Chicken',
    'Dessert',
    'Lamb',
    'Pasta',
    'Pork',
    'Seafood',
    'Vegan',
    'Vegetarian',
  ];

  void dispose() => _http.close();
}
