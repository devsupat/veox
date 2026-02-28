// lib/features/ai_voice_music/data/music_gen_client.dart
//
// MusicGen via Replicate API (meta/musicgen model).
// Generates background music from a text description.

import 'package:dio/dio.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/network/dio_client.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
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
    if (prompt.trim().isEmpty) throw const ValidationFailure('Music prompt cannot be empty.');

    AppLogger.info('Generating music: "$prompt" (${durationSeconds}s)', tag: 'Music');

    final client = await DioClient.instance.getClient(ApiProvider.replicate);
    final response = await client.post('/predictions', data: {
      'version': _model.split(':').last,
      'input': {
        'prompt': instrumental ? '$prompt, no vocals, instrumental' : prompt,
        'duration': durationSeconds.clamp(1, 60),
        'model_version': 'stereo-large',
        'output_format': 'mp3',
        'normalization_strategy': 'peak',
      },
    });

    final predictionId = (response.data as Map<String, dynamic>)['id'] as String;
    return _pollUntilDone(client, predictionId);
  }

  /// Crafts a music prompt from a video description + mood.
  Future<String> generateForVideo(
      String videoDescription, String mood) async {
    final autoPrompt =
        '$mood music, cinematic, background score for: $videoDescription';
    return generateMusic(prompt: autoPrompt, durationSeconds: 30);
  }

  Future<String> _pollUntilDone(Dio client, String predictionId) async {
    final deadline = DateTime.now().add(_timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollInterval);

      final response = await client.get('/predictions/$predictionId');
      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String;

      switch (status) {
        case 'succeeded':
          final output = data['output'];
          if (output is String) return output;
          if (output is List && output.isNotEmpty) return output.first as String;
          throw const ParseFailure('MusicGen returned empty output.');
        case 'failed':
        case 'canceled':
          throw NetworkFailure('MusicGen prediction $status: ${data['error']}');
      }
    }

    throw const NetworkFailure('MusicGen timed out after 5 minutes.');
  }
}
