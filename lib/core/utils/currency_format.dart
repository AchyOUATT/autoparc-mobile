import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/langue.dart';

/// Les montants en FCFA, dans la langue active.
///
/// ── LE DÉFAUT CORRIGÉ ───────────────────────────────────────────────────────
///
/// `locale: 'fr_FR'` était écrit en dur. Un client anglophone lisait donc
/// « 96 000 FCFA » là où il attend « 96,000 FCFA » : l'espace fine française
/// sépare les milliers, la virgule anglaise aussi, et les deux se lisent de
/// travers dans l'autre langue.
///
/// ── POURQUOI UN RÉGLAGE DE MODULE ET NON UN PARAMÈTRE ───────────────────────
///
/// `formatXof` compte une cinquantaine de sites d'appel, dont deux hors widget
/// — `partage.dart` et `whatsapp_helper.dart` composent des messages sortants
/// et n'ont pas de `BuildContext`. Leur passer la locale ferait cinquante
/// signatures à changer pour un lot de fondation, et deux d'entre elles
/// n'auraient rien à lui donner.
///
/// La locale est donc posée par [definirLocaleMontants], que `AutoParcApp`
/// appelle dans son `build`, avant de rendre son `MaterialApp`. L'ordre n'est
/// pas une convention mais une garantie de Flutter : un parent est construit
/// avant ses enfants, donc tout descendant qui formate un prix pendant cette
/// trame voit la même valeur que `Localizations.localeOf(context)`. Un
/// changement de langue reconstruit `AutoParcApp`, qui repose la valeur, puis
/// tout l'arbre en dessous.
///
/// ── POURQUOI L'ANGLAIS NE PASSE PAS PAR `NumberFormat.currency` ─────────────
///
/// Mesuré, pas supposé :
///
///   NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
///     96000      →  « 96 000 FCFA »       U+202F entre les milliers,
///                                          U+00A0 devant FCFA
///   NumberFormat.currency(locale: 'en',    symbol: 'FCFA', decimalDigits: 0)
///     96000      →  « FCFA96,000 »
///
/// Le motif monétaire anglais place le symbole DEVANT et collé. Personne n'a
/// demandé à déplacer « FCFA » : le franc CFA s'écrit après le montant dans les
/// deux langues sur place, et déplacer le symbole obligerait à remesurer chaque
/// carte du catalogue — c'est le prix qui est la ligne la plus large de la
/// fiche, et il ne se coupe jamais. L'anglais compose donc
/// `decimalPattern('en')` et le même U+00A0 que le français avant le symbole :
/// seule la ponctuation des milliers change, qui est exactement ce qui était
/// demandé.
///
/// Le français, lui, reste sur `NumberFormat.currency` À L'IDENTIQUE. Ce n'est
/// pas de la timidité : `decimalPattern('fr_FR')` rend U+202F entre les
/// milliers comme `currency`, mais il faudrait réécrire l'espace avant FCFA à
/// la main, et des bancs assertent ces caractères un par un. Réécrire la sortie
/// française pour l'esthétique du code aurait fait rouge sur une chaîne que
/// personne ne voulait changer.

/// Le séparateur entre le montant et le symbole : espace insécable U+00A0.
///
/// C'est celui que `NumberFormat.currency(locale: 'fr_FR')` pose déjà. Il est
/// repris en anglais pour que « FCFA » ne puisse pas partir seul à la ligne —
/// un prix coupé en deux est illisible, et c'est la ligne que la fiche ne doit
/// jamais perdre.
const String _avantSymbole = ' ';

const String _symbole = 'FCFA';

final _montantsFrancais = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: _symbole,
  decimalDigits: 0,
);

final _entiersAnglais = NumberFormat.decimalPattern('en');
final _entiersFrancais = NumberFormat.decimalPattern('fr_FR');

/// Vrai quand les montants doivent s'écrire à l'anglaise.
///
/// Le français est le défaut, donc aussi l'état de tout banc qui ne pose pas la
/// locale : les 595 tests existants mesurent la sortie française sans avoir à
/// déclarer quoi que ce soit.
bool _anglais = false;

/// Accorde le format des montants à la langue de l'interface.
///
/// Appelé par `AutoParcApp.build` — voir l'en-tête de ce fichier pour l'ordre
/// de construction dont dépend la justesse de ce réglage.
void definirLocaleMontants(Locale locale) {
  _anglais = locale.languageCode == localeAnglais.languageCode;
}

/// « 3 500 000 FCFA » en français, « 3,500,000 FCFA » en anglais.
String formatXof(double? amount) {
  if (amount == null) return '—';
  final arrondi = amount.round();
  return _anglais
      ? '${_entiersAnglais.format(arrondi)}$_avantSymbole$_symbole'
      : _montantsFrancais.format(arrondi);
}

/// Même résultat que [formatXof] — conservé pour les sites d'appel existants.
String formatXofShort(double? amount) => formatXof(amount);

/// Un entier ponctué comme la langue active : « 246 965 » / « 246,965 ».
///
/// Sert aux kilométrages, qui ne portent pas de symbole monétaire. L'accueil
/// les composait avec une expression régulière et une espace ORDINAIRE, quand
/// le catalogue employait `decimalPattern('fr_FR')` et son espace fine
/// insécable U+202F : le même compteur changeait de forme entre l'accueil et la
/// fiche. Les deux passent désormais par ici.
String formatEntier(num valeur) => _anglais
    ? _entiersAnglais.format(valeur)
    : _entiersFrancais.format(valeur);
