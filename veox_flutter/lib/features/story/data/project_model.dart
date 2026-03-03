import 'package:isar/isar.dart';

part 'project_model.g.dart';

@collection
class ProjectModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String projectId; // UUID

  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;

  // Relations to other entities
  // We use IsarLinks for better performance and query capability
  final characters = IsarLinks<CharacterModel>();
  final scenes = IsarLinks<SceneModel>();
}

@collection
class CharacterModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String characterId; // UUID

  late String name;
  String? description;
  String? baseImagePath; // Local path to generated image

  @Backlink(to: 'characters')
  final project = IsarLink<ProjectModel>();
}

@collection
class SceneModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String sceneId; // UUID

  int index = 0; // Order in story
  late String text; // The story line
  late String generatedPrompt; // Final prompt sent to AI

  String? status; // pending, generating, completed, failed
  String? videoPath; // Local path to generated video
  String? audioPath; // Local path to generated audio

  @Backlink(to: 'scenes')
  final project = IsarLink<ProjectModel>();
}
