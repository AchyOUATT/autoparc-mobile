/// Les libellés que le serveur ne rend pas déjà rédigés.
///
/// `engineType` arrive libellé (« Essence », « Électrique »…), la transmission
/// non : elle voyage en code (`manual` / `automatic` / `cvt`). La traduction
/// vivait dans `vehicle_detail_page.dart`, en privé. La carte de la grille en a
/// besoin depuis qu'elle affiche la boîte de vitesses en colonne unique, et
/// recopier le `switch` aurait laissé deux tables divergeant en silence —
/// c'est exactement ce qui s'était produit pour les libellés de carrosserie
/// entre le formulaire d'enregistrement et la fiche.
String libelleTransmission(String code) => switch (code) {
      'manual'    => 'Manuelle',
      'cvt'       => 'CVT',
      'automatic' => 'Automatique',
      _           => code,
    };
