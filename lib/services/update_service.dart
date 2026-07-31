import 'dart:io' show Platform;
import '../config/environment.dart';
import '../services/http_service.dart';
import '../utils/logger.dart';

/// 更新检查结果
class UpdateResult {
  final String latestVersion;
  final String releaseNotes;
  /// 当前平台对应的下载链接（过滤后仅保留一条）
  final String? downloadUrl;
  /// 所有资产的下载链接
  final List<String> downloadUrls;
  final bool hasUpdate;

  UpdateResult({
    required this.latestVersion,
    required this.releaseNotes,
    this.downloadUrl,
    required this.downloadUrls,
    required this.hasUpdate,
  });
}

/// 更新检查服务 —— 通过GitHub API检测新版本
class UpdateService {
  final HttpService _httpService;

  UpdateService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  Future<UpdateResult> checkForUpdate() async {
    Logger.i('Checking for updates...');
    try {
      const apiUrl = 'https://api.github.com/repos/${Environment.githubRepo}/releases/latest';
      final response = await _httpService.getJson(
        apiUrl,
        timeout: const Duration(seconds: 10),
        maxRetries: 1,
      );
      if (response.success && response.data != null) {
        final releaseData = response.data!;
        final latestVersion = releaseData['tag_name'] ?? '0.0.0';
        final releaseNotes = releaseData['body'] ?? '';
        final assets = releaseData['assets'] as List? ?? [];

        // 平台感知：根据当前平台过滤对应安装包后缀
        final platformExt = _getPlatformExtension();
        final allUrls = <String>[];
        String? platformUrl;

        for (final asset in assets) {
          final url = asset['browser_download_url'] as String? ?? '';
          final name = asset['name'] as String? ?? '';
          if (url.isEmpty) continue;
          allUrls.add(url);
          // 匹配当前平台的文件后缀
          if (platformExt != null && name.toLowerCase().endsWith(platformExt)) {
            platformUrl = url;
          }
        }

        // 如果最新 Release 中没有当前平台的安装包，静默忽略
        Logger.d('Found latest version: $latestVersion, platformUrl: $platformUrl');
        return UpdateResult(
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: platformUrl,
          downloadUrls: allUrls,
          hasUpdate: platformUrl != null,
        );
      }
      throw Exception('Failed to parse update response');
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, context: 'Update check');
      throw Exception('检查更新失败: $e');
    }
  }

  /// 返回当前平台对应的安装包后缀
  String? _getPlatformExtension() {
    try {
      if (Platform.isAndroid) return '.apk';
      if (Platform.isWindows) return '.exe';
      return null;
    } catch (_) {
      return null;
    }
  }

  String buildReleaseUrl(String version) {
    return 'https://github.com/${Environment.githubRepo}/releases/tag/$version';
  }

  void dispose() {
    _httpService.dispose();
  }
}