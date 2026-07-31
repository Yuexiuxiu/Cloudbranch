import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/platform_config.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// 液态玻璃卡片 — 带 BackdropFilter 模糊效果，细边框
/// 是否启用毛玻璃效果由 AppState.settings.useHarmonyGlass 控制
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double bgOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool? isDark;

  GlassCard({
    super.key,
    required this.child,
    double? borderRadius,
    double? blurSigma,
    double? bgOpacity,
    double? borderOpacity,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.isDark,
  })  : borderRadius = borderRadius ?? PlatformConfig.radiusMD,
       blurSigma = blurSigma ?? PlatformConfig.glassBlurSigma,
       bgOpacity = bgOpacity ?? PlatformConfig.glassBgOpacity,
       borderOpacity = borderOpacity ?? PlatformConfig.glassBorderOpacity;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final bgColor = AppTheme.bgColor(dark);
    final borderColor = dark
        ? Colors.white.withOpacity(borderOpacity)
        : Colors.black.withOpacity(borderOpacity * 0.6);

    // 检查是否启用毛玻璃效果
    final useGlass = context.watch<AppState>().settings.useHarmonyGlass;
    final effectiveBlurSigma = useGlass ? blurSigma : 0.0;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
            sigmaX: effectiveBlurSigma, sigmaY: effectiveBlurSigma),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor.withOpacity(bgOpacity),
                bgColor.withOpacity(bgOpacity * 0.7),
              ],
            ),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (dark ? Colors.white : Colors.black).withOpacity(0.05),
          highlightColor: (dark ? Colors.white : Colors.black).withOpacity(0.03),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (width != null || height != null) {
      card = SizedBox(width: width, height: height, child: card);
    }

    return card;
  }
}

/// 简洁按钮
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final double bgOpacity;
  final double borderOpacity;

  const GlassButton({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 14,
    this.bgOpacity = 0.25,
    this.borderOpacity = 0.20,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: PlatformConfig.animationDurationMS),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(widget.bgOpacity),
            border: Border.all(
              color: Colors.white.withOpacity(widget.borderOpacity),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 液态玻璃 Dialog 包装器 — 鸿蒙液态玻璃效果，平台自适应
Widget buildGlassDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  required List<Widget> actions,
  double? borderRadius,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final r = borderRadius ?? PlatformConfig.radiusLG;
  return Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: EdgeInsets.symmetric(
      horizontal: PlatformConfig.horizontalPadding * 2,
      vertical: PlatformConfig.spacingXL,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(r),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: PlatformConfig.isAndroid ? 10 : 6,
          sigmaY: PlatformConfig.isAndroid ? 10 : 6,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF))
                    .withOpacity(PlatformConfig.isAndroid ? 0.92 : 0.88),
                (isDark ? const Color(0xFF151A24) : const Color(0xFFF2F2F7))
                    .withOpacity(PlatformConfig.isAndroid ? 0.85 : 0.80),
              ],
            ),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(PlatformConfig.isAndroid ? 0.10 : 0.08),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(r),
          ),
          child: RepaintBoundary(
            child: Padding(
              padding: EdgeInsets.all(PlatformConfig.spacingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  SizedBox(height: PlatformConfig.spacingMD),
                  content,
                  SizedBox(height: PlatformConfig.spacingLG),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}