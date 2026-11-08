/// LA PARITÉ DES DEUX CATALOGUES : `app_fr.arb`, le gabarit, et `app_en.arb`.
///
/// ── POURQUOI UN BANC LIT LES `.arb` ────────────────────────────────────────
///
/// `gen-l10n` ne tire la liste des clés, leurs types et leurs placeholders que
/// du GABARIT (`l10n.yaml` : `template-arb-file: app_fr.arb`). Une clé absente
/// de l'anglais ne produit qu'un avertissement à la génération — noyé dans la
/// sortie de `flutter pub get`, que personne ne lit — et la classe anglaise se
/// replie sur le français : l'écran anglais affiche du français, sans qu'aucun
/// banc ne tombe. Un placeholder que l'anglais n'emploie pas compile tout
/// aussi bien, et la valeur manque simplement à l'écran.
///
/// Aucun banc de widgets ne peut voir cela : ils montent un écran et lisent
/// une clé, et une clé repliée rend bien un texte. C'est le FICHIER qu'il faut
/// lire — comme `accueil_langues_test.dart` lit ses fixtures —, et le comparer
/// à l'autre, nominativement.
///
/// ── CE QUE LE BANC TIENT, ET CE QU'IL NE TIENT PAS ─────────────────────────
///
///  1. Le même ensemble de clés dans les deux catalogues, les manquantes
///     nommées une par une.
///  2. Les mêmes variables `{nom}` dans les deux valeurs d'une même clé — par
///     ENSEMBLE, pas par structure : un pluriel ICU en anglais là où le
///     français écrit « article(s) » est une différence de langue, pas un
///     défaut. Quatre clés le font déjà (`cartItemCountSummary`,
///     `mediaPhotosAdded`, `garageDeadlineOverdue`, `garageDeadlineInDays`).
///  3. Une `description` dans le gabarit pour chaque clé des zones NOUVELLES.
///     151 clés anciennes n'en ont pas, et ce n'est pas ce banc qui les
///     rattrapera : rougir sur le passé n'apprendrait rien à personne. Les
///     zones nommées dans [zonesDecrites] sont tenues depuis leur première
///     clé — elles sont arrivées décrites avec le lot en cours, 42 clés au
///     moment où ce banc est écrit, et c'est ce banc qui les y tient.
///  4. Un RELEVÉ, imprimé et non asserté : le nombre de clés, les valeurs
///     strictement identiques fr == en, et l'inventaire par zone. C'est ce qui
///     permet de tenir `lib/l10n/CONVENTION.md` à jour sans recompter à la
///     main — il disait 1577 clés au 2 novembre 2026.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les préfixes des zones nouvelles, tenues à une `description` dès leur
/// première clé. À allonger quand une zone naît ; jamais à raccourcir.
const List<String> zonesDecrites = [
  'onboardingProfile',
  'partnerDashboard',
  'homeSeller',
  'partnerAccountsClosed',
  'partnerAccountsSellerIntro',
];

Map<String, dynamic> _catalogue(String langue) =>
    jsonDecode(File('lib/l10n/app_$langue.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Les clés de traduction : tout ce qui n'est ni `@@locale` ni une
/// métadonnée `@clé`.
Set<String> _cles(Map<String, dynamic> catalogue) =>
    catalogue.keys.where((cle) => !cle.startsWith('@')).toSet();

/// Les variables d'un message ICU : `{nom}` et `{nom, plural, …}`, à toute
/// profondeur, SANS le texte des branches.
///
/// Une expression régulière sur `{mot}` aurait suffi aujourd'hui, et aurait
/// menti demain : une branche `other{Vehicles}` se lit comme une variable
/// `Vehicles`, et le banc aurait rougi sur un message correct. D'où un
/// parcours qui distingue l'ARGUMENT (`{…}` dans du texte) de la BRANCHE
/// (`sélecteur{…}` dans un pluriel ou un select), dont l'intérieur est du
/// texte et peut porter d'autres arguments. Aucun catalogue n'échappe
/// d'accolade par apostrophe (`'{'`), vérifié : le parcours n'en tient pas
/// compte.
Set<String> variablesDe(String message) {
  final variables = <String>{};
  _lireTexte(message, 0, message.length, variables);

  return variables;
}

/// Du TEXTE — le message entier, ou l'intérieur d'une branche — où chaque
/// `{` ouvre un argument.
void _lireTexte(String s, int debut, int fin, Set<String> variables) {
  var i = debut;
  while (i < fin) {
    if (s[i] != '{') {
      i++;
      continue;
    }
    final ferme = _accoladeFermante(s, i, fin);
    _lireArgument(s, i + 1, ferme, variables);
    i = ferme + 1;
  }
}

/// L'intérieur d'un `{…}` : `nom`, ou `nom, type, branches…`.
void _lireArgument(String s, int debut, int fin, Set<String> variables) {
  final virgule = s.indexOf(',', debut);
  final finNom = virgule == -1 || virgule > fin ? fin : virgule;
  variables.add(s.substring(debut, finNom).trim());
  if (finNom == fin) return; // `{nom}`

  // `nom, plural, …` ou `nom, select, …` : après le type, chaque branche est
  // `sélecteur{texte}`, et le texte peut porter d'autres variables. Un type
  // sans branches (`{date, date}`) n'a rien de plus à lire.
  final apresType = s.indexOf(',', finNom + 1);
  if (apresType == -1 || apresType > fin) return;

  var i = apresType + 1;
  while (i < fin) {
    if (s[i] != '{') {
      i++;
      continue;
    }
    final ferme = _accoladeFermante(s, i, fin);
    _lireTexte(s, i + 1, ferme, variables);
    i = ferme + 1;
  }
}

/// L'indice de l'accolade fermante qui répond à l'ouvrante en [ouvre].
int _accoladeFermante(String s, int ouvre, int fin) {
  var profondeur = 0;
  for (var i = ouvre; i < fin; i++) {
    if (s[i] == '{') profondeur++;
    if (s[i] == '}' && --profondeur == 0) return i;
  }

  throw FormatException('Accolade jamais refermée', s, ouvre);
}

/// Les zones dont le nom a DEUX mots, que la coupure à la première majuscule
/// rangerait sous `partner`, `private`, `password` ou `fault`. Ce sont les
/// lignes de l'inventaire de CONVENTION.md ; une zone oubliée ici coûte une
/// ligne mal rangée dans le relevé, pas un rouge.
const List<String> _zonesComposees = [
  'partnerAccounts',
  'partnerDashboard',
  'privateSales',
  'passwordRecovery',
  'faultDeclaration',
];

/// La zone d'une clé, au sens de CONVENTION.md : le préfixe en minuscules
/// avant le premier rôle en majuscule (`catalogFieldEngine` → `catalog`),
/// sauf pour les zones composées.
String _zoneDe(String cle) {
  for (final zone in _zonesComposees) {
    if (cle.startsWith(zone)) return zone;
  }
  final majuscule = cle.indexOf(RegExp('[A-Z]'));

  return majuscule == -1 ? cle : cle.substring(0, majuscule);
}

void main() {
  final fr = _catalogue('fr');
  final en = _catalogue('en');
  final clesFr = _cles(fr);
  final clesEn = _cles(en);

  group('Parité des catalogues fr et en', () {
    test('les deux catalogues portent les mêmes clés', () {
      final manquentEnAnglais = clesFr.difference(clesEn).toList()..sort();
      final manquentEnFrancais = clesEn.difference(clesFr).toList()..sort();

      expect(
        manquentEnAnglais,
        isEmpty,
        reason:
            "${manquentEnAnglais.length} clé(s) du gabarit n'ont pas de "
            "traduction anglaise — l'écran anglais y affichera du français, "
            'et `gen-l10n` ne le dira que par un avertissement :\n  '
            '${manquentEnAnglais.join('\n  ')}',
      );
      expect(
        manquentEnFrancais,
        isEmpty,
        reason:
            "${manquentEnFrancais.length} clé(s) de l'anglais n'existent pas "
            'dans le gabarit — `gen-l10n` les ignore, donc personne ne les '
            'lira :\n  ${manquentEnFrancais.join('\n  ')}',
      );
    });

    /// Comparé pour TOUTES les clés communes, et pas seulement celles qui
    /// déclarent des `placeholders` : un `{nom}` anglais sans équivalent
    /// français est un défaut quelle que soit la métadonnée, et un `{nom}`
    /// français sans métadonnée reste une variable pour `gen-l10n`.
    test('chaque clé emploie les mêmes variables dans les deux langues', () {
      final ecarts = <String>[];

      for (final cle in clesFr.intersection(clesEn).toList()..sort()) {
        final variablesFr = variablesDe(fr[cle] as String);
        final variablesEn = variablesDe(en[cle] as String);
        if (variablesFr.length == variablesEn.length &&
            variablesFr.containsAll(variablesEn)) {
          continue;
        }

        final absentes = variablesFr.difference(variablesEn);
        final enTrop = variablesEn.difference(variablesFr);
        ecarts.add(
          '$cle : fr {${variablesFr.join(', ')}} contre en '
          '{${variablesEn.join(', ')}}'
          '${absentes.isEmpty ? '' : ' — absentes en anglais : ${absentes.join(', ')}'}'
          '${enTrop.isEmpty ? '' : ' — en trop en anglais : ${enTrop.join(', ')}'}',
        );
      }

      expect(
        ecarts,
        isEmpty,
        reason:
            "${ecarts.length} clé(s) n'emploient pas les mêmes variables dans "
            'les deux langues. Une variable absente en anglais est une valeur '
            "que l'écran anglais n'affiche pas ; une variable en trop ne "
            'correspond à aucun paramètre du gabarit :\n  '
            '${ecarts.join('\n  ')}',
      );
    });

    test('les zones nouvelles décrivent chacune de leurs clés', () {
      final sansDescription = <String>[];

      for (final cle in clesFr.toList()..sort()) {
        if (!zonesDecrites.any(cle.startsWith)) continue;

        final meta = fr['@$cle'];
        final description = meta is Map ? meta['description'] : null;
        if (description is String && description.trim().isNotEmpty) continue;

        sansDescription.add(
          meta == null ? '$cle (pas de @$cle)' : '$cle (description vide)',
        );
      }

      expect(
        sansDescription,
        isEmpty,
        reason:
            '${sansDescription.length} clé(s) des zones ${zonesDecrites.join(', ')} '
            "n'ont pas de `description` dans le gabarit. Le traducteur anglais "
            "et le prochain lecteur n'ont que cette phrase pour savoir OÙ la "
            "chaîne s'affiche et ce qu'elle doit tenir :\n  "
            '${sansDescription.join('\n  ')}',
      );
    });

    /// Imprimé et non asserté : les chiffres bougent à chaque lot de clés, et
    /// un banc qui les figerait rougirait pour une raison qui n'en est pas
    /// une. Ils sont là pour que CONVENTION.md soit tenu à jour.
    test('relevé : clés, valeurs identiques et inventaire par zone', () {
      final communes = clesFr.intersection(clesEn);
      final identiques = communes.where((cle) => fr[cle] == en[cle]).toList()
        ..sort();
      final sansMeta = clesFr.where((cle) => !fr.containsKey('@$cle')).length;

      final parZone = <String, int>{};
      for (final cle in clesFr) {
        parZone.update(_zoneDe(cle), (n) => n + 1, ifAbsent: () => 1);
      }
      final zones = parZone.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // ignore: avoid_print
      print(
        '@@RELEVÉ l10n — ${clesFr.length} clés dans le gabarit français, '
        '${clesEn.length} dans l\'anglais ; '
        '${identiques.length} valeur(s) strictement identique(s) fr == en '
        '(${(100 * identiques.length / communes.length).toStringAsFixed(1)} %) ; '
        '$sansMeta clé(s) du gabarit sans métadonnée @clé.'
        '\n   Identiques : ${identiques.join(', ')}'
        '\n   Par zone : ${zones.map((z) => '${z.key} ${z.value}').join(', ')}',
      );
    });
  });
}
