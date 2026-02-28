import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p; // Alias to avoid conflict during migration
import 'package:veox_flutter/providers/app_state.dart';
import 'package:veox_flutter/ui/layout/main_layout.dart';
import 'package:veox_flutter/ui/theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:veox_flutter/core/database/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Window Manager
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: "Veox Studio",
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize DB
  await IsarService().init();

  runApp(const ProviderScope(child: VeoxApp()));
}

class VeoxApp extends StatelessWidget {
  const VeoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Migration: We wrap MaterialApp with the old Provider for backward compatibility
    // until we fully migrate UI to Riverpod
    return p.MultiProvider(
      providers: [
        p.ChangeNotifierProvider(create: (_) => AppState()),
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
