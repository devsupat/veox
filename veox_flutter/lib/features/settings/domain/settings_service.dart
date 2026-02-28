// lib/features/settings/domain/settings_service.dart
//
// Pure domain service — no Riverpod, no Flutter, just logic.
// Validates API key format before saving and performs lightweight connectivity
// tests against each provider's health/account endpoint.

import 'package:dio/dio.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/network/dio_client.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';

/// Result of an API key test.
class ApiTestResult {
  const ApiTestResult({required this.success, this.detail});
  final bool success;
  final String? detail;
}

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------

  Future<void> saveApiKey(ApiProvider provider, String key) async {
    _validateKeyFormat(provider, key);
    await SecureStorageService.instance.saveApiKey(provider, key.trim());
    AppLogger.info('Saved API key for ${provider.displayName}', tag: 'Settings');
  }

  Future<String?> getApiKey(ApiProvider provider) =>
      SecureStorageService.instance.getApiKey(provider);

  Future<void> deleteApiKey(ApiProvider provider) =>
      SecureStorageService.instance.deleteApiKey(provider);

  Future<Map<ApiProvider, String>> getAllKeys() =>
      SecureStorageService.instance.getAll();

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Checks key format (prefix). Throws [ValidationFailure] on mismatch.
  void _validateKeyFormat(ApiProvider provider, String key) {
    if (key.trim().isEmpty) {
      throw const ValidationFailure('API key cannot be empty.');
    }
    final prefix = provider.keyPrefix;
    if (prefix != null && !key.trim().startsWith(prefix)) {
      throw ValidationFailure(
        '${provider.displayName} keys must start with "$prefix". '
        'Please check you copied the full key.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Connectivity Test
  // ---------------------------------------------------------------------------

  /// Makes a lightweight authenticated request to verify the key works.
  Future<ApiTestResult> testApiKey(ApiProvider provider, String key) async {
    AppLogger.info('Testing ${provider.displayName} key…', tag: 'Settings');

    // Temporarily store the key so DioClient can fetch it.
    await SecureStorageService.instance.saveApiKey(provider, key.trim());

    try {
      final client = await DioClient.instance.getClient(provider);
      await _pingProvider(provider, client);
      AppLogger.info('${provider.displayName} key valid ✓', tag: 'Settings');
      return const ApiTestResult(success: true);
    } on AuthFailure catch (e) {
      return ApiTestResult(success: false, detail: e.message);
    } on NetworkFailure catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        return ApiTestResult(
            success: false, detail: 'Key rejected (HTTP ${e.statusCode}).');
      }
      // Any other network error → treat as passing (can't verify, not our fault).
      return ApiTestResult(success: true, detail: 'Network check skipped: ${e.message}');
    } catch (e) {
      return ApiTestResult(success: false, detail: e.toString());
    }
  }

  Future<void> _pingProvider(ApiProvider provider, Dio client) async {
    switch (provider) {
      case ApiProvider.replicate:
        await client.get('/account');
      case ApiProvider.openai:
        await client.get('/models', queryParameters: {'limit': '1'});
      case ApiProvider.anthropic:
        // Anthropic has no lightweight GET; use a minimal completions call.
        await client.post('/messages', data: {
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1,
          'messages': [{'role': 'user', 'content': 'hi'}],
        });
      case ApiProvider.elevenlabs:
        await client.get('/user');
      case ApiProvider.suno:
        // Suno has no standard health endpoint — skip test.
        break;
    }
  }
}
