import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';
import '../utils/logger.dart';

/// 本地存储服务 —— 管理设置的持久化和历史记录
class StorageService {
  static const String _settingsKey = 'app_settings';
  static const String _historyKey = 'search_history';
  static const String _cacheDataKey = 'last_query_cache';
  static const String _cacheTimeKey = 'last_query_time';
  static const String _cacheCityKey = 'last_query_city';
  static const String _cacheTimestampKey = 'last_query_timestamp';
  static const String _historyCacheKey = 'history_cache_cities';
  static const String _firstLaunchKey = 'is_first_launch_v1';
  static const String _locationPromptKey = 'location_prompt_shown_v1';

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      Logger.d('StorageService initialized');
    } catch (e) {
      Logger.e('Failed to initialize StorageService: $e');
      _prefs = null;
    }
  }

  AppSettings loadSettings() {
    if (_prefs == null) {
      Logger.w('StorageService not initialized, returning default settings');
      return AppSettings();
    }
    try {
      final jsonStr = _prefs!.getString(_settingsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr);
        return AppSettings.fromJson(json);
      }
    } catch (e) {
      Logger.e('Failed to load settings: $e');
    }
    return AppSettings();
  }

  Future<bool> saveSettings(AppSettings settings) async {
    if (_prefs == null) {
      Logger.w('StorageService not initialized, cannot save settings');
      return false;
    }
    try {
      final result = await _prefs!.setString(_settingsKey, jsonEncode(settings.toJson()));
      Logger.d('Settings saved: ${settings.toJson()}');
      return result;
    } catch (e) {
      Logger.e('Failed to save settings: $e');
      return false;
    }
  }

  List<String> loadHistory() {
    if (_prefs == null) {
      Logger.w('StorageService not initialized, returning empty history');
      return [];
    }
    try {
      final jsonStr = _prefs!.getString(_historyKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final data = jsonDecode(jsonStr);
        if (data is List) {
          return data.where((item) => item is String && item.isNotEmpty).cast<String>().toList();
        }
      }
    } catch (e) {
      Logger.e('Failed to load history: $e');
    }
    return [];
  }

  Future<bool> saveHistory(List<String> history) async {
    if (_prefs == null) {
      Logger.w('StorageService not initialized, cannot save history');
      return false;
    }
    try {
      final validHistory = history.where((city) => city.isNotEmpty).take(20).toList();
      return await _prefs!.setString(_historyKey, jsonEncode(validHistory));
    } catch (e) {
      Logger.e('Failed to save history: $e');
      return false;
    }
  }

  Future<void> addToHistory(String city) async {
    if (city.isEmpty) return;
    try {
      final history = loadHistory();
      history.remove(city);
      history.insert(0, city);
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }
      await saveHistory(history);
    } catch (e) {
      Logger.e('Failed to add to history: $e');
    }
  }

  Future<bool> saveLastQueryCache(Map<String, dynamic> unifiedData, String queryTime, String city) async {
    if (_prefs == null) {
      Logger.w('StorageService not initialized, cannot save cache');
      return false;
    }
    try {
      await _prefs!.setString(_cacheDataKey, jsonEncode(unifiedData));
      await _prefs!.setString(_cacheTimeKey, queryTime);
      await _prefs!.setString(_cacheCityKey, city);
      await _prefs!.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      Logger.d('Last query cache saved: $city at $queryTime');
      return true;
    } catch (e) {
      Logger.e('Failed to save last query cache: $e');
      return false;
    }
  }

  Map<String, dynamic>? loadLastQueryCache() {
    if (_prefs == null) {
      Logger.w('StorageService not initialized, cannot load cache');
      return null;
    }
    try {
      final dataStr = _prefs!.getString(_cacheDataKey);
      final timeStr = _prefs!.getString(_cacheTimeKey);
      final cityStr = _prefs!.getString(_cacheCityKey);
      if (dataStr != null && dataStr.isNotEmpty &&
          timeStr != null && timeStr.isNotEmpty &&
          cityStr != null && cityStr.isNotEmpty) {
        final data = jsonDecode(dataStr);
        return {
          'data': data,
          'queryTime': timeStr,
          'city': cityStr,
        };
      }
    } catch (e) {
      Logger.e('Failed to load last query cache: $e');
    }
    return null;
  }

  Future<void> clearLastQueryCache() async {
    if (_prefs == null) return;
    try {
      await _prefs!.remove(_cacheDataKey);
      await _prefs!.remove(_cacheTimeKey);
      await _prefs!.remove(_cacheCityKey);
      await _prefs!.remove(_cacheTimestampKey);
      Logger.d('Last query cache cleared');
    } catch (e) {
      Logger.e('Failed to clear last query cache: $e');
    }
  }

  /// 获取上次查询的时间戳（毫秒），用于缓存间隔检测
  int? loadLastQueryTimestamp() {
    if (_prefs == null) return null;
    try {
      return _prefs!.getInt(_cacheTimestampKey);
    } catch (e) {
      Logger.e('Failed to load last query timestamp: $e');
      return null;
    }
  }

  Future<void> saveCachedCities(Set<String> cities) async {
    if (_prefs == null) return;
    try {
      await _prefs!.setString(_historyCacheKey, jsonEncode(cities.toList()));
    } catch (e) {
      Logger.e('Failed to save cached cities: $e');
    }
  }

  Set<String> loadCachedCities() {
    if (_prefs == null) return {};
    try {
      final jsonStr = _prefs!.getString(_historyCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final data = jsonDecode(jsonStr);
        if (data is List) {
          return data.where((item) => item is String && item.isNotEmpty).cast<String>().toSet();
        }
      }
    } catch (e) {
      Logger.e('Failed to load cached cities: $e');
    }
    return {};
  }

  Future<void> addCachedCity(String city) async {
    if (city.isEmpty) return;
    try {
      final cities = loadCachedCities();
      cities.add(city);
      await saveCachedCities(cities);
    } catch (e) {
      Logger.e('Failed to add cached city: $e');
    }
  }

  Future<void> removeCachedCity(String city) async {
    if (city.isEmpty) return;
    try {
      final cities = loadCachedCities();
      cities.remove(city);
      await saveCachedCities(cities);
    } catch (e) {
      Logger.e('Failed to remove cached city: $e');
    }
  }

  // ── 首次启动 & 位置提示持久化 ──

  bool loadIsFirstLaunch() {
    if (_prefs == null) return true;
    try {
      return _prefs!.getBool(_firstLaunchKey) ?? true;
    } catch (e) {
      Logger.e('Failed to load first launch flag: $e');
      return true;
    }
  }

  Future<bool> saveIsFirstLaunch(bool value) async {
    if (_prefs == null) {
      Logger.w('StorageService not initialized, cannot save first launch flag');
      return false;
    }
    try {
      return await _prefs!.setBool(_firstLaunchKey, value);
    } catch (e) {
      Logger.e('Failed to save first launch flag: $e');
      return false;
    }
  }

  bool loadLocationPromptShown() {
    if (_prefs == null) return false;
    try {
      return _prefs!.getBool(_locationPromptKey) ?? false;
    } catch (e) {
      Logger.e('Failed to load location prompt flag: $e');
      return false;
    }
  }

  Future<bool> saveLocationPromptShown(bool value) async {
    if (_prefs == null) {
      Logger.w('StorageService not initialized, cannot save location prompt flag');
      return false;
    }
    try {
      return await _prefs!.setBool(_locationPromptKey, value);
    } catch (e) {
      Logger.e('Failed to save location prompt flag: $e');
      return false;
    }
  }
}