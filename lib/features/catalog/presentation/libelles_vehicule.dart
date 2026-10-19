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
