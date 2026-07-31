import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式管理 — 持久化主题选择
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  /// 0=浅色, 1=深色, 2=跟随系统
  int get themeIndex {
    switch (_themeMode) {
      case ThemeMode.light:
        return 0;
      case ThemeMode.dark:
        return 1;
      case ThemeMode.system:
        return 2;
    }
  }

  /// 从 SharedPreferences 加载主题模式
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_themeKey) ?? 0;
      setThemeFromIndex(index);
    } catch (_) {
      // 默认浅色模式
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveTheme();
      notifyListeners();
    }
  }

  void setThemeFromIndex(int index) {
    switch (index) {
      case 0:
        _themeMode = ThemeMode.light;
        break;
      case 1:
        _themeMode = ThemeMode.dark;
        break;
      case 2:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeIndex);
    } catch (_) {
      // 静默失败
    }
  }

  bool get isDark {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isLight => !isDark;
}