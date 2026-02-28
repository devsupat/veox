// lib/features/ai_voice_music/presentation/voice_music_provider.dart
//
// Riverpod layer for AI Voice & Music tab.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/features/ai_voice_music/data/elevenlabs_client.dart';
import 'package:veox_flutter/features/ai_voice_music/domain/tts_service.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';

// ── Voice List ────────────────────────────────────────────────────────────

final voicesProvider = FutureProvider<List<VoiceInfo>>((ref) {
  return TtsService.instance.availableVoices();
});

// ── State ──────────────────────────────────────────────────────────────────

class VoiceMusicState {
  const VoiceMusicState({
    this.selectedVoiceId = 'EXAVITQu4vr4xnSDxMaL', // ElevenLabs "Bella"
    this.isGenerating = false,
    this.generatingSceneIndex,
    this.completedScenes = const [],
    this.musicPath,
    this.isMusicGenerating = false,
    this.error,
  });

  final String selectedVoiceId;
  final bool isGenerating;
  final int? generatingSceneIndex;
  final List<String> completedScenes; // local audio paths
  final String? musicPath;
  final bool isMusicGenerating;
  final String? error;

  VoiceMusicState copyWith({
    String? selectedVoiceId,
    bool? isGenerating,
    int? generatingSceneIndex,
    List<String>? completedScenes,
    String? musicPath,
    bool? isMusicGenerating,
    String? error,
    bool clearError = false,
  }) =>
      VoiceMusicState(
        selectedVoiceId: selectedVoiceId ?? this.selectedVoiceId,
        isGenerating: isGenerating ?? this.isGenerating,
        generatingSceneIndex: generatingSceneIndex ?? this.generatingSceneIndex,
        completedScenes: completedScenes ?? this.completedScenes,
        musicPath: musicPath ?? this.musicPath,
        isMusicGenerating: isMusicGenerating ?? this.isMusicGenerating,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────

final voiceMusicNotifierProvider =
    StateNotifierProvider<VoiceMusicNotifier, VoiceMusicState>((ref) {
  return VoiceMusicNotifier();
});

class VoiceMusicNotifier extends StateNotifier<VoiceMusicState> {
  VoiceMusicNotifier() : super(const VoiceMusicState());

  final _svc = TtsService.instance;
  StreamSubscription<VoiceProgress>? _sub;

  void selectVoice(String voiceId) =>
      state = state.copyWith(selectedVoiceId: voiceId);

  /// Generates voice for all scenes in [projectId].
  Future<void> generateBulk(String projectId) async {
    final isar = await IsarService().db;
    final project = await isar.projectModels
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
    if (project == null) return;

    await project.scenes.load();
    final scenes = project.scenes.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    state = state.copyWith(
        isGenerating: true, completedScenes: [], clearError: true);

    _sub = _svc
        .generateBulkVoices(scenes, voiceId: state.selectedVoiceId)
        .listen(
      (progress) {
        if (progress.audioPath.isNotEmpty) {
          state = state.copyWith(
            generatingSceneIndex: progress.sceneIndex,
            completedScenes: [...state.completedScenes, progress.audioPath],
          );
        }
      },
      onDone: () => state = state.copyWith(isGenerating: false),
      onError: (Object e) =>
          state = state.copyWith(isGenerating: false, error: e.toString()),
    );
  }

  /// Generates background music and downloads it.
  Future<void> generateMusic(String prompt, {int durationSeconds = 30}) async {
    state = state.copyWith(isMusicGenerating: true, clearError: true);
    try {
      final path = await _svc.generateAndDownloadMusic(
        prompt,
        durationSeconds: durationSeconds,
      );
      state = state.copyWith(isMusicGenerating: false, musicPath: path);
    } catch (e) {
      state = state.copyWith(isMusicGenerating: false, error: e.toString());
    }
  }

  Future<void> previewVoice(String text) async {
    if (text.trim().isEmpty) return;
    await _svc.previewVoice(text, state.selectedVoiceId);
  }

  Future<void> stopPreview() => _svc.stopPreview();

  void cancel() => _sub?.cancel();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
