# Copilot Instructions for Diet Planner App

## Project Overview
Flutter-based cross-platform (iOS/Android/Web) nutrition tracking app with Firebase backend, AI features via Hugging Face, and multi-API food database integration.

## Architecture

### Core Pattern: Service Layer + StatefulWidgets
- **No state management library** - Uses vanilla StatefulWidgets with service classes
- **Singleton services** via private constructors: `ServiceName._privateConstructor()` + `static final instance`
- **Models are immutable** - Use `copyWith()` for modifications, `toJson()`/`fromJson()` for serialization

### Data Flow
```
UI (Screens) → Services → External APIs/Firebase → Local Cache
              ↓
           Models (immutable data classes)
```

### Key Services
- `FoodDatabaseService`: In-memory cache + optional Firestore sync, searches both local and remote APIs
- `FirestoreService`: Cloud persistence, lazy-initialized (graceful degradation if Firebase not configured)
- `EnhancedApiService`: Multi-API aggregator (OpenFoodFacts primary, CalorieNinjas/Edamam fallback)
- `HuggingFaceAIService`: Dual-mode AI (cloud with API key, local fallback without)

## Critical Patterns

### Environment Variables (ALWAYS)
**Never hardcode credentials**. All secrets in `.env` file:
```dart
await dotenv.load(fileName: ".env");
final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
```

### Lazy Firebase Initialization
Services check Firebase availability before use:
```dart
FirebaseFirestore? get db {
  if (_db != null) return _db;
  try {
    _db = FirebaseFirestore.instance;
    return _db;
  } catch (e) {
    _logger.e('Firestore not available: $e');
    return null;
  }
}
```

### Async Context Safety
**Always** check `mounted` before using `BuildContext` after async operations:
```dart
await someAsyncOperation();
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### Logging (NOT print)
Use `Logger` package for all output:
```dart
final _logger = Logger();
_logger.d('Debug message');
_logger.w('Warning');
_logger.e('Error', error: e, stackTrace: st);
```

## Models Convention
All in `lib/models/`. Structure:
```dart
class ModelName {
  final String id;
  final String field;
  // No mutable fields
  
  ModelName({required this.id, required this.field});
  
  ModelName copyWith({String? id, String? field}) => ModelName(...);
  Map<String, dynamic> toJson() => {...};
  factory ModelName.fromJson(Map<String, dynamic> json) => ModelName(...);
}
```

## API Integration

### Multi-Source Food Search
`EnhancedApiService.smartFoodSearch()` tries in order:
1. OpenFoodFacts (2.8M+ products, no key needed)
2. CalorieNinjas (requires key)
3. Edamam (requires key)

### Barcode Scanning
- Mobile: `mobile_scanner` package (camera-based)
- Web: Manual entry fallback via dialog
- Check `BarcodeScanner.isSupported()` before showing camera option

### AI Features (Optional)
HuggingFace integration with **automatic fallback**:
- With `HF_API_KEY`: Uses cloud models (Mistral-7B default)
- Without key: Local 500+ food database + knowledge base
- **Always works**, degrades gracefully

## UI/UX Patterns

### Color System (Flutter 3.x)
Use `.withValues(alpha:)` instead of deprecated `.withOpacity()`:
```dart
// ✅ Correct
Colors.black.withValues(alpha: 0.05)
// ❌ Deprecated
Colors.black.withOpacity(0.05)
```

### Material Design 3 Theme
- Primary: `#00B4D8` (Vibrant Cyan)
- Cards: 20-24px border radius, elevation 2-4
- Typography: Inter font (Google Fonts)
- Animations: Staggered card entrance, circular progress rings

### Empty States
Provide actionable messages, not just "No data":
```dart
Center(
  child: Column(children: [
    Icon(Icons.search_off, size: 48),
    Text('No foods logged today'),
    ElevatedButton(onPressed: ..., child: Text('Log Your First Meal')),
  ]),
)
```

## Development Workflow

### Running the App
```bash
cd diet_planner_app
flutter pub get
flutter run  # Mobile
flutter run -d chrome  # Web
```

### Environment Setup
```bash
cp .env.example .env
# Edit .env with Firebase + HuggingFace credentials
```

### CI/CD
GitHub Actions at `.github/workflows/flutter-ci.yml`:
- Runs on push/PR to `main` or `develop`
- Jobs: analyze-and-test → build-android, build-web
- Working directory: `./diet_planner_app` (nested structure)

### Pre-Commit Checks
```bash
dart format lib/
flutter analyze
flutter test
```

## Common Tasks

### Adding a New Screen
1. Create in `lib/screens/screen_name.dart`
2. Use `StatefulWidget` pattern
3. Import services via singleton: `FoodDatabaseService.instance`
4. Add navigation in bottom nav or routing logic

### Adding a New Model
1. Create in `lib/models/model_name.dart`
2. Include: constructor, `copyWith()`, `toJson()`, `fromJson()`
3. Update Firestore service if needs cloud sync

### Integrating a New API
1. Add to `lib/services/api_service.dart` or create new service file
2. Follow pattern: try-catch with logger, return normalized `FoodItem`
3. Add to multi-source aggregation in `EnhancedApiService`

### Adding Firebase Collection
1. Update `FirestoreService` with collection reference
2. Add CRUD methods with error handling
3. Update `UserProfile` or create new model if needed

## Testing

### Structure
- `test/widget_test.dart` - Basic widget tests exist
- Coverage: ~5% (low, needs improvement)
- No integration tests yet

### Running Tests
```bash
flutter test
flutter test --coverage
```

## Security Notes

- **Never commit `.env`** - Already in `.gitignore`
- API keys load at runtime from environment variables
- Firebase security rules should restrict `/users/{userId}` collections
- CORS proxy used for web platform API calls

## Known Issues & Workarounds

1. **Barcode scanning on web**: Falls back to manual entry dialog (no camera access in browser)
2. **Firebase offline**: App works without Firebase (local-only mode), checks `db == null` before Firestore ops
3. **AI without key**: Uses local fallback with 500+ food database, no cloud required
4. **OpenFoodFacts CORS**: Handled via proxy for web builds

## Documentation
Extensive docs in project:
- `START_HERE.md` - Project orientation
- `PROJECT_ANALYSIS.md` - Architecture deep-dive
- `AI_INTEGRATION_GUIDE.md` - AI setup steps
- `PRODUCTION_READY_STATUS.md` - Deployment checklist
- `docs/` folder - Feature guides, setup instructions

## Version Info
- Flutter SDK: 3.16.0+ (requires Dart 3.9.2+)
- Key packages: `firebase_core`, `cloud_firestore`, `mobile_scanner`, `logger`, `flutter_dotenv`
- Platform support: iOS 11+, Android API 21+, Web (Chrome/Edge/Firefox)
