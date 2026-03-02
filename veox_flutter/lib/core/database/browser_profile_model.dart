import 'package:isar/isar.dart';
import 'google_account_model.dart';

part 'browser_profile_model.g.dart';

@collection
class BrowserProfileModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name; // e.g., "Personal", "Bot 1"

  late String userDataDir; // Path to folder on disk
  late String platform; // 'veo', 'gemini'

  // Account & Security Management
  final googleAccount = IsarLink<GoogleAccountModel>();

  String? cookiesJson; // Session cookies for persistence
  String? sessionState; // e.g., 'Whisk' state or other session data

  // API Key Placeholders (Connect with flutter_secure_storage later)
  // e.g., String? _geminiApiKeyPlaceholder;
  // e.g., String? _elevenLabsApiKeyPlaceholder;
  // e.g., String? _groqApiKeyPlaceholder;

  DateTime? lastUsed;
}
