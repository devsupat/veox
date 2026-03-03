import 'package:isar/isar.dart';

part 'task_model.g.dart';

@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String taskId; // UUID for external ref

  @Index()
  late String type; // 'video_gen', 'image_gen', 'browser_action'

  @Index()
  late String status; // 'pending', 'running', 'completed', 'failed', 'retrying', 'canceled', 'paused_needs_login'

  /// Lower number = higher priority. Range 0–10.
  @Index()
  int priority = 5;

  late DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;

  int retryCount = 0;
  DateTime? retryAfter;
  String? errorLog;
  String? errorCategory;

  /// Whether the last failure is retryable. Only meaningful when status == 'failed'.
  bool retryable = true;

  /// Deterministic identity hash: SHA-1(profileId + normalizedPrompt + index).
  /// Used for skipDone deduplication — if a completed task with this hash exists,
  /// we skip enqueueing a duplicate.
  @Index(unique: true, replace: false)
  String? promptHash;

  /// JSON payload forwarded to the Node script or API client.
  late String payloadJson;

  /// Local filesystem path to the output file (video/image/audio).
  String? outputPath;
}
