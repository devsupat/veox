import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Riverpod Provider
final automationBridgeProvider = Provider((ref) => AutomationBridgeService());

class AutomationBridgeService {
  Process? _process;
  Completer<void>? _initCompleter;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  // Stream for logs from Node
  final _logController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get logs => _logController.stream;

  Future<void> startEngine() async {
    if (_process != null) return;

    // In production, you'd bundle the node script or executable
    // For dev, we assume 'node' is in path and script is in automation_engine/

    // NOTE: Adjust path for your environment
    const scriptPath = 'automation_engine/index.js';

    try {
      _process = await Process.start('node', [
        scriptPath,
      ], workingDirectory: Directory.current.path);

      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleStdout);
      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            print('[Node STDERR] $line');
          });

      print("Automation Engine Process Started: PID ${_process!.pid}");
    } catch (e) {
      print("Failed to start automation engine: $e");
      rethrow;
    }
  }

  void _handleStdout(String line) {
    if (line.isEmpty) return;
    try {
      final data = jsonDecode(line);

      // Handle Log Event
      if (data['type'] == 'log') {
        _logController.add(data);
        print('[Node Log] ${data['message']}');
        return;
      }

      // Handle Response
      if (data.containsKey('id') && _pendingRequests.containsKey(data['id'])) {
        _pendingRequests[data['id']]!.complete(data);
        _pendingRequests.remove(data['id']);
      }
    } catch (e) {
      print("Error parsing node output: $line | $e");
    }
  }

  Future<Map<String, dynamic>> sendCommand(
    String command, [
    Map<String, dynamic>? payload,
  ]) async {
    if (_process == null) await startEngine();

    final id = const Uuid().v4();
    final msg = jsonEncode({
      'id': id,
      'command': command,
      'payload': payload ?? {},
    });

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    _process!.stdin.writeln(msg);

    // Timeout safety
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException("Command $command timed out");
      },
    );
  }

  Future<void> stopEngine() async {
    _process?.kill();
    _process = null;
  }
}
