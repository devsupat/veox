import 'package:isar/isar.dart';
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/core/database/browser_profile_model.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  late Future<Isar> db;

  Future<Isar> init() async {
    db = _openDb();
    return db;
  }

  Future<Isar> _openDb() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [
          TaskModelSchema,
          BrowserProfileModelSchema,
          ProjectModelSchema,
          CharacterModelSchema,
          SceneModelSchema,
        ],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }

  // --- Implementasi CRUD Proyek ---

  /// Create or Update Project
  Future<void> saveProject(ProjectModel project) async {
    try {
      final isar = await db;
      await isar.writeTxn(() async {
        await isar.collection<ProjectModel>().put(project);
      });
    } catch (e) {
      // Sederhana error handling
      // debugPrint('Error saving project: $e');
      rethrow;
    }
  }

  /// Read all Projects
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final isar = await db;
      return await isar.collection<ProjectModel>().where().findAll();
    } catch (e) {
      // debugPrint('Error getting all projects: $e');
      return [];
    }
  }

  /// Delete Project by ID (Note: Isar uses int ID natively, but UUID is String)
  Future<void> deleteProject(String uuid) async {
    try {
      final isar = await db;
      await isar.writeTxn(() async {
        await isar
            .collection<ProjectModel>()
            .filter()
            .projectIdEqualTo(uuid)
            .deleteAll();
      });
    } catch (e) {
      // debugPrint('Error deleting project: $e');
      rethrow;
    }
  }

  /// Get specific Project by UUID (using generated filter extension)
  Future<ProjectModel?> getProjectById(String uuid) async {
    try {
      final isar = await db;
      return await isar
          .collection<ProjectModel>()
          .filter()
          .projectIdEqualTo(uuid)
          .findFirst();
    } catch (e) {
      // debugPrint('Error getting project by id: $e');
      return null;
    }
  }
}
