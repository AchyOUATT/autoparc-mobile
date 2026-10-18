import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de la destination d'accueil. UNE SEULE CLÉ pour l'onglet de la barre du bas, la tuile « Parcourir » de l'accueil et le titre de la page : le code demande déjà que les trois coïncident (« deux rangements différents pour les mêmes destinations obligeraient à relire à chaque fois »), et une clé partagée rend la divergence impossible.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get commonHome;

  /// Nom de la destination du catalogue de véhicules : onglet, tuile de l'accueil et titre de la page. Voir commonHome.
  ///
  /// In fr, this message translates to:
  /// **'Véhicules'**
  String get commonVehicles;

  /// Nom de la destination des accessoires : onglet, tuile de l'accueil et titre de la page. C'est le plus large des quatre intitulés de la barre du bas — il réclame 87,7 points à 320 points d'écran et à l'échelle 1,3 pour 80,0 reçus, et c'est lui qui a imposé la borne d'échelle de BarreNavigationPrincipale. Toute traduction plus longue rouvre ce défaut : bandes_filtres_test.dart le mesure dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'Accessoires'**
  String get commonAccessories;

  /// Nom COURT de la destination des pièces, pour l'onglet et la tuile de l'accueil. Le titre de la page est plus long et porte sa propre clé, catalogPartListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pièces'**
  String get commonParts;

  /// Mention qui suit le nom de l article dans un message partage : « Mazda CX-9 (2018) — sur AutoParc ». Elle est tout ce qui reste du texte depuis que la page publique porte le prix et les caracteristiques dans sa vignette ; elle sert quand l apercu echoue, pour que le destinataire sache d ou vient le lien au lieu de lire une adresse nue.
  ///
  /// In fr, this message translates to:
  /// **'sur AutoParc'**
  String get partageMentionBoutique;

  /// Bouton qui ferme une boîte de dialogue sans rien appliquer. 15 fichiers de lib/ l'écrivent aujourd'hui en dur : la clé est commune parce que le seuil de trois sites dans deux zones est franchi, pas par anticipation.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// Bouton qui relance une requête échouée. 15 fichiers de lib/ l'écrivent en dur.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// Infobulle du bouton qui ouvre le tiroir latéral, présent dans les quatre barres de titre principales. Identique en anglais, et la clé existe quand même : une chaîne affichée laissée en dur est une chaîne que personne ne retrouvera au lot suivant.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get commonMenuTooltip;

  /// Suffixe collé à un tarif de location journalier : « 25 000 FCFA/j ». Aucune espace avant, et c'est voulu : le suffixe doit rester dans le même segment insécable que le montant, sinon il part seul à la ligne.
  ///
  /// In fr, this message translates to:
  /// **'/j'**
  String get commonPerDaySuffix;

  /// Un kilométrage et son unité. L'UNITÉ RESTE MÉTRIQUE dans les deux langues : les clients visés comptent en kilomètres et en litres, et convertir en milles ferait mentir une valeur relevée au compteur.
  ///
  /// In fr, this message translates to:
  /// **'{value} km'**
  String commonMileageKm(String value);

  /// Repli quand aucune application du téléphone ne sait ouvrir un lien. Le repli copie la valeur plutôt que de s'excuser : une impasse devient une gêne.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir {what} sur cet appareil. {value} a été copié.'**
  String commonLinkUnavailable(String what, String value);

  /// Titre de la demande de confirmation déclenchée par le Retour d'Android depuis l'un des quatre onglets.
  ///
  /// In fr, this message translates to:
  /// **'Quitter AutoParc ?'**
  String get shellExitTitle;

  /// Corps de la demande de confirmation de sortie.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous fermer l\'application ?'**
  String get shellExitBody;

  /// Bouton qui ferme réellement l'application.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get shellExitConfirm;

  /// Nom affiché dans l'en-tête du tiroir pour un utilisateur sans compte.
  ///
  /// In fr, this message translates to:
  /// **'Visiteur'**
  String get shellAccountGuest;

  /// Sous-titre de l'en-tête du tiroir pour un membre du personnel. Le rôle vient du serveur et n'est PAS traduit par ce lot.
  ///
  /// In fr, this message translates to:
  /// **'Personnel — {role}'**
  String shellAccountStaff(String role);

  /// Sous-titre de l'en-tête du tiroir quand personne n'est connecté.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get shellAccountNotSignedIn;

  /// Entrée du tiroir (personnel) vers la liste des demandes déposées par les clients.
  ///
  /// In fr, this message translates to:
  /// **'Besoins clients'**
  String get shellClientNeeds;

  /// Entrée du tiroir (personnel) vers les garages et fournisseurs partenaires.
  ///
  /// In fr, this message translates to:
  /// **'Partenaires'**
  String get shellPartners;

  /// Entrée du tiroir vers les notifications reçues.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get shellNotifications;

  /// Entrée du tiroir (personnel) qui vide le cache local du catalogue.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir le catalogue'**
  String get shellRefreshCatalog;

  /// Confirmation affichée après le vidage du cache du catalogue.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue mis à jour'**
  String get shellCatalogRefreshed;

  /// Entrée du tiroir (client) vers ses propres véhicules et leurs échéances.
  ///
  /// In fr, this message translates to:
  /// **'Mon Garage'**
  String get shellMyGarage;

  /// Entrée du tiroir (client) vers les demandes qu'il a lui-même déposées.
  ///
  /// In fr, this message translates to:
  /// **'Mes besoins'**
  String get shellMyNeeds;

  /// Entrée du tiroir, et titre de la feuille de contact qu'elle ouvre.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get shellContact;

  /// Entrée du tiroir pour un visiteur sans compte.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get shellSignIn;

  /// Entrée du tiroir qui termine la session. Deux sites d'appel seulement — ici et le profil du garage —, donc la clé reste préfixée par sa zone tant que le seuil de trois n'est pas franchi.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get shellSignOut;

  /// Confirmation affichée après la déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes déconnecté.'**
  String get shellSignedOut;

  /// Libellé de la ligne « appeler » de la feuille de contact.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get shellContactPhone;

  /// Libellé de la ligne « écrire » de la feuille de contact.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get shellContactEmail;

  /// Désigne le composeur téléphonique DANS la phrase commonLinkUnavailable : « Impossible d'ouvrir le composeur sur cet appareil. » D'où l'article et la minuscule — ce fragment ne s'affiche jamais seul.
  ///
  /// In fr, this message translates to:
  /// **'le composeur'**
  String get shellContactDialerTarget;

  /// Désigne le client courriel DANS la phrase commonLinkUnavailable. Voir shellContactDialerTarget.
  ///
  /// In fr, this message translates to:
  /// **'la messagerie'**
  String get shellContactMailTarget;

  /// Entrée du tiroir qui ouvre le choix de langue, et titre de la boîte de dialogue correspondante. Les deux noms de langue proposés — « Français », « English » — ne sont PAS dans ce fichier : chacun s'écrit dans sa propre langue, pour qu'un anglophone tombe sur « English » même quand l'interface est encore en français.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get shellLanguage;

  /// Bouton de l'écran bloquant de mise à jour obligatoire ; il ouvre la fiche de l'application dans le magasin. Le message affiché au-dessus vient du serveur et reste en français jusqu'à la vague serveur.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateAction;

  /// Désigne le magasin d'applications DANS la phrase commonLinkUnavailable. Voir shellContactDialerTarget.
  ///
  /// In fr, this message translates to:
  /// **'la fiche de l\'application'**
  String get updateStoreTarget;

  /// Titre de la page du catalogue de pièces. Plus long que l'intitulé de l'onglet (commonParts), et c'était déjà le cas en français : une barre de titre a de la place, une barre de navigation n'en a pas.
  ///
  /// In fr, this message translates to:
  /// **'Pièces détachées'**
  String get catalogPartListTitle;

  /// Ce qui joint deux noms de modèle sur la ligne de compatibilité d'une carte du catalogue : « Corolla · Tucson ». Les NOMS viennent du référentiel du serveur, qui n'envoie que le modèle sans la marque, et ne sont pas traduits ; ce séparateur, lui, nous appartient. Identique en anglais aujourd'hui, et la clé existe quand même — une ponctuation laissée en dur est une ponctuation que personne ne retrouvera le jour où une langue en voudra une autre, et c'est précisément ce qui est arrivé à l'espace des milliers du kilométrage de l'accueil. Les espaces font partie de la valeur : le point médian collé aux noms se lit comme une faute.
  ///
  /// In fr, this message translates to:
  /// **' · '**
  String get catalogCompatibilitySeparator;

  /// Le nombre de modèles compatibles que la carte n'affiche PAS : « +9 ». Il est rendu dans un élément SÉPARÉ de la liste de noms, jamais collé au bout du texte tronqué — la troncature mangerait le compte en premier, donc précisément quand il est le plus utile. Le compte est calculé sur les noms réellement PEINTS et non sur ceux que le serveur envoie : la carte n'en affiche souvent que deux des trois reçus aux grandes échelles de texte, et « +9 » devrait alors dire « +10 ».
  ///
  /// In fr, this message translates to:
  /// **'+{count}'**
  String catalogCompatibilityMore(int count);

  /// Titre de la bande horizontale des véhicules en promotion sur l'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Bonnes affaires'**
  String get homeDealsSection;

  /// Lien au bout d'un titre de section, vers la liste complète.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get homeSeeAll;

  /// Titre de la bande des pièces compatibles avec le véhicule mis en avant. Le modèle vient du référentiel du serveur et n'est pas traduit.
  ///
  /// In fr, this message translates to:
  /// **'Pièces pour {model}'**
  String homeCompatiblePartsSection(String model);

  /// Remplace le modèle dans homeCompatiblePartsSection quand le serveur ne l'a pas renseigné.
  ///
  /// In fr, this message translates to:
  /// **'votre véhicule'**
  String get homeCompatiblePartsFallbackModel;

  /// Bouton de la carte du véhicule. C'est le geste qui fait vivre le rappel de vidange : sans compteur tenu à jour, il ne part jamais.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le kilométrage'**
  String get homeUpdateMileage;

  /// Remplace le bloc d'échéance quand le véhicule n'en porte aucune : on demande les dates plutôt que d'afficher un vide.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez vos échéances pour être prévenu à temps'**
  String get homeNoDeadlinePrompt;

  /// Titre de la carte d'échec du chargement du garage. Distinct de l'invitation à enregistrer un véhicule : dire « enregistrez votre véhicule » à quelqu'un qui en a trois est pire que ne rien dire.
  ///
  /// In fr, this message translates to:
  /// **'Votre garage n\'a pas pu être chargé'**
  String get homeGarageUnavailable;

  /// Titre de la carte d'invitation affichée quand le garage est vide.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez votre véhicule'**
  String get homeAddVehicleTitle;

  /// Corps de la carte d'invitation : les trois rappels que l'enregistrement débloque.
  ///
  /// In fr, this message translates to:
  /// **'Visite technique, assurance, vidange : nous vous prévenons avant l\'échéance.'**
  String get homeAddVehicleBody;

  /// Bouton de la carte d'invitation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ma voiture'**
  String get homeAddVehicleCta;

  /// Lien en bas de l'accueil vers le dépôt d'un besoin. Masqué pour le personnel, qui traite les besoins au lieu de les soumettre.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne trouvez pas ? Dites-nous ce que vous cherchez'**
  String get homeNeedPrompt;

  /// Échéance dont le serveur fournit un détail chiffré : « Vidange — dépassée de 300 km ». LE LIBELLÉ ET LE DÉTAIL VIENNENT DU SERVEUR et restent en français jusqu'à la vague serveur ; cette clé ne porte que le tiret qui les joint.
  ///
  /// In fr, this message translates to:
  /// **'{label} — {detail}'**
  String homeDeadlineDetail(String label, String detail);

  /// Échéance déjà passée. L'accord féminin de « dépassée » suit les libellés du serveur, qui sont tous féminins : visite technique, assurance, vidange.
  ///
  /// In fr, this message translates to:
  /// **'{label} dépassée depuis {days, plural, one{{days} jour} other{{days} jours}}'**
  String homeDeadlineOverdue(String label, int days);

  /// Échéance du jour. L'APOSTROPHE S'ÉCRIT SIMPLE, et c'est une vérification et non une supposition : `use-escaping` vaut faux par défaut, donc `gen-l10n` ne déséchappe rien. Écrite doublée comme le veut ICU, elle ressortait littéralement — le fichier généré contenait « expire aujourd''hui ». Lu dans lib/l10n/app_localizations_fr.dart, et verrouillé par le banc de langue, qui compare la chaîne RENDUE.
  ///
  /// In fr, this message translates to:
  /// **'{label} expire aujourd\'hui'**
  String homeDeadlineToday(String label);

  /// Échéance du lendemain.
  ///
  /// In fr, this message translates to:
  /// **'{label} expire demain'**
  String homeDeadlineTomorrow(String label);

  /// Échéance à venir.
  ///
  /// In fr, this message translates to:
  /// **'{label} dans {days, plural, one{{days} jour} other{{days} jours}}'**
  String homeDeadlineInDays(String label, int days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
