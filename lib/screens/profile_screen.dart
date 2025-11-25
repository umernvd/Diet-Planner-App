import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/firebase_auth_service.dart';
import '../services/food_database_service.dart';
import '../services/meal_plan_service.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/modern_card.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuthService.instance;
    final user = auth.currentUser;
    final isSignedIn = auth.isSignedIn;

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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    GradientAvatar(
                      initials: _getInitials(isSignedIn, user),
                      size: 80,
                      borderGradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFF90E0EF)],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isSignedIn ? (user?.displayName ?? 'User') : 'Guest User',
                      style: AppTheme.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSignedIn && user?.email != null) ...[
                      const SizedBox(height: 6),
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
                          user!.email!,
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                    if (!isSignedIn) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to sync your data',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: AppTheme.headlineSmall),
                    const SizedBox(height: 12),
                    if (!isSignedIn)
                      _buildSettingCard(
                        context,
                        icon: Icons.login_rounded,
                        title: 'Sign In',
                        subtitle: 'Sync your data across devices',
                        color: AppTheme.primary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                      ),
                    if (isSignedIn) ...[
                      _buildSettingCard(
                        context,
                        icon: Icons.cloud_done_rounded,
                        title: 'Cloud Sync',
                        subtitle: 'Your data is automatically synced',
                        color: AppTheme.accent,
                        trailing: _buildCheckBadge(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 24),
                    Text('App', style: AppTheme.headlineSmall),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle: 'Diet Planner v1.0.0',
                      color: AppTheme.primary,
                      onTap: () => _showAboutDialog(context),
                    ),
                    const SizedBox(height: 8),
                    _buildSettingCard(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'How we handle your data',
                      color: AppTheme.accentPurple,
                      onTap: () => _showPrivacyDialog(context),
                    ),
                    if (isSignedIn) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Danger Zone',
                        style: AppTheme.headlineSmall.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        subtitle: 'Sign out of your account',
                        color: AppTheme.accentWarm,
                        onTap: () => _handleSignOut(context, auth),
                      ),
                      const SizedBox(height: 8),
                      _buildSettingCard(
                        context,
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
                        color: AppTheme.error,
                        onTap: () => _handleDeleteAccount(context, auth),
                      ),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(bool isSignedIn, dynamic user) {
    if (!isSignedIn) return 'G';
    final name = user?.displayName;
    if (name != null && name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  Widget _buildCheckBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: const Icon(Icons.check_rounded, color: AppTheme.accent, size: 18),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
          ),
          trailing ??
              (onTap != null
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textTertiary,
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Diet Planner'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: AppTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              'A comprehensive nutrition tracking and meal planning application built with Flutter.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('2024 Muzamil Faryad', style: AppTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        ),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. All data is stored securely '
            'and used only to provide app functionality. We do not share '
            'your personal information with third parties.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(
    BuildContext context,
    FirebaseAuthService auth,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        ),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your data will remain synced in the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await auth.signOut();
      FoodDatabaseService.instance.clearCache();
      MealPlanService.instance.clearAll();
    }
  }

  Future<void> _handleDeleteAccount(
    BuildContext context,
    FirebaseAuthService auth,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure? This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await auth.deleteAccount();
        FoodDatabaseService.instance.clearCache();
        MealPlanService.instance.clearAll();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }
}
