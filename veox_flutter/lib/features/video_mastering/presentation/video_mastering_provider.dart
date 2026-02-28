// lib/features/video_mastering/presentation/video_mastering_provider.dart
//
// Riverpod state layer for the Video Mastering tab.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/features/video_mastering/domain/video_mastering_service.dart';

class VideoMasteringState {
  const VideoMasteringState({
    this.isProcessing = false,
    this.logs = const [],
    this.outputPath,
    this.error,
    this.selectedPreset = '1080p',
    this.currentStep = '',
  });

  final bool isProcessing;
  final List<String> logs;
  final String? outputPath;
  final String? error;
  final String selectedPreset;
  final String currentStep;

  VideoMasteringState copyWith({
    bool? isProcessing,
    List<String>? logs,
    String? outputPath,
    String? error,
    String? selectedPreset,
    String? currentStep,
    bool clearError = false,
    bool clearOutput = false,
  }) =>
      VideoMasteringState(
        isProcessing: isProcessing ?? this.isProcessing,
        logs: logs ?? this.logs,
        outputPath: clearOutput ? null : (outputPath ?? this.outputPath),
        error: clearError ? null : (error ?? this.error),
        selectedPreset: selectedPreset ?? this.selectedPreset,
        currentStep: currentStep ?? this.currentStep,
      );
}

final videoMasteringNotifierProvider =
    StateNotifierProvider<VideoMasteringNotifier, VideoMasteringState>((ref) {
  return VideoMasteringNotifier();
});

class VideoMasteringNotifier extends StateNotifier<VideoMasteringState> {
  VideoMasteringNotifier() : super(const VideoMasteringState());

  final _svc = VideoMasteringService.instance;
  StreamSubscription<MasteringProgress>? _sub;

  void setPreset(String preset) => state = state.copyWith(selectedPreset: preset);

  Future<void> assemble(
    String projectId, {
    bool includeAudio = true,
    String? logoPath,
  }) async {
    state = state.copyWith(
      isProcessing: true,
      logs: [],
      clearError: true,
      clearOutput: true,
      currentStep: 'Starting…',
    );

    _sub = _svc
        .assembleFromProject(
          projectId,
          includeAudio: includeAudio,
          logoPath: logoPath,
          exportPreset: state.selectedPreset,
        )
        .listen(
      (progress) {
        final updatedLogs = progress.log != null
            ? [...state.logs, progress.log!]
            : state.logs;
        state = state.copyWith(
          logs: updatedLogs,
          currentStep: progress.step,
          outputPath: progress.outputPath,
          isProcessing: progress.outputPath == null,
        );
      },
      onError: (Object e) {
        state =
            state.copyWith(isProcessing: false, error: e.toString());
      },
    );
  }

  void cancel() {
    _sub?.cancel();
    state = state.copyWith(isProcessing: false, currentStep: 'Cancelled.');
  }

  void clearLogs() => state = state.copyWith(logs: []);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
