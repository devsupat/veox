// lib/features/story/data/image_generation_client.dart
//
// API client for image generation via:
//   1. Replicate (cloud, handles SDXL, Flux, etc.)
//   2. Local Stable Diffusion WebUI (localhost SD)
//
// Design: This client is stateless — all configuration comes from SecureStorage
// at call time. No long-lived state means rotation of API keys takes effect
// immediately without any restart.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/network/dio_client.dart';
import 'package:veox_flutter/core/storage/secure_storage_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';

// ---------------------------------------------------------------------------
// Input / Output types
// ---------------------------------------------------------------------------

class ImageGenRequest {
  const ImageGenRequest({
    required this.prompt,
    this.negativePrompt,
    this.seed,
    this.width = 1024,
    this.height = 1024,
    this.steps = 30,
    this.cfgScale = 7.5,
    this.referenceImageBase64,
  });

  final String prompt;
  final String? negativePrompt;
  final int? seed;
  final int width;
  final int height;
  final int steps;
  final double cfgScale;
  final String? referenceImageBase64;
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

class ImageGenerationClient {
  ImageGenerationClient._();
  static final ImageGenerationClient instance = ImageGenerationClient._();

  static const _replicateModel =
      'stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b';
  static const _pollInterval = Duration(seconds: 2);
  static const _maxPollDuration = Duration(minutes: 10);

  // ── Replicate ──────────────────────────────────────────────────────────────

  /// Submits a prediction to Replicate, polls until complete, and returns
  /// the image URL.
  Future<String> generateViaReplicate(ImageGenRequest req) async {
    final client = await DioClient.instance.getClient(ApiProvider.replicate);

    // Step 1: create prediction
    final createResponse = await client.post('/predictions', data: {
      'version': _replicateModel,
      'input': {
        'prompt': req.prompt,
        if (req.negativePrompt != null) 'negative_prompt': req.negativePrompt,
        if (req.seed != null) 'seed': req.seed,
        'width': req.width,
        'height': req.height,
        'num_inference_steps': req.steps,
        'guidance_scale': req.cfgScale,
        if (req.referenceImageBase64 != null)
          'image': 'data:image/png;base64,${req.referenceImageBase64}',
      },
    });

    final predictionId = _extractId(createResponse.data);
    AppLogger.info('Replicate prediction $predictionId created.', tag: 'ImageGen');

    // Step 2: poll
    return _pollReplicatePrediction(client, predictionId);
  }

  Future<String> _pollReplicatePrediction(Dio client, String predictionId) async {
    final deadline = DateTime.now().add(_maxPollDuration);

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollInterval);

      final response = await client.get('/predictions/$predictionId');
      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String;

      AppLogger.debug('Replicate [$predictionId] status: $status', tag: 'ImageGen');

      switch (status) {
        case 'succeeded':
          final output = data['output'];
          if (output is List && output.isNotEmpty) {
            return output.first as String;
          }
          throw const ParseFailure('Replicate returned empty output list.');

        case 'failed':
        case 'canceled':
          final errorMsg = data['error'] ?? 'Prediction $status.';
          throw NetworkFailure('Replicate prediction $status: $errorMsg');
      }
      // status is 'starting' or 'processing' — keep polling
    }

    throw const NetworkFailure(
        'Replicate prediction timed out after 10 minutes.');
  }

  // ── Local Stable Diffusion WebUI ──────────────────────────────────────────

  /// Sends a txt2img request to a locally running SD WebUI instance.
  Future<String> generateViaLocalSD(ImageGenRequest req,
      {String baseUrl = 'http://localhost:7860'}) async {
    final plain = DioClient.instance.plain;

    try {
      final response = await plain.post(
        '$baseUrl/sdapi/v1/txt2img',
        data: {
          'prompt': req.prompt,
          if (req.negativePrompt != null) 'negative_prompt': req.negativePrompt,
          'seed': req.seed ?? -1,
          'width': req.width,
          'height': req.height,
          'steps': req.steps,
          'cfg_scale': req.cfgScale,
          'sampler_name': 'DPM++ 2M Karras',
        },
      );

      final images = (response.data as Map<String, dynamic>)['images'] as List;
      if (images.isEmpty) {
        throw const ParseFailure('SD WebUI returned zero images.');
      }
      return images.first as String; // Base64 PNG
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure(
            'SD WebUI not running. Start it with: ./webui.sh');
      }
      rethrow;
    }
  }

  // ── File Download ─────────────────────────────────────────────────────────

  /// Downloads an image from [url] and saves it to the VEOX characters folder.
  /// Returns the local file path.
  Future<String> downloadAndSave(String url, {String? subfolder}) async {
    final plain = DioClient.instance.plain;
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
        '${docsDir.path}/VEOX/${subfolder ?? 'images'}');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final filename = '${const Uuid().v4()}.png';
    final filePath = '${dir.path}/$filename';

    AppLogger.debug('Downloading image → $filePath', tag: 'ImageGen');

    final response = await plain.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    File(filePath).writeAsBytesSync(Uint8List.fromList(response.data!));
    AppLogger.info('Image saved: $filePath', tag: 'ImageGen');
    return filePath;
  }

  /// Saves a base64-encoded PNG to disk. Used for SD WebUI results.
  Future<String> saveBase64Image(String base64Data,
      {String? subfolder}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/VEOX/${subfolder ?? 'images'}');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Strip data URI prefix if present
    final cleanBase64 = base64Data.contains(',')
        ? base64Data.split(',').last
        : base64Data;

    final bytes = base64Decode(cleanBase64);
    final filename = '${const Uuid().v4()}.png';
    final filePath = '${dir.path}/$filename';
    File(filePath).writeAsBytesSync(bytes);
    return filePath;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _extractId(dynamic data) {
    if (data is Map<String, dynamic> && data['id'] is String) {
      return data['id'] as String;
    }
    throw const ParseFailure('Replicate response missing prediction ID.');
  }
}
