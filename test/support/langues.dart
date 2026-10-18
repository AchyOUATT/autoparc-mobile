import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Les deux langues des bancs, et LE PIÈGE QU'ELLES REFERMENT.
///
/// ── POURQUOI CHAQUE COQUE DOIT NOMMER SA LOCALE ─────────────────────────────
///
/// Un `MaterialApp` sans `locale:` choisit tout seul, par
/// `basicLocaleListResolution`, d'après `platformDispatcher.locales`. Dans un
/// banc de widgets, cette liste vaut `[en_US]` par défaut — et
/// `AppLocalizations.supportedLocales`, que `gen-l10n` écrit dans l'ordre
/// alphabétique des `.arb`, commence par `Locale('en')`.
///
/// Conséquence mesurée : une coque qui se contente d'ajouter les délégués, sans
/// `locale:`, mesure l'ANGLAIS. Les 595 tests existants assertent du français ;
/// ils seraient tombés en masse, et — pire — ceux qui ne comparent que des
/// largeurs seraient restés verts en mesurant la mauvaise langue. C'est
/// exactement le défaut que `polices.dart` raconte pour la police de repli :
/// une mesure fausse et verte.
///
/// D'où la règle de ce fichier : **toute coque qui monte un écran traduit
/// nomme sa locale**, même quand c'est le français qu'elle veut.
///
/// L'application, elle, ne dépend pas de cette résolution : elle passe
/// `locale:` explicitement depuis `langueProvider`, et c'est le réglage de
/// l'utilisateur qui décide — voir lib/core/l10n/langue.dart pour la raison de
/// ne pas suivre la locale du système.
const Locale localeFr = Locale('fr');
const Locale localeEn = Locale('en');

/// Les deux langues à parcourir dans un banc de géométrie, nommées pour que le
/// nom du test dise laquelle a échoué.
const Map<String, Locale> langues = <String, Locale>{
  'fr': localeFr,
  'en': localeEn,
};

/// Les chaînes de l'application dans [locale], hors de tout arbre de widgets.
///
/// Permet à un banc d'ASSERTER le texte attendu sans le recopier : une
/// assertion qui réécrirait « Vehicles » à la main passerait encore le jour où
/// l'`.arb` dirait autre chose. Le chargement est synchrone en pratique — les
/// classes générées ne lisent aucun fichier — mais l'API du délégué est
/// asynchrone, d'où la `Future`.
Future<AppLocalizations> chargerTextes(Locale locale) =>
    AppLocalizations.delegate.load(locale);
