import 'dart:io' show Platform;

/// 平台配置中心 — 统一模板 + 平台适配
/// 所有平台差异收敛于此，UI 代码保持统一
class PlatformConfig {
  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// 公开的 Android 平台判断，供 UI 代码使用
  static bool get isAndroid => _isAndroid;

  // ── 版本信息 ──
  static const String windowsVersion = '0.0.22';
  static const String androidVersion = '0.0.4';
  static String get appVersion => _isAndroid ? androidVersion : windowsVersion;
  static const String versionName = '自动更新与稳定性修复';
  static const String buildDate = '2026-07-31';

  // ── 更新日志 ──
  static String get changelogAsset =>
      _isAndroid ? 'CHANGELOG_ANDROID.md' : 'CHANGELOG.md';

  // ── 间距系统 ──
  static double get spacingXS => _isAndroid ? 4.0 : 8.0;
  static double get spacingSM => _isAndroid ? 8.0 : 12.0;
  static double get spacingMD => _isAndroid ? 12.0 : 16.0;
  static double get spacingLG => _isAndroid ? 16.0 : 20.0;
  static double get spacingXL => _isAndroid ? 20.0 : 28.0;

  // ── 水平边距 ──
  static double get horizontalPadding => _isAndroid ? 14.0 : 20.0;

  // ── 圆角 ──
  static double get radiusSM => _isAndroid ? 8.0 : 10.0;
  static double get radiusMD => _isAndroid ? 12.0 : 16.0;
  static double get radiusLG => _isAndroid ? 18.0 : 24.0;
  static double get radiusXL => _isAndroid ? 22.0 : 28.0;

  // ── 卡片样式 ──
  /// 玻璃模糊度 — Windows 6.0 / Android 3.0（性能优化）
  static double get glassBlurSigma => _isAndroid ? 3.0 : 6.0;
  /// 主内容卡片 — 半透明，让背景渐变透出
  static double get glassBgOpacity => _isAndroid ? 0.60 : 0.55;
  /// 次要内容卡片 — 更轻盈（空状态、设置面板、关于页）
  static double get glassBgOpacitySecondary => _isAndroid ? 0.40 : 0.35;
  static double get glassBorderOpacity => _isAndroid ? 0.10 : 0.08;

  // ── 字体 ──
  static double get fontSizeXS => _isAndroid ? 12.0 : 12.0;
  static double get fontSizeSM => _isAndroid ? 14.0 : 13.0;
  static double get fontSizeMD => _isAndroid ? 16.0 : 15.0;
  static double get fontSizeLG => _isAndroid ? 18.0 : 17.0;
  static double get fontSizeXL => _isAndroid ? 22.0 : 20.0;
  static double get fontSizeTitle => _isAndroid ? 24.0 : 24.0;
  static double get fontSizeHero => _isAndroid ? 48.0 : 56.0;

  // ── 图标 ──
  static double get iconSizeSM => _isAndroid ? 18.0 : 16.0;
  static double get iconSizeMD => _isAndroid ? 22.0 : 20.0;
  static double get iconSizeLG => _isAndroid ? 28.0 : 24.0;
  static double get iconSizeXL => _isAndroid ? 36.0 : 32.0;
  static double get iconSizeHero => _isAndroid ? 52.0 : 48.0;

  // ── 导航栏 ──
  static double get navBarHeight => _isAndroid ? 72.0 : 64.0;
  static double get navBarIconSize => _isAndroid ? 26.0 : 22.0;
  static double get navBarFontSize => _isAndroid ? 12.0 : 11.0;

  // ── 搜索栏 ──
  static double get searchBarHeight => _isAndroid ? 48.0 : 44.0;
  static double get searchOverlayWidth =>
      _isAndroid ? double.infinity : 380;
  static double get searchOverlayOffsetY =>
      _isAndroid ? 52.0 : 50.0;

  // ── 查询按钮 ──
  static double get queryChipHeight => _isAndroid ? 40.0 : 36.0;
  static double get queryChipPaddingH => _isAndroid ? 14.0 : 12.0;
  static double get queryChipFontSize => _isAndroid ? 13.0 : 12.0;

  // ── 动画 ──
  static int get animationDurationMS => _isAndroid ? 100 : 150;

  // ── 抽屉 ──
  static double get drawerWidth => _isAndroid ? 280 : 260;

  // ── 触控 ──
  static double get touchTargetMin => _isAndroid ? 48.0 : 40.0;

  // ── 内容最大宽度 (全宽，无限制) ──
  static double? get contentMaxWidth => null;

  // ── 业务限制 ──
  static int get maxHistoryCount => 20;
  static int get maxFavoriteCities => 10;

  // ── 图表 ──
  static double get chartLineWidth => _isAndroid ? 2.5 : 3.0;
  static double get chartDotRadius => _isAndroid ? 3.5 : 4.0;

  // ── 交互 ──
  static bool get supportsHover => !_isAndroid;
  static bool get useDrawer => !_isAndroid;
  static bool get showNavLabels => _isAndroid;
}