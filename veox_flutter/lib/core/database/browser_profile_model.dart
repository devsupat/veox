import 'package:isar/isar.dart';

part 'browser_profile_model.g.dart';

@collection
class BrowserProfileModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name; // e.g., "Personal", "Bot 1"

  late String userDataDir; // Path to folder on disk
  late String platform; // 'veo', 'gemini'
  
  DateTime? lastUsed;
}
