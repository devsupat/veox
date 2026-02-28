// lib/features/video_mastering/domain/video_mastering_service.dart
//
// Orchestrates full video assembly pipeline using ffmpeg via ProcessRunner:
//   1. Load project scenes (images + audio) from Isar
//   2. Build FFmpeg commands
//   3. Execute commands with streaming progress
//   4. Return output path
//
// All heavy FFmpeg work streams progress lines so the UI can display
// a live log (frame counts, fps, time remaining).

import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/process/process_runner.dart';
import 'package:veox_flutter/core/utils/logger.dart';
import 'package:veox_flutter/features/video_mastering/domain/ffmpeg_command_builder.dart';

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

class MasteringProgress {
  const MasteringProgress({required this.step, this.log, this.outputPath});
  final String step;
  final String? log;
  final String? outputPath;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class VideoMasteringService {
  VideoMasteringService._();
  static final VideoMasteringService instance = VideoMasteringService._();

  final _runner = ProcessRunner.instance;

  // ── Assemble Project ─────────────────────────────────────────────────────

  /// Full pipeline: project scenes → final video file.
  Stream<MasteringProgress> assembleFromProject(
    String projectId, {
    bool includeAudio = true,
    String? logoPath,
    String? exportPreset,
  }) async* {
    yield const MasteringProgress(step: 'Loading scenes from database…');

    final isar = await IsarService().db;
    final project = await isar.projectModels
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
    if (project == null) {
      throw DatabaseFailure('Project $projectId not found.');
    }

    await project.scenes.load();
    final scenes = project.scenes.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final imagePaths = scenes
        .where((s) => s.videoPath != null && File(s.videoPath!).existsSync())
        .map((s) => s.videoPath!)
        .toList();

    if (imagePaths.isEmpty) {
      throw const FileSystemFailure(
          'No generated images found. Run scene generation first.');
    }

    final audioPaths = includeAudio
        ? scenes
            .where((s) => s.audioPath != null && File(s.audioPath!).existsSync())
            .map((s) => s.audioPath!)
            .toList()
        : <String>[];

    final docsDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${docsDir.path}/VEOX/exports/$projectId');
    outputDir.createSync(recursive: true);
    final tempDir = Directory('${docsDir.path}/VEOX/temp/$projectId');
    tempDir.createSync(recursive: true);

    // Step 1: Images → silent video
    yield const MasteringProgress(step: 'Converting images to video…');
    final silentVideo = '${tempDir.path}/silent.mp4';
    await for (final line in _runner.stream(
      'ffmpeg',
      FFmpegCommandBuilder.imagesToVideo(imagePaths, silentVideo),
    )) {
      yield MasteringProgress(step: 'Encoding video…', log: line);
    }

    // Step 2: Add audio (if available)
    String videoWithAudio = silentVideo;
    if (audioPaths.isNotEmpty) {
      yield const MasteringProgress(step: 'Merging audio tracks…');
      videoWithAudio = '${tempDir.path}/with_audio.mp4';

      // Concatenate audio tracks, then merge with video
      final mergedAudio = '${tempDir.path}/merged_audio.mp3';
      await for (final line in _runner.stream(
        'ffmpeg',
        FFmpegCommandBuilder.concatenate(audioPaths, mergedAudio, reEncode: true),
      )) {
        yield MasteringProgress(step: 'Merging audio…', log: line);
      }

      await for (final line in _runner.stream(
        'ffmpeg',
        FFmpegCommandBuilder.addAudio(silentVideo, mergedAudio, videoWithAudio),
      )) {
        yield MasteringProgress(step: 'Adding audio to video…', log: line);
      }
    }

    // Step 3: Logo overlay (optional)
    String finalVideo = videoWithAudio;
    if (logoPath != null && File(logoPath).existsSync()) {
      yield const MasteringProgress(step: 'Adding logo watermark…');
      finalVideo = '${tempDir.path}/with_logo.mp4';
      await for (final line in _runner.stream(
        'ffmpeg',
        FFmpegCommandBuilder.addLogo(videoWithAudio, logoPath, finalVideo),
      )) {
        yield MasteringProgress(step: 'Adding logo…', log: line);
      }
    }

    // Step 4: Export with preset
    final outputPath = '${outputDir.path}/${const Uuid().v4()}.mp4';
    yield MasteringProgress(step: 'Exporting final video (${exportPreset ?? '1080p'})…');

    List<String> exportArgs;
    if (exportPreset == '9:16 Reel') {
      exportArgs = FFmpegCommandBuilder.exportReel(finalVideo, outputPath);
    } else if (exportPreset == '4K') {
      exportArgs = FFmpegCommandBuilder.upscale(finalVideo, outputPath, scale: 2);
    } else {
      // Default: copy without re-encoding if codecs match, else fast encode
      exportArgs = ['-y', '-i', finalVideo, '-c', 'copy', outputPath];
    }

    await for (final line in _runner.stream('ffmpeg', exportArgs)) {
      yield MasteringProgress(step: 'Exporting…', log: line);
    }

    // Cleanup temp files
    _cleanDir(tempDir);

    AppLogger.info('Export complete: $outputPath', tag: 'Mastering');
    yield MasteringProgress(step: 'Done!', outputPath: outputPath);
  }

  // ── Single Operations ─────────────────────────────────────────────────────

  Future<String> exportWithPreset(
    String inputPath,
    String outputPath,
    String preset,
  ) async {
    await _assertFfmpeg();
    final args = switch (preset) {
      '9:16 Reel' => FFmpegCommandBuilder.exportReel(inputPath, outputPath),
      '4K' => FFmpegCommandBuilder.upscale(inputPath, outputPath, scale: 2),
      _ => ['-y', '-i', inputPath, '-c', 'copy', outputPath],
    };
    await _runBlocking('ffmpeg', args);
    return outputPath;
  }

  Future<String?> extractThumbnail(String videoPath, {double atSeconds = 1.0}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final out = '${docsDir.path}/VEOX/thumbnails/${const Uuid().v4()}.jpg';
    Directory(out).parent.createSync(recursive: true);
    try {
      await _runBlocking(
          'ffmpeg', FFmpegCommandBuilder.extractThumbnail(videoPath, out));
      return out;
    } catch (e) {
      AppLogger.warn('Thumbnail extraction failed: $e', tag: 'Mastering');
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _runBlocking(String exe, List<String> args) async {
    final result = await _runner.run(exe, args);
    if (!result.succeeded) {
      throw ProcessFailure('$exe failed', exitCode: result.exitCode,
          stderr: result.stderr);
    }
  }

  Future<void> _assertFfmpeg() async {
    if (!await _runner.isInstalled('ffmpeg')) {
      throw const MissingToolFailure('ffmpeg');
    }
  }

  void _cleanDir(Directory dir) {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
