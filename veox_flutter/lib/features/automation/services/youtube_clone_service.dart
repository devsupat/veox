// lib/features/automation/services/youtube_clone_service.dart
//
// Orchestrates the full "YouTube Clone" pipeline:
//   1. Fetch video metadata
//   2. Download transcript (via yt-dlp)
//   3. Send transcript to LLM → generate visual prompts per segment
//   4. Parse and persist resulting PromptItems to Isar (TaskModel)
//   5. Yield progress updates via Stream

import 'dart:async';
import 'dart:convert';

import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/features/automation/services/ytdlp_client.dart';
import 'package:veox_flutter/features/story/data/llm_client.dart';

// ---------------------------------------------------------------------------
// Progress model
// ---------------------------------------------------------------------------

enum CloneStep { idle, fetchingInfo, fetchingTranscript, analyzing, saving, done, failed }

class CloneProgress {
  const CloneProgress({required this.step, this.message, this.prompts});
  final CloneStep step;
  final String? message;
  final List<String>? prompts;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class YouTubeCloneService {
  YouTubeCloneService._();
  static final YouTubeCloneService instance = YouTubeCloneService._();

//   ]
// }
//
// Rules:
// - 3 to 20 segments (don't over-segment short videos).
// - Each visual_prompt should be self-contained and evocative.
// - No text outside the JSON.
// ''';

  /// Returns a Stream<CloneProgress> that emits updates as each stage completes.
  Stream<CloneProgress> cloneVideo(String url) async* {
    AppLogger.info('Starting YouTube clone for: $url', tag: 'YTClone');

    yield const CloneProgress(
        step: CloneStep.fetchingInfo, message: 'Fetching video info…');

    VideoInfo info;
    try {
      info = await YtDlpClient.instance.getVideoInfo(url);
    } catch (e) {
      yield CloneProgress(
          step: CloneStep.failed,
          message: _friendlyError(e));
      return;
    }

    AppLogger.info('"${info.title}" by ${info.uploader}', tag: 'YTClone');
    yield CloneProgress(
        step: CloneStep.fetchingTranscript,
        message: 'Downloading transcript for "${info.title}"…');

    String transcript;
    try {
      transcript = await YtDlpClient.instance.getTranscript(url);
    } catch (e) {
      yield CloneProgress(step: CloneStep.failed, message: _friendlyError(e));
      return;
    }

    AppLogger.info('Transcript: ${transcript.length} chars', tag: 'YTClone');
    yield const CloneProgress(
        step: CloneStep.analyzing,
        message: 'Analysing script with AI…');

    List<String> prompts;
    try {
      prompts = await _analyzeTranscript(transcript);
    } catch (e) {
      yield CloneProgress(step: CloneStep.failed, message: _friendlyError(e));
      return;
    }

    yield const CloneProgress(step: CloneStep.saving, message: 'Saving prompts…');
    try {
      await _saveToIsar(prompts, sourceUrl: url, videoTitle: info.title);
    } catch (e) {
      AppLogger.warn('Failed to persist prompts: $e', tag: 'YTClone');
      // Non-fatal — still yield results
    }

    AppLogger.info('Clone complete: ${prompts.length} prompts', tag: 'YTClone');
    yield CloneProgress(step: CloneStep.done, prompts: prompts);
  }

  // ── LLM Analysis ──────────────────────────────────────────────────────────

  Future<List<String>> _analyzeTranscript(String transcript) async {
    // Trim very long transcripts to ~8000 chars to fit context window
    final trimmed = transcript.length > 8000
        ? transcript.substring(0, 8000)
        : transcript;

    final raw = await LLMClient.instance.enhancePrompt(
      'TASK: Break this transcript into visual scenes.\n\n---\n$trimmed',
      // Override with our custom system prompt by calling the internal method
    );

    // We need to use a custom system prompt — call the LLM directly
    return _parseLLMResponse(raw);
  }

  List<String> _parseLLMResponse(String raw) {
    var jsonStr = raw.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
          .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final segments = data['segments'] as List<dynamic>? ?? [];
      return segments
          .map((s) => (s as Map<String, dynamic>)['visual_prompt'] as String? ?? '')
          .where((p) => p.isNotEmpty)
          .toList();
    } catch (e) {
      // If JSON fails, try treating it as newline-separated prompts
      final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) return lines;
      throw ParseFailure('Could not parse LLM response: $e');
    }
  }

  // ── Isar Persistence ──────────────────────────────────────────────────────

  Future<void> _saveToIsar(
    List<String> prompts, {
    required String sourceUrl,
    required String videoTitle,
  }) async {
    final isar = await IsarService().db;
    final tasks = prompts.asMap().map((idx, prompt) {
      final task = TaskModel()
        ..taskId = '${videoTitle.hashCode}_$idx'
        ..type = 'video_gen'
        ..status = 'pending'
        ..priority = 5
        ..createdAt = DateTime.now()
        ..retryCount = 0
        ..payloadJson = jsonEncode({
          'prompt': prompt,
          'source': sourceUrl,
          'index': idx + 1,
          'platform': 'veo3',
        });
      return MapEntry(idx, task);
    }).values.toList();

    await isar.writeTxn(() async => isar.taskModels.putAll(tasks));
    AppLogger.info('Saved ${prompts.length} tasks to queue.', tag: 'YTClone');
  }

  // ── Error Mapping ─────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    if (e is MissingToolFailure) {
      return 'yt-dlp is not installed. Run: brew install yt-dlp';
    }
    if (e is FileSystemFailure) return e.message;
    if (e is AuthFailure) return e.message;
    return e.toString();
  }
}
