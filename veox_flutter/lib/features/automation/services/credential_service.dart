import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final credentialServiceProvider = Provider((ref) => CredentialService());

class CredentialService {
  final _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      useDataProtectionKeyChain: false,
    ),
  );

  static const String _keyPrefix = 'veo_pass_';

  Future<void> savePassword(String profileName, String password) async {
    await _storage.write(key: '$_keyPrefix$profileName', value: password);
  }

  Future<String?> getPassword(String profileName) async {
    return await _storage.read(key: '$_keyPrefix$profileName');
  }

  Future<void> deletePassword(String profileName) async {
    await _storage.delete(key: '$_keyPrefix$profileName');
  }

  // Generic API key storage
  Future<void> saveApiKey(String service, String key) async {
    await _storage.write(key: 'api_key_$service', value: key);
  }

  Future<String?> getApiKey(String service) async {
    return await _storage.read(key: 'api_key_$service');
  }
}
