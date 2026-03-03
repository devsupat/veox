// lib/features/ai_voice_music/data/music_gen_client.dart
//
// MusicGen via Replicate API (meta/musicgen model).
// Generates background music from a text description.

import 'package:veox_flutter/core/utils/logger.dart';

class MusicGenClient {
  MusicGenClient._();
  static final MusicGenClient instance = MusicGenClient._();

  // Replicate model version for MusicGen
  static const _model =
      'meta/musicgen:671ac645ce5e552cc63a54a2bbff63fcf798043055d2dac5fc9e36a837eedcfb';
  static const _pollInterval = Duration(seconds: 3);
  static const _timeout = Duration(minutes: 5);

  /// Generates music and returns the audio URL.
  ///
  /// [prompt] describes the desired music (genre, mood, instruments).
  /// [durationSeconds] is the output length (8–30 seconds recommended).
  /// [instrumental] if true, removes vocals.
  Future<String> generateMusic({
    required String prompt,
    int durationSeconds = 30,
    bool instrumental = true,
  }) async {
    AppLogger.info('VEOX: Mocking MusicGen (Offline Mode)', tag: 'Music');
    await Future<void>.delayed(const Duration(seconds: 2));
    return 'https://freepd.com/music/A%20Very%20Brady%20Special.mp3'; // Dummy valid MP3
  }

  /// Crafts a music prompt from a video description + mood.
  Future<String> generateForVideo(String videoDescription, String mood) async {
    final autoPrompt =
        '$mood music, cinematic, background score for: $videoDescription';
    return generateMusic(prompt: autoPrompt, durationSeconds: 30);
  }
}
