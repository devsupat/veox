// lib/features/video_mastering/domain/ffmpeg_command_builder.dart
//
// Builder pattern for FFmpeg argument arrays.
// All methods are static: no state, no side effects, fully testable.
//
// Rationale for using system ffmpeg (via ProcessRunner) instead of an
// ffmpeg Flutter plugin:
//   - ffmpeg_kit_flutter_full adds ~100 MB to bundle and is hard to compile on desktop.
//   - macOS ships with ffmpeg (Homebrew), so it's always available in dev.
//   - ProcessRunner gives us streaming output for real-time progress bars.
//   - Users can upgrade ffmpeg independently of the app.

class FFmpegCommandBuilder {
  const FFmpegCommandBuilder._();

  // ── Images → Video ────────────────────────────────────────────────────────

  /// Creates a video from a list of image files using the concat demuxer.
  /// Each image is displayed for [secondsPerImage] seconds.
  static List<String> imagesToVideo(
    List<String> imagePaths,
    String outputPath, {
    int fps = 24,
    double secondsPerImage = 3.0,
  }) {
    // Build a concat file content (returned separately if needed, but here
    // we use pattern matching for simplicity when all images are sequentially named).
    // For numbered frames: ffmpeg can use glob.
    // We use the concat filter for arbitrary paths.
    final scaleFilter =
        'scale=1920:1080:force_original_aspect_ratio=decrease,'
        'pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black';

    return [
      '-y',
      // For each image, input with a duration
      ...imagePaths.expand(
        (p) => ['-loop', '1', '-t', '$secondsPerImage', '-i', p],
      ),
      '-filter_complex',
      [
        // Concat all images into video stream
        List.generate(
          imagePaths.length,
          (i) => '[$i:v]$scaleFilter[v$i]',
        ).join(';'),
        '${List.generate(imagePaths.length, (i) => '[v$i]').join('')}'
            'concat=n=${imagePaths.length}:v=1:a=0[v]',
      ].join(';'),
      '-map', '[v]',
      '-r', '$fps',
      '-c:v', 'libx264',
      '-pix_fmt', 'yuv420p',
      '-preset', 'medium',
      outputPath,
    ];
  }

  // ── Add Audio Track ───────────────────────────────────────────────────────

  /// Merges [audioPath] into [videoPath]. Audio is truncated/looped to video duration.
  static List<String> addAudio(
    String videoPath,
    String audioPath,
    String outputPath, {
    bool loopAudio = false,
  }) {
    return [
      '-y',
      '-i',
      videoPath,
      if (loopAudio) ...['-stream_loop', '-1'],
      '-i',
      audioPath,
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      '-shortest',
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      outputPath,
    ];
  }

  // ── Add Logo / Watermark ──────────────────────────────────────────────────

  /// Overlays [logoPath] at position ([x], [y]) with [opacity].
  static List<String> addLogo(
    String videoPath,
    String logoPath,
    String outputPath, {
    int x = 10,
    int y = 10,
    double opacity = 0.8,
    int logoWidth = 120,
  }) {
    return [
      '-y',
      '-i',
      videoPath,
      '-i',
      logoPath,
      '-filter_complex',
      '[1:v]scale=$logoWidth:-1,format=rgba,colorchannelmixer=aa=$opacity[logo];'
          '[0:v][logo]overlay=$x:$y[v]',
      '-map',
      '[v]',
      '-map',
      '0:a?',
      '-c:v',
      'libx264',
      '-c:a',
      'copy',
      '-preset',
      'fast',
      outputPath,
    ];
  }

  // ── Concatenate Videos ────────────────────────────────────────────────────

  /// Concatenates [videoPaths] in order.
  /// Requires all inputs to have the same codec/resolution. Use re-encode
  /// (passUnified = false) if inputs differ.
  static List<String> concatenate(
    List<String> videoPaths,
    String outputPath, {
    bool reEncode = false,
  }) {
    if (reEncode) {
      return [
        '-y',
        ...videoPaths.expand((p) => ['-i', p]),
        '-filter_complex',
        '${videoPaths.asMap().keys.map((i) => '[$i:v][$i:a]').join('')}'
            'concat=n=${videoPaths.length}:v=1:a=1[v][a]',
        '-map',
        '[v]',
        '-map',
        '[a]',
        '-c:v',
        'libx264',
        '-c:a',
        'aac',
        outputPath,
      ];
    }

    // Fast copy using concat demuxer (all inputs must match).
    return [
      '-y',
      '-f', 'concat',
      '-safe', '0',
      '-i', 'pipe:0', // Write concat file to stdin
      '-c', 'copy',
      outputPath,
    ];
  }

  // ── Upscale ───────────────────────────────────────────────────────────────

  /// Upscales using lanczos — quality close to Real-ESRGAN for video without ML.
  static List<String> upscale(
    String inputPath,
    String outputPath, {
    int scale = 2,
  }) {
    final w = scale == 2 ? '3840' : '2560';
    final h = scale == 2 ? '2160' : '1440';
    return [
      '-y',
      '-i',
      inputPath,
      '-vf',
      'scale=$w:$h:flags=lanczos',
      '-c:v',
      'libx264',
      '-crf',
      '18',
      '-preset',
      'slow',
      outputPath,
    ];
  }

  // ── Export Reel (9:16) ────────────────────────────────────────────────────

  /// Crops and scales a 16:9 video to 9:16 for Reels / Shorts.
  static List<String> exportReel(
    String videoPath,
    String outputPath, {
    String resolution = '1080x1920',
  }) {
    final parts = resolution.split('x');
    final w = parts[0];
    final h = parts[1];
    return [
      '-y',
      '-i',
      videoPath,
      '-vf',
      'crop=ih*9/16:ih,scale=$w:$h',
      '-c:v',
      'libx264',
      '-c:a',
      'copy',
      '-preset',
      'fast',
      outputPath,
    ];
  }

  // ── Add Subtitles ─────────────────────────────────────────────────────────

  /// Burns [srtPath] subtitles permanently into the video.
  static List<String> addSubtitles(
    String videoPath,
    String srtPath,
    String outputPath,
  ) {
    return [
      '-y',
      '-i',
      videoPath,
      '-vf',
      'subtitles=$srtPath:force_style='
          "'FontName=Arial,FontSize=20,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2'",
      '-c:v',
      'libx264',
      '-c:a',
      'copy',
      outputPath,
    ];
  }

  // ── Thumbnail ─────────────────────────────────────────────────────────────

  /// Extracts a thumbnail image at [timestampSeconds].
  static List<String> extractThumbnail(
    String videoPath,
    String outputPath, {
    double timestampSeconds = 1.0,
  }) {
    return [
      '-y',
      '-ss',
      '$timestampSeconds',
      '-i',
      videoPath,
      '-vframes',
      '1',
      '-q:v',
      '2',
      outputPath,
    ];
  }
}
