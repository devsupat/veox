import 'package:flutter/foundation.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:uuid/uuid.dart';

class SceneService {
  Future<List<SceneModel>> parseStoryToScenes(
    String storyText,
    List<CharacterModel> characters,
  ) async {
    return await compute(_processScenes, {
      'text': storyText,
      'chars': characters,
    });
  }

  static List<SceneModel> _processScenes(Map<String, dynamic> args) {
    final text = args['text'] as String;
    final characters = args['chars'] as List<CharacterModel>;
    final uuid = Uuid();
    final List<SceneModel> scenes = [];

    // 1. Split by paragraphs or double newlines
    // A scene is typically a block of action.
    final blocks = text.split(RegExp(r'\n\s*\n'));

    int index = 1;
    for (var block in blocks) {
      block = block.trim();
      if (block.isEmpty) continue;

      // 2. Identify characters in this scene
      final presentChars = characters
          .where((c) => block.contains(c.name))
          .toList();

      // 3. Construct Prompt
      // "Cinematic shot of [Char Desc], action..."
      String prompt = block;

      // Enhance prompt with character descriptions (simple replacement for now)
      // In production, we'd use LLM to rewrite this.
      for (final char in presentChars) {
        if (char.description != null) {
          // Naive injection: Append character description
          // prompt += ", ${char.name} is ${char.description}";
          // Better: Prepend visual style
        }
      }

      scenes.add(
        SceneModel()
          ..sceneId = uuid.v4()
          ..index = index++
          ..text = block
          ..generatedPrompt = prompt
          ..status = 'pending',
      );
    }

    return scenes;
  }
}
