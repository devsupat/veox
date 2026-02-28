// lib/features/ai_voice_music/data/elevenlabs_client.dart
//
// ElevenLabs API client for:
//   - Listing available voices
//   - Generating speech (returns MP3 bytes)
//   - Saving audio to disk

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/network/dio_client.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:dio/dio.dart';

class VoiceInfo {
  const VoiceInfo({
    required this.voiceId,
    required this.name,
    this.previewUrl,
    this.category,
  });
  final String voiceId;
  final String name;
  final String? previewUrl;
  final String? category;

  factory VoiceInfo.fromJson(Map<String, dynamic> json) => VoiceInfo(
        voiceId: json['voice_id'] as String,
        name: json['name'] as String,
        previewUrl: json['preview_url'] as String?,
        category: json['category'] as String?,
      );
}

class ElevenLabsClient {
  ElevenLabsClient._();
  static final ElevenLabsClient instance = ElevenLabsClient._();

  // ── Voices ────────────────────────────────────────────────────────────────

  Future<List<VoiceInfo>> getVoices() async {
    final client = await DioClient.instance.getClient(ApiProvider.elevenlabs);
    final response = await client.get('/voices');
    final voices = (response.data['voices'] as List<dynamic>)
        .map((v) => VoiceInfo.fromJson(v as Map<String, dynamic>))
        .toList();
    AppLogger.info('Loaded ${voices.length} ElevenLabs voices.', tag: 'TTS');
    return voices;
  }

  // ── Generate Speech ───────────────────────────────────────────────────────

  /// Returns MP3 bytes for the given [text] using [voiceId].
  Future<Uint8List> generateSpeech(
    String text,
    String voiceId, {
    double stability = 0.5,
    double similarityBoost = 0.75,
    bool useSpeakerBoost = true,
  }) async {
    if (text.trim().isEmpty) throw const ValidationFailure('Text cannot be empty.');
    if (text.length > 5000) {
      throw const ValidationFailure(
          'Text exceeds ElevenLabs limit of 5000 characters.');
    }

    final client = await DioClient.instance.getClient(ApiProvider.elevenlabs);
    final response = await client.post<List<int>>(
      '/text-to-speech/$voiceId',
      data: {
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': stability,
          'similarity_boost': similarityBoost,
          'use_speaker_boost': useSpeakerBoost,
        },
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'audio/mpeg'},
      ),
    );

    AppLogger.debug('ElevenLabs speech: ${response.data!.length} bytes', tag: 'TTS');
    return Uint8List.fromList(response.data!);
  }

  // ── Save Audio ────────────────────────────────────────────────────────────

  /// Saves [bytes] as an MP3 in the VEOX audio folder.
  /// Returns the local file path.
  Future<String> saveAudio(Uint8List bytes, {String? filename}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/VEOX/audio');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final name = filename ?? '${const Uuid().v4()}.mp3';
    final path = '${dir.path}/$name';
    File(path).writeAsBytesSync(bytes);
    AppLogger.info('Audio saved: $path', tag: 'TTS');
    return path;
  }
}
