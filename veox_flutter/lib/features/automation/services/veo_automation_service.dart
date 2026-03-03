import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/features/queue/domain/queue_service.dart';
import '../models/automation_state.dart';
import 'automation_bridge_service.dart';
import 'settings_service.dart';
import 'credential_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service responsible for orchestrating Veo automation workflows.
/// Follows SOLID principles by delegating low-level process management to [AutomationBridgeService].
final veoAutomationProvider =
    StateNotifierProvider<VeoAutomationService, AutomationState>((ref) {
      final bridge = ref.watch(automationBridgeProvider);
      final settings = ref.watch(settingsServiceProvider);
      final credentials = ref.watch(credentialServiceProvider);
      final isar = IsarService(); // Singleton
      final queue = QueueService.instance;
      return VeoAutomationService(bridge, settings, credentials, isar, queue);
    });

class VeoAutomationService extends StateNotifier<AutomationState> {
  /// Canonical target URL for browser automation.
  /// All launch / resume / recovery paths use this constant.
  static const _kFlowUrl = 'https://labs.google/fx/tools/flow';

  final AutomationBridgeService _bridge;
  // ignore: unused_field
  final SettingsService _settings;
  // ignore: unused_field
  final CredentialService _credentials;
  // ignore: unused_field
  final IsarService _isar;
  final QueueService _queue;

  VeoAutomationService(
    this._bridge,
    this._settings,
    this._credentials,
    this._isar,
    this._queue,
  ) : super(const AutomationState()) {
    _initListeners();
  }

  Timer? _heartbeatTimer;
  String? _activeTaskId;

  void _initListeners() {
    // Monitor queue progress to update automation state
    _queue.progress.listen(_handleQueueProgress);

    // Monitor for unexpected process termination
    _startHeartbeat();
  }

  void _handleQueueProgress(QueueProgressEvent event) {
    if (_activeTaskId != null && event.taskId != _activeTaskId) return;

    switch (event.status) {
      case 'running':
        state = state.copyWith(
          status: AutomationStatus.busy,
          currentAction: event.stage != null
              ? "Status: ${event.stage}"
              : "Processing...",
        );
        break;
      case 'paused_needs_login':
        state = state.copyWith(
          status: AutomationStatus.pausedNeedsLogin,
          currentAction: "Waiting for login...",
        );
        break;
      case 'completed':
        state = state.copyWith(
          status: AutomationStatus.connected,
          currentAction: "Task Completed",
          isBrowserOpen: true,
        );
        break;
      case 'failed':
        state = state.copyWith(
          status: AutomationStatus.error,
          lastError: event.error,
          currentAction: "Failed",
        );
        break;
      case 'canceled':
        state = state.copyWith(
          status: AutomationStatus.idle,
          currentAction: "Canceled",
        );
        break;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (state.isBrowserOpen && state.status != AutomationStatus.busy) {
        try {
          // Sending a no-op to ensure process is alive
          await _bridge.sendCommand('ping');
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

  /// Launches the automation engine and browser via the Queue.
  /// Enqueues a browser_screenshot task which effectively verifies connectivity.
  Future<void> launchBrowser() async {
    try {
      final profileName = await _settings.getProfileName();
      final docsDir = await getApplicationDocumentsDirectory();

      final taskId = const Uuid().v4();
      final expectedPath = p.join(
        docsDir.path,
        'VEOX',
        'screenshots',
        '$taskId.png',
      );
      _activeTaskId = taskId;

      await _queue.enqueue(
        type: 'browser_screenshot',
        payload: {
          'url': _kFlowUrl,
          'profileId': profileName,
          'outputPath': expectedPath,
        },
        expectedOutputPath: expectedPath,
      );

      state = state.copyWith(
        status: AutomationStatus.connecting,
        currentAction: "Queuing Screenshot Task...",
      );
    } catch (e) {
      _handleError("Queueing Failed", e);
    }
  }

  Future<void> resume() async {
    if (_activeTaskId != null) {
      await _queue.resumeTask(_activeTaskId!);
    }
  }

  Future<void> cancel() async {
    if (_activeTaskId != null) {
      await _queue.cancelTask(_activeTaskId!);
    }
  }

  /// Routes automation actions to the Queue.
  Future<void> executeVeoAction({
    String? email,
    String? password,
    String? profileName,
    required String action,
    String? prompt,
  }) async {
    AppLogger.info(
      "executeVeoAction ($action) requested. Routing via Queue...",
      tag: "VeoAutomation",
    );

    if (action == 'generate' && prompt != null) {
      final taskId = const Uuid().v4();
      final docsDir = await getApplicationDocumentsDirectory();
      final expectedPath = p.join(
        docsDir.path,
        'VEOX',
        'videos',
        '$taskId.mp4',
      );

      _activeTaskId = taskId;

      await _queue.enqueue(
        type: 'browser_generate_video',
        payload: {
          'prompt': prompt,
          'profileId': profileName ?? 'default',
          'outputPath': expectedPath,
        },
        expectedOutputPath: expectedPath,
      );
    }
  }

  /// Gracefully shuts down the browser and engine.
  Future<void> closeBrowser() async {
    try {
      await _bridge.sendCommand('close_browser');
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
    state = state.copyWith(
      status: AutomationStatus.error,
      lastError: error.toString(),
      currentAction: context,
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
