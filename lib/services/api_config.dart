/// Centralized switches and optional API credentials for nutrition services.
///
/// Keep secrets out of source control—either replace the `null` placeholders
/// below during development or provide values via `--dart-define` when running
/// the app (see `docs/guides/API_QUICK_START.md`).
class ApiConfig {
  ApiConfig._();

  /// Core free data sources that power search and recipe discovery.
  static const bool useOpenFoodFacts = true;
  static const bool useTheMealDB = true;

  /// Show the "results powered by ..." banner to help with debugging/demoing.
  static const bool showApiSource = true;

  // --- Optional API Keys ----------------------------------------------------
  //
  // Replace the `null` values below or pass them at runtime:
  //
  // flutter run \
  //   --dart-define=CALORIE_NINJAS_API_KEY=your_key \
  //   --dart-define=EDAMAM_APP_ID=your_id \
  //   --dart-define=EDAMAM_APP_KEY=your_key

  static const String? _hardcodedCalorieNinjasKey = null;
  static const String? _hardcodedEdamamAppId = null;
  static const String? _hardcodedEdamamAppKey = null;

  static const String _envCalorieNinjasKey = String.fromEnvironment(
    'CALORIE_NINJAS_API_KEY',
    defaultValue: '',
  );
  static const String _envEdamamAppId = String.fromEnvironment(
    'EDAMAM_APP_ID',
    defaultValue: '',
  );
  static const String _envEdamamAppKey = String.fromEnvironment(
    'EDAMAM_APP_KEY',
    defaultValue: '',
  );

  static String? get calorieNinjasApiKey =>
      _hardcodedCalorieNinjasKey ??
      (_envCalorieNinjasKey.isEmpty ? null : _envCalorieNinjasKey);

  static String? get edamamAppId =>
      _hardcodedEdamamAppId ??
      (_envEdamamAppId.isEmpty ? null : _envEdamamAppId);

  static String? get edamamAppKey =>
      _hardcodedEdamamAppKey ??
      (_envEdamamAppKey.isEmpty ? null : _envEdamamAppKey);
}
