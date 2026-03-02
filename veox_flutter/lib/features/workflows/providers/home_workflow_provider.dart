import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/state/workflow_state.dart';

class HomeWorkflowData {
  final String prompt;
  final String aspectRatio;
  final String model;
  final String quality;
  final String upscale;
  final bool isBoost;

  const HomeWorkflowData({
    this.prompt = '',
    this.aspectRatio = '16:9',
    this.model = 'Veo 3.1 - Fast (Lower Priority)',
    this.quality = 'AI Ultra (25,000 cr)',
    this.upscale = '1080p',
    this.isBoost = false,
  });

  HomeWorkflowData copyWith({
    String? prompt,
    String? aspectRatio,
    String? model,
    String? quality,
    String? upscale,
    bool? isBoost,
  }) {
    return HomeWorkflowData(
      prompt: prompt ?? this.prompt,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      model: model ?? this.model,
      quality: quality ?? this.quality,
      upscale: upscale ?? this.upscale,
      isBoost: isBoost ?? this.isBoost,
    );
  }
}

class HomeWorkflowNotifier
    extends StateNotifier<WorkflowState<HomeWorkflowData>> {
  HomeWorkflowNotifier()
    : super(const WorkflowState(payload: HomeWorkflowData()));

  void updateData(HomeWorkflowData newData) {
    state = state.copyWith(
      payload: newData,
      status: _determineStatus(newData),
      clearError: true,
    );
  }

  WorkflowStatus _determineStatus(HomeWorkflowData data) {
    if (state.isRunning) return WorkflowStatus.running;
    if (data.prompt.isNotEmpty) return WorkflowStatus.ready;
    return WorkflowStatus.editing;
  }

  void startGeneration() {
    if (!state.isReady) return;
    state = state.copyWith(
      status: WorkflowStatus.running,
      progress: 0.1,
      currentAction: 'Initializing generation engine...',
    );
  }

  void updateProgress(double progress, String action) {
    if (!state.isRunning) return;
    state = state.copyWith(progress: progress, currentAction: action);
  }

  void completeGeneration() {
    state = state.copyWith(
      status: WorkflowStatus.done,
      progress: 1.0,
      currentAction: 'Generation complete',
    );
  }

  void failGeneration(String error) {
    state = state.copyWith(
      status: WorkflowStatus.error,
      errorMessage: error,
      currentAction: 'Failed',
    );
  }

  void reset() {
    state = const WorkflowState(payload: HomeWorkflowData());
  }
}

final homeWorkflowProvider =
    StateNotifierProvider<
      HomeWorkflowNotifier,
      WorkflowState<HomeWorkflowData>
    >((ref) {
      return HomeWorkflowNotifier();
    });
