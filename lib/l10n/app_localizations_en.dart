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
  String get partageMentionBoutique => 'on AutoParc';

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
  String get commonShareUnavailable =>
      'Cannot open sharing on this device. The message has been copied.';

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
  String get catalogNeedTooltip => 'Submit a request';

  @override
  String get catalogNeedCta => 'Tell us what you are looking for';

  @override
  String get catalogClearFilters => 'Clear all';

  @override
  String get catalogPricesIncludeVat => 'Prices incl. VAT';

  @override
  String catalogResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '$count result',
    );
    return '$_temp0';
  }

  @override
  String catalogResultTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '$count result',
    );
    return '— $_temp0 in total —';
  }

  @override
  String catalogActiveFilters(String terms) {
    return 'Active filters: $terms.';
  }

  @override
  String get catalogFilterListSeparator => ', ';

  @override
  String catalogFilterTermQuery(String query) {
    return '“$query”';
  }

  @override
  String get catalogVehicleAddCta => 'Add';

  @override
  String get catalogVehicleSearchHint => 'Make, model…';

  @override
  String get catalogFilterGroupOffer => 'Offer';

  @override
  String get catalogFilterGroupType => 'Type';

  @override
  String get catalogFilterGroupCity => 'City';

  @override
  String get catalogFilterGroupBodyStyle => 'Body style';

  @override
  String get catalogOfferSale => 'For sale';

  @override
  String get catalogOfferRent => 'For rent';

  @override
  String get catalogOfferBoth => 'Sale & rental';

  @override
  String get catalogOfferNone => 'Unavailable';

  @override
  String get catalogDealFilter => 'Good deal';

  @override
  String catalogDealFilterCount(int count) {
    return 'Good deal ($count)';
  }

  @override
  String get catalogCustomsCleared => 'Customs cleared';

  @override
  String get catalogRegistered => 'Registered';

  @override
  String get catalogNotRegistered => 'Not registered';

  @override
  String get catalogFilterGroupPapers => 'Paperwork';

  @override
  String get catalogVehicleTypeUtility => 'Utility';

  @override
  String get catalogVehicleTypeHeavy => 'Heavy duty';

  @override
  String get catalogBodyStyleSedan => 'Saloon';

  @override
  String get catalogBodyStyleSuv => 'SUV / 4×4';

  @override
  String get catalogBodyStyleHatchback => 'Hatchback';

  @override
  String get catalogBodyStylePickup => 'Pickup';

  @override
  String get catalogBodyStyleMinibus => 'Minibus';

  @override
  String get catalogBodyStyleBus => 'Bus / Coach';

  @override
  String get catalogBodyStyleVan => 'Van';

  @override
  String get catalogBodyStyleEstate => 'Estate';

  @override
  String get catalogBodyStyleTruck => 'Truck';

  @override
  String get catalogBodyStyleConvertible => 'Convertible';

  @override
  String get catalogBodyStyleCoupe => 'Coupé';

  @override
  String catalogPhotoCount(int count) {
    return '$count photos';
  }

  @override
  String get catalogPriceOnRequest => 'Price on request';

  @override
  String get catalogVehicleNoneFound => 'No vehicles found';

  @override
  String get catalogVehicleCatalogEmpty =>
      'The catalogue has no vehicles at the moment.';

  @override
  String get catalogFilterTermSale => 'for sale';

  @override
  String get catalogFilterTermRent => 'for rent';

  @override
  String get catalogFilterTermDeal => 'good deal';

  @override
  String get catalogFilterTermCustoms => 'customs cleared';

  @override
  String get catalogFilterTermVehicleType => 'vehicle type';

  @override
  String get catalogFilterTermBodyStyle => 'body style';

  @override
  String get catalogFilterTermCondition => 'condition';

  @override
  String get catalogFilterTermYear => 'year';

  @override
  String get catalogFilterTermPriceMax => 'maximum price';

  @override
  String get catalogFilterTermOem => 'OEM reference';

  @override
  String get catalogFilterTermCategory => 'a category';

  @override
  String get catalogFilterTermFitment => 'vehicle fitment';

  @override
  String get catalogFilterTermInStock => 'in stock';

  @override
  String get catalogPartAddCta => 'New part';

  @override
  String get catalogPartSearchHint => 'Name, SKU, OEM…';

  @override
  String get catalogPartTypeOem => 'OEM';

  @override
  String get catalogPartTypeOes => 'OES';

  @override
  String get catalogPartTypeAftermarket => 'Aftermarket';

  @override
  String get catalogPartTypeSalvage => 'Used';

  @override
  String get catalogStockIn => 'In stock';

  @override
  String get catalogStockOut => 'Out of stock';

  @override
  String get catalogGarageFitmentTooltip => 'Parts that fit this vehicle';

  @override
  String get catalogGarageFitmentUnknownModel =>
      'Model not in the catalogue: no fitment data';

  @override
  String get catalogGarageFitmentChip => 'Fitting';

  @override
  String get catalogPartNoneFound => 'No parts found';

  @override
  String get catalogPartCatalogEmpty =>
      'The catalogue has no parts at the moment.';

  @override
  String get catalogAccessoryAddCta => 'New accessory';

  @override
  String get catalogAccessorySearchHint => 'Name or SKU…';

  @override
  String get catalogAccessoryCategoryStyling => 'Styling';

  @override
  String get catalogAccessoryCategoryComfort => 'Comfort';

  @override
  String get catalogAccessoryCategorySafety => 'Safety';

  @override
  String get catalogAccessoryCategoryMultimedia => 'Multimedia';

  @override
  String get catalogAccessoryCategoryUtility => 'Utility';

  @override
  String get catalogAccessoryNoneFound => 'No accessories found';

  @override
  String get catalogAccessoryCatalogEmpty =>
      'The catalogue has no accessories at the moment.';

  @override
  String get catalogShareTooltip => 'Share';

  @override
  String get catalogEditTooltip => 'Edit';

  @override
  String get catalogDeleteAction => 'Delete';

  @override
  String get catalogVehicleDeleteTitle => 'Delete this vehicle?';

  @override
  String catalogVehicleDeleteBody(String name) {
    return '“$name” will be permanently deleted.';
  }

  @override
  String get catalogSectionVehicle => 'Vehicle';

  @override
  String get catalogSectionCondition => 'State';

  @override
  String get catalogSectionImport => 'Import';

  @override
  String get catalogSectionLocation => 'Location';

  @override
  String get catalogSectionFeatures => 'Features';

  @override
  String get catalogSectionPartner => 'Source partner';

  @override
  String get catalogFieldBrand => 'Make';

  @override
  String get catalogFieldModel => 'Model';

  @override
  String get catalogFieldYear => 'Year';

  @override
  String get catalogFieldTrim => 'Trim';

  @override
  String get catalogFieldEngine => 'Engine';

  @override
  String get catalogFieldDrivetrain => 'Driven wheels';

  @override
  String get catalogFieldBodyStyle => 'Body style';

  @override
  String get catalogFieldTransmission => 'Gearbox';

  @override
  String get catalogFieldPower => 'Power';

  @override
  String get catalogFieldDisplacement => 'Displacement';

  @override
  String get catalogFieldCylinders => 'Cylinders';

  @override
  String get catalogFieldTorque => 'Torque';

  @override
  String get catalogFieldGears => 'Gears';

  @override
  String get catalogFieldSeats => 'Seats';

  @override
  String get catalogFieldDoors => 'Doors';

  @override
  String get catalogFieldEngineCode => 'Engine code';

  @override
  String get catalogFieldConsumption => 'Fuel use';

  @override
  String get catalogFieldReference => 'Reference';

  @override
  String get catalogFieldCondition => 'Condition';

  @override
  String get catalogFieldMileage => 'Mileage';

  @override
  String get catalogFieldFaults => 'Declared faults';

  @override
  String get catalogFieldOrigin => 'Origin';

  @override
  String get catalogFieldPortOfEntry => 'Port of entry';

  @override
  String get catalogFieldHandedness => 'Steering';

  @override
  String get catalogFieldBranch => 'Branch';

  @override
  String get catalogFieldColour => 'Colour';

  @override
  String catalogUnitHp(int value) {
    return '$value hp';
  }

  @override
  String catalogUnitCc(int value) {
    return '$value cc';
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
  String get catalogConditionNew => 'New';

  @override
  String get catalogConditionUsed => 'Used';

  @override
  String get catalogConditionDamaged => 'Damaged';

  @override
  String get catalogCustomsYes => '✓ Yes';

  @override
  String get catalogCustomsPending => '⏳ Pending';

  @override
  String get catalogRightHandDrive => 'Right (RHD)';

  @override
  String catalogColourMetallic(String name) {
    return '$name (metallic)';
  }

  @override
  String catalogColourPearl(String name) {
    return '$name (pearl)';
  }

  @override
  String get catalogFeatureCategoryStandard => 'Standard equipment';

  @override
  String get catalogFeatureCategoryComfort => 'Comfort';

  @override
  String get catalogFeatureCategorySafety => 'Safety';

  @override
  String get catalogFeatureCategoryMultimedia => 'Multimedia';

  @override
  String get catalogFeatureCategoryDriverAid => 'Driver assistance';

  @override
  String get catalogFeatureCategoryOther => 'Other';

  @override
  String get catalogFeaturesSheetTitle => 'Vehicle features';

  @override
  String get catalogFeaturesSave => 'Save';

  @override
  String get catalogRefsUnavailable =>
      'Reference data is not loaded; please try again.';

  @override
  String get catalogFeaturesUpdated => 'Features updated ✓';

  @override
  String get catalogFullOption => 'Full option';

  @override
  String catalogFullOptionCount(int count) {
    return '· $count features';
  }

  @override
  String get catalogPriceNegotiable => 'Negotiable';

  @override
  String catalogRentalDeposit(String amount) {
    return 'Deposit: $amount';
  }

  @override
  String get catalogCallAction => 'Call';

  @override
  String catalogOfficialConsumption(String range) {
    return 'Official fuel use: $range';
  }

  @override
  String catalogOfficialConsumptionSingle(
    int year,
    String source,
    String cycle,
  ) {
    return '$year model year — $source, $cycle';
  }

  @override
  String catalogOfficialConsumptionRange(
    int count,
    int year,
    String source,
    String cycle,
  ) {
    return 'Depends on the engine ($count known for the $year model year) — $source, $cycle';
  }

  @override
  String get catalogBodyLabelSedan => 'Saloon';

  @override
  String get catalogBodyLabelHatchback => 'Hatchback';

  @override
  String get catalogBodyLabelSuv => 'SUV / 4×4';

  @override
  String get catalogBodyLabelEstate => 'Estate';

  @override
  String get catalogBodyLabelCoupe => 'Coupé';

  @override
  String get catalogBodyLabelConvertible => 'Convertible';

  @override
  String get catalogBodyLabelPickup => 'Pickup';

  @override
  String get catalogBodyLabelVan => 'Van';

  @override
  String get catalogBodyLabelMinibus => 'Minibus';

  @override
  String get catalogBodyLabelBus => 'Bus / Coach';

  @override
  String get catalogBodyLabelTruck => 'Truck';

  @override
  String get catalogBodyLabelOther => 'Other';

  @override
  String get catalogTransmissionManual => 'Manual';

  @override
  String get catalogTransmissionCvt => 'CVT';

  @override
  String get catalogTransmissionAutomatic => 'Automatic';

  @override
  String get catalogPhotosTooltip => 'Photos';

  @override
  String get catalogPartDeleteTitle => 'Delete this part?';

  @override
  String catalogPartDeleteBody(String name) {
    return '“$name” will be permanently deleted.';
  }

  @override
  String get catalogAccessoryDeleteTitle => 'Delete this accessory?';

  @override
  String catalogAccessoryDeleteBody(String name) {
    return '“$name” will be permanently deleted.';
  }

  @override
  String get catalogSectionDescription => 'Description';

  @override
  String get catalogSectionInformation => 'Information';

  @override
  String get catalogSectionPrice => 'Price';

  @override
  String get catalogFieldSalePrice => 'Sale price';

  @override
  String get catalogFieldType => 'Type';

  @override
  String get catalogFieldState => 'Condition';

  @override
  String get catalogFieldCategory => 'Category';

  @override
  String get catalogFieldSku => 'SKU';

  @override
  String get catalogFieldManufacturer => 'Brand';

  @override
  String get catalogPartTypeOemLong => 'OEM — Original manufacturer';

  @override
  String get catalogPartTypeOesLong => 'OES — Approved supplier';

  @override
  String get catalogPartTypeAftermarketLong => 'Aftermarket — Open market';

  @override
  String get catalogPartTypeSalvageLong => 'Salvage / Second-hand';

  @override
  String get catalogPartConditionNew => 'New';

  @override
  String get catalogPartConditionRefurbished => 'Refurbished';

  @override
  String get catalogPartConditionUsed => 'Used';

  @override
  String get catalogAddToCart => 'Add to cart';

  @override
  String get catalogAddToCartAgain => 'Add another';

  @override
  String catalogAddedToCart(String name) {
    return '$name added to cart';
  }

  @override
  String get catalogSeeCart => 'View';

  @override
  String get catalogOutOfStock => 'Out of stock';

  @override
  String catalogStockQuantity(int count) {
    return '$count in stock';
  }

  @override
  String catalogStockQuantityLow(int count) {
    return '$count in stock — running low';
  }

  @override
  String get catalogStockLowChip => 'Low stock';

  @override
  String catalogStockLocation(String location) {
    return 'Location: $location';
  }

  @override
  String get catalogPartNoFitments =>
      'No fitments declared. This part will not show up in a search by vehicle.';

  @override
  String get catalogAccessoryNoFitments =>
      'No fitments declared. This accessory will not show up in a search by vehicle.';

  @override
  String get catalogGarageSectionTitle => 'Your vehicles';

  @override
  String get catalogFitmentYes => 'Fits';

  @override
  String get catalogFitmentUnsure => 'To be confirmed';

  @override
  String get catalogFitmentUnsureDetail =>
      'Fits this model, but your vehicle\'s engine is not recorded. Add it to be sure.';

  @override
  String get catalogFitmentNo => 'Does not fit';

  @override
  String get catalogFitmentUnknown => 'Undetermined';

  @override
  String get catalogFitmentUnknownDetail =>
      'Record your vehicle\'s engine to get an answer.';

  @override
  String catalogVehicleWithYear(String name, int year) {
    return '$name ($year)';
  }

  @override
  String get cartTitle => 'Cart';

  @override
  String cartTitleCount(int count) {
    return 'Cart ($count)';
  }

  @override
  String get cartClear => 'Empty';

  @override
  String get cartClearTitle => 'Empty the cart?';

  @override
  String get cartClearBody => 'Every item will be removed.';

  @override
  String cartLineTotal(String unitPrice, int quantity, String lineTotal) {
    return '$unitPrice × $quantity = $lineTotal';
  }

  @override
  String get cartSubtotalExclTax => 'Subtotal excl. VAT';

  @override
  String get cartVat => 'VAT';

  @override
  String get cartTotalInclTax => 'Total incl. VAT';

  @override
  String get cartOrderViaWhatsApp => 'Order via WhatsApp';

  @override
  String get cartOpening => 'Opening…';

  @override
  String get cartWhatsAppHeader => '*Order request — AutoParc*';

  @override
  String get cartWhatsAppFooter => 'Please confirm availability.';

  @override
  String get cartWhatsAppMissing => 'WhatsApp is not installed on this device.';

  @override
  String get cartInvoice => 'Invoice';

  @override
  String get cartCustomerSection => 'Customer information';

  @override
  String get cartCustomerName => 'Customer name *';

  @override
  String get cartFieldRequired => 'Required field';

  @override
  String get cartCustomerPhone => 'Phone';

  @override
  String get cartPhoneHint => '+226 xx xx xx xx';

  @override
  String cartItemCountSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0 · $total incl. VAT';
  }

  @override
  String get cartConfirmOrder => 'Confirm the order';

  @override
  String get cartSubmitting => 'Sending…';

  @override
  String get cartOrderSaved => 'Order saved ✓';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyBody =>
      'Add accessories or spare parts\nfrom the catalogue.';

  @override
  String get authSignInTab => 'Sign in';

  @override
  String get authRegisterTab => 'Register';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailInvalid => 'Invalid email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordTooShort => 'At least 6 characters';

  @override
  String get authPasswordConfirm => 'Confirm the password';

  @override
  String get authPasswordMismatch => 'The passwords do not match';

  @override
  String get authCreateAccount => 'Create my account';

  @override
  String get authOrSeparator => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authBrowseWithoutAccount =>
      'Browse the catalogue without an account';

  @override
  String authWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get authTagline => 'Sale · Rental · Parts · Accessories';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingCatalogTitle => 'Explore the catalogue';

  @override
  String get onboardingCatalogBody =>
      'Vehicles, parts and accessories in one place.\nFilter by type, body style, city or availability to find exactly what you need.';

  @override
  String get onboardingNeedsTitle => 'Tell us what you need';

  @override
  String get onboardingNeedsBody =>
      'Not finding the right one?\nSet up an alert and get a notification as soon as a vehicle or a part matches your search.';

  @override
  String get onboardingGarageTitle => 'Your own garage';

  @override
  String get onboardingGarageBody =>
      'Add your vehicles to find the spare parts that fit them straight away.\nYour history follows you on every visit.';

  @override
  String get catalogFitmentsTitle => 'Compatible vehicles';

  @override
  String get catalogFitmentsAllProposed =>
      'All auto-suggested: none has been checked.';

  @override
  String catalogFitmentsSomeProposed(int count, int total) {
    return '$count of $total auto-suggested, unchecked.';
  }

  @override
  String get catalogFitmentSeparator => ' · ';

  @override
  String catalogFitmentYearRange(int from, int to) {
    return ' ($from – $to)';
  }

  @override
  String catalogFitmentYearFrom(int year) {
    return ' (from $year)';
  }

  @override
  String catalogFitmentYearTo(int year) {
    return ' (up to $year)';
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
