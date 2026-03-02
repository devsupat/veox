import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Production-grade logger with console (debug only) and rotating file output.
///
/// Designed with SOLID principles to be scalable, maintainable, and robust.
class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  static const String _logFileName = 'veox.log';
  static const String _oldLogFileName = 'veox.old.log';
  static const int _defaultMaxLogSize = 5 * 1024 * 1024; // 5 MB

  late final Logger _logger;
  bool _initialized = false;

  /// Initializes the logger. Must be called once during app startup.
  ///
  /// [logLevel] defaults to [Level.info] in production and [Level.debug] in debug.
  Future<void> init({Level? logLevel}) async {
    if (_initialized) return;

    final outputs = <LogOutput>[];

    // Console output for development
    if (kDebugMode) {
      outputs.add(ConsoleOutput());
    }

    // Rotating file output for persistence
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(p.join(appDocDir.path, 'VEOX', 'logs'));

      if (!logsDir.existsSync()) {
        logsDir.createSync(recursive: true);
      }

      outputs.add(
        _RotatingFileOutput(
          p.join(logsDir.path, _logFileName),
          p.join(logsDir.path, _oldLogFileName),
          maxBytes: _defaultMaxLogSize,
        ),
      );
    } catch (e) {
      // Fail gracefully - logging issues shouldn't break the app
      debugPrint('AppLogger initialization warning: $e');
    }

    _logger = Logger(
      filter: ProductionFilter(),
      printer: _StructuredPrinter(),
      output: MultiOutput(outputs),
      level: logLevel ?? (kDebugMode ? Level.debug : Level.info),
    );

    _initialized = true;
    info('Logger initialized successfully', tag: 'System');
  }

  // --- Static API ---

  static void debug(String message, {String? tag, Object? error}) =>
      _instance._log(Level.debug, message, tag: tag, error: error);

  static void info(String message, {String? tag, Object? error}) =>
      _instance._log(Level.info, message, tag: tag, error: error);

  static void warn(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _instance._log(
    Level.warning,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _instance._log(
    Level.error,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  // --- Internal logic ---

  void _log(
    Level level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_initialized) {
      debugPrint(
        '[${level.name.toUpperCase()}] ${tag != null ? '[$tag] ' : ''}$message',
      );
      return;
    }

    final formattedMessage = tag != null ? '[$tag] $message' : message;
    _logger.log(level, formattedMessage, error: error, stackTrace: stackTrace);
  }
}

/// A printer that generates clean, timestamped, single-line logs for readability.
class _StructuredPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final timestamp = DateTime.now().toIso8601String().replaceFirst('T', ' ');
    // Safely get up to millisecond precision
    final timeStr = timestamp.length >= 23
        ? timestamp.substring(0, 23)
        : timestamp;

    final level = event.level.name.toUpperCase().padRight(5);
    final buffer = StringBuffer('$timeStr [$level] ${event.message}');

    if (event.error != null) {
      buffer.write('\n         ERROR: ${event.error}');
    }

    if (event.stackTrace != null) {
      // Capture top 8 lines of stack trace for concise debugging in files
      final stLines = event.stackTrace
          .toString()
          .split('\n')
          .take(8)
          .join('\n         ');
      buffer.write('\n         STACK: $stLines');
    }

    return [buffer.toString()];
  }
}

/// Custom [LogOutput] that writes to a file and rotates it when it grows too large.
class _RotatingFileOutput extends LogOutput {
  final String filePath;
  final String oldFilePath;
  final int maxBytes;

  _RotatingFileOutput(
    this.filePath,
    this.oldFilePath, {
    required this.maxBytes,
  });

  @override
  void output(OutputEvent event) {
    try {
      final file = File(filePath);

      // Check for rotation requirement
      if (file.existsSync() && file.lengthSync() > maxBytes) {
        _rotate(file);
      }

      // Append logs
      file.writeAsStringSync(
        '${event.lines.join('\n')}\n',
        mode: FileMode.append,
        flush: true, // Ensure it's written immediately to survive crashes
      );
    } catch (e) {
      // Prevent logging failures from affecting main app logic
      debugPrint('Log rotation/write error: $e');
    }
  }

  void _rotate(File file) {
    try {
      final oldFile = File(oldFilePath);
      if (oldFile.existsSync()) {
        oldFile.deleteSync();
      }
      file.renameSync(oldFilePath);
    } catch (e) {
      debugPrint('Log rotation failed: $e');
    }
  }
}
