// lib/core/ipc/node_service.dart
//
// Manages the lifecycle of the Node.js sidecar process (engine/main.js).
//
// Communication protocol: newline-delimited JSON over stdin/stdout.
//   Flutter → Node: { id, command, params }
//   Node → Flutter: { id, type: 'result'|'event'|'log'|'system', status, data, error }
//
// Key design: every `sendCommand()` call returns a `Future` that resolves
// when the matching response (same `id`) arrives on stdout. This is done via
// a `Map<String, Completer>` dictionary. Commands time out after [commandTimeout].

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/utils/logger.dart';

typedef JsonMap = Map<String, dynamic>;

/// Single source of truth for the target automation URL used by all
/// browser-launch, connect, and diagnostic helpers in this service.
const kFlowUrl = 'https://labs.google/fx/tools/flow';

/// Events emitted while Node is running — useful for a live log panel.
class NodeLogEvent {
  const NodeLogEvent({required this.level, required this.message});
  final String level;
  final String message;
}

/// [NodeService] is a singleton that orchestrates the Node.js child process.
///
/// Lifecycle:
///   1. `startEngine()` — spawns the process, sets up listeners.
///   2. `sendCommand()` — sends JSON, awaits correlated response.
///   3. `stopEngine()` — kills the process cleanly.
///
/// The service auto-restarts if the process dies unexpectedly.
class NodeService {
  NodeService._();
  static final NodeService instance = NodeService._();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  Process? _process;
  bool _running = false;

  /// How long to wait for any single command response.
  static const commandTimeout = Duration(
    minutes: 60,
  ); // Increased for long jobs

  /// Pending commands awaiting their matching response from Node.
  final Map<String, Completer<JsonMap>> _pending = {};

  /// Broadcast stream of log/system events for the UI.
  final StreamController<NodeLogEvent> _logController =
      StreamController.broadcast();
  Stream<NodeLogEvent> get logStream => _logController.stream;

  /// Broadcast stream of application events (e.g., progress, needs_login).
  final StreamController<JsonMap> _eventController =
      StreamController.broadcast();
  Stream<JsonMap> get eventStream => _eventController.stream;

  bool get isRunning => _running;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Starts the Node.js engine. Safe to call multiple times (idempotent).
  Future<void> startEngine() async {
    if (_running) return;

    final enginePath = _resolveEnginePath();
    final engineDir =
        _resolveEngineDir(); // cwd for node so node_modules are found
    AppLogger.info(
      'Starting Node engine: node $enginePath (cwd: $engineDir)',
      tag: 'Node',
    );

    // Build environment for the subprocess.
    final env = Map<String, String>.from(Platform.environment);
    // PLAYWRIGHT_BROWSERS_PATH=0 → use the browsers bundled with playwright package
    // rather than a global cache (important for packaged builds).
    env['PLAYWRIGHT_BROWSERS_PATH'] = env['PLAYWRIGHT_BROWSERS_PATH'] ?? '0';
    if (kDebugMode) env['VEOX_DEBUG'] = '1';
    // Allow the headed browser to show on this display (important on macOS/Linux)
    if (Platform.environment.containsKey('DISPLAY')) {
      env['DISPLAY'] = Platform.environment['DISPLAY']!;
    }

    try {
      _process = await Process.start(
        'node',
        [enginePath],
        workingDirectory: engineDir,
        environment: env,
        // runInShell avoids PATH lookup issues on Windows
        runInShell: Platform.isWindows,
      );

      _running = true;

      // Listen to stdout — JSON lines, correlated by `id`.
      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleLine,
            onDone: _handleProcessExit,
            onError: (Object e) =>
                AppLogger.error('Node stdout error: $e', tag: 'Node'),
          );

      // Stderr: also parsed + routed. Node errors and crash traces come here.
      // We try to JSON-decode them first (structured); raw text falls back.
      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((data) {
            if (data.trim().isEmpty) return;
            // Try structured parse first
            try {
              _handleLine(data);
            } catch (_) {
              AppLogger.warn('Node stderr: $data', tag: 'Node');
              _logController.add(
                NodeLogEvent(level: 'error', message: '[stderr] $data'),
              );
            }
          });

      AppLogger.info('Node engine started (PID ${_process!.pid})', tag: 'Node');
    } catch (e, st) {
      _running = false;
      AppLogger.error(
        'Failed to start Node engine',
        tag: 'Node',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Sends a command to Node and returns the response payload.
  ///
  /// Throws [ProcessFailure] if Node replies with `status: 'error'`.
  /// Throws [TimeoutException] if no response within [commandTimeout].
  Future<JsonMap> sendCommand(
    String commandId,
    String command,
    JsonMap params,
  ) async {
    if (!_running) {
      AppLogger.warn('Node not running. Restarting...', tag: 'Node');
      await startEngine();
    }

    final completer = Completer<JsonMap>();
    _pending[commandId] = completer;

    final payload = jsonEncode({
      'id': commandId,
      'command': command,
      'params': params,
    });
    _process!.stdin.writeln(payload);

    AppLogger.debug('→ Node [$commandId] $command', tag: 'Node');

    return completer.future.timeout(
      commandTimeout,
      onTimeout: () {
        _pending.remove(commandId);
        throw ProcessFailure(
          'Command "$command" timed out after ${commandTimeout.inMinutes}m.',
          exitCode: -1,
        );
      },
    );
  }

  /// Stops the Node engine gracefully, clearing all pending commands.
  Future<void> stopEngine() async {
    _running = false;

    // Fail all pending commands.
    for (final entry in _pending.values) {
      if (!entry.isCompleted) {
        entry.completeError(const ProcessFailure('Node engine stopped.'));
      }
    }
    _pending.clear();

    await _process?.stdin.close();
    _process?.kill();
    _process = null;

    AppLogger.info('Node engine stopped.', tag: 'Node');
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;

    JsonMap json;
    try {
      json = jsonDecode(line) as JsonMap;
    } catch (e) {
      AppLogger.warn('Node non-JSON: $line', tag: 'Node');
      return;
    }

    final type = json['type'] as String?;
    final id = json['id'] as String?;

    switch (type) {
      case 'result':
        if (id != null && _pending.containsKey(id)) {
          final completer = _pending.remove(id)!;
          if (json['status'] == 'error') {
            final isRetryable = json['retryable'] as bool? ?? true;
            final category = json['errorCategory'] as String?;
            completer.completeError(
              ProcessFailure(
                'Node error: ${json['error']}',
                retryable: isRetryable,
                errorCategory: category,
              ),
            );
          } else {
            completer.complete(json['data'] as JsonMap? ?? {});
          }
        }
        break;
      case 'event':
        _eventController.add(json);
        break;
      case 'log':
        final msg =
            json['msg']?.toString() ?? json['message']?.toString() ?? '';
        final lvl = json['level']?.toString() ?? 'debug';
        AppLogger.debug('Node [$lvl]: $msg', tag: 'Node');
        _logController.add(NodeLogEvent(level: lvl, message: msg));
        break;
      case 'system':
        AppLogger.info('Node system: ${json['msg']}', tag: 'Node');
        _logController.add(
          NodeLogEvent(level: 'info', message: json['msg']?.toString() ?? ''),
        );
        break;
      default:
        AppLogger.debug('Node unknown type: $line', tag: 'Node');
    }
  }

  void _handleProcessExit() async {
    if (!_running) return; // intentional stop
    AppLogger.warn(
      'Node engine exited unexpectedly. Restarting...',
      tag: 'Node',
    );
    _running = false;
    await Future<void>.delayed(const Duration(seconds: 2));
    startEngine();
  }

  String _resolveEnginePath() {
    if (kDebugMode) {
      // In debug, the engine is at {project root}/engine/main.js.
      // Directory.current is usually the veox_flutter/ folder when running via `flutter run`.
      return 'engine/main.js';
    }
    // In release builds, engine is bundled next to the executable.
    final exeDir = File(Platform.resolvedExecutable).parent;
    return '${exeDir.path}/engine/main.js';
  }

  /// Working directory for the node process — must be the engine's parent
  /// folder so that `require()` resolves node_modules correctly.
  String _resolveEngineDir() {
    if (kDebugMode) {
      // veox_flutter/ is the working dir when running with `flutter run`
      return Directory.current.path;
    }
    // Release: engine lives beside the app executable
    return File(Platform.resolvedExecutable).parent.path;
  }

  // ---------------------------------------------------------------------------
  // Diagnostics + Test helpers
  // ---------------------------------------------------------------------------

  /// Runs engine.doctor and returns the full diagnostic map.
  Future<JsonMap> sendDoctor() async {
    const id = 'doctor-1';
    return sendCommand(id, 'engine.doctor', {});
  }

  /// Enqueues a browser visibility test: opens [url] in headed mode for [durationSeconds].
  Future<JsonMap> enqueueOpenBrowserTest({
    String url = kFlowUrl,
    int durationSeconds = 30,
  }) async {
    final id = 'browser-test-${DateTime.now().millisecondsSinceEpoch}';
    return sendCommand(id, 'job_start', {
      'type': 'open_browser_test',
      'taskId': id,
      'url': url,
      'durationSeconds': durationSeconds,
    });
  }
}
