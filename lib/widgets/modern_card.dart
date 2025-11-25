import 'package:flutter/material.dart';
import 'dart:ui';
import '../config/app_theme.dart';

/// A beautiful, modern card widget with multiple style variants
class ModernCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool elevated;
  final bool glassmorphism;
  final List<BoxShadow>? customShadow;
  final Border? border;

  const ModernCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.onTap,
    this.elevated = true,
    this.glassmorphism = false,
    this.customShadow,
    this.border,
  });

  /// Creates a card with gradient background
  factory ModernCard.gradient({
    Key? key,
    required Widget child,
    required Gradient gradient,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      key: key,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      gradient: gradient,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates a glassmorphism style card
  factory ModernCard.glass({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      key: key,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      glassmorphism: true,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.radiusXl);

    if (glassmorphism) {
      return _buildGlassCard(radius);
    }

    return _buildRegularCard(radius);
  }

  Widget _buildGlassCard(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: customShadow ?? AppTheme.shadowMd,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: radius,
              border:
                  border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
            ),
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
            child: onTap != null
                ? Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: radius,
                      child: child,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }

  Widget _buildRegularCard(BorderRadius radius) {
    final cardContent = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppTheme.surface) : null,
        gradient: gradient,
        borderRadius: radius,
        border: border,
        boxShadow: elevated ? (customShadow ?? AppTheme.shadowMd) : null,
      ),
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: cardContent),
      );
    }

    return cardContent;
  }
}

/// A feature card with icon, title, and optional action
class FeatureCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;
  final Widget? trailing;

  const FeatureCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color = AppTheme.primary,
    this.onTap,
    this.compact = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: EdgeInsets.all(
        compact ? AppTheme.spacingMd : AppTheme.spacingLg,
      ),
      border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      child: compact ? _buildCompactLayout() : _buildFullLayout(),
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        _buildIconContainer(),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (onTap != null && trailing == null)
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppTheme.textTertiary,
          ),
      ],
    );
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildIconContainer(), if (trailing != null) trailing!],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          title,
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            subtitle!,
            style: AppTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

/// A stat card showing a value with label
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;
  final double? progress;
  final String? target;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.color = AppTheme.primary,
    this.progress,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTheme.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!, style: AppTheme.bodySmall.copyWith(color: color)),
              ],
              if (target != null) ...[
                Text(' / $target', style: AppTheme.bodySmall),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
