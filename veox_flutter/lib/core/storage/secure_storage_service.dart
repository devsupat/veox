// lib/core/storage/secure_storage_service.dart
//
// Stores API keys in the OS keychain (macOS Keychain / Windows Credential Store)
// via flutter_secure_storage. Keys are namespaced to avoid collisions.
//
// Usage:
//   final svc = SecureStorageService.instance;
//   await svc.saveApiKey(ApiProvider.replicate, 'r8_...');
//   final key = await svc.getApiKey(ApiProvider.replicate);

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Supported third-party API providers.
enum ApiProvider {
  replicate,
  openai,
  anthropic,
  elevenlabs,
  suno;

  String get displayName => switch (this) {
        ApiProvider.replicate => 'Replicate',
        ApiProvider.openai => 'OpenAI',
        ApiProvider.anthropic => 'Anthropic',
        ApiProvider.elevenlabs => 'ElevenLabs',
        ApiProvider.suno => 'Suno',
      };

  String get _storageKey => 'veox_api_key_${name}';

  /// Expected key prefix for format validation.
  String? get keyPrefix => switch (this) {
        ApiProvider.replicate => 'r8_',
        ApiProvider.openai => 'sk-',
        ApiProvider.anthropic => 'sk-ant-',
        _ => null, // No enforced prefix
      };
}

/// [SecureStorageService] is a singleton that wraps [FlutterSecureStorage].
///
/// Design: Singleton via factory constructor — ensures a single storage
/// instance across the app, mirroring the Keychain connection lifecycle.
class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(
      // Accessible only when the device is unlocked. Best security posture.
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Persists [key] for the given [provider] into the OS keychain.
  Future<void> saveApiKey(ApiProvider provider, String key) async {
    await _storage.write(key: provider._storageKey, value: key.trim());
  }

  /// Returns the stored API key, or `null` if not set.
  Future<String?> getApiKey(ApiProvider provider) async {
    return _storage.read(key: provider._storageKey);
  }

  /// Removes the stored key for [provider].
  Future<void> deleteApiKey(ApiProvider provider) async {
    await _storage.delete(key: provider._storageKey);
  }

  /// Returns a map of provider → key for all providers that have a stored key.
  Future<Map<ApiProvider, String>> getAll() async {
    final result = <ApiProvider, String>{};
    for (final provider in ApiProvider.values) {
      final key = await _storage.read(key: provider._storageKey);
      if (key != null && key.isNotEmpty) {
        result[provider] = key;
      }
    }
    return result;
  }

  /// Returns `true` if an API key is stored for [provider].
  Future<bool> hasKey(ApiProvider provider) async {
    final k = await getApiKey(provider);
    return k != null && k.isNotEmpty;
  }
}
