// lib/features/automation/presentation/youtube_clone_provider.dart
//
// Riverpod layer for the YouTube Clone tab.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/features/automation/services/youtube_clone_service.dart';

class YouTubeCloneState {
  const YouTubeCloneState({
    this.step = CloneStep.idle,
    this.message = '',
    this.prompts = const [],
    this.sourceUrl = '',
    this.isRunning = false,
    this.error,
  });

  final CloneStep step;
  final String message;
  final List<String> prompts;
  final String sourceUrl;
  final bool isRunning;
  final String? error;

  YouTubeCloneState copyWith({
    CloneStep? step,
    String? message,
    List<String>? prompts,
    String? sourceUrl,
    bool? isRunning,
    String? error,
    bool clearError = false,
  }) =>
      YouTubeCloneState(
        step: step ?? this.step,
        message: message ?? this.message,
        prompts: prompts ?? this.prompts,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        isRunning: isRunning ?? this.isRunning,
        error: clearError ? null : (error ?? this.error),
      );
}

final youtubecloneNotifierProvider =
    StateNotifierProvider<YouTubeCloneNotifier, YouTubeCloneState>((ref) {
  return YouTubeCloneNotifier();
});

class YouTubeCloneNotifier extends StateNotifier<YouTubeCloneState> {
  YouTubeCloneNotifier() : super(const YouTubeCloneState());

  final _svc = YouTubeCloneService.instance;
  StreamSubscription<CloneProgress>? _sub;

  void setUrl(String url) => state = state.copyWith(sourceUrl: url);

  Future<void> startClone() async {
    if (state.sourceUrl.trim().isEmpty) return;

    state = state.copyWith(
        isRunning: true, prompts: [], clearError: true, step: CloneStep.fetchingInfo);

    _sub = _svc.cloneVideo(state.sourceUrl).listen(
      (progress) {
        state = state.copyWith(
          step: progress.step,
          message: progress.message ?? '',
          prompts: progress.prompts ?? state.prompts,
          isRunning: progress.step != CloneStep.done && progress.step != CloneStep.failed,
          error: progress.step == CloneStep.failed ? progress.message : null,
        );
      },
      onError: (Object e) =>
          state = state.copyWith(isRunning: false, error: e.toString()),
    );
  }

  void cancel() {
    _sub?.cancel();
    state = state.copyWith(isRunning: false, step: CloneStep.idle);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
