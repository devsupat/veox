// lib/core/process/process_runner.dart
//
// Safe wrapper around dart:io Process that:
//   1. Checks PATH availability before attempting to run.
//   2. Exposes both Future<ProcessResult> and Stream<String> variants.
//   3. Throws typed [MissingToolFailure] / [ProcessFailure] on error.
//   4. Supports cancellation via an exposed [Process] handle.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/utils/logger.dart';

/// Result of a completed process.
class ProcessOutput {
  const ProcessOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get succeeded => exitCode == 0;
}

/// [ProcessRunner] launches system executables safely.
///
/// Example:
/// ```dart
/// final out = await ProcessRunner.instance.run('yt-dlp', ['--version']);
/// if (!out.succeeded) throw ProcessFailure(out.stderr);
/// ```
class ProcessRunner {
  ProcessRunner._();
  static final ProcessRunner instance = ProcessRunner._();

  /// Cache of `which` results to avoid repeated PATH lookups.
  final Map<String, bool> _toolCache = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Runs [executable] with [args] and returns the combined output.
  ///
  /// Throws [MissingToolFailure] if [executable] is not in PATH.
  /// Throws [ProcessFailure] if exit code is non-zero and [throwOnError] is true.
  Future<ProcessOutput> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
  }) async {
    await _assertInstalled(executable);

    AppLogger.debug('\$ $executable ${args.join(' ')}', tag: 'Process');

    final result = await Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );

    final output = ProcessOutput(
      exitCode: result.exitCode,
      stdout: (result.stdout as String).trim(),
      stderr: (result.stderr as String).trim(),
    );

    if (!output.succeeded && throwOnError) {
      AppLogger.error(
        '$executable exited with ${output.exitCode}: ${output.stderr}',
        tag: 'Process',
      );
      throw ProcessFailure(
        '$executable failed: ${output.stderr.isNotEmpty ? output.stderr : 'exit ${output.exitCode}'}',
        exitCode: output.exitCode,
        stderr: output.stderr,
      );
    }

    return output;
  }

  /// Launches [executable] and returns a broadcast [Stream<String>] of stdout
  /// lines. Useful for long-running processes like ffmpeg.
  ///
  /// The returned [StreamController.sink] is closed when the process exits.
  /// If the process exits with a non-zero code, the stream adds an error.
  Stream<String> stream(
    String executable,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    void Function(Process)? onProcessCreated,
  }) async* {
    await _assertInstalled(executable);

    AppLogger.debug('\$ $executable ${args.join(' ')} [streaming]', tag: 'Process');

    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );

    onProcessCreated?.call(process);

    // Yield stdout lines.
    await for (final line
        in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      yield line;
    }

    // Collect stderr for error reporting.
    final err = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw ProcessFailure(
        '$executable exited with $exitCode: ${err.trim()}',
        exitCode: exitCode,
        stderr: err.trim(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Tool discovery
  // ---------------------------------------------------------------------------

  /// Returns `true` if [executable] is findable in the system PATH.
  Future<bool> isInstalled(String executable) async {
    if (_toolCache.containsKey(executable)) return _toolCache[executable]!;

    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [executable],
        runInShell: false,
      );
      final found = result.exitCode == 0;
      _toolCache[executable] = found;
      return found;
    } catch (_) {
      _toolCache[executable] = false;
      return false;
    }
  }

  Future<void> _assertInstalled(String executable) async {
    if (!await isInstalled(executable)) {
      throw MissingToolFailure(executable);
    }
  }
}
