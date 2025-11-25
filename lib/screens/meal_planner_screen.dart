import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/meal.dart';
import '../models/meal_plan.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../services/meal_plan_service.dart';
import '../widgets/food_search.dart';
import '../widgets/animated_widgets.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen>
    with TickerProviderStateMixin {
  final _planService = MealPlanService.instance;
  final _profile = UserProfile.sample();

  DateTime _selectedDate = DateTime.now();
  MealPlan? _currentPlan;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadPlan();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadPlan() {
    setState(() {
      _currentPlan = _planService.getPlanForDate(_selectedDate);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadPlan();
      });
    }
  }

  void _addFoodToMeal(MealType mealType) async {
    final result = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Food to ${mealType.displayName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: FoodSearch(
                    onAdd: (food) {
                      Navigator.pop(context, food);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      _planService.addFoodToMeal(_selectedDate, mealType, result);
      _loadPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${result.name} to ${mealType.displayName}'),
          ),
        );
      }
    }
  }

  void _removeFoodFromMeal(MealType mealType, FoodItem food) {
    final removed = _planService.removeFoodFromMeal(
      _selectedDate,
      mealType,
      food,
    );
    if (removed) {
      _loadPlan();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${food.name}'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              _planService.addFoodToMeal(_selectedDate, mealType, food);
              _loadPlan();
            },
          ),
        ),
      );
    }
  }

  void _showPlanOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Plan to Another Day'),
              onTap: () async {
                if (!mounted) return;
                Navigator.pop(context);
                final targetDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate.add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (targetDate == null) return;
                if (!mounted) return;

                _planService.copyPlanToDate(_selectedDate, targetDate);

                if (!mounted) return;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Plan copied to ${targetDate.month}/${targetDate.day}/${targetDate.year}',
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Add Notes'),
              onTap: () async {
                if (!mounted) return;
                Navigator.pop(context);
                final controller = TextEditingController(
                  text: _currentPlan?.notes ?? '',
                );
                final notes = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Meal Plan Notes'),
                    content: TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Add notes about this meal plan...',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
                if (!mounted) return;
                if (notes != null) {
                  _planService.updateNotes(_selectedDate, notes);
                  _loadPlan();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Clear Plan'),
              onTap: () {
                Navigator.pop(context);
                final deleted = _planService.deletePlan(_selectedDate);
                if (deleted) {
                  _loadPlan();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meal plan cleared')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPlan == null) {
      return Container(
        decoration: BoxDecoration(gradient: AppTheme.heroGradient),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final goalCalories = _profile.goal.dailyCalories;
    final planCalories = _currentPlan!.totalCalories;
    final calorieProgress = goalCalories > 0
        ? (planCalories / goalCalories).clamp(0.0, 1.0)
        : 0.0;

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Meal Planner',
                          style: AppTheme.headlineLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _showPlanOptions,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Date Selector Card
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXl,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Date',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: AppTheme.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nutrition Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                        boxShadow: AppTheme.shadowMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Totals',
                                style: AppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: calorieProgress > 0.9
                                      ? AppTheme.warningGradient
                                      : AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  '${planCalories.toStringAsFixed(0)} / ${goalCalories.toStringAsFixed(0)} kcal',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AnimatedProgressBar(
                            progress: calorieProgress,
                            height: 10,
                            gradient: calorieProgress > 0.9
                                ? AppTheme.warningGradient
                                : AppTheme.primaryGradient,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMacroStat(
                                'Protein',
                                _currentPlan!.totalProtein,
                                AppTheme.accentRose,
                              ),
                              _buildMacroStat(
                                'Carbs',
                                _currentPlan!.totalCarbs,
                                AppTheme.primary,
                              ),
                              _buildMacroStat(
                                'Fat',
                                _currentPlan!.totalFat,
                                AppTheme.accentWarm,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Notes section
                    if (_currentPlan!.notes != null &&
                        _currentPlan!.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.accentWarm.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          border: Border.all(
                            color: AppTheme.accentWarm.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sticky_note_2_rounded,
                              color: AppTheme.accentWarm,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentPlan!.notes!,
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Meals List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final meal = _currentPlan!.meals[index];
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.1 * index,
                            0.1 * index + 0.4,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          0.1 * index,
                          0.1 * index + 0.4,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: _buildMealCard(meal),
                  ),
                );
              }, childCount: _currentPlan!.meals.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  Widget _buildMacroStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTheme.bodySmall),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            '${value.toStringAsFixed(1)}g',
            style: AppTheme.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    final isEmpty = meal.foods.isEmpty;
    final mealColors = _getMealColors(meal.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: mealColors,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: (mealColors.colors.first).withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getMealIcon(meal.type),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.type.displayName,
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (meal.scheduledTime != null)
                          Text(
                            '${meal.scheduledTime!.hour.toString().padLeft(2, '0')}:${meal.scheduledTime!.minute.toString().padLeft(2, '0')}',
                            style: AppTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (!isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: mealColors.colors.first.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${meal.totalCalories.toStringAsFixed(0)} kcal',
                        style: AppTheme.labelMedium.copyWith(
                          color: mealColors.colors.first,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: AppTheme.primary,
                      ),
                      onPressed: () => _addFoodToMeal(meal.type),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: () => _addFoodToMeal(meal.type),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.divider,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: AppTheme.textTertiary),
                        const SizedBox(width: 8),
                        Text(
                          'Add foods to ${meal.type.displayName.toLowerCase()}',
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Column(
                children: meal.foods.asMap().entries.map((entry) {
                  final food = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.divider, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                style: AppTheme.titleMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildMiniMacro(
                                    'P',
                                    food.protein,
                                    AppTheme.accentRose,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMiniMacro(
                                    'C',
                                    food.carbs,
                                    AppTheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMiniMacro(
                                    'F',
                                    food.fat,
                                    AppTheme.accentWarm,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${food.calories.toStringAsFixed(0)}',
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(' kcal', style: AppTheme.bodySmall),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeFoodFromMeal(meal.type, food),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMacro(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTheme.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text('${value.toStringAsFixed(0)}g', style: AppTheme.bodySmall),
      ],
    );
  }

  LinearGradient _getMealColors(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return AppTheme.warmGradient;
      case MealType.lunch:
        return AppTheme.primaryGradient;
      case MealType.dinner:
        return AppTheme.purpleGradient;
      case MealType.snack:
        return AppTheme.accentGradient;
    }
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast_rounded;
      case MealType.lunch:
        return Icons.lunch_dining_rounded;
      case MealType.dinner:
        return Icons.dinner_dining_rounded;
      case MealType.snack:
        return Icons.cookie_rounded;
    }
  }
}
