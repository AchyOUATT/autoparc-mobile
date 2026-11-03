import 'package:auto/core/api/api_exception.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in {
    'client_account_requires_partner_login': (
      'Ce compte est un compte partenaire. Connectez-vous à l’espace partenaire.',
      'This is a partner account. Sign in to the partner area.',
    ),
    'client_account_requires_staff_login': (
      'Ce compte appartient au personnel. Utilisez la connexion du personnel.',
      'This is a staff account. Use staff sign-in.',
    ),
  }.entries) {
    test(
      'account type ${entry.key} gives translated guidance from its code',
      () {
        final error = ApiException(
          message: 'Forbidden',
          statusCode: 403,
          code: entry.key,
        );
        expect(error.userMessage, entry.value.$1);
        expect(
          messageFor(error, l10n: lookupAppLocalizations(const Locale('fr'))),
          entry.value.$1,
        );
        expect(
          messageFor(error, l10n: lookupAppLocalizations(const Locale('en'))),
          entry.value.$2,
        );
        // This client-login refusal must not expire an independent staff or
        // partner session. The Firebase login flow handles its own refusal.
        expect(error.sessionRejected, isFalse);
      },
    );
  }
}
