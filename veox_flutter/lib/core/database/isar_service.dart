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
