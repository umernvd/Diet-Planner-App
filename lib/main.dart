import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

import 'screens/home_screen_new.dart';
import 'services/food_database_service.dart';
import 'services/huggingface_ai_service.dart';
import 'config/ai_config.dart';
import 'config/app_theme.dart';
import 'models/food_item.dart';

final _logger = Logger();

void main() async {
  // Wrap everything in error handling to prevent blank screen
  FlutterError.onError = (FlutterErrorDetails details) {
    _logger.e('Flutter Error: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables from .env (if present)
    Map<String, String> envVars = {};
    try {
      await dotenv.load(fileName: ".env");
      envVars = Map<String, String>.from(dotenv.env);
      _logger.i('Environment variables loaded from .env');
    } catch (e) {
      _logger.w('No .env file found or error loading it: $e');
      _logger.i('App will run without Firebase and AI features');
    }

    // Initialize Firebase with configuration from environment variables
    // Only initialize if we have at least a project ID
    final projectId = envVars['FIREBASE_PROJECT_ID'] ?? '';
    if (projectId.isNotEmpty) {
      try {
        final firebaseOptions = FirebaseOptions(
          apiKey: envVars['FIREBASE_API_KEY'] ?? '',
          appId: envVars['FIREBASE_APP_ID'] ?? '',
          messagingSenderId: envVars['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
          projectId: projectId,
          authDomain: envVars['FIREBASE_AUTH_DOMAIN'] ?? '',
          storageBucket: envVars['FIREBASE_STORAGE_BUCKET'] ?? '',
          measurementId: envVars['FIREBASE_MEASUREMENT_ID'] ?? '',
        );

        await Firebase.initializeApp(options: firebaseOptions);
        _logger.i('Firebase initialized successfully');
      } catch (e, st) {
        _logger.e('Firebase initialization error: $e\n$st');
      }
    } else {
      _logger.w('Firebase not configured - app will work in offline mode');
    }

    // Initialize AI service - with automatic fallback if no API key
    final hfApiKey = envVars['HF_API_KEY'] ?? '';
    final hfModel = envVars['HF_MODEL'] ?? 'gpt2';

    if (hfApiKey.isNotEmpty && hfApiKey.startsWith('hf_')) {
      try {
        HuggingFaceAIService.instance.initialize(
          hfApiKey,
          apiUrl: AIConfig.hfApiUrl,
          model: hfModel,
        );
        _logger.i('✅ AI Features: ${HuggingFaceAIService.instance.status}');
      } catch (e, st) {
        _logger.w('AI API initialization error, using fallback mode: $e\n$st');
        _logger.i('✅ AI Features: ${HuggingFaceAIService.instance.status}');
      }
    } else {
      _logger.i('✅ AI Features: ${HuggingFaceAIService.instance.status}');
      _logger.i('💡 Optional: Add HF_API_KEY to .env for cloud AI features');
    }

    _seedLocalDatabase();
    runApp(const MyApp());
  } catch (e, st) {
    _logger.e('Fatal error in main: $e\n$st');
    // Run a minimal app to show error
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error starting app: $e'))),
      ),
    );
  }
}

void _seedLocalDatabase() {
  // Add a few sample foods so the app is usable out-of-the-box.
  final db = FoodDatabaseService.instance;
  final now = DateTime.now();

  final apple = FoodItem(
    id: 'apple_1',
    name: 'Apple (medium)',
    calories: 95,
    protein: 0.5,
    carbs: 25,
    fat: 0.3,
    servingSizeGrams: 182,
  );

  final chicken = FoodItem(
    id: 'chicken_breast',
    name: 'Chicken Breast (100g)',
    calories: 165,
    protein: 31,
    carbs: 0,
    fat: 3.6,
    servingSizeGrams: 100,
  );

  final oats = FoodItem(
    id: 'oats_40g',
    name: 'Rolled Oats (40g)',
    calories: 150,
    protein: 5.0,
    carbs: 27.0,
    fat: 3.0,
    servingSizeGrams: 40,
  );

  db.addFood(apple);
  db.addFood(chicken);
  db.addFood(oats);

  // Log a sample breakfast so the home screen shows data immediately.
  db.logFood(now, oats);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for a polished look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diet Planner',
      theme: AppTheme.lightTheme,
      home: const HomeScreenRedesigned(),
    );
  }
}
