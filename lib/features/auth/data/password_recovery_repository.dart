import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

enum PasswordRecoveryAccountType { client, staff, partner }

final passwordRecoveryRepositoryProvider = Provider<PasswordRecoveryRepository>(
  (ref) => PasswordRecoveryRepository(ref.read(apiClientProvider)),
);

/// La récupération ne connecte pas de compte et ne modifie aucune session.
class PasswordRecoveryRepository {
  PasswordRecoveryRepository(this._client, {FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  final ApiClient _client;
  final FirebaseAuth? _firebaseAuth;

  Future<void> request({
    required String email,
    required PasswordRecoveryAccountType accountType,
    required String languageCode,
  }) async {
    final locale = languageCode == 'en' ? 'en' : 'fr';
    if (accountType == PasswordRecoveryAccountType.client) {
      final firebase = _firebaseAuth ?? FirebaseAuth.instance;
      try {
        await firebase.setLanguageCode(locale);
        await firebase.sendPasswordResetEmail(email: email.trim());
      } on FirebaseAuthException catch (error) {
        // Même confirmation que pour un compte existant : l'écran ne révèle
        // ni l'existence ni l'état d'un compte Firebase.
        if (error.code != 'user-not-found' && error.code != 'user-disabled') {
          rethrow;
        }
      }
      return;
    }

    final response = await _client.post(
      '/auth/password/forgot',
      data: {
        'email': email.trim(),
        'account_type': accountType.name,
        'locale': locale,
      },
    );
    if (response['code'] != 'password_reset_requested') {
      throw const FormatException('Unexpected password recovery response.');
    }
  }
}
