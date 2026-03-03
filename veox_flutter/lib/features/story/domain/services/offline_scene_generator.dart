import 'dart:convert';
import 'package:veox_flutter/features/story/domain/services/character_service.dart';
import 'package:veox_flutter/features/story/data/llm_client.dart'; // for StoryParseResult

class OfflineSceneGenerator {
  OfflineSceneGenerator._();

  static Future<StoryParseResult> generateDeterministicScenes(
    String storyText,
    int promptCount,
  ) async {
    // 1. Extract characters using existing heuristic
    final characters = await CharacterService.instance.extractCharacters(
      storyText,
    );

    // 2. Split story into fragments
    var blocks = storyText
        .split(RegExp(r'\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.length > 10)
        .toList();

    // Fallback if no empty lines
    if (blocks.length < 2) {
      blocks = storyText
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final parsedScenes = <ParsedScene>[];

    // Distribute promptCount across the blocks evenly
    for (int i = 0; i < promptCount; i++) {
      final blockIndex = (i * blocks.length) ~/ promptCount;
      final baseText = blocks.isEmpty
          ? "A cinematic scene"
          : blocks[blockIndex];

      // Find characters present in this block
      final presentChars = characters
          .where((c) => baseText.contains(c.name))
          .map((c) => c.name)
          .toList();

      final prompt = 'Cinematic shot, highly detailed. $baseText';

      parsedScenes.add(
        ParsedScene(
          sceneNumber: i + 1,
          description: baseText,
          visualPrompt: prompt,
          charactersInScene: presentChars,
        ),
      );
    }

    final parsedChars = characters
        .map(
          (c) => ParsedCharacter(
            name: c.name,
            description: c.description ?? 'A character',
            appearance: 'cinematic lighting, detailed',
          ),
        )
        .toList();

    return StoryParseResult(characters: parsedChars, scenes: parsedScenes);
  }

  static String buildScenesJson(StoryParseResult result) {
    final map = {
      "character_reference": result.characters
          .map(
            (c) => {
              "name": c.name,
              "description": "${c.description} ${c.appearance}".trim(),
            },
          )
          .toList(),
      "scenes": result.scenes
          .map(
            (s) => {
              "scene_number": s.sceneNumber,
              "prompt": s.visualPrompt,
              "characters_in_scene": s.charactersInScene,
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
