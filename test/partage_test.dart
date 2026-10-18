import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/api/endpoints.dart';
import 'package:auto/core/utils/contact_info.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/core/utils/partage.dart';

/// Ce que lit le destinataire d'un article partagé.
///
/// Le message part dans une conversation WhatsApp, chez quelqu'un qui n'a
/// probablement pas l'application : il doit se suffire à lui-même, et il n'y a
/// pas de second essai. Un « null » au milieu d'un prix, un « · » sans rien
/// derrière, une ligne vide en trop — c'est ce que verra le proche à qui on
/// recommande le magasin.
///
/// Seule la composition du texte est testée ici, et c'est voulu : l'envoi passe
/// par un MethodChannel que `flutter test` n'a pas. Rien dans ce fichier ne
/// touche la plateforme. Ce qui part réellement vers `share_plus` — y compris
/// l'absence de pièce jointe — est vérifié dans `partage_bouton_test.dart`,
/// qui pose un faux gestionnaire sur son canal.
///
/// Les lignes de prix passent par `formatXof` plutôt que par un « 3 000 FCFA »
/// écrit en dur : sous `fr_FR`, `intl` sépare les milliers par un espace
/// insécable étroit (U+202F), pas par l'espace qu'on tape. Le test aurait
/// échoué sur un caractère invisible. Que la séparation existe est vérifié à
/// part, par son propre test.
///
/// Les adresses attendues passent de même par `adresseArticle` et non par une
/// URL écrite en dur : la racine se déduit d'`Endpoints.baseUrl`, donc elle
/// change avec le `--dart-define` du build. Un hôte figé ici ferait tomber la
/// suite chez quiconque compile contre ngrok. Ce qui doit être figé, c'est la
/// *forme* — le segment et l'identifiant —, et c'est ce que ces tests figent.
void main() {
  // ── Le message complet ───────────────────────────────────────────────────

  /// La forme de référence, celle à laquelle tout le reste se compare.
  test('un article entièrement renseigné rend le message complet', () {
    final message = composerMessagePartage(
      titre: 'Cartouche de filtre à huile 04152-YZZA1',
      type: TypeArticle.piece,
      id: 42,
      prix: 3000,
      precisions: ['Filtre à huile', 'Neuf', 'Réf. 04152-YZZA1'],
    );

    expect(message, '''
*Cartouche de filtre à huile 04152-YZZA1*
${formatXof(3000)}
Filtre à huile · Neuf · Réf. 04152-YZZA1

Disponible sur AutoParc :
${adresseArticle(TypeArticle.piece, 42)}''');
  });

  // ── Les précisions, qui manquent souvent ─────────────────────────────────

  /// Un accessoire sans catégorie ni référence : aucune précision à joindre.
  /// Le séparateur ne doit pas rester seul, et la ligne ne doit pas subsister
  /// vide — deux lignes blanches de suite se lisent comme un message tronqué.
  test('un article sans précisions ne laisse ni « · » ni ligne vide en trop', () {
    final message = composerMessagePartage(
      titre: 'Tapis de sol',
      type: TypeArticle.accessoire,
      id: 7,
      prix: 7500,
    );

    expect(message, '''
*Tapis de sol*
${formatXof(7500)}

Disponible sur AutoParc :
${adresseArticle(TypeArticle.accessoire, 7)}''');

    expect(message, isNot(contains('·')));
    expect(message, isNot(contains('\n\n\n')));
  });

  /// Les trois types d'article n'ont pas les mêmes champs renseignés, et les
  /// modèles rendent `null` pour ceux qui manquent. Les interpoler sans les
  /// filtrer écrirait « null » dans la conversation : c'est l'erreur que ce
  /// test interdit.
  test('une précision nulle ou vide disparaît au lieu de s\'afficher', () {
    final message = composerMessagePartage(
      titre: 'Plaquettes de frein avant',
      type: TypeArticle.piece,
      id: 9,
      prix: 18500,
      precisions: ['Freinage', null, '', '   ', 'Neuf'],
    );

    expect(message, contains('Freinage · Neuf'));
    expect(message.toLowerCase(), isNot(contains('null')));
    expect(message, isNot(contains('·  ·')));
    expect(message, isNot(contains(' · \n')));
  });

  // ── Le prix ──────────────────────────────────────────────────────────────

  /// Au Burkina les montants se lisent par tranches de mille. « 3500000 FCFA »
  /// n'est pas un prix, c'est une suite de chiffres : personne ne distingue
  /// trois millions et demi de trente-cinq millions d'un coup d'œil.
  test('le prix est formaté en FCFA, avec l\'espace des milliers', () {
    final message = composerMessagePartage(
      titre: 'Toyota Hilux',
      type: TypeArticle.vehicule,
      id: 3,
      prix: 3500000,
    );

    expect(message, contains('FCFA'));
    // `\s` couvre l'espace insécable étroit que la locale fr_FR utilise comme
    // séparateur : ce qui compte est qu'il y ait une séparation, pas laquelle.
    expect(message, matches(RegExp(r'3\s500\s000\sFCFA')));
    expect(message, isNot(contains('3500000')));
  });

  // ── Le balisage ──────────────────────────────────────────────────────────

  /// Les astérisques sont la mise en gras de WhatsApp. Sans eux le nom de
  /// l'article se noie dans le reste du message.
  test('le titre est encadré d\'astérisques', () {
    final message = composerMessagePartage(
      titre: 'Batterie 12 V 70 Ah',
      type: TypeArticle.piece,
      id: 11,
      prix: 45000,
    );

    expect(message, startsWith('*Batterie 12 V 70 Ah*'));
  });

  // ── Le lien, qui est tout l'enjeu ────────────────────────────────────────

  /// Le message portait auparavant la fiche du magasin d'applications : le
  /// destinataire devait installer l'application, puis retrouver l'article
  /// lui-même. Les pages publiques `/v`, `/p`, `/a` existent, elles portent
  /// les balises Open Graph, et c'est leur adresse qui doit partir — sinon le
  /// travail du serveur n'est lu par personne.
  test('le lien est celui de l\'article, pas celui du magasin', () {
    final message = composerMessagePartage(
      titre: 'Filtre à air',
      type: TypeArticle.piece,
      id: 4500,
      prix: 4500,
    );

    expect(message, contains('Disponible sur AutoParc :'));
    expect(message, endsWith(adresseArticle(TypeArticle.piece, 4500)));
    expect(message, contains('/p/4500'));
    expect(message, isNot(contains('play.google.com')));
  });

  group('l\'adresse construite pour chacun des trois types', () {
    // Le segment vient du serveur et n'est pas négociable : une lettre
    // changée mène à une 404 chez le destinataire, sans que rien ne plante
    // de notre côté. D'où un test par type, segment écrit en clair.
    final segments = <TypeArticle, String>{
      TypeArticle.vehicule: 'v',
      TypeArticle.piece: 'p',
      TypeArticle.accessoire: 'a',
    };

    segments.forEach((type, segment) {
      test('${type.name} → /$segment/{id}', () {
        expect(type.segment, segment);
        expect(adresseArticle(type, 12), '$kSiteUrl/$segment/12');

        final message = composerMessagePartage(
          titre: 'Article',
          type: type,
          id: 12,
          prix: 1000,
        );
        expect(message, endsWith('/$segment/12'));
      });
    });

    /// Trois types, trois adresses distinctes : partager un accessoire ne doit
    /// pas renvoyer vers la pièce portant le même identifiant. Les trois
    /// séquences d'identifiants sont indépendantes côté serveur.
    test('deux types au même identifiant ne donnent pas la même adresse', () {
      final adresses =
          TypeArticle.values.map((t) => adresseArticle(t, 1)).toSet();

      expect(adresses, hasLength(TypeArticle.values.length));
    });
  });

  // ── La racine, déduite de l'API ──────────────────────────────────────────

  group('la racine du site se déduit de l\'adresse de l\'API', () {
    /// Le cas de production. La racine est l'hôte qui sert déjà l'API, sans
    /// son `/api` : un réglage séparé laisserait un build ngrok envoyer des
    /// liens de production dans des conversations de test.
    test('le « /api » final tombe', () {
      expect(
        racineSiteDepuisApi('https://autoparc-backend.onrender.com/api'),
        'https://autoparc-backend.onrender.com',
      );
      expect(racineSiteDepuisApi('http://10.0.2.2:8000/api'),
          'http://10.0.2.2:8000');
      expect(
        racineSiteDepuisApi('https://jujitsu-platinum-glimpse.ngrok-free.dev/api'),
        'https://jujitsu-platinum-glimpse.ngrok-free.dev',
      );
    });

    /// Le cas qui justifie de ne pas couper quatre caractères à l'aveugle :
    /// un `API_BASE_URL` sans suffixe donnerait sinon un hôte tronqué, et
    /// chaque lien partagé mènerait nulle part — sans une seule exception
    /// levée du côté de l'application.
    test('une adresse qui ne finit pas par « /api » reste intacte', () {
      expect(racineSiteDepuisApi('https://autoparc.bf'), 'https://autoparc.bf');
      expect(racineSiteDepuisApi('https://autoparc.bf/v2'),
          'https://autoparc.bf/v2');
      // L'hôte contient « api » sans que le chemin finisse par « /api » : le
      // découpage ne doit pas s'y tromper.
      expect(racineSiteDepuisApi('https://api.autoparc.bf'),
          'https://api.autoparc.bf');
    });

    /// `.../api/` et `.../api` doivent donner la même racine, sans quoi
    /// l'adresse de l'article porterait un `//` au milieu.
    test('la barre finale ne laisse pas de « // » dans l\'adresse', () {
      expect(racineSiteDepuisApi('https://autoparc.bf/api/'),
          'https://autoparc.bf');
      expect(racineSiteDepuisApi('https://autoparc.bf/'), 'https://autoparc.bf');

      expect(adresseArticle(TypeArticle.vehicule, 1).split('://').last,
          isNot(contains('//')));
    });

    /// Mesuré : avec une seule barre retirée, `.../api//` ne finissait plus
    /// par `/api`, ressortait tel quel, et le lien partagé devenait
    /// `https://autoparc.bf/api//v/12` — la racine de l'API, pas celle des
    /// pages publiques. Une 404 chez le destinataire, rien chez l'expéditeur.
    test('plusieurs barres finales tombent toutes', () {
      expect(racineSiteDepuisApi('https://autoparc.bf/api//'),
          'https://autoparc.bf');
      expect(racineSiteDepuisApi('https://autoparc.bf/api///'),
          'https://autoparc.bf');
      expect(racineSiteDepuisApi('https://autoparc.bf//'),
          'https://autoparc.bf');
    });

    /// Une racine d'API qui porte un chemin garde ce chemin : les pages
    /// publiques sont servies par le même montage que l'API, sous le même
    /// préfixe. Figé ici parce que c'est le cas qu'un `API_BASE_URL` versionné
    /// amènerait, et qu'on ne le découvrirait autrement qu'en partageant.
    test('une racine d\'API avec chemin garde son chemin', () {
      expect(racineSiteDepuisApi('https://autoparc.bf/v1/api'),
          'https://autoparc.bf/v1');
      expect(racineSiteDepuisApi('https://autoparc.bf/v1/api/'),
          'https://autoparc.bf/v1');
    });

    /// La racine effectivement utilisée par le partage dérive bien de la
    /// constante de compilation, et non d'une valeur écrite ailleurs : c'est
    /// ce lien-là qui garde ngrok, préproduction et production alignés.
    test('kSiteUrl dérive d\'Endpoints.baseUrl', () {
      expect(kSiteUrl, racineSiteDepuisApi(Endpoints.baseUrl));
      expect(Endpoints.baseUrl, startsWith(kSiteUrl));
      expect(kSiteUrl, isNot(endsWith('/api')));
      expect(kSiteUrl, isNot(endsWith('/')));
    });
  });
}
