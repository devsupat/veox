import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import '../models/automation_state.dart';
import 'automation_bridge_service.dart';
import 'settings_service.dart';
import 'credential_service.dart';

/// Service responsible for orchestrating Veo automation workflows.
/// Follows SOLID principles by delegating low-level process management to [AutomationBridgeService].
final veoAutomationProvider =
    StateNotifierProvider<VeoAutomationService, AutomationState>((ref) {
      final bridge = ref.watch(automationBridgeProvider);
      final settings = ref.watch(settingsServiceProvider);
      final credentials = ref.watch(credentialServiceProvider);
      final isar = IsarService(); // Singleton
      return VeoAutomationService(bridge, settings, credentials, isar);
    });

class VeoAutomationService extends StateNotifier<AutomationState> {
  final AutomationBridgeService _bridge;
  final SettingsService _settings;
  final CredentialService _credentials;
  final IsarService _isar;

  VeoAutomationService(
    this._bridge,
    this._settings,
    this._credentials,
    this._isar,
  ) : super(const AutomationState()) {
    _initListeners();
  }

  Timer? _heartbeatTimer;

  void _initListeners() {
    _bridge.logs.listen((log) {
      final message = log['message'] ?? '';
      final level = log['level'] ?? 'info';

      switch (level) {
        case 'error':
          AppLogger.error(message, tag: "NodeEngine");
          break;
        case 'warn':
          AppLogger.warn(message, tag: "NodeEngine");
          break;
        default:
          AppLogger.info(message, tag: "NodeEngine");
      }

      // Reactive state updates based on engine feedback
      if (message.contains("Login sequence successful")) {
        state = state.copyWith(
          currentAction: "Authenticated. Navigating to Veos...",
        );
      }
    });

    // Monitor for unexpected process termination
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (state.isBrowserOpen && state.status != AutomationStatus.busy) {
        try {
          // Sending a no-op or screenshot check to ensure process is alive
          await _bridge.sendCommand('browser.screenshot', {});
        } catch (e) {
          AppLogger.warn(
            "Heartbeat failed: $e. Triggering recovery...",
            tag: "VeoAutomation",
          );
          _handleRecovery();
        }
      }
    });
  }

  Future<void> _handleRecovery() async {
    state = state.copyWith(isBrowserOpen: false, status: AutomationStatus.idle);
    await launchBrowser();
  }

  /// Launches the automation engine and browser.
  Future<void> launchBrowser() async {
    if (state.isBrowserOpen) {
      AppLogger.info("Browser already open", tag: "VeoAutomation");
      return;
    }

    try {
      state = state.copyWith(
        status: AutomationStatus.busy,
        currentAction: "Launching Browser...",
      );

      final profileName = await _settings.getProfileName();
      await _bridge.startEngine();

      await _bridge.sendCommand('browser.launch', {
        'profileId': profileName,
        'headless':
            false, // Visible for transparency during development/debugging
      });

      state = state.copyWith(
        status: AutomationStatus.connected,
        currentAction: "Browser Ready",
        isBrowserOpen: true,
      );
    } catch (e) {
      _handleError("Launch Failed", e);
    }
  }

  /// Orchestrates a full Veo action sequence: Launching -> Login -> Action.
  /// If [email] or [password] are null, it attempts to fetch them from secure storage
  /// based on the current profile in [SettingsService].
  Future<void> executeVeoAction({
    String? email,
    String? password,
    String? profileName,
    required String action,
    String? prompt,
  }) async {
    if (state.status == AutomationStatus.busy) {
      AppLogger.warn("Automation is currently busy", tag: "VeoAutomation");
      return;
    }

    try {
      state = state.copyWith(
        status: AutomationStatus.busy,
        currentAction: "Initializing Sequence...",
        lastError: null,
      );

      // 1. Resolve Credentials
      final targetProfile = profileName ?? await _settings.getProfileName();
      final profileModel = await _isar.getBrowserProfileByName(targetProfile);

      // Load the linked google account if it exists
      if (profileModel != null && !profileModel.googleAccount.isLoaded) {
        await profileModel.googleAccount.load();
      }

      final effectiveEmail = email ?? profileModel?.googleAccount.value?.email;
      final effectivePassword =
          password ?? await _credentials.getPassword(targetProfile);

      if (effectiveEmail == null || effectivePassword == null) {
        throw AuthFailure(
          "Missing credentials for profile: $targetProfile. Please configure in settings.",
        );
      }

      // 2. Ensure Environment
      if (!state.isBrowserOpen) {
        await launchBrowser();
      }

      // 3. Authentication Flow
      state = state.copyWith(currentAction: "Ensuring Authentication...");
      await _bridge.sendCommand('veo.login', {
        'email': effectiveEmail,
        'password': effectivePassword,
      });

      // 4. Workflow Execution
      if (action == 'generate') {
        if (prompt == null) {
          throw ArgumentError("Prompt is required for 'generate' action.");
        }

        state = state.copyWith(currentAction: "Sending Generation Prompt...");
        final result = await _bridge.sendCommand('veo.generate', {
          'prompt': prompt,
        });

        AppLogger.info(
          "Prompt accepted by engine: ${result['result']}",
          tag: "VeoAutomation",
        );

        state = state.copyWith(
          status: AutomationStatus.connected,
          currentAction: "Task Submitted Successfully",
        );
      } else if (action == 'auth_guided') {
        state = state.copyWith(
          currentAction: "Waiting for User Authentication...",
        );
        await _bridge.sendCommand('veo.auth_guided', {});

        state = state.copyWith(
          status: AutomationStatus.connected,
          currentAction: "Authentication Verified",
        );
      } else {
        throw UnimplementedError("Action '$action' is not supported yet.");
      }
    } catch (e) {
      _handleError("Automation Sequence Failed", e);
      rethrow;
    }
  }

  /// Gracefully shuts down the browser and engine.
  Future<void> closeBrowser() async {
    try {
      await _bridge.sendCommand('browser.close');
      await _bridge.stopEngine();
      state = state.copyWith(
        status: AutomationStatus.idle,
        isBrowserOpen: false,
        currentAction: "Session Terminated",
      );
    } catch (e) {
      AppLogger.error("Failed to close browser: $e", tag: "VeoAutomation");
    }
  }

  void _handleError(String context, dynamic error) {
    AppLogger.error("$context: $error", tag: "VeoAutomation");

    // Classify error
    final isRetryable = _isErrorRetryable(error);

    state = state.copyWith(
      status: AutomationStatus.error,
      lastError: error.toString(),
      currentAction: isRetryable ? "$context (Retryable)" : context,
    );

    if (!isRetryable) {
      // Potentially close browser on fatal errors to reset state
      // closeBrowser();
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  bool _isErrorRetryable(dynamic error) {
    if (error is AuthFailure) return false;
    final message = error.toString().toLowerCase();
    if (message.contains("timeout")) return true;
    if (message.contains("network")) return true;
    if (message.contains("navigation failed")) return true;
    return false;
  }
}
