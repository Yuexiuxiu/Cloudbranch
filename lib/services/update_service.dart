import 'dart:io' show Platform;
import '../config/environment.dart';
import '../services/http_service.dart';
import '../utils/logger.dart';

class UpdateResult {
  final String latestVersion;
  final String releaseNotes;
  final String? downloadUrl;
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
        final releaseNotes = releaseData['body'] ?? '';
        final assets = releaseData['assets'] as List? ?? [];

        final platformExt = _getPlatformExtension();
        final allUrls = <String>[];
        String? platformUrl;
        String? platformVersion;

        for (final asset in assets) {
          final url = asset['browser_download_url'] as String? ?? '';
          final name = asset['name'] as String? ?? '';
          if (url.isEmpty) continue;
          allUrls.add(url);
          if (platformExt != null && name.toLowerCase().endsWith(platformExt)) {
            platformUrl = url;
            platformVersion = _extractVersionFromName(name);
          }
        }

        final effectiveVersion = platformVersion ?? releaseData['tag_name'] ?? '0.0.0';
        Logger.d('Found platform version: $effectiveVersion, url: $platformUrl');
        return UpdateResult(
          latestVersion: effectiveVersion,
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

  String? _extractVersionFromName(String name) {
    final match = RegExp(r'v?(\d+\.\d+\.\d+)').firstMatch(name);
    return match?.group(1);
  }

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
