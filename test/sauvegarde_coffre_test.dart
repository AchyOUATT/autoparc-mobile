import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android ne doit jamais sauvegarder le coffre chiffré.
///
/// ── LE DÉFAUT QUE CES RÈGLES CORRIGENT ─────────────────────────────────────
///
/// Le personnel se reconnectait à CHAQUE démarrage à froid. Mesuré sur le
/// téléphone du propriétaire le 20/10/2026, application 1.5.0 installée
/// depuis Play :
///
///     E keystore2: Error::Km(r#VERIFICATION_FAILED)
///     E SecureStorageAndroid: EncryptedSharedPreferences initialization failed
///     E SecureStorageAndroid: javax.crypto.AEADBadTagException
///
/// Le manifeste ne déclarait aucune règle de sauvegarde, donc Android
/// sauvegardait le fichier chiffré du coffre — alors que sa clé maîtresse vit
/// dans le Keystore MATÉRIEL et n'est jamais sauvegardée. Restauré sans sa
/// clé, le fichier est illisible pour toujours ; `resetOnError` le vide, le
/// jeton disparaît, et au lancement suivant la boucle se referme.
///
/// ── POURQUOI CE BANC EXISTE ────────────────────────────────────────────────
///
/// Tout le correctif tient en quatre lignes d'XML et deux attributs de
/// manifeste, et RIEN NE LES GARDAIT. Un renommage de fichier, une fusion
/// malheureuse, un `tools:replace` ajouté par une dépendance — et la
/// déconnexion revient sans qu'aucun test ne tombe, sur un symptôme qui met
/// des semaines à être rapporté depuis le terrain.
///
/// C'est exactement la forme de défaut rencontrée deux fois ces jours-ci : un
/// correctif réel, posé au bon endroit, que plus rien ne retient.
///
/// ── LES DEUX NOMS, ET POURQUOI LES DEUX ────────────────────────────────────
///
/// `FlutterSecureStorage` est le coffre courant de flutter_secure_storage
/// 9.2.4 ; `FlutterSecureKeyStorage` l'ancien emplacement de clé, encore
/// présent sur un appareil mis à jour de longue date. Les deux sont relevés
/// dans la source du greffon, pas devinés : un chemin faux n'exclut rien, en
/// silence.

const _coffres = ['FlutterSecureStorage.xml', 'FlutterSecureKeyStorage.xml'];

String _lire(String chemin) {
  final f = File(chemin);
  expect(f.existsSync(), isTrue, reason: '$chemin a disparu.');
  return f.readAsStringSync();
}

void main() {
  group('Android ≤ 30 — backup_rules.xml', () {
    test('les deux coffres sont exclus de la sauvegarde', () {
      final xml = _lire('android/app/src/main/res/xml/backup_rules.xml');

      for (final coffre in _coffres) {
        expect(
          xml,
          contains('<exclude domain="sharedpref" path="$coffre" />'),
          reason: '$coffre redevient sauvegardable : restauré sans sa clé '
              'Keystore, le coffre est illisible et le personnel se '
              'reconnecte à chaque démarrage à froid.',
        );
      }
    });
  });

  group('Android 31+ — data_extraction_rules.xml', () {
    late String xml;

    setUp(() => xml = _lire('android/app/src/main/res/xml/data_extraction_rules.xml'));

    test('les deux sections existent', () {
      // Une seule des deux ne suffit pas : la sauvegarde vers le nuage et le
      // transfert d'appareil à appareil sont deux chemins distincts, et la
      // clé ne suit sur aucun des deux.
      expect(xml, contains('<cloud-backup>'));
      expect(xml, contains('<device-transfer>'));
    });

    test('chaque section exclut les deux coffres', () {
      for (final section in ['cloud-backup', 'device-transfer']) {
        final debut = xml.indexOf('<$section>');
        final fin = xml.indexOf('</$section>');

        expect(debut, greaterThanOrEqualTo(0), reason: 'section $section absente');
        expect(fin, greaterThan(debut));

        final corps = xml.substring(debut, fin);

        for (final coffre in _coffres) {
          expect(
            corps,
            contains('path="$coffre"'),
            reason: '$coffre n’est pas exclu de <$section> : ce chemin-là '
                'restaurerait un coffre illisible.',
          );
        }
      }
    });
  });

  group('Le manifeste désigne bien les deux règles', () {
    test('les deux attributs sont posés', () {
      // Les fichiers peuvent être parfaits : sans ces deux attributs, Android
      // ne les lit jamais et applique sa sauvegarde par défaut.
      final manifeste = _lire('android/app/src/main/AndroidManifest.xml');

      expect(manifeste, contains('android:fullBackupContent="@xml/backup_rules"'));
      expect(
        manifeste,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
    });
  });
}
