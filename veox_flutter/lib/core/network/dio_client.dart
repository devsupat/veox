// lib/core/network/dio_client.dart
//
// The single source-of-truth HTTP client for all external API calls.
//
// Architecture decision: Rather than creating one Dio per provider, we return
// a *configured clone* from `getClient()`. This lets us have:
//   - Shared connection pool at the root
//   - Per-provider base URL and auth headers without rebuilding interceptors
//   - Centralised retry + logging with zero duplication

import 'package:dio/dio.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/core/errors/failures.dart';

/// Base URLs for each supported provider.
const _baseUrls = {
  ApiProvider.replicate: 'https://api.replicate.com/v1',
  ApiProvider.openai: 'https://api.openai.com/v1',
  ApiProvider.anthropic: 'https://api.anthropic.com/v1',
  ApiProvider.elevenlabs: 'https://api.elevenlabs.io/v1',
  ApiProvider.suno: 'https://api.sunoai.io/v1',
};

/// Additional fixed headers required by some providers.
const _extraHeaders = {
  ApiProvider.anthropic: {
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
  },
};

/// [DioClient] is a singleton factory that produces provider-specific Dio
/// instances sharing the same connection pool and interceptors.
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  /// Root Dio — only used for non-provider calls (e.g., health checks).
  late final Dio _root;

  bool _initialised = false;

  /// Must be called once in `main()` before any network request.
  void init() {
    if (_initialised) return;
    _root = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 120), // AI APIs are slow
        sendTimeout: const Duration(seconds: 60),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    _root.interceptors.add(_LoggingInterceptor());
    _initialised = true;
  }

  /// Returns a Dio instance pre-configured for [provider].
  ///
  /// Fetches the API key from the keychain at call-time (not cached) so
  /// a key change in Settings takes effect on the next request without restart.
  Future<Dio> getClient(ApiProvider provider) async {
    final key = await SecureStorageService.instance.getApiKey(provider);
    if (key == null || key.isEmpty) {
      throw AuthFailure(
        'No API key found for ${provider.displayName}. '
        'Please add it in Settings.',
      );
    }

    final baseUrl = _baseUrls[provider]!;
    final headers = <String, dynamic>{
      'Authorization': 'Bearer $key',
      ...?_extraHeaders[provider],
    };

    // Create a new Dio with provider-specific base URL and auth headers,
    // sharing the same connection pool settings as root.
    final client = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: headers,
        connectTimeout: _root.options.connectTimeout,
        receiveTimeout: _root.options.receiveTimeout,
        sendTimeout: _root.options.sendTimeout,
      ),
    );

    client.interceptors.addAll([_RetryInterceptor(maxAttempts: 3)]);

    return client;
  }

  /// Returns a plain Dio with no auth (for public endpoints).
  Dio get plain => _root;
}

// ---------------------------------------------------------------------------
// Interceptors
// ---------------------------------------------------------------------------

/// Logs every request and response at debug level.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('→ ${options.method} ${options.uri}', tag: 'HTTP');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      tag: 'HTTP',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri} '
      '— ${err.message}',
      tag: 'HTTP',
      error: err,
    );
    handler.next(err);
  }
}

/// Retries failed requests with exponential backoff.
/// Retry conditions: connection timeout, network error (not 4xx client errors).
class _RetryInterceptor extends Interceptor {
  final int maxAttempts;
  _RetryInterceptor({this.maxAttempts = 3});

  static const _backoffSeconds = [
    1,
    5,
    30,
  ]; // per attempt (0-indexed after 1st)

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = err.requestOptions.extra['_retryCount'] as int? ?? 0;

    final isRetryable =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isRetryable && attempt < maxAttempts - 1) {
      final delay =
          _backoffSeconds[attempt.clamp(0, _backoffSeconds.length - 1)];
      AppLogger.warn(
        'Retry ${attempt + 1}/$maxAttempts after ${delay}s '
        '— ${err.requestOptions.uri}',
        tag: 'HTTP',
      );

      await Future<void>.delayed(Duration(seconds: delay));

      final options = err.requestOptions..extra['_retryCount'] = attempt + 1;

      try {
        final response = await DioClient.instance.plain.fetch(options);
        handler.resolve(response);
      } on DioException catch (e) {
        handler.next(e);
      }
      return;
    }

    // Map Dio errors to typed Failures for cleaner caller code.
    final failure = _mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: failure,
        message: failure.message,
        type: err.type,
      ),
    );
  }

  NetworkFailure _mapDioError(DioException err) {
    return switch (err.type) {
      DioExceptionType.badResponse => NetworkFailure(
        'Server returned ${err.response?.statusCode}: '
        '${err.response?.data}',
        statusCode: err.response?.statusCode,
      ),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => const NetworkFailure(
        'Request timed out. The AI API may be overloaded.',
      ),
      DioExceptionType.connectionError => const NetworkFailure(
        'No internet connection.',
      ),
      _ => NetworkFailure(err.message ?? 'Unknown network error'),
    };
  }
}
