import 'package:flutter/material.dart';
import '../config/platform_config.dart';

/// 鸿蒙液态玻璃主题 — 浅色 / 深色
class AppTheme {
  // ── 浅色主题 ──
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF007AFF),
          secondary: Color(0xFF5856D6),
          tertiary: Color(0xFF34C759),
          surface: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(PlatformConfig.radiusLG)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF2F2F7).withOpacity(0.80),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.10), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
            borderSide: BorderSide(color: const Color(0xFF007AFF).withOpacity(0.50), width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: PlatformConfig.spacingMD,
            vertical: PlatformConfig.spacingSM,
          ),
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.30)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: PlatformConfig.spacingLG,
              vertical: PlatformConfig.spacingSM,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF007AFF),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.black.withOpacity(0.08),
          thickness: 1,
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.black.withOpacity(0.80),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
      );

  // ── 深色主题 ──
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A90D9),
          secondary: Color(0xFF5B7FFF),
          tertiary: Color(0xFF7B68EE),
          surface: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(PlatformConfig.radiusLG)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: PlatformConfig.spacingMD,
            vertical: PlatformConfig.spacingSM,
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.15),
            foregroundColor: Colors.white.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlatformConfig.radiusSM),
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: PlatformConfig.spacingLG,
              vertical: PlatformConfig.spacingSM,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.85),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.08),
          thickness: 1,
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.white.withOpacity(0.15),
          contentTextStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PlatformConfig.radiusMD),
            side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
      );

  // ── 鸿蒙液态玻璃色值 ──
  static Color get harmonyGlassLight => const Color(0xCCF2F2F7);
  static Color get harmonyGlassDark => const Color(0xCC1C1C1E);
  static Color get harmonyBorderLight => Colors.white.withOpacity(0.60);
  static Color get harmonyBorderDark => Colors.white.withOpacity(0.12);
  static Color get harmonyTextPrimaryLight => const Color(0xFF1C1C1E);
  static Color get harmonyTextPrimaryDark => Colors.white.withOpacity(0.85);
  static Color get harmonyTextSecondaryLight => const Color(0xFF8E8E93);
  static Color get harmonyTextSecondaryDark => Colors.white.withOpacity(0.45);
  static Color get accentBlue => const Color(0xFF007AFF);

  /// 根据 isDark 返回对应背景色
  static Color bgColor(bool isDark) =>
      isDark ? const Color(0xFF0D1117) : const Color(0xFFF2F2F7);

  /// 根据 isDark 返回对应文字主色
  static Color textPrimary(bool isDark) =>
      isDark ? harmonyTextPrimaryDark : harmonyTextPrimaryLight;

  /// 根据 isDark 返回对应文字次色
  static Color textSecondary(bool isDark) =>
      isDark ? harmonyTextSecondaryDark : harmonyTextSecondaryLight;

  /// 鸿蒙液态玻璃卡片背景
  static Color glassBg(bool isDark, {double opacity = 0.80}) =>
      isDark
          ? harmonyGlassDark.withOpacity(opacity)
          : harmonyGlassLight.withOpacity(opacity);

  /// 鸿蒙液态玻璃边框
  static Color glassBorder(bool isDark) =>
      isDark ? harmonyBorderDark : harmonyBorderLight;
}