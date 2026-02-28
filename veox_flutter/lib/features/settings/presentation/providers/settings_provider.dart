// lib/features/settings/presentation/providers/settings_provider.dart
//
// Riverpod state management for the Settings tab.
// Exposes: current key values, test results, and loading booleans.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/features/settings/domain/settings_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum TestStatus { idle, testing, success, failure }

class ProviderKeyState {
  const ProviderKeyState({
    this.maskedKey,
    this.testStatus = TestStatus.idle,
    this.testDetail,
  });

  /// Shows last 4 chars of stored key, or null if not set.
  final String? maskedKey;
  final TestStatus testStatus;
  final String? testDetail;

  ProviderKeyState copyWith({
    String? maskedKey,
    TestStatus? testStatus,
    String? testDetail,
    bool clearMaskedKey = false,
  }) =>
      ProviderKeyState(
        maskedKey: clearMaskedKey ? null : (maskedKey ?? this.maskedKey),
        testStatus: testStatus ?? this.testStatus,
        testDetail: testDetail ?? this.testDetail,
      );
}

class SettingsState {
  const SettingsState({
    this.keys = const {},
    this.isLoading = false,
  });

  final Map<ApiProvider, ProviderKeyState> keys;
  final bool isLoading;

  SettingsState copyWith({
    Map<ApiProvider, ProviderKeyState>? keys,
    bool? isLoading,
  }) =>
      SettingsState(
        keys: keys ?? this.keys,
        isLoading: isLoading ?? this.isLoading,
      );

  ProviderKeyState stateFor(ApiProvider p) =>
      keys[p] ?? const ProviderKeyState();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    loadAllKeys();
  }

  final _service = SettingsService.instance;

  /// Loads all stored keys and builds masked display strings.
  Future<void> loadAllKeys() async {
    state = state.copyWith(isLoading: true);
    try {
      final stored = await _service.getAllKeys();
      final keysState = <ApiProvider, ProviderKeyState>{};
      for (final provider in ApiProvider.values) {
        final raw = stored[provider];
        keysState[provider] = ProviderKeyState(
          maskedKey: raw != null ? _mask(raw) : null,
          testStatus: TestStatus.idle,
        );
      }
      state = state.copyWith(keys: keysState, isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to load keys', tag: 'Settings', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Saves [key] for [provider], then immediately tests it.
  Future<void> saveAndTestKey(ApiProvider provider, String key) async {
    _setProviderStatus(provider, TestStatus.testing);

    try {
      await _service.saveApiKey(provider, key);
      final result = await _service.testApiKey(provider, key);

      _setProviderStatus(
        provider,
        result.success ? TestStatus.success : TestStatus.failure,
        detail: result.detail,
        maskedKey: _mask(key),
      );
    } on ValidationFailure catch (e) {
      _setProviderStatus(provider, TestStatus.failure, detail: e.message);
    } catch (e) {
      _setProviderStatus(provider, TestStatus.failure, detail: e.toString());
    }
  }

  /// Deletes the stored key and resets the UI state.
  Future<void> deleteKey(ApiProvider provider) async {
    await _service.deleteApiKey(provider);
    final updated = Map<ApiProvider, ProviderKeyState>.from(state.keys);
    updated[provider] = const ProviderKeyState();
    state = state.copyWith(keys: updated);
  }

  void _setProviderStatus(
    ApiProvider provider,
    TestStatus status, {
    String? detail,
    String? maskedKey,
  }) {
    final updated = Map<ApiProvider, ProviderKeyState>.from(state.keys);
    updated[provider] = (updated[provider] ?? const ProviderKeyState())
        .copyWith(testStatus: status, testDetail: detail, maskedKey: maskedKey);
    state = state.copyWith(keys: updated);
  }

  String _mask(String key) {
    if (key.length <= 4) return '••••';
    return '•' * (key.length - 4) + key.substring(key.length - 4);
  }
}
