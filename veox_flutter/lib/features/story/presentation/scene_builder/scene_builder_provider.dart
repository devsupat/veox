import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:veox_flutter/features/story/domain/services/scene_service.dart';
import 'package:veox_flutter/features/story/presentation/character_studio_provider.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/features/queue/domain/queue_service.dart';
import 'package:isar/isar.dart';

final sceneBuilderProvider = StateNotifierProvider<SceneBuilderNotifier, SceneBuilderState>((ref) {
  return SceneBuilderNotifier(ref);
});

class SceneBuilderState {
  final List<SceneModel> scenes;
  final bool isProcessing;
  final String? error;

  SceneBuilderState({
    this.scenes = const [],
    this.isProcessing = false,
    this.error,
  });

  SceneBuilderState copyWith({
    List<SceneModel>? scenes,
    bool? isProcessing,
    String? error,
  }) {
    return SceneBuilderState(
      scenes: scenes ?? this.scenes,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class SceneBuilderNotifier extends StateNotifier<SceneBuilderState> {
  final Ref _ref;
  final SceneService _sceneService;

  SceneBuilderNotifier(this._ref) 
      : _sceneService = SceneService(),
        super(SceneBuilderState());

  Future<void> generateScenesFromStory(String storyText) async {
    if (storyText.trim().isEmpty) return;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Get known characters to help context
      final characters = _ref.read(characterStudioProvider).detectedCharacters;
      
      final scenes = await _sceneService.parseStoryToScenes(storyText, characters);
      
      state = state.copyWith(
        scenes: scenes,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: "Failed to generate scenes: ${e.toString()}",
      );
    }
  }

  void updateScenePrompt(int index, String newPrompt) {
    final newScenes = List<SceneModel>.from(state.scenes);
    newScenes[index].generatedPrompt = newPrompt;
    state = state.copyWith(scenes: newScenes);
  }
  
  void removeScene(int index) {
    final newScenes = List<SceneModel>.from(state.scenes);
    newScenes.removeAt(index);
    // Re-index
    for (int i = 0; i < newScenes.length; i++) {
      newScenes[i].index = i + 1;
    }
    state = state.copyWith(scenes: newScenes);
  }

  Future<void> saveScenesToProject() async {
    final isar = await IsarService().db;
    
    // For now, we assume there's an active project or create a default one
    var project = await isar.projectModels.where().findFirst();
    
    if (project == null) {
      project = ProjectModel()
        ..projectId = "default_project"
        ..name = "My First Project"
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      
      await isar.writeTxn(() async {
        await isar.projectModels.put(project!);
      });
    }

    // Save scenes
    await isar.writeTxn(() async {
      for (final scene in state.scenes) {
        await isar.sceneModels.put(scene);
        project!.scenes.add(scene);
      }
      await project!.scenes.save();
    });
  }

  Future<void> renderAllScenes() async {
    // 1. Save scenes first
    await saveScenesToProject();
    
    // 2. Queue tasks
    final queue = _ref.read(queueServiceProvider);
    
    for (final scene in state.scenes) {
      // Create a task for each scene
      // We use the prompt we generated
      await queue.addTask('generate_video', {
        'prompt': scene.generatedPrompt,
        'sceneId': scene.sceneId,
        'model': 'veo3', // Default for now
      });
    }
  }
}
