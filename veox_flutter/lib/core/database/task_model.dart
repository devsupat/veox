import 'package:isar/isar.dart';

part 'task_model.g.dart';

@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String taskId; // UUID for external ref

  @Index()
  late String type; // 'video_gen', 'image_gen', 'upscale'

  @Index()
  late String status; // 'pending', 'running', 'completed', 'failed'

  late DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;

  int retryCount = 0;
  String? errorLog;

  // JSON payload for the Node script
  late String payloadJson; 
  
  // Path to output file
  String? outputPath;
}
