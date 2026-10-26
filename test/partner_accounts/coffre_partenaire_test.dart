import 'dart:convert';

import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le VRAI coffre partenaire, par-dessus un canal de plateforme faussé.
///
/// Les autres bancs de ce dossier passent par un faux magasin en mémoire, ce
/// qui est juste pour éprouver le notifier — mais laisse
/// `SecurePartnerTokenStore` sans aucune couverture. Or c'est lui qui porte la
/// MIGRATION : tout partenaire connecté avant cette version n'a que
/// `partner_sanctum_token`, et ignorer cette clé les déconnecterait tous à la
/// mise à jour, sans message et sans raison.
///
/// Son pendant côté personnel est le harnais de `test/session_personnel_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> valeurs;

  setUp(() {
    valeurs = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?) ?? const {};
        final cle = args['key'] as String?;

        switch (call.method) {
          case 'read':
            return valeurs[cle];
          case 'write':
            valeurs[cle!] = args['value'] as String;

            return null;
          case 'delete':
            valeurs.remove(cle);

            return null;
          case 'readAll':
            return valeurs;
          case 'deleteAll':
            valeurs.clear();

            return null;
        }

        return null;
      },
    );
  });

  final coffre = SecurePartnerTokenStore();

  Map<String, dynamic> profil() => {
        'user': {'role': 'partner'},
        'partner_account': {'company_name': 'Garage Kossodo', 'status': 'approved'},
      };

  test('les deux clés ne portent pas le même nom', () {
    expect(SecurePartnerTokenStore.tokenKey, 'partner_sanctum_token');
    expect(SecurePartnerTokenStore.sessionKey, 'partner_sanctum_session');
  });

  test('un coffre vide ne rend rien', () async {
    expect(await coffre.readSession(), isNull);
    expect(await coffre.read(), isNull);
  });

  /// LA MIGRATION.
  test('l’ancienne clé seule est lue, sans profil', () async {
    valeurs[SecurePartnerTokenStore.tokenKey] = 'jeton-d-avant';

    final session = await coffre.readSession();

    expect(session?.token, 'jeton-d-avant');
    expect(session?.profile, isNull,
        reason: 'Cette version du coffre n’enregistrait pas le profil ; la '
            'vérification le ramènera.');
    expect(await coffre.read(), 'jeton-d-avant',
        reason: 'Le jeton doit continuer d’authentifier les requêtes.');
  });

  test('l’enregistrement courant rend le jeton ET le profil', () async {
    valeurs[SecurePartnerTokenStore.sessionKey] =
        jsonEncode({'token': 'jeton-courant', 'profile': profil()});

    final session = await coffre.readSession();

    expect(session?.token, 'jeton-courant');
    expect(PartnerProfile.fromJson(session!.profile!).companyName,
        'Garage Kossodo');
  });

  /// L'ancienne clé ne doit pas survivre : la lecture préfère l'enregistrement
  /// courant, donc un jeton laissé là ne serait plus jamais ni lu ni effacé —
  /// et le serveur le garde valable, `config/sanctum.php` portant
  /// `'expiration' => null`.
  test('écrire une session retire l’ancienne clé', () async {
    valeurs[SecurePartnerTokenStore.tokenKey] = 'jeton-d-avant';

    await coffre.writeSession('jeton-neuf', profil());

    expect(valeurs.containsKey(SecurePartnerTokenStore.tokenKey), isFalse);
    expect((await coffre.readSession())?.token, 'jeton-neuf');
  });

  test('effacer retire LES DEUX clés', () async {
    valeurs[SecurePartnerTokenStore.tokenKey] = 'jeton-d-avant';
    valeurs[SecurePartnerTokenStore.sessionKey] =
        jsonEncode({'token': 'jeton-courant'});

    await coffre.clear();

    expect(valeurs, isEmpty,
        reason: 'Laisser une clé derrière, c’est ne pas déconnecter.');
  });

  test('un enregistrement illisible retombe sur l’ancienne clé', () async {
    valeurs[SecurePartnerTokenStore.sessionKey] = 'ceci n’est pas du JSON';
    valeurs[SecurePartnerTokenStore.tokenKey] = 'le-secours';

    expect((await coffre.readSession())?.token, 'le-secours',
        reason: 'Une erreur de format ne doit pas déconnecter.');
  });

  test('un enregistrement sans jeton utilisable est ignoré', () async {
    for (final corps in [
      jsonEncode({'profile': <String, dynamic>{}}),
      jsonEncode({'token': ''}),
      jsonEncode({'token': 42}),
      jsonEncode(['pas', 'un', 'objet']),
    ]) {
      valeurs
        ..clear()
        ..[SecurePartnerTokenStore.sessionKey] = corps;

      expect(await coffre.readSession(), isNull, reason: 'Pour $corps');
    }
  });

  test('un profil non conforme laisse le jeton utilisable', () async {
    valeurs[SecurePartnerTokenStore.sessionKey] =
        jsonEncode({'token': 'jeton-courant', 'profile': 'pas un objet'});

    final session = await coffre.readSession();

    expect(session?.token, 'jeton-courant',
        reason: 'Un profil abîmé ne doit pas coûter la session.');
    expect(session?.profile, isNull);
  });
}
