import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:veox_flutter/features/story/domain/services/character_service.dart';

final characterStudioProvider = StateNotifierProvider<CharacterStudioNotifier, CharacterStudioState>((ref) {
  return CharacterStudioNotifier(ref);
});

class CharacterStudioState {
  final List<CharacterModel> detectedCharacters;
  final bool isDetecting;
  final String? error;
  
  CharacterStudioState({
    this.detectedCharacters = const [],
    this.isDetecting = false,
    this.error,
  });

  CharacterStudioState copyWith({
    List<CharacterModel>? detectedCharacters,
    bool? isDetecting,
    String? error,
  }) {
    return CharacterStudioState(
      detectedCharacters: detectedCharacters ?? this.detectedCharacters,
      isDetecting: isDetecting ?? this.isDetecting,
      error: error,
    );
  }
}

class CharacterStudioNotifier extends StateNotifier<CharacterStudioState> {
  final Ref _ref;
  final CharacterService _characterService;

  CharacterStudioNotifier(this._ref) 
      : _characterService = CharacterService(),
        super(CharacterStudioState());

  Future<void> detectCharacters(String storyText) async {
    if (storyText.trim().isEmpty) return;

    state = state.copyWith(isDetecting: true, error: null);

    try {
      // Run heavy regex/logic in Isolate via Service
      final characters = await _characterService.extractCharacters(storyText);
      state = state.copyWith(
        detectedCharacters: characters,
        isDetecting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isDetecting: false,
        error: "Failed to detect characters: ${e.toString()}",
      );
    }
  }

  void updateCharacter(int index, CharacterModel updatedChar) {
    final newList = List<CharacterModel>.from(state.detectedCharacters);
    newList[index] = updatedChar;
    state = state.copyWith(detectedCharacters: newList);
  }
  
  void removeCharacter(int index) {
    final newList = List<CharacterModel>.from(state.detectedCharacters);
    newList.removeAt(index);
    state = state.copyWith(detectedCharacters: newList);
  }
}
