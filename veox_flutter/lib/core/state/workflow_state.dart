enum WorkflowStatus { idle, editing, ready, running, done, error }

class WorkflowState<T> {
  final WorkflowStatus status;
  final T? payload;
  final String? errorMessage;
  final double progress;
  final String? currentAction;

  const WorkflowState({
    this.status = WorkflowStatus.idle,
    this.payload,
    this.errorMessage,
    this.progress = 0.0,
    this.currentAction,
  });

  bool get isIdle => status == WorkflowStatus.idle;
  bool get isEditing => status == WorkflowStatus.editing;
  bool get isReady => status == WorkflowStatus.ready;
  bool get isRunning => status == WorkflowStatus.running;
  bool get isDone => status == WorkflowStatus.done;
  bool get isError => status == WorkflowStatus.error;

  WorkflowState<T> copyWith({
    WorkflowStatus? status,
    T? payload,
    String? errorMessage,
    double? progress,
    String? currentAction,
    bool clearError = false,
  }) {
    return WorkflowState<T>(
      status: status ?? this.status,
      payload: payload ?? this.payload,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      progress: progress ?? this.progress,
      currentAction: currentAction ?? this.currentAction,
    );
  }
}
