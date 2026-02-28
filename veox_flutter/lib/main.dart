// lib/main.dart
//
// Application entry point.
//
// Startup sequence:
//   1. Flutter binding initialised.
//   2. Window manager configured (desktop title, size).
//   3. AppLogger initialised (file output enabled).
//   4. DioClient initialised (connection pool).
//   5. Isar database opened.
//   6. Crash recovery: any tasks stuck in 'running' are reset to 'retrying'.
//   7. Node.js engine started.
//   8. App launched inside runZonedGuarded (catches unhandled errors).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/core/errors/error_handler.dart';
import 'package:veox_flutter/core/ipc/node_service.dart';
import 'package:veox_flutter/core/network/dio_client.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/providers/app_state.dart';
import 'package:veox_flutter/ui/layout/main_layout.dart';
import 'package:veox_flutter/ui/theme.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  // Wrap the entire app startup in runZonedGuarded so unhandled async errors
  // (e.g., from Isolates, timers) are logged rather than silently dropped.
  await runZonedGuarded(
    _boot,
    (error, stack) {
      AppLogger.error(
        'Unhandled zone error',
        tag: 'Main',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Window Manager ──────────────────────────────────────────────────────────
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(1024, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Veox Studio',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // ── Logger ───────────────────────────────────────────────────────────────────
  await AppLogger.instance.init();
  AppLogger.info('Veox Studio starting up…', tag: 'Main');

  // ── Networking ───────────────────────────────────────────────────────────────
  DioClient.instance.init();

  // ── Database ─────────────────────────────────────────────────────────────────
  await IsarService().init();
  AppLogger.info('Isar database opened.', tag: 'Main');

  // ── Crash Recovery ───────────────────────────────────────────────────────────
  // Any task left in 'running' means the app crashed mid-processing last session.
  // Reset them so the queue can retry them on this boot.
  await _recoverStaleTasks();

  // ── Node Engine ──────────────────────────────────────────────────────────────
  // Fire-and-don't-await: let the app open while Node boots in the background.
  // The queue service guards against sending commands before Node is ready.
  NodeService.instance.startEngine().catchError((Object e) {
    AppLogger.warn(
      'Node engine failed to start on boot: $e. '
      'Browser automation will be unavailable.',
      tag: 'Main',
    );
  });

  runApp(
    ProviderScope(
      observers: [VeoxProviderObserver()],
      child: const VeoxApp(),
    ),
  );
}

/// Resets tasks that were left in 'running' state due to a crash.
Future<void> _recoverStaleTasks() async {
  try {
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      final stale = await isar.taskModels
          .filter()
          .statusEqualTo('running')
          .findAll();
      for (final task in stale) {
        task.status = 'retrying';
        task.retryCount = (task.retryCount) + 1;
        task.errorLog = 'App crashed while processing — auto-retrying.';
      }
      await isar.taskModels.putAll(stale);
      if (stale.isNotEmpty) {
        AppLogger.warn('Recovered ${stale.length} stale task(s).',
            tag: 'CrashRecovery');
      }
    });
  } catch (e) {
    AppLogger.error('Crash recovery failed: $e', tag: 'CrashRecovery');
  }
}

class VeoxApp extends StatelessWidget {
  const VeoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The legacy [AppState] ChangeNotifier is kept alive during the incremental
    // Riverpod migration. It is removed in Phase 10.
    return p.MultiProvider(
      providers: [
        p.ChangeNotifierProvider<AppState>(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'Veox Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const MainLayout(),
      ),
    );
  }
}
