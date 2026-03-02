import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/database/google_account_model.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/features/automation/services/credential_service.dart';
import 'package:veox_flutter/features/automation/services/veo_automation_service.dart';
import 'package:veox_flutter/core/utils/logger.dart';

final googleAuthProvider = Provider(
  (ref) => GoogleAuthService(
    ref.watch(isarServiceProvider),
    ref.watch(credentialServiceProvider),
    ref.read(veoAutomationProvider.notifier),
  ),
);

final googleAccountsStreamProvider = StreamProvider<List<GoogleAccountModel>>((
  ref,
) {
  return ref.watch(googleAuthProvider).watchAccounts();
});

class GoogleAuthService {
  final IsarService _isar;
  final CredentialService _credentials;
  final VeoAutomationService _automation;

  GoogleAuthService(this._isar, this._credentials, this._automation);

  /// Triggers an interactive login flow by launching the browser.
  /// The user signs in manually, and the automation engine waits for the session.
  Future<void> startGuidedLogin({
    required String email,
    required String password,
  }) async {
    AppLogger.info('Starting guided Google login for $email', tag: 'Auth');

    try {
      // 1. Store credentials securely first
      await _credentials.savePassword(email, password);

      // 2. Trigger "auth" action in the Node.js engine
      // This will launch a non-headless browser specifically for login.
      await _automation.executeVeoAction(
        action: "auth_guided",
        email: email,
        password: password,
      );

      // 3. If the command succeeds, it means login was detected.
      // Save the account metadata to Isar.
      final account = GoogleAccountModel()..email = email;
      await _isar.saveGoogleAccount(account);

      AppLogger.info(
        'Successfully added and authorized account: $email',
        tag: 'Auth',
      );
    } catch (e) {
      AppLogger.error('Guided login failed for $email', error: e, tag: 'Auth');
      rethrow;
    }
  }

  /// Removes an account and its secured credentials.
  Future<void> removeAccount(GoogleAccountModel account) async {
    AppLogger.warn('Removing Google account: ${account.email}', tag: 'Auth');
    await _credentials.deletePassword(account.email);
    await _isar.deleteGoogleAccount(account.id);
  }

  /// Stream of all registered Google accounts.
  Stream<List<GoogleAccountModel>> watchAccounts() {
    return _isar.watchGoogleAccounts();
  }
}
