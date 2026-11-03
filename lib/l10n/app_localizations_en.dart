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
  String get commonPerMonthSuffix => '/month';

  @override
  String commonMileageKm(String value) {
    return '$value km';
  }

  @override
  String get commonMileageNotProvided => 'Mileage not provided';

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
  String get shellSessionToConfirm => 'Checking your session…';

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
  String get catalogTransmissionCvt => 'Continuously variable (CVT)';

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

  @override
  String get privateSalesSellTitle => 'Sell my car';

  @override
  String get privateSalesMineTitle => 'My listings';

  @override
  String get privateSalesBrowseTitle => 'Cars from private sellers';

  @override
  String get privateSalesReviewTitle => 'Review listings';

  @override
  String get privateSalesStatusDraft => 'Draft';

  @override
  String get privateSalesStatusPending => 'Under review';

  @override
  String get privateSalesStatusPublished => 'Published';

  @override
  String get privateSalesStatusRejected => 'Changes needed';

  @override
  String get privateSalesStatusWithdrawn => 'Withdrawn';

  @override
  String get privateSalesStatusSold => 'Sold';

  @override
  String get privateSalesPrivateSeller => 'Private seller';

  @override
  String get privateSalesConfirmRemovalBody =>
      'Buyers will no longer see this listing.';

  @override
  String get privateSalesConfirm => 'Confirm';

  @override
  String get privateSalesRejectReasonTitle => 'Reason to share with the seller';

  @override
  String get privateSalesRejectReasonHint =>
      'Explain what needs to be changed.';

  @override
  String get privateSalesRejectAction => 'Reject / withdraw';

  @override
  String get privateSalesMissingPhonePublication =>
      'This listing has no phone number and cannot be published. Reject it and ask the seller to add one.';

  @override
  String get privateSalesCallSeller => 'Call the seller';

  @override
  String get privateSalesCallCheckInstructions =>
      'Ask whether THEY posted this listing, rather than only checking that the number belongs to them.';

  @override
  String get privateSalesDial => 'Dial';

  @override
  String get privateSalesCallConfirmed =>
      'I called this number and the seller confirmed posting this listing.';

  @override
  String get privateSalesPublish => 'Publish';

  @override
  String get privateSalesReviewAccessDenied =>
      'Only catalogue staff can access this page.';

  @override
  String get privateSalesSignInManage => 'Sign in to manage my listings';

  @override
  String get privateSalesRefresh => 'Refresh';

  @override
  String get privateSalesSearchHint => 'Search for a car or city';

  @override
  String get privateSalesReviewFilterLabel => 'Listing status';

  @override
  String get privateSalesReviewFilterPending => 'Pending';

  @override
  String get privateSalesReviewFilterPublished => 'Published';

  @override
  String get privateSalesOneActiveListingHint =>
      'One active listing is free. Withdraw it or mark it as sold before creating another.';

  @override
  String get privateSalesEmptyMine => 'Create your first listing here.';

  @override
  String get privateSalesEmptyReview => 'No listings to review.';

  @override
  String get privateSalesEmptyBrowse => 'No listings yet.';

  @override
  String get privateSalesPrevious => 'Previous';

  @override
  String get privateSalesNext => 'Next';

  @override
  String get privateSalesEdit => 'Edit / complete';

  @override
  String get privateSalesConfirmSoldTitle => 'Mark this vehicle as sold?';

  @override
  String get privateSalesMarkSold => 'Mark as sold';

  @override
  String get privateSalesConfirmWithdrawTitle => 'Withdraw this listing?';

  @override
  String get privateSalesWithdraw => 'Withdraw';

  @override
  String get privateSalesGarageEmpty =>
      'Your garage is empty. You can enter the vehicle here instead.';

  @override
  String get privateSalesChooseGarageTitle => 'Choose a vehicle from my garage';

  @override
  String get privateSalesPhotosLimit => 'You can add up to 10 photos in total.';

  @override
  String get privateSalesSaveBeforeSubmit =>
      'Save your changes before submitting the listing.';

  @override
  String get privateSalesSubmitted =>
      'Listing submitted. Check My listings for the review decision.';

  @override
  String get privateSalesSignInSell => 'Sign in to sell';

  @override
  String get privateSalesAccountChanged =>
      'The account has changed. Close this form and reopen My listings.';

  @override
  String get privateSalesFormHeading => 'Your car, your listing';

  @override
  String get privateSalesNoPartnerRequired =>
      'One active listing is free. No partner account needed.';

  @override
  String get privateSalesPrefillGarage => 'Fill in from my garage';

  @override
  String get privateSalesGaragePrivacy =>
      'Your garage stays private. Only the vehicle details and photos are published.';

  @override
  String get privateSalesPriceLabel => 'Price in FCFA';

  @override
  String get privateSalesCityLabel => 'City';

  @override
  String get privateSalesDescriptionLabel =>
      'Vehicle condition and useful details';

  @override
  String get privateSalesSellerNameLabel => 'Seller name';

  @override
  String get privateSalesPhoneLabel => 'Phone number with country code';

  @override
  String get privateSalesWhatsappOptIn =>
      'Allow AutoParc to contact me on WhatsApp';

  @override
  String get privateSalesSaveDraft => 'Save draft';

  @override
  String get privateSalesSaveChanges => 'Save changes';

  @override
  String get privateSalesChangesNeedReview =>
      'Editing this listing will return it to draft and require another review.';

  @override
  String get privateSalesPhotosPrivacy =>
      'The first photo will be the cover. Only add photos you intend to make public.';

  @override
  String get privateSalesVehiclePhoto => 'Vehicle photo';

  @override
  String get privateSalesDeletePhoto => 'Delete photo';

  @override
  String get privateSalesAddPhotos => 'Add photos';

  @override
  String get privateSalesBeforePublication => 'Before publication';

  @override
  String get privateSalesPhoneCallNotice =>
      'Someone from AutoParc will call the number provided to confirm you posted this listing. AutoParc keeps your number private.';

  @override
  String get privateSalesOwnerConfirmation =>
      'I own this vehicle or am authorised to sell it.';

  @override
  String get privateSalesContactConsent =>
      'I authorise AutoParc to contact me about this listing. My name and phone number will not be made public.';

  @override
  String get privateSalesSubmit => 'Submit for review';

  @override
  String get privateSalesRequiredField => 'Fill in this field.';

  @override
  String get privateSalesDescriptionTooShort =>
      'Describe the vehicle using at least 20 characters.';

  @override
  String get privateSalesPhoneInvalid =>
      'Include the country code, for example +22670000000.';

  @override
  String get privateSalesIntegerInvalid => 'Enter a valid whole number.';

  @override
  String get privateSalesYearInvalid => 'Check the year.';

  @override
  String get privateSalesDetailTitle => 'Private seller listing';

  @override
  String get privateSalesShare => 'Share listing';

  @override
  String get privateSalesFuel => 'Fuel';

  @override
  String get privateSalesDrivetrain => 'Drivetrain';

  @override
  String get privateSalesPhoneVerified => 'Phone verified';

  @override
  String get privateSalesNotInspected =>
      'This vehicle has not been inspected by AutoParc.';

  @override
  String get privateSalesContactWhatsapp => 'Contact on WhatsApp';

  @override
  String get privateSalesAutoParcContactNotice =>
      'Contact AutoParc about this listing. The seller’s contact details remain private.';

  @override
  String get privateSalesCallAutoParc => 'Call AutoParc';

  @override
  String get privateSalesWhatsappAutoParc => 'WhatsApp AutoParc';

  @override
  String privateSalesAutoParcMessage(String title, String url) {
    return 'Hello AutoParc, I would like information about this listing: $title\n$url';
  }

  @override
  String get privateSalesBrandRequiredLabel => 'Make *';

  @override
  String get privateSalesBrandRequiredError => 'Make is required';

  @override
  String get privateSalesModelRequiredLabel => 'Model *';

  @override
  String get privateSalesModelSelectionError =>
      'Select a model or enter your own.';

  @override
  String get privateSalesFreeModelHint => 'Enter your model name';

  @override
  String get privateSalesFreeModelRequired => 'Enter the model.';

  @override
  String get privateSalesModelListAction => 'Back to the model list';

  @override
  String get privateSalesFreeModelAction => 'My model is not listed';

  @override
  String get privateSalesManufactureYearLabel => 'Year of manufacture *';

  @override
  String get privateSalesManufactureYearInvalid =>
      'Check the year of manufacture.';

  @override
  String get privateSalesMileageInvalid => 'Enter a valid mileage.';

  @override
  String get privateSalesClearTrim => 'Clear trim';

  @override
  String get privateSalesClearFuel => 'Clear fuel';

  @override
  String get privateSalesClearDrivetrain => 'Clear drivetrain';

  @override
  String get privateSalesClearColour => 'Clear colour';

  @override
  String get privateSalesTransmissionOptional => 'Gearbox (optional)';

  @override
  String get privateSalesTransmissionDualClutch => 'Dual-clutch (DCT)';

  @override
  String get privateSalesTransmissionSingleSpeed => 'Single-speed';

  @override
  String get privateSalesClearTransmission => 'Clear transmission';

  @override
  String privateSalesReviewReason(String reason) {
    return 'Changes needed: $reason';
  }

  @override
  String privateSalesPhotosHeading(int count) {
    return 'Photos ($count/10)';
  }

  @override
  String privateSalesVerifiedNumber(String number) {
    return 'Verified number: $number';
  }

  @override
  String privateSalesGenerationWarning(String years) {
    return 'This generation is listed for $years. Check the model and year.';
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
    return '$label: $value';
  }

  @override
  String get partnerAccountsPromotionStartTitle => 'Promotion start';

  @override
  String get partnerAccountsPromotionEndTitle => 'Promotion end';

  @override
  String get partnerAccountsPromotionEnabled => 'Put on promotion';

  @override
  String get partnerAccountsPromotionPriceRequired =>
      'Enter a sale price first.';

  @override
  String get partnerAccountsPromotionDurationHelp => 'For a period you choose.';

  @override
  String get partnerAccountsPromotionPrice => 'Promotional price (FCFA)';

  @override
  String get partnerAccountsPromotionPriceInvalid =>
      'The promotional price must be lower than the regular price.';

  @override
  String get partnerAccountsPromotionDiscountInvalid => 'Discount is too high.';

  @override
  String get partnerAccountsPromotionStart => 'Start';

  @override
  String get partnerAccountsPromotionEnd => 'End';

  @override
  String get partnerAccountsMarginYourPrice => 'Your price';

  @override
  String get partnerAccountsMarginPublicPrice => 'Price shown to the buyer';

  @override
  String get partnerAccountsMarginLockedHelp =>
      'This total is fixed when you save.';

  @override
  String get partnerAccountsSpaceTitle => 'Partner area';

  @override
  String get partnerAccountsCompanyIntro => 'Introduce your business';

  @override
  String get partnerAccountsActivityIntro => 'Grow your business';

  @override
  String get partnerAccountsRegisterIntro =>
      'Once your account is approved, list your vehicles, parts and accessories.';

  @override
  String get partnerAccountsLoginIntro =>
      'Manage your sale and rental listings in your business area.';

  @override
  String get partnerAccountsLoginTab => 'Sign in';

  @override
  String get partnerAccountsRegisterTab => 'Register';

  @override
  String get partnerAccountsCompanyOptional => 'Business name (optional)';

  @override
  String get partnerAccountsCompanyFallbackHelp =>
      'If you have no business, your listings will show your name.';

  @override
  String get partnerAccountsContactName => 'Contact name';

  @override
  String get partnerAccountsBusinessPhone => 'Business phone';

  @override
  String get partnerAccountsWhatsappOptional => 'WhatsApp (optional)';

  @override
  String get partnerAccountsEmailOptional => 'Email address (optional)';

  @override
  String get partnerAccountsPhoneLoginHelp =>
      'You will sign in with your phone number.';

  @override
  String get partnerAccountsInvalidEmail => 'Enter a valid email address.';

  @override
  String get partnerAccountsLoginIdentifier => 'Phone number or email address';

  @override
  String get partnerAccountsIdentifierRequired =>
      'Enter your phone number or email address.';

  @override
  String get partnerAccountsIdentifierInvalid =>
      'Enter a phone number or email address.';

  @override
  String get partnerAccountsPasswordHelp =>
      'At least 12 characters, including letters and numbers.';

  @override
  String get partnerAccountsShowPassword => 'Show password';

  @override
  String get partnerAccountsHidePassword => 'Hide password';

  @override
  String get partnerAccountsPasswordRequired => 'Enter your password.';

  @override
  String get partnerAccountsPasswordInvalid =>
      'Use at least 12 characters, including letters and numbers.';

  @override
  String get partnerAccountsPasswordMismatch => 'Passwords do not match.';

  @override
  String get partnerAccountsRestoreSession => 'Try restoring my session again';

  @override
  String get partnerAccountsRequestAccount => 'Request a partner account';

  @override
  String get partnerAccountsPublishingAfterApproval =>
      'You can publish listings once your business is approved.';

  @override
  String get partnerAccountsRequiredField => 'This field is required.';

  @override
  String get partnerAccountsStatusUnconfirmed => 'Confirming status…';

  @override
  String get partnerAccountsAccountApproved => 'Account approved';

  @override
  String get partnerAccountsCreateListingHelp =>
      'Create a listing, add your photos, then publish it. Your contact details will appear with your listings.';

  @override
  String get partnerAccountsSaleAndRental => 'Sale and rental';

  @override
  String get partnerAccountsInventorySummary =>
      'Prices, availability and stock';

  @override
  String get partnerAccountsCustomerRequests => 'Customer requests';

  @override
  String get partnerAccountsCustomerRequestsSubtitle =>
      'Requests forwarded by the shop';

  @override
  String get partnerAccountsRefreshAccount => 'Refresh my account';

  @override
  String get partnerAccountsRejectedTitle => 'Application rejected';

  @override
  String get partnerAccountsRejectedDescription =>
      'Your application was not approved. See the reason below.';

  @override
  String get partnerAccountsSuspendedTitle => 'Account suspended';

  @override
  String get partnerAccountsSuspendedDescription =>
      'Managing and publishing your listings is suspended.';

  @override
  String get partnerAccountsReceivedTitle => 'Registration received';

  @override
  String get partnerAccountsReceivedDescription =>
      'Your business is awaiting approval. You can manage your listings once it is approved.';

  @override
  String get partnerAccountsRefreshing => 'Refreshing…';

  @override
  String get partnerAccountsCheckStatus => 'Check my status';

  @override
  String get partnerAccountsBackToLogin => 'Back to sign in';

  @override
  String get partnerAccountsPendingStatus => 'Pending';

  @override
  String get partnerAccountsApprovedStatus => 'Approved';

  @override
  String get partnerAccountsRejectedStatus => 'Rejected';

  @override
  String get partnerAccountsSuspendedStatus => 'Suspended';

  @override
  String get partnerAccountsRejectApplication => 'Reject application';

  @override
  String get partnerAccountsSuspendAccount => 'Suspend account';

  @override
  String get partnerAccountsReviewReasonLabel =>
      'Reason shared with the partner';

  @override
  String get partnerAccountsReviewReasonRequired =>
      'Explain the reason for this decision.';

  @override
  String get partnerAccountsConfirm => 'Confirm';

  @override
  String get partnerAccountsApplicationIncomplete =>
      'This application is incomplete. Refresh the list.';

  @override
  String get partnerAccountsDecisionSaved => 'Decision saved.';

  @override
  String get partnerAccountsApplicationsTitle => 'Partner approval';

  @override
  String get partnerAccountsManagerOnly => 'Access is restricted to managers.';

  @override
  String get partnerAccountsApplicationsFilter => 'Applications';

  @override
  String get partnerAccountsNoApplications =>
      'No applications in this category.';

  @override
  String get partnerAccountsPrevious => 'Previous';

  @override
  String get partnerAccountsNext => 'Next';

  @override
  String get partnerAccountsUnnamedCompany => 'Unnamed business';

  @override
  String get partnerAccountsMissingContact => 'Contact not provided';

  @override
  String get partnerAccountsMissingPhone => 'Phone number not provided';

  @override
  String get partnerAccountsReactivate => 'Reactivate';

  @override
  String get partnerAccountsApprove => 'Approve';

  @override
  String get partnerAccountsReject => 'Reject';

  @override
  String get partnerAccountsSuspend => 'Suspend';

  @override
  String get partnerAccountsListingIncomplete =>
      'This listing is incomplete. Refresh the list.';

  @override
  String get partnerAccountsArchiveQuestion => 'Archive this listing?';

  @override
  String get partnerAccountsArchiveDescription =>
      'It will be removed from your inventory and the public catalogue.';

  @override
  String get partnerAccountsArchive => 'Archive';

  @override
  String get partnerAccountsAdjustStock => 'Adjust stock';

  @override
  String get partnerAccountsAvailableQuantity => 'Available quantity';

  @override
  String get partnerAccountsQuantityInvalid => 'Enter a valid quantity.';

  @override
  String get partnerAccountsSave => 'Save';

  @override
  String get partnerAccountsListingFallback => 'Listing';

  @override
  String get partnerAccountsRefresh => 'Refresh';

  @override
  String get partnerAccountsCreateListing => 'Create a listing';

  @override
  String get partnerAccountsSearchListings => 'Search my listings';

  @override
  String get partnerAccountsSearch => 'Search';

  @override
  String get partnerAccountsInventoryEmpty => 'Your inventory starts here';

  @override
  String get partnerAccountsNoMatchingListings => 'No matching listings';

  @override
  String get partnerAccountsInventoryEmptyHelp =>
      'Create a listing, add photos, then choose to publish it.';

  @override
  String get partnerAccountsCreateFirstListing => 'Create my first listing';

  @override
  String get partnerAccountsPreviousPage => 'Previous page';

  @override
  String get partnerAccountsNextPage => 'Next page';

  @override
  String get partnerAccountsManageListing => 'Manage this listing';

  @override
  String get partnerAccountsManagePhotos => 'Manage photos';

  @override
  String get partnerAccountsMakeAvailable => 'Make available';

  @override
  String get partnerAccountsMakeUnavailable => 'Mark unavailable';

  @override
  String get partnerAccountsPublished => 'Published';

  @override
  String get partnerAccountsDraft => 'Draft';

  @override
  String get partnerAccountsWithdraw => 'Withdraw';

  @override
  String get partnerAccountsPublish => 'Publish';

  @override
  String get partnerAccountsRequestFailed =>
      'Unable to complete the request. Check your connection and try again.';

  @override
  String get partnerAccountsPriceRequired => 'Enter a price.';

  @override
  String get partnerAccountsMoneyInvalid => 'Enter an amount of zero or more.';

  @override
  String get partnerAccountsNotProvided => 'Not provided';

  @override
  String get partnerAccountsChoiceRequired => 'Choose a value.';

  @override
  String get partnerAccountsEditListingHelp => 'Update your listing.';

  @override
  String get partnerAccountsNewListingHelp =>
      'Your listing will be saved as a draft. You can then add photos and publish it.';

  @override
  String get partnerAccountsSaving => 'Saving…';

  @override
  String get partnerAccountsSaveChanges => 'Save changes';

  @override
  String get partnerAccountsSaveDraft => 'Save draft';

  @override
  String get partnerAccountsItemName => 'Item name';

  @override
  String get partnerAccountsNameRequired => 'Enter a name.';

  @override
  String get partnerAccountsPartCategory => 'Part category';

  @override
  String get partnerAccountsPartOrigin => 'Part origin';

  @override
  String get partnerAccountsPartOem => 'Original manufacturer (OEM)';

  @override
  String get partnerAccountsPartOes => 'Original equipment supplier (OES)';

  @override
  String get partnerAccountsPartAftermarket => 'Aftermarket';

  @override
  String get partnerAccountsPartSalvage => 'Salvaged part';

  @override
  String get partnerAccountsCondition => 'Condition';

  @override
  String get partnerAccountsConditionNew => 'New';

  @override
  String get partnerAccountsConditionRefurbished => 'Refurbished';

  @override
  String get partnerAccountsConditionUsed => 'Used';

  @override
  String get partnerAccountsDonorRequiredHelp =>
      'A used part must be linked to a donor vehicle in your own inventory.';

  @override
  String get partnerAccountsReloadDonors => 'Reload donor vehicles';

  @override
  String get partnerAccountsDonorsEmpty =>
      'Add the donor vehicle to your vehicle listings first.';

  @override
  String get partnerAccountsDonorVehicle => 'Donor vehicle';

  @override
  String get partnerAccountsManufacturerReferenceOptional =>
      'Manufacturer reference (optional)';

  @override
  String get partnerAccountsAccessoryCategory => 'Accessory category';

  @override
  String get partnerAccountsManufacturerOptional => 'Manufacturer (optional)';

  @override
  String get partnerAccountsSkuOptional =>
      'Internal reference / SKU (optional)';

  @override
  String get partnerAccountsSalePrice => 'Sale price (FCFA)';

  @override
  String get partnerAccountsStockQuantity => 'Stock quantity';

  @override
  String get partnerAccountsStockInvalid =>
      'Enter a whole number of zero or more.';

  @override
  String get partnerAccountsPhotosTitle => 'Listing photos';

  @override
  String get partnerAccountsAddPhotos => 'Add photos';

  @override
  String get partnerAccountsPhotosHelp =>
      'JPEG, PNG or WebP. Choose a cover and arrange your gallery.';

  @override
  String get partnerAccountsPhotosEmpty =>
      'Add the first photos for your listing.';

  @override
  String get partnerAccountsCover => 'Cover';

  @override
  String get partnerAccountsSetCover => 'Set as cover';

  @override
  String get partnerAccountsMoveBefore => 'Move earlier';

  @override
  String get partnerAccountsMoveAfter => 'Move later';

  @override
  String get partnerAccountsDeletePhoto => 'Delete photo';

  @override
  String get partnerAccountsDeletePhotoQuestion => 'Delete this photo?';

  @override
  String get partnerAccountsDelete => 'Delete';

  @override
  String get partnerAccountsPhotoLimit => 'Select up to 10 photos per upload.';

  @override
  String get partnerAccountsMarkAllRead => 'Mark all as read';

  @override
  String get partnerAccountsNoRequests => 'No requests yet.';

  @override
  String get partnersEditTitle => 'Edit partner';

  @override
  String get partnersCreateTitle => 'New partner';

  @override
  String get partnersSave => 'Save';

  @override
  String get partnersCompanySection => 'Business';

  @override
  String get partnersCompanyName => 'Business name *';

  @override
  String get partnersRequiredField => 'Required field';

  @override
  String get partnersContactName => 'Contact name';

  @override
  String get partnersContactsSection => 'Contacts';

  @override
  String get partnersPhone => 'Phone *';

  @override
  String get partnersWhatsappDifferent => 'WhatsApp (if different)';

  @override
  String get partnersEmail => 'Email';

  @override
  String get partnersInvalidEmail => 'Invalid email address';

  @override
  String get partnersNotesSection => 'Notes';

  @override
  String get partnersInternalNotes => 'Internal notes';

  @override
  String get partnersNotesHint => 'Speciality, terms, opening hours…';

  @override
  String get partnersActive => 'Active partner';

  @override
  String get partnersInactiveHelp => 'Inactive partners are hidden from lists';

  @override
  String get partnersSearchHint => 'Name, contact, phone…';

  @override
  String get partnersNoResults => 'No partners found';

  @override
  String get partnersDelete => 'Delete';

  @override
  String get partnersDeleteQuestion => 'Delete this partner?';

  @override
  String get partnersAttach => 'Link';

  @override
  String get partnersNoLinkedPartners => 'No linked partners.';

  @override
  String get partnersAttachTitle => 'Link a partner';

  @override
  String get partnersPartnerRequired => 'Partner *';

  @override
  String get partnersRoleOptional => 'Role (optional)';

  @override
  String get partnersRoleHint => 'supplier, importer…';

  @override
  String get partnersNotesOptional => 'Notes (optional)';

  @override
  String get partnersRemove => 'Remove';

  @override
  String get partnersRemoveQuestion => 'Remove this partner?';

  @override
  String partnerAccountsReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String partnerAccountsApplicationPagination(
    int page,
    int lastPage,
    int total,
  ) {
    return 'Page $page / $lastPage · $total application(s)';
  }

  @override
  String partnerAccountsMarginIncluded(String amount, String rate) {
    return 'including $amount shop margin ($rate%)';
  }

  @override
  String partnerAccountsStockSummary(String quantity) {
    return 'Stock: $quantity';
  }

  @override
  String partnerAccountsRentalDaily(String amount) {
    return 'Rental: $amount / day';
  }

  @override
  String partnerAccountsRentalMonthly(String amount) {
    return 'Rental: $amount / month';
  }

  @override
  String partnerAccountsPromotionMaximum(String maximum) {
    return 'Discount up to $maximum%.';
  }

  @override
  String partnerAccountsPromotionExceeded(String maximum, String discount) {
    return 'The discount cannot exceed $maximum%: this one is $discount%.';
  }

  @override
  String partnerAccountsPromotionPreview(String discount, String price) {
    return 'The buyer will see −$discount%, with $price FCFA crossed out.';
  }

  @override
  String partnerAccountsMarginRate(String rate) {
    return 'Shop margin ($rate%)';
  }

  @override
  String get partnerAccountsMyVehicles => 'My vehicles';

  @override
  String get partnerAccountsMyParts => 'My spare parts';

  @override
  String get partnerAccountsMyAccessories => 'My accessories';

  @override
  String get partnerAccountsAddPart => 'Add a part';

  @override
  String get partnerAccountsEditPart => 'Edit a part';

  @override
  String get partnerAccountsAddAccessory => 'Add an accessory';

  @override
  String get partnerAccountsEditAccessory => 'Edit an accessory';

  @override
  String partnersDeleteDescription(String name) {
    return '$name will be removed from all products.';
  }

  @override
  String partnersRemoveDescription(String name) {
    return 'The link with $name will be removed.';
  }

  @override
  String get partnerAccountsNetworkError =>
      'Unable to connect. Check your network and try again.';

  @override
  String get partnerAccountsSessionResponseInvalid =>
      'The response does not match a partner session.';

  @override
  String get partnerAccountsSessionInvalid =>
      'This partner session is invalid.';

  @override
  String get partnerAccountsSessionCheckFailed =>
      'Unable to verify your session. Try again.';

  @override
  String get partnerAccountsLoginFailed =>
      'Sign-in was unsuccessful. Try again.';

  @override
  String get partnerAccountsRefreshFailed => 'Unable to refresh. Try again.';

  @override
  String get privateSalesHomeTitle => 'Cars from private sellers';

  @override
  String get privateSalesHomeBody =>
      'Sell your car with your regular account. One active listing is free.';

  @override
  String get privateSalesBrowseAction => 'Browse listings';

  @override
  String get privateSalesSellThisVehicle => 'Sell this vehicle';

  @override
  String get shellPartnerApplications => 'Partner applications';

  @override
  String get shellPartnerSpace => 'Partner area';

  @override
  String get commonErrorNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get commonErrorSessionExpired =>
      'Your session has expired. Sign in again.';

  @override
  String get commonErrorNotFound =>
      'Not found. The item may have been deleted.';

  @override
  String get commonErrorUploadTooLarge =>
      'The upload is too large. Remove some photos or reduce their size, then try again.';

  @override
  String get commonErrorServer => 'Server error.';

  @override
  String get commonErrorGeneric => 'Something went wrong. Try again.';

  @override
  String get commonErrorPermission => 'Your role does not allow this action.';

  @override
  String get commonErrorDisabled =>
      'This account has been disabled. Contact support.';

  @override
  String get commonErrorUnavailable =>
      'The service is currently unavailable. Try again later.';

  @override
  String get commonErrorThrottled =>
      'Too many attempts. Try again in a few minutes.';

  @override
  String commonErrorReference(String message, String reference) {
    return '$message (ref. $reference)';
  }

  @override
  String get partnerAccountsRequestsHelp =>
      'Customer requests appear here as soon as the shop forwards them.';

  @override
  String get garageBrandRequiredMessage => 'Please select a make.';

  @override
  String get garageModelRequiredMessage => 'Select a model, or enter your own.';

  @override
  String get garageSignInReminderTitle => 'An account for your reminders';

  @override
  String get garageSignInReminderBody =>
      'Vehicle inspection, insurance, oil changes: these reminders are sent to you, so we need to know who you are.\n\nYour entries are kept.';

  @override
  String get garageSignInLater => 'Later';

  @override
  String get garageSignInAction => 'Sign in';

  @override
  String get garageSignInCancelled =>
      'Sign-in cancelled — your entries are kept.';

  @override
  String get garageAddVehicleTitle => 'Add to my garage';

  @override
  String garageReferencesLoadError(String value0) {
    return 'Could not load reference data: $value0';
  }

  @override
  String get garageIdentitySection => 'Identification';

  @override
  String get garageBrandRequiredLabel => 'Make *';

  @override
  String get garageSelectPlaceholder => 'Select…';

  @override
  String get garageBrandRequired => 'Make is required';

  @override
  String get garageModelRequiredLabel => 'Model *';

  @override
  String get garageSelectBrandFirst => 'Choose a make first';

  @override
  String get garageModelRequired => 'Model is required';

  @override
  String get garageModelExample => 'CX-9, Tribute, Prado…';

  @override
  String get garageEnterModel => 'Enter the model';

  @override
  String get garageBackToModels => 'Back to the model list';

  @override
  String get garageModelNotListed => 'My model is not listed';

  @override
  String get garageManufacturingYearLabel => 'Year of manufacture *';

  @override
  String get garageYearRequired => 'Year is required';

  @override
  String get garageInvalidYear => 'Invalid year';

  @override
  String get garageEngineCompatibilityExplanation =>
      'It determines which parts fit your vehicle. The trim often identifies it.';

  @override
  String get garageFuelLabel => 'Fuel';

  @override
  String get garageOptionalDetails => 'Details (optional)';

  @override
  String get garageNicknameLabel => 'Nickname';

  @override
  String get garageNicknameHint => 'E.g. My Corolla, The family car…';

  @override
  String get garageRegistrationLabel => 'Registration plate';

  @override
  String get garageRegistrationHint => 'E.g. AA 1234 BF';

  @override
  String get garageCurrentMileage => 'Current mileage';

  @override
  String get garageSaving => 'Saving…';

  @override
  String get garageCompatibilityAvailable =>
      'You will be able to filter parts that fit this vehicle.';

  @override
  String get garageUnlistedModelCompatibility =>
      'As your model is not in the catalogue, matching parts will remain unavailable — even if you enter the fuel type.';

  @override
  String get garageMissingEngineCompatibility =>
      'Without this information, the list of matching parts will remain empty. You can complete it later from your garage.';

  @override
  String get garageUnlistedModelServices =>
      'Deadlines, mileage, checks and maintenance reminders will work normally. Only matching parts will be unavailable: that search uses the catalogue. Your entry helps us expand it.';

  @override
  String get garageVinAutomaticTitle => 'Automatic VIN decoding';

  @override
  String get garageVinAutomaticExplanation =>
      'Enter the VIN (17-character chassis number) to fill in the form automatically.';

  @override
  String get garageVinLabel => 'VIN (chassis number)';

  @override
  String garageVinLength(String value0) {
    return '$value0/17 characters';
  }

  @override
  String get garageVinInvalidLength =>
      'The VIN must contain exactly 17 characters.';

  @override
  String get garageVinDecodeAction => 'Decode';

  @override
  String get garageVinInvalidTitle => 'Invalid VIN';

  @override
  String get garageVinCompletedTitle => 'Form filled in';

  @override
  String get garageVinCompletedBody => 'Check and complete it if needed.';

  @override
  String get garageVinPartialTitle => 'Partially filled in';

  @override
  String get garageVinPartialBody =>
      'Some fields could not be identified — please check.';

  @override
  String get garageVinLimitedTitle => 'Limited data';

  @override
  String get garageVinOfflineYearOnly =>
      'NHTSA API unavailable — only the year was decoded locally.';

  @override
  String get garageVinUnknownModel =>
      'Make or model not found in the catalogue — enter the details manually.';

  @override
  String get garageVinNoMatchTitle => 'No match';

  @override
  String get garageVinNoMatchBody => 'Fill in the form manually.';

  @override
  String get garageVinTwoYears => 'Two possible years — choose one:';

  @override
  String garageGenerationMismatch(String value0, String value1) {
    return '$value0 may not match $value1.';
  }

  @override
  String garageGenerationYearMismatch(
    String value0,
    String value1,
    String value2,
  ) {
    return 'The $value0 was produced $value1. Your vehicle is from $value2.';
  }

  @override
  String get garageGenerationAlternativeQuestion => 'Did you mean this one?';

  @override
  String garageGenerationAlternatives(String value0) {
    return 'Generations produced in $value0:';
  }

  @override
  String garageGenerationNoAlternative(String value0) {
    return 'No other generation of $value0 is recorded for this year. You can continue: the parts search will simply be less precise.';
  }

  @override
  String garageMatchingPartsForVehicle(String value0) {
    return 'Parts — $value0';
  }

  @override
  String get garageMatchingPartsTitle => 'Matching parts';

  @override
  String get garageMatchingPartsLimited =>
      'Limited accuracy — add the engine for more precise results.';

  @override
  String garageMatchingPartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parts found',
      one: '1 part found',
    );
    return '$_temp0';
  }

  @override
  String get garageUnknownEngineTitle => 'Engine unknown';

  @override
  String get garageNoMatchingPartsTitle => 'No parts listed for this model';

  @override
  String get garageUnknownEngineBody =>
      'Without the engine, we cannot determine which parts fit this vehicle. Enter it, or enter the chassis number to identify it automatically.';

  @override
  String get garageNoVehiclePartsBody =>
      'No catalogue parts are linked to this vehicle yet.';

  @override
  String garageNoModelPartsBody(String value0) {
    return 'No catalogue parts are linked to this model — a $value0 — yet.';
  }

  @override
  String get garageCompleteVehicleAction => 'Complete my vehicle';

  @override
  String get garageBrowseAllPartsAction => 'Browse all parts';

  @override
  String get garageRefillsTitle => 'Fuel refills';

  @override
  String garageFuelForVehicle(String value0) {
    return 'Fuel — $value0';
  }

  @override
  String get garageRefillLabel => 'Refill';

  @override
  String get garageRefillSaved => 'Refill saved.';

  @override
  String get garageFullRefillExplanation =>
      'Full tank — the pump stopped automatically';

  @override
  String get garagePartialRefill => 'Partial refill';

  @override
  String garageRefillSummary(String value0, String value1, String value2) {
    return '$value0 km · $value1 l$value2';
  }

  @override
  String get garageFullRefill => 'Full tank';

  @override
  String garageRefillConsumption(String value0, String value1, String value2) {
    return '$value0 l/100 km$value1$value2';
  }

  @override
  String get garageDeleteRefillAction => 'Delete this refill';

  @override
  String get garageDeleteRefillTitle => 'Delete this refill?';

  @override
  String get garageRefillDeleted => 'Refill deleted.';

  @override
  String get garageDeleteTwoIntervals =>
      'This refill closes one measurement and starts another. Deleting it removes both measurements and merges their intervals into one that is twice as long. Your consumption will be recalculated over it and may change significantly.';

  @override
  String get garageDeleteOneInterval =>
      'This refill closes one of the measurements used. Deleting it removes that measurement and recalculates your consumption.';

  @override
  String get garageDeleteRefillLitres =>
      'The litres from this refill will be removed from the calculation and your consumption will be recalculated.';

  @override
  String get garageNoRefillsTitle => 'No refills recorded';

  @override
  String get garageNoRefillsBody =>
      'Record what you buy at the pump: the amount paid and the price per litre are enough. After two full tanks, the app shows your vehicle’s actual consumption and alerts you if it rises.';

  @override
  String get garageSignInGarageTitle => 'Sign in to access your garage';

  @override
  String get garageSignInGarageBody =>
      'Quickly find parts that fit your vehicles.';

  @override
  String get garageSignInOrRegister => 'Sign in / Register';

  @override
  String get garageTitle => 'My garage';

  @override
  String get garageRefreshAction => 'Refresh';

  @override
  String get garageAccountTitle => 'My account';

  @override
  String get garageAddVehicleAction => 'Add a vehicle';

  @override
  String get garageSignOutAction => 'Sign out';

  @override
  String get garageSignedOut => 'You are signed out.';

  @override
  String get garageDeleteAccountTitle => 'Delete my account';

  @override
  String get garageAccountDeleted => 'Your account and data have been deleted.';

  @override
  String get garageAccountDeletionListTitle =>
      'The following will be permanently deleted:';

  @override
  String get garageAccountDeletionList =>
      '• your vehicles and their deadlines\n• your search requests\n• your notifications\n• your sign-in account';

  @override
  String get garageInvoicesRetained =>
      'Invoices for fulfilled orders are retained for accounting purposes.';

  @override
  String garageDeleteAccountConfirmText(String value0) {
    return 'To confirm, enter $value0:';
  }

  @override
  String get garageDeletePermanently => 'Delete permanently';

  @override
  String garageMileageValue(String value0) {
    return '$value0 km';
  }

  @override
  String get garagePreciseCompatibility => 'Precise compatibility';

  @override
  String get garageTrackDeadlinesAction => 'Track my deadlines';

  @override
  String get garageCheckVehicleAction => 'Check my vehicle';

  @override
  String get garageRepeatCheckAction => 'Check again';

  @override
  String get garageSellThisVehicle => 'Sell this vehicle';

  @override
  String get garageUpdateAction => 'Update';

  @override
  String garageCompactThousands(String value0) {
    return '$value0 k';
  }

  @override
  String get garageServiceMissingBoth =>
      'Enter the last oil-change mileage above and the vehicle’s current mileage using “Update”.';

  @override
  String get garageServiceMissingLastMileage =>
      'Enter the last oil-change mileage above.';

  @override
  String get garageServiceMissingCurrentMileage =>
      'Enter the vehicle’s current mileage using “Update”.';

  @override
  String get garageMaintenanceTitle => 'Maintenance deadlines';

  @override
  String get garageMaintenanceReminders =>
      'You will be notified 30 days before the deadline, then if it is overdue.';

  @override
  String get garageInspectionLabel => 'Vehicle inspection';

  @override
  String get garageInsuranceLabel => 'Insurance';

  @override
  String get garageOilChangeLabel => 'Oil change';

  @override
  String get garageLastOilChangeMileage => 'Mileage at last oil change';

  @override
  String get garageOilReminderMileageExplanation =>
      'Oil-change reminders depend on keeping your mileage up to date.';

  @override
  String get garageClearAction => 'Clear';

  @override
  String garageLastCheckTitle(String value0) {
    return 'Last check · $value0';
  }

  @override
  String get garageCheckNothingToFix => 'Nothing to address';

  @override
  String get garageCheckOnePointToFix => '1 item to address';

  @override
  String garageCheckPointsToFix(String value0) {
    return '$value0 items to address';
  }

  @override
  String garageDaysAgoLower(String value0) {
    return '$value0 days ago';
  }

  @override
  String get garageLastWeekLower => 'last week';

  @override
  String garageWeeksAgoLower(String value0) {
    return '$value0 weeks ago';
  }

  @override
  String garageMonthsAgoLower(String value0) {
    return '$value0 months ago';
  }

  @override
  String get garageRemoveVehicleAction => 'Remove from garage';

  @override
  String get garageRemoveVehicleTitle => 'Remove from garage?';

  @override
  String garageRemoveVehicleBody(String value0) {
    return '$value0 will be removed from your garage. This action cannot be undone.';
  }

  @override
  String get garageRemoveAction => 'Remove';

  @override
  String get garageEmptyTitle => 'Your garage is empty';

  @override
  String get garageEmptyBody =>
      'Add your vehicles to quickly find matching parts.';

  @override
  String get garageProfileTitle => 'My profile';

  @override
  String get garageStaffLabel => 'Staff';

  @override
  String garageCheckRejected(String value0) {
    return 'The check was not accepted: $value0\nCorrect the entry, then finish again.';
  }

  @override
  String garageCheckDeferred(String value0) {
    return 'Cannot send right now: $value0\nThe check is saved on this phone and will be sent when the network returns.';
  }

  @override
  String get garageVehicleFallback => 'My vehicle';

  @override
  String get garageCheckFinishedTitle => 'Check complete';

  @override
  String get garageCheckWaitingToSend =>
      'A completed check has not been sent yet. It will be sent when the network returns.';

  @override
  String get garageTripDestinationQuestion => 'Where are you going?';

  @override
  String garageTripOptionDistance(String value0, String value1) {
    return '$value0 · $value1 km';
  }

  @override
  String get garageOdometerLabel => 'Odometer reading';

  @override
  String get garageOdometerExplanation =>
      'You are in front of the dashboard: now is the time. Without this reading, oil-change reminders cannot be sent.';

  @override
  String get garageCheckComposing => 'Preparing…';

  @override
  String get garageViewCheckItems => 'See what to check';

  @override
  String garageTripCheckItemsExplanation(String value0) {
    return '$value0 items for this vehicle and journey. They vary by vehicle: each explains why it is included.';
  }

  @override
  String garageSeasonCheckItemsExplanation(String value0) {
    return '$value0 items to check once before the season, not before every journey.';
  }

  @override
  String get garageChooseTripAction => 'Choose the journey';

  @override
  String garageChangeTripDistance(String value0) {
    return '$value0 km journey · Change';
  }

  @override
  String get garageChangeCheckAction => 'Choose another check';

  @override
  String get garageFinishCheckAction => 'Finish the check';

  @override
  String get garageCheckOkay => 'OK';

  @override
  String get garageCheckWatch => 'Monitor';

  @override
  String get garageCheckFault => 'Fault';

  @override
  String get garageCheckOneUnchecked => '1 item was not checked.';

  @override
  String garageCheckUnchecked(String value0) {
    return '$value0 items were not checked.';
  }

  @override
  String garageCheckOdometerRecorded(String value0) {
    return 'Odometer recorded: $value0 km';
  }

  @override
  String get garageCheckFixNow => 'To address';

  @override
  String get garageCheckCanWait => 'Can wait';

  @override
  String get garageBackToGarageAction => 'Back to garage';

  @override
  String get garageViewPartsAction => 'View parts';

  @override
  String garageConsumptionValue(String value) {
    return 'Reference: $value L/100 km';
  }

  @override
  String garageFuelCostValue(String value0) {
    return '$value0 XOF/100 km';
  }

  @override
  String garageConsumptionMeasuredOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'measured over $count intervals',
      one: 'measured over 1 interval',
    );
    return '$_temp0';
  }

  @override
  String garageLitresValue(String value0) {
    return '$value0 l';
  }

  @override
  String garageCurrencyValue(String value0) {
    return '$value0 XOF';
  }

  @override
  String get garageSinceFirstRefill => 'since your first refill';

  @override
  String get garageNeedTwoFullRefills =>
      'Record two full tanks — with the pump stopping automatically — to see your actual consumption here.';

  @override
  String get garageNeedOneFullRefill =>
      'One more full tank and your actual consumption will appear here.';

  @override
  String get garageTrackConsumptionAction => 'Track my consumption';

  @override
  String get garageTrackConsumptionBody =>
      'Record your refills: the app calculates your actual fuel consumption.';

  @override
  String get garageConsumptionIncreased => 'Your consumption has increased.';

  @override
  String garageConsumptionIncreasedCompared(String value0, String value1) {
    return 'Your consumption has increased: $value0 l/100 km compared with your usual $value1.';
  }

  @override
  String get garageConsumptionCommonCauses =>
      'A dirty air filter and tyre pressure are the two most common causes.';

  @override
  String get garageOdometerReplacedExplanation =>
      'Odometer replaced: earlier refills remain in your history but are no longer used in this calculation.';

  @override
  String get garageOfficialConsumptionUnknown =>
      'Manufacturer consumption figure unknown';

  @override
  String garageOfficialConsumptionValue(String value0) {
    return 'Manufacturer figure $value0 l/100 km';
  }

  @override
  String get garageSpecifyEngineAction => 'Specify';

  @override
  String get garageChangeAction => 'Change';

  @override
  String get garageRecordRefillTitle => 'Fuel refill';

  @override
  String garageRefillHistoryCount(String value0) {
    return 'History ($value0)';
  }

  @override
  String get garageConsumptionQuestion => 'What is my consumption?';

  @override
  String garageOfficialCityHighway(String value0, String value1) {
    return 'city $value0 · highway $value1';
  }

  @override
  String get garageConsumptionNoModel =>
      'Consumption unavailable: this vehicle’s model is not in the catalogue yet.';

  @override
  String get garageEnginesUnavailable =>
      'Engine list unavailable. Try again later.';

  @override
  String get garageNoOfficialConsumption =>
      'No official consumption data for this model.';

  @override
  String get garageEngineSaved => 'Engine saved.';

  @override
  String garageEngineForVehicle(String value0) {
    return 'Engine in your $value0';
  }

  @override
  String get garageChooseEngineExplanation =>
      'Choose the engine under the bonnet. Trim does not change fuel consumption.';

  @override
  String get garageEngineSavedCompatibility =>
      'Engine saved: matching parts are up to date.';

  @override
  String get garageFuelQuestion => 'What fuel does this vehicle use?';

  @override
  String get garageRefillAmountPaid => 'Amount paid';

  @override
  String get garageRefillPricePerLitre => 'Price per litre';

  @override
  String get garageRefillLitres => 'Litres purchased';

  @override
  String get garageRefillValueUnchanged => 'Saved as entered.';

  @override
  String get garageRefillLitresCalculated =>
      'Litres are calculated from the amount and price.';

  @override
  String garageRefillCalculatedLitres(String value0) {
    return 'That is $value0 l';
  }

  @override
  String get garageRefillEnterAmount => 'Enter the amount paid';

  @override
  String get garageRefillKnowLitres => 'I know the litres';

  @override
  String get garageRefillFullTankExplanation =>
      'Full tank means the pump stopped automatically. Only a full tank allows consumption to be measured.';

  @override
  String get garageRefillMileageRequired => 'Enter the odometer reading.';

  @override
  String get garageRefillLitresRange => 'Litres must be between 1 and 200.';

  @override
  String get garageRefillImpossibleQuantity =>
      'The amount and price per litre give an impossible quantity.';

  @override
  String get garageMileageRequired => 'Enter a number of kilometres.';

  @override
  String get garageMileageOutOfRange =>
      'This mileage is outside the allowed range.';

  @override
  String garageMileageConfirmDecrease(String value0, String value1) {
    return 'The odometer read $value0 km. Press again to save $value1 km.';
  }

  @override
  String get garageConfirmAction => 'Confirm';

  @override
  String get garageSaveMileageAction => 'Save';

  @override
  String get needsMyNeedsTitle => 'My requests';

  @override
  String get needsNewNeedAction => 'New request';

  @override
  String needsYearFromValue(String value0) {
    return 'From $value0';
  }

  @override
  String needsBudgetValue(String value0) {
    return 'Budget: $value0';
  }

  @override
  String get needsToday => 'Today';

  @override
  String get needsYesterday => 'Yesterday';

  @override
  String needsDaysAgo(String value0) {
    return '$value0 days ago';
  }

  @override
  String get needsBodyHatchback => 'Hatchback';

  @override
  String get needsBodyPickup => 'Pick-up';

  @override
  String get needsBodyVan => 'Van';

  @override
  String get needsBodyBus => 'Bus';

  @override
  String get needsEmptyMineTitle => 'No requests submitted';

  @override
  String get needsEmptyMineBody =>
      'Tell us what you are looking for — we will\ncontact you when a matching offer is available.';

  @override
  String get needsStaffListTitle => 'Customer requests';

  @override
  String get needsStatusPending => 'Pending';

  @override
  String get needsStatusApproved => 'Forwarded';

  @override
  String get needsStatusContacted => 'Contacted';

  @override
  String get needsStatusFulfilled => 'Fulfilled';

  @override
  String get needsStatusCancelled => 'Cancelled';

  @override
  String get needsTypePart => 'Part';

  @override
  String get needsTypeAccessory => 'Accessory';

  @override
  String get needsFilterAll => 'All';

  @override
  String get needsFilterAllTypes => 'All types';

  @override
  String needsMaximumBudgetValue(String value0) {
    return 'Maximum budget: $value0';
  }

  @override
  String get needsNoContact => 'No contact details provided';

  @override
  String get needsUpdateAction => 'Update';

  @override
  String needsTodayAtTime(String value0, String value1) {
    return 'Today $value0:$value1';
  }

  @override
  String get needsUpdateStatusTitle => 'Update status';

  @override
  String get needsStaffNotesLabel => 'Internal notes (optional)';

  @override
  String get needsStaffNotesHint =>
      'E.g. Customer called on 02/09, quote sent…';

  @override
  String get needsEmptyPendingTitle => 'No pending requests';

  @override
  String get needsEmptyResultsTitle => 'No requests found';

  @override
  String get needsEmptyStaffBody =>
      'Requests submitted by customers\nwill appear here.';

  @override
  String get needsSubmittedTitle => 'Request saved!';

  @override
  String get needsSubmittedBody =>
      'We have received your request.\nOur team will contact you when a matching offer becomes available.';

  @override
  String get needsSubmittedConfirm => 'Got it';

  @override
  String get needsSignInRequiredTitle => 'Sign-in required';

  @override
  String get needsSignInRequiredBody => 'You must sign in to submit a request.';

  @override
  String get needsSignInAction => 'Sign in';

  @override
  String get needsIntroduction =>
      'Cannot find what you are looking for? Submit your request — we will contact you when a matching offer becomes available.';

  @override
  String get needsTypeLabel => 'What are you looking for?';

  @override
  String get needsDescriptionLabel => 'Describe your request *';

  @override
  String get needsVehicleDescriptionHint =>
      'Preferred colour, maximum mileage, desired options…';

  @override
  String get needsPartDescriptionHint =>
      'Reference, vehicle compatibility, desired condition…';

  @override
  String get needsAccessoryDescriptionHint =>
      'Dimensions, compatibility, colour…';

  @override
  String get needsDescriptionRequired =>
      'Describe what you need (at least 10 characters).';

  @override
  String get needsBudgetLabel => 'Maximum budget (optional)';

  @override
  String get needsBudgetInvalid => 'Invalid amount';

  @override
  String get needsCallbackPhoneLabel => 'Phone number to call you *';

  @override
  String get needsCallbackPhoneExplanation =>
      'We cannot reply without a number. You can provide a second number from another network.';

  @override
  String get needsPrimaryPhoneLabel => 'Primary number';

  @override
  String get needsSecondaryPhoneLabel => 'Other number (optional)';

  @override
  String get needsPhoneRequired => 'Enter a phone number.';

  @override
  String get needsPhoneTooShort => 'Number is too short.';

  @override
  String get needsRemovePhoneAction => 'Remove this number';

  @override
  String get needsAddPhoneAction => 'Add a number';

  @override
  String needsCustomerAccountNotice(String value0) {
    return 'Signed in as $value0 — your request will be linked to your account.';
  }

  @override
  String needsStaffAccountNotice(String value0) {
    return 'Entered by $value0 on behalf of a customer. The request will not be linked to an account: the number above is the only way to call them back.';
  }

  @override
  String get needsSubmitAction => 'Submit my request';

  @override
  String get needsVehicleCriteriaTitle => 'Vehicle requirements';

  @override
  String get needsBrandsLoadError => 'Could not load makes.';

  @override
  String get needsAnyBrand => 'All makes';

  @override
  String get needsModelsLoadError => 'Could not load models.';

  @override
  String get needsNoModels => 'No models available for this make.';

  @override
  String get needsAnyModel => 'All models';

  @override
  String get needsAnyOption => 'Any';

  @override
  String get needsYearFromLabel => 'From';

  @override
  String needsYearRangeInvalid(String value0) {
    return 'Invalid year (1950–$value0)';
  }

  @override
  String get needsYearEndBeforeStart => 'Must be at least the starting year';

  @override
  String get needsPartCriteriaTitle => 'Part requirements';

  @override
  String get needsCategoriesLoadError => 'Could not load categories.';

  @override
  String get needsAnyCategory => 'All categories';

  @override
  String get needsManufacturerOptionalLabel => 'Manufacturer (optional)';

  @override
  String get needsAnyManufacturer => 'All manufacturers';

  @override
  String get needsOemOptionalLabel => 'OEM reference (optional)';

  @override
  String get needsOemHint => 'E.g. 90915-YZZD4';

  @override
  String get needsOemTooLong =>
      'Reference is too long (maximum 100 characters)';

  @override
  String get needsAccessoryCriteriaTitle => 'Accessory requirements';

  @override
  String get needsBrandManufacturerOptional => 'Make / Manufacturer (optional)';

  @override
  String get needsCriteriaExplanation =>
      'The more detail you provide, the better we can match offers.';

  @override
  String get garageEngineMissingTitle => 'Engine not specified';

  @override
  String get garageEngineMissingBody =>
      'Without it, we cannot determine which parts fit this vehicle.';

  @override
  String get garageCompleteAction => 'Complete';

  @override
  String get garageTripCity => 'In town';

  @override
  String get garageTripHundredKm => 'About 100 km';

  @override
  String get garageTripOtherCity => 'Another city';

  @override
  String get garageTripOtherRegion => 'Another region';

  @override
  String get garageTripOtherCountry => 'Another country';

  @override
  String get garageRecentlyLower => 'recently';

  @override
  String get garageTodayLower => 'today';

  @override
  String get garageYesterdayLower => 'yesterday';

  @override
  String get garageNoInterval => 'None';

  @override
  String get vehiclesUpdated => 'Vehicle updated ✓';

  @override
  String get vehiclesCreated => 'Vehicle saved — add some photos!';

  @override
  String get vehiclesSaveFailed => 'Unable to save';

  @override
  String get vehiclesBuyerPriceLabel => 'Price shown to the buyer';

  @override
  String get vehiclesBuyerRateLabel => 'Rate shown to the buyer';

  @override
  String get vehiclesOk => 'OK';

  @override
  String get vehiclesEditTitle => 'Edit vehicle';

  @override
  String get vehiclesCreateTitle => 'Register a vehicle';

  @override
  String get vehiclesPhotos => 'Photos';

  @override
  String get vehiclesTypeTitle => 'Vehicle type';

  @override
  String get vehiclesTypePassenger => 'Passenger car';

  @override
  String get vehiclesTypeUtility => 'Commercial vehicle';

  @override
  String get vehiclesTypeHeavy => 'Heavy vehicle';

  @override
  String get vehiclesBodyStyleLabel => 'Body style *';

  @override
  String get vehiclesBodyStyleHint => 'Saloon, SUV, pickup…';

  @override
  String get vehiclesBodyStyleRequired => 'Select a body style';

  @override
  String get vehiclesVinOptional => 'VIN (optional)';

  @override
  String get vehiclesVinHelper =>
      '17 characters — international vehicle identification number';

  @override
  String get vehiclesVinLengthError =>
      'The VIN must contain exactly 17 characters.';

  @override
  String get vehiclesRegisteredLabel => 'Registered vehicle';

  @override
  String get vehiclesRegisteredHint =>
      'Already registered — the number plate can be added later.';

  @override
  String get vehiclesImportedHint => 'Imported and not yet registered here.';

  @override
  String get vehiclesRegistrationRemovalWarning =>
      'This vehicle is recorded as registered. Marking it as imported will delete its registration details. Enter the mileage again: registered-vehicle mileage and mileage at import are different readings.';

  @override
  String get vehiclesPlateOptional => 'Number plate (optional)';

  @override
  String get vehiclesPlateHint => 'e.g. AA 1234 BF';

  @override
  String get vehiclesIdentityTitle => 'Identity';

  @override
  String get vehiclesBrandLabel => 'Make *';

  @override
  String get vehiclesBrandRequired => 'Make is required';

  @override
  String get vehiclesModelLabel => 'Model *';

  @override
  String get vehiclesModelRequired => 'Model is required';

  @override
  String get vehiclesManufactureYearLabel => 'Year of manufacture *';

  @override
  String get vehiclesYearRequired => 'Year is required';

  @override
  String get vehiclesTransmissionManualSummary => 'manual';

  @override
  String get vehiclesTransmissionAutomaticSummary => 'automatic';

  @override
  String get vehiclesOfferRentSummary => 'rental';

  @override
  String get vehiclesOfferBothSummary => 'sale and rental';

  @override
  String get vehiclesOfferSaleSummary => 'sale';

  @override
  String get vehiclesTechnicalTitle => 'Technical specifications';

  @override
  String get vehiclesEngineTypeLabel => 'Powertrain type *';

  @override
  String get vehiclesEngineTypeRequired => 'Powertrain is required';

  @override
  String get vehiclesTransmissionLabel => 'Gearbox';

  @override
  String get vehiclesDrivetrainLabel => 'Driven wheels';

  @override
  String get vehiclesPowerLabel => 'Power (hp)';

  @override
  String get vehiclesFeaturesTitle => 'Equipment & options';

  @override
  String get vehiclesFeaturesHint =>
      'Select the equipment fitted to this vehicle.';

  @override
  String get vehiclesCommercialTitle => 'Sales information';

  @override
  String get vehiclesConditionLabel => 'Vehicle condition';

  @override
  String get vehiclesConditionDamaged => 'Damaged';

  @override
  String get vehiclesOriginCountryLabel => 'Country of origin';

  @override
  String get vehiclesOriginCountryHint => 'Origin of the imported vehicle';

  @override
  String get vehiclesAvailabilityLabel => 'Available for';

  @override
  String get vehiclesForSale => 'Sale';

  @override
  String get vehiclesForRent => 'Rental';

  @override
  String get vehiclesForBoth => 'Sale & rental';

  @override
  String get vehiclesDealLabel => 'Promotion';

  @override
  String get vehiclesNoDeal => 'None';

  @override
  String get vehiclesGoodDeal => 'Good deal';

  @override
  String get vehiclesFlashSale => 'Flash sale';

  @override
  String get vehiclesClearance => 'Clearance';

  @override
  String get vehiclesSalePriceLabel => 'Sale price *';

  @override
  String get vehiclesSalePriceRequired => 'Sale price is required';

  @override
  String get vehiclesDailyRateLabel => 'Daily rate';

  @override
  String get vehiclesMonthlyRateLabel => 'Monthly rate';

  @override
  String get vehiclesRentalRateRequired => 'Enter a daily or monthly rate';

  @override
  String get vehiclesRentalRateHint =>
      'Enter at least one rate: daily or monthly.';

  @override
  String get vehiclesDepositLabel => 'Deposit';

  @override
  String get vehiclesNegotiable => 'Negotiable price';

  @override
  String get vehiclesBranchLabel => 'Branch / showroom';

  @override
  String get vehiclesSiteLabel => 'Site / branch';

  @override
  String get vehiclesSiteHint => 'e.g. Ouagadougou North showroom';

  @override
  String get vehiclesSupplierLabel => 'Supplier / source partner';

  @override
  String get vehiclesSupplierHint =>
      'Vehicle source (importer, auction, partner dealership…)';

  @override
  String get vehiclesPartnersLoadFailed => 'Unable to load partners.';

  @override
  String get vehiclesNoneOptional => 'None (optional)';

  @override
  String get vehiclesNone => 'None';

  @override
  String get vehiclesDescriptionHint => 'Additional vehicle details…';

  @override
  String get vehiclesNext => 'Next';

  @override
  String get vehiclesBack => 'Back';

  @override
  String get vehiclesFeatureStandard => 'Standard equipment';

  @override
  String get vehiclesFeatureComfort => 'Comfort';

  @override
  String get vehiclesFeatureSafety => 'Safety';

  @override
  String get vehiclesFeatureMultimedia => 'Multimedia';

  @override
  String get vehiclesFeatureDriverAssistance => 'Driver assistance';

  @override
  String get vehiclesFeatureOther => 'Other';

  @override
  String get vehiclesFeatureStandardHint => '— tick the items fitted';

  @override
  String get vehiclesErrorNetworkTitle => 'No connection';

  @override
  String get vehiclesErrorSessionTitle => 'Session expired';

  @override
  String get vehiclesErrorForbiddenTitle => 'Action not allowed';

  @override
  String get vehiclesErrorValidationTitle => 'Incomplete form';

  @override
  String get vehiclesErrorTooLargeTitle => 'Upload too large';

  @override
  String get vehiclesErrorThrottledTitle => 'Too many attempts';

  @override
  String get vehiclesErrorServerTitle => 'Server error';

  @override
  String get vehiclesFaultDeclare => 'Report';

  @override
  String get vehiclesFaultResolve => 'Resolve';

  @override
  String get vehiclesFaultDrivingAffected => 'Driving affected';

  @override
  String get vehiclesFaultDisclosed => 'Disclosed to buyer';

  @override
  String get vehiclesFaultDeleteTitle => 'Delete this fault?';

  @override
  String get vehiclesFaultEmpty => 'No faults reported';

  @override
  String get vehiclesFaultEmptyStaffHint =>
      'Report known faults to inform buyers.';

  @override
  String get vehiclesFaultEmptyViewerHint =>
      'This vehicle has no known faults.';

  @override
  String get vehiclesFaultCreateTitle => 'Report a fault';

  @override
  String get vehiclesFaultTitleLabel => 'Title *';

  @override
  String get vehiclesFaultTitleHint => 'e.g. Engine oil leak';

  @override
  String get vehiclesFaultTitleRequired => 'Title is required';

  @override
  String get vehiclesFaultCategoryLabel => 'Category *';

  @override
  String get vehiclesFaultSeverityLabel => 'Severity *';

  @override
  String get vehiclesFaultAffectsDriving => 'Affects driving';

  @override
  String get vehiclesFaultDrivingHint =>
      'The vehicle is difficult or unsafe to drive';

  @override
  String get vehiclesFaultSafetyCritical => 'Safety-critical';

  @override
  String get vehiclesFaultDisclosureLabel => 'Disclosed to the buyer';

  @override
  String get vehiclesFaultDisclosureHint =>
      'This fault is mentioned in the listing';

  @override
  String get vehiclesFaultDescriptionLabel => 'Description (optional)';

  @override
  String get vehiclesFaultDescriptionHint =>
      'Fault details, symptoms, conditions…';

  @override
  String get vehiclesFaultObdLabel => 'OBD code (optional)';

  @override
  String get vehiclesFaultObdHint => 'e.g. P0301';

  @override
  String get vehiclesFaultDetectionDate => 'Detection date (optional)';

  @override
  String get vehiclesDateHint => 'YYYY-MM-DD';

  @override
  String get vehiclesFaultDetectionMileage => 'Mileage at detection (optional)';

  @override
  String get vehiclesFaultEstimatedCost => 'Estimated repair cost (optional)';

  @override
  String get vehiclesAmountInvalid => 'Invalid amount';

  @override
  String get vehiclesFaultReportedBy => 'Reported by (optional)';

  @override
  String get vehiclesFaultReporterHint => 'Technician or customer name';

  @override
  String get vehiclesFaultSave => 'Save fault';

  @override
  String get vehiclesFaultRepairDate => 'Repair date';

  @override
  String get vehiclesFaultActualCost => 'Actual repair cost (optional)';

  @override
  String get vehiclesFaultMarkRepaired => 'Mark as repaired';

  @override
  String get vehiclesFaultCategoryEngine => 'Engine';

  @override
  String get vehiclesFaultCategoryTransmission => 'Transmission';

  @override
  String get vehiclesFaultCategoryElectrical => 'Electrical';

  @override
  String get vehiclesFaultCategoryBraking => 'Brakes';

  @override
  String get vehiclesFaultCategorySuspension => 'Suspension';

  @override
  String get vehiclesFaultCategorySteering => 'Steering';

  @override
  String get vehiclesFaultCategoryCooling => 'Cooling';

  @override
  String get vehiclesFaultCategoryAirConditioning => 'Air conditioning';

  @override
  String get vehiclesFaultCategoryBodywork => 'Bodywork';

  @override
  String get vehiclesFaultCategoryInterior => 'Interior';

  @override
  String get vehiclesFaultCategoryElectronics => 'Electronics';

  @override
  String get vehiclesFaultCategoryTyres => 'Tyres';

  @override
  String get vehiclesFaultCategoryOther => 'Other';

  @override
  String get vehiclesFaultSeverityMinor => 'Minor';

  @override
  String get vehiclesFaultSeverityModerate => 'Moderate';

  @override
  String get vehiclesFaultSeverityMajor => 'Major';

  @override
  String get vehiclesFaultSeverityCritical => 'Critical';

  @override
  String get vehiclesFaultStatusDeclared => 'Reported';

  @override
  String get vehiclesFaultStatusDiagnosed => 'Diagnosed';

  @override
  String get vehiclesFaultStatusQuoted => 'Quoted';

  @override
  String get vehiclesFaultStatusRepairing => 'Being repaired';

  @override
  String get vehiclesFaultStatusRepaired => 'Repaired';

  @override
  String get vehiclesFaultStatusWontFix => 'No further action';

  @override
  String vehiclesMissingStep(int step) {
    return 'Something is missing in step $step.';
  }

  @override
  String vehiclesYearRangeInvalid(int year) {
    return 'Invalid year (1950–$year)';
  }

  @override
  String vehiclesPowerSummary(String power) {
    return '$power hp';
  }

  @override
  String vehiclesOfferSummary(String offer, String price) {
    return '$offer · $price FCFA';
  }

  @override
  String vehiclesReferencesLoadError(String error) {
    return 'Unable to load reference data:\n$error';
  }

  @override
  String vehiclesFaultEstimatedCostValue(String cost) {
    return 'Estimated: $cost';
  }

  @override
  String vehiclesFaultActualCostValue(String cost) {
    return 'Actual: $cost';
  }

  @override
  String vehiclesFaultResolveTitle(String title) {
    return 'Resolve: $title';
  }

  @override
  String get catalogAdminSelectCategory => 'Please select a category.';

  @override
  String get catalogAdminPartUpdated => 'Part updated.';

  @override
  String get catalogAdminPartCreated => 'Part saved — add some photos!';

  @override
  String get catalogAdminAccessoryUpdated => 'Accessory updated.';

  @override
  String get catalogAdminAccessoryCreated =>
      'Accessory saved — add some photos!';

  @override
  String get catalogAdminEditPart => 'Edit part';

  @override
  String get catalogAdminNewPart => 'New part';

  @override
  String get catalogAdminEditAccessory => 'Edit accessory';

  @override
  String get catalogAdminNewAccessory => 'New accessory';

  @override
  String get catalogAdminIdentification => 'Identification';

  @override
  String get catalogAdminNameLabel => 'Name *';

  @override
  String get catalogAdminRequired => 'Required';

  @override
  String get catalogAdminSkuLabel => 'SKU / internal reference';

  @override
  String get catalogAdminPartSkuHint => 'e.g. PDT-BRQ-0042 (optional)';

  @override
  String get catalogAdminAccessorySkuHint => 'e.g. ACC-EST-0012 (optional)';

  @override
  String get catalogAdminTypeLabel => 'Type *';

  @override
  String get catalogAdminConditionLabel => 'Condition *';

  @override
  String get catalogAdminConditionNew => 'New';

  @override
  String get catalogAdminConditionRefurbished => 'Refurbished';

  @override
  String get catalogAdminConditionUsed => 'Used';

  @override
  String get catalogAdminClassification => 'Classification';

  @override
  String get catalogAdminCategoryLabel => 'Category *';

  @override
  String get catalogAdminManufacturerLabel =>
      'Manufacturer / equipment supplier';

  @override
  String get catalogAdminPricing => 'Pricing';

  @override
  String get catalogAdminSalePrice => 'Sale price *';

  @override
  String get catalogAdminInvalidNumber => 'Invalid number';

  @override
  String get catalogAdminPurchasePrice => 'Purchase price';

  @override
  String get catalogAdminOptional => 'Optional';

  @override
  String get catalogAdminStock => 'Stock';

  @override
  String get catalogAdminInitialQuantity => 'Initial quantity';

  @override
  String get catalogAdminAlertThreshold => 'Alert threshold';

  @override
  String get catalogAdminPhysicalLocation => 'Storage location';

  @override
  String get catalogAdminLocationHint => 'e.g. Shelf B3, Drawer 12';

  @override
  String get catalogAdminBranch => 'Branch / showroom';

  @override
  String get catalogAdminAllBranches => '— All branches —';

  @override
  String get catalogAdminFitments => 'Vehicle compatibility';

  @override
  String get catalogAdminFitmentsHint =>
      'Specify compatible vehicles to enable model-based searches, even without an OEM number.';

  @override
  String get catalogAdminNone => '— None —';

  @override
  String catalogAdminModelsLoadError(String error) {
    return 'Unable to load models: $error';
  }

  @override
  String get mediaDeletePhotoTitle => 'Delete this photo?';

  @override
  String get mediaDeletePhotoBody => 'This action cannot be undone.';

  @override
  String get mediaFinish => 'Done';

  @override
  String get mediaUploading => 'Uploading…';

  @override
  String get mediaGallery => 'Gallery';

  @override
  String get mediaCamera => 'Camera';

  @override
  String get mediaCover => 'Cover';

  @override
  String get mediaLoadFailed => 'Photos not loaded';

  @override
  String get mediaEmpty => 'No photos';

  @override
  String get mediaEmptyHint => 'Tap Gallery to add photos.';

  @override
  String get mediaAddPhotos => 'Add photos';

  @override
  String mediaPhotosAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos added.',
      one: '1 photo added.',
    );
    return '$_temp0';
  }

  @override
  String get catalogAdminAccessoryFitmentsHint =>
      'Optional — specify compatible vehicles to make searching easier.';

  @override
  String get needsTypeSparePart => 'Spare part';

  @override
  String get garageRefillMissing => 'A refill was probably missed';

  @override
  String get garageRefillImplausible =>
      'Implausible figure: a refill is missing';

  @override
  String get garageRefillTooLow =>
      'Figure too low to be correct: an earlier refill was not recorded';

  @override
  String garageDeadlineOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get garageDeadlineToday => 'Expires today';

  @override
  String garageDeadlineInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days',
      one: 'In 1 day',
    );
    return '$_temp0';
  }

  @override
  String garageRefillDistanceSuffix(String value0) {
    return ' over $value0 km';
  }

  @override
  String get garageRefillExcludedSuffix => ' — excluded';

  @override
  String get needsYearToLabel => 'To';

  @override
  String get garageGenericVehicle => 'vehicle';

  @override
  String get garageCurrencyUnit => 'XOF';

  @override
  String get garageCurrencyPerLitre => 'XOF/l';

  @override
  String garageRefillAmountSuffix(String value0) {
    return ' · $value0 XOF';
  }

  @override
  String garageModelSinceYear(String value0) {
    return 'since $value0';
  }

  @override
  String catalogFitmentModelNumber(String value) {
    return 'Model no. $value';
  }

  @override
  String get notificationsChannelDescription =>
      'Important AutoParc notifications';

  @override
  String get updateUnsupportedMessage =>
      'This version of the app is no longer supported. Install the latest version to continue.';

  @override
  String get authErrorTokenMissing =>
      'The server response did not include a session token.';

  @override
  String get authErrorGoogleTokenMissing =>
      'Google did not provide an identity token.';

  @override
  String get authErrorGoogleInterrupted =>
      'Google sign-in was interrupted. If you did not close the window, check your internet connection and try again.';

  @override
  String get authErrorGoogleInterruptedNetwork =>
      'Google sign-in was interrupted. Check your internet connection and try again.';

  @override
  String get authErrorGoogleConfiguration =>
      'Google sign-in is not configured correctly for this version of the app.';

  @override
  String get authErrorGoogleUnavailable =>
      'Google sign-in is not available on this device.';

  @override
  String get authErrorGoogleWindow =>
      'The Google sign-in window could not be opened.';

  @override
  String authErrorGoogleCode(String value0) {
    return 'Google sign-in failed ($value0).';
  }

  @override
  String get authErrorAccountMissing =>
      'No account was found for this email address.';

  @override
  String get authErrorWrongPassword => 'Incorrect password.';

  @override
  String get authErrorCredentials => 'Incorrect email or password.';

  @override
  String get authErrorPartnerAccount =>
      'This is a partner account. Sign in to the partner area.';

  @override
  String get authErrorStaffAccount =>
      'This is a staff account. Use staff sign-in.';

  @override
  String get authOpenPartnerSpace => 'Open partner area';

  @override
  String get authErrorEmailInUse =>
      'An account already exists for this email address.';

  @override
  String get authErrorWeakPassword =>
      'The password is too weak (at least 6 characters required).';

  @override
  String get authErrorEmailInvalid => 'Invalid email address.';

  @override
  String get authErrorNetwork =>
      'Network error. Check your internet connection.';

  @override
  String get authErrorMethodDisabled => 'This sign-in method is not enabled.';

  @override
  String get authErrorOtherMethod =>
      'This account already uses a different sign-in method.';

  @override
  String authErrorCode(String value0) {
    return 'Sign-in error ($value0).';
  }

  @override
  String get authErrorUnavailable =>
      'Sign-in is currently unavailable. Try again.';

  @override
  String get authErrorDeleteClientOnly =>
      'Only customer accounts can be deleted here.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsBroadcastTooltip => 'Send a tip';

  @override
  String notificationsMinutesAgo(String value0) {
    return '$value0 min ago';
  }

  @override
  String notificationsHoursAgo(String value0) {
    return '$value0 h ago';
  }

  @override
  String get notificationsYesterday => 'Yesterday';

  @override
  String notificationsDaysAgo(String value0) {
    return '$value0 days ago';
  }

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptyBody => 'Important activity will appear here.';

  @override
  String get notificationsTitleBodyRequired =>
      'A title and message are required.';

  @override
  String get notificationsBroadcastSent => 'Tip sent to all customers ✓';

  @override
  String get notificationsBroadcastTitle => 'Tip for vehicle owners';

  @override
  String get notificationsBroadcastBody =>
      'This message will be sent as a push notification to all app customers.';

  @override
  String get notificationsTitleField => 'Title *';

  @override
  String get notificationsTitleHint => 'e.g. Check your tyre pressure';

  @override
  String get notificationsBodyField => 'Message *';

  @override
  String get notificationsBodyHint =>
      'e.g. Correct tyre pressure can improve tyre life by 20%…';

  @override
  String get notificationsBroadcastAction => 'Send to all customers';

  @override
  String get catalogFitmentEmptyTitle => 'No declared fitments';

  @override
  String get catalogFitmentEmptyBody =>
      'The part will only be searchable by SKU.';

  @override
  String get catalogFitmentUnverified =>
      'Automatically suggested, not verified';

  @override
  String get catalogFitmentConfirmationHint =>
      'When you save, the suggested rows you keep become declared fitments. They will no longer be recalculated, and you are responsible for confirming them. Remove any you cannot confirm.';

  @override
  String get catalogFitmentAdd => 'Add a fitment';

  @override
  String get catalogFitmentModelRequired => 'Please select a model.';

  @override
  String get catalogFitmentDialogTitle => 'Vehicle fitment';

  @override
  String get catalogFitmentBrandRequired => 'Brand *';

  @override
  String get catalogFitmentSelect => 'Select…';

  @override
  String get catalogFitmentModelField => 'Model *';

  @override
  String get catalogFitmentChooseBrand => 'Choose a brand first';

  @override
  String get catalogFitmentTrimOptional => 'Trim (optional)';

  @override
  String get catalogFitmentAllTrims => 'All trims';

  @override
  String get catalogFitmentAllTrimsOption => '— All trims —';

  @override
  String get catalogFitmentYearFromField => 'Year from';

  @override
  String get catalogFitmentYearToField => 'Year to';

  @override
  String get catalogFitmentPositionField => 'Position (optional)';

  @override
  String get catalogFitmentPositionHint => 'e.g. Front left, engine side…';

  @override
  String get catalogFitmentConfirmAction => 'Add this fitment';

  @override
  String get catalogFitmentUnavailableTitle => 'Fitments could not be loaded';

  @override
  String get catalogFitmentUnavailableBody =>
      'They could not be loaded and cannot be edited at the moment. They will be preserved unchanged when you save the other fields. Reopen this screen when your connection is restored to edit them.';

  @override
  String get vehiclesReferenceFuelPetrol => 'Petrol';

  @override
  String get vehiclesReferenceFuelDiesel => 'Diesel';

  @override
  String get vehiclesReferenceFuelElectric => 'Electric';

  @override
  String get vehiclesReferenceFuelHybrid => 'Hybrid';

  @override
  String get vehiclesReferenceDriveFrontWheel => 'Front-wheel drive';

  @override
  String get vehiclesReferenceDriveRearWheel => 'Rear-wheel drive';

  @override
  String get vehiclesReferenceDriveAllWheel => 'All-wheel drive (AWD)';

  @override
  String get vehiclesReferenceDriveFourWheel => 'Four-wheel drive (4WD)';

  @override
  String get vehiclesReferenceColourWhite => 'White';

  @override
  String get vehiclesReferenceColourPearlWhite => 'Pearl white';

  @override
  String get vehiclesReferenceColourLightGrey => 'Light grey';

  @override
  String get vehiclesReferenceColourAnthraciteGrey => 'Anthracite grey';

  @override
  String get vehiclesReferenceColourTitaniumGrey => 'Titanium grey';

  @override
  String get vehiclesReferenceColourSilver => 'Silver';

  @override
  String get vehiclesReferenceColourBlack => 'Black';

  @override
  String get vehiclesReferenceColourMetallicBlack => 'Metallic black';

  @override
  String get vehiclesReferenceColourRed => 'Red';

  @override
  String get vehiclesReferenceColourMetallicRed => 'Metallic red';

  @override
  String get vehiclesReferenceColourBurgundy => 'Burgundy';

  @override
  String get vehiclesReferenceColourNavyBlue => 'Navy blue';

  @override
  String get vehiclesReferenceColourMetallicBlue => 'Metallic blue';

  @override
  String get vehiclesReferenceColourSkyBlue => 'Sky blue';

  @override
  String get vehiclesReferenceColourDarkGreen => 'Dark green';

  @override
  String get vehiclesReferenceColourOliveGreen => 'Olive green';

  @override
  String get vehiclesReferenceColourBeige => 'Beige';

  @override
  String get vehiclesReferenceColourBrown => 'Brown';

  @override
  String get vehiclesReferenceColourGoldChampagne => 'Gold / Champagne';

  @override
  String get vehiclesReferenceColourOrange => 'Orange';

  @override
  String get vehiclesReferenceColourYellow => 'Yellow';

  @override
  String get vehiclesReferenceColourPurple => 'Purple';

  @override
  String get vehiclesReferenceCountryBf => 'Burkina Faso';

  @override
  String get vehiclesReferenceCountryCi => 'Côte d’Ivoire';

  @override
  String get vehiclesReferenceCountrySn => 'Senegal';

  @override
  String get vehiclesReferenceCountryMl => 'Mali';

  @override
  String get vehiclesReferenceCountryNe => 'Niger';

  @override
  String get vehiclesReferenceCountryTg => 'Togo';

  @override
  String get vehiclesReferenceCountryBj => 'Benin';

  @override
  String get vehiclesReferenceCountryGw => 'Guinea-Bissau';

  @override
  String get vehiclesReferenceCountryGn => 'Guinea';

  @override
  String get vehiclesReferenceCountryGh => 'Ghana';

  @override
  String get vehiclesReferenceCountryNg => 'Nigeria';

  @override
  String get vehiclesReferenceCountryLr => 'Liberia';

  @override
  String get vehiclesReferenceCountrySl => 'Sierra Leone';

  @override
  String get vehiclesReferenceCountryGm => 'Gambia';

  @override
  String get vehiclesReferenceCountryCv => 'Cape Verde';

  @override
  String get vehiclesReferenceCountryMr => 'Mauritania';

  @override
  String get vehiclesReferenceCountryCm => 'Cameroon';

  @override
  String get vehiclesReferenceCountryCf => 'Central African Republic';

  @override
  String get vehiclesReferenceCountryTd => 'Chad';

  @override
  String get vehiclesReferenceCountryCg => 'Congo - Brazzaville';

  @override
  String get vehiclesReferenceCountryGa => 'Gabon';

  @override
  String get vehiclesReferenceCountryGq => 'Equatorial Guinea';

  @override
  String get vehiclesReferenceCountryCd => 'Congo - Kinshasa';

  @override
  String get vehiclesReferenceCountryEt => 'Ethiopia';

  @override
  String get vehiclesReferenceCountryKe => 'Kenya';

  @override
  String get vehiclesReferenceCountryTz => 'Tanzania';

  @override
  String get vehiclesReferenceCountryUg => 'Uganda';

  @override
  String get vehiclesReferenceCountryRw => 'Rwanda';

  @override
  String get vehiclesReferenceCountryZa => 'South Africa';

  @override
  String get vehiclesReferenceCountryAo => 'Angola';

  @override
  String get vehiclesReferenceCountryMz => 'Mozambique';

  @override
  String get vehiclesReferenceCountryMa => 'Morocco';

  @override
  String get vehiclesReferenceCountryDz => 'Algeria';

  @override
  String get vehiclesReferenceCountryTn => 'Tunisia';

  @override
  String get vehiclesReferenceCountryEg => 'Egypt';

  @override
  String get vehiclesReferenceCountryLy => 'Libya';

  @override
  String get vehiclesReferenceCountryJp => 'Japan';

  @override
  String get vehiclesReferenceCountryKr => 'South Korea';

  @override
  String get vehiclesReferenceCountryDe => 'Germany';

  @override
  String get vehiclesReferenceCountryFr => 'France';

  @override
  String get vehiclesReferenceCountryGb => 'United Kingdom';

  @override
  String get vehiclesReferenceCountryNl => 'Netherlands';

  @override
  String get vehiclesReferenceCountryBe => 'Belgium';

  @override
  String get vehiclesReferenceCountryIt => 'Italy';

  @override
  String get vehiclesReferenceCountryEs => 'Spain';

  @override
  String get vehiclesReferenceCountrySe => 'Sweden';

  @override
  String get vehiclesReferenceCountryCn => 'China';

  @override
  String get vehiclesReferenceCountryIn => 'India';

  @override
  String get vehiclesReferenceCountryUs => 'United States';

  @override
  String get vehiclesReferenceCountryCa => 'Canada';

  @override
  String get vehiclesReferenceCountryAu => 'Australia';

  @override
  String get vehiclesReferenceCountryBr => 'Brazil';

  @override
  String get vehiclesReferenceCountryMx => 'Mexico';

  @override
  String get vehiclesReferenceCountryTr => 'Türkiye';

  @override
  String get vehiclesReferenceCountryAe => 'United Arab Emirates';

  @override
  String get vehiclesReferenceCountrySa => 'Saudi Arabia';

  @override
  String get vehiclesReferenceCountryPk => 'Pakistan';

  @override
  String get vehiclesReferenceCountryId => 'Indonesia';

  @override
  String get vehiclesReferenceCountryTh => 'Thailand';

  @override
  String get vehiclesReferenceCountryMy => 'Malaysia';

  @override
  String get vehiclesReferenceCountrySg => 'Singapore';

  @override
  String get vehiclesReferenceCountryZw => 'Zimbabwe';

  @override
  String get vehiclesReferenceCountryLb => 'Lebanon';

  @override
  String get vehiclesReferenceCountryPt => 'Portugal';

  @override
  String get vehiclesReferenceCountryCh => 'Switzerland';

  @override
  String get vehiclesReferenceCountryAt => 'Austria';

  @override
  String get vehiclesReferenceCountryPl => 'Poland';

  @override
  String get catalogPartCategoryEngine => 'Engine';

  @override
  String get catalogPartCategoryFilters => 'Filters';

  @override
  String get catalogPartCategoryOilFilter => 'Oil filter';

  @override
  String get catalogPartCategoryAirFilter => 'Air filter';

  @override
  String get catalogPartCategoryCabinFilter => 'Cabin filter';

  @override
  String get catalogPartCategoryFuelFilter => 'Fuel filter';

  @override
  String get catalogPartCategoryTimingSystem => 'Timing system';

  @override
  String get catalogPartCategoryTimingBelt => 'Timing belt';

  @override
  String get catalogPartCategoryTimingBeltKit => 'Timing belt kit';

  @override
  String get catalogPartCategoryTimingChain => 'Timing chain';

  @override
  String get catalogPartCategoryLubrication => 'Lubrication';

  @override
  String get catalogPartCategoryEngineOil => 'Engine oil';

  @override
  String get catalogPartCategoryCylinderHeadGasket => 'Cylinder head gasket';

  @override
  String get catalogPartCategoryOilSump => 'Oil sump';

  @override
  String get catalogPartCategoryCooling => 'Cooling';

  @override
  String get catalogPartCategoryRadiator => 'Radiator';

  @override
  String get catalogPartCategoryThermostat => 'Thermostat';

  @override
  String get catalogPartCategoryWaterPump => 'Water pump';

  @override
  String get catalogPartCategoryCoolant => 'Coolant';

  @override
  String get catalogPartCategoryInjectionIgnition => 'Injection & ignition';

  @override
  String get catalogPartCategorySparkPlugs => 'Spark plugs';

  @override
  String get catalogPartCategoryInjectors => 'Injectors';

  @override
  String get catalogPartCategoryIgnitionCoils => 'Ignition coils';

  @override
  String get catalogPartCategoryBraking => 'Braking';

  @override
  String get catalogPartCategoryDiscsPads => 'Discs & pads';

  @override
  String get catalogPartCategoryFrontBrakeDiscs => 'Front brake discs';

  @override
  String get catalogPartCategoryRearBrakeDiscs => 'Rear brake discs';

  @override
  String get catalogPartCategoryFrontBrakePads => 'Front brake pads';

  @override
  String get catalogPartCategoryRearBrakePads => 'Rear brake pads';

  @override
  String get catalogPartCategoryBrakeCalipers => 'Brake calipers';

  @override
  String get catalogPartCategoryBrakeMasterCylinder => 'Brake master cylinder';

  @override
  String get catalogPartCategoryBrakeHoses => 'Brake hoses';

  @override
  String get catalogPartCategoryBrakeFluid => 'Brake fluid';

  @override
  String get catalogPartCategorySuspensionSteering => 'Suspension & steering';

  @override
  String get catalogPartCategoryShockAbsorbers => 'Shock absorbers';

  @override
  String get catalogPartCategoryFrontShockAbsorbers => 'Front shock absorbers';

  @override
  String get catalogPartCategoryRearShockAbsorbers => 'Rear shock absorbers';

  @override
  String get catalogPartCategorySprings => 'Springs';

  @override
  String get catalogPartCategoryBallJointsLinks => 'Ball joints & links';

  @override
  String get catalogPartCategoryTieRodEnd => 'Tie rod end';

  @override
  String get catalogPartCategoryAntiRollBarLink => 'Anti-roll bar link';

  @override
  String get catalogPartCategoryWheelBearingsHubs => 'Wheel bearings & hubs';

  @override
  String get catalogPartCategoryCVBootsJoints => 'CV boots & joints';

  @override
  String get catalogPartCategorySteering => 'Steering';

  @override
  String get catalogPartCategorySteeringRack => 'Steering rack';

  @override
  String get catalogPartCategorySteeringColumn => 'Steering column';

  @override
  String get catalogPartCategoryTransmission => 'Transmission';

  @override
  String get catalogPartCategoryGearbox => 'Gearbox';

  @override
  String get catalogPartCategoryClutch => 'Clutch';

  @override
  String get catalogPartCategoryClutchKit => 'Clutch kit';

  @override
  String get catalogPartCategoryFlywheel => 'Flywheel';

  @override
  String get catalogPartCategoryDriveShaftsHalfShafts =>
      'Drive shafts & half-shafts';

  @override
  String get catalogPartCategoryDifferential => 'Differential';

  @override
  String get catalogPartCategoryElectricalSystem => 'Electrical system';

  @override
  String get catalogPartCategoryBatteryAlternator => 'Battery & alternator';

  @override
  String get catalogPartCategory12VBattery => '12V battery';

  @override
  String get catalogPartCategoryAlternator => 'Alternator';

  @override
  String get catalogPartCategoryStarterMotor => 'Starter motor';

  @override
  String get catalogPartCategoryLighting => 'Lighting';

  @override
  String get catalogPartCategoryHeadlights => 'Headlights';

  @override
  String get catalogPartCategoryTailLights => 'Tail lights';

  @override
  String get catalogPartCategoryBulbs => 'Bulbs';

  @override
  String get catalogPartCategorySensors => 'Sensors';

  @override
  String get catalogPartCategoryOxygenSensor => 'Oxygen sensor';

  @override
  String get catalogPartCategoryABSSensor => 'ABS sensor';

  @override
  String get catalogPartCategoryPressureSensor => 'Pressure sensor';

  @override
  String get catalogPartCategoryBodywork => 'Bodywork';

  @override
  String get catalogPartCategoryGlass => 'Glass';

  @override
  String get catalogPartCategoryWindscreen => 'Windscreen';

  @override
  String get catalogPartCategorySideWindow => 'Side window';

  @override
  String get catalogPartCategoryRearWindow => 'Rear window';

  @override
  String get catalogPartCategoryMirrors => 'Mirrors';

  @override
  String get catalogPartCategoryBumpers => 'Bumpers';

  @override
  String get catalogPartCategoryBonnetDoors => 'Bonnet & doors';

  @override
  String get catalogPartCategorySeals => 'Seals';

  @override
  String get catalogPartCategoryAirConditioning => 'Air conditioning';

  @override
  String get catalogPartCategoryAirConditioningCompressor =>
      'Air conditioning compressor';

  @override
  String get catalogPartCategoryCondenser => 'Condenser';

  @override
  String get catalogPartCategoryExpansionValve => 'Expansion valve';

  @override
  String get catalogPartCategoryRefrigerant => 'Refrigerant';

  @override
  String get catalogPartCategoryTyresWheels => 'Tyres & wheels';

  @override
  String get catalogPartCategoryTyres => 'Tyres';

  @override
  String get catalogPartCategoryRims => 'Rims';

  @override
  String get catalogPartCategoryValvesAccessories => 'Valves & accessories';

  @override
  String get catalogPartCategoryExhaust => 'Exhaust';

  @override
  String get catalogPartCategorySilencer => 'Silencer';

  @override
  String get catalogPartCategoryExhaustManifold => 'Exhaust manifold';

  @override
  String get catalogPartCategoryCatalyticConverter => 'Catalytic converter';

  @override
  String get catalogPartCategoryDPF => 'DPF';

  @override
  String get catalogEquipmentManualAirConditioning => 'Manual air conditioning';

  @override
  String get catalogEquipmentAutomaticAirConditioning =>
      'Automatic air conditioning';

  @override
  String get catalogEquipmentVentilatedSeats => 'Ventilated seats';

  @override
  String get catalogEquipmentSunroof => 'Sunroof';

  @override
  String get catalogEquipmentPanoramicRoof => 'Panoramic roof';

  @override
  String get catalogEquipmentFrontElectricWindows => 'Front electric windows';

  @override
  String get catalogEquipmentRearElectricWindows => 'Rear electric windows';

  @override
  String get catalogEquipmentElectricMirrors => 'Electric mirrors';

  @override
  String get catalogEquipmentPowerFoldingMirrors => 'Power-folding mirrors';

  @override
  String get catalogEquipmentHeightAdjustableSteeringWheel =>
      'Height-adjustable steering wheel';

  @override
  String get catalogEquipmentElectricDriverSSeat => 'Electric driver\'s seat';

  @override
  String get catalogEquipmentKeylessEntryAndStart => 'Keyless entry and start';

  @override
  String get catalogEquipmentElectricPowerSteering => 'Electric power steering';

  @override
  String get catalogEquipmentABS => 'ABS';

  @override
  String get catalogEquipmentESPStabilityControl => 'ESP / stability control';

  @override
  String get catalogEquipmentEmergencyBrakeAssistBA =>
      'Emergency brake assist (BA)';

  @override
  String get catalogEquipmentFrontAirbags => 'Front airbags';

  @override
  String get catalogEquipmentSideAirbags => 'Side airbags';

  @override
  String get catalogEquipmentCurtainAirbags => 'Curtain airbags';

  @override
  String get catalogEquipmentTractionControlASR => 'Traction control (ASR)';

  @override
  String get catalogEquipmentHillStartAssist => 'Hill start assist';

  @override
  String get catalogEquipmentFrontDiscBrakes => 'Front disc brakes';

  @override
  String get catalogEquipmentFourWheelDiscBrakes => 'Four-wheel disc brakes';

  @override
  String get catalogEquipmentChildSeatAnchors => 'Child seat anchors';

  @override
  String get catalogEquipmentCarRadio => 'Car radio';

  @override
  String get catalogEquipmentTouchscreen => 'Touchscreen';

  @override
  String get catalogEquipmentBluetooth => 'Bluetooth';

  @override
  String get catalogEquipmentAndroidAuto => 'Android Auto';

  @override
  String get catalogEquipmentAppleCarPlay => 'Apple CarPlay';

  @override
  String get catalogEquipmentBuiltInGPS => 'Built-in GPS';

  @override
  String get catalogEquipmentUSBPort => 'USB port';

  @override
  String get catalogEquipmentPremiumSpeakers => 'Premium speakers';

  @override
  String get catalogEquipmentWirelessCharger => 'Wireless charger';

  @override
  String get catalogEquipmentWarningTriangle => 'Warning triangle';

  @override
  String get catalogEquipmentSpareWheel => 'Spare wheel';

  @override
  String get catalogEquipmentJack => 'Jack';

  @override
  String get catalogEquipmentWheelWrench => 'Wheel wrench';

  @override
  String get catalogEquipmentFirstAidKit => 'First aid kit';

  @override
  String get catalogEquipmentReflectiveVest => 'Reflective vest';

  @override
  String get catalogEquipmentJumpLeads => 'Jump leads';

  @override
  String get catalogEquipmentOwnerSManual => 'Owner\'s manual';

  @override
  String get catalogEquipmentServiceBook => 'Service book';

  @override
  String get catalogEquipmentReversingCamera => 'Reversing camera';

  @override
  String get catalogEquipment360Camera => '360° camera';

  @override
  String get catalogEquipmentRearParkingSensors => 'Rear parking sensors';

  @override
  String get catalogEquipmentFrontParkingSensors => 'Front parking sensors';

  @override
  String get catalogEquipmentCruiseControl => 'Cruise control';

  @override
  String get catalogEquipmentAdaptiveCruiseControlACC =>
      'Adaptive cruise control (ACC)';

  @override
  String get catalogEquipmentLaneDepartureWarning => 'Lane departure warning';

  @override
  String get catalogEquipmentBlindSpotMonitor => 'Blind spot monitor';

  @override
  String get catalogEquipmentAutomaticEmergencyBraking =>
      'Automatic emergency braking';

  @override
  String get catalogEquipmentHeadUpDisplayHUD => 'Head-up display (HUD)';

  @override
  String get catalogEquipmentTrafficSignRecognition =>
      'Traffic sign recognition';

  @override
  String garageConsumptionRange(String min, String max) {
    return '$min–$max L/100 km';
  }

  @override
  String get garageConsumptionSourceCanada => 'Natural Resources Canada';

  @override
  String get garageConsumptionSourceEurope => 'European Environment Agency';

  @override
  String get garageConsumptionCycleCanadianFive =>
      'Canadian five-cycle equivalent protocol';

  @override
  String get garageConsumptionCycleCanadianTwo => 'Canadian two-cycle test';

  @override
  String get garageConsumptionCycleWltp => 'WLTP standard';

  @override
  String get garageConsumptionCycleNedc => 'Former NEDC standard';

  @override
  String get garageEngineAutomatic => 'automatic';

  @override
  String get garageEngineManual => 'manual';

  @override
  String get garageEngineAutomatedManual => 'automated manual';

  @override
  String get garageEngineCvt => 'CVT';

  @override
  String garageEngineTransmissionGears(String transmission, int gears) {
    return '$gears-speed $transmission';
  }

  @override
  String get garageConsumptionFuelRegularPetrol => 'Regular petrol';

  @override
  String get garageConsumptionFuelPremiumPetrol => 'Premium petrol';

  @override
  String get garageConsumptionFuelEthanol => 'Ethanol (E85)';

  @override
  String get garageConsumptionFuelNaturalGas => 'Natural gas';

  @override
  String get garageConsumptionFuelLpg => 'LPG';

  @override
  String get garageConsumptionFuelPlugInHybrid => 'Plug-in hybrid';

  @override
  String get garageMyVehicle => 'my vehicle';

  @override
  String get vehiclesReferenceSelect => 'Select…';

  @override
  String get vehiclesReferenceChoosePrevious =>
      'Choose the previous value first';

  @override
  String get catalogEquipmentLeatherSeats => 'Leather seats';

  @override
  String get garageConsumptionCorresponding => 'Reference for this version';

  @override
  String get garageConsumptionApproximate => 'Approximate reference';

  @override
  String get garageConsumptionIncomplete => 'Version needs clarification';

  @override
  String get garageConsumptionLegacy => 'Legacy reference to review';

  @override
  String get garageConsumptionWithdrawn => 'Withdrawn reference';

  @override
  String get garageConsumptionUnavailable =>
      'Reference consumption unavailable';

  @override
  String get garageConsumptionDetails => 'Details and source';

  @override
  String get garageConsumptionChoose => 'Clarify the version';

  @override
  String get garageConsumptionChange => 'Change reference';

  @override
  String get garageConsumptionSelectionNotice =>
      'Selecting a reference does not verify the vehicle against documentation.';

  @override
  String get garageConsumptionNotVerified => 'Documentary match not verified';

  @override
  String get garageConsumptionMarketUnknown =>
      'Original specification market unknown';

  @override
  String get garageConsumptionYearMissing => 'Reference year unknown';

  @override
  String get garageConsumptionSourceUnknown => 'Source not provided';

  @override
  String get garageConsumptionCycleUnknown => 'Protocol not provided';

  @override
  String get garageConsumptionMethodTest => 'Method: test';

  @override
  String get garageConsumptionMethodAdjustment => 'Method: adjustment';

  @override
  String get garageConsumptionMethodAggregation =>
      'Method: registration aggregation';

  @override
  String get garageConsumptionMethodTranscription =>
      'Method: document transcription';

  @override
  String get garageConsumptionMethodUnknown => 'Method not established';

  @override
  String get garageConsumptionLimitedSample =>
      'Result from a limited sample; it does not describe a specific vehicle.';

  @override
  String get garageConsumptionMissingDetails =>
      'Missing information remains unknown. The model alone does not establish an exact match.';

  @override
  String get garageConsumptionChooseInstruction =>
      'Compare the year, market, engine and transmission. References may describe different variants or protocols.';

  @override
  String get garageConsumptionNoCandidates =>
      'No consumption reference available for this model.';

  @override
  String get garageConsumptionCandidatesUnavailable =>
      'Reference list unavailable. Try again later.';

  @override
  String get garageConsumptionMissingModel =>
      'Consumption unavailable: this vehicle model is not in the catalogue yet.';

  @override
  String get garageConsumptionSaved =>
      'Reference selected. Check its matching level.';

  @override
  String get garageConsumptionSourceTarget => 'the source document';

  @override
  String get garageConsumptionOpenSource => 'Open source document';

  @override
  String get garageConsumptionReasonYear =>
      'The reference model year differs from the provided year.';

  @override
  String get garageConsumptionReasonMarket =>
      'The specification market is not confirmed.';

  @override
  String get garageConsumptionReasonAggregation =>
      'An aggregate is not an exact rating for this vehicle.';

  @override
  String get garageConsumptionReasonLegacy =>
      'This legacy reference still needs review.';

  @override
  String get garageConsumptionReasonIncomplete =>
      'Some characteristics needed for matching remain unknown.';

  @override
  String get garageConsumptionReasonContradiction =>
      'The reference conflicts with the provided characteristics.';

  @override
  String get garageConsumptionReasonUnverified =>
      'The selected version has not been checked against a document.';

  @override
  String garageConsumptionSourceValue(String value) {
    return 'Source value: $value L/100 km';
  }

  @override
  String garageConsumptionVehicleYear(int year) {
    return 'Provided year: $year';
  }

  @override
  String garageConsumptionModelYear(int year) {
    return 'Reference model year: $year';
  }

  @override
  String garageConsumptionRegistrationYear(int year) {
    return 'Registration year: $year';
  }

  @override
  String garageConsumptionUnknownYear(int year) {
    return 'Reference year: $year (type not established)';
  }

  @override
  String garageConsumptionMarket(String market) {
    return 'Reference specification market: $market';
  }

  @override
  String garageConsumptionSource(String source) {
    return 'Source: $source';
  }

  @override
  String garageConsumptionProtocol(String cycle) {
    return 'Protocol: $cycle';
  }

  @override
  String garageConsumptionVerified(String date) {
    return 'Documentary verification: $date';
  }

  @override
  String garageConsumptionImported(String date) {
    return 'Imported: $date';
  }

  @override
  String garageConsumptionPublished(String date) {
    return 'Published: $date';
  }

  @override
  String garageConsumptionRevision(String revision) {
    return 'Revision: $revision';
  }

  @override
  String garageConsumptionResource(String resource) {
    return 'Resource: $resource';
  }

  @override
  String garageConsumptionHash(String hash) {
    return 'SHA-256 checksum: $hash';
  }

  @override
  String garageConsumptionRecords(String count) {
    return 'Records: $count';
  }

  @override
  String garageConsumptionVersionTitle(String model) {
    return 'References for your $model';
  }

  @override
  String get garageConsumptionReasonRevision =>
      'A newer revision is available; this selection keeps its original reference.';

  @override
  String garageConsumptionSourceRecord(String record) {
    return 'Source row/record: $record';
  }

  @override
  String garageConsumptionOriginalUnit(String unit) {
    return 'Original unit: $unit';
  }

  @override
  String garageConsumptionLicense(String license) {
    return 'Licence stated by the resource: $license';
  }

  @override
  String get catalogDeclaredConsumption => 'Consumption declared by the seller';

  @override
  String get catalogConsumptionReferences => 'Compare consumption references';

  @override
  String get catalogConsumptionComparisonNotice =>
      'These references describe distinct versions and protocols. None is attributed to this listing.';

  @override
  String garageConsumptionRetrieved(String date) {
    return 'Retrieved: $date';
  }

  @override
  String garageConsumptionSourceCity(String value) {
    return 'Source city value: $value L/100 km';
  }

  @override
  String garageConsumptionSourceHighway(String value) {
    return 'Source highway value: $value L/100 km';
  }

  @override
  String get garageConsumptionFuelHybridUnspecified =>
      'Hybrid (type unspecified)';

  @override
  String garageMeasuredConsumptionValue(String value) {
    return '$value L/100 km';
  }

  @override
  String get privateSalesSubmitPhotosRequired => 'Add at least one photo.';

  @override
  String get privateSalesSubmitConsentRequired => 'Tick both boxes above.';

  @override
  String get privateSalesRejectReasonMinimumHint => 'At least 5 characters.';

  @override
  String get privateSalesRejectReasonTooShort =>
      'Use at least 5 characters so the seller knows what to correct.';

  @override
  String get settingsContactTitle => 'AutoParc contact';

  @override
  String get settingsContactSaved => 'AutoParc contact number saved.';

  @override
  String get settingsContactAccessDenied =>
      'Only administrators and managers can access this page.';

  @override
  String get settingsContactPhoneTitle => 'Phone number to contact AutoParc';

  @override
  String get settingsContactPhoneDescription =>
      'The app uses this number for calls and WhatsApp.';

  @override
  String get settingsContactPhoneLabel => 'Phone number with country code';

  @override
  String get settingsContactCountryCodeHelp =>
      'Include + and the country code.';

  @override
  String get settingsContactPhoneInvalid =>
      'Enter a valid international number, for example +226 75 57 04 84.';

  @override
  String get settingsContactSave => 'Save phone number';

  @override
  String get settingsContactSaving => 'Saving…';

  @override
  String get shellContactSettings => 'Settings · AutoParc contact';

  @override
  String get inspectionBadgeLabel => 'Inspected by AutoParc';

  @override
  String get inspectionAttentionLabel => 'Points needing attention';

  @override
  String get inspectionBlockingLabel => 'Blocking issues reported';

  @override
  String get inspectionReportTitle => 'Inspection report';

  @override
  String get inspectionScopeNote =>
      'Findings at the recorded date and mileage, limited to the points listed below.';

  @override
  String get inspectionDateLabel => 'Inspection date';

  @override
  String get inspectionMileageLabel => 'Recorded mileage';

  @override
  String get inspectionValidUntilLabel => 'Valid until';

  @override
  String inspectionCheckedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points checked',
      one: '1 point checked',
    );
    return '$_temp0';
  }

  @override
  String get inspectionSummaryLabel => 'Summary';

  @override
  String get inspectionStatusOk => 'Checked: no issue found';

  @override
  String get inspectionStatusAttention => 'Needs attention';

  @override
  String get inspectionStatusBlocking => 'Blocking issue';

  @override
  String get inspectionStatusNotChecked => 'Not checked';

  @override
  String get inspectionReportUnavailable =>
      'This report is no longer available. Refresh the vehicle details.';

  @override
  String get inspectionClose => 'Close';

  @override
  String get inspectionAdd => 'Record an inspection';

  @override
  String get inspectionReplace => 'Record a new inspection';

  @override
  String get inspectionWithdraw => 'Withdraw inspection';

  @override
  String get inspectionHistory => 'Inspection history';

  @override
  String get inspectionHistoryActive => 'Current inspection';

  @override
  String get inspectionHistoryWithdrawn => 'Withdrawn';

  @override
  String get inspectionHistorySuperseded => 'Replaced';

  @override
  String get inspectionHistoryExpired => 'Expired';

  @override
  String get inspectionHistoryInactive => 'Inactive inspection';

  @override
  String get inspectionMore => 'Load earlier inspections';

  @override
  String get inspectionFormTitle => 'AutoParc inspection';

  @override
  String get inspectionFormIntro =>
      'Complete after physically inspecting the vehicle. Select only the points actually checked and record any issues found.';

  @override
  String get inspectionDateFuture =>
      'The inspection date cannot be in the future.';

  @override
  String get inspectionMileageRequired =>
      'Enter the recorded mileage in kilometres.';

  @override
  String get inspectionSummaryRequired => 'Enter the inspection summary.';

  @override
  String get inspectionPointLabel => 'Inspection point';

  @override
  String get inspectionPointHint => 'E.g. brakes, engine, bodywork';

  @override
  String get inspectionPointNote => 'Observation (optional)';

  @override
  String get inspectionPointStatus => 'Inspection finding';

  @override
  String get inspectionPointRequired => 'Name the inspection point.';

  @override
  String get inspectionAddPoint => 'Add an inspection point';

  @override
  String get inspectionRemovePoint => 'Remove this point';

  @override
  String get inspectionAtLeastOneChecked =>
      'Check at least one point before saving the inspection.';

  @override
  String get inspectionConfirmation =>
      'I confirm that AutoParc physically inspected this vehicle and that this report describes the points checked.';

  @override
  String get inspectionConfirmationRequired =>
      'Confirm that the vehicle was physically inspected.';

  @override
  String get inspectionSave => 'Save inspection';

  @override
  String get inspectionSaved => 'Inspection saved.';

  @override
  String get inspectionValidityOptional => 'Specify an expiry date (optional)';

  @override
  String get inspectionValidityDateError =>
      'Choose an expiry date after the inspection.';

  @override
  String get inspectionChooseDate => 'Choose a date';

  @override
  String get inspectionWithdrawTitle => 'Withdraw this inspection?';

  @override
  String get inspectionWithdrawReason => 'Reason for withdrawal';

  @override
  String get inspectionWithdrawReasonRequired =>
      'Enter a reason for withdrawal.';

  @override
  String get inspectionWithdrawConfirm => 'Withdraw';

  @override
  String get inspectionWithdrawn => 'Inspection withdrawn.';

  @override
  String get faultDeclarationTitle => 'Declared condition';

  @override
  String get faultDeclarationUnknown => 'Not provided';

  @override
  String get faultDeclarationNoneSeller => 'No faults declared by the seller';

  @override
  String get faultDeclarationHasFaults => 'Faults declared';

  @override
  String get faultDeclarationSellerNote =>
      'Information declared by the seller. This is not an AutoParc inspection.';

  @override
  String faultDeclarationDate(String date) {
    return 'Declared on $date';
  }

  @override
  String faultDeclarationUnresolvedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count declared unrepaired faults',
      one: '1 declared unrepaired fault',
      zero: 'No declared unrepaired faults',
    );
    return '$_temp0';
  }

  @override
  String get faultDeclarationUnrepaired => 'Unrepaired';

  @override
  String get faultDeclarationDetailsUnavailable =>
      'Faults have been declared. Contact AutoParc for details.';

  @override
  String get faultDeclarationPrivateSubmitRequired =>
      'Declare the vehicle’s condition: no faults or a list of faults.';

  @override
  String get faultDeclarationListRequired =>
      'Add at least one fault or explicitly choose another condition.';

  @override
  String get faultDeclarationInvalidFault =>
      'Check the declared faults before saving.';

  @override
  String get faultDeclarationFilterNoUnrepaired =>
      'No declared unrepaired faults';

  @override
  String get faultDeclarationChoiceHint =>
      'Explicitly choose the declared condition. An empty list does not declare the absence of faults.';

  @override
  String get faultDeclarationAdd => 'Add a fault';

  @override
  String get faultDeclarationEdit => 'Edit fault';

  @override
  String get faultDeclarationStatusLabel => 'Declared status';

  @override
  String get faultDeclarationClearTitle => 'Clear the entered faults?';

  @override
  String get faultDeclarationClearMessage =>
      'Choosing “No faults declared” will remove the entered faults from this declaration.';

  @override
  String get faultDeclarationClearConfirm => 'Clear and continue';

  @override
  String get faultDeclarationReadOnlyNotice =>
      'This fault is managed by AutoParc. Only staff can change it.';

  @override
  String get faultDeclarationReadOnlyBlocksNone =>
      'Faults managed by AutoParc are still present. You cannot clear this list.';

  @override
  String get faultDeclarationKeepFaultsBeforeUnknown =>
      'Remove editable faults before choosing “Not provided”. Faults managed by AutoParc are retained.';

  @override
  String get faultDeclarationChangedElsewhere =>
      'The declaration changed while you were editing. Review it before trying again.';

  @override
  String get faultDeclarationFaultLimit =>
      'A declaration can contain up to 100 faults.';

  @override
  String get faultDeclarationTitleTooLong =>
      'The title must not exceed 180 characters.';

  @override
  String get faultDeclarationDescriptionTooLong =>
      'The description must not exceed 5,000 characters.';

  @override
  String get faultDeclarationApply => 'Apply';

  @override
  String vehiclesSavedTransmissionType(String type) {
    return 'Saved gearbox: $type';
  }

  @override
  String get catalogTransmissionAutomatedManual => 'Automated manual (AMT)';

  @override
  String get catalogTransmissionECvt => 'Hybrid e-CVT';

  @override
  String get catalogValidatedByAutoParc => 'Validated by AutoParc';
}
