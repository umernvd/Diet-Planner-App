import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/user_profile.dart';
import '../services/food_database_service.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/modern_card.dart';
import '../features/calculator/presentation/screens/bmr_calculator_input_screen.dart';
import 'log_food_screen.dart';
import 'meal_planner_screen.dart';
import 'progress_screen.dart';
import 'recipe_screen_enhanced.dart';
import 'patient_screen.dart';
import 'profile_screen.dart';
import 'ai_nutrition_advisor_screen.dart';
import 'ai_recipe_generator_screen.dart';

class HomeScreenRedesigned extends StatefulWidget {
  const HomeScreenRedesigned({super.key});

  @override
  State<HomeScreenRedesigned> createState() => _HomeScreenRedesignedState();
}

class _HomeScreenRedesignedState extends State<HomeScreenRedesigned>
    with TickerProviderStateMixin {
  int _index = 0;
  final _db = FoodDatabaseService.instance;
  final _auth = FirebaseAuthService.instance;
  final _profile = UserProfile.sample();

  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  String get _userName {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 'Friend';
    final displayName = currentUser.displayName;
    if (displayName == null || displayName.isEmpty) return 'Friend';
    return displayName.split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _onAddFood(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildOverview(context),
      LogFoodScreen(onAdd: _onAddFood),
      const MealPlannerScreen(),
      const ProgressScreen(),
      const RecipeScreenEnhanced(),
      const PatientScreen(),
      ProfileScreen(
        onLoginSuccess: () {
          setState(() => _index = 0);
        },
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(_index), child: screens[_index]),
      ),
      bottomNavigationBar: _buildModernNavBar(),
    );
  }

  Widget _buildModernNavBar() {
    final navItems = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(
        Icons.restaurant_menu_outlined,
        Icons.restaurant_menu_rounded,
        'Log',
      ),
      _NavItem(
        Icons.calendar_month_outlined,
        Icons.calendar_month_rounded,
        'Plan',
      ),
      _NavItem(Icons.insights_outlined, Icons.insights_rounded, 'Progress'),
      _NavItem(
        Icons.auto_stories_outlined,
        Icons.auto_stories_rounded,
        'Recipes',
      ),
      _NavItem(
        Icons.health_and_safety_outlined,
        Icons.health_and_safety_rounded,
        'Patient',
      ),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(navItems.length, (i) {
              final item = navItems[i];
              final isSelected = _index == i;
              return _buildNavItem(item, isSelected, i);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                size: isSelected ? 24 : 22,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final today = DateTime.now();
    final calories = _db.caloriesFor(today);

    final loggedAll = _db.getLoggedFoods(today).toList();
    final proteinConsumed = loggedAll.fold<double>(
      0.0,
      (sum, f) => sum + f.protein,
    );
    final carbsConsumed = loggedAll.fold<double>(
      0.0,
      (sum, f) => sum + f.carbs,
    );
    final fatConsumed = loggedAll.fold<double>(0.0, (sum, f) => sum + f.fat);

    final targetCalories = _profile.goal.dailyCalories;
    final calorieProgress = targetCalories > 0
        ? (calories / targetCalories).clamp(0.0, 1.0)
        : 0.0;

    final targetProteinGrams =
        (targetCalories * _profile.goal.proteinRatio) / 4.0;
    final targetCarbsGrams = (targetCalories * _profile.goal.carbsRatio) / 4.0;
    final targetFatGrams = (targetCalories * _profile.goal.fatRatio) / 9.0;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.heroGradient),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Hero Header
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _headerAnimation.value)),
                    child: Opacity(
                      opacity: _headerAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreetingText(),
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hi, $_userName! 👋',
                              style: AppTheme.headlineLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                _getMotivationalQuote(),
                                style: AppTheme.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GradientAvatar(
                        initials: _userName.isNotEmpty
                            ? _userName[0].toUpperCase()
                            : '?',
                        size: 56,
                        borderGradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Calorie Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ModernCard(
                  padding: const EdgeInsets.all(28),
                  borderRadius: BorderRadius.circular(28),
                  customShadow: AppTheme.shadowXl,
                  child: Column(
                    children: [
                      // Progress Ring
                      EnhancedProgressRing(
                        progress: calorieProgress,
                        size: 180,
                        strokeWidth: 16,
                        showGlow: true,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              calories.toStringAsFixed(0),
                              style: AppTheme.displaySmall.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'kcal consumed',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                '${targetCalories.toStringAsFixed(0)} goal',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Macros Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMacroItem(
                              'Protein',
                              proteinConsumed,
                              targetProteinGrams,
                              AppTheme.accentRose,
                              Icons.egg_alt_rounded,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: AppTheme.divider,
                          ),
                          Expanded(
                            child: _buildMacroItem(
                              'Carbs',
                              carbsConsumed,
                              targetCarbsGrams,
                              AppTheme.accentWarm,
                              Icons.bakery_dining_rounded,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: AppTheme.divider,
                          ),
                          Expanded(
                            child: _buildMacroItem(
                              'Fat',
                              fatConsumed,
                              targetFatGrams,
                              AppTheme.accent,
                              Icons.water_drop_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // AI Features Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI-Powered Features',
                          style: AppTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAICard(
                            'AI Advisor',
                            'Get personalized\nnutrition advice',
                            Icons.psychology_rounded,
                            AppTheme.primaryGradient,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AINutritionAdvisorScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAICard(
                            'Recipe Gen',
                            'Create healthy\nrecipes instantly',
                            Icons.auto_fix_high_rounded,
                            AppTheme.accentGradient,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AIRecipeGeneratorScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      'BMR Calculator',
                      'Calculate your daily calorie needs',
                      Icons.local_fire_department_rounded,
                      AppTheme.accentWarm,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BmrCalculatorInputScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Today's Meals Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Meals", style: AppTheme.headlineSmall),
                    TextButton.icon(
                      onPressed: () => setState(() => _index = 1),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add_rounded, size: 16),
                      ),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Meals List
            _buildMealsList(),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(
    String label,
    double current,
    double target,
    Color color,
    IconData icon,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: current.toStringAsFixed(0),
                style: AppTheme.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '/${target.toStringAsFixed(0)}g',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAICard(
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withValues(
                alpha: 0.35,
              ),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTheme.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return FeatureCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onTap: onTap,
      compact: true,
    );
  }

  Widget _buildMealsList() {
    final today = DateTime.now();
    final logged = _db.getLoggedFoods(today).reversed.toList();

    if (logged.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 56,
                  color: AppTheme.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text('No meals logged yet', style: AppTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Start tracking your nutrition today!',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _index = 1),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Log Your First Meal'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          if (i >= logged.length) return null;
          final f = logged[i];

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 350 + (i * 80)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 24 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  onLongPress: () => _showFoodOptions(context, f, today),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                style: AppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'P: ${f.protein.toStringAsFixed(0)}g • C: ${f.carbs.toStringAsFixed(0)}g • F: ${f.fat.toStringAsFixed(0)}g',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                '${f.calories.toStringAsFixed(0)} kcal',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Delete meal',
                              onPressed: () {
                                _db.removeLoggedFood(today, f);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Deleted ${f.name}'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () {
                                        _db.logFood(today, f);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getGreetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationalQuote() {
    final quotes = [
      '💪 Every healthy meal counts!',
      '🌟 You\'re doing amazing!',
      '🎯 Stay focused on your goals!',
      '🌱 Nourish your body today!',
      '✨ Small steps, big results!',
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  void _showFoodOptions(BuildContext context, food, DateTime today) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  food.name,
                  style: AppTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                  ),
                ),
                title: const Text('Delete from log'),
                subtitle: const Text('Remove this meal from today'),
                onTap: () {
                  Navigator.pop(context);
                  _db.removeLoggedFood(today, food);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text('Deleted ${food.name}'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: AppTheme.primaryLight,
                        onPressed: () {
                          _db.logFood(today, food);
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for navigation items
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(this.icon, this.selectedIcon, this.label);
}
