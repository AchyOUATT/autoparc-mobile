import '../../../l10n/app_localizations.dart';

/// Les libellés que le serveur ne rend pas déjà rédigés.
///
/// `engineType` arrive libellé (« Essence », « Électrique »…), la transmission
/// non : elle voyage en code (`manual` / `automatic` / `cvt`). La traduction
/// vivait dans `vehicle_detail_page.dart`, en privé, et a été sortie ici quand
/// la carte de la grille s'est mise à afficher la boîte de vitesses.
///
/// ELLE NE L'AFFICHE PLUS, et le constat est fait ici plutôt que laissé à
/// l'écart : la carte a perdu la boîte quand sa ligne de caractéristiques est
/// passée à deux valeurs — `carte_geometrie_test.dart` l'y vérifie nommément,
/// « la boîte de vitesses reste hors de la ligne de caractéristiques ». Ce
/// fichier n'a donc plus qu'UN appelant, la ligne « Boîte » de la fiche. Il
/// reste séparé parce que la raison d'origine n'a pas disparu : recopier le
/// `switch` laisserait deux tables divergeant en silence —
/// c'est exactement ce qui s'était produit pour les libellés de carrosserie
/// entre le formulaire d'enregistrement et la fiche.
///
/// Depuis la vague 2, le libellé vient des `.arb` et la fonction demande donc
/// les traductions actives. Elle ne peut pas les lire elle-même : un
/// `BuildContext` ne traverse pas une fonction de niveau supérieur, et le seul
/// appelant est une ligne de la fiche qui en a déjà un sous la main.
String libelleTransmission(AppLocalizations l10n, String code) =>
    switch (code) {
      'manual' => l10n.catalogTransmissionManual,
      'cvt' => l10n.catalogTransmissionCvt,
      'automatic' => l10n.catalogTransmissionAutomatic,
      _ => code,
    };

/// La finition telle qu'une CARTE doit l'afficher : sans sa parenthèse.
///
/// ── POURQUOI UNE PARENTHÈSE EXISTE DANS CES NOMS ──────────────────────────
///
/// Le référentiel dédouble un nom de finition quand la même désignation couvre
/// deux voitures mécaniquement différentes sur UNE SEULE génération. La BMW
/// Série 5 F10 en est le cas d'école : « 528i » y désigne un six cylindres
/// 2996 N52B30 jusqu'en 09/2011, puis un QUATRE cylindres 1997 N20B20 turbo.
/// Les deux rendent 245 ch — la puissance ne les distingue pas — et l'index
/// unique `(vehicle_model_id, name)` interdit deux lignes homonymes. D'où
/// « 528i (6 cyl. 2010-2011) » et « 528i (4 cyl. 2011-2016) ».
///
/// Cette précision n'est pas décorative : vendre le mauvais filtre à huile se
/// termine par un moteur vidé, et c'est tout l'objet du dédoublement.
///
/// ── POURQUOI LA CARTE NE LA MONTRE PAS ────────────────────────────────────
///
/// Vingt-trois caractères sur une carte que plusieurs lots ont servi à
/// désencombrer, et qui se couperait sous la règle du propriétaire — on tient
/// jusqu'à l'échelle 1,5. Arbitrage du propriétaire, à qui les trois options
/// ont été posées : « n'afficher que la partie avant la parenthèse ».
///
/// La fiche détaillée, elle, garde le nom ENTIER. C'est elle qu'on lit avant
/// d'acheter une pièce, et c'est là que la distinction doit rester lisible.
///
/// ── CE QUE CETTE FONCTION NE FAIT PAS ─────────────────────────────────────
///
/// Elle ne coupe que sur une parenthèse OUVRANTE précédée d'un espace. Un nom
/// qui en porterait une sans espace — « 528i(4cyl) » — ou des parenthèses au
/// milieu d'une désignation légitime n'est pas touché : mieux vaut un libellé
/// un peu long qu'un libellé amputé de ce qui le nommait.
String finitionCourte(String? finition) {
  final nom = finition?.trim() ?? '';

  if (nom.isEmpty) return '';

  final coupe = nom.indexOf(' (');

  // `coupe <= 0` et non `== -1` : un nom qui COMMENCE par une parenthèse n'a
  // rien devant elle, et le raccourcir rendrait une chaîne vide — une carte
  // sans finition plutôt qu'une finition longue, ce qui est pire.
  return coupe <= 0 ? nom : nom.substring(0, coupe).trimRight();
}
