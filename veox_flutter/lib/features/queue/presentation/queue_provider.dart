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
// Queue state
// ---------------------------------------------------------------------------

class QueueState {
  const QueueState({
    this.isRunning = false,
    this.circuitOpen = false,
    this.activeWorkers = 0,
    this.concurrency = 3,
    this.lastEvent,
  });

  final bool isRunning;
  final bool circuitOpen;
  final int activeWorkers;
  final int concurrency;
  final QueueProgressEvent? lastEvent;

  QueueState copyWith({
    bool? isRunning,
    bool? circuitOpen,
    int? activeWorkers,
    int? concurrency,
    QueueProgressEvent? lastEvent,
  }) =>
      QueueState(
        isRunning: isRunning ?? this.isRunning,
        circuitOpen: circuitOpen ?? this.circuitOpen,
        activeWorkers: activeWorkers ?? this.activeWorkers,
        concurrency: concurrency ?? this.concurrency,
        lastEvent: lastEvent ?? this.lastEvent,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final queueNotifierProvider =
    StateNotifierProvider<QueueNotifier, QueueState>((ref) {
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

  Future<void> start({int? concurrency}) async {
    final c = concurrency ?? state.concurrency;
    await _service.start(concurrency: c);
    state = state.copyWith(isRunning: true, concurrency: c);
  }

  void pause() {
    _service.pause();
    state = state.copyWith(isRunning: false);
  }

  void stop() {
    _service.stop();
    state = state.copyWith(isRunning: false);
  }

  Future<void> retryFailed() async {
    await _service.retryFailed();
    if (!state.isRunning) await start();
  }

  void resetCircuit() {
    _service.resetCircuit();
    state = state.copyWith(circuitOpen: false);
  }

  void setConcurrency(int value) {
    state = state.copyWith(concurrency: value.clamp(1, 10));
  }

  // ── Enqueue ───────────────────────────────────────────────────────────────

  Future<TaskModel> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    int priority = 5,
  }) {
    return _service.enqueue(type: type, payload: payload, priority: priority);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
