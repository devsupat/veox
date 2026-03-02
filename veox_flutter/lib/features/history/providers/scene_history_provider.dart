import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';

final sceneHistoryProvider = StreamProvider<List<SceneModel>>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return isarService.watchScenes();
});
