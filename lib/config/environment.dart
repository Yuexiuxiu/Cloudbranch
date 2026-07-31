// 环境配置类 —— 业务常量的唯一来源
// 平台相关版本/布局信息见 PlatformConfig
import 'platform_config.dart';

class Environment {
  /// 版本号：平台自动适配
  static String get appVersion => PlatformConfig.appVersion;
  static String get fullVersion => appVersion;
  static String get versionName => PlatformConfig.versionName;
  static String get buildDate => PlatformConfig.buildDate;

  static const String githubRepo = 'Yuexiuxiu/Cloudbranch';

  static const String apiKey = '984c5a8b803e4c4a89dd79dfc8511d55';

  static const String geoApiUrl = 'https://geoapi.qweather.com/v2/city/lookup';
  static const String nowWeatherUrl = 'https://api.qweather.com/v7/weather/now';
  static const String hourlyWeatherUrl = 'https://api.qweather.com/v7/weather/24h';
  static const String dailyWeatherUrl = 'https://api.qweather.com/v7/weather/7d';

  static const Duration requestTimeout = Duration(seconds: 15);
  static const int maxRetryCount = 2;
  static const Duration retryDelay = Duration(seconds: 2);
}
