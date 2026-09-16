import 'package:auto/core/diagnostics/error_journal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le journal d'erreurs, et surtout ce qu'il ne doit pas casser.
///
/// Il existe pour un défaut qui ne s'est montré qu'une fois. S'il devait
/// lui-même perturber le démarrage, ou avaler les erreurs au lieu de les
/// relayer, il coûterait plus qu'il ne rapporte.
///
/// Ces tests tournent sans plateforme : `getDatabasesPath` échoue, le fichier
/// est donc indisponible. C'est précisément le cas à vérifier — l'installation
/// doit aboutir quand même, et les erreurs continuer d'arriver là où elles
/// allaient.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      (call) async => throw MissingPluginException('pas de plateforme en test'),
    );
  });

  test('l\'installation aboutit même sans disque accessible', () async {
    await ErrorJournal.installer();

    expect(ErrorJournal.chemin, isNull);
    expect(FlutterError.onError, isNotNull);
  });

  /// Le point le plus important. Le journal *ajoute* une écriture ; il ne
  /// remplace pas l'affichage. Remplacer `FlutterError.onError` sans rappeler
  /// le gestionnaire précédent ferait disparaître l'écran rouge en
  /// développement et les rapports en production — on perdrait en visibilité
  /// ce qu'on croyait gagner.
  test('le gestionnaire précédent est conservé et rappelé', () async {
    final recu = <String>[];
    final origine = FlutterError.onError;

    FlutterError.onError = (details) => recu.add(details.exceptionAsString());

    await ErrorJournal.installer();

    FlutterError.reportError(FlutterErrorDetails(
      exception: Exception('bruit de fond'),
      library: 'essai',
    ));

    expect(recu, hasLength(1));
    expect(recu.single, contains('bruit de fond'));

    FlutterError.onError = origine;
  });

  test('une erreur consignée ne fait pas échouer l\'appelant', () async {
    await ErrorJournal.installer();

    // Sans fichier, `_consigner` doit se contenter de la console : consigner ne
    // doit jamais devenir la cause d'une erreur.
    expect(
      () => FlutterError.onError!(FlutterErrorDetails(
        exception: Exception('sans disque'),
        stack: StackTrace.current,
        library: 'essai',
      )),
      returnsNormally,
    );
  });

  test('la lecture rend une chaîne vide quand rien n\'est écrit', () async {
    await ErrorJournal.installer();

    expect(await ErrorJournal.lire(), isEmpty);
  });

  /// Sans garde, le second appel enchaînerait notre gestionnaire au premier,
  /// qui est déjà le nôtre : chaque erreur serait consignée deux fois, puis
  /// trois. Le journal deviendrait illisible à mesure qu'on s'en sert.
  test('installer deux fois ne double pas les entrées', () async {
    await ErrorJournal.installer();
    await ErrorJournal.installer();

    final recu = <String>[];
    final apres = FlutterError.onError!;

    FlutterError.onError = (details) {
      recu.add(details.exceptionAsString());
      apres(details);
    };

    FlutterError.reportError(FlutterErrorDetails(
      exception: Exception('une seule fois'),
      library: 'essai',
    ));

    expect(recu, hasLength(1));
  });
}
