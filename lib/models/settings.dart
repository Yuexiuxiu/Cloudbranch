/// 应用设置数据模型
class AppSettings {
  int historyLimit;
  String temperatureUnit;
  String windSpeedUnit;
  List<String> favoriteCities;
  bool autoQueryLocation;
  int cachePromptMinutes;
  bool useHarmonyGlass;
  bool enableLogging;

  AppSettings({
    this.historyLimit = 20,
    this.temperatureUnit = '℃',
    this.windSpeedUnit = 'km/h',
    this.favoriteCities = const [],
    this.autoQueryLocation = false,
    this.cachePromptMinutes = 30,
    this.useHarmonyGlass = true,
    this.enableLogging = true,
  });

  Map<String, dynamic> toJson() => {
        'history_limit': historyLimit,
        'temperature_unit': temperatureUnit,
        'wind_speed_unit': windSpeedUnit,
        'favorite_cities': favoriteCities,
        'auto_query_location': autoQueryLocation,
        'cache_prompt_minutes': cachePromptMinutes,
        'use_harmony_glass': useHarmonyGlass,
        'enable_logging': enableLogging,
      };

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AppSettings();

    try {
      final historyLimit = json['history_limit'];
      final temperatureUnit = json['temperature_unit'];
      final windSpeedUnit = json['wind_speed_unit'];
      final autoQueryLocation = json['auto_query_location'];
      final cachePromptMinutes = json['cache_prompt_minutes'];
      final useHarmonyGlass = json['use_harmony_glass'];

      final enableLogging = json['enable_logging'];

      return AppSettings(
        historyLimit: historyLimit is int ? historyLimit : 20,
        temperatureUnit: temperatureUnit is String && temperatureUnit.isNotEmpty
            ? temperatureUnit
            : '℃',
        windSpeedUnit: windSpeedUnit is String && windSpeedUnit.isNotEmpty
            ? windSpeedUnit
            : 'km/h',
        favoriteCities: _parseFavoriteCities(json['favorite_cities']),
        autoQueryLocation: autoQueryLocation is bool ? autoQueryLocation : false,
        cachePromptMinutes: cachePromptMinutes is int ? cachePromptMinutes : 30,
        useHarmonyGlass: useHarmonyGlass is bool ? useHarmonyGlass : false,
        enableLogging: enableLogging is bool ? enableLogging : false,
      );
    } catch (_) {
      return AppSettings();
    }
  }

  static List<String> _parseFavoriteCities(dynamic value) {
    if (value is List) {
      return value.where((item) => item is String && item.isNotEmpty).cast<String>().toList();
    }
    return [];
  }

  AppSettings copyWith({
    int? historyLimit,
    String? temperatureUnit,
    String? windSpeedUnit,
    List<String>? favoriteCities,
    bool? autoQueryLocation,
    int? cachePromptMinutes,
    bool? useHarmonyGlass,
    bool? enableLogging,
  }) =>
      AppSettings(
        historyLimit: historyLimit ?? this.historyLimit,
        temperatureUnit: temperatureUnit ?? this.temperatureUnit,
        windSpeedUnit: windSpeedUnit ?? this.windSpeedUnit,
        favoriteCities: favoriteCities ?? this.favoriteCities,
        autoQueryLocation: autoQueryLocation ?? this.autoQueryLocation,
        cachePromptMinutes: cachePromptMinutes ?? this.cachePromptMinutes,
        useHarmonyGlass: useHarmonyGlass ?? this.useHarmonyGlass,
        enableLogging: enableLogging ?? this.enableLogging,
      );
}