import 'dart:io';
import 'package:veox_flutter/core/utils/logger.dart';

class PlatformUtils {
  PlatformUtils._();

  /// Creates physical directory if it doesn't exist.
  static Future<void> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Opens the directory in the native file explorer (macOS Finder or Windows Explorer).
  static Future<void> openFolder(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to open folder: $path',
        tag: 'PlatformUtils',
        error: e,
        stackTrace: st,
      );
    }
  }
}
