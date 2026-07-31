import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/settings.dart';
import '../services/weather_api.dart';
import '../services/update_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../utils/version_utils.dart';
import '../config/environment.dart';
import '../config/platform_config.dart';
import '../utils/logger.dart';

enum QueryType { now, hourly, daily, chart, unified }

class AppState extends ChangeNotifier {
  final WeatherApiService _weatherApi = WeatherApiService();
  final UpdateService _updateService = UpdateService();
  final StorageService _storageService = StorageService();

  AppSettings _settings = AppSettings();
  List<String> _searchHistory = [];
  String _currentCity = '';
  String _queryTime = '';
  QueryType _currentQueryType = QueryType.now;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSettingsPage = false;
  bool _hasUpdate = false;
  String _latestVersion = '';
  String _releaseNotes = '';
  bool _isMajorUpdate = false;
  bool _isInitialized = false;
  String _majorVersion = '';
  String? _lastQueryCity;
  String? _lastQueryTime;
  int? _lastQueryTimestamp;
  Set<String> _cachedCities = {};
  bool _hasCachedQuery = false;
  bool _isFirstLaunch = true;
  bool _locationPromptShown = false;
  bool _restoredCache = false;  // 防止重复恢复缓存

  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  String get majorVersion => _majorVersion;
  List<String> get searchHistory => _searchHistory;
  String get currentCity => _currentCity;
  String get queryTime => _queryTime;
  QueryType get currentQueryType => _currentQueryType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSettingsPage => _isSettingsPage;
  bool get hasUpdate => _hasUpdate;
  String get latestVersion => _latestVersion;
  String get releaseNotes => _releaseNotes;
  bool get hasMajorUpdate => _isMajorUpdate;
  String? get lastQueryCity => _lastQueryCity;
  String? get lastQueryTime => _lastQueryTime;
  Set<String> get cachedCities => _cachedCities;
  bool get hasCachedQuery => _hasCachedQuery;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get locationPromptShown => _locationPromptShown;
  bool get restoredCache => _restoredCache;

  /// 标记位置提示已显示，避免重复弹出 — 持久化到本地
  Future<void> markLocationPromptShown() async {
    _locationPromptShown = true;
    _isFirstLaunch = false;
    await _storageService.saveLocationPromptShown(true);
    await _storageService.saveIsFirstLaunch(false);
    Logger.d('Location prompt marked as shown and persisted');
  }

  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? get weatherData => _weatherData;

  /// 统一查询数据 — 包含 now + hourly + daily
  Map<String, dynamic>? _unifiedData;
  Map<String, dynamic>? get unifiedData => _unifiedData;

  final Map<String, Map<String, dynamic>> _weatherCache = {};
  static const int _maxCacheSize = 20;

  void _addToCache(String key, Map<String, dynamic> data) {
    if (_weatherCache.length >= _maxCacheSize) {
      final firstKey = _weatherCache.keys.first;
      _weatherCache.remove(firstKey);
    }
    _weatherCache[key] = data;
  }

  Future<void> initialize() async {
    Logger.i('Initializing AppState...');
    try {
      await _storageService.init();
      _settings = _storageService.loadSettings();
      _searchHistory = _storageService.loadHistory();

      _cachedCities = _storageService.loadCachedCities();
      final cachedQuery = _storageService.loadLastQueryCache();
      if (cachedQuery != null) {
        _lastQueryCity = cachedQuery['city'] as String?;
        _lastQueryTime = cachedQuery['queryTime'] as String?;
        _lastQueryTimestamp = _storageService.loadLastQueryTimestamp();
        _hasCachedQuery = true;
      }

      // 从本地加载首次启动和位置提示标志，避免每次重启都重置
      _isFirstLaunch = _storageService.loadIsFirstLaunch();
      _locationPromptShown = _storageService.loadLocationPromptShown();
      Logger.d('First launch: $_isFirstLaunch, Location prompt shown: $_locationPromptShown');

      _isInitialized = true;
      _majorVersion = getMajorVersion(Environment.fullVersion);
      Logger.i('AppState initialized successfully');

      // Android: 请求位置权限
      if (PlatformConfig.isAndroid) {
        PermissionService.requestLocationPermission();
      }

      if (_settings.autoQueryLocation) {
        _autoQueryLocation();
      }

      _checkForUpdateInBackground();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, context: 'App initialization');
      _isInitialized = true;
      _majorVersion = '';
    }
    notifyListeners();
  }

  void _autoQueryLocation() async {
    try {
      final city = await detectLocation();
      if (city != null && city.isNotEmpty) {
        _currentCity = city;
        await queryUnifiedWeather();
      }
    } catch (e) {
      Logger.w('Auto location query failed: $e');
    }
  }

  void _checkForUpdateInBackground() async {
    Logger.d('Checking for updates in background...');
    try {
      final result = await _updateService.checkForUpdate();
      final cmp = compareVersions(Environment.fullVersion, result.latestVersion);
      if (cmp < 0) {
        _hasUpdate = true;
        _latestVersion = result.latestVersion;
        _releaseNotes = result.releaseNotes;
        _isMajorUpdate = isMajorUpdate(Environment.fullVersion, result.latestVersion);
        Logger.i('Update available: ${result.latestVersion}');
        notifyListeners();
      } else {
        Logger.d('No update available');
      }
    } catch (e) {
      Logger.w('Background update check failed: $e');
    }
  }

  Future<void> checkUpdate() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _updateService.checkForUpdate();
      _latestVersion = result.latestVersion;
      _releaseNotes = result.releaseNotes;
      final cmp = compareVersions(Environment.fullVersion, result.latestVersion);
      if (cmp < 0) {
        _hasUpdate = true;
        _isMajorUpdate = isMajorUpdate(Environment.fullVersion, result.latestVersion);
      } else {
        _hasUpdate = false;
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
      Logger.e('Update check failed: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearUpdate() {
    _hasUpdate = false;
    notifyListeners();
  }

  void setSettingsPage(bool value) {
    _isSettingsPage = value;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    bool saved = await _storageService.saveSettings(_settings);
    // 如果保存失败，尝试重新初始化 StorageService 后再保存一次
    if (!saved) {
      Logger.w('Settings save failed, retrying after re-init...');
      await _storageService.init();
      saved = await _storageService.saveSettings(_settings);
      if (!saved) {
        Logger.e('Settings save failed after retry');
      }
    }
    notifyListeners();
  }

  Future<void> queryWeather(QueryType type, {bool forceRefresh = false}) async {
    final city = _currentCity.trim();
    if (city.isEmpty) {
      _errorMessage = '请输入城市名称';
      notifyListeners();
      return;
    }

    final cacheKey = '$city|${type.name}';

    if (!forceRefresh && _weatherCache.containsKey(cacheKey)) {
      Logger.d('Using cached weather data for $cacheKey');
      final cached = _weatherCache[cacheKey]!;
      _weatherData = cached['data'] as Map<String, dynamic>?;
      _queryTime = cached['queryTime'] as String? ?? '';
      _errorMessage = null;
      _isSettingsPage = false;
      _currentQueryType = type;
      notifyListeners();
      return;
    }

    _isSettingsPage = false;
    _currentQueryType = type;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _storageService.addToHistory(city);
      _searchHistory = _storageService.loadHistory();

      final queryTime = formatCurrentTime();

      if (forceRefresh) {
        final response = await _fetchByType(type, city);
        if (response.isSuccess && response.data != null) {
          _weatherData = response.data;
          _queryTime = queryTime;
          _errorMessage = null;
          _addToCache(cacheKey, {
            'data': _weatherData,
            'queryTime': _queryTime,
          });
        } else {
          _weatherData = null;
          _errorMessage = response.message;
        }
      } else {
        final results = await Future.wait([
          _weatherApi.getCurrentWeather(city),
          _weatherApi.getHourlyForecast(city),
          _weatherApi.getDailyForecast(city),
        ]);

        final nowResponse = results[0];
        final hourlyResponse = results[1];
        final dailyResponse = results[2];

        if (nowResponse.isSuccess && nowResponse.data != null) {
          _addToCache('$city|now', {
            'data': nowResponse.data,
            'queryTime': queryTime,
          });
        }
        if (hourlyResponse.isSuccess && hourlyResponse.data != null) {
          _addToCache('$city|hourly', {
            'data': hourlyResponse.data,
            'queryTime': queryTime,
          });
        }
        if (dailyResponse.isSuccess && dailyResponse.data != null) {
          _addToCache('$city|daily', {
            'data': dailyResponse.data,
            'queryTime': queryTime,
          });
          _addToCache('$city|chart', {
            'data': dailyResponse.data,
            'queryTime': queryTime,
          });
        }

        final targetKey = '$city|${type.name}';
        if (_weatherCache.containsKey(targetKey)) {
          final cached = _weatherCache[targetKey]!;
          _weatherData = cached['data'] as Map<String, dynamic>?;
          _queryTime = cached['queryTime'] as String? ?? '';
          _errorMessage = null;
        } else {
          final fallbackKey = '$city|now';
          if (_weatherCache.containsKey(fallbackKey)) {
            _currentQueryType = QueryType.now;
            final cached = _weatherCache[fallbackKey]!;
            _weatherData = cached['data'] as Map<String, dynamic>?;
            _queryTime = cached['queryTime'] as String? ?? '';
            _errorMessage = null;
          } else {
            _weatherData = null;
            _errorMessage = '获取天气数据失败，请检查城市名称';
          }
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, context: 'Weather query');
      _weatherData = null;
      _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<WeatherApiResponse> _fetchByType(QueryType type, String city) async {
    switch (type) {
      case QueryType.now:
        return await _weatherApi.getCurrentWeather(city);
      case QueryType.hourly:
        return await _weatherApi.getHourlyForecast(city);
      case QueryType.daily:
      case QueryType.chart:
      case QueryType.unified:
        return await _weatherApi.getDailyForecast(city);
    }
  }

  /// 统一查询 — 一次搜索获取全部天气数据（实时+每小时+每日）
  Future<void> queryUnifiedWeather({bool forceRefresh = false}) async {
    final city = _currentCity.trim();
    if (city.isEmpty) {
      _errorMessage = '请输入城市名称';
      notifyListeners();
      return;
    }

    _isSettingsPage = false;
    _currentQueryType = QueryType.unified;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _storageService.addToHistory(city);
      _searchHistory = _storageService.loadHistory();

      // 清理旧缓存，避免内存沉积
      clearOldCache(city);

      final queryTime = formatCurrentTime();

      final results = await Future.wait([
        _weatherApi.getCurrentWeather(city),
        _weatherApi.getHourlyForecast(city),
        _weatherApi.getDailyForecast(city),
      ]);

      final nowResponse = results[0];
      final hourlyResponse = results[1];
      final dailyResponse = results[2];

      if (nowResponse.isSuccess && nowResponse.data != null) {
        _unifiedData = {
          'now': nowResponse.data!['now'],
          'hourly': (hourlyResponse.isSuccess && hourlyResponse.data != null)
              ? hourlyResponse.data!['hourly']
              : null,
          'daily': (dailyResponse.isSuccess && dailyResponse.data != null)
              ? dailyResponse.data!['daily']
              : null,
        };

        final nowData = nowResponse.data!['now'];
        if (nowData is Map<String, dynamic>) {
          final rawTemp = nowData['temp'];
          final rawWindSpeed = nowData['windSpeed'];
          if (rawTemp is num) {
            _unifiedData!['convertedTemp'] = _convertTemperature(rawTemp.toDouble());
          }
          if (rawWindSpeed is num) {
            _unifiedData!['convertedWindSpeed'] = _convertWindSpeed(rawWindSpeed.toDouble());
          }
        }

        _weatherData = nowResponse.data;
        _queryTime = queryTime;
        _errorMessage = null;

        // 缓存各类型数据
        _addToCache('$city|now', {'data': nowResponse.data, 'queryTime': queryTime});
        if (hourlyResponse.isSuccess && hourlyResponse.data != null) {
          _addToCache('$city|hourly', {'data': hourlyResponse.data, 'queryTime': queryTime});
        }
        if (dailyResponse.isSuccess && dailyResponse.data != null) {
          _addToCache('$city|daily', {'data': dailyResponse.data, 'queryTime': queryTime});
        }

        saveQueryCache();
      } else {
        _unifiedData = null;
        _weatherData = null;
        _errorMessage = nowResponse.message;
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, context: 'Unified weather query');
      _unifiedData = null;
      _weatherData = null;
      _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCity(String city) {
    _currentCity = city;
    notifyListeners();
  }

  Future<List<Map<String, String>>> searchCities(String query) async {
    return await _weatherApi.searchCities(query);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearCache() {
    _weatherCache.clear();
    Logger.d('Weather cache cleared');
  }

  Future<String?> detectLocation() async {
    // IP 定位 API 链式 fallback（仅中文 API，避免返回拼音/英文地名）
    // 优先级：pconline（国内最稳定，UTF-8 JSON）→ ip-api.com（中文）
    const apis = [
      _LocationApi('https://whois.pconline.com.cn/ipJson.jsp?json=true', _parsePconline),
      _LocationApi('http://ip-api.com/json/?lang=zh-CN&fields=city,regionName,country', _parseIpApi),
    ];

    for (final api in apis) {
      try {
        final uri = Uri.parse(api.url);
        final response = await http.get(
          uri,
          headers: const {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          // 显式 UTF-8 解码，避免服务器未声明 charset 时乱码
          final body = utf8.decode(response.bodyBytes);
          Logger.d('Location API ${api.url} responded: ${body.length} chars');
          final city = api.parser(body);
          if (city != null && city.isNotEmpty) {
            Logger.d('Location detected via ${api.url}: $city');
            return city;
          }
          Logger.d('Location API ${api.url} returned empty city');
        } else {
          Logger.d('Location API ${api.url} returned status ${response.statusCode}');
        }
      } catch (e) {
        Logger.d('Location API ${api.url} failed: $e');
      }
    }
    Logger.w('All location APIs failed');
    return null;
  }

  /// 解析 pconline.com.cn 响应（UTF-8 JSON），优先取 city，fallback 到 pro
  static String? _parsePconline(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        // 检查是否有错误
        final err = data['err'];
        if (err != null && err.toString().isNotEmpty) return null;
        final city = data['city'] as String?;
        if (city != null && city.isNotEmpty && _isValidCityName(city)) {
          return city;
        }
        // city 无效时用 pro 作为 fallback
        final pro = data['pro'] as String?;
        if (pro != null && pro.isNotEmpty) return pro;
        return data['addr'] as String?;
      }
    } catch (e) {
      Logger.d('Failed to parse pconline response: $e');
    }
    return null;
  }

  /// 判断是否为有效城市名（排除街道/片区级地名）
  /// 规则：以行政后缀结尾（市/区/县/州/盟/旗/镇/乡），或长度>=3，或全英文
  static bool _isValidCityName(String name) {
    // 纯英文地名（如 Changsha）直接通过
    if (RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(name)) return true;
    // 以行政后缀结尾
    const citySuffixes = ['市', '区', '县', '州', '盟', '旗', '镇', '乡'];
    if (citySuffixes.any((s) => name.endsWith(s))) return true;
    // 长度>=3（如"长沙市"）
    if (name.length >= 3) return true;
    return false;
  }

  /// 解析 ip-api.com 响应，优先取有效 city，fallback 到 regionName → country
  static String? _parseIpApi(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final city = data['city'] as String?;
        if (city != null && city.isNotEmpty && _isValidCityName(city)) return city;
        final region = data['regionName'] as String?;
        if (region != null && region.isNotEmpty && _isValidCityName(region)) return region;
        return data['country'] as String?;
      }
    } catch (e) {
      Logger.d('Failed to parse ip-api.com response: $e');
    }
    return null;
  }

  Future<void> saveQueryCache() async {
    if (_unifiedData == null || _currentCity.isEmpty) return;
    try {
      await _storageService.saveLastQueryCache(_unifiedData!, _queryTime, _currentCity);
      await _storageService.addCachedCity(_currentCity);
      _cachedCities = _storageService.loadCachedCities();
      _lastQueryCity = _currentCity;
      _lastQueryTime = _queryTime;
      _lastQueryTimestamp = DateTime.now().millisecondsSinceEpoch;
      _hasCachedQuery = true;
      Logger.d('Query cache saved for $_currentCity at $_queryTime');
    } catch (e) {
      Logger.e('Failed to save query cache: $e');
    }
  }

  Future<void> restoreCachedQuery() async {
    if (_restoredCache) return;  // 已恢复过，不再重复
    final cachedQuery = _storageService.loadLastQueryCache();
    if (cachedQuery == null) return;
    try {
      final data = cachedQuery['data'];
      final queryTime = cachedQuery['queryTime'] as String? ?? '';
      final city = cachedQuery['city'] as String? ?? '';
      if (data is Map<String, dynamic>) {
        _unifiedData = data;
        _queryTime = queryTime;
        _currentCity = city;
        _hasCachedQuery = true;
        _lastQueryCity = city;
        _lastQueryTime = queryTime;
        _lastQueryTimestamp = _storageService.loadLastQueryTimestamp();
        _restoredCache = true;
        Logger.d('Cached query restored for $city, timestamp: $_lastQueryTimestamp');
        notifyListeners();
      }
    } catch (e) {
      Logger.e('Failed to restore cached query: $e');
    }
  }

  void clearOldCache(String newCity) {
    if (_lastQueryCity != null && _lastQueryCity != newCity) {
      final oldCity = _lastQueryCity;
      _lastQueryCity = null;
      _lastQueryTime = null;
      _hasCachedQuery = false;
      _storageService.clearLastQueryCache();
      Logger.d('Old cache cleared for $oldCity');
    }
  }

  /// 检查上次查询是否在缓存提示间隔内（返回 true 表示需要提示用户）
  bool shouldPromptCache(String city) {
    if (_lastQueryCity != city) return false;
    final timestamp = _lastQueryTimestamp;
    if (timestamp == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - timestamp;
    final thresholdMs = _settings.cachePromptMinutes * 60 * 1000;
    final shouldPrompt = elapsed < thresholdMs;
    Logger.d('Cache check: elapsed=${elapsed}ms, threshold=${thresholdMs}ms, shouldPrompt=$shouldPrompt');
    return shouldPrompt;
  }

  double _convertTemperature(double celsius) {
    if (_settings.temperatureUnit == '℉') {
      return celsius * 9 / 5 + 32;
    }
    return celsius;
  }

  double _convertWindSpeed(double kmh) {
    if (_settings.windSpeedUnit == 'm/s') {
      return kmh / 3.6;
    }
    return kmh;
  }

  @override
  void dispose() {
    try {
      _weatherApi.dispose();
      _updateService.dispose();
    } catch (_) {}
    super.dispose();
  }
}

/// IP 定位 API 描述
class _LocationApi {
  final String url;
  final String? Function(String) parser;
  const _LocationApi(this.url, this.parser);
}