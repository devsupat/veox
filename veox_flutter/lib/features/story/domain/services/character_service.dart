// lib/features/story/domain/services/character_service.dart
//
// Full character management service:
//   - Extract candidate names via regex heuristic (fast, offline)
//   - Generate images via Replicate or local SD WebUI
//   - Persist characters to Isar with local image paths
//   - Delete characters (removes image file + DB record)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/features/story/data/image_generation_client.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';

/// In-process name extraction result (used in Isolate.
typedef _ExtractResult = List<String>;

class CharacterService {
  CharacterService._();
  static final CharacterService instance = CharacterService._();

  final _imgClient = ImageGenerationClient.instance;

  // ── Name Extraction ────────────────────────────────────────────────────────

  /// Extracts probable character names from [storyText] using regex heuristics.
  /// Runs in a compute isolate to keep the UI smooth.
  Future<List<CharacterModel>> extractCharacters(String storyText) async {
    final names = await compute(_extractNames, storyText);
    return names.map((name) {
      return CharacterModel()
        ..characterId = const Uuid().v4()
        ..name = name
        ..description = 'Auto-detected from story.';
    }).toList();
  }

  /// Regex-based name extractor — runs in isolate (no closures).
  static _ExtractResult _extractNames(String text) {
    const stopWords = {
      'The', 'A', 'An', 'This', 'That', 'Then', 'When', 'Where', 'Why',
      'How', 'But', 'And', 'Or', 'If', 'So', 'Because', 'While', 'After',
      'Before', 'Once', 'Suddenly', 'Finally', 'Next', 'Later', 'Meanwhile',
      'However', 'Although', 'Even', 'Just', 'Only', 'Today', 'Yesterday',
      'Tomorrow', 'Here', 'There', 'It', 'He', 'She', 'They', 'We', 'You',
      'I', 'His', 'Her', 'Their',
    };

    final nameRegex = RegExp(r'\b[A-Z][a-z]{2,}(?:\s[A-Z][a-z]+)?\b');
    final frequency = <String, int>{};

    for (final match in nameRegex.allMatches(text)) {
      final word = match.group(0)!;
      if (!stopWords.contains(word)) {
        frequency[word] = (frequency[word] ?? 0) + 1;
      }
    }

    // Keep names appearing more than once (or any name in short texts).
    final minCount = text.length < 500 ? 1 : 2;
    final result = frequency.entries
        .where((e) => e.value >= minCount)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));

    return result.take(20).toList(); // Cap at 20 unique characters
  }

  // ── Generate Character Image ───────────────────────────────────────────────

  /// Generates an image for [character] using the configured provider
  /// (Replicate when API key exists, local SD as fallback).
  /// Saves the image to disk and updates the character in Isar.
  Future<CharacterModel> generateImage(
    CharacterModel character, {
    int? seed,
    String? referenceImagePath,
    String? style,
  }) async {
    final prompt = _buildPrompt(character, style: style);
    final negativePrompt =
        'blurry, deformed, ugly, low quality, text, watermark, logo';

    String? referenceBase64;
    if (referenceImagePath != null) {
      final file = File(referenceImagePath);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        referenceBase64 = base64Encode(bytes);
      }
    }

    final req = ImageGenRequest(
      prompt: prompt,
      negativePrompt: negativePrompt,
      seed: seed,
      width: 768,
      height: 1024,
      referenceImageBase64: referenceBase64,
    );

    AppLogger.info('Generating image for "${character.name}"', tag: 'CharSvc');

    String imagePath;
    final hasReplicate =
        await SecureStorageService.instance.hasKey(ApiProvider.replicate);

    if (hasReplicate) {
      final url = await _imgClient.generateViaReplicate(req);
      imagePath = await _imgClient.downloadAndSave(url, subfolder: 'characters');
    } else {
      // Fallback to local SD WebUI
      final base64 = await _imgClient.generateViaLocalSD(req);
      imagePath = await _imgClient.saveBase64Image(base64, subfolder: 'characters');
    }

    // Persist to Isar
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      character.baseImagePath = imagePath;
      await isar.characterModels.put(character);
    });

    AppLogger.info('Character "${character.name}" image saved: $imagePath',
        tag: 'CharSvc');
    return character;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<CharacterModel>> getAll(int isarProjectId) async {
    final isar = await IsarService().db;
    final project =
        await isar.projectModels.filter().idEqualTo(isarProjectId).findFirst();
    if (project == null) return [];
    await project.characters.load();
    return project.characters.toList();
  }

  Future<void> save(CharacterModel character) async {
    final isar = await IsarService().db;
    await isar.writeTxn(() async => isar.characterModels.put(character));
  }

  Future<void> delete(int isarId) async {
    final isar = await IsarService().db;
    final character = await isar.characterModels.get(isarId);
    if (character?.baseImagePath != null) {
      final file = File(character!.baseImagePath!);
      if (file.existsSync()) file.deleteSync();
    }
    await isar.writeTxn(() async => isar.characterModels.delete(isarId));
    AppLogger.info('Deleted character $isarId', tag: 'CharSvc');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _buildPrompt(CharacterModel character, {String? style}) {
    final desc = character.description?.isNotEmpty == true
        ? character.description!
        : 'a person';
    final styleClause =
        style != null && style.isNotEmpty ? ', $style style' : '';
    return 'Portrait of ${character.name}, $desc$styleClause, '
        'highly detailed, cinematic lighting, 8K, sharp focus';
  }
}
