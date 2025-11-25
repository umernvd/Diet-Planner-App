import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/user_profile.dart';
import '../services/food_database_service.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/modern_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _calculateStreak(FoodDatabaseService db, DateTime now) {
    int streak = 0;
    var day = now;
    while (true) {
      if (db.caloriesFor(day) > 0) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String _formatDate(DateTime d) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  IconData _getStatusIcon(double pct) {
    if (pct >= 0.9) return Icons.check_circle_rounded;
    if (pct >= 0.7) return Icons.trending_up_rounded;
    if (pct >= 0.4) return Icons.trending_flat_rounded;
    if (pct > 0) return Icons.trending_down_rounded;
    return Icons.circle_outlined;
  }

  Color _getStatusColor(double pct) {
    if (pct >= 0.9) return AppTheme.accent;
    if (pct >= 0.7) return AppTheme.primary;
    if (pct >= 0.4) return AppTheme.accentWarm;
    return AppTheme.textTertiary;
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTheme.headlineSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FoodDatabaseService.instance;
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: i)));
    final profile = UserProfile.sample();
    final goal = profile.goal.dailyCalories;

    double totalCalories = 0;
    int daysWithData = 0;
    for (var day in days) {
      final cals = db.caloriesFor(day);
      if (cals > 0) {
        totalCalories += cals;
        daysWithData++;
      }
    }
    final avgCalories = daysWithData > 0 ? totalCalories / daysWithData : 0.0;
    final weeklyProgress = goal > 0
        ? (avgCalories / goal).clamp(0.0, 1.0)
        : 0.0;
    final streak = _calculateStreak(db, now);

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.heroGradient),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: AppTheme.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your nutrition journey',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ModernCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(24),
                  customShadow: AppTheme.shadowLg,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weekly Overview',
                                  style: AppTheme.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Last 7 days performance',
                                  style: AppTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Avg. Calories',
                              avgCalories.toStringAsFixed(0),
                              'kcal/day',
                              Icons.local_fire_department_rounded,
                              AppTheme.accentWarm,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: AppTheme.divider,
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Streak',
                              streak.toString(),
                              'days',
                              Icons.whatshot_rounded,
                              AppTheme.accentRose,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: AppTheme.divider,
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Goal Hit',
                              '${(weeklyProgress * 100).toInt()}',
                              '%',
                              Icons.track_changes_rounded,
                              AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AnimatedProgressBar(
                        progress: weeklyProgress,
                        height: 10,
                        showLabel: true,
                        label: 'Weekly Goal Progress',
                        gradient: AppTheme.primaryGradient,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Text('Daily History', style: AppTheme.headlineSmall),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final d = days[i];
                  final cals = db.caloriesFor(d);
                  final pct = (goal <= 0) ? 0.0 : (cals / goal).clamp(0.0, 1.0);
                  final isToday = i == 0;

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 350 + (i * 60)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: isToday ? AppTheme.primaryGradient : null,
                        color: isToday ? null : AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        boxShadow: isToday
                            ? AppTheme.shadowColored(AppTheme.primary)
                            : AppTheme.shadowSm,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            _buildCircularProgress(pct, isToday),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _buildDayInfo(d, cals, goal, isToday),
                            ),
                            _buildStatusBadge(pct, isToday),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: days.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(double pct, bool isToday) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: isToday
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppTheme.primarySoft,
              valueColor: AlwaysStoppedAnimation(
                isToday ? Colors.white : AppTheme.primary,
              ),
            ),
          ),
          Text(
            '${(pct * 100).toInt()}%',
            style: AppTheme.labelLarge.copyWith(
              color: isToday ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayInfo(DateTime d, double cals, double goal, bool isToday) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isToday ? 'Today' : _formatDate(d),
              style: AppTheme.titleMedium.copyWith(
                color: isToday ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  'In Progress',
                  style: AppTheme.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: isToday
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppTheme.accentWarm,
            ),
            const SizedBox(width: 4),
            Text(
              '${cals.toStringAsFixed(0)} kcal',
              style: AppTheme.bodyMedium.copyWith(
                color: isToday ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' / ${goal.toStringAsFixed(0)}',
              style: AppTheme.bodySmall.copyWith(
                color: isToday
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(double pct, bool isToday) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withValues(alpha: 0.2)
            : _getStatusColor(pct).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(
        _getStatusIcon(pct),
        color: isToday ? Colors.white : _getStatusColor(pct),
        size: 22,
      ),
    );
  }
}
