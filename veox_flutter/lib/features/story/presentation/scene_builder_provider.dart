// lib/features/story/presentation/scene_builder_provider.dart
//
// Riverpod layer for the Story/Scene Builder tab.

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/features/queue/presentation/queue_provider.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:veox_flutter/features/story/domain/services/scene_builder_service.dart';

// ── State ──────────────────────────────────────────────────────────────────

class SceneBuilderState {
  const SceneBuilderState({
    this.scenes = const [],
    this.characters = const [],
    this.isParsing = false,
    this.isGenerating = false,
    this.completedCount = 0,
    this.error,
  });

  final List<SceneModel> scenes;
  final List<CharacterModel> characters;
  final bool isParsing;
  final bool isGenerating;
  final int completedCount;
  final String? error;

  int get totalScenes => scenes.length;
  double get progress => totalScenes == 0 ? 0 : completedCount / totalScenes;

  SceneBuilderState copyWith({
    List<SceneModel>? scenes,
    List<CharacterModel>? characters,
    bool? isParsing,
    bool? isGenerating,
    int? completedCount,
    String? error,
    bool clearError = false,
  }) => SceneBuilderState(
    scenes: scenes ?? this.scenes,
    characters: characters ?? this.characters,
    isParsing: isParsing ?? this.isParsing,
    isGenerating: isGenerating ?? this.isGenerating,
    completedCount: completedCount ?? this.completedCount,
    error: clearError ? null : (error ?? this.error),
  );
}

// ── Provider ──────────────────────────────────────────────────────────────

final sceneBuilderProvider =
    StateNotifierProvider<SceneBuilderNotifier, SceneBuilderState>((ref) {
      return SceneBuilderNotifier();
    });

// ── Notifier ──────────────────────────────────────────────────────────────

class SceneBuilderNotifier extends StateNotifier<SceneBuilderState> {
  SceneBuilderNotifier() : super(const SceneBuilderState());

  final _svc = SceneBuilderService.instance;
  StreamSubscription<SceneModel>? _genSub;

  // ── Parse Story ────────────────────────────────────────────────────────

  Future<void> parseStory(String storyText, {required String projectId}) async {
    if (storyText.trim().isEmpty) return;
    state = state.copyWith(isParsing: true, clearError: true);

    try {
      final result = await _svc.parseStory(storyText, projectId: projectId);
      state = state.copyWith(
        isParsing: false,
        scenes: result.scenes,
        characters: result.characters,
        completedCount: 0,
      );
    } catch (e) {
      state = state.copyWith(isParsing: false, error: 'Parse failed: $e');
    }
  }

  // ── Load directly from Character Studio JSON ──────────────────────────────

  Future<void> loadScenesFromJson(String jsonString, String projectId) async {
    if (jsonString.trim().isEmpty) return;
    state = state.copyWith(isParsing: true, clearError: true);

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final isarSvc = IsarService();

      final charsRaw = decoded['character_reference'] as List? ?? [];
      final scenesRaw = decoded['scenes'] as List? ?? [];

      final characterModels = charsRaw
          .map(
            (c) => CharacterModel()
              ..characterId = const Uuid().v4()
              ..name = c['name'] ?? 'Unknown'
              ..description = c['description'] ?? '',
          )
          .toList();

      final sceneModels = scenesRaw
          .map(
            (s) => SceneModel()
              ..sceneId = const Uuid().v4()
              ..index = s['scene_number'] ?? 0
              ..text = s['description'] ?? ''
              ..generatedPrompt = s['prompt'] ?? ''
              ..status = 'pending',
          )
          .toList();

      await isarSvc.replaceProjectScenesAndCharacters(
        projectId,
        characterModels,
        sceneModels,
      );

      state = state.copyWith(
        isParsing: false,
        scenes: sceneModels,
        characters: characterModels,
        completedCount: 0,
      );
    } catch (e) {
      state = state.copyWith(isParsing: false, error: 'JSON load failed: $e');
    }
  }

  // ── Generate Images ────────────────────────────────────────────────────

  Future<void> generateSceneImages(
    String projectId, {
    int concurrency = 3,
  }) async {
    if (state.scenes.isEmpty) return;

    state = state.copyWith(
      isGenerating: true,
      completedCount: 0,
      clearError: true,
    );

    _genSub = _svc
        .generateAllScenes(projectId, maxConcurrent: concurrency)
        .listen(
          (scene) {
            final idx = state.scenes.indexWhere(
              (s) => s.sceneId == scene.sceneId,
            );
            if (idx != -1) {
              final updated = List<SceneModel>.from(state.scenes);
              updated[idx] = scene;
              state = state.copyWith(
                scenes: updated,
                completedCount: state.completedCount + 1,
              );
            }
          },
          onDone: () => state = state.copyWith(isGenerating: false),
          onError: (Object e) {
            AppLogger.error('Scene generation error: $e', tag: 'SceneBuilder');
            state = state.copyWith(isGenerating: false, error: e.toString());
          },
        );
  }

  // ── Batch Enqueue to Playwright Engine ────────────────────────────────

  Future<void> batchEnqueueVideos({
    required WidgetRef ref, // We pass UI ref to trigger queueNotifier
    required String profileId,
    required String outputDir,
    required String projectId,
  }) async {
    if (state.scenes.isEmpty) return;

    final prompts = state.scenes.map((s) => s.generatedPrompt).toList();
    final sceneIds = state.scenes.map((s) => s.sceneId).toList();

    await ref
        .read(queueNotifierProvider.notifier)
        .enqueueBulk(
          prompts: prompts,
          profileId: profileId,
          outputDir: outputDir,
          projectId: projectId,
          sceneIds: sceneIds,
        );
  }

  Future<void> regenerateSingleScene(String sceneId) async {
    try {
      final updated = await _svc.generateSingleScene(sceneId);
      final idx = state.scenes.indexWhere((s) => s.sceneId == sceneId);
      if (idx != -1) {
        final list = List<SceneModel>.from(state.scenes);
        list[idx] = updated;
        state = state.copyWith(scenes: list);
      }
    } catch (e) {
      state = state.copyWith(error: 'Scene regen failed: $e');
    }
  }

  void cancel() {
    _genSub?.cancel();
    state = state.copyWith(isGenerating: false);
  }

  @override
  void dispose() {
    _genSub?.cancel();
    super.dispose();
  }
}
