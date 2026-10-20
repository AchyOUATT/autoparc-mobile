// Effacer une recherche doit VRAIMENT l'effacer, sur les trois listes.
//
// ── LE DÉFAUT, SIGNALÉ PAR LE PROPRIÉTAIRE ─────────────────────────────────
//
// « Après une recherche dans la barre de recherche de véhicules je ne retrouve
// plus tous les véhicules, d'autres ne s'affichent plus. »
//
// Les trois `copyWith` de `catalog_providers.dart` suivent la même convention :
// un paramètre à `null` signifie « ne change pas », et l'effacement passe par
// un drapeau `clearX` séparé. C'est une convention saine — elle distingue
// « je ne touche pas à ce champ » de « je le vide » — mais elle a un piège :
// `copyWith(search: null)` ne fait RIEN, et ne lève pas.
//
// Les trois pages écrivaient `copyWith(search: q.isEmpty ? null : q)`. Vider le
// champ au clavier laissait donc le terme précédent en place, et la liste
// restait filtrée sur une recherche que l'utilisateur voyait effacée.
//
// Deux aggravations, trouvées en corrigeant :
//   — sur la liste des PIÈCES, `PartFilter` n'avait ni `clearSearch` ni
//     `clearOem`. Son bouton « ✕ » appelait `copyWith(search: null)`, donc
//     lui non plus ne nettoyait rien : la recherche y était DÉFINITIVEMENT
//     coincée, au clavier comme au bouton ;
//   — sur les véhicules et les accessoires, le bouton « ✕ » passait bien
//     `clearSearch`. Ce chemin-là marchait, et c'est précisément ce qui
//     masquait le défaut : deux façons d'exprimer la même intention, une
//     seule correcte.
//
// ── POURQUOI CE BANC PORTE SUR LES FILTRES ET NON SUR LES ÉCRANS ───────────
//
// Le défaut vit dans la composition `copyWith` + site d'appel, pas dans le
// rendu. Un test d'écran aurait dû monter une liste, taper, effacer, et
// observer une requête — long, et il n'aurait pas couvert `clearOem`, qui n'a
// aucun champ dédié dans l'interface aujourd'hui mais que la recherche par
// référence OEM utilise.
//
// Les assertions portent donc sur le contrat des trois filtres, à l'endroit
// exact où il s'est révélé faux.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';

void main() {
  // ── LA GARDE QUI PORTE SUR LE DÉFAUT RÉEL ────────────────────────────────
  //
  // Les tests de contrat ci-dessous décrivent `copyWith`, qui n'a jamais été
  // faux : le défaut vivait dans les trois PAGES, qui appelaient
  // `copyWith(search: null)` en croyant effacer. Une garde posée uniquement
  // sur le filtre serait restée verte pendant toute la durée du défaut — et
  // resterait verte si quelqu'un réécrivait l'ancien appel demain.
  //
  // D'où une lecture des sources. C'est inhabituel, et c'est assumé : le
  // défaut n'est pas un comportement mais une TOURNURE D'ÉCRITURE qui ne lève
  // pas, ne compile pas moins bien, et ne se voit qu'à l'usage. Un test de
  // widget serait plus noble mais devrait monter trois listes et simuler une
  // API pour attraper ce qu'une ligne de texte dit directement.
  group('Aucune page ne croit effacer avec `null`', () {
    const pages = [
      'lib/features/catalog/presentation/pages/vehicle_list_page.dart',
      'lib/features/catalog/presentation/pages/part_list_page.dart',
      'lib/features/catalog/presentation/pages/accessory_list_page.dart',
    ];

    for (final chemin in pages) {
      test(chemin.split('/').last, () {
        final source = File(chemin).readAsStringSync();

        // Le fichier doit exister : un chemin devenu faux rendrait ce test
        // vert sans rien vérifier, ce qui est le défaut qu'il surveille.
        expect(source, isNotEmpty, reason: '$chemin est introuvable ou vide.');

        for (final tournure in ['search: q.isEmpty', 'copyWith(search: null)', 'copyWith(oem: null)']) {
          expect(
            source.contains(tournure),
            isFalse,
            reason: 'Dans $chemin, « $tournure » ne fait RIEN : le `copyWith` de ce '
                'dépôt traite `null` comme « ne change pas ». Utiliser '
                '`clearSearch: true` ou `clearOem: true`.',
          );
        }

        // Et la tournure juste doit être présente, sinon le test passerait
        // sur une page qui n'effacerait plus du tout.
        expect(
          source.contains('clearSearch: true'),
          isTrue,
          reason: '$chemin n\'efface plus sa recherche nulle part.',
        );
      });
    }
  });

  group('Effacer une recherche la retire vraiment du filtre', () {
    test('véhicules : le drapeau efface, et `null` seul ne suffit pas', () {
      const avec = VehicleFilter(search: 'hilux');

      // Le comportement qui a causé le défaut, VÉRIFIÉ et non supposé : il est
      // important qu'il reste tel quel. La convention `null` = « ne change
      // pas » est volontaire ; c'est le site d'appel qui avait tort.
      expect(
        avec.copyWith(search: null).search,
        'hilux',
        reason: 'La convention a changé : `null` doit signifier « ne change pas ». '
            'Si elle a changé exprès, les trois pages doivent être relues.',
      );

      expect(avec.copyWith(clearSearch: true).search, isNull);
    });

    test('accessoires : même contrat', () {
      const avec = AccessoryFilter(search: 'tapis');

      expect(avec.copyWith(search: null).search, 'tapis');
      expect(avec.copyWith(clearSearch: true).search, isNull);
    });

    test('pièces : `clearSearch` et `clearOem` existent et effacent', () {
      const avec = PartFilter(search: 'filtre', oem: '04152-YZZA1');

      expect(avec.copyWith(search: null).search, 'filtre');
      expect(avec.copyWith(oem: null).oem, '04152-YZZA1');

      // Les deux drapeaux manquaient entièrement à `PartFilter` : c'est ce qui
      // rendait la recherche de pièces inéffaçable même par le bouton.
      expect(avec.copyWith(clearSearch: true).search, isNull);
      expect(avec.copyWith(clearOem: true).oem, isNull);
    });

    test('effacer un champ ne touche pas les autres', () {
      // La raison d'être de la convention : un `copyWith` qui viderait tout
      // dès qu'on omet un argument perdrait la carrosserie choisie à chaque
      // frappe dans la barre de recherche.
      const filtre = VehicleFilter(
        search: 'prado',
        bodyStyle: 'suv',
        city: 'Ouagadougou',
      );

      final apres = filtre.copyWith(clearSearch: true);

      expect(apres.search, isNull);
      expect(apres.bodyStyle, 'suv');
      expect(apres.city, 'Ouagadougou');
    });

    test('pièces : effacer la recherche garde la référence OEM, et l\'inverse', () {
      const filtre = PartFilter(search: 'filtre', oem: '90915-YZZN1', inStockOnly: true);

      final sansRecherche = filtre.copyWith(clearSearch: true);
      expect(sansRecherche.search, isNull);
      expect(sansRecherche.oem, '90915-YZZN1');
      expect(sansRecherche.inStockOnly, isTrue);

      final sansOem = filtre.copyWith(clearOem: true);
      expect(sansOem.oem, isNull);
      expect(sansOem.search, 'filtre');
    });
  });
}
