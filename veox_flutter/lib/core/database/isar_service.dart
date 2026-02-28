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
          SceneModelSchema
        ],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
