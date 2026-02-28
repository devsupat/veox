// lib/core/utils/logger.dart
//
// Production-grade dual logger: console output (during development) and
// rotating file output (always). Structured log lines include timestamp,
// level, and optional tag for easier grepping.
//
// Usage:
//   AppLogger.info('Queue started', tag: 'Queue');
//   AppLogger.error('API call failed', error: e, stackTrace: st);

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Severity levels used internally — mapped from [Level].
enum LogLevel { debug, info, warn, error }

/// Singleton app-wide logger.
///
/// Outputs to:
///   1. Pretty console (debug builds only).
///   2. Rotating flat file at `~/Documents/VEOX/logs/veox.log`.
class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  late final Logger _logger;
  bool _initialised = false;

  /// Must be called once during app startup (after [path_provider] is ready).
  Future<void> init() async {
    if (_initialised) return;

    final outputs = <LogOutput>[if (kDebugMode) ConsoleOutput()];

    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/VEOX/logs');
      if (!logsDir.existsSync()) logsDir.createSync(recursive: true);
      outputs.add(_RotatingFileOutput(logsDir.path));
    } catch (e) {
      // File logging failure must not crash the app.
      debugPrint('AppLogger: cannot open log file — $e');
    }

    _logger = Logger(
      filter: ProductionFilter(),
      printer: _StructuredPrinter(),
      output: MultiOutput(outputs),
    );

    _initialised = true;
  }

  static void debug(String message, {String? tag, Object? error}) =>
      _instance._log(Level.debug, message, tag: tag, error: error);

  static void info(String message, {String? tag, Object? error}) =>
      _instance._log(Level.info, message, tag: tag, error: error);

  static void warn(String message,
          {String? tag, Object? error, StackTrace? stackTrace}) =>
      _instance._log(Level.warning, message,
          tag: tag, error: error, stackTrace: stackTrace);

  static void error(String message,
          {String? tag, Object? error, StackTrace? stackTrace}) =>
      _instance._log(Level.error, message,
          tag: tag, error: error, stackTrace: stackTrace);

  void _log(
    Level level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_initialised) {
      debugPrint('[${level.name.toUpperCase()}] $message');
      return;
    }

    final tagged = tag != null ? '[$tag] $message' : message;
    _logger.log(level, tagged, error: error, stackTrace: stackTrace);
  }
}

/// Formats log lines as:
/// `2026-03-01 01:11:45.000 [INFO ] Message`
class _StructuredPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final now = DateTime.now().toIso8601String().replaceFirst('T', ' ').substring(0, 23);
    final levelStr = event.level.name.toUpperCase().padRight(5);
    final line = '$now [$levelStr] ${event.message}';
    final lines = [line];
    if (event.error != null) lines.add('  ERROR: ${event.error}');
    if (event.stackTrace != null) {
      lines.add('  STACK: ${event.stackTrace.toString().split('\n').take(6).join('\n         ')}');
    }
    return lines;
  }
}

/// Appends structured log lines to a file, rotating when size exceeds [maxBytes].
class _RotatingFileOutput extends LogOutput {
  final String dirPath;
  final int maxBytes;

  _RotatingFileOutput(this.dirPath, {this.maxBytes = 5 * 1024 * 1024}); // 5 MB

  File get _file => File('$dirPath/veox.log');

  @override
  void output(OutputEvent event) {
    try {
      final f = _file;
      if (f.existsSync() && f.lengthSync() > maxBytes) {
        // Rotate: rename current → .old, begin fresh
        f.renameSync('$dirPath/veox.old.log');
      }
      f.writeAsStringSync('${event.lines.join('\n')}\n', mode: FileMode.append);
    } catch (_) {
      // Swallow — never let logging crash the app.
    }
  }
}
