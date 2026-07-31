import '../config/environment.dart';
import '../services/http_service.dart';
import '../utils/logger.dart';

/// 天气API响应模型
class WeatherApiResponse {
  final String code;
  final String message;
  final Map<String, dynamic>? data;

  WeatherApiResponse({required this.code, required this.message, this.data});

  bool get isSuccess => code == '200';
}

/// 天气API服务 —— 封装和风天气API的所有请求
class WeatherApiService {
  final HttpService _httpService;

  WeatherApiService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  /// 通用API请求方法，解析天气数据响应
  Future<WeatherApiResponse> _makeRequest(String url, Map<String, String> params) async {
    try {
      final response = await _httpService.getJson(url, queryParameters: params);
      if (response.success && response.data != null) {
        final data = response.data!;
        if (data.containsKey('error')) {
          return WeatherApiResponse(
            code: '${data['error']['status']}',
            message: data['error']['detail'] ?? '未知错误',
          );
        }
        return WeatherApiResponse(code: data['code'] ?? '200', message: 'success', data: data);
      }
      return WeatherApiResponse(
        code: '${response.statusCode ?? 500}',
        message: response.errorMessage ?? '请求失败',
      );
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, context: 'Weather API request');
      return WeatherApiResponse(code: '500', message: ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// 根据城市名称模糊搜索locationId
  Future<String?> getLocationId(String city) async {
    if (city.isEmpty) return null;

    final variants = <String>{
      city,
      city.replaceAll(' ', '').replaceAll('省', '').replaceAll('市', '').replaceAll('自治区', ''),
      city.replaceAll(' ', ''),
      city.replaceAll(RegExp(r'市$'), ''),
      city.replaceAll(RegExp(r'省$'), ''),
      city.replaceAll(RegExp(r'自治区$'), ''),
      city.split(' ').last,
    }.where((v) => v.isNotEmpty).toList();

    for (final variant in variants) {
      Logger.d('Searching location for: $variant');
      final response = await _makeRequest(Environment.geoApiUrl, {
        'location': variant,
        'key': Environment.apiKey,
        'range': 'cn',
        'number': '10',
        'mode': 'fuzzy',
      });
      if (response.isSuccess && response.data != null) {
        final locations = response.data!['location'] as List?;
        if (locations != null && locations.isNotEmpty) {
          for (final loc in locations) {
            if (loc['name'] == variant || loc['name'] == city.replaceAll(RegExp(r'市$'), '')) {
              return loc['id'];
            }
          }
          return locations[0]['id'];
        }
      }
    }
    Logger.w('Location not found for: $city');
    return null;
  }

  Future<WeatherApiResponse> getCurrentWeather(String city) async {
    Logger.i('Getting current weather for: $city');
    final locationId = await getLocationId(city);
    if (locationId == null) {
      return WeatherApiResponse(code: '404', message: '未找到城市: $city，请检查城市名称是否正确');
    }
    return _makeRequest(Environment.nowWeatherUrl, {
      'location': locationId,
      'key': Environment.apiKey,
      'lang': 'zh',
    });
  }

  Future<WeatherApiResponse> getHourlyForecast(String city) async {
    Logger.i('Getting hourly forecast for: $city');
    final locationId = await getLocationId(city);
    if (locationId == null) {
      return WeatherApiResponse(code: '404', message: '未找到城市: $city，请检查城市名称是否正确');
    }
    return _makeRequest(Environment.hourlyWeatherUrl, {
      'location': locationId,
      'key': Environment.apiKey,
      'lang': 'zh',
    });
  }

  Future<WeatherApiResponse> getDailyForecast(String city) async {
    Logger.i('Getting daily forecast for: $city');
    final locationId = await getLocationId(city);
    if (locationId == null) {
      return WeatherApiResponse(code: '404', message: '未找到城市: $city，请检查城市名称是否正确');
    }
    return _makeRequest(Environment.dailyWeatherUrl, {
      'location': locationId,
      'key': Environment.apiKey,
      'lang': 'zh',
    });
  }

  void dispose() {
    _httpService.dispose();
  }

  Future<List<Map<String, String>>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await _makeRequest(Environment.geoApiUrl, {
      'location': query,
      'key': Environment.apiKey,
      'range': 'cn',
      'number': '10',
      'mode': 'fuzzy',
    });

    if (response.isSuccess && response.data != null) {
      final locations = response.data!['location'] as List?;
      if (locations != null) {
        return locations.map<Map<String, String>>((loc) => {
          'name': loc['name']?.toString() ?? '',
          'adm1': loc['adm1']?.toString() ?? '',
          'adm2': loc['adm2']?.toString() ?? '',
          'id': loc['id']?.toString() ?? '',
        }).toList();
      }
    }
    return [];
  }
}