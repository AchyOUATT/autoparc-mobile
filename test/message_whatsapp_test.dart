import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/core/utils/whatsapp_helper.dart';
import 'package:auto/features/cart/data/models/cart_item.dart';

import 'support/langues.dart';

/// LE MESSAGE DE COMMANDE, ET POURQUOI IL N'AVAIT AUCUNE GARDE.
///
/// ── CE QUE CE FICHIER VERROUILLE ───────────────────────────────────────────
///
/// `buildWhatsAppMessage` est l'ACTION PRINCIPALE du panier : c'est ce qui
/// part réellement vers la boutique quand le client appuie sur « Commander
/// via WhatsApp ». Avant ce fichier, aucun banc du dépôt ne la touchait —
/// `grep` sur `test/` ne rendait ni `buildWhatsAppMessage`, ni
/// `LibellesCommande`, ni « Sous-total HT ». La fonction a été réécrite deux
/// fois pendant la traduction, et les deux fois sans témoin.
///
/// Elle est pourtant la moitié VÉRIFIABLE de ce chemin, et la seule : l'envoi
/// passe par `canLaunchUrl`, donc par un canal de plateforme que
/// `flutter test` n'a pas. Le texte, lui, se compose en une ligne sans
/// `BuildContext` — c'est exactement l'arbitrage que `whatsapp_helper.dart`
/// explique, et ce fichier en est la contrepartie.
///
/// ── LE DÉFAUT QU'IL AURAIT ATTRAPÉ ─────────────────────────────────────────
///
/// Le passage aux `.arb` a remplacé l'alignement écrit à la main
/// — « TVA           : », compté sur « Sous-total HT » — par un
/// `padRight(largeur)`. Sur les deux premières lignes c'était équivalent au
/// caractère près. Sur la TROISIÈME, l'astérisque du gras WhatsApp n'était
/// plus compté dans la colonne : le préfixe « *Total TTC    : » passait de 16
/// à 17 caractères, et le français du message gagnait un espace sur sa ligne
/// la plus lue, celle du montant à payer. Personne ne l'avait décidé, et rien
/// ne l'aurait signalé.
///
/// D'où la forme des assertions : le message ENTIER, écrit en clair, et non
/// une suite de `contains`. Un `contains` sur « Sous-total HT » serait resté
/// vert pendant tout ce glissement.
///
/// ── POURQUOI LES MONTANTS NE SONT PAS RECOPIÉS ─────────────────────────────
///
/// Les prix attendus passent par `formatXof` plutôt que par un « 18 000 FCFA »
/// tapé ici : sous `fr_FR`, `intl` sépare les milliers par une espace fine
/// insécable U+202F et pose U+00A0 devant « FCFA ». Une attente écrite avec
/// les espaces du clavier serait rouge sans qu'aucun défaut existe — ou, pire,
/// verte sur le mauvais caractère. Même raison que `partage_test.dart`.
///
/// La LANGUE des montants, elle, est bien assertée : `definirLocaleMontants`
/// est appelée avant chaque cas, comme `AutoParcApp.build` le fait en
/// production, et le test vérifie que la ponctuation des milliers a suivi.
void main() {
  /// Deux articles, dont un sans référence : la référence est optionnelle sur
  /// le modèle, et sa parenthèse est le seul morceau conditionnel de la ligne.
  final articles = <CartItem>[
    const CartItem(
      id: 1,
      sku: '04152-YZZA1',
      name: 'Filtre à huile moteur cartouche',
      unitPriceHt: 4500,
      unitPriceTtc: 5310,
      currency: 'XOF',
      itemType: CartItemType.part,
      quantity: 2,
    ),
    const CartItem(
      id: 2,
      sku: null,
      name: 'Tapis de sol caoutchouc',
      unitPriceHt: 18000,
      unitPriceTtc: 21240,
      currency: 'XOF',
      itemType: CartItemType.accessory,
    ),
  ];

  /// Les cinq intitulés LUS DANS LES `.arb`, et non recopiés : c'est le chemin
  /// exact que `cart_page.dart` emprunte — mêmes clés, même ordre.
  Future<LibellesCommande> libelles(locale) async {
    final t = await chargerTextes(locale);
    return LibellesCommande(
      entete: t.cartWhatsAppHeader,
      sousTotal: t.cartSubtotalExclTax,
      taxe: t.cartVat,
      total: t.cartTotalInclTax,
      pied: t.cartWhatsAppFooter,
    );
  }

  // ── Le message entier, dans les deux langues ─────────────────────────────

  group('le message entier', () {
    test('fr', () async {
      definirLocaleMontants(localeFr);

      final message = buildWhatsAppMessage(articles, await libelles(localeFr));

      expect(
        message,
        '*Demande de commande — AutoParc*\n'
        '\n'
        '• 2× Filtre à huile moteur cartouche (04152-YZZA1) → '
        '${formatXof(9000)}\n'
        '• 1× Tapis de sol caoutchouc → ${formatXof(18000)}\n'
        '\n'
        'Sous-total HT : ${formatXof(27000)}\n'
        'TVA           : ${formatXof(4860)}\n'
        '*Total TTC    : ${formatXof(31860)}*\n'
        '\n'
        'Merci de confirmer la disponibilité.',
      );
    });

    test('en', () async {
      definirLocaleMontants(localeEn);

      final message = buildWhatsAppMessage(articles, await libelles(localeEn));

      expect(
        message,
        '*Order request — AutoParc*\n'
        '\n'
        '• 2× Filtre à huile moteur cartouche (04152-YZZA1) → '
        '${formatXof(9000)}\n'
        '• 1× Tapis de sol caoutchouc → ${formatXof(18000)}\n'
        '\n'
        'Subtotal excl. VAT : ${formatXof(27000)}\n'
        'VAT                : ${formatXof(4860)}\n'
        '*Total incl. VAT   : ${formatXof(31860)}*\n'
        '\n'
        'Please confirm availability.',
      );
    });
  });

  // ── La colonne du deux-points ────────────────────────────────────────────

  /// L'ASTÉRISQUE COMPTE POUR UNE COLONNE, et c'est ce test qui l'affirme
  /// indépendamment du texte des intitulés. Les trois lignes du décompte
  /// ouvrent leur deux-points au MÊME rang, gras compris : c'est la seule
  /// assertion qui survivrait à un changement de libellé dans les `.arb`.
  group('les trois deux-points s\'ouvrent au même rang', () {
    for (final langue in langues.entries) {
      test(langue.key, () async {
        definirLocaleMontants(langue.value);

        final message = buildWhatsAppMessage(
          articles,
          await libelles(langue.value),
        );

        // Les trois lignes du décompte : celles qui portent « : » et viennent
        // après la ligne vide qui suit les articles. Repérées par leur rang
        // depuis la fin — pied, ligne vide, total, taxe, sous-total — plutôt
        // que par leur texte, qui change avec la langue.
        final lignes = message.split('\n');
        final decompte = lignes.sublist(lignes.length - 5, lignes.length - 2);

        final rangs = decompte.map((l) => l.indexOf(' : ')).toList();

        expect(
          rangs.toSet().length,
          1,
          reason:
              'Les deux-points du décompte ne s\'ouvrent pas au même rang : '
              '$rangs pour\n${decompte.join("\n")}\n'
              'L\'astérisque du gras WhatsApp occupe une colonne sur la ligne '
              'du total ; c\'est le `largeur - 1` de `buildWhatsAppMessage` '
              'qui la lui rend.',
        );

        // La ligne du total est bien celle en gras, et c'est elle qui portait
        // le décalage : l'assertion ci-dessus ne vaut que si elle est dedans.
        expect(decompte.last, startsWith('*'));
        expect(decompte.last, endsWith('*'));
      });
    }
  });

  // ── La langue des montants ───────────────────────────────────────────────

  /// `formatXof` lit un réglage de MODULE, posé par `AutoParcApp.build`. Un
  /// message composé pendant que ce réglage est resté sur l'autre langue
  /// mélangerait des intitulés anglais et des milliers séparés à la française.
  /// Ces deux cas montent la garde sur la ponctuation elle-même, caractère par
  /// caractère, parce que c'est elle qui se lit de travers : « 27 000 » et
  /// « 27,000 » ne sont pas le même nombre pour tout le monde.
  group('les milliers suivent la langue', () {
    test('fr : espace fine insécable U+202F', () async {
      definirLocaleMontants(localeFr);
      final message = buildWhatsAppMessage(articles, await libelles(localeFr));

      expect(message, contains('27 000'));
      expect(message, isNot(contains('27,000')));
    });

    test('en : virgule des milliers', () async {
      definirLocaleMontants(localeEn);
      final message = buildWhatsAppMessage(articles, await libelles(localeEn));

      expect(message, contains('27,000'));
      expect(message, isNot(contains('27 000')));
    });
  });

  // Le réglage de module est global : le laisser en anglais ferait dépendre
  // les fichiers suivants de l'ordre d'exécution. Il est remis au français,
  // qui est la locale de repli de l'application.
  tearDownAll(() => definirLocaleMontants(localeFr));
}
