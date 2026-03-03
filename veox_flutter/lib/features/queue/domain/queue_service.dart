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
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/ipc/node_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

class QueueProgressEvent {
  const QueueProgressEvent({
    required this.taskId,
    required this.status,
    this.stage,
    this.outputPath,
    this.error,
    this.errorCategory,
    this.retryable = true,
  });
  final String taskId;
  final String status;
  final String? stage;
  final String? outputPath;
  final String? error;
  final String? errorCategory;
  final bool retryable;
}

// ---------------------------------------------------------------------------
// Service (singleton)
// ---------------------------------------------------------------------------

class QueueService {
  QueueService._() {
    _init();
  }
  static final QueueService instance = QueueService._();

  void _init() {
    NodeService.instance.eventStream.listen(_handleNodeEvent);
  }

  static const int browserPoolMax = 1;
  static const int localPoolMax = 2;
  static const int circuitBreakerLimit = 5;

  bool _running = false;
  int _activeBrowserWorkers = 0;
  int _activeLocalWorkers = 0;
  int _consecutiveFailures = 0;
  bool _circuitOpen = false;

  final _progressController = StreamController<QueueProgressEvent>.broadcast();
  Stream<QueueProgressEvent> get progress => _progressController.stream;

  bool get isRunning => _running;
  bool get isCircuitOpen => _circuitOpen;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_running) return;
    if (_circuitOpen) {
      AppLogger.warn(
        'Circuit breaker OPEN. Call resetCircuit() first.',
        tag: 'Queue',
      );
      return;
    }
    _running = true;
    AppLogger.info(
      'Queue started (browser=$browserPoolMax, local=$localPoolMax)',
      tag: 'Queue',
    );
    _tick();
  }

  /// Pause scheduling — no new tasks will be dispatched, but active tasks
  /// continue running until they complete or fail.
  void pause() {
    _running = false;
    AppLogger.info('Queue paused (active tasks continue).', tag: 'Queue');
  }

  /// Stop active tasks — cancels running and paused_needs_login tasks, then
  /// pauses scheduling. Does NOT cancel pending tasks.
  Future<void> stop() async {
    _running = false;
    final isar = await IsarService().db;
    final activeTasks = await isar.taskModels
        .filter()
        .group(
          (q) => q
              .statusEqualTo('running')
              .or()
              .statusEqualTo('paused_needs_login'),
        )
        .findAll();
    for (final task in activeTasks) {
      await cancelTask(task.taskId);
    }
    AppLogger.info(
      'Queue stopped (${activeTasks.length} active task(s) cancelled).',
      tag: 'Queue',
    );
  }

  void resetCircuit() {
    _circuitOpen = false;
    _consecutiveFailures = 0;
    if (_running) _tick();
    AppLogger.info('Circuit breaker reset.', tag: 'Queue');
  }

  // ── Enqueue ───────────────────────────────────────────────────────────────

  Future<TaskModel> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    String? expectedOutputPath,
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
      ..retryCount = 0
      ..outputPath = expectedOutputPath;

    await isar.writeTxn(() async => isar.taskModels.put(task));
    AppLogger.info('Enqueued ${task.taskId} ($type p=$priority)', tag: 'Queue');

    if (_running) _tick();
    return task;
  }

  // ── Bulk Enqueue ──────────────────────────────────────────────────────────

  /// Deterministic SHA-1 hash for a prompt identity.
  static String computePromptHash({
    required String profileId,
    required String normalizedPrompt,
    required int index,
  }) {
    final input = '$profileId|${normalizedPrompt.trim().toLowerCase()}|$index';
    return sha1.convert(utf8.encode(input)).toString();
  }

  /// Enqueue N browser_generate_video tasks from a list of prompts.
  ///
  /// - [skipDone]: if true, skip prompts whose promptHash already has a
  ///   completed task with a valid output file.
  /// - [from]/[to]: 1-indexed inclusive range to slice prompts.
  /// - Returns the number of tasks actually enqueued.
  Future<int> enqueueBulk({
    required List<String> prompts,
    required String profileId,
    required String outputDir,
    String? projectId,
    List<String>? sceneIds,
    int from = 1,
    int? to,
    bool skipDone = true,
  }) async {
    final isar = await IsarService().db;
    final effectiveTo = (to ?? prompts.length).clamp(1, prompts.length);
    final effectiveFrom = from.clamp(1, effectiveTo);
    int enqueued = 0;

    for (int i = effectiveFrom - 1; i < effectiveTo; i++) {
      final prompt = prompts[i].trim();
      if (prompt.isEmpty) continue;

      final hash = computePromptHash(
        profileId: profileId,
        normalizedPrompt: prompt,
        index: i,
      );

      // skipDone: check if a task with this hash already completed with valid output
      if (skipDone) {
        final existing = await isar.taskModels
            .filter()
            .promptHashEqualTo(hash)
            .findFirst();
        if (existing != null &&
            existing.status == 'completed' &&
            existing.outputPath != null) {
          final file = File(existing.outputPath!);
          if (file.existsSync() && file.lengthSync() > 1024) {
            AppLogger.info(
              'Skipping prompt #${i + 1} (already completed: ${existing.taskId})',
              tag: 'Queue',
            );
            continue;
          }
        }
        // Also skip if there's already a pending/running/retrying task for this hash
        if (existing != null &&
            (existing.status == 'pending' ||
                existing.status == 'running' ||
                existing.status == 'retrying')) {
          AppLogger.info(
            'Skipping prompt #${i + 1} (task already in queue: ${existing.taskId})',
            tag: 'Queue',
          );
          continue;
        }
      }

      final taskId = const Uuid().v4();
      final outputPath = '$outputDir/videos/$taskId.mp4';
      final payload = {
        'type': 'browser_generate_video',
        'prompt': prompt,
        'profileId': profileId,
        'outputPath': outputPath,
      };

      if (projectId != null) {
        payload['projectId'] = projectId;
      }
      if (sceneIds != null && i < sceneIds.length) {
        payload['sceneId'] = sceneIds[i];
      }

      final task = TaskModel()
        ..taskId = taskId
        ..type = 'browser_generate_video'
        ..status = 'pending'
        ..payloadJson = jsonEncode(payload)
        ..priority = 5
        ..createdAt = DateTime.now()
        ..retryCount = 0
        ..outputPath = outputPath
        ..promptHash = hash;

      await isar.writeTxn(() async => isar.taskModels.put(task));
      enqueued++;
    }

    AppLogger.info(
      'Bulk enqueued $enqueued of ${effectiveTo - effectiveFrom + 1} tasks.',
      tag: 'Queue',
    );
    if (_running) _tick();
    return enqueued;
  }

  // ── Retry ─────────────────────────────────────────────────────────────────

  /// Retry only retryable failed tasks. Non-retryable failures are left alone.
  Future<void> retryFailed() async {
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      final failed = await isar.taskModels
          .filter()
          .statusEqualTo('failed')
          .retryableEqualTo(true)
          .findAll();
      for (final t in failed) {
        t.status = 'retrying';
        final backoffSeconds =
            pow(2, t.retryCount).toInt() + Random().nextInt(5);
        t.retryAfter = DateTime.now().add(Duration(seconds: backoffSeconds));
        t.retryCount = t.retryCount + 1;
      }
      await isar.taskModels.putAll(failed);
      AppLogger.info(
        'Retrying ${failed.length} retryable failed tasks.',
        tag: 'Queue',
      );
    });
    if (_running) _tick();
  }

  // ── Resume All Paused ────────────────────────────────────────────────────

  /// Sets all paused_needs_login tasks back to pending and ticks.
  Future<void> resumeAllPaused() async {
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      final paused = await isar.taskModels
          .filter()
          .statusEqualTo('paused_needs_login')
          .findAll();
      for (final t in paused) {
        t.status = 'pending';
      }
      await isar.taskModels.putAll(paused);
      AppLogger.info('Resumed ${paused.length} paused tasks.', tag: 'Queue');
    });
    if (_running) _tick();
  }

  Future<void> resumeTask(String taskId) async {
    final isar = await IsarService().db;
    final task = await isar.taskModels
        .filter()
        .taskIdEqualTo(taskId)
        .findFirst();
    if (task == null) return;

    if (task.status == 'paused_needs_login') {
      await isar.writeTxn(() async {
        task.status = 'pending'; // Re-dispatch
        await isar.taskModels.put(task);
      });
      AppLogger.info('Resuming task $taskId', tag: 'Queue');
      if (_running) _tick();
    }
  }

  Future<void> cancelTask(String taskId) async {
    final isar = await IsarService().db;
    final task = await isar.taskModels
        .filter()
        .taskIdEqualTo(taskId)
        .findFirst();
    if (task == null) return;

    if (task.status == 'running' || task.status == 'paused_needs_login') {
      // Send cancel to Node — safe even if the job already finished
      try {
        await NodeService.instance.sendCommand(
          const Uuid().v4(),
          'job_cancel',
          {'taskId': taskId},
        );
      } catch (_) {
        // job_cancel is best effort; ignore node errors
      }
    }

    await isar.writeTxn(() async {
      task.status = 'canceled';
      task.errorLog = 'Cancelled by user';
      await isar.taskModels.put(task);
    });

    _progressController.add(
      QueueProgressEvent(
        taskId: taskId,
        status: 'canceled',
        error: 'Cancelled by user',
      ),
    );
    AppLogger.info('Cancelled task $taskId', tag: 'Queue');
  }

  // ── Tick loop ─────────────────────────────────────────────────────────────

  Future<void> _tick() async {
    if (!_running || _circuitOpen) return;

    final isBrowserFull = _activeBrowserWorkers >= browserPoolMax;
    final isLocalFull = _activeLocalWorkers >= localPoolMax;

    if (isBrowserFull && isLocalFull) return;

    final isar = await IsarService().db;
    final now = DateTime.now();

    // Find the highest priority eligible task that respects backoff and pool limits
    final tasks = await isar.taskModels
        .filter()
        .group((q) => q.statusEqualTo('pending').or().statusEqualTo('retrying'))
        .and()
        .group((q) => q.retryAfterIsNull().or().retryAfterLessThan(now))
        .sortByPriorityDesc()
        .findAll(); // Get all eligible tasks

    TaskModel? taskToRun;
    bool isBrowserTask = false;

    for (var task in tasks) {
      final isBrowser =
          task.type == 'browser_screenshot' ||
          task.type == 'browser_generate_video' ||
          task.type == 'browser_action';
      if (isBrowser && !isBrowserFull) {
        taskToRun = task;
        isBrowserTask = true;
        break;
      } else if (!isBrowser && !isLocalFull) {
        taskToRun = task;
        isBrowserTask = false;
        break;
      }
    }

    if (taskToRun == null) {
      if (_activeBrowserWorkers == 0 && _activeLocalWorkers == 0) {
        AppLogger.info('Queue drained or waiting for backoff.', tag: 'Queue');
      }
      return;
    }

    // Atomic claim: mark 'running'
    await isar.writeTxn(() async {
      taskToRun!.status = 'running';
      taskToRun.startedAt = DateTime.now();
      await isar.taskModels.put(taskToRun);
    });

    if (isBrowserTask) {
      _activeBrowserWorkers++;
    } else {
      _activeLocalWorkers++;
    }

    _processTask(taskToRun, isBrowserTask).whenComplete(() {
      if (isBrowserTask) {
        _activeBrowserWorkers--;
      } else {
        _activeLocalWorkers--;
      }
      if (_running) _tick();
    });

    // Saturate slots eagerly
    unawaited(_tick());
  }

  // ── Dispatch ──────────────────────────────────────────────────────────────

  Future<void> _processTask(TaskModel task, bool isBrowserTask) async {
    AppLogger.info('Processing ${task.taskId} (${task.type})', tag: 'Queue');
    try {
      final payload = jsonDecode(task.payloadJson) as Map<String, dynamic>;

      // Idempotency check
      if (task.outputPath != null && task.outputPath!.isNotEmpty) {
        final file = File(task.outputPath!);
        if (file.existsSync() &&
            file.lengthSync() > 1024 &&
            !task.outputPath!.endsWith('.partial')) {
          AppLogger.info(
            'Task ${task.taskId} already completed (valid file exists at ${task.outputPath}).',
            tag: 'Queue',
          );
          await _complete(task, outputPath: task.outputPath);
          _progressController.add(
            QueueProgressEvent(
              taskId: task.taskId,
              status: 'completed',
              outputPath: task.outputPath,
            ),
          );
          return;
        }
      }

      String? newOutputPath;
      switch (task.type) {
        case 'video_gen':
          newOutputPath = await _videoGen(task.taskId, payload);
        case 'browser_screenshot':
        case 'browser_generate_video':
        case 'browser_action':
          newOutputPath = await _browserAction(task.taskId, payload, task.type);
        default:
          throw UnsupportedError('Unknown task type: ${task.type}');
      }

      final finalPath = newOutputPath ?? task.outputPath;
      await _complete(task, outputPath: finalPath);
      _consecutiveFailures = 0;
      _progressController.add(
        QueueProgressEvent(
          taskId: task.taskId,
          status: 'completed',
          outputPath: finalPath,
        ),
      );
    } catch (e, st) {
      final isar = await IsarService().db;
      if (e is _SilentPauseException) {
        // Task remains in its status or is updated by event listener
        // But we must ensure it's marked correctly if the event didn't fire yet
        await _setTaskStatus(task.taskId, 'paused_needs_login');
        return;
      }

      AppLogger.error(
        'Task ${task.taskId} failed',
        tag: 'Queue',
        error: e,
        stackTrace: st,
      );

      bool isRetryable = true;
      String? category;
      if (e is ProcessFailure) {
        isRetryable = e.retryable;
        category = e.errorCategory;
      }

      final targetStatus = 'failed';

      await isar.writeTxn(() async {
        task.status = targetStatus;
        task.errorLog = e.toString();
        task.errorCategory = category;
        task.retryable = isRetryable;
        await isar.taskModels.put(task);
      });

      if (isRetryable) {
        _consecutiveFailures++;
        if (_consecutiveFailures >= circuitBreakerLimit) _tripCircuit();
      }

      _progressController.add(
        QueueProgressEvent(
          taskId: task.taskId,
          status: targetStatus,
          error: e.toString(),
          errorCategory: category,
          retryable: isRetryable,
        ),
      );
    }
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<String?> _videoGen(String taskId, Map<String, dynamic> payload) async {
    final result = await NodeService.instance.sendCommand(
      taskId,
      'generate_video',
      payload,
    );
    return result['outputPath'] as String?;
  }

  Future<String?> _browserAction(
    String taskId,
    Map<String, dynamic> payload,
    String type,
  ) async {
    // If it's the new golden path browser_screenshot or browser_generate_video, we use job_start
    final command =
        (type == 'browser_screenshot' || type == 'browser_generate_video')
        ? 'job_start'
        : (payload['command'] as String? ?? 'job_start');
    final params = Map<String, dynamic>.from(payload)..remove('command');

    // Add type if missing for job_start
    if (command == 'job_start' && !params.containsKey('type')) {
      params['type'] = type;
    }

    // Ensure taskId is passed in params for internal node routing
    params['taskId'] = taskId;

    final result = await NodeService.instance.sendCommand(
      taskId,
      command,
      params,
    );

    // If it paused for login, we throw a specific "exception" or return null
    // Node returns { status: 'paused_needs_login' } in the result for job_start result.
    if (result['status'] == 'paused_needs_login') {
      // The task will be marked as 'running' in DB still?
      // No, we need to mark it as paused_needs_login in DB.
      // But _processTask will call _fail if we throw or _complete if we return.
      // We need a middle ground. Let's throw a SilentPauseException.
      throw _SilentPauseException();
    }

    return result['outputPath'] as String?;
  }

  // ── Internal Node Event Handling ──────────────────────────────────────────

  void _handleNodeEvent(Map<String, dynamic> event) {
    final taskId = event['id'] as String?;
    if (taskId == null) return;

    if (event['action'] == 'needs_login') {
      _setTaskStatus(taskId, 'paused_needs_login');
      _progressController.add(
        QueueProgressEvent(taskId: taskId, status: 'paused_needs_login'),
      );
      return;
    }

    if (event['stage'] != null) {
      _progressController.add(
        QueueProgressEvent(
          taskId: taskId,
          status: 'running',
          stage: event['stage'] as String,
        ),
      );
    }
  }

  Future<void> _setTaskStatus(String taskId, String status) async {
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      final task = await isar.taskModels
          .filter()
          .taskIdEqualTo(taskId)
          .findFirst();
      if (task != null) {
        task.status = status;
        await isar.taskModels.put(task);
      }
    });
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

  void _tripCircuit() {
    _circuitOpen = true;
    _running = false;
    AppLogger.warn(
      'Circuit breaker TRIPPED ($_consecutiveFailures consecutive failures).',
      tag: 'Queue',
    );
  }
}

class _SilentPauseException implements Exception {}
