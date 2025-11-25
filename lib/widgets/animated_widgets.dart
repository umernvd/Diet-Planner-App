import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';

/// Enhanced animated circular progress with beautiful gradient and glow effects
class EnhancedProgressRing extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? startColor;
  final Color? endColor;
  final Widget? child;
  final bool showPercentage;
  final bool animate;
  final Duration animationDuration;
  final bool showGlow;

  const EnhancedProgressRing({
    super.key,
    required this.progress,
    this.size = 160,
    this.strokeWidth = 14,
    this.startColor,
    this.endColor,
    this.child,
    this.showPercentage = false,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.showGlow = true,
  });

  @override
  State<EnhancedProgressRing> createState() => _EnhancedProgressRingState();
}

class _EnhancedProgressRingState extends State<EnhancedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.progress,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startColor = widget.startColor ?? AppTheme.primary;
    final endColor = widget.endColor ?? AppTheme.primaryLight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (widget.showGlow)
              Container(
                width: widget.size + 20,
                height: widget.size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: startColor.withValues(
                        alpha: 0.2 * _glowAnimation.value,
                      ),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            // Progress ring
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _EnhancedProgressPainter(
                progress: widget.animate
                    ? _progressAnimation.value
                    : widget.progress,
                strokeWidth: widget.strokeWidth,
                startColor: startColor,
                endColor: endColor,
              ),
            ),
            // Child or percentage
            if (widget.child != null)
              widget.child!
            else if (widget.showPercentage)
              Text(
                '${((widget.animate ? _progressAnimation.value : widget.progress) * 100).toInt()}%',
                style: AppTheme.headlineLarge.copyWith(
                  color: startColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EnhancedProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color startColor;
  final Color endColor;

  _EnhancedProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = AppTheme.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [startColor, endColor, startColor],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // End cap glow
    if (progress > 0) {
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      final glowPaint = Paint()
        ..color = endColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(endX, endY), strokeWidth / 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_EnhancedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// A horizontal progress bar with gradient and animation
class AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final double height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool showLabel;
  final String? label;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.gradient,
    this.color,
    this.borderRadius,
    this.showLabel = false,
    this.label,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    final bgColor = widget.backgroundColor ?? AppTheme.surfaceVariant;
    final progressGradient =
        widget.gradient ??
        LinearGradient(
          colors: [
            widget.color ?? AppTheme.primary,
            (widget.color ?? AppTheme.primary).withValues(alpha: 0.7),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label!, style: AppTheme.bodySmall),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return Text(
                    '${(_animation.value * 100).toInt()}%',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(color: bgColor, borderRadius: radius),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _animation.value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: progressGradient,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.color ?? AppTheme.primary).withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A beautiful circular avatar with gradient border
class GradientAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Gradient? borderGradient;
  final double borderWidth;

  const GradientAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 60,
    this.borderGradient,
    this.borderWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + borderWidth * 2,
      height: size + borderWidth * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: borderGradient ?? AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
          ),
          child: ClipOval(
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitials(),
                  )
                : _buildInitials(),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        initials ?? '?',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

/// Animated tap scale widget for micro-interactions
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final bool enableHaptics;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptics = true,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Pulse animation widget for highlighting important elements
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.97,
    this.maxScale = 1.03,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;

    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Slide in animation for list items
class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 400),
    this.delay = const Duration(milliseconds: 50),
    this.beginOffset = const Offset(0.3, 0),
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Shimmer loading effect for skeleton screens
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? AppTheme.surfaceVariant;
    final highlightColor = widget.highlightColor ?? AppTheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}

/// Count up animation for numbers
class CountUpAnimation extends StatefulWidget {
  final double value;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;

  const CountUpAnimation({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
  });

  @override
  State<CountUpAnimation> createState() => _CountUpAnimationState();
}

class _CountUpAnimationState extends State<CountUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final displayValue = widget.decimalPlaces > 0
            ? _animation.value.toStringAsFixed(widget.decimalPlaces)
            : _animation.value.toInt().toString();
        return Text(
          '${widget.prefix ?? ''}$displayValue${widget.suffix ?? ''}',
          style: widget.style ?? AppTheme.headlineLarge,
        );
      },
    );
  }
}
