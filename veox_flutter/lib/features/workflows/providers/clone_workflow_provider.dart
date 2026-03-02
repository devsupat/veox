import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/state/workflow_state.dart';

class CloneWorkflowData {
  final String sourceUrl;
  final String prompt;
  final String style;
  final String model;
  final bool autoSync;
  final bool voiceEnabled;

  const CloneWorkflowData({
    this.sourceUrl = '',
    this.prompt = '',
    this.style = 'No Style',
    this.model = 'Gemini 3 Flash',
    this.autoSync = true,
    this.voiceEnabled = false,
  });

  CloneWorkflowData copyWith({
    String? sourceUrl,
    String? prompt,
    String? style,
    String? model,
    bool? autoSync,
    bool? voiceEnabled,
  }) {
    return CloneWorkflowData(
      sourceUrl: sourceUrl ?? this.sourceUrl,
      prompt: prompt ?? this.prompt,
      style: style ?? this.style,
      model: model ?? this.model,
      autoSync: autoSync ?? this.autoSync,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
    );
  }
}

class CloneWorkflowNotifier
    extends StateNotifier<WorkflowState<CloneWorkflowData>> {
  CloneWorkflowNotifier()
    : super(const WorkflowState(payload: CloneWorkflowData()));

  void updateData(CloneWorkflowData newData) {
    state = state.copyWith(
      payload: newData,
      status: _determineStatus(newData),
      clearError: true,
    );
  }

  WorkflowStatus _determineStatus(CloneWorkflowData data) {
    if (state.isRunning) return WorkflowStatus.running;
    if (data.sourceUrl.isNotEmpty && data.prompt.isNotEmpty)
      return WorkflowStatus.ready;
    return WorkflowStatus.editing;
  }

  void startGeneration() {
    if (!state.isReady) return;
    state = state.copyWith(
      status: WorkflowStatus.running,
      progress: 0.1,
      currentAction: 'Analyzing source URL...',
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
      currentAction: 'Sequence completed',
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
    state = const WorkflowState(payload: CloneWorkflowData());
  }
}

final cloneWorkflowProvider =
    StateNotifierProvider<
      CloneWorkflowNotifier,
      WorkflowState<CloneWorkflowData>
    >((ref) {
      return CloneWorkflowNotifier();
    });
