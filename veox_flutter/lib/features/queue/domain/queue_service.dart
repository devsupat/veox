import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/core/ipc/node_service.dart';
import 'package:uuid/uuid.dart';

final queueServiceProvider = Provider<QueueService>((ref) {
  return QueueService(ref);
});

final taskListProvider = StreamProvider<List<TaskModel>>((ref) async* {
  final isar = await IsarService().db;
  // Yield initial
  yield await isar.taskModels.where().sortByCreatedAtDesc().findAll();
  
  // Watch for changes
  await for (final _ in isar.taskModels.watchLazy()) {
    yield await isar.taskModels.where().sortByCreatedAtDesc().findAll();
  }
});

class QueueService {
  final Ref _ref;
  final NodeService _nodeService = NodeService();
  bool _isRunning = false;
  Timer? _loopTimer;
  
  QueueService(this._ref) {
    _init();
  }
  
  void _init() {
    _nodeService.startEngine();
    _nodeService.logs.listen((msg) {
      if (msg['type'] == 'result') {
        _handleResult(msg);
      } else if (msg['type'] == 'log') {
        // TODO: Persist logs
      }
    });
  }
  
  Future<void> addTask(String type, Map<String, dynamic> payload) async {
    final isar = await IsarService().db;
    final task = TaskModel()
      ..taskId = const Uuid().v4()
      ..type = type
      ..status = 'pending'
      ..createdAt = DateTime.now()
      ..payloadJson = jsonEncode(payload);
      
    await isar.writeTxn(() async {
      await isar.taskModels.put(task);
    });
    
    // Trigger loop if not running
    if (!_isRunning) startQueue();
  }
  
  void startQueue() {
    if (_isRunning) return;
    _isRunning = true;
    _processNext();
  }
  
  void stopQueue() {
    _isRunning = false;
    _loopTimer?.cancel();
  }
  
  Future<void> _processNext() async {
    if (!_isRunning) return;
    
    final isar = await IsarService().db;
    
    // Find next pending task
    final task = await isar.taskModels
        .filter()
        .statusEqualTo('pending')
        .sortByCreatedAt()
        .findFirst();
        
    if (task == null) {
      // No tasks, check again in 2 seconds
      _loopTimer = Timer(const Duration(seconds: 2), _processNext);
      return;
    }
    
    // Mark as running
    task.status = 'running';
    task.startedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.taskModels.put(task);
    });
    
    // Execute
    final payload = jsonDecode(task.payloadJson);
    String command;
    switch (task.type) {
      case 'open_browser': command = 'open_browser'; break;
      default: command = 'ping';
    }
    
    _nodeService.sendCommand(task.taskId, command, payload);
  }
  
  Future<void> _handleResult(Map<String, dynamic> msg) async {
    final id = msg['id'];
    final status = msg['status'];
    final data = msg['data']; // unused for now
    final error = msg['error'];
    
    final isar = await IsarService().db;
    final task = await isar.taskModels.filter().taskIdEqualTo(id).findFirst();
    
    if (task != null) {
      await isar.writeTxn(() async {
        task.status = status == 'success' ? 'completed' : 'failed';
        task.completedAt = DateTime.now();
        if (error != null) task.errorLog = error.toString();
        await isar.taskModels.put(task);
      });
    }
    
    // Process next immediately
    if (_isRunning) _processNext();
  }
}
