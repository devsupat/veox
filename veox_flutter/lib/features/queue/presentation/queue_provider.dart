// lib/features/queue/presentation/queue_provider.dart
//
// Riverpod layer over QueueService. The UI only ever talks to this provider.
//
// Exposes:
//   • Reactive task list (live Isar stream).
//   • Control actions (start, pause, stop, retry, enqueue).
//   • Circuit breaker / running state.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/features/queue/domain/queue_service.dart';

// ---------------------------------------------------------------------------
// Live task list from Isar
// ---------------------------------------------------------------------------

/// Streams all tasks ordered by creation date descending.
final taskListProvider = StreamProvider<List<TaskModel>>((ref) async* {
  final isar = await IsarService().db;
  yield await isar.taskModels.where().sortByCreatedAtDesc().findAll();
  await for (final _ in isar.taskModels.watchLazy()) {
    yield await isar.taskModels.where().sortByCreatedAtDesc().findAll();
  }
});

// ---------------------------------------------------------------------------
// Queue Stats
// ---------------------------------------------------------------------------

class QueueStats {
  const QueueStats({
    this.total = 0,
    this.done = 0,
    this.active = 0,
    this.failed = 0,
    this.canceled = 0,
  });
  final int total;
  final int done;
  final int active;
  final int failed;
  final int canceled;
}

final queueStatsProvider = Provider<QueueStats>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final tasks = tasksAsync.value ?? [];
  return QueueStats(
    total: tasks.length,
    done: tasks.where((t) => t.status == 'completed').length,
    active: tasks
        .where(
          (t) =>
              t.status == 'running' ||
              t.status == 'pending' ||
              t.status == 'retrying' ||
              t.status == 'paused_needs_login',
        )
        .length,
    failed: tasks.where((t) => t.status == 'failed').length,
    canceled: tasks.where((t) => t.status == 'canceled').length,
  );
});

// ---------------------------------------------------------------------------
// Queue state
// ---------------------------------------------------------------------------

class QueueState {
  const QueueState({
    this.isRunning = false,
    this.circuitOpen = false,
    this.lastEvent,
  });

  final bool isRunning;
  final bool circuitOpen;
  final QueueProgressEvent? lastEvent;

  QueueState copyWith({
    bool? isRunning,
    bool? circuitOpen,
    QueueProgressEvent? lastEvent,
  }) => QueueState(
    isRunning: isRunning ?? this.isRunning,
    circuitOpen: circuitOpen ?? this.circuitOpen,
    lastEvent: lastEvent ?? this.lastEvent,
  );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final queueNotifierProvider = StateNotifierProvider<QueueNotifier, QueueState>((
  ref,
) {
  return QueueNotifier();
});

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier() : super(const QueueState()) {
    _subscribe();
  }

  final _service = QueueService.instance;
  StreamSubscription<QueueProgressEvent>? _sub;

  void _subscribe() {
    _sub = _service.progress.listen((event) {
      state = state.copyWith(
        lastEvent: event,
        isRunning: _service.isRunning,
        circuitOpen: _service.isCircuitOpen,
      );
    });
  }

  // ── Control ───────────────────────────────────────────────────────────────

  Future<void> start() async {
    await _service.start();
    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _service.pause();
    state = state.copyWith(isRunning: false);
  }

  void stop() {
    _service.stop(); // fire-and-forget: cancels active tasks in background
    state = state.copyWith(isRunning: false);
  }

  Future<void> retryFailed() async {
    await _service.retryFailed();
    if (!state.isRunning) await start();
  }

  Future<void> resumeAllPaused() async {
    await _service.resumeAllPaused();
    if (!state.isRunning) await start();
  }

  void resetCircuit() {
    _service.resetCircuit();
    state = state.copyWith(circuitOpen: false);
  }

  // ── Enqueue ───────────────────────────────────────────────────────────────

  Future<TaskModel> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    String? expectedOutputPath,
    int priority = 5,
  }) {
    return _service.enqueue(
      type: type,
      payload: payload,
      expectedOutputPath: expectedOutputPath,
      priority: priority,
    );
  }

  Future<int> enqueueBulk({
    required List<String> prompts,
    required String profileId,
    required String outputDir,
    String? projectId,
    List<String>? sceneIds,
    int from = 1,
    int? to,
    bool skipDone = true,
  }) {
    return _service.enqueueBulk(
      prompts: prompts,
      profileId: profileId,
      outputDir: outputDir,
      projectId: projectId,
      sceneIds: sceneIds,
      from: from,
      to: to,
      skipDone: skipDone,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
