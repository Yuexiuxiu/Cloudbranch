import 'dart:developer' as dev;
import 'dart:io' show File, Directory, FileMode;
import 'package:path_provider/path_provider.dart' as pp;

/// 日志级别枚举
enum LogLevel { verbose, debug, info, warning, error }

/// 统一日志服务 —— 输出到开发者控制台 + 可选文件日志
class Logger {
  static const String _tag = '[Cloudbranch]';
  static bool _fileLoggingEnabled = false;
  static String? _logDirPath;
  static final List<String> _pendingLogs = [];
  static bool _initialized = false;

  /// 启用文件日志
  static Future<void> enableFileLogging() async {
    _fileLoggingEnabled = true;
    await _initLogDir();
    // 写入排队中的日志
    for (final log in _pendingLogs) {
      await _writeToFile(log);
    }
    _pendingLogs.clear();
    _initialized = true;
    i('File logging enabled');
  }

  /// 禁用文件日志
  static void disableFileLogging() {
    _fileLoggingEnabled = false;
    d('File logging disabled');
  }

  /// 是否启用文件日志
  static bool get isFileLoggingEnabled => _fileLoggingEnabled;

  static Future<void> _initLogDir() async {
    try {
      // 统一使用 path_provider 获取文档目录，避免中文 Windows 下 Documents 文件夹名称问题
      final appDir = await pp.getApplicationDocumentsDirectory();
      _logDirPath = '${appDir.path}/Cloudbranch/log';
      final dir = Directory(_logDirPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      dev.log('$_tag Log directory initialized: $_logDirPath', name: 'cloudbranch');
    } catch (e) {
      // 初始化失败不阻塞应用
      dev.log('$_tag Failed to init log dir: $e', name: 'cloudbranch');
      _logDirPath = null;
    }
  }

  static Future<void> _writeToFile(String message) async {
    if (_logDirPath == null) return;
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final file = File('$_logDirPath\\cloudbranch_$dateStr.log');
      await file.writeAsString('$message\n', mode: FileMode.append);
    } catch (_) {
      // 文件写入失败不阻塞
    }
  }

  static void v(String message) => _log(LogLevel.verbose, message);
  static void d(String message) => _log(LogLevel.debug, message);
  static void i(String message) => _log(LogLevel.info, message);
  static void w(String message) => _log(LogLevel.warning, message);
  static void e(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);

  static void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final levelPrefix = _getLevelPrefix(level);
    final time = DateTime.now().toIso8601String();
    final logMessage = '$time $_tag $levelPrefix $message';

    switch (level) {
      case LogLevel.verbose:
      case LogLevel.debug:
        dev.log(logMessage, name: 'cloudbranch');
      case LogLevel.info:
        dev.log(logMessage, name: 'cloudbranch', level: 0);
      case LogLevel.warning:
        dev.log(logMessage, name: 'cloudbranch', level: 900);
      case LogLevel.error:
        dev.log(logMessage, name: 'cloudbranch', level: 1000, error: error, stackTrace: stackTrace);
    }

    // 文件日志
    if (_fileLoggingEnabled) {
      final fileMsg = '${_formatFileTime()} $levelPrefix $message';
      if (_initialized) {
        _writeToFile(fileMsg);
      } else {
        _pendingLogs.add(fileMsg);
      }
    }
  }

  static String _formatFileTime() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)} '
        '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.verbose: return '[VERBOSE]';
      case LogLevel.debug:   return '[DEBUG]';
      case LogLevel.info:    return '[INFO]';
      case LogLevel.warning: return '[WARNING]';
      case LogLevel.error:   return '[ERROR]';
    }
  }
}

/// 统一错误处理工具类
class ErrorHandler {
  /// 记录错误日志
  static void handleError(dynamic error, StackTrace stackTrace, {String? context}) {
    Logger.e(
      context != null ? '$context: ${error.toString()}' : error.toString(),
      error,
      stackTrace,
    );
  }

  /// 获取错误原文
  static String getErrorMessage(dynamic error) => error.toString();

  /// 将错误信息转化为对用户友好的中文提示
  static String getFriendlyErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network') || message.contains('socket') || message.contains('connection')) {
      return '网络连接失败，请检查网络设置';
    }
    if (message.contains('timeout')) {
      return '请求超时，请稍后重试';
    }
    if (message.contains('404')) {
      return '未找到相关数据';
    }
    if (message.contains('403') || message.contains('forbidden')) {
      return '访问被拒绝，请检查API密钥';
    }
    if (message.contains('500') || message.contains('server')) {
      return '服务器错误，请稍后重试';
    }
    return '操作失败，请稍后重试';
  }
}