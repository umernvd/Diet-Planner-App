import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

import '../models/food_item.dart';

final Logger _defaultLogger = Logger();

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
  /// Creates an instance of [EnhancedApiService]. You may provide a custom
  /// `http.Client` (useful for tests) and a `Logger` instance.
  EnhancedApiService({
    http.Client? client,
    Logger? logger,
    List<String>? corsProxies,
  }) : _http = client ?? http.Client(),
       _logger = logger ?? _defaultLogger,
       _corsProxies = corsProxies ?? _corsProxiesDefault,
       _ownsClient = client == null;

  /// Convenient singleton instance for quick use. For production code prefer
  /// injecting an instance (so it can be mocked in tests).
  static final EnhancedApiService instance = EnhancedApiService();

  final http.Client _http;
  final Logger _logger;
  final List<String> _corsProxies;
  final bool _ownsClient;
  // CORS proxies to try when running on web
  static const List<String> _corsProxiesDefault = [
    'https://corsproxy.io/?',
    'https://api.allorigins.win/raw?url=',
    'https://thingproxy.freeboard.io/fetch/',
  ];

  static const Duration _defaultTimeout = Duration(seconds: 20);
  static const int _defaultMaxRetries = 3;

  bool get _shouldCloseClient => _ownsClient;

  // OpenFoodFacts search with retry logic and relevance filtering
  Future<List<FoodItem>> searchOpenFoodFacts(
    String query, {
    int retries = _defaultMaxRetries,
    bool forceDirect = false,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    // Build base URL
    final baseUrl =
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=50';

    // If running on web, try direct first (may work in dev) then proxy fallbacks
    if (kIsWeb && !forceDirect) {
      // Try direct first on web (may fail due to CORS).
      try {
        final directUri = Uri.parse(baseUrl);
        _logger.d('Searching OpenFoodFacts (direct): $directUri');
        final directResp = await _getWithRetries(
          directUri,
          timeout: const Duration(seconds: 5),
          maxRetries: 0,
        );
        if (directResp != null && directResp.statusCode == 200) {
          _logger.i('Direct OpenFoodFacts request succeeded');
          final json = jsonDecode(directResp.body) as Map<String, dynamic>;
          final products = (json['products'] as List<dynamic>?) ?? [];
          return products
              .map((p) => _foodItemFromOpenFoodFacts(p as Map<String, dynamic>))
              .whereType<FoodItem>()
              .where((item) => item.name.isNotEmpty && item.calories >= 0)
              .toList();
        }
      } catch (e, st) {
        _logger.w(
          'Direct OpenFoodFacts request failed, will try proxies: $e',
          error: e,
          stackTrace: st,
        );
      }
    }

    // Prepare proxy candidate list (web only)
    final proxyCandidates = <String>[];
    if (kIsWeb) {
      for (final proxy in _corsProxies) {
        if (proxy.contains('allorigins')) {
          proxyCandidates.add('$proxy${Uri.encodeComponent(baseUrl)}');
        } else {
          proxyCandidates.add('$proxy$baseUrl');
        }
      }
    } else {
      proxyCandidates.add(baseUrl);
    }

    // Try proxies with retries using centralized GET helper
    for (final urlStr in proxyCandidates) {
      final uri = Uri.parse(urlStr);
      try {
        final resp = await _getWithRetries(
          uri,
          timeout: kIsWeb ? const Duration(seconds: 45) : _defaultTimeout,
          maxRetries: retries,
        );
        if (resp == null) continue;
        if (resp.statusCode != 200) {
          _logger.w('OpenFoodFacts returned status ${resp.statusCode}');
          continue;
        }

        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final products = (json['products'] as List<dynamic>?) ?? [];

        // Parse all products
        final allItems = products
            .map((p) => _foodItemFromOpenFoodFacts(p as Map<String, dynamic>))
            .whereType<FoodItem>()
            .where((item) => item.name.isNotEmpty && item.calories >= 0)
            .toList();

        // Score and filter by relevance
        final queryWords = q.split(' ').where((w) => w.isNotEmpty).toList();
        final scoredItems = allItems
            .map((item) {
              final itemName = item.name.toLowerCase();
              double score = 0;

              if (itemName == q) {
                score = 100;
              } else if (itemName.startsWith(q)) {
                score = 90;
              } else if (itemName.contains(q)) {
                score = 80;
              } else {
                int matchedWords = 0;
                for (final word in queryWords) {
                  if (itemName.contains(word)) {
                    matchedWords++;
                    score += 10;
                  }
                }
                if (matchedWords == queryWords.length) score += 20;
              }

              if (itemName.length > q.length * 3) score -= 10;

              return {'item': item, 'score': score};
            })
            .where((entry) => (entry['score'] as double) > 0)
            .toList();

        scoredItems.sort(
          (a, b) => (b['score'] as double).compareTo(a['score'] as double),
        );

        final items = scoredItems
            .take(20)
            .map((e) => e['item'] as FoodItem)
            .toList();

        _logger.i(
          'Found ${items.length} relevant items from OpenFoodFacts (filtered from ${allItems.length})',
        );
        return items;
      } catch (e, stackTrace) {
        _logger.e(
          'OpenFoodFacts error for $uri: $e',
          error: e,
          stackTrace: stackTrace,
        );
        // try next proxy candidate
      }
    }

    return [];
  }

  /// Centralized GET with retries, timeouts and basic backoff handling.
  Future<http.Response?> _getWithRetries(
    Uri uri, {
    Duration? timeout,
    int maxRetries = _defaultMaxRetries,
  }) async {
    final dur = timeout ?? _defaultTimeout;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        _logger.d('HTTP GET attempt ${attempt + 1} -> $uri');
        final resp = await _http.get(uri).timeout(dur);
        if (resp.statusCode == 429) {
          // Handle rate limiting: honor Retry-After if present
          final ra = resp.headers['retry-after'];
          int waitSeconds = 1 + attempt; // exponential-ish
          if (ra != null) {
            final parsed = int.tryParse(ra);
            if (parsed != null) waitSeconds = parsed;
          }
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
        return resp;
      } on TimeoutException catch (te) {
        _logger.w('Timeout on GET $uri: ${te.message}');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      } catch (e) {
        _logger.w('GET error on $uri: $e');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    return null;
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
    bool forceDirect = false,
  }) async {
    final clean = barcode.trim();
    if (clean.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(clean)) {
      _logger.w('Invalid barcode format: $barcode');
      return null;
    }

    final baseUrl =
        'https://world.openfoodfacts.org/api/v0/product/$clean.json';

    // If web and not forcing direct false, try direct first
    if (kIsWeb && !forceDirect) {
      try {
        final directUri = Uri.parse(baseUrl);
        _logger.d('Barcode lookup (direct): $directUri');
        final directResp = await _http
            .get(directUri)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () =>
                  throw TimeoutException('Direct barcode lookup timed out'),
            );
        if (directResp.statusCode == 200) {
          final json = jsonDecode(directResp.body) as Map<String, dynamic>;
          final status = json['status'];
          if (status == 0 || status == '0') {
            _logger.i('Product not found for barcode: $clean');
            return null;
          }
          final product = json['product'] as Map<String, dynamic>?;
          if (product == null || product.isEmpty) return null;
          final item = _foodItemFromOpenFoodFacts(product);
          if (item != null) {
            _logger.i('Successfully found product: ${item.name} (direct)');
          }
          return item;
        }
      } catch (e, st) {
        _logger.w(
          'Direct barcode lookup failed, will try proxies: $e',
          error: e,
          stackTrace: st,
        );
      }
    }

    // prepare proxy candidates
    final proxyCandidates = <String>[];
    if (kIsWeb) {
      for (final proxy in _corsProxies) {
        if (proxy.contains('allorigins')) {
          proxyCandidates.add('$proxy${Uri.encodeComponent(baseUrl)}');
        } else {
          proxyCandidates.add('$proxy$baseUrl');
        }
      }
    } else {
      proxyCandidates.add(baseUrl);
    }

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final idx = attempt % proxyCandidates.length;
        final urlStr = proxyCandidates[idx];
        final uri = Uri.parse(urlStr);
        _logger.d('Barcode lookup (attempt ${attempt + 1}): $uri');

        final timeoutDuration = kIsWeb
            ? const Duration(seconds: 30)
            : const Duration(seconds: 20);
        final resp = await _http
            .get(uri)
            .timeout(
              timeoutDuration,
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
      String baseUrl =
          'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(q)}';
      String urlStr = baseUrl;
      if (kIsWeb) {
        final proxy = _corsProxies[0];
        // prefer corsproxy for recipes, fallback handled by retries
        if (proxy.contains('allorigins')) {
          urlStr = '$proxy${Uri.encodeComponent(baseUrl)}';
        } else {
          urlStr = '$proxy$baseUrl';
        }
      }
      final uri = Uri.parse(urlStr);
      _logger.d('Searching recipes: $uri');

      final timeoutDuration = kIsWeb
          ? const Duration(seconds: 20)
          : const Duration(seconds: 15);
      final resp = await _getWithRetries(
        uri,
        timeout: timeoutDuration,
        maxRetries: _defaultMaxRetries,
      );

      if (resp == null || resp.statusCode != 200) {
        _logger.w('Recipe search returned status ${resp?.statusCode}');
        return [];
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final meals = (json['meals'] as List<dynamic>?) ?? [];

      return meals
          .map((m) {
            final map = m as Map<String, dynamic>;

            // Extract ingredients from strIngredient1-20 and strMeasure1-20
            final ingredients = <Map<String, String>>[];
            for (int j = 1; j <= 20; j++) {
              final ingredient =
                  map['strIngredient$j']?.toString().trim() ?? '';
              final measure = map['strMeasure$j']?.toString().trim() ?? '';
              if (ingredient.isNotEmpty && ingredient.toLowerCase() != 'null') {
                ingredients.add({
                  'ingredient': ingredient,
                  'measure':
                      measure.isNotEmpty && measure.toLowerCase() != 'null'
                      ? measure
                      : '',
                });
              }
            }

            return {
              'id': map['idMeal'] ?? '',
              'name': map['strMeal'] ?? 'Unknown Recipe',
              'category': map['strCategory'] ?? '',
              'area': map['strArea'] ?? '',
              'instructions': map['strInstructions'] ?? '',
              'thumbnail': map['strMealThumb'] ?? '',
              'image': map['strMealThumb'] ?? '',
              'ingredients': ingredients,
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
        final resp = await _getWithRetries(
          uri,
          timeout: const Duration(seconds: 10),
          maxRetries: 1,
        );
        if (resp != null && resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final meals = (json['meals'] as List<dynamic>?) ?? [];
          if (meals.isNotEmpty) {
            final meal = meals[0] as Map<String, dynamic>;

            // Extract ingredients from strIngredient1-20 and strMeasure1-20
            final ingredients = <Map<String, String>>[];
            for (int j = 1; j <= 20; j++) {
              final ingredient =
                  meal['strIngredient$j']?.toString().trim() ?? '';
              final measure = meal['strMeasure$j']?.toString().trim() ?? '';
              if (ingredient.isNotEmpty && ingredient.toLowerCase() != 'null') {
                ingredients.add({
                  'ingredient': ingredient,
                  'measure':
                      measure.isNotEmpty && measure.toLowerCase() != 'null'
                      ? measure
                      : '',
                });
              }
            }

            recipes.add({
              'id': meal['idMeal'] ?? '',
              'name': meal['strMeal'] ?? 'Unknown Recipe',
              'category': meal['strCategory'] ?? '',
              'area': meal['strArea'] ?? '',
              'instructions': meal['strInstructions'] ?? '',
              'thumbnail': meal['strMealThumb'] ?? '',
              'image': meal['strMealThumb'] ?? '',
              'ingredients': ingredients,
            });
          }
        }
        // Small delay between requests to avoid rate limiting
        if (i < count - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      return recipes;
    } catch (e, stackTrace) {
      _logger.e('Random recipes error: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecipesByCategory(
    String category,
  ) async {
    try {
      // First get the list of recipes in the category
      final uri = Uri.https('www.themealdb.com', '/api/json/v1/1/filter.php', {
        'c': category,
      });
      final resp = await _getWithRetries(
        uri,
        timeout: const Duration(seconds: 10),
        maxRetries: _defaultMaxRetries,
      );
      if (resp == null || resp.statusCode != 200) return [];

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final meals = (json['meals'] as List<dynamic>?) ?? [];

      // Get full details for each recipe (limited to first 10 to avoid too many requests)
      final detailedRecipes = <Map<String, dynamic>>[];
      final limit = meals.length > 10 ? 10 : meals.length;

      for (int i = 0; i < limit; i++) {
        final meal = meals[i] as Map<String, dynamic>;
        final mealId = meal['idMeal']?.toString() ?? '';

        if (mealId.isNotEmpty) {
          try {
            // Get full meal details
            final detailUri = Uri.https(
              'www.themealdb.com',
              '/api/json/v1/1/lookup.php',
              {'i': mealId},
            );
            final detailResp = await _getWithRetries(
              detailUri,
              timeout: const Duration(seconds: 5),
              maxRetries: 0,
            );

            if (detailResp != null && detailResp.statusCode == 200) {
              final detailJson =
                  jsonDecode(detailResp.body) as Map<String, dynamic>;
              final detailMeals = (detailJson['meals'] as List<dynamic>?) ?? [];

              if (detailMeals.isNotEmpty) {
                final fullMeal = detailMeals[0] as Map<String, dynamic>;

                // Extract ingredients
                final ingredients = <Map<String, String>>[];
                for (int j = 1; j <= 20; j++) {
                  final ingredient =
                      fullMeal['strIngredient$j']?.toString().trim() ?? '';
                  final measure =
                      fullMeal['strMeasure$j']?.toString().trim() ?? '';
                  if (ingredient.isNotEmpty &&
                      ingredient.toLowerCase() != 'null') {
                    ingredients.add({
                      'ingredient': ingredient,
                      'measure':
                          measure.isNotEmpty && measure.toLowerCase() != 'null'
                          ? measure
                          : '',
                    });
                  }
                }

                detailedRecipes.add({
                  'id': fullMeal['idMeal'] ?? '',
                  'name': fullMeal['strMeal'] ?? 'Unknown Recipe',
                  'category': fullMeal['strCategory'] ?? '',
                  'area': fullMeal['strArea'] ?? '',
                  'instructions': fullMeal['strInstructions'] ?? '',
                  'thumbnail': fullMeal['strMealThumb'] ?? '',
                  'image': fullMeal['strMealThumb'] ?? '',
                  'ingredients': ingredients,
                });
              }
            }

            // Small delay to avoid rate limiting
            if (i < limit - 1) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
          } catch (e) {
            _logger.w('Error fetching details for meal $mealId: $e');
            // Continue with next meal
          }
        }
      }

      return detailedRecipes;
    } catch (e, stackTrace) {
      _logger.e('Category error: $e', error: e, stackTrace: stackTrace);
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

  void dispose() {
    if (_shouldCloseClient) {
      _http.close();
    }
  }
}
