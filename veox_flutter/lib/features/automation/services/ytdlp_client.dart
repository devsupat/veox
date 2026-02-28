// lib/features/automation/services/ytdlp_client.dart
//
// Wraps the yt-dlp command-line tool for:
//   - Checking if yt-dlp is installed
//   - Fetching video metadata (title, duration, thumbnail)
//   - Downloading subtitles / auto-captions and converting to plain text

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/process/process_runner.dart';
import 'package:veox_flutter/core/utils/logger.dart';

class VideoInfo {
  const VideoInfo({
    required this.title,
    required this.uploader,
    required this.durationSeconds,
    this.thumbnailUrl,
    this.description,
  });

  final String title;
  final String uploader;
  final int durationSeconds;
  final String? thumbnailUrl;
  final String? description;
}

class YtDlpClient {
  YtDlpClient._();
  static final YtDlpClient instance = YtDlpClient._();

  static const _exe = 'yt-dlp';

  // ── Availability ──────────────────────────────────────────────────────────

  Future<bool> isInstalled() => ProcessRunner.instance.isInstalled(_exe);

  Future<void> assertInstalled() async {
    if (!await isInstalled()) {
      throw const MissingToolFailure('yt-dlp');
    }
  }

  // ── Video Info ────────────────────────────────────────────────────────────

  Future<VideoInfo> getVideoInfo(String url) async {
    await assertInstalled();
    _validateUrl(url);

    final result = await ProcessRunner.instance.run(_exe, [
      '--dump-json',
      '--no-playlist',
      url,
    ]);

    try {
      final data = jsonDecode(result.stdout) as Map<String, dynamic>;
      return VideoInfo(
        title: data['title'] as String? ?? 'Unknown',
        uploader: data['uploader'] as String? ?? 'Unknown',
        durationSeconds: (data['duration'] as num?)?.toInt() ?? 0,
        thumbnailUrl: data['thumbnail'] as String?,
        description: data['description'] as String?,
      );
    } catch (e) {
      throw ParseFailure('Could not parse yt-dlp video info: $e');
    }
  }

  // ── Transcript ────────────────────────────────────────────────────────────

  /// Downloads and returns the transcript as plain text.
  /// Tries: manual subtitles → auto-generated subtitles → no transcript.
  Future<String> getTranscript(String url) async {
    await assertInstalled();
    _validateUrl(url);

    final tmpDir = await getTemporaryDirectory();
    final outputBase = '${tmpDir.path}/veox_transcript_${const Uuid().v4()}';

    // Prefer manual English subs; fallback to auto-captions.
    await ProcessRunner.instance.run(_exe, [
      '--write-subs',
      '--write-auto-subs',
      '--sub-lang', 'en',
      '--skip-download',
      '--sub-format', 'vtt',
      '--convert-subs', 'vtt',
      '--output', outputBase,
      '--no-playlist',
      url,
    ], throwOnError: false);

    // yt-dlp appends a suffix like `.en.vtt`
    final dir = Directory(tmpDir.path);
    final vttFile = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.startsWith(outputBase) && f.path.endsWith('.vtt'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (vttFile.isEmpty) {
      throw const FileSystemFailure(
          'No transcript available for this video. '
          'Try a video with manual subtitles.');
    }

    final vttText = vttFile.first.readAsStringSync();
    // Clean up temp files
    for (final f in vttFile) {
      f.deleteSync();
    }

    return _parseVtt(vttText);
  }

  // ── VTT → Plain Text ──────────────────────────────────────────────────────

  /// Strips VTT timestamps and metadata, returns clean transcript.
  String _parseVtt(String vtt) {
    final lines = vtt.split('\n');
    final textLines = <String>[];
    final timestampRegex = RegExp(
        r'\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}');
    final tagRegex = RegExp(r'<[^>]+>');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed == 'WEBVTT') continue;
      if (trimmed.startsWith('NOTE')) continue;
      if (timestampRegex.hasMatch(trimmed)) continue;
      if (RegExp(r'^\d+$').hasMatch(trimmed)) continue; // cue identifier

      final clean = trimmed
          .replaceAll(tagRegex, '')  // remove <b>, <i>, <c.color> tags
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();

      if (clean.isNotEmpty && (textLines.isEmpty || textLines.last != clean)) {
        textLines.add(clean);
      }
    }

    return textLines.join(' ');
  }

  void _validateUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw const ValidationFailure('Please enter a valid YouTube URL.');
    }
  }
}
