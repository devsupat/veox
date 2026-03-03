// lib/features/story/data/llm_client.dart
//
// LLM client supporting OpenAI GPT-4o (default) and Anthropic Claude as fallback.
// Purpose:
//   1. Parse a story text into structured JSON scenes (parseStoryToScenes)
//   2. Enhance a simple prompt with cinematic adjectives (enhancePrompt)
//
// Provider selection:
//   - Checks OpenAI key first, Anthropic second.
//   - Both are tried if available; first successful wins.

import 'dart:convert';

import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/utils/logger.dart';

// ---------------------------------------------------------------------------
// Output types
// ---------------------------------------------------------------------------

class ParsedScene {
  const ParsedScene({
    required this.sceneNumber,
    required this.description,
    required this.visualPrompt,
    this.cameraAngle = 'medium shot',
    this.lighting = 'natural',
    this.mood = 'neutral',
    this.charactersInScene = const [],
  });

  final int sceneNumber;
  final String description;
  final String visualPrompt;
  final String cameraAngle;
  final String lighting;
  final String mood;
  final List<String> charactersInScene;

  factory ParsedScene.fromJson(Map<String, dynamic> json, int fallbackIndex) {
    return ParsedScene(
      sceneNumber: (json['scene_number'] as int?) ?? fallbackIndex,
      description: json['description'] as String? ?? '',
      visualPrompt: json['visual_prompt'] as String? ?? '',
      cameraAngle: json['camera_angle'] as String? ?? 'medium shot',
      lighting: json['lighting'] as String? ?? 'natural',
      mood: json['mood'] as String? ?? 'neutral',
      charactersInScene:
          (json['characters_in_scene'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class ParsedCharacter {
  const ParsedCharacter({
    required this.name,
    this.description = '',
    this.appearance = '',
  });

  final String name;
  final String description;
  final String appearance;

  factory ParsedCharacter.fromJson(Map<String, dynamic> json) =>
      ParsedCharacter(
        name: json['name'] as String? ?? 'Unknown',
        description: json['description'] as String? ?? '',
        appearance: json['appearance'] as String? ?? '',
      );
}

class StoryParseResult {
  const StoryParseResult({required this.characters, required this.scenes});
  final List<ParsedCharacter> characters;
  final List<ParsedScene> scenes;
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

class LLMClient {
  LLMClient._();
  static final LLMClient instance = LLMClient._();

  static const _systemPrompt = '''
You are a visual storytelling expert and cinematographer's assistant.
Parse the given story into individual scenes suitable for AI video/image generation.

Return ONLY valid JSON with this exact structure:
{
  "characters": [
    { "name": "string", "description": "string", "appearance": "string" }
  ],
  "scenes": [
    {
      "scene_number": 1,
      "description": "What happens in this scene (1-2 sentences)",
      "visual_prompt": "Highly detailed cinematic image generation prompt, include style, lighting, composition, camera angle",
      "camera_angle": "wide shot|close-up|medium shot|over-the-shoulder|bird's eye|etc.",
      "lighting": "golden hour|harsh sunlight|neon|candlelight|etc.",
      "mood": "tense|romantic|mysterious|joyful|etc.",
      "characters_in_scene": ["character_name_1"]
    }
  ]
}

Rules:
- Every visual_prompt must be self-contained and evocative — no pronouns, always name subjects.
- Minimum 1 scene, maximum 50 scenes.
- Do NOT add any text outside the JSON.
''';

  // ── Story Parsing ─────────────────────────────────────────────────────────

  Future<StoryParseResult> parseStoryToScenes(String storyText) async {
    if (storyText.trim().isEmpty) {
      throw const ValidationFailure('Story text cannot be empty.');
    }

    AppLogger.info('Parsing story (${storyText.length} chars)…', tag: 'LLM');
    final rawJson = await _callLLM(storyText);
    return _parseResult(rawJson);
  }

  // ── Prompt Enhancement ────────────────────────────────────────────────────

  Future<String> enhancePrompt(String basicPrompt) async {
    const enhanceSystem = '''
You are a text-to-image prompt expert. 
Given a simple scene description, rewrite it as a highly detailed image generation prompt.
Include: lighting, mood, camera angle, colour palette, style (e.g., "cinematic, 8K, shot on ARRI").
Return ONLY the enhanced prompt with no explanation.
''';

    final text = await _callLLM(basicPrompt, systemOverride: enhanceSystem);
    return text.trim();
  }

  // ── Provider routing ──────────────────────────────────────────────────────

  Future<String> _callLLM(String userMessage, {String? systemOverride}) async {
    // Stub implementation for offline VEOX
    AppLogger.info('VEOX: Mocking LLM response (Offline Mode)', tag: 'LLM');
    await Future<void>.delayed(const Duration(seconds: 1));

    final isEnhance = systemOverride?.contains('enhance') ?? false;

    if (isEnhance) {
      return "Cinematic, highly detailed, 8k resolution: $userMessage";
    }

    return '''
{
  "characters": [
    { "name": "Hero", "description": "A brave protagonist", "appearance": "Wearing armor" }
  ],
  "scenes": [
    {
      "scene_number": 1,
      "description": "Opening scene setup",
      "visual_prompt": "Cinematic shot of a scene",
      "camera_angle": "wide shot",
      "lighting": "natural",
      "mood": "neutral",
      "characters_in_scene": ["Hero"]
    }
  ]
}
''';
  }

  // ── JSON Parsing ──────────────────────────────────────────────────────────

  StoryParseResult _parseResult(String rawText) {
    try {
      // Strip potential markdown code fence wrapping
      var jsonStr = rawText.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr
            .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final chars = (data['characters'] as List<dynamic>? ?? [])
          .map((c) => ParsedCharacter.fromJson(c as Map<String, dynamic>))
          .toList();

      final scenes = (data['scenes'] as List<dynamic>? ?? [])
          .asMap()
          .map(
            (i, s) => MapEntry(
              i,
              ParsedScene.fromJson(s as Map<String, dynamic>, i + 1),
            ),
          )
          .values
          .toList();

      if (scenes.isEmpty) {
        throw const ParseFailure(
          'LLM returned zero scenes. Check your story text.',
        );
      }

      AppLogger.info(
        'Parsed ${chars.length} character(s) and ${scenes.length} scene(s).',
        tag: 'LLM',
      );
      return StoryParseResult(characters: chars, scenes: scenes);
    } catch (e) {
      if (e is ParseFailure || e is ValidationFailure) rethrow;
      throw ParseFailure(
        'Failed to parse LLM JSON response: $e\n\nRaw: $rawText',
      );
    }
  }
}
