/// Centralized switches and optional API credentials for nutrition services.
///
class ApiConfig {
  ApiConfig._();

  /// Core free data sources that power search and recipe discovery.
  static const bool useOpenFoodFacts = true;
  static const bool useTheMealDB = true;

  /// Show the "results powered by ..." banner to help with debugging/demoing.
  static const bool showApiSource = true;

  // --- API Keys from environment variables ---
  // These return `null` by default. Set them in your build or replace
  // with real values during local development. Avoid committing secrets.
  static String? get calorieNinjasApiKey => null;

  static String? get edamamAppId => null;

  static String? get edamamAppKey => null;
}
