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
  late String status; // 'pending', 'running', 'completed', 'failed', 'retrying'

  /// Lower number = higher priority. Range 0–10.
  @Index()
  int priority = 5;

  late DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;

  int retryCount = 0;
  String? errorLog;

  /// JSON payload forwarded to the Node script or API client.
  late String payloadJson;

  /// Local filesystem path to the output file (video/image/audio).
  String? outputPath;
}
