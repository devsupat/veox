import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/core/database/browser_profile_model.dart';
import 'package:veox_flutter/core/database/google_account_model.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:path_provider/path_provider.dart';

final isarServiceProvider = Provider((ref) => IsarService());

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
          GoogleAccountModelSchema,
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
  // ... (keep existing project CRUD)

  // --- Implementasi CRUD BrowserProfile ---

  Future<void> saveBrowserProfile(BrowserProfileModel profile) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.collection<BrowserProfileModel>().put(profile);
    });
  }

  Future<List<BrowserProfileModel>> getAllBrowserProfiles() async {
    final isar = await db;
    return await isar.collection<BrowserProfileModel>().where().findAll();
  }

  Future<BrowserProfileModel?> getBrowserProfileByName(String name) async {
    final isar = await db;
    return await isar
        .collection<BrowserProfileModel>()
        .filter()
        .nameEqualTo(name)
        .findFirst();
  }

  Future<void> updateProfileGoogleAccount(
    BrowserProfileModel profile,
    GoogleAccountModel? account,
  ) async {
    final isar = await db;
    await isar.writeTxn(() async {
      profile.googleAccount.value = account;
      await profile.googleAccount.save();
    });
  }

  // --- Implementasi CRUD GoogleAccount ---

  Future<void> saveGoogleAccount(GoogleAccountModel account) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.collection<GoogleAccountModel>().put(account);
    });
  }

  Stream<List<GoogleAccountModel>> watchGoogleAccounts() async* {
    final isar = await db;
    yield* isar.collection<GoogleAccountModel>().where().watch(
      fireImmediately: true,
    );
  }

  Future<void> deleteGoogleAccount(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.collection<GoogleAccountModel>().delete(id);
    });
  }

  // --- Implementasi CRUD SceneModel ---

  Future<void> saveScene(SceneModel scene) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.collection<SceneModel>().put(scene);
    });
  }

  Future<void> replaceProjectScenesAndCharacters(
    String projectId,
    List<CharacterModel> characters,
    List<SceneModel> scenes,
  ) async {
    final isar = await db;
    final project = await isar
        .collection<ProjectModel>()
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
    if (project == null) return;

    await isar.writeTxn(() async {
      // Load current relationships
      await project.characters.load();
      await project.scenes.load();

      // Delete existing records from disk
      final oldCharIds = project.characters.map((c) => c.id).toList();
      final oldSceneIds = project.scenes.map((s) => s.id).toList();
      await isar.collection<CharacterModel>().deleteAll(oldCharIds);
      await isar.collection<SceneModel>().deleteAll(oldSceneIds);

      // Clear links
      project.characters.clear();
      project.scenes.clear();

      // Save new records
      await isar.collection<CharacterModel>().putAll(characters);
      await isar.collection<SceneModel>().putAll(scenes);

      // Add new links
      project.characters.addAll(characters);
      project.scenes.addAll(scenes);

      // Save links
      await project.characters.save();
      await project.scenes.save();
    });
  }

  Future<List<SceneModel>> getScenesByProjectId(String projectId) async {
    final isar = await db;
    final project = await isar
        .collection<ProjectModel>()
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
    if (project == null) return [];
    await project.scenes.load();
    final scenes = project.scenes.toList();
    scenes.sort((a, b) => a.index.compareTo(b.index));
    return scenes;
  }

  Future<List<SceneModel>> getAllScenes() async {
    final isar = await db;
    return await isar.collection<SceneModel>().where().findAll();
  }

  Stream<List<SceneModel>> watchScenes() async* {
    final isar = await db;
    yield* isar.collection<SceneModel>().where().watch(fireImmediately: true);
  }

  Future<void> deleteScene(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.collection<SceneModel>().delete(id);
    });
  }
}
