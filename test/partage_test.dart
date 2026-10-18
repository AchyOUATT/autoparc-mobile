import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/api/endpoints.dart';
import 'package:auto/core/utils/contact_info.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/core/utils/partage.dart';

import 'support/langues.dart';

/// Ce que lit le destinataire d'un article partagé — et surtout ce qu'il ne
/// doit plus y lire DEUX FOIS.
///
/// ── POURQUOI LE MESSAGE EST SI COURT ────────────────────────────────────────
///
/// Deux lignes, et rien de plus :
///
///     *Mazda CX-9 (2018)* — sur AutoParc
///     https://<racine>/v/86
///
/// Il en portait six — titre, prix, caractéristiques, mention, adresse. Le
/// propriétaire a signalé que « le partage duplique les informations de
/// l'article », et le défaut était de conception. Tant que le lien menait au
/// magasin d'applications, le texte devait tout porter : le destinataire
/// n'avait que lui. Depuis que le lien mène à la page publique, WhatsApp va
/// chercher les balises Open Graph de cette page et affiche sous le message une
/// vignette qui dit DÉJÀ le nom, le prix et les caractéristiques. Vérifié sur
/// les trois types : la page en dit PLUS que le message dans chacun — elle
/// ajoute le fabricant, la garantie et la ville pour une pièce, l'année et
/// l'état pour un véhicule. Le prix et les précisions arrivaient donc deux fois
/// dans la même bulle, et le texte n'apportait rien.
///
/// ── POURQUOI CE FICHIER MONTE LA GARDE ─────────────────────────────────────
///
/// La duplication reviendra au premier qui trouvera le message trop maigre, et
/// elle reviendra EN SILENCE : rien à l'écran de l'application ne la montre.
/// Elle ne se voit que dans une conversation WhatsApp, chez le destinataire —
/// c'est-à-dire nulle part où quelqu'un regarde en travaillant. D'où le
/// renversement des assertions de ce fichier : elles affirmaient la PRÉSENCE du
/// prix et des précisions, elles affirment maintenant leur ABSENCE.
///
/// Ce qu'on perd est connu et borné : quand l'instance gratuite de Render dort,
/// son robot d'aperçu abandonne avant d'avoir lu la page, et le destinataire ne
/// voit que ces deux lignes. Il garde le nom, la provenance et un lien qui
/// marche. La duplication, elle, se voyait à chaque partage réussi.
///
/// ── CE QUI N'EST PAS MESURÉ ICI ────────────────────────────────────────────
///
/// Seule la composition du texte, et c'est voulu : l'envoi passe par un
/// MethodChannel que `flutter test` n'a pas. Ce qui part RÉELLEMENT vers
/// `share_plus` depuis une fiche — mention comprise, absence de pièce jointe
/// comprise — est mesuré dans `partage_bouton_test.dart`, qui pose un faux
/// gestionnaire sur le canal. C'est là que les absences se vérifient sur les
/// champs d'un vrai modèle, et non sur des valeurs choisies par un test.
///
/// Les prix interdits passent par `formatXof` plutôt que par un « 3 000 FCFA »
/// écrit en dur : sous `fr_FR`, `intl` sépare les milliers par un espace
/// insécable étroit (U+202F), pas par l'espace qu'on tape. Une absence assertée
/// sur le mauvais caractère serait verte sans rien mesurer.
///
/// Les adresses attendues passent de même par `adresseArticle` et non par une
/// URL écrite en dur : la racine se déduit d'`Endpoints.baseUrl`, donc elle
/// change avec le `--dart-define` du build. Un hôte figé ici ferait tomber la
/// suite chez quiconque compile contre ngrok. Ce qui doit être figé, c'est la
/// *forme* — le segment et l'identifiant —, et c'est ce que ces tests figent.
void main() {
  /// La mention telle que l'appelant la lit dans les traductions.
  ///
  /// `composerMessagePartage` est PURE — aucun `BuildContext`, donc aucun accès
  /// aux `.arb` —, et c'est ce qui la rend testable sans MethodChannel : la
  /// fiche lui passe la chaîne déjà traduite. Le français ici, parce que c'est
  /// la locale de repli ; que chaque langue sorte bien la sienne est vérifié
  /// par le groupe « la mention suit la langue ».
  const mentionFr = 'sur AutoParc';

  // ── La forme, en entier ──────────────────────────────────────────────────

  /// La référence à laquelle tout le reste se compare. Égalité stricte et non
  /// une série de `contains` : c'est l'égalité qui fait tomber le test le jour
  /// où une troisième ligne revient, quelle qu'elle soit et d'où qu'elle
  /// vienne.
  test('le message tient en deux lignes : titre et mention, puis l\'adresse',
      () {
    final message = composerMessagePartage(
      titre: 'Mazda CX-9 (2018)',
      mentionBoutique: mentionFr,
      type: TypeArticle.vehicule,
      id: 86,
    );

    expect(message, '''
*Mazda CX-9 (2018)* — $mentionFr
${adresseArticle(TypeArticle.vehicule, 86)}''');

    expect(message.split('\n'), hasLength(2));
  });

  // ── La garde : ce que la vignette dit déjà ne revient pas dans le texte ──

  /// **Le point de ce lot.** Les valeurs interdites sont celles des trois
  /// articles de `partage_bouton_test.dart`, aux libellés que l'écran affiche :
  /// ce sont exactement les champs que le message portait avant, et que la
  /// vignette de la page publique porte maintenant.
  ///
  /// La garde existe aussi à ce niveau-ci, et pas seulement sur la fiche :
  /// quelqu'un qui rebrancherait un paramètre `prix` ou `precisions` le
  /// brancherait d'abord ici.
  group('le texte ne redit NI le prix NI les caractéristiques', () {
    final articles = <String,
        ({
          String titre,
          TypeArticle type,
          int id,
          List<String> dejaDansLaVignette,
        })>{
      'pièce': (
        titre: 'Filtre à huile moteur cartouche 04152-YZZA1',
        type: TypeArticle.piece,
        id: 7,
        // Le SKU est dans le NOM de cette pièce — c'est le cas des dix filtres
        // à huile du catalogue. Ce qui doit manquer est donc la précision
        // « Réf. … », et non la suite de caractères : l'interdire ferait tomber
        // le test sur le titre lui-même.
        dejaDansLaVignette: ['Filtration', 'Neuf', 'Réf.'],
      ),
      'accessoire': (
        titre: 'Tapis de sol caoutchouc toutes saisons, jeu de quatre',
        type: TypeArticle.accessoire,
        id: 12,
        dejaDansLaVignette: ['Confort'],
      ),
      'véhicule': (
        titre: 'Hyundai Tucson (2023)',
        type: TypeArticle.vehicule,
        id: 305,
        // « km » et non « 62 400 km » : la fiche ponctue les milliers avec
        // l'espace insécable étroit de `fr_FR`, et une absence assertée sur
        // l'espace qu'on tape passerait sans rien mesurer. L'unité suffit à
        // identifier la ligne de kilométrage, et aucun titre ne la porte.
        dejaDansLaVignette: ['SUV / 4×4', 'Automatique', 'Diesel', 'km'],
      ),
    };

    articles.forEach((nom, article) {
      test('celui d\'une $nom', () {
        final message = composerMessagePartage(
          titre: article.titre,
          mentionBoutique: mentionFr,
          type: article.type,
          id: article.id,
        );

        for (final valeur in article.dejaDansLaVignette) {
          expect(
            message,
            isNot(contains(valeur)),
            reason: '« $valeur » est déjà dans la vignette de la page '
                'publique. Le redire dans le texte, c\'est la duplication que '
                'le propriétaire a signalée — invisible à l\'écran de '
                'l\'application, visible dans la conversation du destinataire.',
          );
        }

        // Le prix sous toutes ses formes : le montant tel que `formatXof` le
        // rend, espace insécable comprise, et le symbole seul — un prix
        // rebranché autrement garderait au moins « FCFA ».
        for (final montant in [formatXof(3000), formatXof(2450000), 'FCFA']) {
          expect(message, isNot(contains(montant)));
        }

        // Les deux restes de l'ancienne forme : le séparateur des précisions,
        // et la ligne qui annonçait le lien.
        expect(message, isNot(contains('·')));
        expect(message, isNot(contains('Disponible sur AutoParc')));

        // Deux lignes, et la seconde est l'adresse : toute information
        // rebranchée en ajouterait une, où qu'elle soit insérée.
        expect(message.split('\n'), hasLength(2));
        expect(
          message.split('\n').last,
          adresseArticle(article.type, article.id),
        );
      });
    });
  });

  // ── La mention, et la langue qu'elle suit ────────────────────────────────

  /// La mention est tout ce qui reste du texte autour du lien, et elle sert
  /// précisément quand l'aperçu échoue : sans elle, le destinataire a une
  /// adresse nue et rien qui dise d'où vient le lien.
  group('la mention suit la langue', () {
    /// Les deux chaînes attendues, écrites en clair. C'est le CONTRAT des deux
    /// `.arb` : une assertion qui se contenterait de relire la clé resterait
    /// verte le jour où l'anglais rendrait le texte français.
    const mentions = <String, String>{
      'fr': 'sur AutoParc',
      'en': 'on AutoParc',
    };

    langues.forEach((nom, locale) {
      test(nom, () async {
        final textes = await chargerTextes(locale);

        expect(textes.partageMentionBoutique, mentions[nom]);

        final message = composerMessagePartage(
          titre: 'Mazda CX-9 (2018)',
          // La clé relue, et non la chaîne recopiée : c'est le chemin que la
          // fiche emprunte, via `partagerArticle`.
          mentionBoutique: textes.partageMentionBoutique,
          type: TypeArticle.vehicule,
          id: 86,
        );

        expect(message, startsWith('*Mazda CX-9 (2018)* — ${mentions[nom]}'));

        // L'autre langue n'a rien à faire là : un repli qui rendrait toujours
        // le français ne se verrait pas autrement.
        for (final autre in mentions.entries.where((e) => e.key != nom)) {
          expect(message, isNot(contains(autre.value)));
        }
      });
    });
  });

  // ── Le balisage ──────────────────────────────────────────────────────────

  /// Les astérisques sont la mise en gras de WhatsApp ; ailleurs — SMS,
  /// Facebook, presse-papier — ils s'affichent tels quels, deux caractères
  /// inoffensifs. Le titre est désormais la seule information du message :
  /// sans le gras, il se lit comme la première moitié d'une phrase coupée.
  test('le titre est encadré d\'astérisques, la mention vient après le tiret',
      () {
    final message = composerMessagePartage(
      titre: 'Batterie 12 V 70 Ah',
      mentionBoutique: mentionFr,
      type: TypeArticle.piece,
      id: 11,
    );

    expect(message, startsWith('*Batterie 12 V 70 Ah* — $mentionFr'));
  });

  /// Une désignation venue de l'API peut porter une espace de queue, et
  /// l'astérisque de fermeture se retrouverait derrière elle. WhatsApp ne rend
  /// PAS le gras quand une espace précède l'astérisque fermant : le titre
  /// s'afficherait entouré de deux astérisques nus, sans que rien ne change de
  /// notre côté.
  test('les espaces de bord du titre tombent avant l\'astérisque', () {
    final message = composerMessagePartage(
      titre: '  Tapis de sol  ',
      mentionBoutique: mentionFr,
      type: TypeArticle.accessoire,
      id: 7,
    );

    expect(message, startsWith('*Tapis de sol* — $mentionFr'));
  });

  // ── Le lien, qui est tout l'enjeu ────────────────────────────────────────

  /// Le message portait auparavant la fiche du magasin d'applications : le
  /// destinataire devait installer l'application, puis retrouver l'article
  /// lui-même. Les pages publiques `/v`, `/p`, `/a` existent, elles portent les
  /// balises Open Graph, et c'est leur adresse qui doit partir — sinon le
  /// travail du serveur n'est lu par personne, et le texte allégé ne laisse
  /// plus rien à la place.
  test('le lien est celui de l\'article, pas celui du magasin', () {
    final message = composerMessagePartage(
      titre: 'Filtre à air',
      mentionBoutique: mentionFr,
      type: TypeArticle.piece,
      id: 4500,
    );

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
          mentionBoutique: mentionFr,
          type: type,
          id: 12,
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
      expect(racineSiteDepuisApi('https://autoparc.bf//'), 'https://autoparc.bf');
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
