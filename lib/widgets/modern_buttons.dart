import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// A beautiful gradient button with multiple styles
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final IconData? icon;
  final bool isLoading;
  final bool outlined;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
    this.width,
    this.height = 56,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: isDisabled ? null : _onTapDown,
        onTapUp: isDisabled ? null : _onTapUp,
        onTapCancel: isDisabled ? null : _onTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.outlined
                ? null
                : (isDisabled
                      ? LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        )
                      : (widget.gradient ?? AppTheme.primaryGradient)),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: widget.outlined
                ? Border.all(
                    color: isDisabled ? Colors.grey.shade300 : AppTheme.primary,
                    width: 2,
                  )
                : null,
            boxShadow: widget.outlined || isDisabled
                ? null
                : AppTheme.shadowColored(AppTheme.primary),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        widget.outlined ? AppTheme.primary : Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.outlined
                              ? (isDisabled ? Colors.grey : AppTheme.primary)
                              : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                      ],
                      Text(
                        widget.text,
                        style: AppTheme.labelLarge.copyWith(
                          color: widget.outlined
                              ? (isDisabled ? Colors.grey : AppTheme.primary)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A pill-shaped chip button for selections
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final IconData? icon;

  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.selectedColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppTheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: selected ? color : AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: selected ? color : AppTheme.divider,
                width: 1.5,
              ),
              boxShadow: selected ? AppTheme.shadowSm : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                ],
                Text(
                  label,
                  style: AppTheme.labelLarge.copyWith(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An icon button with beautiful styling
class StyledIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final bool outlined;
  final String? tooltip;

  const StyledIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.size = 48,
    this.outlined = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.primary;
    final bgColor = backgroundColor ?? iconColor.withValues(alpha: 0.1);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: outlined
                ? Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: size * 0.5),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
