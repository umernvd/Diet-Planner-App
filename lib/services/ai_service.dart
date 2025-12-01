import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

class AIService {
  AIService._();

  static final AIService instance = AIService._();

  static const String _defaultModel = 'gemini-2.5-flash';
  final Logger _logger = Logger();
  GenerativeModel? _model;

  bool get isConfigured =>
      (dotenv.env['GEMINI_API_KEY'] ?? '').trim().isNotEmpty;

  GenerativeModel get _client {
    if (_model != null) return _model!;
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY not found. Ensure dotenv is loaded before using AIService.',
      );
    }
    _model = GenerativeModel(
      model: _defaultModel,
      apiKey: key,
      systemInstruction: Content.text(
        '''You are NutriBot! 🤖 A super friendly, enthusiastic, and knowledgeable nutrition buddy who LOVES helping people with food and health!

Your vibe:
- Chat like you're texting a friend - casual, warm, and real! 😊
- Throw in emojis when it feels right (but don't overdo it)
- Get EXCITED about nutrition! Show your passion! 💪
- Keep it simple - no boring textbook talk
- Say "you" and "your" to make it personal
- Give bite-sized advice that's actually doable
- Share real-life tips and examples people can actually use

What you're awesome at:
- Creating delicious healthy recipes 👨‍🍳
- Diet planning that actually works
- Making healthy eating fun and not boring
- Weight goals (losing, gaining, or maintaining)
- Meal prep hacks and planning
- Breaking down nutrition stuff (macros, micros, all that jazz)
- Food advice for health stuff
- Fitness nutrition that fuels workouts 🏋️
- Finding healthy alternatives to junk food

Your golden rules:
- Keep it short and sweet (under 200 words usually)
- Always be supportive and positive! 🌟
- Ask friendly questions if you need more details
- Say "hey, check with your doctor" for medical stuff - you're not a doctor!
- Make healthy eating sound exciting, not like a chore
- Be enthusiastic but genuine - no fake positivity
- Use casual language like "gonna", "wanna", "let\'s", "awesome", "great"

When creating recipes:
- Be creative and fun with names!
- Make instructions super clear and easy to follow
- Talk like you're cooking together in the kitchen
- Add personal touches and helpful tips
- Show excitement about the food! 🎉''',
      ),
    );
    return _model!;
  }

  Future<String?> getDietAdvice(String userQuery) async {
    if (!isConfigured) return null;
    try {
      final response = await _client.generateContent([Content.text(userQuery)]);
      final text = response.text?.trim();
      return text?.isNotEmpty == true ? text : null;
    } catch (e, st) {
      _logger.e('Gemini diet advice error: $e', error: e, stackTrace: st);
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateRecipe({
    required List<String> ingredients,
    String? dietaryRestrictions,
    String? cuisineType,
    int? targetCalories,
  }) async {
    if (!isConfigured) return null;
    try {
      final prompt =
          '''
Hey! 👨‍🍳 Let's create an awesome recipe together! I've got these ingredients: ${ingredients.join(', ')}.
${dietaryRestrictions != null ? '\nOh, and I need it to be $dietaryRestrictions-friendly! 🥗' : ''}
${cuisineType != null ? '\nI\'m really craving some $cuisineType flavors today! 🌍' : ''}
${targetCalories != null ? '\nTrying to keep it around $targetCalories calories per serving. 💪' : ''}

Can you whip up something delicious? Be creative and make it fun! Talk to me like a friendly chef, not a robot. 😊

Give me a recipe in JSON format (no markdown code blocks, just pure JSON):
{
  "name": "Give it a catchy, appetizing name!",
  "description": "A friendly 1-2 sentence description that makes me hungry",
  "ingredients": ["List all ingredients with measurements in a conversational way"],
  "instructions": ["Step-by-step in a friendly, easy-to-follow tone - like you're teaching a friend"],
  "nutrition": {
    "calories": estimated_calories_number,
    "protein": protein_grams_number,
    "carbs": carbs_grams_number,
    "fat": fat_grams_number
  },
  "tips": ["Add 1-2 casual, helpful cooking tips or variations"],
  "servings": number_of_servings,
  "prepTime": "like 25 minutes"
}

Make it sound natural and enthusiastic - I want to feel excited about cooking this! 🎉
''';

      final response = await _client.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;

      final jsonString = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final recipeData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Extract nutrition info if nested
      if (recipeData['nutrition'] is Map) {
        final nutrition = recipeData['nutrition'] as Map<String, dynamic>;
        recipeData['calories'] = nutrition['calories'] ?? 0;
        recipeData['protein'] = nutrition['protein'] ?? 0;
        recipeData['carbs'] = nutrition['carbs'] ?? 0;
        recipeData['fat'] = nutrition['fat'] ?? 0;
      }

      return recipeData;
    } catch (e, st) {
      _logger.e('Gemini recipe error: $e', error: e, stackTrace: st);
      if (kDebugMode) {
        debugPrint('AI recipe generation failed: $e');
      }
      return null;
    }
  }
}
