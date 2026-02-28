// lib/features/story/presentation/character_studio_provider.dart
//
// Full Riverpod provider for the Character Studio tab:
//   - Text extraction (compute isolate)
//   - Image generation via Replicate / local SD
//   - Per-character generation progress
//   - Full CRUD: update, remove, save to Isar

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:veox_flutter/features/story/domain/services/character_service.dart';

// ── State ──────────────────────────────────────────────────────────────────

class CharacterStudioState {
  const CharacterStudioState({
    this.characters = const [],
    this.isDetecting = false,
    this.generatingIndex,
    this.error,
  });

  final List<CharacterModel> characters;
  final bool isDetecting;

  /// Index of the character currently having an image generated.
  final int? generatingIndex;
  final String? error;

  bool get hasCharacters => characters.isNotEmpty;

  CharacterStudioState copyWith({
    List<CharacterModel>? characters,
    bool? isDetecting,
    int? generatingIndex,
    String? error,
    bool clearError = false,
    bool clearGenerating = false,
  }) =>
      CharacterStudioState(
        characters: characters ?? this.characters,
        isDetecting: isDetecting ?? this.isDetecting,
        generatingIndex: clearGenerating ? null : (generatingIndex ?? this.generatingIndex),
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Provider ──────────────────────────────────────────────────────────────

final characterStudioProvider =
    StateNotifierProvider<CharacterStudioNotifier, CharacterStudioState>((ref) {
  return CharacterStudioNotifier();
});

// ── Notifier ──────────────────────────────────────────────────────────────

class CharacterStudioNotifier extends StateNotifier<CharacterStudioState> {
  CharacterStudioNotifier() : super(const CharacterStudioState());

  final _svc = CharacterService.instance;

  // ── Extraction ──────────────────────────────────────────────────────────

  Future<void> detectCharacters(String storyText) async {
    if (storyText.trim().isEmpty) return;
    state = state.copyWith(isDetecting: true, clearError: true);

    try {
      final chars = await _svc.extractCharacters(storyText);
      state = state.copyWith(characters: chars, isDetecting: false);
    } catch (e) {
      state = state.copyWith(
          isDetecting: false, error: 'Detection failed: $e');
    }
  }

  // ── Image Generation ────────────────────────────────────────────────────

  Future<void> generateImage(
    int index, {
    int? seed,
    String? referenceImagePath,
    String? style,
  }) async {
    if (index < 0 || index >= state.characters.length) return;

    state = state.copyWith(generatingIndex: index, clearError: true);

    try {
      final updated = await _svc.generateImage(
        state.characters[index],
        seed: seed,
        referenceImagePath: referenceImagePath,
        style: style,
      );
      final list = List<CharacterModel>.from(state.characters);
      list[index] = updated;
      state = state.copyWith(
          characters: list, clearGenerating: true);
    } catch (e) {
      state = state.copyWith(
          clearGenerating: true, error: 'Image gen failed: $e');
    }
  }

  Future<void> generateAllImages({String? style}) async {
    for (var i = 0; i < state.characters.length; i++) {
      if (!mounted) return;
      await generateImage(i, style: style);
    }
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  void addCharacter(CharacterModel character) {
    state = state.copyWith(characters: [...state.characters, character]);
  }

  void updateCharacter(int index, CharacterModel updated) {
    final list = List<CharacterModel>.from(state.characters);
    list[index] = updated;
    state = state.copyWith(characters: list);
  }

  Future<void> removeCharacter(int index) async {
    final char = state.characters[index];
    if (char.id > 0) await _svc.delete(char.id);
    final list = List<CharacterModel>.from(state.characters)..removeAt(index);
    state = state.copyWith(characters: list);
  }

  Future<void> saveAll() async {
    for (final char in state.characters) {
      await _svc.save(char);
    }
  }
}
