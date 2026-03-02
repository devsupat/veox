import 'package:isar/isar.dart';

part 'google_account_model.g.dart';

@collection
class GoogleAccountModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String email;

  String? displayName;
  String? avatarUrl;

  // Metadata for the account
  DateTime createdAt = DateTime.now();
  DateTime? lastLogin;

  // Status flags
  bool isActive = true;

  // Note: Passwords/Secrets are NOT stored here.
  // They are stored in flutter_secure_storage via CredentialService.
}
