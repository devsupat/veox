// lib/features/story/domain/services/scene_builder_service.dart
//
// Orchestrates:
//   1. Story text → LLM parse → CharacterModels + SceneModels in Isar
//   2. Scene image generation with configurable concurrency (default 3)
//
// The generation step returns a Stream<SceneModel> so the UI can render
// each completed scene as it arrives, rather than waiting for all N.

import 'dart:async';

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/features/story/data/image_generation_client.dart';
import 'package:veox_flutter/features/story/data/llm_client.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';

class SceneParseResult {
  const SceneParseResult({
    required this.characters,
    required this.scenes,
  });
  final List<CharacterModel> characters;
  final List<SceneModel> scenes;
}

class SceneBuilderService {
  SceneBuilderService._();
  static final SceneBuilderService instance = SceneBuilderService._();

  final _llm = LLMClient.instance;
  final _imgClient = ImageGenerationClient.instance;

  // ── Parse Story ────────────────────────────────────────────────────────────

  /// Calls the LLM to parse [storyText] into characters and scenes,
  /// then persists them all to Isar under the given [projectId].
  Future<SceneParseResult> parseStory(
    String storyText, {
    required String projectId,
  }) async {
    final parsed = await _llm.parseStoryToScenes(storyText);
    final isar = await IsarService().db;

    // Find project
    final project = await isar.projectModels
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
    if (project == null) {
      throw DatabaseFailure('Project $projectId not found.');
    }

    // Convert ParsedCharacter → CharacterModel
    final characterModels = parsed.characters.map((c) {
      return CharacterModel()
        ..characterId = const Uuid().v4()
        ..name = c.name
        ..description = '${c.description} ${c.appearance}'.trim();
    }).toList();

    // Convert ParsedScene → SceneModel
    final sceneModels = parsed.scenes.asMap().map((i, s) {
      final model = SceneModel()
        ..sceneId = const Uuid().v4()
        ..index = s.sceneNumber
        ..text = s.description
        ..generatedPrompt = s.visualPrompt
        ..status = 'pending';
      return MapEntry(i, model);
    }).values.toList();

    // Persist in a single transaction
    await isar.writeTxn(() async {
      await isar.characterModels.putAll(characterModels);
      await isar.sceneModels.putAll(sceneModels);

      await project.characters.load();
      await project.scenes.load();
      project.characters.addAll(characterModels);
      project.scenes.addAll(sceneModels);
      await project.characters.save();
      await project.scenes.save();
    });

    AppLogger.info(
        'Parsed ${characterModels.length} characters, '
        '${sceneModels.length} scenes for project $projectId.',
        tag: 'SceneBuilder');

    return SceneParseResult(characters: characterModels, scenes: sceneModels);
  }

  // ── Generate All Scenes ───────────────────────────────────────────────────

  /// Generates images for all pending scenes in [projectId].
  /// Yields each [SceneModel] as soon as its image is ready.
  /// Concurrency is limited to [maxConcurrent] simultaneous API calls.
  Stream<SceneModel> generateAllScenes(
    String projectId, {
    int maxConcurrent = 3,
  }) async* {
    final isar = await IsarService().db;
    final project = await isar.projectModels
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();

    if (project == null) {
      throw DatabaseFailure('Project $projectId not found.');
    }

    await project.scenes.load();
    final pending = project.scenes
        .where((s) => s.status == 'pending' || s.status == 'failed')
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (pending.isEmpty) return;

    AppLogger.info(
        'Generating images for ${pending.length} scenes (concurrency=$maxConcurrent).',
        tag: 'SceneBuilder');

    // Semaphore via active future slots list
    final activeFutures = <Future<SceneModel?>>[];
    final controller = StreamController<SceneModel>();

    var idx = 0;

    Future<SceneModel?> generateOne(SceneModel scene) async {
      try {
        return await _generateSceneImage(scene);
      } catch (e, st) {
        AppLogger.error('Scene ${scene.index} image failed',
            tag: 'SceneBuilder', error: e, stackTrace: st);
        await _markSceneStatus(scene, 'failed', errorMsg: e.toString());
        return null;
      }
    }

    // Seed the initial batch
    while (idx < pending.length && activeFutures.length < maxConcurrent) {
      activeFutures.add(generateOne(pending[idx]));
      idx++;
    }

    while (activeFutures.isNotEmpty) {
      final completed = await Future.any(activeFutures.map(
        (f) => f.then((result) => (f, result)),
      ));

      activeFutures.remove(completed.$1);

      if (completed.$2 != null) {
        yield completed.$2!;
      }

      // Fill slot with next pending scene
      if (idx < pending.length) {
        activeFutures.add(generateOne(pending[idx]));
        idx++;
      }
    }
  }

  // ── Single Scene Generation ───────────────────────────────────────────────

  Future<SceneModel> generateSingleScene(String sceneId) async {
    final isar = await IsarService().db;
    final scene =
        await isar.sceneModels.filter().sceneIdEqualTo(sceneId).findFirst();
    if (scene == null) throw DatabaseFailure('Scene $sceneId not found.');
    return _generateSceneImage(scene);
  }

  Future<SceneModel> _generateSceneImage(SceneModel scene) async {
    await _markSceneStatus(scene, 'generating');
    AppLogger.info('Generating scene ${scene.index}: "${scene.generatedPrompt.substring(0, scene.generatedPrompt.length.clamp(0, 60))}..."', tag: 'SceneBuilder');

    final req = ImageGenRequest(
      prompt: scene.generatedPrompt,
      negativePrompt: 'blurry, low quality, text, watermark, deformed',
      width: 1280,
      height: 720,
    );

    final hasReplicate =
        await SecureStorageService.instance.hasKey(ApiProvider.replicate);

    String imagePath;
    if (hasReplicate) {
      final url = await _imgClient.generateViaReplicate(req);
      imagePath = await _imgClient.downloadAndSave(url, subfolder: 'scenes');
    } else {
      final base64 = await _imgClient.generateViaLocalSD(req);
      imagePath = await _imgClient.saveBase64Image(base64, subfolder: 'scenes');
    }

    // The video path re-uses the image path convention at this stage;
    // actual video generation goes through the Queue → Node pipeline.
    await _markSceneStatus(scene, 'completed', imagePath: imagePath);
    scene.videoPath = imagePath;
    scene.status = 'completed';
    return scene;
  }

  // ── Isar Helpers ──────────────────────────────────────────────────────────

  Future<void> _markSceneStatus(
    SceneModel scene,
    String status, {
    String? imagePath,
    String? errorMsg,
  }) async {
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      scene.status = status;
      if (imagePath != null) scene.videoPath = imagePath;
      if (errorMsg != null) scene.audioPath = errorMsg; // Temporary log slot
      await isar.sceneModels.put(scene);
    });
  }
}
