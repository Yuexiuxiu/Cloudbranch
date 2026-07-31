import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../config/platform_config.dart';

/// 鸿蒙液态玻璃卡片 — 平台自适应液态玻璃效果
/// [Android Liquid Glass] 性能优化：模糊半径限制 sigmaX/Y <= 10, RepaintBoundary 包裹
/// [Android Liquid Glass] 长按光影涟漪：ShaderMask 从按压点扩散
/// [Windows Liquid Glass] 交互优化：hover 上浮 + 边框高光 + 右键菜单 + 键盘快捷键
class HarmonyGlass extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double bgOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;
  final bool isDark;
  final Color? customBgColor;
  final Color? customBorderColor;
  final bool enableHover;
  final bool enableScaleAnimation;
  /// [Android Liquid Glass] 列表滚动项禁用模糊以保性能
  final bool isInScrollList;
  /// [Windows Liquid Glass] 右键菜单项
  final List<PopupMenuEntry<String>>? contextMenuItems;
  /// [Windows Liquid Glass] 快捷键提示
  final String? shortcutHint;

  const HarmonyGlass({
    super.key,
    required this.child,
    required this.isDark,
    this.borderRadius = 16,
    this.blurSigma = 12,
    this.bgOpacity = 0.80,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
    this.customBgColor,
    this.customBorderColor,
    this.enableHover = true,
    this.enableScaleAnimation = true,
    this.isInScrollList = false,
    this.contextMenuItems,
    this.shortcutHint,
  });

  @override
  State<HarmonyGlass> createState() => _HarmonyGlassState();
}

class _HarmonyGlassState extends State<HarmonyGlass>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  Offset? _longPressPosition;

  // [Android Liquid Glass] 光影涟漪动画
  AnimationController? _rippleController;
  Animation<double>? _rippleAnimation;

  @override
  void initState() {
    super.initState();
    if (PlatformConfig.isAndroid) {
      _rippleController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _rippleController!, curve: Curves.easeOutCubic),
      );
    }
  }

  @override
  void dispose() {
    _rippleController?.dispose();
    super.dispose();
  }

  // [Android Liquid Glass] 液态收缩动画
  double get _scale {
    if (!widget.enableScaleAnimation) return 1.0;
    if (_isPressed) return 0.97;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.customBgColor ??
        AppTheme.glassBg(widget.isDark, opacity: widget.bgOpacity);
    final borderColor =
        widget.customBorderColor ?? AppTheme.glassBorder(widget.isDark);

    final isAndroid = PlatformConfig.isAndroid;

    // 检查是否启用毛玻璃效果
    final useGlass = context.read<AppState>().settings.useHarmonyGlass;

    // [Android Liquid Glass] 限制模糊半径以保证性能
    // 列表滚动项禁用模糊；毛玻璃关闭时模糊归零
    final effectiveBlur = !useGlass || widget.isInScrollList
        ? 0.0
        : isAndroid
            ? widget.blurSigma.clamp(0.0, 10.0)
            : widget.blurSigma.clamp(0.0, 6.0);

    // [Windows Liquid Glass] hover 边框高光
    final effectiveBorderColor = _isHovered &&
            widget.enableHover &&
            !isAndroid
        ? borderColor
            .withOpacity((borderColor.opacity * 2.5).clamp(0.0, 0.4))
        : borderColor;
    final effectiveBorderWidth =
        _isHovered && widget.enableHover && !isAndroid ? 1.0 : 0.5;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      transform: Matrix4.identity()
        ..translate(
            0.0,
            _isHovered && widget.enableHover && !isAndroid
                ? -4.0
                : 0.0)
        ..scale(_scale),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            // 背景模糊
            if (effectiveBlur > 0)
              BackdropFilter(
                filter: ui.ImageFilter.blur(
                    sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                child: _buildGlassBackground(bgColor, effectiveBorderColor,
                    effectiveBorderWidth),
              )
            else
              _buildGlassBackground(
                  bgColor, effectiveBorderColor, effectiveBorderWidth),
            // [Android Liquid Glass] 长按光影涟漪
            if (_longPressPosition != null && _rippleAnimation != null)
              _buildLightRipple(),
            // 内容
            if (widget.padding != null)
              Padding(
                  padding: widget.padding!,
                  child: _buildContentWithShortcut())
            else
              _buildContentWithShortcut(),
          ],
        ),
      ),
    );

    // [Android Liquid Glass] RepaintBoundary 包裹减少重绘
    card = RepaintBoundary(child: card);

    // 交互包装
    card = _wrapInteraction(card);

    // [Windows Liquid Glass] 鼠标悬停检测
    if (!isAndroid && widget.enableHover) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: card,
      );
    }

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    if (widget.width != null || widget.height != null) {
      card = SizedBox(width: widget.width, height: widget.height, child: card);
    }

    return card;
  }

  Widget _buildGlassBackground(
      Color bgColor, Color borderColor, double borderWidth) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withOpacity(widget.bgOpacity * 0.7),
          ],
        ),
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }

  Widget _buildContentWithShortcut() {
    if (widget.shortcutHint == null) return widget.child;
    return Stack(
      children: [
        widget.child,
        // [Windows Liquid Glass] 快捷键提示 Chip
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (widget.isDark ? Colors.white : Colors.black)
                  .withOpacity(0.10),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: (widget.isDark ? Colors.white : Colors.black)
                    .withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Text(
              widget.shortcutHint!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: (widget.isDark ? Colors.white : Colors.black)
                    .withOpacity(0.40),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // [Android Liquid Glass] 长按光影涟漪效果
  Widget _buildLightRipple() {
    return AnimatedBuilder(
      animation: _rippleAnimation!,
      builder: (context, child) {
        final progress = _rippleAnimation!.value;
        return ShaderMask(
          shaderCallback: (bounds) {
            return RadialGradient(
              center: Alignment(
                (_longPressPosition!.dx / bounds.width) * 2 - 1,
                (_longPressPosition!.dy / bounds.height) * 2 - 1,
              ),
              radius: 0.8 * progress,
              colors: [
                Colors.white.withOpacity(0.30 * (1 - progress)),
                Colors.white.withOpacity(0.10 * (1 - progress)),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: Colors.white.withOpacity(0.05 * (1 - progress)),
            ),
          ),
        );
      },
    );
  }

  Widget _wrapInteraction(Widget card) {
    // [Windows Liquid Glass] 右键菜单
    if (widget.contextMenuItems != null && !PlatformConfig.isAndroid) {
      return GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(context, details.globalPosition);
        },
        child: card,
      );
    }

    if (widget.onTap != null || widget.onLongPress != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress ??
              (PlatformConfig.isAndroid
                  ? () => _startLongPressRipple()
                  : null),
          onTapDown: widget.enableScaleAnimation
              ? (details) {
                  setState(() => _isPressed = true);
                  if (PlatformConfig.isAndroid) {
                    _longPressPosition = details.localPosition;
                  }
                }
              : null,
          onTapUp: widget.enableScaleAnimation
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.enableScaleAnimation
              ? () {
                  setState(() => _isPressed = false);
                  _longPressPosition = null;
                }
              : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: (widget.isDark ? Colors.white : Colors.black)
              .withOpacity(PlatformConfig.isAndroid ? 0.05 : 0.2),
          highlightColor: (widget.isDark ? Colors.white : Colors.black)
              .withOpacity(0.03),
          child: card,
        ),
      );
    }

    return card;
  }

  // [Android Liquid Glass] 启动长按光影涟漪
  void _startLongPressRipple() {
    if (_rippleController == null) return;
    _rippleController!.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _longPressPosition = null);
      }
    });
  }

  // [Windows Liquid Glass] 显示右键上下文菜单
  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      items: widget.contextMenuItems!,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
        side: BorderSide(
          color: (widget.isDark ? Colors.white : Colors.black)
              .withOpacity(0.10),
          width: 0.5,
        ),
      ),
      color: widget.isDark
          ? const Color(0xFF1A1F2E).withOpacity(0.95)
          : const Color(0xFFFFFFFF).withOpacity(0.95),
    );
  }
}

/// 鸿蒙液态玻璃 Dialog 包装器
Widget buildHarmonyDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  required List<Widget> actions,
  required bool isDark,
  double borderRadius = 20,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: EdgeInsets.symmetric(
      horizontal: PlatformConfig.horizontalPadding * 2,
      vertical: PlatformConfig.spacingXL,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: HarmonyGlass(
      isDark: isDark,
      borderRadius: borderRadius,
      blurSigma: PlatformConfig.isAndroid ? 10 : 6,
      enableScaleAnimation: false,
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
  );
}