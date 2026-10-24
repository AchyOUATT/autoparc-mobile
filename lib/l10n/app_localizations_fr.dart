// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonHome => 'Accueil';

  @override
  String get commonVehicles => 'Véhicules';

  @override
  String get commonAccessories => 'Accessoires';

  @override
  String get commonParts => 'Pièces';

  @override
  String get partageMentionBoutique => 'sur AutoParc';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonMenuTooltip => 'Menu';

  @override
  String get commonPerDaySuffix => '/j';

  @override
  String commonMileageKm(String value) {
    return '$value km';
  }

  @override
  String get commonShareUnavailable =>
      'Impossible d\'ouvrir le partage sur cet appareil. Le message a été copié.';

  @override
  String commonLinkUnavailable(String what, String value) {
    return 'Impossible d\'ouvrir $what sur cet appareil. $value a été copié.';
  }

  @override
  String get shellExitTitle => 'Quitter AutoParc ?';

  @override
  String get shellExitBody => 'Voulez-vous fermer l\'application ?';

  @override
  String get shellExitConfirm => 'Quitter';

  @override
  String get shellAccountGuest => 'Visiteur';

  @override
  String shellAccountStaff(String role) {
    return 'Personnel — $role';
  }

  @override
  String get shellAccountNotSignedIn => 'Non connecté';

  @override
  String get shellClientNeeds => 'Besoins clients';

  @override
  String get shellPartners => 'Partenaires';

  @override
  String get shellNotifications => 'Notifications';

  @override
  String get shellRefreshCatalog => 'Rafraîchir le catalogue';

  @override
  String get shellCatalogRefreshed => 'Catalogue mis à jour';

  @override
  String get shellMyGarage => 'Mon Garage';

  @override
  String get shellMyNeeds => 'Mes besoins';

  @override
  String get shellContact => 'Nous contacter';

  @override
  String get shellSignIn => 'Se connecter';

  @override
  String get shellSignOut => 'Se déconnecter';

  @override
  String get shellSignedOut => 'Vous êtes déconnecté.';

  @override
  String get shellContactPhone => 'Téléphone';

  @override
  String get shellContactEmail => 'Email';

  @override
  String get shellContactDialerTarget => 'le composeur';

  @override
  String get shellContactMailTarget => 'la messagerie';

  @override
  String get shellLanguage => 'Langue';

  @override
  String get updateAction => 'Mettre à jour';

  @override
  String get updateStoreTarget => 'la fiche de l\'application';

  @override
  String get catalogPartListTitle => 'Pièces détachées';

  @override
  String get catalogCompatibilitySeparator => ' · ';

  @override
  String catalogCompatibilityMore(int count) {
    return '+$count';
  }

  @override
  String get catalogNeedTooltip => 'Exprimer un besoin';

  @override
  String get catalogNeedCta => 'Dites-nous ce que vous cherchez';

  @override
  String get catalogClearFilters => 'Tout effacer';

  @override
  String get catalogPricesIncludeVat => 'Prix TTC';

  @override
  String catalogResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '$count résultat',
    );
    return '$_temp0';
  }

  @override
  String catalogResultTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '$count résultat',
    );
    return '— $_temp0 au total —';
  }

  @override
  String catalogActiveFilters(String terms) {
    return 'Filtres actifs : $terms.';
  }

  @override
  String get catalogFilterListSeparator => ', ';

  @override
  String catalogFilterTermQuery(String query) {
    return '« $query »';
  }

  @override
  String get catalogVehicleAddCta => 'Ajouter';

  @override
  String get catalogVehicleSearchHint => 'Marque, modèle…';

  @override
  String get catalogFilterGroupOffer => 'Offre';

  @override
  String get catalogFilterGroupType => 'Type';

  @override
  String get catalogFilterGroupCity => 'Ville';

  @override
  String get catalogFilterGroupBodyStyle => 'Carrosserie';

  @override
  String get catalogOfferSale => 'À vendre';

  @override
  String get catalogOfferRent => 'À louer';

  @override
  String get catalogOfferBoth => 'Vente & Location';

  @override
  String get catalogOfferNone => 'Indisponible';

  @override
  String get catalogDealFilter => 'Bonne affaire';

  @override
  String catalogDealFilterCount(int count) {
    return 'Bonne affaire ($count)';
  }

  @override
  String get catalogCustomsCleared => 'Dédouané';

  @override
  String get catalogRegistered => 'Immatriculé';

  @override
  String get catalogNotRegistered => 'Non immatriculé';

  @override
  String get catalogFilterGroupPapers => 'Papiers';

  @override
  String get catalogVehicleTypeUtility => 'Utilitaire';

  @override
  String get catalogVehicleTypeHeavy => 'Poids lourd';

  @override
  String get catalogBodyStyleSedan => 'Berline';

  @override
  String get catalogBodyStyleSuv => 'SUV / 4×4';

  @override
  String get catalogBodyStyleHatchback => 'Citadine';

  @override
  String get catalogBodyStylePickup => 'Pickup';

  @override
  String get catalogBodyStyleMinibus => 'Minibus';

  @override
  String get catalogBodyStyleBus => 'Bus / Car';

  @override
  String get catalogBodyStyleVan => 'Fourgon';

  @override
  String get catalogBodyStyleEstate => 'Break';

  @override
  String get catalogBodyStyleTruck => 'Camion';

  @override
  String get catalogBodyStyleConvertible => 'Cabriolet';

  @override
  String get catalogBodyStyleCoupe => 'Coupé';

  @override
  String catalogPhotoCount(int count) {
    return '$count photos';
  }

  @override
  String get catalogPriceOnRequest => 'Prix non communiqué';

  @override
  String get catalogVehicleNoneFound => 'Aucun véhicule trouvé';

  @override
  String get catalogVehicleCatalogEmpty =>
      'Le catalogue ne contient aucun véhicule pour le moment.';

  @override
  String get catalogFilterTermSale => 'à vendre';

  @override
  String get catalogFilterTermRent => 'à louer';

  @override
  String get catalogFilterTermDeal => 'bonne affaire';

  @override
  String get catalogFilterTermCustoms => 'dédouané';

  @override
  String get catalogFilterTermVehicleType => 'type de véhicule';

  @override
  String get catalogFilterTermBodyStyle => 'carrosserie';

  @override
  String get catalogFilterTermCondition => 'état';

  @override
  String get catalogFilterTermYear => 'année';

  @override
  String get catalogFilterTermPriceMax => 'prix maximum';

  @override
  String get catalogFilterTermOem => 'référence OEM';

  @override
  String get catalogFilterTermCategory => 'une catégorie';

  @override
  String get catalogFilterTermFitment => 'compatibilité véhicule';

  @override
  String get catalogFilterTermInStock => 'en stock';

  @override
  String get catalogPartAddCta => 'Nouvelle pièce';

  @override
  String get catalogPartSearchHint => 'Nom, SKU, OEM…';

  @override
  String get catalogPartTypeOem => 'OEM';

  @override
  String get catalogPartTypeOes => 'OES';

  @override
  String get catalogPartTypeAftermarket => 'Aftermarket';

  @override
  String get catalogPartTypeSalvage => 'Occasion';

  @override
  String get catalogStockIn => 'Disponible';

  @override
  String get catalogStockOut => 'Indisponible';

  @override
  String get catalogGarageFitmentTooltip =>
      'Pièces compatibles avec ce véhicule';

  @override
  String get catalogGarageFitmentUnknownModel =>
      'Modèle hors catalogue : compatibilité indisponible';

  @override
  String get catalogGarageFitmentChip => 'Compatibles';

  @override
  String get catalogPartNoneFound => 'Aucune pièce trouvée';

  @override
  String get catalogPartCatalogEmpty =>
      'Le catalogue ne contient aucune pièce pour le moment.';

  @override
  String get catalogAccessoryAddCta => 'Nouvel accessoire';

  @override
  String get catalogAccessorySearchHint => 'Nom ou SKU…';

  @override
  String get catalogAccessoryCategoryStyling => 'Esthétique';

  @override
  String get catalogAccessoryCategoryComfort => 'Confort';

  @override
  String get catalogAccessoryCategorySafety => 'Sécurité';

  @override
  String get catalogAccessoryCategoryMultimedia => 'Multimédia';

  @override
  String get catalogAccessoryCategoryUtility => 'Utilitaire';

  @override
  String get catalogAccessoryNoneFound => 'Aucun accessoire trouvé';

  @override
  String get catalogAccessoryCatalogEmpty =>
      'Le catalogue ne contient aucun accessoire pour le moment.';

  @override
  String get catalogShareTooltip => 'Partager';

  @override
  String get catalogEditTooltip => 'Modifier';

  @override
  String get catalogDeleteAction => 'Supprimer';

  @override
  String get catalogVehicleDeleteTitle => 'Supprimer ce véhicule ?';

  @override
  String catalogVehicleDeleteBody(String name) {
    return '« $name » sera supprimé définitivement.';
  }

  @override
  String get catalogSectionVehicle => 'Véhicule';

  @override
  String get catalogSectionCondition => 'État';

  @override
  String get catalogSectionImport => 'Import';

  @override
  String get catalogSectionLocation => 'Localisation';

  @override
  String get catalogSectionFeatures => 'Équipements';

  @override
  String get catalogSectionPartner => 'Partenaire source';

  @override
  String get catalogFieldBrand => 'Marque';

  @override
  String get catalogFieldModel => 'Modèle';

  @override
  String get catalogFieldYear => 'Année';

  @override
  String get catalogFieldTrim => 'Finition';

  @override
  String get catalogFieldEngine => 'Motorisation';

  @override
  String get catalogFieldDrivetrain => 'Roues motrices';

  @override
  String get catalogFieldBodyStyle => 'Carrosserie';

  @override
  String get catalogFieldTransmission => 'Boîte';

  @override
  String get catalogFieldPower => 'Puissance';

  @override
  String get catalogFieldDisplacement => 'Cylindrée';

  @override
  String get catalogFieldCylinders => 'Cylindres';

  @override
  String get catalogFieldTorque => 'Couple';

  @override
  String get catalogFieldGears => 'Rapports';

  @override
  String get catalogFieldSeats => 'Places';

  @override
  String get catalogFieldDoors => 'Portes';

  @override
  String get catalogFieldEngineCode => 'Code moteur';

  @override
  String get catalogFieldConsumption => 'Consommation';

  @override
  String get catalogFieldReference => 'Référence';

  @override
  String get catalogFieldCondition => 'Condition';

  @override
  String get catalogFieldMileage => 'Kilométrage';

  @override
  String get catalogFieldFaults => 'Pannes déclarées';

  @override
  String get catalogFieldOrigin => 'Origine';

  @override
  String get catalogFieldPortOfEntry => 'Port d\'entrée';

  @override
  String get catalogFieldHandedness => 'Conduite';

  @override
  String get catalogFieldBranch => 'Agence';

  @override
  String get catalogFieldColour => 'Couleur';

  @override
  String catalogUnitHp(int value) {
    return '$value ch';
  }

  @override
  String catalogUnitCc(int value) {
    return '$value cm³';
  }

  @override
  String catalogUnitTorque(int value) {
    return '$value Nm';
  }

  @override
  String catalogUnitConsumption(String value) {
    return '$value L/100 km';
  }

  @override
  String get catalogConditionNew => 'Neuf';

  @override
  String get catalogConditionUsed => 'Occasion';

  @override
  String get catalogConditionDamaged => 'Accidenté';

  @override
  String get catalogCustomsYes => '✓ Oui';

  @override
  String get catalogCustomsPending => '⏳ En attente';

  @override
  String get catalogRightHandDrive => 'Droite (RHD)';

  @override
  String catalogColourMetallic(String name) {
    return '$name (métallisé)';
  }

  @override
  String catalogColourPearl(String name) {
    return '$name (nacré)';
  }

  @override
  String get catalogFeatureCategoryStandard => 'Dotation standard';

  @override
  String get catalogFeatureCategoryComfort => 'Confort';

  @override
  String get catalogFeatureCategorySafety => 'Sécurité';

  @override
  String get catalogFeatureCategoryMultimedia => 'Multimédia';

  @override
  String get catalogFeatureCategoryDriverAid => 'Aides à la conduite';

  @override
  String get catalogFeatureCategoryOther => 'Autres';

  @override
  String get catalogFeaturesSheetTitle => 'Équipements du véhicule';

  @override
  String get catalogFeaturesSave => 'Enregistrer';

  @override
  String get catalogRefsUnavailable =>
      'Données de référence non chargées, réessayez.';

  @override
  String get catalogFeaturesUpdated => 'Équipements mis à jour ✓';

  @override
  String get catalogFullOption => 'Full option';

  @override
  String catalogFullOptionCount(int count) {
    return '· $count équipements';
  }

  @override
  String get catalogPriceNegotiable => 'Négociable';

  @override
  String catalogRentalDeposit(String amount) {
    return 'Caution : $amount';
  }

  @override
  String get catalogCallAction => 'Appeler';

  @override
  String catalogOfficialConsumption(String range) {
    return 'Consommation officielle : $range';
  }

  @override
  String catalogOfficialConsumptionSingle(
    int year,
    String source,
    String cycle,
  ) {
    return 'Millésime $year — $source, $cycle';
  }

  @override
  String catalogOfficialConsumptionRange(
    int count,
    int year,
    String source,
    String cycle,
  ) {
    return 'Selon la motorisation ($count connues pour le millésime $year) — $source, $cycle';
  }

  @override
  String get catalogBodyLabelSedan => 'Berline';

  @override
  String get catalogBodyLabelHatchback => 'Citadine / Hayon';

  @override
  String get catalogBodyLabelSuv => 'SUV / 4×4';

  @override
  String get catalogBodyLabelEstate => 'Break';

  @override
  String get catalogBodyLabelCoupe => 'Coupé';

  @override
  String get catalogBodyLabelConvertible => 'Cabriolet';

  @override
  String get catalogBodyLabelPickup => 'Pickup';

  @override
  String get catalogBodyLabelVan => 'Fourgonnette';

  @override
  String get catalogBodyLabelMinibus => 'Minibus';

  @override
  String get catalogBodyLabelBus => 'Bus / Car';

  @override
  String get catalogBodyLabelTruck => 'Camion';

  @override
  String get catalogBodyLabelOther => 'Autre';

  @override
  String get catalogTransmissionManual => 'Manuelle';

  @override
  String get catalogTransmissionCvt => 'CVT';

  @override
  String get catalogTransmissionAutomatic => 'Automatique';

  @override
  String get catalogPhotosTooltip => 'Photos';

  @override
  String get catalogPartDeleteTitle => 'Supprimer cette pièce ?';

  @override
  String catalogPartDeleteBody(String name) {
    return '« $name » sera supprimée définitivement.';
  }

  @override
  String get catalogAccessoryDeleteTitle => 'Supprimer cet accessoire ?';

  @override
  String catalogAccessoryDeleteBody(String name) {
    return '« $name » sera supprimé définitivement.';
  }

  @override
  String get catalogSectionDescription => 'Description';

  @override
  String get catalogSectionInformation => 'Informations';

  @override
  String get catalogSectionPrice => 'Prix';

  @override
  String get catalogFieldSalePrice => 'Prix de vente';

  @override
  String get catalogFieldType => 'Type';

  @override
  String get catalogFieldState => 'État';

  @override
  String get catalogFieldCategory => 'Catégorie';

  @override
  String get catalogFieldSku => 'SKU';

  @override
  String get catalogFieldManufacturer => 'Fabricant';

  @override
  String get catalogPartTypeOemLong => 'OEM — Constructeur d\'origine';

  @override
  String get catalogPartTypeOesLong => 'OES — Équipementier agréé';

  @override
  String get catalogPartTypeAftermarketLong => 'Aftermarket — Marché libre';

  @override
  String get catalogPartTypeSalvageLong => 'Récupération / Occasion';

  @override
  String get catalogPartConditionNew => 'Neuf';

  @override
  String get catalogPartConditionRefurbished => 'Reconditionné';

  @override
  String get catalogPartConditionUsed => 'Usagé';

  @override
  String get catalogAddToCart => 'Ajouter au panier';

  @override
  String get catalogAddToCartAgain => 'Ajouter à nouveau';

  @override
  String catalogAddedToCart(String name) {
    return '$name ajouté au panier';
  }

  @override
  String get catalogSeeCart => 'Voir';

  @override
  String get catalogOutOfStock => 'Rupture de stock';

  @override
  String catalogStockQuantity(int count) {
    return '$count en stock';
  }

  @override
  String catalogStockQuantityLow(int count) {
    return '$count en stock — stock faible';
  }

  @override
  String get catalogStockLowChip => 'Stock bas';

  @override
  String catalogStockLocation(String location) {
    return 'Emplacement : $location';
  }

  @override
  String get catalogPartNoFitments =>
      'Aucune compatibilité déclarée. La pièce ne remonte pas dans une recherche par véhicule.';

  @override
  String get catalogAccessoryNoFitments =>
      'Aucune compatibilité déclarée. L\'accessoire ne remonte pas dans une recherche par véhicule.';

  @override
  String get catalogGarageSectionTitle => 'Vos véhicules';

  @override
  String get catalogFitmentYes => 'Compatible';

  @override
  String get catalogFitmentUnsure => 'À confirmer';

  @override
  String get catalogFitmentUnsureDetail =>
      'Compatible avec ce modèle, mais la motorisation de votre véhicule n\'est pas renseignée. Complétez-la pour être sûr.';

  @override
  String get catalogFitmentNo => 'Non compatible';

  @override
  String get catalogFitmentUnknown => 'Non déterminé';

  @override
  String get catalogFitmentUnknownDetail =>
      'Renseignez la motorisation de votre véhicule pour obtenir une réponse.';

  @override
  String catalogVehicleWithYear(String name, int year) {
    return '$name ($year)';
  }

  @override
  String get cartTitle => 'Panier';

  @override
  String cartTitleCount(int count) {
    return 'Panier ($count)';
  }

  @override
  String get cartClear => 'Vider';

  @override
  String get cartClearTitle => 'Vider le panier ?';

  @override
  String get cartClearBody => 'Tous les articles seront retirés.';

  @override
  String cartLineTotal(String unitPrice, int quantity, String lineTotal) {
    return '$unitPrice × $quantity = $lineTotal';
  }

  @override
  String get cartSubtotalExclTax => 'Sous-total HT';

  @override
  String get cartVat => 'TVA';

  @override
  String get cartTotalInclTax => 'Total TTC';

  @override
  String get cartOrderViaWhatsApp => 'Commander via WhatsApp';

  @override
  String get cartOpening => 'Ouverture…';

  @override
  String get cartWhatsAppHeader => '*Demande de commande — AutoParc*';

  @override
  String get cartWhatsAppFooter => 'Merci de confirmer la disponibilité.';

  @override
  String get cartWhatsAppMissing =>
      'WhatsApp n\'est pas installé sur cet appareil.';

  @override
  String get cartInvoice => 'Facturer';

  @override
  String get cartCustomerSection => 'Informations client';

  @override
  String get cartCustomerName => 'Nom du client *';

  @override
  String get cartFieldRequired => 'Champ obligatoire';

  @override
  String get cartCustomerPhone => 'Téléphone';

  @override
  String get cartPhoneHint => '+226 xx xx xx xx';

  @override
  String cartItemCountSummary(int count, String total) {
    return '$count article(s) · $total TTC';
  }

  @override
  String get cartConfirmOrder => 'Confirmer la commande';

  @override
  String get cartSubmitting => 'Envoi en cours…';

  @override
  String get cartOrderSaved => 'Commande enregistrée avec succès ✓';

  @override
  String get cartEmptyTitle => 'Votre panier est vide';

  @override
  String get cartEmptyBody =>
      'Ajoutez des accessoires ou des pièces\ndepuis le catalogue.';

  @override
  String get authSignInTab => 'Se connecter';

  @override
  String get authRegisterTab => 'S\'inscrire';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailInvalid => 'Email invalide';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authPasswordTooShort => 'Minimum 6 caractères';

  @override
  String get authPasswordConfirm => 'Confirmer le mot de passe';

  @override
  String get authPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authCreateAccount => 'Créer mon compte';

  @override
  String get authOrSeparator => 'ou';

  @override
  String get authContinueWithGoogle => 'Continuer avec Google';

  @override
  String get authBrowseWithoutAccount => 'Parcourir le catalogue sans compte';

  @override
  String authWelcome(String name) {
    return 'Bienvenue, $name !';
  }

  @override
  String get authTagline => 'Vente · Location · Pièces · Accessoires';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingCatalogTitle => 'Explorez le catalogue';

  @override
  String get onboardingCatalogBody =>
      'Véhicules, pièces et accessoires en un seul endroit.\nFiltrez par type, carrosserie, ville ou disponibilité pour trouver exactement ce qu\'il vous faut.';

  @override
  String get onboardingNeedsTitle => 'Exprimez vos besoins';

  @override
  String get onboardingNeedsBody =>
      'Vous ne trouvez pas votre bonheur ?\nCréez une alerte et recevez une notification dès qu\'un véhicule ou une pièce correspond à votre recherche.';

  @override
  String get onboardingGarageTitle => 'Votre garage personnel';

  @override
  String get onboardingGarageBody =>
      'Ajoutez vos véhicules pour retrouver instantanément les pièces détachées compatibles.\nVotre historique vous suit à chaque visite.';

  @override
  String get catalogFitmentsTitle => 'Véhicules compatibles';

  @override
  String get catalogFitmentsAllProposed =>
      'Toutes proposées automatiquement : aucune n\'a été vérifiée.';

  @override
  String catalogFitmentsSomeProposed(int count, int total) {
    return '$count sur $total proposées automatiquement, non vérifiées.';
  }

  @override
  String get catalogFitmentSeparator => ' · ';

  @override
  String catalogFitmentYearRange(int from, int to) {
    return ' ($from – $to)';
  }

  @override
  String catalogFitmentYearFrom(int year) {
    return ' (depuis $year)';
  }

  @override
  String catalogFitmentYearTo(int year) {
    return ' (jusqu\'à $year)';
  }

  @override
  String get homeDealsSection => 'Bonnes affaires';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String homeCompatiblePartsSection(String model) {
    return 'Pièces pour $model';
  }

  @override
  String get homeCompatiblePartsFallbackModel => 'votre véhicule';

  @override
  String get homeUpdateMileage => 'Mettre à jour le kilométrage';

  @override
  String get homeNoDeadlinePrompt =>
      'Renseignez vos échéances pour être prévenu à temps';

  @override
  String get homeGarageUnavailable => 'Votre garage n\'a pas pu être chargé';

  @override
  String get homeAddVehicleTitle => 'Enregistrez votre véhicule';

  @override
  String get homeAddVehicleBody =>
      'Visite technique, assurance, vidange : nous vous prévenons avant l\'échéance.';

  @override
  String get homeAddVehicleCta => 'Ajouter ma voiture';

  @override
  String get homeNeedPrompt =>
      'Vous ne trouvez pas ? Dites-nous ce que vous cherchez';

  @override
  String homeDeadlineDetail(String label, String detail) {
    return '$label — $detail';
  }

  @override
  String homeDeadlineOverdue(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return '$label dépassée depuis $_temp0';
  }

  @override
  String homeDeadlineToday(String label) {
    return '$label expire aujourd\'hui';
  }

  @override
  String homeDeadlineTomorrow(String label) {
    return '$label expire demain';
  }

  @override
  String homeDeadlineInDays(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return '$label dans $_temp0';
  }
}
