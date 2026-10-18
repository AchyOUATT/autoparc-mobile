// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonHome => 'Home';

  @override
  String get commonVehicles => 'Vehicles';

  @override
  String get commonAccessories => 'Accessories';

  @override
  String get commonParts => 'Parts';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonMenuTooltip => 'Menu';

  @override
  String get commonPerDaySuffix => '/day';

  @override
  String commonMileageKm(String value) {
    return '$value km';
  }

  @override
  String commonLinkUnavailable(String what, String value) {
    return 'Cannot open $what on this device. $value has been copied.';
  }

  @override
  String get shellExitTitle => 'Quit AutoParc?';

  @override
  String get shellExitBody => 'Do you want to close the app?';

  @override
  String get shellExitConfirm => 'Quit';

  @override
  String get shellAccountGuest => 'Guest';

  @override
  String shellAccountStaff(String role) {
    return 'Staff — $role';
  }

  @override
  String get shellAccountNotSignedIn => 'Not signed in';

  @override
  String get shellClientNeeds => 'Customer requests';

  @override
  String get shellPartners => 'Partners';

  @override
  String get shellNotifications => 'Notifications';

  @override
  String get shellRefreshCatalog => 'Refresh catalogue';

  @override
  String get shellCatalogRefreshed => 'Catalogue updated';

  @override
  String get shellMyGarage => 'My Garage';

  @override
  String get shellMyNeeds => 'My requests';

  @override
  String get shellContact => 'Contact us';

  @override
  String get shellSignIn => 'Sign in';

  @override
  String get shellSignOut => 'Sign out';

  @override
  String get shellSignedOut => 'You are signed out.';

  @override
  String get shellContactPhone => 'Phone';

  @override
  String get shellContactEmail => 'Email';

  @override
  String get shellContactDialerTarget => 'the phone app';

  @override
  String get shellContactMailTarget => 'your mail app';

  @override
  String get shellLanguage => 'Language';

  @override
  String get updateAction => 'Update';

  @override
  String get updateStoreTarget => 'the app listing';

  @override
  String get catalogPartListTitle => 'Spare parts';

  @override
  String get catalogCompatibilitySeparator => ' · ';

  @override
  String catalogCompatibilityMore(int count) {
    return '+$count';
  }

  @override
  String get homeDealsSection => 'Good deals';

  @override
  String get homeSeeAll => 'See all';

  @override
  String homeCompatiblePartsSection(String model) {
    return 'Parts for $model';
  }

  @override
  String get homeCompatiblePartsFallbackModel => 'your vehicle';

  @override
  String get homeUpdateMileage => 'Update mileage';

  @override
  String get homeNoDeadlinePrompt => 'Add your due dates to be warned in time';

  @override
  String get homeGarageUnavailable => 'Your garage could not be loaded';

  @override
  String get homeAddVehicleTitle => 'Register your vehicle';

  @override
  String get homeAddVehicleBody =>
      'Roadworthiness test, insurance, oil change: we warn you before the due date.';

  @override
  String get homeAddVehicleCta => 'Add my car';

  @override
  String get homeNeedPrompt =>
      'Can\'t find it? Tell us what you are looking for';

  @override
  String homeDeadlineDetail(String label, String detail) {
    return '$label — $detail';
  }

  @override
  String homeDeadlineOverdue(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return '$label overdue by $_temp0';
  }

  @override
  String homeDeadlineToday(String label) {
    return '$label expires today';
  }

  @override
  String homeDeadlineTomorrow(String label) {
    return '$label expires tomorrow';
  }

  @override
  String homeDeadlineInDays(String label, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return '$label in $_temp0';
  }
}
