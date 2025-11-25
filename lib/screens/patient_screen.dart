import 'package:flutter/material.dart';
import '../services/huggingface_ai_service.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diseaseController = TextEditingController();
  final _aiService = HuggingFaceAIService.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _suggestedRecipes = [];
  String? _selectedDisease;

  // Common diseases for quick selection
  final List<String> _commonDiseases = [
    'Diabetes',
    'Hypertension (High Blood Pressure)',
    'Heart Disease',
    'Kidney Disease',
    'Obesity',
    'High Cholesterol',
    'Celiac Disease (Gluten Intolerance)',
    'Lactose Intolerance',
    'GERD (Acid Reflux)',
    'IBS (Irritable Bowel Syndrome)',
    'Anemia',
    'Thyroid Disorder',
    'Osteoporosis',
    'Cancer',
    'Food Allergies',
  ];

  @override
  void dispose() {
    _diseaseController.dispose();
    super.dispose();
  }

  Future<void> _getSuggestions() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _suggestedRecipes = [];
    });

    try {
      final disease = _diseaseController.text.trim();

      // Try to get AI-generated recipes
      try {
        final prompt =
            'As a nutrition expert, suggest 5 healthy recipes for someone with $disease. '
            'For each recipe include: recipe name, brief description, health benefits for $disease, '
            'main ingredients, estimated calories, and prep time.';

        final response = await _aiService.getNutritionAdvice(prompt);

        if (response != null && response.length > 50) {
          final recipes = _parseRecipes(response);
          if (recipes.isNotEmpty) {
            setState(() {
              _suggestedRecipes = recipes;
            });
            return;
          }
        }
      } catch (e) {
        print('AI service error: $e');
      }

      // Fallback to predefined recipes based on disease
      final fallbackRecipes = _getFallbackRecipes(disease);
      setState(() {
        _suggestedRecipes = fallbackRecipes;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Showing curated recipes for your condition'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFallbackRecipes(String disease) {
    final lowerDisease = disease.toLowerCase();

    // Disease-specific recipe databases
    if (lowerDisease.contains('diabetes')) {
      return [
        {
          'name': 'Quinoa & Vegetable Bowl',
          'description':
              'A fiber-rich bowl with quinoa, roasted vegetables, and chickpeas',
          'benefits':
              'Low glycemic index, helps maintain stable blood sugar levels',
          'ingredients':
              'Quinoa, broccoli, bell peppers, chickpeas, olive oil, herbs',
          'calories': 350,
          'prepTime': '25 minutes',
          'servings': '1-2 servings per day',
          'portionSize': '1.5 cups',
        },
        {
          'name': 'Grilled Salmon with Asparagus',
          'description': 'Omega-3 rich salmon with fresh asparagus and lemon',
          'benefits':
              'High in protein and omega-3, helps improve insulin sensitivity',
          'ingredients': 'Salmon fillet, asparagus, lemon, garlic, olive oil',
          'calories': 320,
          'prepTime': '20 minutes',
          'servings': '1 serving per day (2-3 times per week)',
          'portionSize': '4-6 oz salmon',
        },
        {
          'name': 'Lentil & Spinach Soup',
          'description': 'Hearty soup packed with protein and iron',
          'benefits': 'High fiber content helps slow glucose absorption',
          'ingredients':
              'Red lentils, spinach, tomatoes, onions, garlic, spices',
          'calories': 280,
          'prepTime': '35 minutes',
          'servings': '1-2 servings per day',
          'portionSize': '1.5 cups',
        },
        {
          'name': 'Chicken & Avocado Salad',
          'description': 'Fresh salad with grilled chicken and healthy fats',
          'benefits':
              'Balanced meal with protein and healthy fats for blood sugar control',
          'ingredients':
              'Chicken breast, avocado, mixed greens, cherry tomatoes, olive oil',
          'calories': 380,
          'prepTime': '15 minutes',
          'servings': '1 serving per day',
          'portionSize': '1 large salad bowl',
        },
        {
          'name': 'Steel-Cut Oats with Berries',
          'description':
              'Slow-digesting oats topped with antioxidant-rich berries',
          'benefits': 'Low GI breakfast that provides sustained energy',
          'ingredients':
              'Steel-cut oats, blueberries, strawberries, almonds, cinnamon',
          'calories': 290,
          'prepTime': '30 minutes',
          'servings': '1 serving per day (breakfast)',
          'portionSize': '1 cup cooked oats',
        },
      ];
    } else if (lowerDisease.contains('hypertension') ||
        lowerDisease.contains('blood pressure')) {
      return [
        {
          'name': 'DASH Diet Buddha Bowl',
          'description':
              'Low-sodium bowl with whole grains, vegetables, and lean protein',
          'benefits': 'Low sodium, high potassium helps reduce blood pressure',
          'ingredients':
              'Brown rice, grilled chicken, kale, sweet potato, avocado',
          'calories': 400,
          'prepTime': '30 minutes',
          'servings': '1-2 servings per day',
          'portionSize': '2 cups',
        },
        {
          'name': 'Baked Cod with Herbs',
          'description': 'Herb-crusted cod with roasted vegetables',
          'benefits': 'Low sodium, heart-healthy omega-3 fatty acids',
          'ingredients':
              'Cod fillet, herbs (no salt), lemon, garlic, mixed vegetables',
          'calories': 290,
          'prepTime': '25 minutes',
          'servings': '1 serving per day (3-4 times per week)',
          'portionSize': '5 oz fish',
        },
        {
          'name': 'Banana & Oat Smoothie',
          'description': 'Potassium-rich smoothie with no added sugar',
          'benefits': 'High potassium helps counteract sodium effects',
          'ingredients': 'Banana, oats, Greek yogurt, almond milk, cinnamon',
          'calories': 250,
          'prepTime': '5 minutes',
          'servings': '1 serving per day (morning or snack)',
          'portionSize': '12 oz',
        },
        {
          'name': 'Mediterranean Chickpea Salad',
          'description':
              'Fresh salad with chickpeas and heart-healthy ingredients',
          'benefits': 'Rich in fiber and potassium, naturally low in sodium',
          'ingredients':
              'Chickpeas, cucumber, tomatoes, red onion, olive oil, lemon',
          'calories': 320,
          'prepTime': '15 minutes',
          'servings': '1 serving per day',
          'portionSize': '2 cups',
        },
        {
          'name': 'Spinach & Mushroom Frittata',
          'description':
              'Protein-rich egg dish with potassium-packed vegetables',
          'benefits':
              'High in potassium and magnesium for blood pressure control',
          'ingredients': 'Eggs, spinach, mushrooms, onions, herbs (no salt)',
          'calories': 260,
          'prepTime': '20 minutes',
          'servings': '1 serving per day (breakfast or lunch)',
          'portionSize': '2 slices',
        },
      ];
    } else if (lowerDisease.contains('heart')) {
      return [
        {
          'name': 'Mediterranean Grilled Fish',
          'description': 'Heart-healthy fish with olive oil and vegetables',
          'benefits':
              'Omega-3 fatty acids reduce inflammation and improve heart health',
          'ingredients':
              'White fish, olive oil, tomatoes, olives, garlic, herbs',
          'calories': 310,
          'prepTime': '20 minutes',
          'servings': '1 serving per day (4-5 times per week)',
          'portionSize': '5-6 oz fish',
        },
        {
          'name': 'Walnut & Berry Salad',
          'description': 'Antioxidant-rich salad with heart-healthy nuts',
          'benefits':
              'Walnuts contain omega-3 ALA, berries reduce oxidative stress',
          'ingredients':
              'Mixed greens, walnuts, blueberries, strawberries, balsamic',
          'calories': 280,
          'prepTime': '10 minutes',
          'servings': '1-2 servings per day',
          'portionSize': '2 cups (¼ cup walnuts max)',
        },
        {
          'name': 'Oatmeal with Flaxseed',
          'description': 'Fiber-rich breakfast with omega-3 seeds',
          'benefits': 'Soluble fiber helps lower cholesterol levels',
          'ingredients': 'Oats, ground flaxseed, banana, almond milk, cinnamon',
          'calories': 300,
          'prepTime': '15 minutes',
          'servings': '1 serving per day (breakfast)',
          'portionSize': '1 cup cooked',
        },
        {
          'name': 'Grilled Vegetable Stack',
          'description': 'Colorful layered vegetables with herbs',
          'benefits':
              'Rich in antioxidants and fiber for cardiovascular health',
          'ingredients':
              'Eggplant, zucchini, tomatoes, bell peppers, olive oil',
          'calories': 220,
          'prepTime': '25 minutes',
          'servings': '1-2 servings per day',
          'portionSize': '1.5 cups',
        },
        {
          'name': 'Lentil & Tomato Stew',
          'description': 'Fiber and protein-packed vegetarian stew',
          'benefits': 'Lentils help lower cholesterol and improve heart health',
          'ingredients': 'Lentils, tomatoes, carrots, celery, garlic, herbs',
          'calories': 290,
          'prepTime': '40 minutes',
          'servings': '1-2 servings per day',
          'portionSize': '1.5 cups',
        },
      ];
    }

    // Default healthy recipes for other conditions
    return [
      {
        'name': 'Rainbow Veggie Stir-Fry',
        'description': 'Colorful mix of vegetables with lean protein',
        'benefits': 'Packed with vitamins, minerals, and antioxidants',
        'ingredients':
            'Mixed vegetables, tofu or chicken, ginger, garlic, soy sauce',
        'calories': 320,
        'prepTime': '20 minutes',
        'servings': '1 serving per day',
        'portionSize': '2 cups',
      },
      {
        'name': 'Greek Yogurt Parfait',
        'description': 'Layered yogurt with fruits and nuts',
        'benefits': 'High in protein and probiotics for gut health',
        'ingredients': 'Greek yogurt, mixed berries, granola, honey, nuts',
        'calories': 280,
        'prepTime': '5 minutes',
        'servings': '1-2 servings per day',
        'portionSize': '1 cup',
      },
      {
        'name': 'Baked Sweet Potato & Black Beans',
        'description': 'Nutrient-dense vegetarian meal',
        'benefits': 'High fiber, complex carbs, and plant-based protein',
        'ingredients': 'Sweet potato, black beans, avocado, salsa, lime',
        'calories': 350,
        'prepTime': '45 minutes',
        'servings': '1 serving per day',
        'portionSize': '1 large potato + ½ cup beans',
      },
      {
        'name': 'Green Smoothie Bowl',
        'description': 'Nutrient-packed blended greens with toppings',
        'benefits': 'Rich in vitamins, minerals, and antioxidants',
        'ingredients': 'Spinach, banana, mango, chia seeds, almond butter',
        'calories': 310,
        'prepTime': '10 minutes',
        'servings': '1 serving per day (breakfast or snack)',
        'portionSize': '1.5 cups',
      },
      {
        'name': 'Herb-Roasted Chicken & Vegetables',
        'description': 'Simple one-pan meal with lean protein',
        'benefits': 'Balanced meal with protein and vegetables',
        'ingredients':
            'Chicken breast, carrots, Brussels sprouts, herbs, olive oil',
        'calories': 380,
        'prepTime': '40 minutes',
        'servings': '1 serving per day',
        'portionSize': '4-6 oz chicken + 1.5 cups vegetables',
      },
    ];
  }

  List<Map<String, dynamic>> _parseRecipes(String response) {
    final recipes = <Map<String, dynamic>>[];
    final recipeSections = response.split('---');

    for (final section in recipeSections) {
      if (section.trim().isEmpty) continue;

      final recipe = <String, dynamic>{};
      final lines = section.split('\n');

      for (final line in lines) {
        if (line.contains('RECIPE:')) {
          recipe['name'] = line.replaceFirst('RECIPE:', '').trim();
        } else if (line.contains('DESCRIPTION:')) {
          recipe['description'] = line.replaceFirst('DESCRIPTION:', '').trim();
        } else if (line.contains('BENEFITS:')) {
          recipe['benefits'] = line.replaceFirst('BENEFITS:', '').trim();
        } else if (line.contains('INGREDIENTS:')) {
          recipe['ingredients'] = line.replaceFirst('INGREDIENTS:', '').trim();
        } else if (line.contains('CALORIES:')) {
          final caloriesStr = line.replaceFirst('CALORIES:', '').trim();
          recipe['calories'] =
              int.tryParse(caloriesStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        } else if (line.contains('PREP_TIME:')) {
          recipe['prepTime'] = line.replaceFirst('PREP_TIME:', '').trim();
        }
      }

      if (recipe.isNotEmpty && recipe['name'] != null) {
        recipes.add(recipe);
      }
    }

    return recipes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00B4D8),
            const Color(0xFF90E0EF).withValues(alpha: 0.2),
            const Color(0xFFF8F9FA),
          ],
          stops: const [0.0, 0.3, 0.6],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Patient Diet Plans',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get personalized recipes for your condition',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Disease Input Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select or Enter Disease/Condition',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Dropdown for common diseases
                                DropdownButtonFormField<String>(
                                  value: _selectedDisease,
                                  decoration: const InputDecoration(
                                    labelText: 'Select from common conditions',
                                    prefixIcon: Icon(
                                      Icons.local_hospital_outlined,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Select a condition...'),
                                    ),
                                    ..._commonDiseases.map((disease) {
                                      return DropdownMenuItem(
                                        value: disease,
                                        child: Text(disease),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDisease = value;
                                      if (value != null) {
                                        _diseaseController.text = value;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Text input for custom disease
                                TextFormField(
                                  controller: _diseaseController,
                                  decoration: const InputDecoration(
                                    labelText: 'Or enter custom condition',
                                    prefixIcon: Icon(Icons.edit_outlined),
                                    hintText: 'e.g., Gluten sensitivity',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter or select a condition';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      setState(() {
                                        _selectedDisease = null;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Get Suggestions Button
                                ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _getSuggestions,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.restaurant_menu),
                                            SizedBox(width: 8),
                                            Text(
                                              'Get Recipe Suggestions',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Results
                      if (_suggestedRecipes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Recommended Recipes for ${_diseaseController.text}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recipe Cards
                        ..._suggestedRecipes.map((recipe) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildRecipeCard(recipe),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showRecipeDetails(recipe);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xFF00B4D8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['name'] ?? 'Recipe',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe['prepTime'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe['calories'] ?? 0} cal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recipe['description'] ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recipe['benefits'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    recipe['name'] ?? 'Recipe',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.access_time,
                        recipe['prepTime'] ?? 'N/A',
                      ),
                      _buildInfoChip(
                        Icons.local_fire_department,
                        '${recipe['calories'] ?? 0} cal',
                      ),
                      if (recipe['portionSize'] != null)
                        _buildInfoChip(
                          Icons.restaurant_menu,
                          recipe['portionSize'],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Daily Servings Info
                  if (recipe['servings'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Recommended: ${recipe['servings']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe['description'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Health Benefits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recipe['benefits'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Ingredients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe['ingredients'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recipe saved to your favorites!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_add),
                        SizedBox(width: 8),
                        Text('Save Recipe'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00B4D8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF00B4D8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
