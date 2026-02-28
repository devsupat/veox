// lib/features/ai_voice_music/domain/tts_service.dart
//
// Orchestrates TTS generation:
//   - Single scene voice generation
//   - Bulk voice generation with progress stream
//   - Voice preview (play in-app via just_audio)
//   - Music generation delegation to MusicGenClient + download

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/features/ai_voice_music/data/elevenlabs_client.dart';
import 'package:veox_flutter/features/ai_voice_music/data/music_gen_client.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

class VoiceProgress {
  const VoiceProgress({
    required this.sceneIndex,
    required this.total,
    required this.audioPath,
  });
  final int sceneIndex;
  final int total;
  final String audioPath;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final _elClient = ElevenLabsClient.instance;
  final _musicClient = MusicGenClient.instance;
  final AudioPlayer _player = AudioPlayer();

  // ── Voices ────────────────────────────────────────────────────────────────

  /// Returns available voices from ElevenLabs.
  Future<List<VoiceInfo>> availableVoices() => _elClient.getVoices();

  // ── Single Scene ──────────────────────────────────────────────────────────

  /// Generates voice for a single scene and updates Isar.
  /// Returns the local audio path.
  Future<String> generateVoiceForScene(
    SceneModel scene, {
    required String voiceId,
  }) async {
    AppLogger.info(
        'TTS for scene ${scene.index}: "${scene.text.substring(0, scene.text.length.clamp(0, 60))}…"',
        tag: 'TTS');

    final bytes = await _generateBytes(scene.text, voiceId);
    final filename = 'scene_${scene.index}_${scene.sceneId}.mp3';
    final audioPath = await _elClient.saveAudio(bytes, filename: filename);

    // Persist audio path to Isar
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      scene.audioPath = audioPath;
      await isar.sceneModels.put(scene);
    });

    return audioPath;
  }

  // ── Bulk Generation ───────────────────────────────────────────────────────

  /// Generates voice for all scenes in a project.
  /// Yields VoiceProgress after each scene completes.
  Stream<VoiceProgress> generateBulkVoices(
    List<SceneModel> scenes, {
    required String voiceId,
  }) async* {
    if (scenes.isEmpty) return;
    final total = scenes.length;

    for (final scene in scenes) {
      try {
        final path = await generateVoiceForScene(scene, voiceId: voiceId);
        yield VoiceProgress(
            sceneIndex: scene.index, total: total, audioPath: path);
      } catch (e) {
        AppLogger.error('TTS failed for scene ${scene.index}',
            tag: 'TTS', error: e);
        // Yield partial progress; caller decides whether to stop or continue
        yield VoiceProgress(
            sceneIndex: scene.index, total: total, audioPath: '');
      }
    }
  }

  // ── Preview ───────────────────────────────────────────────────────────────

  /// Generates a sample preview and plays it in-app.
  Future<void> previewVoice(String text, String voiceId) async {
    final bytes = await _generateBytes(text, voiceId);
    final path = await _elClient.saveAudio(bytes, filename: 'preview.mp3');
    await _player.stop();
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> stopPreview() => _player.stop();

  // ── Music ─────────────────────────────────────────────────────────────────

  /// Generates background music and downloads it locally.
  /// Returns the local audio file path.
  Future<String> generateAndDownloadMusic(
    String prompt, {
    int durationSeconds = 30,
  }) async {
    final musicUrl = await _musicClient.generateMusic(
      prompt: prompt,
      durationSeconds: durationSeconds,
    );
    // Download music
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(musicUrl));
    final response = await request.close();
    final bytes = Uint8List.fromList(
        await response.reduce((a, b) => [...a, ...b]));
    httpClient.close();

    return _elClient.saveAudio(bytes, filename: 'music_${DateTime.now().millisecondsSinceEpoch}.mp3');
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<Uint8List> _generateBytes(String text, String voiceId) async {
    final hasElevenLabs =
        await SecureStorageService.instance.hasKey(ApiProvider.elevenlabs);
    if (!hasElevenLabs) {
      throw const AuthFailure(
          'No ElevenLabs key. Add it in Settings to use TTS.');
    }
    return _elClient.generateSpeech(text, voiceId);
  }
}
