import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../utils/logger.dart';

/// HTTP通用响应模型
class HttpResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? statusCode;

  HttpResponse.success(this.data)
      : success = true,
        errorMessage = null,
        statusCode = null;

  HttpResponse.error(this.errorMessage, [this.statusCode])
      : success = false,
        data = null;
}

/// HTTP服务 —— 封装GET请求，支持重试和超时
class HttpService {
  final http.Client _client;

  HttpService({http.Client? client}) : _client = client ?? http.Client();

  Future<HttpResponse<Map<String, dynamic>>> getJson(
    String url, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    int maxRetries = Environment.maxRetryCount,
    Duration timeout = Environment.requestTimeout,
  }) async {
    Uri uri = Uri.parse(url);
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    Logger.d('HTTP GET: $uri');

    int attempts = 0;
    Exception? lastException;

    while (attempts <= maxRetries) {
      try {
        final response = await _client.get(uri, headers: headers).timeout(timeout);
        Logger.d('HTTP Response: ${response.statusCode}');

        if (response.statusCode == 200) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.body);
            return HttpResponse.success(data);
          } catch (e) {
            Logger.e('JSON parsing failed: $e');
            return HttpResponse.error('JSON解析失败');
          }
        } else if (response.statusCode >= 500 && attempts < maxRetries) {
          attempts++;
          Logger.w('Server error, retrying... ($attempts/$maxRetries)');
          await Future.delayed(Environment.retryDelay * attempts);
          continue;
        } else {
          return HttpResponse.error(_getStatusMessage(response.statusCode), response.statusCode);
        }
      } catch (e) {
        attempts++;
        lastException = Exception(e);
        Logger.w('Request failed, retrying... ($attempts/$maxRetries): $e');
        if (attempts <= maxRetries) {
          await Future.delayed(Environment.retryDelay * attempts);
          continue;
        }
      }
    }

    return HttpResponse.error(
      lastException != null
          ? ErrorHandler.getFriendlyErrorMessage(lastException)
          : '请求失败',
    );
  }

  String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400: return '请求参数错误';
      case 401: return '未授权访问';
      case 403: return '访问被拒绝';
      case 404: return '未找到资源';
      case 429: return '请求过于频繁，请稍后重试';
      case 500: return '服务器内部错误';
      case 502: return '网关错误';
      case 503: return '服务不可用';
      default:  return 'HTTP错误: $statusCode';
    }
  }

  void dispose() {
    _client.close();
  }
}