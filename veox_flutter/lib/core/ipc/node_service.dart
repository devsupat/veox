import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class NodeService {
  Process? _process;
  final StreamController<Map<String, dynamic>> _logController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get logs => _logController.stream;

  Future<void> startEngine() async {
    // Kill any existing process first
    kill();
    
    // Resolve path to engine/main.js
    // In production (bundled app), this will be different.
    // For now, we assume we are running from source or built app structure.
    String enginePath;
    if (kDebugMode) {
      enginePath = 'engine/main.js';
    } else {
      // Production path logic (needs to be adjusted based on platform)
      // On macOS, it might be inside Contents/Resources
      final exeDir = File(Platform.resolvedExecutable).parent;
      enginePath = '${exeDir.path}/engine/main.js';
    }

    try {
      _process = await Process.start(
        'node', 
        [enginePath], 
        workingDirectory: Directory.current.path,
      );
      
      debugPrint("Node Engine started at PID: ${_process!.pid}");

      // Listen to Stdout (Logs & Results)
      _process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim().isEmpty) return;
        try {
          final json = jsonDecode(line);
          _logController.add(json);
          if (kDebugMode) {
            print("NODE: $line");
          }
        } catch (e) {
          print("Node Parse Error: $line");
        }
      });

      // Listen to Stderr (Critical Errors)
      _process!.stderr.transform(utf8.decoder).listen((data) {
        print("Node Error: $data");
      });
      
    } catch (e) {
      print("Failed to start Node Engine: $e");
      rethrow;
    }
  }

  void sendCommand(String id, String command, Map<String, dynamic> params) {
    if (_process == null) {
      print("Node Engine not running. Restarting...");
      startEngine().then((_) => _sendCommandInternal(id, command, params));
    } else {
      _sendCommandInternal(id, command, params);
    }
  }
  
  void _sendCommandInternal(String id, String command, Map<String, dynamic> params) {
    final payload = jsonEncode({
      "id": id,
      "command": command,
      "params": params
    });
    _process?.stdin.writeln(payload);
  }
  
  void kill() {
    _process?.kill();
    _process = null;
  }
}
