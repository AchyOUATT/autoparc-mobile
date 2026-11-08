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
  String get commonPerMonthSuffix => '/mois';

  @override
  String commonMileageKm(String value) {
    return '$value km';
  }

  @override
  String get commonMileageNotProvided => 'Kilométrage non renseigné';

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
  String get shellSessionToConfirm => 'Session à confirmer…';

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
  String get catalogFieldTransmission => 'Boîte de vitesses';

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
  String get catalogTransmissionCvt => 'Variation continue (CVT)';

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

  @override
  String get privateSalesSellTitle => 'Vendre ma voiture';

  @override
  String get privateSalesMineTitle => 'Mes annonces';

  @override
  String get privateSalesBrowseTitle => 'Voitures de particuliers';

  @override
  String get privateSalesReviewTitle => 'Valider les annonces';

  @override
  String get privateSalesStatusDraft => 'Brouillon';

  @override
  String get privateSalesStatusPending => 'En cours de validation';

  @override
  String get privateSalesStatusPublished => 'En ligne';

  @override
  String get privateSalesStatusRejected => 'À corriger';

  @override
  String get privateSalesStatusWithdrawn => 'Retirée';

  @override
  String get privateSalesStatusSold => 'Vendue';

  @override
  String get privateSalesPrivateSeller => 'Particulier';

  @override
  String get privateSalesConfirmRemovalBody =>
      'L’annonce ne sera plus visible par les acheteurs.';

  @override
  String get privateSalesConfirm => 'Confirmer';

  @override
  String get privateSalesRejectReasonTitle => 'Motif à communiquer au vendeur';

  @override
  String get privateSalesRejectReasonHint =>
      'Expliquez ce qui doit être corrigé.';

  @override
  String get privateSalesRejectAction => 'Refuser / retirer';

  @override
  String get privateSalesMissingPhonePublication =>
      'Cette annonce n’indique aucun numéro : elle ne peut pas être publiée. Refusez-la en demandant au vendeur de le renseigner.';

  @override
  String get privateSalesCallSeller => 'Appeler le vendeur';

  @override
  String get privateSalesCallCheckInstructions =>
      'Demandez-lui si c’est bien LUI qui a déposé cette annonce — pas seulement si le numéro est le sien.';

  @override
  String get privateSalesDial => 'Composer';

  @override
  String get privateSalesCallConfirmed =>
      'J’ai appelé ce numéro et le vendeur a confirmé avoir déposé cette annonce.';

  @override
  String get privateSalesPublish => 'Publier';

  @override
  String get privateSalesReviewAccessDenied =>
      'Accès réservé au personnel chargé du catalogue.';

  @override
  String get privateSalesSignInManage => 'Se connecter pour gérer mes annonces';

  @override
  String get privateSalesRefresh => 'Actualiser';

  @override
  String get privateSalesSearchHint => 'Chercher une voiture ou une ville';

  @override
  String get privateSalesReviewFilterLabel => 'État des annonces';

  @override
  String get privateSalesReviewFilterPending => 'En attente';

  @override
  String get privateSalesReviewFilterPublished => 'Publiées';

  @override
  String get privateSalesOneActiveListingHint =>
      'Une annonce en cours gratuite. Retirez-la ou marquez-la vendue pour en créer une autre.';

  @override
  String get privateSalesEmptyMine => 'Votre première annonce commence ici.';

  @override
  String get privateSalesEmptyReview => 'Aucune annonce à examiner.';

  @override
  String get privateSalesEmptyBrowse => 'Aucune annonce pour le moment.';

  @override
  String get privateSalesPrevious => 'Précédent';

  @override
  String get privateSalesNext => 'Suivant';

  @override
  String get privateSalesEdit => 'Modifier / compléter';

  @override
  String get privateSalesConfirmSoldTitle => 'Marquer ce véhicule vendu ?';

  @override
  String get privateSalesMarkSold => 'Marquer vendu';

  @override
  String get privateSalesConfirmWithdrawTitle => 'Retirer cette annonce ?';

  @override
  String get privateSalesWithdraw => 'Retirer';

  @override
  String get privateSalesGarageEmpty =>
      'Votre garage est vide. Vous pouvez saisir le véhicule directement ici.';

  @override
  String get privateSalesChooseGarageTitle =>
      'Choisir un véhicule de mon garage';

  @override
  String get privateSalesPhotosLimit =>
      'Vous pouvez ajouter au plus 10 photos au total.';

  @override
  String get privateSalesSaveBeforeSubmit =>
      'Enregistrez vos modifications avant d’envoyer l’annonce.';

  @override
  String get privateSalesSubmitted =>
      'Annonce envoyée. Vous retrouverez la décision dans « Mes annonces ».';

  @override
  String get privateSalesSignInSell => 'Se connecter pour vendre';

  @override
  String get privateSalesAccountChanged =>
      'Le compte a changé. Fermez ce formulaire et rouvrez « Mes annonces ».';

  @override
  String get privateSalesFormHeading => 'Votre voiture, votre annonce';

  @override
  String get privateSalesNoPartnerRequired =>
      'Une annonce en cours gratuite. Aucun compte partenaire nécessaire.';

  @override
  String get privateSalesPrefillGarage => 'Préremplir depuis mon garage';

  @override
  String get privateSalesGaragePrivacy =>
      'Votre garage reste privé. Seuls les détails du véhicule et ses photos sont publiés.';

  @override
  String get privateSalesPriceLabel => 'Prix en FCFA';

  @override
  String get privateSalesCityLabel => 'Ville';

  @override
  String get privateSalesDescriptionLabel =>
      'État du véhicule et informations utiles';

  @override
  String get privateSalesSellerNameLabel => 'Nom du vendeur';

  @override
  String get privateSalesPhoneLabel => 'Téléphone avec indicatif';

  @override
  String get privateSalesWhatsappOptIn =>
      'Autoriser AutoParc à me joindre sur WhatsApp';

  @override
  String get privateSalesSaveDraft => 'Enregistrer le brouillon';

  @override
  String get privateSalesSaveChanges => 'Enregistrer les modifications';

  @override
  String get privateSalesChangesNeedReview =>
      'Une modification remettra l’annonce en brouillon et demandera une nouvelle validation.';

  @override
  String get privateSalesPhotosPrivacy =>
      'La première photo sera la couverture. Ajoutez uniquement des photos destinées à être publiques.';

  @override
  String get privateSalesVehiclePhoto => 'Photo du véhicule';

  @override
  String get privateSalesDeletePhoto => 'Supprimer la photo';

  @override
  String get privateSalesAddPhotos => 'Ajouter des photos';

  @override
  String get privateSalesBeforePublication => 'Avant la mise en ligne';

  @override
  String get privateSalesPhoneCallNotice =>
      'Une personne d’AutoParc vous appellera au numéro indiqué pour confirmer que l’annonce vient bien de vous. Votre numéro reste réservé à AutoParc.';

  @override
  String get privateSalesOwnerConfirmation =>
      'Je suis propriétaire de ce véhicule ou autorisé à le vendre.';

  @override
  String get privateSalesContactConsent =>
      'J’autorise AutoParc à me contacter au sujet de cette annonce. Mon nom et mon numéro ne sont pas rendus publics.';

  @override
  String get privateSalesSubmit => 'Envoyer pour validation';

  @override
  String get privateSalesRequiredField => 'Renseignez ce champ.';

  @override
  String get privateSalesDescriptionTooShort =>
      'Décrivez le véhicule en au moins 20 caractères.';

  @override
  String get privateSalesPhoneInvalid =>
      'Indiquez le numéro avec l’indicatif, par exemple +22670000000.';

  @override
  String get privateSalesIntegerInvalid => 'Saisissez un nombre entier valide.';

  @override
  String get privateSalesYearInvalid => 'Vérifiez l’année.';

  @override
  String get privateSalesDetailTitle => 'Annonce de particulier';

  @override
  String get privateSalesShare => 'Partager l’annonce';

  @override
  String get privateSalesFuel => 'Carburant';

  @override
  String get privateSalesDrivetrain => 'Roues motrices';

  @override
  String get privateSalesPhoneVerified => 'Téléphone vérifié';

  @override
  String get privateSalesNotInspected =>
      'Le véhicule n’a pas été inspecté par AutoParc.';

  @override
  String get privateSalesContactWhatsapp => 'Contacter sur WhatsApp';

  @override
  String get privateSalesAutoParcContactNotice =>
      'Pour cette annonce, contactez AutoParc. Les coordonnées du vendeur restent privées.';

  @override
  String get privateSalesCallAutoParc => 'Appeler AutoParc';

  @override
  String get privateSalesWhatsappAutoParc => 'WhatsApp AutoParc';

  @override
  String privateSalesAutoParcMessage(String title, String url) {
    return 'Bonjour AutoParc, je souhaite des informations sur cette annonce : $title\n$url';
  }

  @override
  String get privateSalesBrandRequiredLabel => 'Marque *';

  @override
  String get privateSalesBrandRequiredError => 'Marque obligatoire';

  @override
  String get privateSalesModelRequiredLabel => 'Modèle *';

  @override
  String get privateSalesModelSelectionError =>
      'Sélectionnez un modèle ou saisissez le vôtre.';

  @override
  String get privateSalesFreeModelHint => 'Saisissez le nom de votre modèle';

  @override
  String get privateSalesFreeModelRequired => 'Renseignez le modèle.';

  @override
  String get privateSalesModelListAction => 'Revenir à la liste des modèles';

  @override
  String get privateSalesFreeModelAction =>
      'Mon modèle n’est pas dans la liste';

  @override
  String get privateSalesManufactureYearLabel => 'Année de fabrication *';

  @override
  String get privateSalesManufactureYearInvalid =>
      'Vérifiez l’année de fabrication.';

  @override
  String get privateSalesMileageInvalid => 'Saisissez un kilométrage valide.';

  @override
  String get privateSalesClearTrim => 'Effacer la finition';

  @override
  String get privateSalesClearFuel => 'Effacer le carburant';

  @override
  String get privateSalesClearDrivetrain => 'Effacer la motricité';

  @override
  String get privateSalesClearColour => 'Effacer la couleur';

  @override
  String get privateSalesTransmissionOptional =>
      'Boîte de vitesses (facultatif)';

  @override
  String get privateSalesTransmissionDualClutch => 'Double embrayage (DCT)';

  @override
  String get privateSalesTransmissionSingleSpeed => 'Rapport unique';

  @override
  String get privateSalesClearTransmission => 'Effacer la boîte';

  @override
  String privateSalesReviewReason(String reason) {
    return 'À corriger : $reason';
  }

  @override
  String privateSalesPhotosHeading(int count) {
    return 'Photos ($count/10)';
  }

  @override
  String privateSalesVerifiedNumber(String number) {
    return 'Numéro vérifié : $number';
  }

  @override
  String privateSalesGenerationWarning(String years) {
    return 'Cette génération est indiquée $years. Vérifiez le modèle et l’année.';
  }

  @override
  String privateSalesVehicleSummary(int year, int mileage, String city) {
    return '$year · $mileage km · $city';
  }

  @override
  String privateSalesPagination(int page, int lastPage) {
    return '$page / $lastPage';
  }

  @override
  String privateSalesFieldValue(String label, String value) {
    return '$label : $value';
  }

  @override
  String get partnerAccountsPromotionStartTitle => 'Début de la promotion';

  @override
  String get partnerAccountsPromotionEndTitle => 'Fin de la promotion';

  @override
  String get partnerAccountsPromotionEnabled => 'Mettre en promotion';

  @override
  String get partnerAccountsPromotionPriceRequired =>
      'Indiquez d’abord un prix de vente.';

  @override
  String get partnerAccountsPromotionDurationHelp =>
      'Pendant une durée que vous choisissez.';

  @override
  String get partnerAccountsPromotionPrice =>
      'Prix pendant la promotion (FCFA)';

  @override
  String get partnerAccountsPromotionPriceInvalid =>
      'Le prix promotionnel doit être inférieur au prix normal.';

  @override
  String get partnerAccountsPromotionDiscountInvalid => 'Remise trop forte.';

  @override
  String get partnerAccountsPromotionStart => 'Début';

  @override
  String get partnerAccountsPromotionEnd => 'Fin';

  @override
  String get partnerAccountsMarginYourPrice => 'Votre prix';

  @override
  String get partnerAccountsMarginPublicPrice => 'Prix affiché à l’acheteur';

  @override
  String get partnerAccountsMarginLockedHelp =>
      'Ce total est figé au moment où vous enregistrez.';

  @override
  String get partnerAccountsSpaceTitle => 'Espace partenaire';

  @override
  String get partnerAccountsCompanyIntro => 'Présentez votre entreprise';

  @override
  String get partnerAccountsActivityIntro => 'Développez votre activité';

  @override
  String get partnerAccountsRegisterIntro =>
      'Après validation de votre compte, publiez vos véhicules, pièces et accessoires.';

  @override
  String get partnerAccountsLoginIntro =>
      'Gérez vos annonces de vente et de location dans votre espace professionnel.';

  @override
  String get partnerAccountsLoginTab => 'Connexion';

  @override
  String get partnerAccountsRegisterTab => 'Inscription';

  @override
  String get partnerAccountsCompanyOptional =>
      'Nom de l’entreprise (facultatif)';

  @override
  String get partnerAccountsCompanyFallbackHelp =>
      'Sans entreprise, vos annonces porteront votre nom.';

  @override
  String get partnerAccountsContactName => 'Nom du responsable';

  @override
  String get partnerAccountsBusinessPhone => 'Téléphone professionnel';

  @override
  String get partnerAccountsWhatsappOptional => 'WhatsApp (facultatif)';

  @override
  String get partnerAccountsEmailOptional => 'Adresse email (facultatif)';

  @override
  String get partnerAccountsPhoneLoginHelp =>
      'Vous vous connecterez avec votre numéro de téléphone.';

  @override
  String get partnerAccountsInvalidEmail =>
      'Indiquez une adresse email valide.';

  @override
  String get partnerAccountsLoginIdentifier => 'Téléphone ou adresse email';

  @override
  String get partnerAccountsIdentifierRequired =>
      'Indiquez votre numéro ou votre adresse email.';

  @override
  String get partnerAccountsIdentifierInvalid =>
      'Indiquez un numéro de téléphone ou une adresse email.';

  @override
  String get partnerAccountsPasswordHelp =>
      '12 caractères minimum, avec des lettres et des chiffres.';

  @override
  String get partnerAccountsShowPassword => 'Afficher le mot de passe';

  @override
  String get partnerAccountsHidePassword => 'Masquer le mot de passe';

  @override
  String get partnerAccountsPasswordRequired => 'Indiquez votre mot de passe.';

  @override
  String get partnerAccountsPasswordInvalid =>
      'Utilisez au moins 12 caractères, des lettres et des chiffres.';

  @override
  String get partnerAccountsPasswordMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get partnerAccountsRestoreSession =>
      'Réessayer de restaurer ma session';

  @override
  String get partnerAccountsRequestAccount => 'Demander mon compte partenaire';

  @override
  String get partnerAccountsPublishingAfterApproval =>
      'La publication devient disponible après validation de votre entreprise.';

  @override
  String get partnerAccountsRequiredField => 'Ce champ est obligatoire.';

  @override
  String get partnerAccountsStatusUnconfirmed => 'Statut à confirmer…';

  @override
  String get partnerAccountsAccountApproved => 'Compte approuvé';

  @override
  String get partnerAccountsCreateListingHelp =>
      'Créez une annonce, ajoutez vos photos puis publiez-la. Vos coordonnées accompagneront vos annonces.';

  @override
  String get partnerAccountsSaleAndRental => 'Vente et location';

  @override
  String get partnerAccountsInventorySummary => 'Prix, disponibilité et stock';

  @override
  String get partnerAccountsCustomerRequests => 'Demandes clients';

  @override
  String get partnerAccountsCustomerRequestsSubtitle =>
      'Ce que la boutique vous transmet';

  @override
  String get partnerAccountsRefreshAccount => 'Actualiser mon compte';

  @override
  String get partnerAccountsRejectedTitle => 'Demande refusée';

  @override
  String get partnerAccountsRejectedDescription =>
      'Votre demande n’a pas été approuvée. Consultez le motif ci-dessous.';

  @override
  String get partnerAccountsSuspendedTitle => 'Compte suspendu';

  @override
  String get partnerAccountsSuspendedDescription =>
      'La gestion et la publication de vos annonces sont suspendues.';

  @override
  String get partnerAccountsReceivedTitle => 'Inscription reçue';

  @override
  String get partnerAccountsReceivedDescription =>
      'Votre entreprise est en attente de validation. Vous pourrez gérer vos annonces après approbation.';

  @override
  String get partnerAccountsRefreshing => 'Actualisation…';

  @override
  String get partnerAccountsCheckStatus => 'Vérifier mon statut';

  @override
  String get partnerAccountsBackToLogin => 'Revenir à la connexion';

  @override
  String get partnerAccountsPendingStatus => 'En attente';

  @override
  String get partnerAccountsApprovedStatus => 'Approuvés';

  @override
  String get partnerAccountsRejectedStatus => 'Refusés';

  @override
  String get partnerAccountsSuspendedStatus => 'Suspendus';

  @override
  String get partnerAccountsRejectApplication => 'Refuser la demande';

  @override
  String get partnerAccountsSuspendAccount => 'Suspendre le compte';

  @override
  String get partnerAccountsReviewReasonLabel =>
      'Motif communiqué au partenaire';

  @override
  String get partnerAccountsReviewReasonRequired =>
      'Précisez le motif de cette décision.';

  @override
  String get partnerAccountsConfirm => 'Confirmer';

  @override
  String get partnerAccountsApplicationIncomplete =>
      'Cette candidature est incomplète. Rafraîchissez la liste.';

  @override
  String get partnerAccountsDecisionSaved => 'Décision enregistrée.';

  @override
  String get partnerAccountsApplicationsTitle => 'Validation des partenaires';

  @override
  String get partnerAccountsManagerOnly => 'Accès réservé aux responsables.';

  @override
  String get partnerAccountsApplicationsFilter => 'Demandes';

  @override
  String get partnerAccountsNoApplications =>
      'Aucune demande dans cette catégorie.';

  @override
  String get partnerAccountsPrevious => 'Précédent';

  @override
  String get partnerAccountsNext => 'Suivant';

  @override
  String get partnerAccountsUnnamedCompany => 'Entreprise sans nom';

  @override
  String get partnerAccountsMissingContact => 'Contact non renseigné';

  @override
  String get partnerAccountsMissingPhone => 'Téléphone non renseigné';

  @override
  String get partnerAccountsReactivate => 'Réactiver';

  @override
  String get partnerAccountsApprove => 'Approuver';

  @override
  String get partnerAccountsReject => 'Refuser';

  @override
  String get partnerAccountsSuspend => 'Suspendre';

  @override
  String get partnerAccountsListingIncomplete =>
      'Cette annonce est incomplète. Rafraîchissez la liste.';

  @override
  String get partnerAccountsArchiveQuestion => 'Archiver cette annonce ?';

  @override
  String get partnerAccountsArchiveDescription =>
      'Elle sera retirée de votre inventaire et du catalogue public.';

  @override
  String get partnerAccountsArchive => 'Archiver';

  @override
  String get partnerAccountsAdjustStock => 'Ajuster le stock';

  @override
  String get partnerAccountsAvailableQuantity => 'Quantité disponible';

  @override
  String get partnerAccountsQuantityInvalid => 'Indiquez une quantité valide.';

  @override
  String get partnerAccountsSave => 'Enregistrer';

  @override
  String get partnerAccountsListingFallback => 'Annonce';

  @override
  String get partnerAccountsRefresh => 'Actualiser';

  @override
  String get partnerAccountsCreateListing => 'Créer une annonce';

  @override
  String get partnerAccountsSearchListings => 'Rechercher dans mes annonces';

  @override
  String get partnerAccountsSearch => 'Rechercher';

  @override
  String get partnerAccountsInventoryEmpty => 'Votre inventaire commence ici';

  @override
  String get partnerAccountsNoMatchingListings =>
      'Aucune annonce correspondante';

  @override
  String get partnerAccountsInventoryEmptyHelp =>
      'Créez votre annonce, ajoutez ses photos puis choisissez de la publier.';

  @override
  String get partnerAccountsCreateFirstListing => 'Créer ma première annonce';

  @override
  String get partnerAccountsPreviousPage => 'Page précédente';

  @override
  String get partnerAccountsNextPage => 'Page suivante';

  @override
  String get partnerAccountsManageListing => 'Gérer cette annonce';

  @override
  String get partnerAccountsManagePhotos => 'Gérer les photos';

  @override
  String get partnerAccountsMakeAvailable => 'Rendre disponible';

  @override
  String get partnerAccountsMakeUnavailable => 'Marquer indisponible';

  @override
  String get partnerAccountsPublished => 'Publiée';

  @override
  String get partnerAccountsDraft => 'Brouillon';

  @override
  String get partnerAccountsWithdraw => 'Retirer';

  @override
  String get partnerAccountsPublish => 'Publier';

  @override
  String get partnerAccountsRequestFailed =>
      'Impossible de terminer la demande. Vérifiez votre connexion et réessayez.';

  @override
  String get partnerAccountsPriceRequired => 'Indiquez un prix.';

  @override
  String get partnerAccountsMoneyInvalid =>
      'Indiquez un montant positif ou nul.';

  @override
  String get partnerAccountsNotProvided => 'Non renseigné';

  @override
  String get partnerAccountsChoiceRequired => 'Choisissez une valeur.';

  @override
  String get partnerAccountsEditListingHelp => 'Mettez à jour votre annonce.';

  @override
  String get partnerAccountsNewListingHelp =>
      'L’annonce sera créée en brouillon. Vous pourrez ensuite ajouter ses photos et la publier.';

  @override
  String get partnerAccountsSaving => 'Enregistrement…';

  @override
  String get partnerAccountsSaveChanges => 'Enregistrer les modifications';

  @override
  String get partnerAccountsSaveDraft => 'Enregistrer le brouillon';

  @override
  String get partnerAccountsItemName => 'Nom de l’article';

  @override
  String get partnerAccountsNameRequired => 'Indiquez un nom.';

  @override
  String get partnerAccountsPartCategory => 'Catégorie de pièce';

  @override
  String get partnerAccountsPartOrigin => 'Origine de la pièce';

  @override
  String get partnerAccountsPartOem => 'Constructeur (OEM)';

  @override
  String get partnerAccountsPartOes => 'Équipementier (OES)';

  @override
  String get partnerAccountsPartAftermarket => 'Adaptable';

  @override
  String get partnerAccountsPartSalvage => 'Pièce de récupération';

  @override
  String get partnerAccountsCondition => 'État';

  @override
  String get partnerAccountsConditionNew => 'Neuve';

  @override
  String get partnerAccountsConditionRefurbished => 'Reconditionnée';

  @override
  String get partnerAccountsConditionUsed => 'D’occasion';

  @override
  String get partnerAccountsDonorRequiredHelp =>
      'Une pièce d’occasion doit être rattachée à un véhicule donneur de votre propre inventaire.';

  @override
  String get partnerAccountsReloadDonors => 'Recharger les véhicules donneurs';

  @override
  String get partnerAccountsDonorsEmpty =>
      'Ajoutez d’abord le véhicule donneur dans vos annonces de véhicules.';

  @override
  String get partnerAccountsDonorVehicle => 'Véhicule donneur';

  @override
  String get partnerAccountsManufacturerReferenceOptional =>
      'Référence fabricant (facultatif)';

  @override
  String get partnerAccountsAccessoryCategory => 'Catégorie d’accessoire';

  @override
  String get partnerAccountsManufacturerOptional => 'Fabricant (facultatif)';

  @override
  String get partnerAccountsSkuOptional =>
      'Référence interne / SKU (facultatif)';

  @override
  String get partnerAccountsSalePrice => 'Prix de vente (FCFA)';

  @override
  String get partnerAccountsStockQuantity => 'Quantité en stock';

  @override
  String get partnerAccountsStockInvalid =>
      'Indiquez un nombre entier positif ou nul.';

  @override
  String get partnerAccountsPhotosTitle => 'Photos de l’annonce';

  @override
  String get partnerAccountsAddPhotos => 'Ajouter des photos';

  @override
  String get partnerAccountsPhotosHelp =>
      'JPEG, PNG ou WebP. Choisissez une couverture et ordonnez votre galerie.';

  @override
  String get partnerAccountsPhotosEmpty =>
      'Ajoutez les premières photos de votre annonce.';

  @override
  String get partnerAccountsCover => 'Couverture';

  @override
  String get partnerAccountsSetCover => 'En couverture';

  @override
  String get partnerAccountsMoveBefore => 'Déplacer avant';

  @override
  String get partnerAccountsMoveAfter => 'Déplacer après';

  @override
  String get partnerAccountsDeletePhoto => 'Supprimer la photo';

  @override
  String get partnerAccountsDeletePhotoQuestion => 'Supprimer cette photo ?';

  @override
  String get partnerAccountsDelete => 'Supprimer';

  @override
  String get partnerAccountsPhotoLimit =>
      'Sélectionnez au plus 10 photos par envoi.';

  @override
  String get partnerAccountsMarkAllRead => 'Tout lire';

  @override
  String get partnerAccountsNoRequests => 'Aucune demande pour le moment.';

  @override
  String get partnersEditTitle => 'Modifier le partenaire';

  @override
  String get partnersCreateTitle => 'Nouveau partenaire';

  @override
  String get partnersSave => 'Enregistrer';

  @override
  String get partnersCompanySection => 'Entreprise';

  @override
  String get partnersCompanyName => 'Nom de l\'entreprise *';

  @override
  String get partnersRequiredField => 'Champ requis';

  @override
  String get partnersContactName => 'Nom de l\'interlocuteur';

  @override
  String get partnersContactsSection => 'Contacts';

  @override
  String get partnersPhone => 'Téléphone *';

  @override
  String get partnersWhatsappDifferent => 'WhatsApp (si différent)';

  @override
  String get partnersEmail => 'E-mail';

  @override
  String get partnersInvalidEmail => 'Adresse email invalide';

  @override
  String get partnersNotesSection => 'Notes';

  @override
  String get partnersInternalNotes => 'Notes internes';

  @override
  String get partnersNotesHint => 'Spécialité, conditions, horaires…';

  @override
  String get partnersActive => 'Partenaire actif';

  @override
  String get partnersInactiveHelp => 'Inactif = masqué dans les listes';

  @override
  String get partnersSearchHint => 'Nom, contact, téléphone…';

  @override
  String get partnersNoResults => 'Aucun partenaire trouvé';

  @override
  String get partnersDelete => 'Supprimer';

  @override
  String get partnersDeleteQuestion => 'Supprimer ce partenaire ?';

  @override
  String get partnersAttach => 'Associer';

  @override
  String get partnersNoLinkedPartners => 'Aucun partenaire associé.';

  @override
  String get partnersAttachTitle => 'Associer un partenaire';

  @override
  String get partnersPartnerRequired => 'Partenaire *';

  @override
  String get partnersRoleOptional => 'Rôle (optionnel)';

  @override
  String get partnersRoleHint => 'fournisseur, importateur…';

  @override
  String get partnersNotesOptional => 'Notes (optionnel)';

  @override
  String get partnersRemove => 'Retirer';

  @override
  String get partnersRemoveQuestion => 'Retirer ce partenaire ?';

  @override
  String partnerAccountsReason(String reason) {
    return 'Motif : $reason';
  }

  @override
  String partnerAccountsApplicationPagination(
    int page,
    int lastPage,
    int total,
  ) {
    return 'Page $page / $lastPage · $total demande(s)';
  }

  @override
  String partnerAccountsMarginIncluded(String amount, String rate) {
    return 'dont $amount de marge boutique ($rate %)';
  }

  @override
  String partnerAccountsStockSummary(String quantity) {
    return 'Stock : $quantity';
  }

  @override
  String partnerAccountsRentalDaily(String amount) {
    return 'Location : $amount / jour';
  }

  @override
  String partnerAccountsRentalMonthly(String amount) {
    return 'Location : $amount / mois';
  }

  @override
  String partnerAccountsPromotionMaximum(String maximum) {
    return 'Remise de $maximum % au maximum.';
  }

  @override
  String partnerAccountsPromotionExceeded(String maximum, String discount) {
    return 'La remise ne peut pas dépasser $maximum % : celle-ci est de $discount %.';
  }

  @override
  String partnerAccountsPromotionPreview(String discount, String price) {
    return 'L’acheteur verra −$discount %, $price FCFA barré.';
  }

  @override
  String partnerAccountsMarginRate(String rate) {
    return 'Marge boutique ($rate %)';
  }

  @override
  String get partnerAccountsMyVehicles => 'Mes véhicules';

  @override
  String get partnerAccountsMyParts => 'Mes pièces détachées';

  @override
  String get partnerAccountsMyAccessories => 'Mes accessoires';

  @override
  String get partnerAccountsAddPart => 'Ajouter une pièce';

  @override
  String get partnerAccountsEditPart => 'Modifier une pièce';

  @override
  String get partnerAccountsAddAccessory => 'Ajouter un accessoire';

  @override
  String get partnerAccountsEditAccessory => 'Modifier un accessoire';

  @override
  String partnersDeleteDescription(String name) {
    return '$name sera retiré de tous les produits.';
  }

  @override
  String partnersRemoveDescription(String name) {
    return 'L’association avec $name sera supprimée.';
  }

  @override
  String get partnerAccountsNetworkError =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String get partnerAccountsSessionResponseInvalid =>
      'La réponse ne correspond pas à une session partenaire.';

  @override
  String get partnerAccountsSessionInvalid =>
      'Cette session partenaire est invalide.';

  @override
  String get partnerAccountsSessionCheckFailed =>
      'Impossible de vérifier votre session. Réessayez.';

  @override
  String get partnerAccountsLoginFailed =>
      'La connexion n’a pas abouti. Réessayez.';

  @override
  String get partnerAccountsRefreshFailed =>
      'Actualisation impossible. Réessayez.';

  @override
  String get privateSalesHomeTitle => 'Les voitures de particuliers';

  @override
  String get privateSalesHomeBody =>
      'Vendez votre voiture depuis votre compte habituel. Une annonce en cours gratuite.';

  @override
  String get privateSalesBrowseAction => 'Voir les annonces';

  @override
  String get privateSalesSellThisVehicle => 'Vendre ce véhicule';

  @override
  String get shellPartnerApplications => 'Validation des partenaires';

  @override
  String get shellPartnerSpace => 'Espace partenaire';

  @override
  String get commonErrorNetwork =>
      'Pas de connexion. Vérifiez votre réseau puis réessayez.';

  @override
  String get commonErrorSessionExpired =>
      'Votre session a expiré. Reconnectez-vous.';

  @override
  String get commonErrorNotFound =>
      'Introuvable. L’élément a peut-être été supprimé.';

  @override
  String get commonErrorUploadTooLarge =>
      'Envoi trop volumineux. Retirez quelques photos ou réduisez-les, puis réessayez.';

  @override
  String get commonErrorServer => 'Erreur du serveur.';

  @override
  String get commonErrorGeneric => 'Une erreur est survenue. Réessayez.';

  @override
  String get commonErrorPermission => 'Votre rôle ne permet pas cette action.';

  @override
  String get commonErrorDisabled =>
      'Ce compte a été désactivé. Contactez le support.';

  @override
  String get commonErrorUnavailable =>
      'Service indisponible pour le moment. Réessayez plus tard.';

  @override
  String get commonErrorThrottled =>
      'Trop de tentatives. Réessayez dans quelques minutes.';

  @override
  String commonErrorReference(String message, String reference) {
    return '$message (réf. $reference)';
  }

  @override
  String get partnerAccountsRequestsHelp =>
      'Les demandes des clients vous parviennent ici dès que la boutique les transmet.';

  @override
  String get garageBrandRequiredMessage => 'Veuillez sélectionner une marque.';

  @override
  String get garageModelRequiredMessage =>
      'Sélectionnez un modèle, ou tapez le vôtre.';

  @override
  String get garageSignInReminderTitle => 'Un compte pour vos rappels';

  @override
  String get garageSignInReminderBody =>
      'Visite technique, assurance, vidange : ces rappels vous sont envoyés, il faut donc savoir à qui.\n\nVotre saisie est conservée.';

  @override
  String get garageSignInLater => 'Plus tard';

  @override
  String get garageSignInAction => 'Se connecter';

  @override
  String get garageSignInCancelled =>
      'Connexion annulée — votre saisie est conservée.';

  @override
  String get garageAddVehicleTitle => 'Ajouter à mon garage';

  @override
  String garageReferencesLoadError(String value0) {
    return 'Impossible de charger les références : $value0';
  }

  @override
  String get garageIdentitySection => 'Identification';

  @override
  String get garageBrandRequiredLabel => 'Marque *';

  @override
  String get garageSelectPlaceholder => 'Sélectionner…';

  @override
  String get garageBrandRequired => 'Marque obligatoire';

  @override
  String get garageModelRequiredLabel => 'Modèle *';

  @override
  String get garageSelectBrandFirst => 'Choisir d\'abord une marque';

  @override
  String get garageModelRequired => 'Modèle obligatoire';

  @override
  String get garageModelExample => 'CX-9, Tribute, Prado…';

  @override
  String get garageEnterModel => 'Indiquez le modèle';

  @override
  String get garageBackToModels => 'Revenir à la liste des modèles';

  @override
  String get garageModelNotListed => 'Mon modèle n\'est pas dans la liste';

  @override
  String get garageManufacturingYearLabel => 'Année de fabrication *';

  @override
  String get garageYearRequired => 'Année obligatoire';

  @override
  String get garageInvalidYear => 'Année invalide';

  @override
  String get garageEngineCompatibilityExplanation =>
      'C\'est elle qui détermine quelles pièces vont sur votre véhicule. La finition suffit souvent à la déduire.';

  @override
  String get garageFuelLabel => 'Carburant';

  @override
  String get garageOptionalDetails => 'Détails (optionnels)';

  @override
  String get garageNicknameLabel => 'Surnom';

  @override
  String get garageNicknameHint => 'Ex. : Ma Corolla, La familiale…';

  @override
  String get garageRegistrationLabel => 'Plaque d\'immatriculation';

  @override
  String get garageRegistrationHint => 'Ex. : AA 1234 BF';

  @override
  String get garageCurrentMileage => 'Kilométrage actuel';

  @override
  String get garageSaving => 'Enregistrement…';

  @override
  String get garageCompatibilityAvailable =>
      'Les pièces compatibles avec ce véhicule pourront être filtrées.';

  @override
  String get garageUnlistedModelCompatibility =>
      'Votre modèle n\'étant pas au catalogue, la recherche de pièces compatibles restera indisponible — même en renseignant le carburant.';

  @override
  String get garageMissingEngineCompatibility =>
      'Sans cette information, la liste des pièces compatibles restera vide. Vous pourrez la compléter plus tard depuis votre garage.';

  @override
  String get garageUnlistedModelServices =>
      'Échéances, kilométrage, contrôles et rappels d\'entretien fonctionneront normalement. Seule la recherche de pièces compatibles restera indisponible : elle s\'appuie sur le catalogue. Votre saisie nous aide à l\'enrichir.';

  @override
  String get garageVinAutomaticTitle => 'Décodage automatique par VIN';

  @override
  String get garageVinAutomaticExplanation =>
      'Saisissez le VIN (numéro de châssis, 17 caractères) et le formulaire sera pré-rempli automatiquement.';

  @override
  String get garageVinLabel => 'VIN (numéro de châssis)';

  @override
  String garageVinLength(String value0) {
    return '$value0/17 caractères';
  }

  @override
  String get garageVinInvalidLength =>
      'Le VIN doit faire exactement 17 caractères.';

  @override
  String get garageVinDecodeAction => 'Décoder';

  @override
  String get garageVinInvalidTitle => 'VIN invalide';

  @override
  String get garageVinCompletedTitle => 'Formulaire pré-rempli';

  @override
  String get garageVinCompletedBody => 'Vérifiez et complétez si nécessaire.';

  @override
  String get garageVinPartialTitle => 'Pré-remplissage partiel';

  @override
  String get garageVinPartialBody =>
      'Certains champs n\'ont pas pu être résolus — vérifiez.';

  @override
  String get garageVinLimitedTitle => 'Données limitées';

  @override
  String get garageVinOfflineYearOnly =>
      'API NHTSA inaccessible — seule l\'année a été décodée localement.';

  @override
  String get garageVinUnknownModel =>
      'Marque ou modèle introuvable dans le catalogue — saisissez manuellement.';

  @override
  String get garageVinNoMatchTitle => 'Aucune correspondance';

  @override
  String get garageVinNoMatchBody => 'Remplissez le formulaire manuellement.';

  @override
  String get garageVinTwoYears => 'Deux années possibles — choisissez :';

  @override
  String garageGenerationMismatch(String value0, String value1) {
    return '$value0 ne correspond peut-être pas à $value1.';
  }

  @override
  String garageGenerationYearMismatch(
    String value0,
    String value1,
    String value2,
  ) {
    return 'La $value0 est produite $value1. Votre véhicule est de $value2.';
  }

  @override
  String get garageGenerationAlternativeQuestion => 'Vouliez-vous celle-ci ?';

  @override
  String garageGenerationAlternatives(String value0) {
    return 'Générations produites en $value0 :';
  }

  @override
  String garageGenerationNoAlternative(String value0) {
    return 'Aucune autre génération de $value0 n\'est enregistrée pour cette année. Vous pouvez continuer : la recherche de pièces sera simplement moins précise.';
  }

  @override
  String garageMatchingPartsForVehicle(String value0) {
    return 'Pièces — $value0';
  }

  @override
  String get garageMatchingPartsTitle => 'Pièces compatibles';

  @override
  String get garageMatchingPartsLimited =>
      'Précision limitée — ajoutez la motorisation pour un résultat plus fin.';

  @override
  String garageMatchingPartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces trouvées',
      one: '1 pièce trouvée',
    );
    return '$_temp0';
  }

  @override
  String get garageUnknownEngineTitle => 'Motorisation inconnue';

  @override
  String get garageNoMatchingPartsTitle =>
      'Aucune pièce déclarée pour ce modèle';

  @override
  String get garageUnknownEngineBody =>
      'Sans la motorisation, impossible de savoir quelles pièces vont sur ce véhicule. Renseignez-la, ou saisissez le numéro de série : il la retrouve tout seul.';

  @override
  String get garageNoVehiclePartsBody =>
      'Aucune pièce du catalogue n\'est rattachée à ce véhicule pour le moment.';

  @override
  String garageNoModelPartsBody(String value0) {
    return 'Aucune pièce du catalogue n\'est rattachée à ce modèle — une $value0 — pour le moment.';
  }

  @override
  String get garageCompleteVehicleAction => 'Compléter mon véhicule';

  @override
  String get garageBrowseAllPartsAction => 'Parcourir toutes les pièces';

  @override
  String get garageRefillsTitle => 'Passages à la pompe';

  @override
  String garageFuelForVehicle(String value0) {
    return 'Carburant — $value0';
  }

  @override
  String get garageRefillLabel => 'Passage';

  @override
  String get garageRefillSaved => 'Passage enregistré.';

  @override
  String get garageFullRefillExplanation =>
      'Plein — la pompe s\'est arrêtée toute seule';

  @override
  String get garagePartialRefill => 'Demi-plein';

  @override
  String garageRefillSummary(String value0, String value1, String value2) {
    return '$value0 km · $value1 l$value2';
  }

  @override
  String get garageFullRefill => 'Plein';

  @override
  String garageRefillConsumption(String value0, String value1, String value2) {
    return '$value0 l/100 km$value1$value2';
  }

  @override
  String get garageDeleteRefillAction => 'Supprimer ce passage';

  @override
  String get garageDeleteRefillTitle => 'Supprimer ce passage ?';

  @override
  String get garageRefillDeleted => 'Passage supprimé.';

  @override
  String get garageDeleteTwoIntervals =>
      'Ce passage ferme une mesure et en ouvre une autre. En le supprimant, ces deux mesures disparaissent et leurs intervalles n\'en font plus qu\'un, deux fois plus long : votre consommation sera recalculée dessus, et elle peut changer beaucoup.';

  @override
  String get garageDeleteOneInterval =>
      'Ce passage ferme une des mesures retenues. En le supprimant, cette mesure disparaît et votre consommation sera recalculée.';

  @override
  String get garageDeleteRefillLitres =>
      'Les litres de ce passage sortiront du calcul et votre consommation sera recalculée.';

  @override
  String get garageNoRefillsTitle => 'Aucun passage enregistré';

  @override
  String get garageNoRefillsBody =>
      'Notez ce que vous mettez à la pompe : le montant et le prix au litre suffisent. Après deux pleins, l\'application vous dit ce que votre véhicule consomme vraiment, et vous prévient le jour où ça monte.';

  @override
  String get garageSignInGarageTitle =>
      'Connectez-vous pour accéder à votre garage';

  @override
  String get garageSignInGarageBody =>
      'Retrouvez rapidement les pièces compatibles avec vos véhicules.';

  @override
  String get garageSignInOrRegister => 'Se connecter / S\'inscrire';

  @override
  String get garageTitle => 'Mon garage';

  @override
  String get garageRefreshAction => 'Actualiser';

  @override
  String get garageAccountTitle => 'Mon compte';

  @override
  String get garageAddVehicleAction => 'Ajouter un véhicule';

  @override
  String get garageSignOutAction => 'Se déconnecter';

  @override
  String get garageSignedOut => 'Vous êtes déconnecté.';

  @override
  String get garageDeleteAccountTitle => 'Supprimer mon compte';

  @override
  String get garageAccountDeleted =>
      'Votre compte et vos données ont été supprimés.';

  @override
  String get garageAccountDeletionListTitle =>
      'Seront supprimés définitivement :';

  @override
  String get garageAccountDeletionList =>
      '• vos véhicules et leurs échéances\n• vos demandes de recherche\n• vos notifications\n• votre compte de connexion';

  @override
  String get garageInvoicesRetained =>
      'Les factures des commandes déjà honorées sont conservées, la comptabilité l\'impose.';

  @override
  String garageDeleteAccountConfirmText(String value0) {
    return 'Pour confirmer, saisissez $value0 :';
  }

  @override
  String get garageDeletePermanently => 'Supprimer définitivement';

  @override
  String garageMileageValue(String value0) {
    return '$value0 km';
  }

  @override
  String get garagePreciseCompatibility => 'Compatibilité précise';

  @override
  String get garageTrackDeadlinesAction => 'Suivre mes échéances';

  @override
  String get garageCheckVehicleAction => 'Contrôler mon véhicule';

  @override
  String get garageRepeatCheckAction => 'Refaire un contrôle';

  @override
  String get garageSellThisVehicle => 'Vendre ce véhicule';

  @override
  String get garageUpdateAction => 'Mettre à jour';

  @override
  String garageCompactThousands(String value0) {
    return '$value0 k';
  }

  @override
  String get garageServiceMissingBoth =>
      'Renseignez le kilométrage ci-dessus, ainsi que le kilométrage actuel du véhicule via « Mettre à jour ».';

  @override
  String get garageServiceMissingLastMileage =>
      'Renseignez le kilométrage de la dernière vidange ci-dessus.';

  @override
  String get garageServiceMissingCurrentMileage =>
      'Renseignez le kilométrage actuel du véhicule via « Mettre à jour ».';

  @override
  String get garageMaintenanceTitle => 'Échéances d\'entretien';

  @override
  String get garageMaintenanceReminders =>
      'Vous serez prévenu 30 jours avant, puis en cas de dépassement.';

  @override
  String get garageInspectionLabel => 'Visite technique';

  @override
  String get garageInsuranceLabel => 'Assurance';

  @override
  String get garageOilChangeLabel => 'Vidange';

  @override
  String get garageLastOilChangeMileage => 'Kilométrage de la dernière vidange';

  @override
  String get garageOilReminderMileageExplanation =>
      'Le rappel de vidange dépend du kilométrage que vous tenez à jour.';

  @override
  String get garageClearAction => 'Effacer';

  @override
  String garageLastCheckTitle(String value0) {
    return 'Dernier contrôle · $value0';
  }

  @override
  String get garageCheckNothingToFix => 'Rien à reprendre';

  @override
  String get garageCheckOnePointToFix => '1 point à reprendre';

  @override
  String garageCheckPointsToFix(String value0) {
    return '$value0 points à reprendre';
  }

  @override
  String garageDaysAgoLower(String value0) {
    return 'il y a $value0 jours';
  }

  @override
  String get garageLastWeekLower => 'la semaine dernière';

  @override
  String garageWeeksAgoLower(String value0) {
    return 'il y a $value0 semaines';
  }

  @override
  String garageMonthsAgoLower(String value0) {
    return 'il y a $value0 mois';
  }

  @override
  String get garageRemoveVehicleAction => 'Retirer du garage';

  @override
  String get garageRemoveVehicleTitle => 'Retirer du garage ?';

  @override
  String garageRemoveVehicleBody(String value0) {
    return '$value0 sera retiré de votre garage. Cette action est irréversible.';
  }

  @override
  String get garageRemoveAction => 'Retirer';

  @override
  String get garageEmptyTitle => 'Votre garage est vide';

  @override
  String get garageEmptyBody =>
      'Ajoutez vos véhicules pour retrouver rapidement les pièces compatibles.';

  @override
  String get garageProfileTitle => 'Mon profil';

  @override
  String get garageStaffLabel => 'Staff';

  @override
  String garageCheckRejected(String value0) {
    return 'Le contrôle n\'a pas été accepté : $value0\nCorrige la saisie, puis termine à nouveau.';
  }

  @override
  String garageCheckDeferred(String value0) {
    return 'Envoi impossible pour le moment : $value0\nLe contrôle est gardé sur ce téléphone et repartira dès que le réseau revient.';
  }

  @override
  String get garageVehicleFallback => 'Mon véhicule';

  @override
  String get garageCheckFinishedTitle => 'Contrôle terminé';

  @override
  String get garageCheckWaitingToSend =>
      'Un contrôle rempli n\'est pas encore parti. Il repartira dès que le réseau revient.';

  @override
  String get garageTripDestinationQuestion => 'Où vas-tu ?';

  @override
  String garageTripOptionDistance(String value0, String value1) {
    return '$value0 · $value1 km';
  }

  @override
  String get garageOdometerLabel => 'Kilométrage au compteur';

  @override
  String get garageOdometerExplanation =>
      'Tu es devant le tableau de bord : c\'est le moment. Sans ce relevé, le rappel de vidange ne peut pas partir.';

  @override
  String get garageCheckComposing => 'Composition…';

  @override
  String get garageViewCheckItems => 'Voir ce qu\'il faut vérifier';

  @override
  String garageTripCheckItemsExplanation(String value0) {
    return '$value0 points pour ce véhicule et ce trajet. Ils ne sont pas les mêmes pour tous : chacun dit pourquoi il est là.';
  }

  @override
  String garageSeasonCheckItemsExplanation(String value0) {
    return '$value0 points à vérifier une fois avant la saison, pas à chaque trajet.';
  }

  @override
  String get garageChooseTripAction => 'Choisir le trajet';

  @override
  String garageChangeTripDistance(String value0) {
    return 'Trajet de $value0 km · Modifier';
  }

  @override
  String get garageChangeCheckAction => 'Changer de contrôle';

  @override
  String get garageFinishCheckAction => 'Terminer le contrôle';

  @override
  String get garageCheckOkay => 'Correct';

  @override
  String get garageCheckWatch => 'À surveiller';

  @override
  String get garageCheckFault => 'Défaut';

  @override
  String get garageCheckOneUnchecked => '1 point n\'a pas été vérifié.';

  @override
  String garageCheckUnchecked(String value0) {
    return '$value0 points n\'ont pas été vérifiés.';
  }

  @override
  String garageCheckOdometerRecorded(String value0) {
    return 'Compteur relevé : $value0 km';
  }

  @override
  String get garageCheckFixNow => 'À régler';

  @override
  String get garageCheckCanWait => 'Peut attendre';

  @override
  String get garageBackToGarageAction => 'Revenir au garage';

  @override
  String get garageViewPartsAction => 'Voir les pièces';

  @override
  String garageConsumptionValue(String value) {
    return 'Référence : $value L/100 km';
  }

  @override
  String garageFuelCostValue(String value0) {
    return '$value0 FCFA/100 km';
  }

  @override
  String garageConsumptionMeasuredOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mesuré sur $count intervalles',
      one: 'mesuré sur 1 intervalle',
    );
    return '$_temp0';
  }

  @override
  String garageLitresValue(String value0) {
    return '$value0 l';
  }

  @override
  String garageCurrencyValue(String value0) {
    return '$value0 FCFA';
  }

  @override
  String get garageSinceFirstRefill => 'depuis votre premier passage';

  @override
  String get garageNeedTwoFullRefills =>
      'Deux pleins — pompe arrêtée toute seule — et votre consommation réelle s\'affiche ici.';

  @override
  String get garageNeedOneFullRefill =>
      'Encore un plein et votre consommation réelle s\'affiche ici.';

  @override
  String get garageTrackConsumptionAction => 'Suivre ma consommation';

  @override
  String get garageTrackConsumptionBody =>
      'Enregistrez vos passages à la pompe : l\'application calcule ce que vous consommez vraiment.';

  @override
  String get garageConsumptionIncreased => 'Votre consommation a augmenté.';

  @override
  String garageConsumptionIncreasedCompared(String value0, String value1) {
    return 'Votre consommation a augmenté : $value0 l/100 km contre $value1 d\'habitude.';
  }

  @override
  String get garageConsumptionCommonCauses =>
      'Filtre à air encrassé, pression des pneus : ce sont les deux causes les plus courantes.';

  @override
  String get garageOdometerReplacedExplanation =>
      'Compteur remplacé : les passages d\'avant restent dans votre historique, mais n\'entrent plus dans ce calcul.';

  @override
  String get garageOfficialConsumptionUnknown => 'Cote constructeur inconnue';

  @override
  String garageOfficialConsumptionValue(String value0) {
    return 'Cote constructeur $value0 l/100 km';
  }

  @override
  String get garageSpecifyEngineAction => 'Préciser';

  @override
  String get garageChangeAction => 'Changer';

  @override
  String get garageRecordRefillTitle => 'Passage à la pompe';

  @override
  String garageRefillHistoryCount(String value0) {
    return 'Historique ($value0)';
  }

  @override
  String get garageConsumptionQuestion => 'Quelle est ma consommation ?';

  @override
  String garageOfficialCityHighway(String value0, String value1) {
    return 'ville $value0 · route $value1';
  }

  @override
  String get garageConsumptionNoModel =>
      'Consommation indisponible : le modèle de ce véhicule n\'est pas encore au catalogue.';

  @override
  String get garageEnginesUnavailable =>
      'Liste des motorisations indisponible. Réessayez plus tard.';

  @override
  String get garageNoOfficialConsumption =>
      'Aucune donnée officielle de consommation pour ce modèle.';

  @override
  String get garageEngineSaved => 'Motorisation enregistrée.';

  @override
  String garageEngineForVehicle(String value0) {
    return 'Motorisation de votre $value0';
  }

  @override
  String get garageChooseEngineExplanation =>
      'Choisissez le moteur qui se trouve sous le capot. La finition ne change pas la consommation.';

  @override
  String get garageEngineSavedCompatibility =>
      'Motorisation enregistrée : les pièces compatibles sont à jour.';

  @override
  String get garageFuelQuestion => 'Avec quel carburant roule ce véhicule ?';

  @override
  String get garageRefillAmountPaid => 'Montant payé';

  @override
  String get garageRefillPricePerLitre => 'Prix au litre';

  @override
  String get garageRefillLitres => 'Litres pris';

  @override
  String get garageRefillValueUnchanged => 'Enregistré tel quel.';

  @override
  String get garageRefillLitresCalculated =>
      'Les litres se déduisent du montant et du prix.';

  @override
  String garageRefillCalculatedLitres(String value0) {
    return 'Soit $value0 l';
  }

  @override
  String get garageRefillEnterAmount => 'Saisir le montant payé';

  @override
  String get garageRefillKnowLitres => 'Je connais les litres';

  @override
  String get garageRefillFullTankExplanation =>
      'Plein = la pompe s\'est arrêtée toute seule. Seul un plein permet de mesurer la consommation.';

  @override
  String get garageRefillMileageRequired =>
      'Indiquez le kilométrage au compteur.';

  @override
  String get garageRefillLitresRange =>
      'Les litres doivent être compris entre 1 et 200.';

  @override
  String get garageRefillImpossibleQuantity =>
      'Montant et prix au litre donnent une quantité impossible.';

  @override
  String get garageMileageRequired => 'Entrez un nombre de kilomètres.';

  @override
  String get garageMileageOutOfRange => 'Ce kilométrage est hors de portée.';

  @override
  String garageMileageConfirmDecrease(String value0, String value1) {
    return 'Le compteur affichait $value0 km. Appuyez à nouveau pour enregistrer $value1 km.';
  }

  @override
  String get garageConfirmAction => 'Confirmer';

  @override
  String get garageSaveMileageAction => 'Sauvegarder';

  @override
  String get needsMyNeedsTitle => 'Mes besoins';

  @override
  String get needsNewNeedAction => 'Nouveau besoin';

  @override
  String needsYearFromValue(String value0) {
    return 'À partir de $value0';
  }

  @override
  String needsBudgetValue(String value0) {
    return 'Budget : $value0';
  }

  @override
  String get needsToday => 'Aujourd\'hui';

  @override
  String get needsYesterday => 'Hier';

  @override
  String needsDaysAgo(String value0) {
    return 'Il y a $value0 jours';
  }

  @override
  String get needsBodyHatchback => 'Compacte';

  @override
  String get needsBodyPickup => 'Pick-up';

  @override
  String get needsBodyVan => 'Camionnette';

  @override
  String get needsBodyBus => 'Bus';

  @override
  String get needsEmptyMineTitle => 'Aucun besoin déposé';

  @override
  String get needsEmptyMineBody =>
      'Exprimez votre recherche — nous vous\ncontacterons dès qu\'une offre correspond.';

  @override
  String get needsStaffListTitle => 'Besoins clients';

  @override
  String get needsStatusPending => 'En attente';

  @override
  String get needsStatusApproved => 'Transmise';

  @override
  String get needsStatusContacted => 'Contacté';

  @override
  String get needsStatusFulfilled => 'Satisfait';

  @override
  String get needsStatusCancelled => 'Annulé';

  @override
  String get needsTypePart => 'Pièce';

  @override
  String get needsTypeAccessory => 'Accessoire';

  @override
  String get needsFilterAll => 'Tous';

  @override
  String get needsFilterAllTypes => 'Tous types';

  @override
  String needsMaximumBudgetValue(String value0) {
    return 'Budget max : $value0';
  }

  @override
  String get needsNoContact => 'Aucun contact renseigné';

  @override
  String get needsUpdateAction => 'Mettre à jour';

  @override
  String needsTodayAtTime(String value0, String value1) {
    return 'Aujourd\'hui $value0:$value1';
  }

  @override
  String get needsUpdateStatusTitle => 'Mettre à jour le statut';

  @override
  String get needsStaffNotesLabel => 'Notes internes (optionnel)';

  @override
  String get needsStaffNotesHint =>
      'Ex. : Client rappelé le 02/09, devis envoyé…';

  @override
  String get needsEmptyPendingTitle => 'Aucun besoin en attente';

  @override
  String get needsEmptyResultsTitle => 'Aucun besoin trouvé';

  @override
  String get needsEmptyStaffBody =>
      'Les besoins soumis par les clients\napparaîtront ici.';

  @override
  String get needsSubmittedTitle => 'Besoin enregistré !';

  @override
  String get needsSubmittedBody =>
      'Nous avons bien reçu votre demande.\nNotre équipe vous contactera dès qu\'une offre correspondante sera disponible.';

  @override
  String get needsSubmittedConfirm => 'Compris';

  @override
  String get needsSignInRequiredTitle => 'Connexion requise';

  @override
  String get needsSignInRequiredBody =>
      'Vous devez être connecté pour déposer un besoin.';

  @override
  String get needsSignInAction => 'Se connecter';

  @override
  String get needsIntroduction =>
      'Vous ne trouvez pas ce que vous cherchez ? Déposez votre besoin — nous vous contacterons dès qu\'une offre correspondante sera disponible.';

  @override
  String get needsTypeLabel => 'Type de recherche';

  @override
  String get needsDescriptionLabel => 'Description du besoin *';

  @override
  String get needsVehicleDescriptionHint =>
      'Couleur préférée, kilométrage max, options souhaitées…';

  @override
  String get needsPartDescriptionHint =>
      'Référence, compatibilité véhicule, état souhaité…';

  @override
  String get needsAccessoryDescriptionHint =>
      'Dimensions, compatibilité, couleur…';

  @override
  String get needsDescriptionRequired =>
      'Décrivez votre besoin (10 caractères minimum).';

  @override
  String get needsBudgetLabel => 'Budget maximum (optionnel)';

  @override
  String get needsBudgetInvalid => 'Montant invalide';

  @override
  String get needsCallbackPhoneLabel => 'Téléphone pour vous rappeler *';

  @override
  String get needsCallbackPhoneExplanation =>
      'Sans numéro, nous ne pouvons pas vous répondre. Vous pouvez en donner un second, d’un autre opérateur.';

  @override
  String get needsPrimaryPhoneLabel => 'Numéro principal';

  @override
  String get needsSecondaryPhoneLabel => 'Autre numéro (optionnel)';

  @override
  String get needsPhoneRequired => 'Indiquez un numéro.';

  @override
  String get needsPhoneTooShort => 'Numéro trop court.';

  @override
  String get needsRemovePhoneAction => 'Retirer ce numéro';

  @override
  String get needsAddPhoneAction => 'Ajouter un numéro';

  @override
  String needsCustomerAccountNotice(String value0) {
    return 'Connecté en tant que $value0 — votre demande sera liée à votre compte.';
  }

  @override
  String needsStaffAccountNotice(String value0) {
    return 'Saisie par $value0, pour le compte d’un client. La demande ne sera rattachée à aucun compte : le numéro ci-dessus est le seul moyen de le rappeler.';
  }

  @override
  String get needsSubmitAction => 'Soumettre mon besoin';

  @override
  String get needsVehicleCriteriaTitle => 'Critères du véhicule recherché';

  @override
  String get needsBrandsLoadError => 'Impossible de charger les marques.';

  @override
  String get needsAnyBrand => 'Toutes marques';

  @override
  String get needsModelsLoadError => 'Impossible de charger les modèles.';

  @override
  String get needsNoModels => 'Aucun modèle disponible pour cette marque.';

  @override
  String get needsAnyModel => 'Tous modèles';

  @override
  String get needsAnyOption => 'Peu importe';

  @override
  String get needsYearFromLabel => 'De';

  @override
  String needsYearRangeInvalid(String value0) {
    return 'Année invalide (1950–$value0)';
  }

  @override
  String get needsYearEndBeforeStart => 'Doit être ≥ année de départ';

  @override
  String get needsPartCriteriaTitle => 'Critères de la pièce recherchée';

  @override
  String get needsCategoriesLoadError =>
      'Impossible de charger les catégories.';

  @override
  String get needsAnyCategory => 'Toutes catégories';

  @override
  String get needsManufacturerOptionalLabel => 'Fabricant (optionnel)';

  @override
  String get needsAnyManufacturer => 'Tous fabricants';

  @override
  String get needsOemOptionalLabel => 'Référence OEM (optionnel)';

  @override
  String get needsOemHint => 'Ex: 90915-YZZD4';

  @override
  String get needsOemTooLong => 'Référence trop longue (max 100 caractères)';

  @override
  String get needsAccessoryCriteriaTitle =>
      'Critères de l\'accessoire recherché';

  @override
  String get needsBrandManufacturerOptional => 'Marque / Fabricant (optionnel)';

  @override
  String get needsCriteriaExplanation =>
      'Plus vous précisez, mieux nous ciblons les offres.';

  @override
  String get garageEngineMissingTitle => 'Motorisation non renseignée';

  @override
  String get garageEngineMissingBody =>
      'Sans elle, impossible de savoir quelles pièces vont sur ce véhicule.';

  @override
  String get garageCompleteAction => 'Compléter';

  @override
  String get garageTripCity => 'En ville';

  @override
  String get garageTripHundredKm => 'Une centaine de km';

  @override
  String get garageTripOtherCity => 'Une autre ville';

  @override
  String get garageTripOtherRegion => 'Une autre région';

  @override
  String get garageTripOtherCountry => 'Un autre pays';

  @override
  String get garageRecentlyLower => 'récemment';

  @override
  String get garageTodayLower => 'aujourd\'hui';

  @override
  String get garageYesterdayLower => 'hier';

  @override
  String get garageNoInterval => 'Aucun';

  @override
  String get vehiclesUpdated => 'Véhicule mis à jour ✓';

  @override
  String get vehiclesCreated => 'Véhicule enregistré — ajoutez des photos !';

  @override
  String get vehiclesSaveFailed => 'Enregistrement impossible';

  @override
  String get vehiclesBuyerPriceLabel => 'Prix affiché à l’acheteur';

  @override
  String get vehiclesBuyerRateLabel => 'Tarif affiche a l’acheteur';

  @override
  String get vehiclesOk => 'OK';

  @override
  String get vehiclesEditTitle => 'Modifier le véhicule';

  @override
  String get vehiclesCreateTitle => 'Enregistrer un véhicule';

  @override
  String get vehiclesPhotos => 'Photos';

  @override
  String get vehiclesTypeTitle => 'Type de véhicule';

  @override
  String get vehiclesTypePassenger => 'Particulier';

  @override
  String get vehiclesTypeUtility => 'Utilitaire';

  @override
  String get vehiclesTypeHeavy => 'Poids lourd';

  @override
  String get vehiclesBodyStyleLabel => 'Carrosserie *';

  @override
  String get vehiclesBodyStyleHint => 'Berline, SUV, Pickup…';

  @override
  String get vehiclesBodyStyleRequired => 'Sélectionne un type de carrosserie';

  @override
  String get vehiclesVinOptional => 'VIN (optionnel)';

  @override
  String get vehiclesVinHelper =>
      '17 caractères — numéro de châssis international';

  @override
  String get vehiclesVinLengthError =>
      'Le VIN doit faire exactement 17 caractères.';

  @override
  String get vehiclesRegisteredLabel => 'Véhicule immatriculé';

  @override
  String get vehiclesRegisteredHint =>
      'Déjà immatriculé — la plaque peut être ajoutée plus tard.';

  @override
  String get vehiclesImportedHint => 'Importé, pas encore immatriculé ici.';

  @override
  String get vehiclesRegistrationRemovalWarning =>
      'Ce véhicule est enregistré comme immatriculé. En le déclarant importé, ses informations d’immatriculation seront supprimées. Ressaisissez le kilométrage : il ne mesure pas la même chose pour un véhicule immatriculé et pour un import.';

  @override
  String get vehiclesPlateOptional => 'Plaque d\'immatriculation (optionnel)';

  @override
  String get vehiclesPlateHint => 'Ex. : AA 1234 BF';

  @override
  String get vehiclesIdentityTitle => 'Identité';

  @override
  String get vehiclesBrandLabel => 'Marque *';

  @override
  String get vehiclesBrandRequired => 'Marque obligatoire';

  @override
  String get vehiclesModelLabel => 'Modèle *';

  @override
  String get vehiclesModelRequired => 'Modèle obligatoire';

  @override
  String get vehiclesManufactureYearLabel => 'Année de fabrication *';

  @override
  String get vehiclesYearRequired => 'Année obligatoire';

  @override
  String get vehiclesTransmissionManualSummary => 'manuelle';

  @override
  String get vehiclesTransmissionAutomaticSummary => 'automatique';

  @override
  String get vehiclesOfferRentSummary => 'location';

  @override
  String get vehiclesOfferBothSummary => 'vente et location';

  @override
  String get vehiclesOfferSaleSummary => 'vente';

  @override
  String get vehiclesTechnicalTitle => 'Caractéristiques techniques';

  @override
  String get vehiclesEngineTypeLabel => 'Type de motorisation *';

  @override
  String get vehiclesEngineTypeRequired => 'Motorisation obligatoire';

  @override
  String get vehiclesTransmissionLabel => 'Boîte de vitesses';

  @override
  String get vehiclesDrivetrainLabel => 'Roues motrices';

  @override
  String get vehiclesPowerLabel => 'Puissance (ch)';

  @override
  String get vehiclesFeaturesTitle => 'Équipements & options';

  @override
  String get vehiclesFeaturesHint =>
      'Sélectionnez les équipements présents sur ce véhicule.';

  @override
  String get vehiclesCommercialTitle => 'Informations commerciales';

  @override
  String get vehiclesConditionLabel => 'État du véhicule';

  @override
  String get vehiclesConditionDamaged => 'Endommagé';

  @override
  String get vehiclesOriginCountryLabel => 'Pays d\'origine';

  @override
  String get vehiclesOriginCountryHint => 'Provenance du véhicule importé';

  @override
  String get vehiclesAvailabilityLabel => 'Disponible pour';

  @override
  String get vehiclesForSale => 'Vente';

  @override
  String get vehiclesForRent => 'Location';

  @override
  String get vehiclesForBoth => 'Vente & Location';

  @override
  String get vehiclesDealLabel => 'Mise en avant';

  @override
  String get vehiclesNoDeal => 'Aucune';

  @override
  String get vehiclesGoodDeal => 'Bonne affaire';

  @override
  String get vehiclesFlashSale => 'Vente flash';

  @override
  String get vehiclesClearance => 'Déstockage';

  @override
  String get vehiclesSalePriceLabel => 'Prix de vente *';

  @override
  String get vehiclesSalePriceRequired => 'Prix de vente obligatoire';

  @override
  String get vehiclesDailyRateLabel => 'Tarif journalier';

  @override
  String get vehiclesMonthlyRateLabel => 'Tarif mensuel';

  @override
  String get vehiclesRentalRateRequired =>
      'Saisissez un tarif journalier, hebdomadaire ou mensuel';

  @override
  String get vehiclesRentalRateHint =>
      'Renseignez au moins un tarif : par jour, par semaine ou par mois.';

  @override
  String get vehiclesDepositLabel => 'Caution';

  @override
  String get vehiclesNegotiable => 'Prix négociable';

  @override
  String get vehiclesBranchLabel => 'Agence / Showroom';

  @override
  String get vehiclesSiteLabel => 'Site / Agence';

  @override
  String get vehiclesSiteHint => 'Ex. : Showroom Ouagadougou Nord';

  @override
  String get vehiclesSupplierLabel => 'Fournisseur / Partenaire source';

  @override
  String get vehiclesSupplierHint =>
      'Source du véhicule (importateur, enchère, concessionnaire partenaire…)';

  @override
  String get vehiclesPartnersLoadFailed =>
      'Impossible de charger les partenaires.';

  @override
  String get vehiclesNoneOptional => 'Aucun (optionnel)';

  @override
  String get vehiclesNone => 'Aucun';

  @override
  String get vehiclesDescriptionHint =>
      'Détails supplémentaires sur le véhicule…';

  @override
  String get vehiclesNext => 'Suivant';

  @override
  String get vehiclesBack => 'Retour';

  @override
  String get vehiclesFeatureStandard => 'Dotation standard';

  @override
  String get vehiclesFeatureComfort => 'Confort';

  @override
  String get vehiclesFeatureSafety => 'Sécurité';

  @override
  String get vehiclesFeatureMultimedia => 'Multimédia';

  @override
  String get vehiclesFeatureDriverAssistance => 'Aides à la conduite';

  @override
  String get vehiclesFeatureOther => 'Autres';

  @override
  String get vehiclesFeatureStandardHint => '— cochez ce qui est présent';

  @override
  String get vehiclesErrorNetworkTitle => 'Pas de connexion';

  @override
  String get vehiclesErrorSessionTitle => 'Session expirée';

  @override
  String get vehiclesErrorForbiddenTitle => 'Action non autorisée';

  @override
  String get vehiclesErrorValidationTitle => 'Formulaire incomplet';

  @override
  String get vehiclesErrorTooLargeTitle => 'Envoi trop volumineux';

  @override
  String get vehiclesErrorThrottledTitle => 'Trop de tentatives';

  @override
  String get vehiclesErrorServerTitle => 'Erreur du serveur';

  @override
  String get vehiclesFaultDeclare => 'Déclarer';

  @override
  String get vehiclesFaultResolve => 'Résoudre';

  @override
  String get vehiclesFaultDrivingAffected => 'Conduite affectée';

  @override
  String get vehiclesFaultDisclosed => 'Divulguée acheteur';

  @override
  String get vehiclesFaultDeleteTitle => 'Supprimer cette panne ?';

  @override
  String get vehiclesFaultEmpty => 'Aucune panne déclarée';

  @override
  String get vehiclesFaultEmptyStaffHint =>
      'Déclarez les défauts connus pour informer les acheteurs.';

  @override
  String get vehiclesFaultEmptyViewerHint =>
      'Ce véhicule ne présente aucun défaut connu.';

  @override
  String get vehiclesFaultCreateTitle => 'Déclarer une panne';

  @override
  String get vehiclesFaultTitleLabel => 'Titre *';

  @override
  String get vehiclesFaultTitleHint => 'Ex. : Fuite d\'huile moteur';

  @override
  String get vehiclesFaultTitleRequired => 'Le titre est obligatoire';

  @override
  String get vehiclesFaultCategoryLabel => 'Catégorie *';

  @override
  String get vehiclesFaultSeverityLabel => 'Sévérité *';

  @override
  String get vehiclesFaultAffectsDriving => 'Affecte la conduite';

  @override
  String get vehiclesFaultDrivingHint =>
      'Le véhicule est difficile ou dangereux à conduire';

  @override
  String get vehiclesFaultSafetyCritical => 'Critique pour la sécurité';

  @override
  String get vehiclesFaultDisclosureLabel => 'Divulguée à l\'acheteur';

  @override
  String get vehiclesFaultDisclosureHint =>
      'Cette panne est mentionnée dans l\'annonce';

  @override
  String get vehiclesFaultDescriptionLabel => 'Description (optionnel)';

  @override
  String get vehiclesFaultDescriptionHint =>
      'Détails sur la panne, symptômes, conditions…';

  @override
  String get vehiclesFaultObdLabel => 'Code OBD (optionnel)';

  @override
  String get vehiclesFaultObdHint => 'Ex. : P0301';

  @override
  String get vehiclesFaultDetectionDate => 'Date de détection (optionnel)';

  @override
  String get vehiclesDateHint => 'AAAA-MM-JJ';

  @override
  String get vehiclesFaultDetectionMileage =>
      'Kilométrage à la détection (optionnel)';

  @override
  String get vehiclesFaultEstimatedCost =>
      'Coût estimé de réparation (optionnel)';

  @override
  String get vehiclesAmountInvalid => 'Montant invalide';

  @override
  String get vehiclesFaultReportedBy => 'Signalé par (optionnel)';

  @override
  String get vehiclesFaultReporterHint => 'Nom du technicien ou du client';

  @override
  String get vehiclesFaultSave => 'Enregistrer la panne';

  @override
  String get vehiclesFaultRepairDate => 'Date de réparation';

  @override
  String get vehiclesFaultActualCost => 'Coût réel de réparation (optionnel)';

  @override
  String get vehiclesFaultMarkRepaired => 'Marquer comme réparée';

  @override
  String get vehiclesFaultCategoryEngine => 'Moteur';

  @override
  String get vehiclesFaultCategoryTransmission => 'Transmission';

  @override
  String get vehiclesFaultCategoryElectrical => 'Électricité';

  @override
  String get vehiclesFaultCategoryBraking => 'Freinage';

  @override
  String get vehiclesFaultCategorySuspension => 'Suspension';

  @override
  String get vehiclesFaultCategorySteering => 'Direction';

  @override
  String get vehiclesFaultCategoryCooling => 'Refroidissement';

  @override
  String get vehiclesFaultCategoryAirConditioning => 'Climatisation';

  @override
  String get vehiclesFaultCategoryBodywork => 'Carrosserie';

  @override
  String get vehiclesFaultCategoryInterior => 'Intérieur';

  @override
  String get vehiclesFaultCategoryElectronics => 'Électronique';

  @override
  String get vehiclesFaultCategoryTyres => 'Pneumatiques';

  @override
  String get vehiclesFaultCategoryOther => 'Autre';

  @override
  String get vehiclesFaultSeverityMinor => 'Mineur';

  @override
  String get vehiclesFaultSeverityModerate => 'Modéré';

  @override
  String get vehiclesFaultSeverityMajor => 'Majeur';

  @override
  String get vehiclesFaultSeverityCritical => 'Critique';

  @override
  String get vehiclesFaultStatusDeclared => 'Déclaré';

  @override
  String get vehiclesFaultStatusDiagnosed => 'Diagnostiqué';

  @override
  String get vehiclesFaultStatusQuoted => 'Devisé';

  @override
  String get vehiclesFaultStatusRepairing => 'En réparation';

  @override
  String get vehiclesFaultStatusRepaired => 'Réparé';

  @override
  String get vehiclesFaultStatusWontFix => 'Sans suite';

  @override
  String vehiclesMissingStep(int step) {
    return 'Il manque quelque chose à l\'étape $step.';
  }

  @override
  String vehiclesYearRangeInvalid(int year) {
    return 'Année invalide (1950–$year)';
  }

  @override
  String vehiclesPowerSummary(String power) {
    return '$power ch';
  }

  @override
  String vehiclesOfferSummary(String offer, String price) {
    return '$offer · $price FCFA';
  }

  @override
  String vehiclesReferencesLoadError(String error) {
    return 'Impossible de charger les référentiels :\n$error';
  }

  @override
  String vehiclesFaultEstimatedCostValue(String cost) {
    return 'Estimé : $cost';
  }

  @override
  String vehiclesFaultActualCostValue(String cost) {
    return 'Réel : $cost';
  }

  @override
  String vehiclesFaultResolveTitle(String title) {
    return 'Résoudre : $title';
  }

  @override
  String get catalogAdminSelectCategory =>
      'Veuillez sélectionner une catégorie.';

  @override
  String get catalogAdminPartUpdated => 'Pièce mise à jour.';

  @override
  String get catalogAdminPartCreated =>
      'Pièce enregistrée — ajoutez des photos !';

  @override
  String get catalogAdminAccessoryUpdated => 'Accessoire mis à jour.';

  @override
  String get catalogAdminAccessoryCreated =>
      'Accessoire enregistré — ajoutez des photos !';

  @override
  String get catalogAdminEditPart => 'Modifier la pièce';

  @override
  String get catalogAdminNewPart => 'Nouvelle pièce';

  @override
  String get catalogAdminEditAccessory => 'Modifier l\'accessoire';

  @override
  String get catalogAdminNewAccessory => 'Nouvel accessoire';

  @override
  String get catalogAdminIdentification => 'Identification';

  @override
  String get catalogAdminNameLabel => 'Désignation *';

  @override
  String get catalogAdminRequired => 'Requis';

  @override
  String get catalogAdminSkuLabel => 'SKU / Référence interne';

  @override
  String get catalogAdminPartSkuHint => 'Ex. PDT-BRQ-0042 (optionnel)';

  @override
  String get catalogAdminAccessorySkuHint => 'Ex. ACC-EST-0012 (optionnel)';

  @override
  String get catalogAdminTypeLabel => 'Type *';

  @override
  String get catalogAdminConditionLabel => 'État *';

  @override
  String get catalogAdminConditionNew => 'Neuve';

  @override
  String get catalogAdminConditionRefurbished => 'Reconditionnée';

  @override
  String get catalogAdminConditionUsed => 'D\'occasion';

  @override
  String get catalogAdminClassification => 'Classification';

  @override
  String get catalogAdminCategoryLabel => 'Catégorie *';

  @override
  String get catalogAdminManufacturerLabel => 'Fabricant / Équipementier';

  @override
  String get catalogAdminPricing => 'Tarification';

  @override
  String get catalogAdminSalePrice => 'Prix de vente *';

  @override
  String get catalogAdminInvalidNumber => 'Nombre invalide';

  @override
  String get catalogAdminPurchasePrice => 'Prix d\'achat';

  @override
  String get catalogAdminOptional => 'Optionnel';

  @override
  String get catalogAdminStock => 'Stock';

  @override
  String get catalogAdminInitialQuantity => 'Quantité initiale';

  @override
  String get catalogAdminAlertThreshold => 'Seuil d\'alerte';

  @override
  String get catalogAdminPhysicalLocation => 'Emplacement physique';

  @override
  String get catalogAdminLocationHint => 'Ex. Étagère B3, Tiroir 12';

  @override
  String get catalogAdminBranch => 'Agence / Showroom';

  @override
  String get catalogAdminAllBranches => '— Toutes agences —';

  @override
  String get catalogAdminFitments => 'Compatibilités véhicules';

  @override
  String get catalogAdminFitmentsHint =>
      'Déclarez les véhicules compatibles pour permettre la recherche par modèle — même sans numéro OEM.';

  @override
  String get catalogAdminNone => '— Aucun —';

  @override
  String catalogAdminModelsLoadError(String error) {
    return 'Impossible de charger les modèles : $error';
  }

  @override
  String get mediaDeletePhotoTitle => 'Supprimer cette photo ?';

  @override
  String get mediaDeletePhotoBody => 'Cette action est irréversible.';

  @override
  String get mediaFinish => 'Terminer';

  @override
  String get mediaUploading => 'Envoi…';

  @override
  String get mediaGallery => 'Galerie';

  @override
  String get mediaCamera => 'Caméra';

  @override
  String get mediaCover => 'Cover';

  @override
  String get mediaLoadFailed => 'Photos non chargées';

  @override
  String get mediaEmpty => 'Aucune photo';

  @override
  String get mediaEmptyHint =>
      'Appuyez sur \"Galerie\" pour ajouter des photos.';

  @override
  String get mediaAddPhotos => 'Ajouter des photos';

  @override
  String mediaPhotosAdded(int count) {
    return '$count photo(s) ajoutée(s).';
  }

  @override
  String get catalogAdminAccessoryFitmentsHint =>
      'Optionnel — déclarez les véhicules compatibles pour faciliter la recherche.';

  @override
  String get needsTypeSparePart => 'Pièce détachée';

  @override
  String get garageRefillMissing => 'Un passage a probablement été oublié';

  @override
  String get garageRefillImplausible =>
      'Chiffre invraisemblable, un passage manque';

  @override
  String get garageRefillTooLow =>
      'Chiffre trop bas pour être vrai : un passage d\'avant n\'a pas été enregistré';

  @override
  String garageDeadlineOverdue(int days) {
    return 'Dépassée de $days j';
  }

  @override
  String get garageDeadlineToday => 'Expire aujourd\'hui';

  @override
  String garageDeadlineInDays(int days) {
    return 'Dans $days j';
  }

  @override
  String garageRefillDistanceSuffix(String value0) {
    return ' sur $value0 km';
  }

  @override
  String get garageRefillExcludedSuffix => ' — écarté';

  @override
  String get needsYearToLabel => 'À';

  @override
  String get garageGenericVehicle => 'véhicule';

  @override
  String get garageCurrencyUnit => 'FCFA';

  @override
  String get garageCurrencyPerLitre => 'FCFA/l';

  @override
  String garageRefillAmountSuffix(String value0) {
    return ' · $value0 FCFA';
  }

  @override
  String garageModelSinceYear(String value0) {
    return 'depuis $value0';
  }

  @override
  String catalogFitmentModelNumber(String value) {
    return 'Modèle n° $value';
  }

  @override
  String get notificationsChannelDescription =>
      'Notifications importantes AutoParc';

  @override
  String get updateUnsupportedMessage =>
      'Cette version de l\'application n\'est plus prise en charge. Installez la dernière version pour continuer.';

  @override
  String get authErrorTokenMissing => 'Token manquant dans la réponse.';

  @override
  String get authErrorGoogleTokenMissing =>
      'Google n\'a pas fourni de jeton d\'identité.';

  @override
  String get authErrorGoogleInterrupted =>
      'Connexion Google interrompue. Si vous n\'avez pas fermé la fenêtre, vérifiez votre connexion internet puis réessayez.';

  @override
  String get authErrorGoogleInterruptedNetwork =>
      'Connexion Google interrompue. Vérifiez votre connexion internet puis réessayez.';

  @override
  String get authErrorGoogleConfiguration =>
      'La connexion Google n\'est pas correctement configurée pour cette version de l\'application.';

  @override
  String get authErrorGoogleUnavailable =>
      'La connexion Google n\'est pas disponible sur cet appareil.';

  @override
  String get authErrorGoogleWindow =>
      'Impossible d\'afficher la fenêtre de connexion Google.';

  @override
  String authErrorGoogleCode(String value0) {
    return 'Connexion Google impossible ($value0).';
  }

  @override
  String get authErrorAccountMissing => 'Aucun compte trouvé pour cet email.';

  @override
  String get authErrorWrongPassword => 'Mot de passe incorrect.';

  @override
  String get authErrorCredentials => 'Email ou mot de passe incorrect.';

  @override
  String get authErrorPartnerAccount =>
      'Ce compte est un compte partenaire. Connectez-vous à l’espace partenaire.';

  @override
  String get authErrorStaffAccount =>
      'Ce compte appartient au personnel. Utilisez la connexion du personnel.';

  @override
  String get authOpenPartnerSpace => 'Ouvrir l’espace partenaire';

  @override
  String get authErrorEmailInUse => 'Un compte existe déjà avec cet email.';

  @override
  String get authErrorWeakPassword =>
      'Mot de passe trop faible (6 caractères minimum).';

  @override
  String get authErrorEmailInvalid => 'Adresse email invalide.';

  @override
  String get authErrorNetwork =>
      'Erreur réseau. Vérifiez votre connexion internet.';

  @override
  String get authErrorMethodDisabled =>
      'Cette méthode de connexion n\'est pas activée.';

  @override
  String get authErrorOtherMethod =>
      'Ce compte existe déjà avec un autre mode de connexion.';

  @override
  String authErrorCode(String value0) {
    return 'Erreur de connexion ($value0).';
  }

  @override
  String get authErrorUnavailable =>
      'Connexion impossible pour le moment. Réessayez.';

  @override
  String get authErrorDeleteClientOnly =>
      'Seuls les comptes clients se suppriment ici.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Tout lire';

  @override
  String get notificationsBroadcastTooltip => 'Envoyer un conseil';

  @override
  String notificationsMinutesAgo(String value0) {
    return 'Il y a $value0 min';
  }

  @override
  String notificationsHoursAgo(String value0) {
    return 'Il y a $value0 h';
  }

  @override
  String get notificationsYesterday => 'Hier';

  @override
  String notificationsDaysAgo(String value0) {
    return 'Il y a $value0 jours';
  }

  @override
  String get notificationsEmptyTitle => 'Aucune notification';

  @override
  String get notificationsEmptyBody =>
      'Vous serez notifié ici des activités importantes.';

  @override
  String get notificationsTitleBodyRequired =>
      'Titre et message sont obligatoires.';

  @override
  String get notificationsBroadcastSent =>
      'Conseil envoyé à tous les clients ✓';

  @override
  String get notificationsBroadcastTitle => 'Conseil aux propriétaires';

  @override
  String get notificationsBroadcastBody =>
      'Ce message sera envoyé par notification push à tous les clients de l\'app.';

  @override
  String get notificationsTitleField => 'Titre *';

  @override
  String get notificationsTitleHint =>
      'Ex. : Vérifiez votre pression des pneus';

  @override
  String get notificationsBodyField => 'Message *';

  @override
  String get notificationsBodyHint =>
      'Ex. : Une bonne pression de gonflage améliore la durée de vie des pneus de 20 %…';

  @override
  String get notificationsBroadcastAction => 'Envoyer à tous les clients';

  @override
  String get catalogFitmentEmptyTitle => 'Aucune compatibilité déclarée';

  @override
  String get catalogFitmentEmptyBody =>
      'La pièce sera trouvable uniquement par SKU.';

  @override
  String get catalogFitmentUnverified =>
      'Proposée automatiquement, non vérifiée';

  @override
  String get catalogFitmentConfirmationHint =>
      'En enregistrant, les lignes proposées que vous laissez ici deviennent des compatibilités déclarées : elles ne seront plus recalculées, et vous en répondez. Retirez celles que vous ne pouvez pas confirmer.';

  @override
  String get catalogFitmentAdd => 'Ajouter une compatibilité';

  @override
  String get catalogFitmentModelRequired => 'Veuillez sélectionner un modèle.';

  @override
  String get catalogFitmentDialogTitle => 'Compatibilité véhicule';

  @override
  String get catalogFitmentBrandRequired => 'Marque *';

  @override
  String get catalogFitmentSelect => 'Sélectionner…';

  @override
  String get catalogFitmentModelField => 'Modèle *';

  @override
  String get catalogFitmentChooseBrand => 'Choisir d\'abord une marque';

  @override
  String get catalogFitmentTrimOptional => 'Finition (optionnel)';

  @override
  String get catalogFitmentAllTrims => 'Toutes finitions';

  @override
  String get catalogFitmentAllTrimsOption => '— Toutes finitions —';

  @override
  String get catalogFitmentYearFromField => 'Année de';

  @override
  String get catalogFitmentYearToField => 'Année à';

  @override
  String get catalogFitmentPositionField => 'Position (optionnel)';

  @override
  String get catalogFitmentPositionHint => 'Ex. Avant gauche, Côté moteur…';

  @override
  String get catalogFitmentConfirmAction => 'Ajouter cette compatibilité';

  @override
  String get catalogFitmentUnavailableTitle => 'Compatibilités non relues';

  @override
  String get catalogFitmentUnavailableBody =>
      'Elles n\'ont pas pu être chargées et ne sont donc pas modifiables pour l\'instant. Elles seront conservées telles quelles : enregistrer les autres champs ne leur fera rien. Rouvrez cet écran une fois la connexion revenue pour y toucher.';

  @override
  String get vehiclesReferenceFuelPetrol => 'Essence';

  @override
  String get vehiclesReferenceFuelDiesel => 'Diesel';

  @override
  String get vehiclesReferenceFuelElectric => 'Électrique';

  @override
  String get vehiclesReferenceFuelHybrid => 'Hybride';

  @override
  String get vehiclesReferenceDriveFrontWheel => 'Traction avant';

  @override
  String get vehiclesReferenceDriveRearWheel => 'Propulsion arrière';

  @override
  String get vehiclesReferenceDriveAllWheel => 'Intégrale (AWD)';

  @override
  String get vehiclesReferenceDriveFourWheel => '4×4 (4WD)';

  @override
  String get vehiclesReferenceColourWhite => 'Blanc';

  @override
  String get vehiclesReferenceColourPearlWhite => 'Blanc nacré';

  @override
  String get vehiclesReferenceColourLightGrey => 'Gris clair';

  @override
  String get vehiclesReferenceColourAnthraciteGrey => 'Gris anthracite';

  @override
  String get vehiclesReferenceColourTitaniumGrey => 'Gris titanium';

  @override
  String get vehiclesReferenceColourSilver => 'Argent';

  @override
  String get vehiclesReferenceColourBlack => 'Noir';

  @override
  String get vehiclesReferenceColourMetallicBlack => 'Noir métallisé';

  @override
  String get vehiclesReferenceColourRed => 'Rouge';

  @override
  String get vehiclesReferenceColourMetallicRed => 'Rouge métallisé';

  @override
  String get vehiclesReferenceColourBurgundy => 'Bordeaux';

  @override
  String get vehiclesReferenceColourNavyBlue => 'Bleu marine';

  @override
  String get vehiclesReferenceColourMetallicBlue => 'Bleu métallisé';

  @override
  String get vehiclesReferenceColourSkyBlue => 'Bleu ciel';

  @override
  String get vehiclesReferenceColourDarkGreen => 'Vert foncé';

  @override
  String get vehiclesReferenceColourOliveGreen => 'Vert olive';

  @override
  String get vehiclesReferenceColourBeige => 'Beige';

  @override
  String get vehiclesReferenceColourBrown => 'Marron';

  @override
  String get vehiclesReferenceColourGoldChampagne => 'Or / Champagne';

  @override
  String get vehiclesReferenceColourOrange => 'Orange';

  @override
  String get vehiclesReferenceColourYellow => 'Jaune';

  @override
  String get vehiclesReferenceColourPurple => 'Violet';

  @override
  String get vehiclesReferenceCountryBf => 'Burkina Faso';

  @override
  String get vehiclesReferenceCountryCi => 'Côte d\'Ivoire';

  @override
  String get vehiclesReferenceCountrySn => 'Sénégal';

  @override
  String get vehiclesReferenceCountryMl => 'Mali';

  @override
  String get vehiclesReferenceCountryNe => 'Niger';

  @override
  String get vehiclesReferenceCountryTg => 'Togo';

  @override
  String get vehiclesReferenceCountryBj => 'Bénin';

  @override
  String get vehiclesReferenceCountryGw => 'Guinée-Bissau';

  @override
  String get vehiclesReferenceCountryGn => 'Guinée';

  @override
  String get vehiclesReferenceCountryGh => 'Ghana';

  @override
  String get vehiclesReferenceCountryNg => 'Nigéria';

  @override
  String get vehiclesReferenceCountryLr => 'Libéria';

  @override
  String get vehiclesReferenceCountrySl => 'Sierra Leone';

  @override
  String get vehiclesReferenceCountryGm => 'Gambie';

  @override
  String get vehiclesReferenceCountryCv => 'Cap-Vert';

  @override
  String get vehiclesReferenceCountryMr => 'Mauritanie';

  @override
  String get vehiclesReferenceCountryCm => 'Cameroun';

  @override
  String get vehiclesReferenceCountryCf => 'République centrafricaine';

  @override
  String get vehiclesReferenceCountryTd => 'Tchad';

  @override
  String get vehiclesReferenceCountryCg => 'République du Congo';

  @override
  String get vehiclesReferenceCountryGa => 'Gabon';

  @override
  String get vehiclesReferenceCountryGq => 'Guinée équatoriale';

  @override
  String get vehiclesReferenceCountryCd => 'République démocratique du Congo';

  @override
  String get vehiclesReferenceCountryEt => 'Éthiopie';

  @override
  String get vehiclesReferenceCountryKe => 'Kenya';

  @override
  String get vehiclesReferenceCountryTz => 'Tanzanie';

  @override
  String get vehiclesReferenceCountryUg => 'Ouganda';

  @override
  String get vehiclesReferenceCountryRw => 'Rwanda';

  @override
  String get vehiclesReferenceCountryZa => 'Afrique du Sud';

  @override
  String get vehiclesReferenceCountryAo => 'Angola';

  @override
  String get vehiclesReferenceCountryMz => 'Mozambique';

  @override
  String get vehiclesReferenceCountryMa => 'Maroc';

  @override
  String get vehiclesReferenceCountryDz => 'Algérie';

  @override
  String get vehiclesReferenceCountryTn => 'Tunisie';

  @override
  String get vehiclesReferenceCountryEg => 'Égypte';

  @override
  String get vehiclesReferenceCountryLy => 'Libye';

  @override
  String get vehiclesReferenceCountryJp => 'Japon';

  @override
  String get vehiclesReferenceCountryKr => 'Corée du Sud';

  @override
  String get vehiclesReferenceCountryDe => 'Allemagne';

  @override
  String get vehiclesReferenceCountryFr => 'France';

  @override
  String get vehiclesReferenceCountryGb => 'Royaume-Uni';

  @override
  String get vehiclesReferenceCountryNl => 'Pays-Bas';

  @override
  String get vehiclesReferenceCountryBe => 'Belgique';

  @override
  String get vehiclesReferenceCountryIt => 'Italie';

  @override
  String get vehiclesReferenceCountryEs => 'Espagne';

  @override
  String get vehiclesReferenceCountrySe => 'Suède';

  @override
  String get vehiclesReferenceCountryCn => 'Chine';

  @override
  String get vehiclesReferenceCountryIn => 'Inde';

  @override
  String get vehiclesReferenceCountryUs => 'États-Unis';

  @override
  String get vehiclesReferenceCountryCa => 'Canada';

  @override
  String get vehiclesReferenceCountryAu => 'Australie';

  @override
  String get vehiclesReferenceCountryBr => 'Brésil';

  @override
  String get vehiclesReferenceCountryMx => 'Mexique';

  @override
  String get vehiclesReferenceCountryTr => 'Turquie';

  @override
  String get vehiclesReferenceCountryAe => 'Émirats arabes unis';

  @override
  String get vehiclesReferenceCountrySa => 'Arabie saoudite';

  @override
  String get vehiclesReferenceCountryPk => 'Pakistan';

  @override
  String get vehiclesReferenceCountryId => 'Indonésie';

  @override
  String get vehiclesReferenceCountryTh => 'Thaïlande';

  @override
  String get vehiclesReferenceCountryMy => 'Malaisie';

  @override
  String get vehiclesReferenceCountrySg => 'Singapour';

  @override
  String get vehiclesReferenceCountryZw => 'Zimbabwe';

  @override
  String get vehiclesReferenceCountryLb => 'Liban';

  @override
  String get vehiclesReferenceCountryPt => 'Portugal';

  @override
  String get vehiclesReferenceCountryCh => 'Suisse';

  @override
  String get vehiclesReferenceCountryAt => 'Autriche';

  @override
  String get vehiclesReferenceCountryPl => 'Pologne';

  @override
  String get catalogPartCategoryEngine => 'Moteur';

  @override
  String get catalogPartCategoryFilters => 'Filtres';

  @override
  String get catalogPartCategoryOilFilter => 'Filtre à huile';

  @override
  String get catalogPartCategoryAirFilter => 'Filtre à air';

  @override
  String get catalogPartCategoryCabinFilter => 'Filtre habitacle';

  @override
  String get catalogPartCategoryFuelFilter => 'Filtre à carburant';

  @override
  String get catalogPartCategoryTimingSystem => 'Distribution';

  @override
  String get catalogPartCategoryTimingBelt => 'Courroie de distribution';

  @override
  String get catalogPartCategoryTimingBeltKit => 'Kit distribution';

  @override
  String get catalogPartCategoryTimingChain => 'Chaîne de distribution';

  @override
  String get catalogPartCategoryLubrication => 'Lubrification';

  @override
  String get catalogPartCategoryEngineOil => 'Huile moteur';

  @override
  String get catalogPartCategoryCylinderHeadGasket => 'Joint de culasse';

  @override
  String get catalogPartCategoryOilSump => 'Carter d\'huile';

  @override
  String get catalogPartCategoryCooling => 'Refroidissement';

  @override
  String get catalogPartCategoryRadiator => 'Radiateur';

  @override
  String get catalogPartCategoryThermostat => 'Thermostat';

  @override
  String get catalogPartCategoryWaterPump => 'Pompe à eau';

  @override
  String get catalogPartCategoryCoolant => 'Liquide de refroidissement';

  @override
  String get catalogPartCategoryInjectionIgnition => 'Injection & Allumage';

  @override
  String get catalogPartCategorySparkPlugs => 'Bougies d\'allumage';

  @override
  String get catalogPartCategoryInjectors => 'Injecteurs';

  @override
  String get catalogPartCategoryIgnitionCoils => 'Bobines d\'allumage';

  @override
  String get catalogPartCategoryBraking => 'Freinage';

  @override
  String get catalogPartCategoryDiscsPads => 'Disques & Plaquettes';

  @override
  String get catalogPartCategoryFrontBrakeDiscs => 'Disques avant';

  @override
  String get catalogPartCategoryRearBrakeDiscs => 'Disques arrière';

  @override
  String get catalogPartCategoryFrontBrakePads => 'Plaquettes avant';

  @override
  String get catalogPartCategoryRearBrakePads => 'Plaquettes arrière';

  @override
  String get catalogPartCategoryBrakeCalipers => 'Étriers';

  @override
  String get catalogPartCategoryBrakeMasterCylinder => 'Maître-cylindre';

  @override
  String get catalogPartCategoryBrakeHoses => 'Flexibles de frein';

  @override
  String get catalogPartCategoryBrakeFluid => 'Liquide de frein';

  @override
  String get catalogPartCategorySuspensionSteering => 'Suspension & Direction';

  @override
  String get catalogPartCategoryShockAbsorbers => 'Amortisseurs';

  @override
  String get catalogPartCategoryFrontShockAbsorbers => 'Amortisseurs avant';

  @override
  String get catalogPartCategoryRearShockAbsorbers => 'Amortisseurs arrière';

  @override
  String get catalogPartCategorySprings => 'Ressorts';

  @override
  String get catalogPartCategoryBallJointsLinks => 'Rotules & Biellettes';

  @override
  String get catalogPartCategoryTieRodEnd => 'Rotule de direction';

  @override
  String get catalogPartCategoryAntiRollBarLink =>
      'Biellette de barre stabilisatrice';

  @override
  String get catalogPartCategoryWheelBearingsHubs => 'Roulements & Moyeux';

  @override
  String get catalogPartCategoryCVBootsJoints =>
      'Soufflets & Joints homocinétiques';

  @override
  String get catalogPartCategorySteering => 'Direction';

  @override
  String get catalogPartCategorySteeringRack => 'Crémaillère de direction';

  @override
  String get catalogPartCategorySteeringColumn => 'Colonne de direction';

  @override
  String get catalogPartCategoryTransmission => 'Transmission';

  @override
  String get catalogPartCategoryGearbox => 'Boîte de vitesses';

  @override
  String get catalogPartCategoryClutch => 'Embrayage';

  @override
  String get catalogPartCategoryClutchKit => 'Kit embrayage';

  @override
  String get catalogPartCategoryFlywheel => 'Volant moteur';

  @override
  String get catalogPartCategoryDriveShaftsHalfShafts => 'Cardan & Demi-arbre';

  @override
  String get catalogPartCategoryDifferential => 'Différentiel';

  @override
  String get catalogPartCategoryElectricalSystem => 'Électricité';

  @override
  String get catalogPartCategoryBatteryAlternator => 'Batterie & Alternateur';

  @override
  String get catalogPartCategory12VBattery => 'Batterie 12V';

  @override
  String get catalogPartCategoryAlternator => 'Alternateur';

  @override
  String get catalogPartCategoryStarterMotor => 'Démarreur';

  @override
  String get catalogPartCategoryLighting => 'Éclairage';

  @override
  String get catalogPartCategoryHeadlights => 'Phares';

  @override
  String get catalogPartCategoryTailLights => 'Feux arrière';

  @override
  String get catalogPartCategoryBulbs => 'Ampoules';

  @override
  String get catalogPartCategorySensors => 'Capteurs & Sondes';

  @override
  String get catalogPartCategoryOxygenSensor => 'Sonde lambda';

  @override
  String get catalogPartCategoryABSSensor => 'Capteur ABS';

  @override
  String get catalogPartCategoryPressureSensor => 'Capteur de pression';

  @override
  String get catalogPartCategoryBodywork => 'Carrosserie';

  @override
  String get catalogPartCategoryGlass => 'Vitrage';

  @override
  String get catalogPartCategoryWindscreen => 'Pare-brise';

  @override
  String get catalogPartCategorySideWindow => 'Vitre latérale';

  @override
  String get catalogPartCategoryRearWindow => 'Lunette arrière';

  @override
  String get catalogPartCategoryMirrors => 'Rétroviseurs';

  @override
  String get catalogPartCategoryBumpers => 'Pare-chocs';

  @override
  String get catalogPartCategoryBonnetDoors => 'Capot & Portes';

  @override
  String get catalogPartCategorySeals => 'Joints d\'étanchéité';

  @override
  String get catalogPartCategoryAirConditioning => 'Climatisation';

  @override
  String get catalogPartCategoryAirConditioningCompressor =>
      'Compresseur de clim';

  @override
  String get catalogPartCategoryCondenser => 'Condenseur';

  @override
  String get catalogPartCategoryExpansionValve => 'Détendeur';

  @override
  String get catalogPartCategoryRefrigerant => 'Gaz réfrigérant';

  @override
  String get catalogPartCategoryTyresWheels => 'Pneus & Roues';

  @override
  String get catalogPartCategoryTyres => 'Pneus';

  @override
  String get catalogPartCategoryRims => 'Jantes';

  @override
  String get catalogPartCategoryValvesAccessories => 'Valves & Accessoires';

  @override
  String get catalogPartCategoryExhaust => 'Échappement';

  @override
  String get catalogPartCategorySilencer => 'Silencieux';

  @override
  String get catalogPartCategoryExhaustManifold => 'Collecteur';

  @override
  String get catalogPartCategoryCatalyticConverter => 'Catalyseur';

  @override
  String get catalogPartCategoryDPF => 'FAP / DPF';

  @override
  String get catalogEquipmentManualAirConditioning => 'Climatisation manuelle';

  @override
  String get catalogEquipmentAutomaticAirConditioning =>
      'Climatisation automatique';

  @override
  String get catalogEquipmentVentilatedSeats => 'Sièges ventilés';

  @override
  String get catalogEquipmentSunroof => 'Toit ouvrant';

  @override
  String get catalogEquipmentPanoramicRoof => 'Toit panoramique';

  @override
  String get catalogEquipmentFrontElectricWindows => 'Vitres électriques avant';

  @override
  String get catalogEquipmentRearElectricWindows =>
      'Vitres électriques arrière';

  @override
  String get catalogEquipmentElectricMirrors => 'Rétroviseurs électriques';

  @override
  String get catalogEquipmentPowerFoldingMirrors =>
      'Rétroviseurs rabattables électr.';

  @override
  String get catalogEquipmentHeightAdjustableSteeringWheel =>
      'Volant réglable en hauteur';

  @override
  String get catalogEquipmentElectricDriverSSeat =>
      'Siège conducteur électrique';

  @override
  String get catalogEquipmentKeylessEntryAndStart =>
      'Accès et démarrage sans clé';

  @override
  String get catalogEquipmentElectricPowerSteering =>
      'Direction assistée électrique';

  @override
  String get catalogEquipmentABS => 'ABS';

  @override
  String get catalogEquipmentESPStabilityControl =>
      'ESP / Contrôle de stabilité';

  @override
  String get catalogEquipmentEmergencyBrakeAssistBA =>
      'Aide au freinage d\'urgence (BA)';

  @override
  String get catalogEquipmentFrontAirbags => 'Airbags frontaux';

  @override
  String get catalogEquipmentSideAirbags => 'Airbags latéraux';

  @override
  String get catalogEquipmentCurtainAirbags => 'Airbags rideaux';

  @override
  String get catalogEquipmentTractionControlASR => 'Contrôle de traction (ASR)';

  @override
  String get catalogEquipmentHillStartAssist => 'Aide au démarrage en côte';

  @override
  String get catalogEquipmentFrontDiscBrakes => 'Freins à disques avant';

  @override
  String get catalogEquipmentFourWheelDiscBrakes => 'Freins à disques 4 roues';

  @override
  String get catalogEquipmentChildSeatAnchors => 'Ancrage siège enfant';

  @override
  String get catalogEquipmentCarRadio => 'Autoradio';

  @override
  String get catalogEquipmentTouchscreen => 'Écran tactile';

  @override
  String get catalogEquipmentBluetooth => 'Bluetooth';

  @override
  String get catalogEquipmentAndroidAuto => 'Android Auto';

  @override
  String get catalogEquipmentAppleCarPlay => 'Apple CarPlay';

  @override
  String get catalogEquipmentBuiltInGPS => 'GPS intégré';

  @override
  String get catalogEquipmentUSBPort => 'Prise USB';

  @override
  String get catalogEquipmentPremiumSpeakers => 'Haut-parleurs premium';

  @override
  String get catalogEquipmentWirelessCharger => 'Chargeur à induction';

  @override
  String get catalogEquipmentWarningTriangle => 'Triangle de signalisation';

  @override
  String get catalogEquipmentSpareWheel => 'Roue de secours';

  @override
  String get catalogEquipmentJack => 'Cric';

  @override
  String get catalogEquipmentWheelWrench => 'Clé de roue';

  @override
  String get catalogEquipmentFirstAidKit => 'Boîte à pharmacie';

  @override
  String get catalogEquipmentReflectiveVest => 'Gilet réfléchissant';

  @override
  String get catalogEquipmentJumpLeads => 'Câbles de démarrage';

  @override
  String get catalogEquipmentOwnerSManual => 'Manuel du propriétaire';

  @override
  String get catalogEquipmentServiceBook => 'Carnet d\'entretien';

  @override
  String get catalogEquipmentReversingCamera => 'Caméra de recul';

  @override
  String get catalogEquipment360Camera => 'Caméra 360°';

  @override
  String get catalogEquipmentRearParkingSensors => 'Radar de recul';

  @override
  String get catalogEquipmentFrontParkingSensors => 'Radar avant';

  @override
  String get catalogEquipmentCruiseControl => 'Régulateur de vitesse';

  @override
  String get catalogEquipmentAdaptiveCruiseControlACC =>
      'Régulateur adaptatif (ACC)';

  @override
  String get catalogEquipmentLaneDepartureWarning => 'Alerte sortie de voie';

  @override
  String get catalogEquipmentBlindSpotMonitor => 'Détecteur d\'angle mort';

  @override
  String get catalogEquipmentAutomaticEmergencyBraking =>
      'Freinage automatique d\'urgence';

  @override
  String get catalogEquipmentHeadUpDisplayHUD => 'Affichage tête haute (HUD)';

  @override
  String get catalogEquipmentTrafficSignRecognition =>
      'Reconnaissance des panneaux';

  @override
  String garageConsumptionRange(String min, String max) {
    return '$min à $max l/100 km';
  }

  @override
  String get garageConsumptionSourceCanada => 'Ressources naturelles Canada';

  @override
  String get garageConsumptionSourceEurope =>
      'Agence europeenne pour l\'environnement';

  @override
  String get garageConsumptionCycleCanadianFive =>
      'Protocole canadien équivalent cinq cycles';

  @override
  String get garageConsumptionCycleCanadianTwo => 'essai canadien, deux cycles';

  @override
  String get garageConsumptionCycleWltp => 'norme WLTP';

  @override
  String get garageConsumptionCycleNedc => 'ancienne norme NEDC';

  @override
  String get garageEngineAutomatic => 'boîte auto.';

  @override
  String get garageEngineManual => 'boîte manuelle';

  @override
  String get garageEngineAutomatedManual => 'boîte robotisée';

  @override
  String get garageEngineCvt => 'boîte à variation continue';

  @override
  String garageEngineTransmissionGears(String transmission, int gears) {
    return '$transmission $gears';
  }

  @override
  String get garageConsumptionFuelRegularPetrol => 'Essence ordinaire';

  @override
  String get garageConsumptionFuelPremiumPetrol => 'Essence super';

  @override
  String get garageConsumptionFuelEthanol => 'Ethanol (E85)';

  @override
  String get garageConsumptionFuelNaturalGas => 'Gaz naturel';

  @override
  String get garageConsumptionFuelLpg => 'GPL';

  @override
  String get garageConsumptionFuelPlugInHybrid => 'Hybride rechargeable';

  @override
  String get garageMyVehicle => 'mon véhicule';

  @override
  String get vehiclesReferenceSelect => 'Sélectionner…';

  @override
  String get vehiclesReferenceChoosePrevious =>
      'Choisir d\'abord la valeur précédente';

  @override
  String get catalogEquipmentLeatherSeats => 'Sièges cuir';

  @override
  String get garageConsumptionCorresponding => 'Référence de cette version';

  @override
  String get garageConsumptionApproximate => 'Référence approchante';

  @override
  String get garageConsumptionIncomplete => 'Version à préciser';

  @override
  String get garageConsumptionLegacy => 'Référence héritée à vérifier';

  @override
  String get garageConsumptionWithdrawn => 'Référence retirée';

  @override
  String get garageConsumptionUnavailable =>
      'Consommation de référence indisponible';

  @override
  String get garageConsumptionDetails => 'Détails et source';

  @override
  String get garageConsumptionChoose => 'Préciser la version';

  @override
  String get garageConsumptionChange => 'Changer la référence';

  @override
  String get garageConsumptionSelectionNotice =>
      'Choisir une référence ne constitue pas une vérification documentaire du véhicule.';

  @override
  String get garageConsumptionNotVerified =>
      'Correspondance documentaire non vérifiée';

  @override
  String get garageConsumptionMarketUnknown => 'Marché d’origine inconnu';

  @override
  String get garageConsumptionYearMissing => 'Année de référence inconnue';

  @override
  String get garageConsumptionSourceUnknown => 'Source non renseignée';

  @override
  String get garageConsumptionCycleUnknown => 'Protocole non renseigné';

  @override
  String get garageConsumptionMethodTest => 'Méthode : essai';

  @override
  String get garageConsumptionMethodAdjustment => 'Méthode : ajustement';

  @override
  String get garageConsumptionMethodAggregation =>
      'Méthode : agrégation d’immatriculations';

  @override
  String get garageConsumptionMethodTranscription =>
      'Méthode : transcription documentaire';

  @override
  String get garageConsumptionMethodUnknown => 'Méthode non établie';

  @override
  String get garageConsumptionLimitedSample =>
      'Résultat issu d’un échantillon limité ; il ne décrit pas un exemplaire précis.';

  @override
  String get garageConsumptionMissingDetails =>
      'Les informations absentes restent inconnues. Aucun rapprochement exact n’est déduit du seul modèle.';

  @override
  String get garageConsumptionChooseInstruction =>
      'Comparez l’année, le marché, le moteur et la boîte. Plusieurs références peuvent décrire des variantes ou des protocoles différents.';

  @override
  String get garageConsumptionNoCandidates =>
      'Aucune référence de consommation disponible pour ce modèle.';

  @override
  String get garageConsumptionCandidatesUnavailable =>
      'Liste des références indisponible. Réessayez plus tard.';

  @override
  String get garageConsumptionMissingModel =>
      'Consommation indisponible : le modèle de ce véhicule n’est pas encore au catalogue.';

  @override
  String get garageConsumptionSaved =>
      'Référence sélectionnée. Consultez son niveau de correspondance.';

  @override
  String get garageConsumptionSourceTarget => 'le document source';

  @override
  String get garageConsumptionOpenSource => 'Ouvrir le document source';

  @override
  String get garageConsumptionReasonYear =>
      'Le millésime de la référence diffère de l’année renseignée.';

  @override
  String get garageConsumptionReasonMarket =>
      'Le marché de commercialisation n’est pas confirmé.';

  @override
  String get garageConsumptionReasonAggregation =>
      'Une agrégation ne constitue pas la cote exacte de ce véhicule.';

  @override
  String get garageConsumptionReasonLegacy =>
      'Cette ancienne référence reste à requalifier.';

  @override
  String get garageConsumptionReasonIncomplete =>
      'Des caractéristiques nécessaires au rapprochement restent inconnues.';

  @override
  String get garageConsumptionReasonContradiction =>
      'La référence contredit les caractéristiques renseignées.';

  @override
  String get garageConsumptionReasonUnverified =>
      'La version sélectionnée n’a pas été vérifiée sur un document.';

  @override
  String garageConsumptionSourceValue(String value) {
    return 'Valeur de la source : $value L/100 km';
  }

  @override
  String garageConsumptionVehicleYear(int year) {
    return 'Année renseignée : $year';
  }

  @override
  String garageConsumptionModelYear(int year) {
    return 'Millésime de référence : $year';
  }

  @override
  String garageConsumptionRegistrationYear(int year) {
    return 'Année du registre : $year';
  }

  @override
  String garageConsumptionUnknownYear(int year) {
    return 'Année de référence : $year (type non établi)';
  }

  @override
  String garageConsumptionMarket(String market) {
    return 'Marché de référence : $market';
  }

  @override
  String garageConsumptionSource(String source) {
    return 'Source : $source';
  }

  @override
  String garageConsumptionProtocol(String cycle) {
    return 'Protocole : $cycle';
  }

  @override
  String garageConsumptionVerified(String date) {
    return 'Vérification documentaire : $date';
  }

  @override
  String garageConsumptionImported(String date) {
    return 'Import : $date';
  }

  @override
  String garageConsumptionPublished(String date) {
    return 'Publication : $date';
  }

  @override
  String garageConsumptionRevision(String revision) {
    return 'Révision : $revision';
  }

  @override
  String garageConsumptionResource(String resource) {
    return 'Ressource : $resource';
  }

  @override
  String garageConsumptionHash(String hash) {
    return 'Empreinte SHA-256 : $hash';
  }

  @override
  String garageConsumptionRecords(String count) {
    return 'Effectif : $count';
  }

  @override
  String garageConsumptionVersionTitle(String model) {
    return 'Références pour votre $model';
  }

  @override
  String get garageConsumptionReasonRevision =>
      'Une révision plus récente existe ; ce choix conserve sa référence initiale.';

  @override
  String garageConsumptionSourceRecord(String record) {
    return 'Ligne/enregistrement source : $record';
  }

  @override
  String garageConsumptionOriginalUnit(String unit) {
    return 'Unité d’origine : $unit';
  }

  @override
  String garageConsumptionLicense(String license) {
    return 'Licence indiquée par la ressource : $license';
  }

  @override
  String get catalogDeclaredConsumption =>
      'Consommation déclarée par le vendeur';

  @override
  String get catalogConsumptionReferences =>
      'Comparer les références de consommation';

  @override
  String get catalogConsumptionComparisonNotice =>
      'Ces références décrivent des versions et protocoles distincts. Aucune n’est attribuée à cette annonce.';

  @override
  String garageConsumptionRetrieved(String date) {
    return 'Récupération : $date';
  }

  @override
  String garageConsumptionSourceCity(String value) {
    return 'Valeur ville de la source : $value L/100 km';
  }

  @override
  String garageConsumptionSourceHighway(String value) {
    return 'Valeur route de la source : $value L/100 km';
  }

  @override
  String get garageConsumptionFuelHybridUnspecified =>
      'Hybride (type à préciser)';

  @override
  String garageMeasuredConsumptionValue(String value) {
    return '$value l/100 km';
  }

  @override
  String get privateSalesSubmitPhotosRequired => 'Ajoutez au moins une photo.';

  @override
  String get privateSalesSubmitConsentRequired =>
      'Cochez les deux cases ci-dessus.';

  @override
  String get privateSalesRejectReasonMinimumHint => 'Au moins 5 caractères.';

  @override
  String get privateSalesRejectReasonTooShort =>
      'Au moins 5 caractères : le vendeur doit comprendre quoi corriger.';

  @override
  String get settingsContactTitle => 'Contact AutoParc';

  @override
  String get settingsContactSaved => 'Numéro de contact AutoParc enregistré.';

  @override
  String get settingsContactAccessDenied =>
      'Accès réservé aux administrateurs et responsables.';

  @override
  String get settingsContactPhoneTitle => 'Numéro pour joindre AutoParc';

  @override
  String get settingsContactPhoneDescription =>
      'Ce numéro est utilisé pour les appels et WhatsApp dans l’application.';

  @override
  String get settingsContactPhoneLabel =>
      'Téléphone avec indicatif international';

  @override
  String get settingsContactCountryCodeHelp =>
      'Incluez + et l’indicatif du pays.';

  @override
  String get settingsContactPhoneInvalid =>
      'Saisissez un numéro international valide, par exemple +226 75 57 04 84.';

  @override
  String get settingsContactSave => 'Enregistrer le numéro';

  @override
  String get settingsContactSaving => 'Enregistrement…';

  @override
  String get shellContactSettings => 'Paramètres · Contact AutoParc';

  @override
  String get inspectionBadgeLabel => 'Inspecté par AutoParc';

  @override
  String get inspectionAttentionLabel => 'Points à prévoir';

  @override
  String get inspectionBlockingLabel => 'Défauts bloquants signalés';

  @override
  String get inspectionReportTitle => 'Rapport d’inspection';

  @override
  String get inspectionScopeNote =>
      'Constat à la date et au kilométrage indiqués, limité aux points ci-dessous.';

  @override
  String get inspectionDateLabel => 'Date du contrôle';

  @override
  String get inspectionMileageLabel => 'Kilométrage relevé';

  @override
  String get inspectionValidUntilLabel => 'Valable jusqu’au';

  @override
  String inspectionCheckedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points contrôlés',
      one: '1 point contrôlé',
    );
    return '$_temp0';
  }

  @override
  String get inspectionSummaryLabel => 'Compte rendu';

  @override
  String get inspectionStatusOk => 'Contrôlé : aucun défaut relevé';

  @override
  String get inspectionStatusAttention => 'À prévoir';

  @override
  String get inspectionStatusBlocking => 'Défaut bloquant';

  @override
  String get inspectionStatusNotChecked => 'Non contrôlé';

  @override
  String get inspectionReportUnavailable =>
      'Ce rapport n’est plus disponible. Actualisez la fiche du véhicule.';

  @override
  String get inspectionClose => 'Fermer';

  @override
  String get inspectionAdd => 'Enregistrer une inspection';

  @override
  String get inspectionReplace => 'Enregistrer une nouvelle inspection';

  @override
  String get inspectionWithdraw => 'Retirer l’inspection';

  @override
  String get inspectionHistory => 'Historique des inspections';

  @override
  String get inspectionHistoryActive => 'Inspection en cours';

  @override
  String get inspectionHistoryWithdrawn => 'Retirée';

  @override
  String get inspectionHistorySuperseded => 'Remplacée';

  @override
  String get inspectionHistoryExpired => 'Validité expirée';

  @override
  String get inspectionHistoryInactive => 'Inspection inactive';

  @override
  String get inspectionMore => 'Voir les inspections précédentes';

  @override
  String get inspectionFormTitle => 'Inspection AutoParc';

  @override
  String get inspectionFormIntro =>
      'À remplir après un contrôle physique du véhicule. Sélectionnez uniquement les points réellement contrôlés et consignez les défauts constatés.';

  @override
  String get inspectionDateFuture =>
      'La date du contrôle ne peut pas être dans le futur.';

  @override
  String get inspectionMileageRequired =>
      'Indiquez le kilométrage relevé en kilomètres.';

  @override
  String get inspectionSummaryRequired =>
      'Renseignez le compte rendu du contrôle.';

  @override
  String get inspectionPointLabel => 'Point de contrôle';

  @override
  String get inspectionPointHint => 'Ex. freinage, moteur, carrosserie';

  @override
  String get inspectionPointNote => 'Observation (facultatif)';

  @override
  String get inspectionPointStatus => 'Résultat du contrôle';

  @override
  String get inspectionPointRequired => 'Nommez le point de contrôle.';

  @override
  String get inspectionAddPoint => 'Ajouter un point de contrôle';

  @override
  String get inspectionRemovePoint => 'Supprimer ce point';

  @override
  String get inspectionAtLeastOneChecked =>
      'Contrôlez au moins un point avant d’enregistrer l’inspection.';

  @override
  String get inspectionConfirmation =>
      'Je confirme qu’AutoParc a physiquement contrôlé ce véhicule et que ce rapport décrit les points vérifiés.';

  @override
  String get inspectionConfirmationRequired =>
      'Confirmez le contrôle physique du véhicule.';

  @override
  String get inspectionSave => 'Enregistrer l’inspection';

  @override
  String get inspectionSaved => 'Inspection enregistrée.';

  @override
  String get inspectionValidityOptional =>
      'Préciser une fin de validité (facultatif)';

  @override
  String get inspectionValidityDateError =>
      'Choisissez une fin de validité postérieure au contrôle.';

  @override
  String get inspectionChooseDate => 'Choisir une date';

  @override
  String get inspectionWithdrawTitle => 'Retirer cette inspection ?';

  @override
  String get inspectionWithdrawReason => 'Motif du retrait';

  @override
  String get inspectionWithdrawReasonRequired =>
      'Indiquez le motif du retrait.';

  @override
  String get inspectionWithdrawConfirm => 'Retirer';

  @override
  String get inspectionWithdrawn => 'Inspection retirée.';

  @override
  String get faultDeclarationTitle => 'État déclaré';

  @override
  String get faultDeclarationUnknown => 'Non renseigné';

  @override
  String get faultDeclarationNoneSeller =>
      'Aucun défaut déclaré par le vendeur';

  @override
  String get faultDeclarationHasFaults => 'Des défauts sont déclarés';

  @override
  String get faultDeclarationSellerNote =>
      'Informations déclarées par le vendeur. Elles ne constituent pas un contrôle AutoParc.';

  @override
  String faultDeclarationDate(String date) {
    return 'Déclaration du $date';
  }

  @override
  String faultDeclarationUnresolvedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count défauts non réparés déclarés',
      one: '1 défaut non réparé déclaré',
      zero: 'Aucun défaut non réparé déclaré',
    );
    return '$_temp0';
  }

  @override
  String get faultDeclarationUnrepaired => 'Non réparé';

  @override
  String get faultDeclarationDetailsUnavailable =>
      'Des défauts ont été déclarés. Contactez AutoParc pour consulter les détails.';

  @override
  String get faultDeclarationPrivateSubmitRequired =>
      'Renseignez l’état du véhicule : aucun défaut déclaré ou une liste de défauts.';

  @override
  String get faultDeclarationListRequired =>
      'Ajoutez au moins un défaut ou choisissez explicitement un autre état.';

  @override
  String get faultDeclarationInvalidFault =>
      'Vérifiez les défauts déclarés avant d’enregistrer.';

  @override
  String get faultDeclarationFilterNoUnrepaired =>
      'Sans défaut non réparé déclaré';

  @override
  String get faultDeclarationChoiceHint =>
      'Choisissez explicitement l’état déclaré. Une liste vide ne vaut pas une déclaration d’absence de défaut.';

  @override
  String get faultDeclarationAdd => 'Ajouter un défaut';

  @override
  String get faultDeclarationEdit => 'Modifier le défaut';

  @override
  String get faultDeclarationStatusLabel => 'Statut déclaré';

  @override
  String get faultDeclarationClearTitle => 'Effacer les défauts saisis ?';

  @override
  String get faultDeclarationClearMessage =>
      'Choisir « Aucun défaut déclaré » retirera les défauts saisis de cette déclaration.';

  @override
  String get faultDeclarationClearConfirm => 'Effacer et continuer';

  @override
  String get faultDeclarationReadOnlyNotice =>
      'Ce défaut est géré par AutoParc. Sa modification est réservée au personnel.';

  @override
  String get faultDeclarationReadOnlyBlocksNone =>
      'Des défauts gérés par AutoParc restent présents. Vous ne pouvez pas effacer cette liste.';

  @override
  String get faultDeclarationKeepFaultsBeforeUnknown =>
      'Retirez d’abord les défauts modifiables pour passer à « Non renseigné ». Les défauts gérés par AutoParc restent conservés.';

  @override
  String get faultDeclarationChangedElsewhere =>
      'La déclaration a été actualisée pendant la saisie. Vérifiez son contenu avant de réessayer.';

  @override
  String get faultDeclarationFaultLimit =>
      'La déclaration est limitée à 100 défauts.';

  @override
  String get faultDeclarationTitleTooLong =>
      'L’intitulé ne doit pas dépasser 180 caractères.';

  @override
  String get faultDeclarationDescriptionTooLong =>
      'La description ne doit pas dépasser 5 000 caractères.';

  @override
  String get faultDeclarationApply => 'Appliquer';

  @override
  String vehiclesSavedTransmissionType(String type) {
    return 'Boîte enregistrée : $type';
  }

  @override
  String get catalogTransmissionAutomatedManual => 'Robotisée (AMT)';

  @override
  String get catalogTransmissionECvt => 'Hybride e-CVT';

  @override
  String get catalogValidatedByAutoParc => 'Validés par AutoParc';

  @override
  String get garageEngineDetailsTitle => 'Détails du moteur — facultatif';

  @override
  String get garageEngineDetailsHelp =>
      'Renseignez uniquement ce que vous connaissez. La cylindrée en litres ne donne pas la cylindrée exacte en cm³. Ces détails ne confirment pas à eux seuls la compatibilité des pièces.';

  @override
  String get garageEngineLitres => 'Cylindrée indiquée (L)';

  @override
  String get garageEngineCc => 'Cylindrée exacte (cm³)';

  @override
  String get garageEngineCylinders => 'Nombre de cylindres';

  @override
  String get garageEngineLayout => 'Disposition des cylindres';

  @override
  String get garageEngineInline => 'En ligne';

  @override
  String get garageEngineV => 'En V';

  @override
  String get garageEngineBoxer => 'Boxer';

  @override
  String get garageEngineW => 'En W';

  @override
  String get garageEngineOther => 'Autre';

  @override
  String get garageEngineUnspecified => 'Non renseigné';

  @override
  String get garageEngineCode => 'Code moteur';

  @override
  String get garageEnginePower => 'Puissance (ch)';

  @override
  String get garageEngineNumberInvalid =>
      'Saisissez un nombre positif dans la plage indiquée.';

  @override
  String get garageEngineCodeInvalid => '20 caractères maximum.';

  @override
  String get garageEngineAddDetails => 'Compléter les détails du moteur';

  @override
  String garageEngineCylindersValue(int count) {
    return '$count cylindres';
  }

  @override
  String garageEnginePowerValue(int power) {
    return '$power ch';
  }

  @override
  String get vehiclesModelsBodyFilterActive =>
      'Modèles correspondant à la carrosserie choisie.';

  @override
  String get vehiclesModelsBodyFilterEmpty =>
      'Aucun modèle de cette carrosserie n’est renseigné pour cette marque.';

  @override
  String get vehiclesModelsBodyFilterShowAll => 'Afficher tous les modèles';

  @override
  String get vehiclesModelsBodyFilterRestore => 'Filtrer par carrosserie';

  @override
  String get vehiclesModelsBodyFilterRetained =>
      'Votre modèle actuel est conservé. Sa carrosserie diffère ou n’est pas précisée au catalogue.';

  @override
  String get garageConsumptionRecommendationClosest =>
      'Référence la plus proche';

  @override
  String get garageConsumptionRecommendationTied => 'Références à départager';

  @override
  String get garageConsumptionRecommendationNeedsDetails =>
      'Précisez la version du moteur';

  @override
  String get garageConsumptionRecommendationProvisional =>
      'Les informations connues ne permettent pas de recommander une référence unique. Ces valeurs restent des points de comparaison.';

  @override
  String get garageConsumptionRecommendationNotice =>
      'La sélection ne confirme pas à elle seule que cette référence correspond au véhicule.';

  @override
  String get garageConsumptionRecommendationNoEligible =>
      'Aucune des références proposées ne correspond aux caractéristiques connues.';

  @override
  String garageConsumptionRecommendationTieCount(int count) {
    return '$count références sont aussi proches. Les trois premières sont affichées.';
  }

  @override
  String get garageConsumptionRecommendationCurrent =>
      'Référence actuellement sélectionnée';

  @override
  String get garageConsumptionRecommendationShowAll =>
      'Voir toutes les références';

  @override
  String get garageConsumptionRecommendationShowLess =>
      'Revenir aux références ciblées';

  @override
  String get garageConsumptionRecommendationOther => 'Autres références';

  @override
  String garageConsumptionRecommendationConflict(String details) {
    return 'Écart avec les caractéristiques connues : $details.';
  }

  @override
  String get garageConsumptionRecommendationConflictGeneric =>
      'Écart avec les caractéristiques connues. Consultez les détails avant de modifier le véhicule.';

  @override
  String garageConsumptionRecommendationBasedOn(String details) {
    return 'Rapprochée grâce à : $details.';
  }

  @override
  String garageConsumptionRecommendationMissing(String details) {
    return 'À préciser : $details.';
  }

  @override
  String get garageConsumptionRecommendationRefine =>
      'Préciser les détails du moteur';

  @override
  String get garageConsumptionRecommendationEngineCode => 'code moteur';

  @override
  String get garageConsumptionRecommendationDisplacement => 'cylindrée';

  @override
  String get garageConsumptionRecommendationCylinders => 'cylindres';

  @override
  String get garageConsumptionRecommendationPower => 'puissance';

  @override
  String get garageConsumptionRecommendationFuel => 'carburant';

  @override
  String get garageConsumptionRecommendationDrive => 'roues motrices';

  @override
  String get garageConsumptionRecommendationTrim => 'finition';

  @override
  String get garageConsumptionRecommendationModelYear => 'millésime';

  @override
  String get garageConsumptionRecommendationMarket => 'marché d’origine';

  @override
  String get garageConsumptionRecommendationTransmission => 'boîte de vitesses';

  @override
  String get garageConsumptionRecommendationVersion => 'version';

  @override
  String get heavyConfigurationTitle =>
      'Configuration poids lourd — facultatif';

  @override
  String get heavyConfigurationDetailsTitle => 'Configuration poids lourd';

  @override
  String get heavyConfigurationHelp =>
      'Renseignez uniquement les informations connues, à partir des documents du véhicule. Ces données sont déclarées.';

  @override
  String get heavyConfigurationDeclared => 'Données déclarées';

  @override
  String get heavyConfigurationVersion => 'Version commerciale';

  @override
  String get heavyConfigurationCab => 'Cabine';

  @override
  String get heavyConfigurationAxles => 'Configuration des essieux';

  @override
  String get heavyConfigurationAxlesHelp =>
      'Recopiez la notation exacte (ex. 6x2/4 ou 6x2*4).';

  @override
  String get heavyConfigurationChassis => 'Type de châssis';

  @override
  String get heavyConfigurationUnspecified => 'Non renseigné';

  @override
  String get heavyConfigurationTractor => 'Tracteur routier';

  @override
  String get heavyConfigurationRigid => 'Porteur';

  @override
  String get heavyConfigurationOther => 'Autre';

  @override
  String get heavyConfigurationBodyUse => 'Carrosserie / usage';

  @override
  String get heavyConfigurationEmission => 'Norme antipollution';

  @override
  String get heavyConfigurationPtac => 'PTAC (kg)';

  @override
  String get heavyConfigurationPtacHelp =>
      'Poids total autorisé en charge, indiqué sur les documents du véhicule.';

  @override
  String get heavyConfigurationPtra => 'PTRA (kg)';

  @override
  String get heavyConfigurationPtraHelp =>
      'Poids total roulant autorisé, indiqué sur les documents du véhicule.';

  @override
  String get heavyConfigurationMassInvalid =>
      'Saisissez un entier entre 1 et 1 000 000 kg.';

  @override
  String get heavyConfigurationTrainMassTooSmall =>
      'Le PTRA doit être supérieur ou égal au PTAC.';

  @override
  String heavyConfigurationTextTooLong(int max) {
    return 'Saisissez au maximum $max caractères.';
  }

  @override
  String get vehicleRegistrationEntryTitle => 'Ajouter un véhicule';

  @override
  String get vehicleRegistrationChoosePurpose =>
      'Que souhaitez-vous proposer ?';

  @override
  String get vehicleRegistrationSaleTitle => 'Mettre un véhicule en vente';

  @override
  String get vehicleRegistrationSaleHelp =>
      'Renseignez le véhicule et les informations utiles à sa vente.';

  @override
  String get vehicleRegistrationRentalTitle => 'Mettre un véhicule en location';

  @override
  String get vehicleRegistrationRentalHelp =>
      'Un formulaire court pour le véhicule et ses tarifs de location.';

  @override
  String get rentalVehicleCreateTitle => 'Mettre en location';

  @override
  String get rentalVehicleEditTitle => 'Modifier la location';

  @override
  String get rentalVehicleIntro =>
      'Renseignez le véhicule et au moins un tarif. Vous pourrez ajouter les photos après l’enregistrement.';

  @override
  String get rentalVehicleIdentityTitle => 'Le véhicule';

  @override
  String get rentalVehicleRatesTitle => 'Tarifs de location';

  @override
  String get rentalVehicleOptionalTitle =>
      'Informations complémentaires — facultatif';

  @override
  String get rentalVehiclePickupPlace => 'Lieu de retrait';

  @override
  String get rentalVehiclePickupPlaceHelp =>
      'Ville, quartier ou adresse où récupérer le véhicule.';

  @override
  String get rentalVehicleRateRequired =>
      'Renseignez un tarif journalier, hebdomadaire ou mensuel.';

  @override
  String get rentalVehicleSave => 'Enregistrer la location';

  @override
  String get rentalVehicleOptionalHint =>
      'La boîte, les places et les informations complémentaires sont facultatives.';

  @override
  String get rentalVehicleSeatsInvalid =>
      'Saisissez un nombre de places entre 1 et 70.';

  @override
  String get commonPerWeekSuffix => '/semaine';

  @override
  String get vehiclesWeeklyRateLabel => 'Tarif hebdomadaire';

  @override
  String get rentalVehicleEquipmentTitle =>
      'Équipements et accessoires — facultatif';

  @override
  String get rentalVehicleEquipmentHelp =>
      'Cochez uniquement les équipements et accessoires inclus. Cette section peut rester vide.';

  @override
  String get rentalVehicleOtherEquipmentHelp =>
      'Précisez ici les accessoires, services ou autres informations non proposés dans la liste.';

  @override
  String partnerAccountsRentalWeekly(String amount) {
    return 'Location : $amount / semaine';
  }

  @override
  String get equipmentDetailsTitle => 'Engin et matériel';

  @override
  String get equipmentDeclared => 'Données déclarées';

  @override
  String get equipmentTypeLabel => 'Type d’engin';

  @override
  String get equipmentTypeRequired => 'Choisissez un type d’engin.';

  @override
  String get equipmentTypeAgriculturalTractor => 'Tracteur agricole';

  @override
  String get equipmentTypeAerialPlatform => 'Nacelle / plateforme élévatrice';

  @override
  String get equipmentTypeExcavator => 'Pelle / mini-pelle';

  @override
  String get equipmentTypeBackhoeLoader => 'Tractopelle';

  @override
  String get equipmentTypeLoader => 'Chargeuse';

  @override
  String get equipmentTypeTelehandler => 'Chariot télescopique';

  @override
  String get equipmentTypeForklift => 'Chariot élévateur';

  @override
  String get equipmentTypeGenerator => 'Groupe électrogène';

  @override
  String get equipmentTypeOther => 'Autre matériel';

  @override
  String get equipmentBrand => 'Marque';

  @override
  String get equipmentModel => 'Modèle / désignation';

  @override
  String get equipmentBrandLabel => 'Marque *';

  @override
  String get equipmentModelLabel => 'Modèle ou désignation *';

  @override
  String get equipmentBrandNotListed => 'Ma marque n’est pas dans la liste';

  @override
  String get equipmentModelNotListed => 'Mon modèle n’est pas dans la liste';

  @override
  String get equipmentSerialNumber => 'Numéro de série';

  @override
  String get equipmentRegistrationNumber => 'Immatriculation, si applicable';

  @override
  String get equipmentParkNumber => 'Numéro de parc / chantier';

  @override
  String get equipmentOperatingHours => 'Heures de fonctionnement (h)';

  @override
  String get equipmentHourReadingDate => 'Date du relevé (AAAA-MM-JJ)';

  @override
  String get equipmentOdometerKm => 'Compteur kilométrique (km)';

  @override
  String get equipmentPowerKw => 'Puissance (kW)';

  @override
  String get equipmentTransmission => 'Transmission';

  @override
  String get equipmentRatedLoadKg => 'Charge admissible (kg)';

  @override
  String get equipmentWorkingHeightM => 'Hauteur de travail (m)';

  @override
  String get equipmentOutreachM => 'Déport / portée (m)';

  @override
  String get equipmentLiftHeightM => 'Hauteur de levage (m)';

  @override
  String get equipmentOperatingWeightKg => 'Masse en fonctionnement (kg)';

  @override
  String get equipmentBucketCapacityM3 => 'Volume du godet (m³)';

  @override
  String get equipmentPtoRpm => 'Prise de force (tr/min)';

  @override
  String get equipmentCabin => 'Cabine';

  @override
  String get equipmentQuickCoupler => 'Attache rapide';

  @override
  String get equipmentAttachments => 'Équipements, outils et accessoires';

  @override
  String get equipmentEngineSerialNumber => 'Numéro de série du moteur';

  @override
  String get equipmentTransmissionMechanical => 'Mécanique';

  @override
  String get equipmentTransmissionHydrostatic => 'Hydrostatique';

  @override
  String get equipmentTransmissionPowershift => 'Powershift';

  @override
  String get equipmentTransmissionElectric => 'Électrique';

  @override
  String get equipmentTransmissionOther => 'Autre';

  @override
  String get equipmentCabinOpen => 'Ouverte';

  @override
  String get equipmentCabinClosed => 'Fermée';

  @override
  String get equipmentCabinAirConditioned => 'Climatisée';

  @override
  String get equipmentYes => 'Oui';

  @override
  String get equipmentNo => 'Non';

  @override
  String get equipmentCreateSaleTitle => 'Mettre un engin en vente';

  @override
  String get equipmentCreateRentalTitle => 'Mettre un engin en location';

  @override
  String get equipmentEditTitle => 'Modifier l’engin';

  @override
  String get equipmentFormIntro =>
      'Renseignez le type, la marque, le modèle et le tarif. Les autres informations peuvent être complétées plus tard.';

  @override
  String get equipmentYearLabel => 'Année, si connue';

  @override
  String get equipmentFuelLabel => 'Carburant / énergie — facultatif';

  @override
  String get equipmentFuelNone => 'Énergie non renseignée';

  @override
  String get equipmentOptionalIdentity =>
      'Identification complémentaire — facultatif';

  @override
  String get equipmentOptionalTechnical =>
      'Caractéristiques techniques — facultatif';

  @override
  String get equipmentOptionalAttachments =>
      'Équipements et précisions — facultatif';

  @override
  String get equipmentValueInvalid =>
      'Saisissez un nombre positif ou nul dans l’unité indiquée.';

  @override
  String get equipmentDateInvalid =>
      'Saisissez une date valide, sans dépasser aujourd’hui.';

  @override
  String get equipmentSave => 'Enregistrer l’engin';

  @override
  String get equipmentDocuments => 'Documents de l’engin';

  @override
  String get equipmentUnknown => 'Non renseigné';

  @override
  String get equipmentSalePriceRequired => 'Renseignez le prix de vente.';

  @override
  String get equipmentOptionalTextHint =>
      'Renseignez uniquement les informations connues.';

  @override
  String get equipmentIdentityTitle => 'L’engin';

  @override
  String get equipmentPricesTitle => 'Tarifs et disponibilité';

  @override
  String get equipmentDocumentAfterSaveHint =>
      'Les photos et documents peuvent être ajoutés après l’enregistrement.';

  @override
  String get vehicleRegistrationFamilyTitle =>
      'Quel type de bien souhaitez-vous enregistrer ?';

  @override
  String get vehicleRegistrationRoadTitle => 'Véhicule routier';

  @override
  String get vehicleRegistrationRoadHelp =>
      'Voiture, utilitaire ou poids lourd.';

  @override
  String get vehicleRegistrationEquipmentTitle => 'Engins et matériels';

  @override
  String get vehicleRegistrationEquipmentHelp =>
      'Tracteur agricole, nacelle, pelle, chariot ou autre matériel.';

  @override
  String get equipmentDocumentsPrivateHint =>
      'Ces justificatifs sont privés. Ils ne sont pas affichés dans l’annonce publique.';

  @override
  String get equipmentDocumentAdd => 'Ajouter un document';

  @override
  String get equipmentDocumentEmpty =>
      'Aucun document ajouté. Cette étape est facultative.';

  @override
  String get equipmentDocumentType => 'Type de document';

  @override
  String get equipmentDocumentOwnership => 'Titre de propriété';

  @override
  String get equipmentDocumentRegistration => 'Immatriculation';

  @override
  String get equipmentDocumentInspection => 'Contrôle / inspection';

  @override
  String get equipmentDocumentInsurance => 'Assurance';

  @override
  String get equipmentDocumentOther => 'Autre justificatif';

  @override
  String get equipmentDocumentExpiry => 'Expiration — facultatif (AAAA-MM-JJ)';

  @override
  String get equipmentDocumentSelect => 'Choisir le fichier';

  @override
  String get equipmentDocumentFormats =>
      'PDF, JPEG, PNG ou WebP, 8 Mo maximum.';

  @override
  String get equipmentDocumentTooLarge =>
      'Le fichier dépasse la limite de 8 Mo.';

  @override
  String get equipmentDocumentProvided => 'Document fourni — non vérifié';

  @override
  String get equipmentDocumentExport => 'Enregistrer ou partager le document';

  @override
  String get equipmentDocumentDelete => 'Supprimer le document';

  @override
  String get equipmentDocumentDeleteConfirm =>
      'Supprimer ce document de l’engin ?';

  @override
  String get equipmentDocumentExpired => 'Document expiré';

  @override
  String get equipmentDocumentSaved => 'Document ajouté';

  @override
  String get equipmentDocumentDeleted => 'Document supprimé';

  @override
  String get equipmentDocumentDateInvalid =>
      'Saisissez une date valide au format AAAA-MM-JJ.';
}
