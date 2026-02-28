// lib/features/queue/domain/queue_service.dart
//
// Production persistent queue engine: priority-ordered, concurrent, resilient.
//
// Architecture notes:
//   • Tasks stored in Isar — survives app restarts.
//   • Concurrent workers: configurable (default 3).
//   • Circuit breaker trips after N consecutive failures.
//   • Tasks dispatch to NodeService (browser) or local handlers (image/FFmpeg).

import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/core/ipc/node_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

class QueueProgressEvent {
  const QueueProgressEvent({
    required this.taskId,
    required this.status,
    this.outputPath,
    this.error,
  });
  final String taskId;
  final String status;
  final String? outputPath;
  final String? error;
}

// ---------------------------------------------------------------------------
// Service (singleton)
// ---------------------------------------------------------------------------

class QueueService {
  QueueService._();
  static final QueueService instance = QueueService._();

  static const int _defaultConcurrency = 3;
  static const int circuitBreakerLimit = 5;

  bool _running = false;
  int _concurrency = _defaultConcurrency;
  int _activeWorkers = 0;
  int _consecutiveFailures = 0;
  bool _circuitOpen = false;

  final _progressController = StreamController<QueueProgressEvent>.broadcast();
  Stream<QueueProgressEvent> get progress => _progressController.stream;

  bool get isRunning => _running;
  bool get isCircuitOpen => _circuitOpen;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> start({int concurrency = _defaultConcurrency}) async {
    if (_running) return;
    if (_circuitOpen) {
      AppLogger.warn(
          'Circuit breaker OPEN. Call resetCircuit() first.', tag: 'Queue');
      return;
    }
    _running = true;
    _concurrency = concurrency;
    AppLogger.info('Queue started (concurrency=$concurrency)', tag: 'Queue');
    _tick();
  }

  void pause() {
    _running = false;
    AppLogger.info('Queue paused.', tag: 'Queue');
  }

  void stop() {
    _running = false;
    AppLogger.info('Queue stopped.', tag: 'Queue');
  }

  void resetCircuit() {
    _circuitOpen = false;
    _consecutiveFailures = 0;
    AppLogger.info('Circuit breaker reset.', tag: 'Queue');
  }

  // ── Enqueue ───────────────────────────────────────────────────────────────

  Future<TaskModel> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    int priority = 5,
  }) async {
    final isar = await IsarService().db;
    final task = TaskModel()
      ..taskId = const Uuid().v4()
      ..type = type
      ..status = 'pending'
      ..payloadJson = jsonEncode(payload)
      ..priority = priority
      ..createdAt = DateTime.now()
      ..retryCount = 0;

    await isar.writeTxn(() async => isar.taskModels.put(task));
    AppLogger.info('Enqueued ${task.taskId} ($type p=$priority)', tag: 'Queue');

    if (_running && _activeWorkers < _concurrency) _tick();
    return task;
  }

  // ── Retry ─────────────────────────────────────────────────────────────────

  Future<void> retryFailed() async {
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      final failed = await isar.taskModels
          .filter()
          .statusEqualTo('failed')
          .findAll();
      for (final t in failed) {
        t.status = 'retrying';
        t.retryCount = t.retryCount + 1;
      }
      await isar.taskModels.putAll(failed);
      AppLogger.info('Reset ${failed.length} failed tasks.', tag: 'Queue');
    });
    if (_running) _tick();
  }

  // ── Tick loop ─────────────────────────────────────────────────────────────

  Future<void> _tick() async {
    if (!_running || _circuitOpen || _activeWorkers >= _concurrency) return;

    final isar = await IsarService().db;
    final task = await isar.taskModels
        .filter()
        .group((q) => q.statusEqualTo('pending').or().statusEqualTo('retrying'))
        .sortByPriorityDesc()
        .findFirst();

    if (task == null) {
      if (_activeWorkers == 0) {
        AppLogger.info('Queue drained.', tag: 'Queue');
      }
      return;
    }

    // Atomic claim: mark 'running' before spawning worker.
    await isar.writeTxn(() async {
      task.status = 'running';
      task.startedAt = DateTime.now();
      await isar.taskModels.put(task);
    });

    _activeWorkers++;
    _processTask(task).whenComplete(() {
      _activeWorkers--;
      if (_running) _tick();
    });

    // Saturate concurrency slots eagerly.
    if (_activeWorkers < _concurrency) unawaited(_tick());
  }

  // ── Dispatch ──────────────────────────────────────────────────────────────

  Future<void> _processTask(TaskModel task) async {
    AppLogger.info('Processing ${task.taskId} (${task.type})', tag: 'Queue');
    try {
      final payload = jsonDecode(task.payloadJson) as Map<String, dynamic>;
      String? outputPath;

      switch (task.type) {
        case 'video_gen':
          outputPath = await _videoGen(task.taskId, payload);
        case 'browser_action':
          outputPath = await _browserAction(task.taskId, payload);
        default:
          throw UnsupportedError('Unknown task type: ${task.type}');
      }

      await _complete(task, outputPath: outputPath);
      _consecutiveFailures = 0;
      _progressController.add(QueueProgressEvent(
        taskId: task.taskId,
        status: 'completed',
        outputPath: outputPath,
      ));
    } catch (e, st) {
      AppLogger.error('Task ${task.taskId} failed',
          tag: 'Queue', error: e, stackTrace: st);
      await _fail(task, e.toString());
      _consecutiveFailures++;
      if (_consecutiveFailures >= circuitBreakerLimit) _tripCircuit();
      _progressController.add(QueueProgressEvent(
        taskId: task.taskId,
        status: 'failed',
        error: e.toString(),
      ));
    }
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<String?> _videoGen(
      String taskId, Map<String, dynamic> payload) async {
    final result = await NodeService.instance
        .sendCommand(taskId, 'generate_video', payload);
    return result['outputPath'] as String?;
  }

  Future<String?> _browserAction(
      String taskId, Map<String, dynamic> payload) async {
    final command = payload['command'] as String;
    final params = Map<String, dynamic>.from(payload)..remove('command');
    final result =
        await NodeService.instance.sendCommand(taskId, command, params);
    return result['outputPath'] as String?;
  }

  // ── DB helpers ────────────────────────────────────────────────────────────

  Future<void> _complete(TaskModel task, {String? outputPath}) async {
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      task
        ..status = 'completed'
        ..completedAt = DateTime.now()
        ..outputPath = outputPath;
      await isar.taskModels.put(task);
    });
  }

  Future<void> _fail(TaskModel task, String error) async {
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      task
        ..status = 'failed'
        ..completedAt = DateTime.now()
        ..errorLog = error;
      await isar.taskModels.put(task);
    });
  }

  void _tripCircuit() {
    _circuitOpen = true;
    _running = false;
    AppLogger.warn(
        'Circuit breaker TRIPPED ($_consecutiveFailures consecutive failures).',
        tag: 'Queue');
  }
}
