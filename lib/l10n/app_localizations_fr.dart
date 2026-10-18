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
