# 🥗 Diet Planner - AI-Powered Nutrition & Meal Management App

[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)](https://flutter.dev)

## 📱 Overview

**Diet Planner** is a comprehensive, cross-platform nutrition and meal management application built with Flutter. It combines modern UI design with powerful AI-driven features to help users track their nutrition, plan meals, and achieve their health goals.

For a detailed technical report on the project, including methodology, system design, and testing results, please see the [Project Report](PROJECT_REPORT.md).

### ✨ Key Features

#### 🎯 Core Functionality
- **Real-time Calorie & Macro Tracking** - Track calories, protein, carbs, and fats with beautiful visualizations
- **Intelligent Meal Planning** - Create and manage 7-day meal plans with automatic nutrition calculations
- **Food Database** - Extensive local database with 500+ foods plus cloud API integration
- **Barcode Scanner** - Quick food logging via mobile barcode scanning (Android/iOS)
- **Progress Tracking** - Visual charts and graphs to monitor your nutrition journey
- **Goal Management** - Set and track personalized daily calorie and macro targets

#### 🤖 AI-Powered Features
- **Smart Food Parser** - Natural language food entry (e.g., "2 large eggs", "grilled chicken breast")
- **AI Nutrition Advisor** - Ask nutrition questions and get expert advice
- **Recipe Generator** - Generate healthy recipes from available ingredients
- **Meal Analyzer** - Get personalized suggestions for balanced nutrition
- **Dual AI Mode** - Works offline (Fallback AI) or with cloud AI (Hugging Face/Gemini)

#### ☁️ Cloud Features
- **Firebase Authentication** - Secure login with email/password and Google Sign-In
- **Cloud Sync** - Automatic data synchronization across devices
- **Data Persistence** - All data saved securely to Cloud Firestore
- **Offline Mode** - Full functionality without internet connection

### 🎨 Modern UI/UX
- **Material Design 3** - Beautiful, modern interface with glassmorphism effects
- **Responsive Design** - Works seamlessly on phones, tablets, and web
- **Dark/Light Themes** - Comfortable viewing in any lighting
- **Smooth Animations** - Polished user experience with fluid transitions
- **Custom Widgets** - Reusable components for consistent design

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (v3.35.4 or higher) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (v3.9.2 or higher) - Included with Flutter
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control

Verify your installation:
```bash
flutter doctor
```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/diet-planner.git
   cd diet-planner
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables (Optional)**
   
   Create a `.env` file in the project root:
   ```env
   # Firebase Configuration (Optional - for cloud sync)
   FIREBASE_API_KEY=your_firebase_api_key
   FIREBASE_APP_ID=your_app_id
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_AUTH_DOMAIN=your_auth_domain
   FIREBASE_STORAGE_BUCKET=your_storage_bucket
   FIREBASE_MEASUREMENT_ID=your_measurement_id

   # AI Configuration (Optional - for cloud AI)
   HF_API_KEY=your_huggingface_api_key
   HF_MODEL=mistralai/Mistral-7B-Instruct-v0.2
   GEMINI_API_KEY=your_gemini_api_key
   ```

   > **Note**: The app works perfectly without these configurations! All features have offline fallbacks.

4. **Run the application**
   ```bash
   # For web
   flutter run -d chrome

   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios

   # List all available devices
   flutter devices
   ```

---

## 📂 Project Structure

```
diet_planner_app/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── config/
│   │   └── ai_config.dart          # AI service configuration
│   ├── models/                      # Data models
│   │   ├── food_item.dart          # Food nutrition data
│   │   ├── meal.dart               # Meal types and structure
│   │   ├── meal_plan.dart          # Daily meal plans
│   │   ├── user_profile.dart       # User profile data
│   │   └── goal.dart               # Nutrition goals
│   ├── screens/                     # UI screens
│   │   ├── home_screen_redesigned.dart
│   │   ├── log_food_screen.dart
│   │   ├── meal_planner_screen.dart
│   │   ├── progress_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── ai_nutrition_advisor_screen.dart
│   │   └── ai_recipe_generator_screen.dart
│   ├── services/                    # Business logic
│   │   ├── ai_service.dart         # Gemini AI integration
│   │   ├── huggingface_ai_service.dart
│   │   ├── fallback_ai_service.dart
│   │   ├── firebase_auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── food_database_service.dart
│   │   ├── meal_plan_service.dart
│   │   ├── enhanced_api_service.dart
│   │   └── barcode_scanner_service.dart
│   └── widgets/                     # Reusable UI components
│       ├── ai_food_parser.dart
│       ├── food_search.dart
│       ├── calorie_summary.dart
│       ├── macro_progress_bar.dart
│       └── animated_progress_ring.dart
├── android/                         # Android-specific files
├── ios/                            # iOS-specific files
├── web/                            # Web-specific files
├── test/                           # Unit and widget tests
├── pubspec.yaml                    # Dependencies and configuration
└── .env                            # Environment variables (optional)
```

---

## 🛠️ Technology Stack

### Framework & Languages
- **Flutter 3.35.4** - Cross-platform UI framework
- **Dart 3.9.2** - Programming language

### State Management & Architecture
- **Provider Pattern** - Lightweight state management
- **Service Layer Architecture** - Clean separation of concerns
- **Singleton Pattern** - Efficient resource management

### Backend & Database
- **Firebase Core** - Backend infrastructure
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL cloud database
- **Google Sign-In** - OAuth authentication

### AI & Machine Learning
- **Google Generative AI (Gemini 2.5 Flash)** - Cloud AI for advanced features
- **Hugging Face Inference API** - Alternative cloud AI
- **Fallback AI Service** - Local AI with 500+ food database

### APIs & External Services
- **OpenFoodFacts API** - Nutrition database
- **Calorie Ninjas API** - Alternative nutrition data
- **Enhanced Multi-API Search** - Intelligent API fallback system

### UI/UX Libraries
- **Google Fonts** - Custom typography
- **Mobile Scanner** - Barcode scanning
- **Cached Network Image** - Efficient image loading
- **Custom Animations** - Smooth UI transitions

### Development Tools
- **Logger** - Advanced logging
- **Flutter Dotenv** - Environment variable management
- **HTTP Package** - Network requests
- **Analysis Options** - Code quality linting

---

## 🔑 Key Technologies Explained

### AI Integration
The app features a **dual-mode AI system**:

1. **Cloud AI Mode** (Optional)
   - Uses Gemini or Hugging Face API
   - More advanced natural language understanding
   - Dynamic recipe generation
   - Personalized recommendations

2. **Fallback AI Mode** (Always Available)
   - 100% offline functionality
   - 500+ food database
   - Rule-based nutrition advice
   - Template-based recipe generation
   - Zero latency responses

### Firebase Integration
- **Authentication**: Email/password and Google OAuth
- **Firestore**: Real-time data sync
- **Security**: Row-level security rules
- **Offline Support**: Local caching with automatic sync

### Barcode Scanner
- **Mobile Scanner**: Native camera integration
- **Platform Support**: Android and iOS
- **API Integration**: Automatic nutrition lookup
- **Manual Entry**: Web fallback option

---

## 📊 Features in Detail

### 1. Food Logging
- Search extensive food database
- Scan barcodes for instant lookup
- AI-powered natural language parsing
- Manual nutrition entry
- Serving size customization

### 2. Meal Planning
- Create 7-day meal plans
- Breakfast, Lunch, Dinner, Snacks
- Drag-and-drop interface
- Automatic nutrition totals
- Save and reuse plans

### 3. Progress Tracking
- Daily calorie trends
- Macro nutrient breakdown
- Weight tracking graphs
- Goal achievement metrics
- Weekly summaries

### 4. AI Nutrition Advisor
- Ask nutrition questions
- Get personalized advice
- Learn about healthy eating
- Understand macro nutrients
- Diet strategy recommendations

### 5. Recipe Generator
- Input available ingredients
- Set dietary preferences
- Generate healthy recipes
- View nutrition information
- Save favorite recipes

---

## 🎯 Use Cases

### For Individuals
- **Weight Loss**: Track calories and maintain deficit
- **Muscle Building**: Monitor protein intake
- **Healthy Eating**: Balance macronutrients
- **Medical Needs**: Manage specific dietary requirements

### For Fitness Enthusiasts
- **Performance Tracking**: Optimize nutrition for workouts
- **Meal Prep**: Plan and track weekly meals
- **Macro Counting**: Precise nutrient tracking

### For Students & Learners
- **Nutrition Education**: Learn about food and health
- **Project Reference**: Example Flutter architecture
- **AI Integration**: Study AI implementation patterns

---

## 🔐 Security & Privacy

- **Local-First**: All data stored locally by default
- **Optional Cloud Sync**: User controls data sharing
- **Secure Authentication**: Firebase Auth with encryption
- **No Tracking**: No analytics or user tracking
- **Open Source**: Transparent codebase

---

## 🧪 Testing

Run tests:
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# Coverage report
flutter test --coverage
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` before committing
- Add comments for complex logic
- Write tests for new features

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) - Amazing framework
- [Firebase](https://firebase.google.com) - Backend infrastructure
- [OpenFoodFacts](https://world.openfoodfacts.org) - Nutrition database
- [Hugging Face](https://huggingface.co) - AI models
- [Google Fonts](https://fonts.google.com) - Typography

---

## 🔮 Future Enhancements

- [ ] Water intake tracking
- [ ] Exercise logging and integration
- [ ] Social features and meal sharing
- [ ] Wearable device integration
- [ ] Voice-controlled food logging
- [ ] Restaurant menu nutrition lookup
- [ ] Grocery list generation
- [ ] Meal preparation timers
- [ ] Nutrition goal templates
- [ ] Multi-language support

---

## 📞 Support

If you encounter any issues or have questions:
- Open an [Issue](https://github.com/yourusername/diet-planner/issues)
- Check the [Documentation](docs/)
- Join our community discussions

---

## ⭐ Show Your Support

If you find this project helpful, please give it a ⭐️ on GitHub!

---

**Built with ❤️ using Flutter**
