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

  /// Suffixe d'un forfait mensuel de location, sans conversion en tarif journalier.
  ///
  /// In fr, this message translates to:
  /// **'/mois'**
  String get commonPerMonthSuffix;

  /// Un kilométrage et son unité. L'UNITÉ RESTE MÉTRIQUE dans les deux langues : les clients visés comptent en kilomètres et en litres, et convertir en milles ferait mentir une valeur relevée au compteur.
  ///
  /// In fr, this message translates to:
  /// **'{value} km'**
  String commonMileageKm(String value);

  /// Repli de `partagerArticle` quand la feuille de partage d'Android refuse de s'ouvrir. UN SEUL site d'écriture — `_signalerEchec` dans core/utils/partage.dart — donc sous la règle des trois sites, `common` est une entorse ASSUMÉE : c'est la même famille de repli que commonLinkUnavailable, dans le même fichier voisin, servant les trois fiches clientes. Les séparer rendrait deux clés jumelles dont l'une serait traduite et l'autre non, ce qui est précisément le défaut que ce lot corrige.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le partage sur cet appareil. Le message a été copié.'**
  String get commonShareUnavailable;

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

  /// Sous-titre de l'en-tête du tiroir pendant qu'une session restaurée du coffre n'est pas encore confirmée par le serveur. Il REMPLACE la ligne du rôle, parce que l'en-tête a une hauteur fixe et débordait avec deux lignes — et parce que le rôle lu au coffre est une hypothèse tant que rien ne l'a confirmé. Explique pourquoi certaines commandes peuvent manquer l'espace d'un instant ; disparaît dès la confirmation.
  ///
  /// In fr, this message translates to:
  /// **'Session à confirmer…'**
  String get shellSessionToConfirm;

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

  /// Infobulle du bouton de la barre de titre qui ouvre le dépôt d'un besoin, sur les trois listes du catalogue. Masqué pour le personnel, qui traite les besoins au lieu d'en déposer. Trois sites d'appel mais une seule zone : la clé reste préfixée `catalog` tant que le seuil de deux zones de CONVENTION.md n'est pas franchi.
  ///
  /// In fr, this message translates to:
  /// **'Exprimer un besoin'**
  String get catalogNeedTooltip;

  /// Lien au bas de l'écran vide des trois listes, vers le dépôt d'un besoin. Même geste que homeNeedPrompt, et même fin de phrase en anglais, mais pas la même chaîne : l'accueil l'introduit par une question (« Vous ne trouvez pas ? ») que l'écran vide n'a pas à poser — « Aucun véhicule trouvé » vient d'être écrit juste au-dessus.
  ///
  /// In fr, this message translates to:
  /// **'Dites-nous ce que vous cherchez'**
  String get catalogNeedCta;

  /// Bouton de l'écran vide qui remet les filtres à zéro. Trois sites d'appel, tous dans catalog.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get catalogClearFilters;

  /// Mention posée UNE FOIS en tête de la liste des véhicules, à droite du compte de résultats, et non sur chaque carte — demande du propriétaire : « n'affiche pas TTC sur les widgets de présentation, floque l'info en même alignement que résultats trouvés, juste en bas de carrosserie, peut excentré à droite ». Répétée sur chaque carte elle aurait coûté de la place sur une carte qu'on a passé du temps à désencombrer, et dit douze fois ce qui se dit une. Volontairement courte : elle partage sa ligne avec le compte, qui grandit avec le nombre de résultats.
  ///
  /// In fr, this message translates to:
  /// **'Prix TTC'**
  String get catalogPricesIncludeVat;

  /// Le compte de résultats, en tête des trois listes. PASSE PAR UN PLURIEL ICU, et c'était la seule façon de ne pas casser l'anglais : le code écrivait `'$total résultat${total > 1 ? "s" : ""}'`, donc une règle de pluriel française codée en dur — zéro au singulier. L'anglais met zéro au pluriel (« 0 results »), et la forme `one` d'ICU rend exactement cette différence sans que le site d'appel la connaisse. Le français ne bouge pas : la règle ICU `one` du français couvre 0 et 1, comme le faisait `total > 1`.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} résultat} other{{count} résultats}}'**
  String catalogResultCount(int count);

  /// Le pied des trois listes, une fois la dernière page chargée. Les deux cadratins font partie de la valeur : ils encadrent la ligne et une langue peut en vouloir d'autres. Même règle de pluriel que catalogResultCount.
  ///
  /// In fr, this message translates to:
  /// **'— {count, plural, one{{count} résultat} other{{count} résultats}} au total —'**
  String catalogResultTotal(int count);

  /// La phrase de l'écran vide qui NOMME les filtres posés. La barre en compte une douzaine, dont plusieurs restent actifs hors du champ une fois la liste défilée ; « Aucun véhicule trouvé » obligeait à remonter les décocher un par un. L'ESPACE DEVANT LES DEUX-POINTS EST UNE ESPACE ORDINAIRE (U+0020), relevée telle quelle dans les trois pages : ce lot reporte la typographie existante et ne la corrige pas en passant. Les termes sont joints par catalogFilterListSeparator.
  ///
  /// In fr, this message translates to:
  /// **'Filtres actifs : {terms}.'**
  String catalogActiveFilters(String terms);

  /// Ce qui joint deux termes dans catalogActiveFilters. Identique en anglais aujourd'hui, et la clé existe quand même — pour la raison déjà écrite sur catalogCompatibilitySeparator : une ponctuation laissée en dur est une ponctuation que personne ne retrouvera le jour où une langue en voudra une autre. L'espace fait partie de la valeur.
  ///
  /// In fr, this message translates to:
  /// **', '**
  String get catalogFilterListSeparator;

  /// Le texte cherché, cité dans catalogActiveFilters. LES GUILLEMETS CHANGENT AVEC LA LANGUE — « » en français, “ ” en anglais —, et c'est précisément ce qu'une chaîne en dur empêchait. Les espaces intérieures sont reportées telles qu'elles existent : des espaces ORDINAIRES dans les trois pages, et non des espaces fines insécables.
  ///
  /// In fr, this message translates to:
  /// **'« {query} »'**
  String catalogFilterTermQuery(String query);

  /// Bouton flottant de la liste des véhicules, visible pour le seul personnel habilité à créer une fiche. Court là où les deux autres listes sont explicites (catalogPartAddCta, catalogAccessoryAddCta), et c'était déjà le cas en français.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get catalogVehicleAddCta;

  /// Invite de la barre de recherche des véhicules. Les points de suspension sont UN SEUL signe (U+2026) et non trois points, et ils disent que la liste citée n'est pas close — le serveur interroge aussi la référence, que l'invite ne nomme plus. RACCOURCIE SOUS LA MESURE : « Marque, modèle, référence… » réclamait 272,0 points pour 240,0 reçus à 320 points d'écran dès l'échelle 1,3 et 311,9 à 1,5, et il n'en restait peint que « Marque, modè ». LE DÉFAUT ÉTAIT FRANÇAIS D'ABORD, et c'est l'inverse de ce qu'on en avait conclu : à 320 × 1,3 la longueur anglaise équivalente (239,7) TENAIT dans 240,0, et c'est le français (272,0) qui débordait ; l'anglais ne tombait qu'à 1,5 (274,8). Cette invite-ci est justement celle qu'on avait citée pour soutenir que la traduction n'aggravait rien — vrai, mais elle ne masquait pas un défaut anglais, elle en révélait un français que la barre de recherche, laissée hors de la matrice du banc, cachait depuis toujours. Ce lot l'y a fait entrer.
  ///
  /// In fr, this message translates to:
  /// **'Marque, modèle…'**
  String get catalogVehicleSearchHint;

  /// Intitulé du premier groupe de la bande de filtres des véhicules : vente, location, bonne affaire, dédouané.
  ///
  /// In fr, this message translates to:
  /// **'Offre'**
  String get catalogFilterGroupOffer;

  /// Intitulé du groupe utilitaire / poids lourd de la bande de filtres des véhicules. Identique en anglais.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get catalogFilterGroupType;

  /// Intitulé du groupe des villes de la bande de filtres des véhicules. Les NOMS de ville viennent du référentiel du serveur et ne sont pas traduits.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get catalogFilterGroupCity;

  /// Intitulé de la seconde bande de filtres des véhicules, celle des onze carrosseries.
  ///
  /// In fr, this message translates to:
  /// **'Carrosserie'**
  String get catalogFilterGroupBodyStyle;

  /// Puce de filtre « vente » et badge de la carte d'un véhicule proposé à la vente seule. DEUX SITES D'APPEL POUR UNE SEULE CLÉ, et c'est voulu : la puce choisit ce que le badge affiche, et deux libellés différents pour le même état se liraient comme deux états.
  ///
  /// In fr, this message translates to:
  /// **'À vendre'**
  String get catalogOfferSale;

  /// Puce de filtre « location » et badge de la carte d'un véhicule proposé à la location seule. Voir catalogOfferSale.
  ///
  /// In fr, this message translates to:
  /// **'À louer'**
  String get catalogOfferRent;

  /// Badge de la carte d'un véhicule proposé à la vente ET à la location. LE PLUS LARGE DES QUATRE BADGES, et celui qui a imposé les deux lignes de `_AvailabilityBadge` : il reçoit 107,0 points sur une vignette de 135 et en demande 118,9 en français à l'échelle 1,5 — d'où les deux lignes, sans lesquelles le `clipBehavior` du `Card` le coupait en silence. L'ANGLAIS Y GAGNE DE LA PLACE, mesuré au même endroit : « Sale & rental » demande 88,8 points et tient sur UNE ligne à 1,5, et 117,4 contre 157,2 à l'échelle 2,0. Toute traduction plus large rouvre le défaut — `carte_geometrie_test.dart` lit ce libellé dans les `.arb` et le mesure dans les deux langues, aux vingt-quatre cases.
  ///
  /// In fr, this message translates to:
  /// **'Vente & Location'**
  String get catalogOfferBoth;

  /// Badge de la carte d'un véhicule qui n'est ni à vendre ni à louer. Distinct de catalogStockOut, qui dit l'absence de STOCK d'une pièce ou d'un accessoire : le français disait « Indisponible » pour les deux, l'anglais ne le peut pas — un véhicule n'est pas « out of stock ».
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get catalogOfferNone;

  /// Puce de filtre des promotions, quand le serveur n'en annonce aucune. L'ÉTIQUETTE « Bonne affaire » QUE PORTE UNE CARTE N'EST PAS CETTE CLÉ : elle vient du champ `deal_label` du serveur et reste en français jusqu'à la vague serveur — voir la fin de CONVENTION.md.
  ///
  /// In fr, this message translates to:
  /// **'Bonne affaire'**
  String get catalogDealFilter;

  /// La même puce quand le serveur annonce des promotions. Le compte est entre parenthèses et non suffixé : la puce pulse trois fois pour se faire remarquer, et un nombre collé au libellé grandirait la cible pendant la pulsation.
  ///
  /// In fr, this message translates to:
  /// **'Bonne affaire ({count})'**
  String catalogDealFilterCount(int count);

  /// Puce de filtre des véhicules déjà dédouanés, et ligne de la fiche détaillée. CONTRE-EXEMPLE DE L'IDÉE QUE L'ANGLAIS RACCOURCIT : 8 signes en français, 15 en anglais (« Customs cleared »), soit presque le double. C'est la puce la plus large de son groupe en anglais, et `bandes_filtres_test.dart` la mesure dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'Dédouané'**
  String get catalogCustomsCleared;

  /// Puce de filtre des véhicules déjà immatriculés — ceux qui se conduisent le jour même, sans démarche. Va par paire avec catalogNotRegistered, et se lit à côté de catalogCustomsCleared, qui ne dit que la première étape d'un import.
  ///
  /// In fr, this message translates to:
  /// **'Immatriculé'**
  String get catalogRegistered;

  /// Puce de filtre des véhicules importés pas encore immatriculés. Le français est ici le plus long des deux (15 signes contre 14 pour « Not registered ») : c'est la puce à surveiller dans bandes_filtres_test.dart pour ce groupe.
  ///
  /// In fr, this message translates to:
  /// **'Non immatriculé'**
  String get catalogNotRegistered;

  /// Titre du groupe de filtres qui réunit l'immatriculation et le dédouanement. Mot volontairement courant plutôt que « Statut administratif » : c'est ainsi qu'on en parle sur un parc.
  ///
  /// In fr, this message translates to:
  /// **'Papiers'**
  String get catalogFilterGroupPapers;

  /// Puce de filtre des véhicules utilitaires légers. À ne pas confondre avec catalogAccessoryCategoryUtility, qui porte le même mot français pour une catégorie d'ACCESSOIRES : deux clés distinctes parce que l'anglais les sépare mal et qu'une clé partagée aurait figé la confusion.
  ///
  /// In fr, this message translates to:
  /// **'Utilitaire'**
  String get catalogVehicleTypeUtility;

  /// Puce de filtre des poids lourds.
  ///
  /// In fr, this message translates to:
  /// **'Poids lourd'**
  String get catalogVehicleTypeHeavy;

  /// Puce de carrosserie. « Saloon » et non « Sedan » : le reste des traductions de ce dépôt est en anglais britannique — « Refresh catalogue », « Catalogue updated » — et c'est aussi l'usage de l'Afrique de l'Ouest anglophone. À réarbitrer en un seul endroit si le propriétaire préfère l'usage américain.
  ///
  /// In fr, this message translates to:
  /// **'Berline'**
  String get catalogBodyStyleSedan;

  /// Puce de carrosserie, identique dans les deux langues. Le signe est une MULTIPLICATION (U+00D7) et non la lettre x : `bandes_filtres_test.dart` cherche cette puce par son texte exact, et une lettre x ne la trouverait pas.
  ///
  /// In fr, this message translates to:
  /// **'SUV / 4×4'**
  String get catalogBodyStyleSuv;

  /// Puce de carrosserie. Le français de la fiche détaillée dit « Citadine / Hayon » pour la MÊME valeur `hatchback` — deux libellés français divergents, antérieurs à ce lot, d'où deux clés : catalogBodyLabelHatchback porte celui de la fiche. Les unifier serait une modification du français, que ce lot n'a pas à faire en passant.
  ///
  /// In fr, this message translates to:
  /// **'Citadine'**
  String get catalogBodyStyleHatchback;

  /// Puce de carrosserie, identique dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'Pickup'**
  String get catalogBodyStylePickup;

  /// Puce de carrosserie, identique dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'Minibus'**
  String get catalogBodyStyleMinibus;

  /// Puce de carrosserie. PIÈGE DE TRADUCTION : le « Car » français désigne un autocar, pas une automobile. Laissé tel quel, un anglophone y lirait « bus ou voiture ». D'où « Bus / Coach ».
  ///
  /// In fr, this message translates to:
  /// **'Bus / Car'**
  String get catalogBodyStyleBus;

  /// Puce de carrosserie. La fiche détaillée dit « Fourgonnette » pour la même valeur `van` — voir catalogBodyStyleHatchback pour la raison des deux clés.
  ///
  /// In fr, this message translates to:
  /// **'Fourgon'**
  String get catalogBodyStyleVan;

  /// Puce de carrosserie. « Break » est un faux ami : en anglais il ne désigne aucune carrosserie, d'où « Estate ».
  ///
  /// In fr, this message translates to:
  /// **'Break'**
  String get catalogBodyStyleEstate;

  /// Puce de carrosserie.
  ///
  /// In fr, this message translates to:
  /// **'Camion'**
  String get catalogBodyStyleTruck;

  /// Puce de carrosserie.
  ///
  /// In fr, this message translates to:
  /// **'Cabriolet'**
  String get catalogBodyStyleConvertible;

  /// Puce de carrosserie. L'ACCENT EST CONSERVÉ EN ANGLAIS : « Coupé » est la graphie du vocabulaire automobile anglais, et « Coupe » s'y lit comme un autre mot.
  ///
  /// In fr, this message translates to:
  /// **'Coupé'**
  String get catalogBodyStyleCoupe;

  /// Compteur de photos dans le coin de la vignette d'une carte de véhicule, à partir de deux — « 1 photos » est faux et « 1 photo » n'annoncerait rien que la vignette ne montre déjà. Identique en anglais. La clé existe quand même, et pas seulement par principe : le libellé est borné à deux lignes sur 93,0 points de largeur utile, donc toute traduction plus longue est un défaut, et une chaîne en dur sort du champ de la vérification.
  ///
  /// In fr, this message translates to:
  /// **'{count} photos'**
  String catalogPhotoCount(int count);

  /// Remplace le prix sur la carte d'un véhicule dont ni le prix de vente ni le tarif de location n'est renseigné. Cette chaîne-ci A LE DROIT de s'ellipser, contrairement au prix qu'elle remplace : « Prix non communi… » se lit encore comme la même phrase, alors qu'un nombre coupé devient un AUTRE nombre — voir porteUnNombre dans test/support/mesures.dart.
  ///
  /// In fr, this message translates to:
  /// **'Prix non communiqué'**
  String get catalogPriceOnRequest;

  /// Titre de l'écran vide de la liste des véhicules.
  ///
  /// In fr, this message translates to:
  /// **'Aucun véhicule trouvé'**
  String get catalogVehicleNoneFound;

  /// Corps de l'écran vide quand AUCUN filtre n'est posé : alors la liste est vide parce que le catalogue l'est, et nommer des filtres inexistants égarerait. Avec des filtres, c'est catalogActiveFilters qui s'affiche.
  ///
  /// In fr, this message translates to:
  /// **'Le catalogue ne contient aucun véhicule pour le moment.'**
  String get catalogVehicleCatalogEmpty;

  /// Terme listé par catalogActiveFilters. MINUSCULE ET SANS PONCTUATION : ce fragment ne s'affiche jamais seul, il est joint à d'autres au milieu d'une phrase. Distinct de catalogOfferSale, qui est le libellé de la puce et porte sa majuscule.
  ///
  /// In fr, this message translates to:
  /// **'à vendre'**
  String get catalogFilterTermSale;

  /// Terme listé par catalogActiveFilters. Voir catalogFilterTermSale.
  ///
  /// In fr, this message translates to:
  /// **'à louer'**
  String get catalogFilterTermRent;

  /// Terme listé par catalogActiveFilters. Voir catalogFilterTermSale.
  ///
  /// In fr, this message translates to:
  /// **'bonne affaire'**
  String get catalogFilterTermDeal;

  /// Terme listé par catalogActiveFilters. Voir catalogFilterTermSale.
  ///
  /// In fr, this message translates to:
  /// **'dédouané'**
  String get catalogFilterTermCustoms;

  /// Terme listé par catalogActiveFilters. Il nomme le CRITÈRE et non la valeur choisie, parce que la phrase sert à retrouver quelle case décocher.
  ///
  /// In fr, this message translates to:
  /// **'type de véhicule'**
  String get catalogFilterTermVehicleType;

  /// Terme listé par catalogActiveFilters. Voir catalogFilterTermVehicleType.
  ///
  /// In fr, this message translates to:
  /// **'carrosserie'**
  String get catalogFilterTermBodyStyle;

  /// Terme listé par catalogActiveFilters. Voir catalogFilterTermVehicleType.
  ///
  /// In fr, this message translates to:
  /// **'état'**
  String get catalogFilterTermCondition;

  /// Terme listé par catalogActiveFilters, posé dès que l'une des deux bornes d'année est renseignée. Voir catalogFilterTermVehicleType.
  ///
  /// In fr, this message translates to:
  /// **'année'**
  String get catalogFilterTermYear;

  /// Terme listé par catalogActiveFilters. Voir catalogFilterTermVehicleType.
  ///
  /// In fr, this message translates to:
  /// **'prix maximum'**
  String get catalogFilterTermPriceMax;

  /// Terme listé par catalogActiveFilters sur la liste des pièces. Voir catalogFilterTermVehicleType.
  ///
  /// In fr, this message translates to:
  /// **'référence OEM'**
  String get catalogFilterTermOem;

  /// Terme listé par catalogActiveFilters sur les listes des pièces et des accessoires. L'ARTICLE INDÉFINI EST VOULU : la catégorie choisie porte un nom que le serveur envoie, et le répéter ici aurait demandé de le traduire — alors qu'il reste en français jusqu'à la vague serveur.
  ///
  /// In fr, this message translates to:
  /// **'une catégorie'**
  String get catalogFilterTermCategory;

  /// Terme listé par catalogActiveFilters sur la liste des pièces, quand le filtre « compatibles avec mon véhicule » est posé.
  ///
  /// In fr, this message translates to:
  /// **'compatibilité véhicule'**
  String get catalogFilterTermFitment;

  /// Terme listé par catalogActiveFilters sur la liste des pièces. Voir catalogFilterTermSale.
  ///
  /// In fr, this message translates to:
  /// **'en stock'**
  String get catalogFilterTermInStock;

  /// Bouton flottant de la liste des pièces, visible pour le seul personnel habilité. Il mène à un écran de saisie du personnel, qui n'est PAS traduit par cette vague ; le bouton l'est, parce qu'il s'affiche sur une page cliente.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle pièce'**
  String get catalogPartAddCta;

  /// Invite de la barre de recherche des pièces. Les trois termes disent les trois champs réellement interrogés ; « OEM » seul y remplace « référence OEM », parce que le sigle suffit sur un écran de pièces. RACCOURCIE SOUS LA MESURE, dans les deux langues : le français réclamait 264,7 points pour 240,0 reçus à 320 points d'écran dès l'échelle 1,3, et l'anglais 275,7 — « Name, SKU, OEM reference… » était PLUS LONG que le français, ce qu'aucun banc ne voyait.
  ///
  /// In fr, this message translates to:
  /// **'Nom, SKU, OEM…'**
  String get catalogPartSearchHint;

  /// Nature d'une pièce, sur le badge de sa carte. Sigle identique dans les deux langues, et la clé existe quand même : les quatre natures forment un ensemble, et en laisser trois en dur rendrait le quatrième libellé introuvable. Le repli pour une nature inconnue du serveur reste le code brut en capitales, sans clé — ce n'est pas un libellé, c'est un aveu.
  ///
  /// In fr, this message translates to:
  /// **'OEM'**
  String get catalogPartTypeOem;

  /// Nature d'une pièce. Voir catalogPartTypeOem.
  ///
  /// In fr, this message translates to:
  /// **'OES'**
  String get catalogPartTypeOes;

  /// Nature d'une pièce. Le français emprunte déjà le mot anglais ; les deux locales portent donc la même valeur. Voir catalogPartTypeOem.
  ///
  /// In fr, this message translates to:
  /// **'Aftermarket'**
  String get catalogPartTypeAftermarket;

  /// Nature d'une pièce de récupération. La seule des quatre dont le libellé change réellement avec la langue.
  ///
  /// In fr, this message translates to:
  /// **'Occasion'**
  String get catalogPartTypeSalvage;

  /// Badge de stock d'une pièce ou d'un accessoire. CE LIBELLÉ N'EST PAS ATTEIGNABLE AUJOURD'HUI : les deux `_AvailabilityBadge` du catalogue rendent `SizedBox.shrink()` dès que le stock est disponible — « une information portée par 100 % des cartes n'en est plus une ». La clé existe pour que la branche reste traduite si cette décision change, et ce fait est écrit ici plutôt que découvert au lot suivant.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get catalogStockIn;

  /// Badge de stock d'une pièce ou d'un accessoire en rupture. Le français écrit le même mot que catalogOfferNone, qui dit l'indisponibilité commerciale d'un VÉHICULE ; l'anglais les sépare — « Out of stock » n'a pas de sens pour un véhicule. Deux clés, donc, et c'est la traduction qui a révélé que le français confondait deux états.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get catalogStockOut;

  /// Infobulle de la puce « Compatibles » du bandeau de garage, sur la liste des pièces. Visible pour les seuls clients connectés ayant un véhicule enregistré.
  ///
  /// In fr, this message translates to:
  /// **'Pièces compatibles avec ce véhicule'**
  String get catalogGarageFitmentTooltip;

  /// Remplace l'infobulle précédente quand le véhicule du garage porte un modèle tapé à la main : le catalogue ne le connaît pas, la puce est grisée, et son motif est dit plutôt que tu — une puce inerte et sans explication se lit comme une panne.
  ///
  /// In fr, this message translates to:
  /// **'Modèle hors catalogue : compatibilité indisponible'**
  String get catalogGarageFitmentUnknownModel;

  /// Puce du bandeau de garage qui restreint la liste aux pièces compatibles avec le véhicule choisi. Elle vit dans un bandeau dont la hauteur a été rabaissée sous les 48 points de cible tactile standard, donc sa largeur est comptée : « Fitting only » déborderait, « Fitting » tient.
  ///
  /// In fr, this message translates to:
  /// **'Compatibles'**
  String get catalogGarageFitmentChip;

  /// Titre de l'écran vide de la liste des pièces.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pièce trouvée'**
  String get catalogPartNoneFound;

  /// Corps de l'écran vide de la liste des pièces, sans aucun filtre posé. Voir catalogVehicleCatalogEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Le catalogue ne contient aucune pièce pour le moment.'**
  String get catalogPartCatalogEmpty;

  /// Bouton flottant de la liste des accessoires, visible pour le seul personnel habilité. Voir catalogPartAddCta.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel accessoire'**
  String get catalogAccessoryAddCta;

  /// Invite de la barre de recherche des accessoires. Deux champs seulement, contre trois pour les pièces : un accessoire n'a pas de référence constructeur.
  ///
  /// In fr, this message translates to:
  /// **'Nom ou SKU…'**
  String get catalogAccessorySearchHint;

  /// Puce de catégorie d'accessoire. LES CINQ CATÉGORIES SONT ÉCRITES DANS L'APPLICATION et non reçues du serveur — l'API ne fournit ni libellé ni icône, seulement lesquelles portent un article en vente —, donc elles entrent bien dans les `.arb`, contrairement aux catégories de PIÈCES qui arrivent nommées du référentiel et restent en français jusqu'à la vague serveur.
  ///
  /// In fr, this message translates to:
  /// **'Esthétique'**
  String get catalogAccessoryCategoryStyling;

  /// Puce de catégorie d'accessoire. Voir catalogAccessoryCategoryStyling.
  ///
  /// In fr, this message translates to:
  /// **'Confort'**
  String get catalogAccessoryCategoryComfort;

  /// Puce de catégorie d'accessoire. Voir catalogAccessoryCategoryStyling.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get catalogAccessoryCategorySafety;

  /// Puce de catégorie d'accessoire. Voir catalogAccessoryCategoryStyling.
  ///
  /// In fr, this message translates to:
  /// **'Multimédia'**
  String get catalogAccessoryCategoryMultimedia;

  /// Puce de catégorie d'accessoire. Même mot français que catalogVehicleTypeUtility, qui filtre des VÉHICULES utilitaires ; deux clés distinctes parce qu'une clé partagée aurait figé en anglais une confusion que le français laisse passer.
  ///
  /// In fr, this message translates to:
  /// **'Utilitaire'**
  String get catalogAccessoryCategoryUtility;

  /// Titre de l'écran vide de la liste des accessoires.
  ///
  /// In fr, this message translates to:
  /// **'Aucun accessoire trouvé'**
  String get catalogAccessoryNoneFound;

  /// Corps de l'écran vide de la liste des accessoires, sans aucun filtre posé. Voir catalogVehicleCatalogEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Le catalogue ne contient aucun accessoire pour le moment.'**
  String get catalogAccessoryCatalogEmpty;

  /// Infobulle du bouton de partage, sur les trois fiches. C'est la seule commande de la barre de titre qu'un visiteur sans compte voit, et le geste le plus courant de l'application — on envoie la fiche à un proche pour qu'il rappelle l'agence. Trois sites d'appel, une seule zone : la clé reste préfixée `catalog`, le seuil de `common` demandant deux zones.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get catalogShareTooltip;

  /// Infobulle du bouton qui ouvre l'écran de saisie du personnel, sur les trois fiches, et bouton du bloc des compatibilités déclarées. L'écran de saisie lui-même n'est pas traduit par cette vague ; son point d'entrée l'est, parce qu'il s'affiche sur une fiche cliente.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get catalogEditTooltip;

  /// Le mot de l'action destructrice : infobulle du bouton de la barre de titre ET bouton de confirmation de la boîte de dialogue, sur les trois fiches — six sites d'appel. UNE SEULE CLÉ, et c'est voulu : la boîte demande « Supprimer ce véhicule ? » et son bouton doit répéter le mot du bouton qui l'a ouverte, sinon l'utilisateur doute d'avoir déclenché la même action.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get catalogDeleteAction;

  /// Titre de la confirmation de suppression d'un véhicule.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce véhicule ?'**
  String get catalogVehicleDeleteTitle;

  /// Corps de la confirmation de suppression d'un véhicule. TROIS CLÉS POUR LA MÊME PHRASE — véhicule, pièce, accessoire —, et c'est le FRANÇAIS qui les impose : « supprimé » s'accorde, et « la pièce sera supprimée ». L'anglais n'accorde pas et porte trois fois la même valeur ; fusionner les clés rendrait l'une des trois phrases fautive en français, ce qui est le genre de défaut qu'aucun outil ne signale.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera supprimé définitivement.'**
  String catalogVehicleDeleteBody(String name);

  /// Titre du bloc d'identité de la fiche d'un véhicule : marque, modèle, année, et tout le bloc technique.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get catalogSectionVehicle;

  /// Titre du bloc d'usure de la fiche d'un véhicule : condition, kilométrage, pannes déclarées. DISTINCT de catalogFieldCondition, qui est le libellé de la LIGNE à l'intérieur de ce bloc — le français écrit « État » pour le titre et « Condition » pour la ligne, et l'anglais ne peut pas écrire « Condition » deux fois de suite sans donner l'impression d'un doublon.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get catalogSectionCondition;

  /// Titre du bloc d'importation, affiché pour un véhicule non immatriculé. Identique en anglais.
  ///
  /// In fr, this message translates to:
  /// **'Import'**
  String get catalogSectionImport;

  /// Titre du bloc qui dit où le véhicule se trouve.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get catalogSectionLocation;

  /// Titre du bloc des équipements de la fiche, et libellé du bouton flottant du personnel qui ouvre leur édition. Deux sites, même mot, même clé : le bouton ouvre exactement le bloc qu'il nomme.
  ///
  /// In fr, this message translates to:
  /// **'Équipements'**
  String get catalogSectionFeatures;

  /// Titre du bloc du partenaire ayant fourni le véhicule. Visible du PERSONNEL seulement, et traduit quand même : il s'affiche sur une fiche par ailleurs cliente, et un bloc français au milieu d'une fiche anglaise se lit comme un défaut d'affichage.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire source'**
  String get catalogSectionPartner;

  /// Libellé de ligne de la fiche. La VALEUR vient du référentiel du serveur et n'est pas traduite.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get catalogFieldBrand;

  /// Libellé de ligne de la fiche. Voir catalogFieldBrand.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get catalogFieldModel;

  /// Libellé de ligne de la fiche.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get catalogFieldYear;

  /// Libellé de ligne de la fiche. Voir catalogFieldBrand.
  ///
  /// In fr, this message translates to:
  /// **'Finition'**
  String get catalogFieldTrim;

  /// Libellé de ligne de la fiche. La valeur arrive DÉJÀ RÉDIGÉE du serveur — « Essence », « Électrique » sont les intitulés de la table de référence — et reste en français jusqu'à la vague serveur. La ligne sera donc anglaise à gauche et française à droite, ce qui est assumé : la clé .arb ne traduirait pas la valeur, elle dupliquerait un texte que le serveur continue d'écrire.
  ///
  /// In fr, this message translates to:
  /// **'Motorisation'**
  String get catalogFieldEngine;

  /// Libellé de ligne de la fiche. Voir catalogFieldEngine pour la valeur.
  ///
  /// In fr, this message translates to:
  /// **'Roues motrices'**
  String get catalogFieldDrivetrain;

  /// Libellé de ligne de la fiche. Même mot que catalogFilterGroupBodyStyle, qui titre le groupe de puces de la liste ; deux clés parce que l'un est un intitulé de groupe de filtres et l'autre un libellé de ligne — scinder plus tard aurait demandé d'auditer les deux écrans.
  ///
  /// In fr, this message translates to:
  /// **'Carrosserie'**
  String get catalogFieldBodyStyle;

  /// Libellé de ligne de la fiche. ABRÉGÉ EN FRANÇAIS — « Boîte » et non « Boîte de vitesses » —, et l'anglais ne peut pas abréger de la même façon : « Box » ne veut rien dire ici, d'où « Gearbox », plus long d'un signe que le français.
  ///
  /// In fr, this message translates to:
  /// **'Boîte'**
  String get catalogFieldTransmission;

  /// Libellé de ligne de la fiche.
  ///
  /// In fr, this message translates to:
  /// **'Puissance'**
  String get catalogFieldPower;

  /// Libellé de ligne de la fiche.
  ///
  /// In fr, this message translates to:
  /// **'Cylindrée'**
  String get catalogFieldDisplacement;

  /// Libellé de ligne de la fiche.
  ///
  /// In fr, this message translates to:
  /// **'Cylindres'**
  String get catalogFieldCylinders;

  /// Libellé de ligne de la fiche. Faux ami à l'envers : le « couple » mécanique se dit « torque » et non « couple », qui en anglais désigne deux personnes.
  ///
  /// In fr, this message translates to:
  /// **'Couple'**
  String get catalogFieldTorque;

  /// Libellé de ligne de la fiche : le nombre de rapports de la boîte.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get catalogFieldGears;

  /// Libellé de ligne de la fiche.
  ///
  /// In fr, this message translates to:
  /// **'Places'**
  String get catalogFieldSeats;

  /// Libellé de ligne de la fiche.
  ///
  /// In fr, this message translates to:
  /// **'Portes'**
  String get catalogFieldDoors;

  /// Libellé de ligne de la fiche : la référence constructeur du moteur, qui sert à commander la bonne pièce.
  ///
  /// In fr, this message translates to:
  /// **'Code moteur'**
  String get catalogFieldEngineCode;

  /// Libellé de ligne de la fiche : la consommation mixte déclarée pour ce véhicule-ci.
  ///
  /// In fr, this message translates to:
  /// **'Consommation'**
  String get catalogFieldConsumption;

  /// Libellé de ligne de la fiche : la référence interne du parc, « VH-… ».
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get catalogFieldReference;

  /// Libellé de la ligne qui dit si le véhicule est neuf, d'occasion ou accidenté. Voir catalogSectionCondition pour la raison des deux clés.
  ///
  /// In fr, this message translates to:
  /// **'Condition'**
  String get catalogFieldCondition;

  /// Libellé de ligne de la fiche. La valeur passe par commonMileageKm, dont l'unité reste MÉTRIQUE dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'Kilométrage'**
  String get catalogFieldMileage;

  /// Libellé de ligne de la fiche : le nombre de pannes que le vendeur a déclarées. « Déclarées » et non « connues », parce que c'est le vendeur qui répond de ce compte.
  ///
  /// In fr, this message translates to:
  /// **'Pannes déclarées'**
  String get catalogFieldFaults;

  /// Libellé de ligne du bloc d'import : le pays de provenance. La valeur vient du référentiel du serveur.
  ///
  /// In fr, this message translates to:
  /// **'Origine'**
  String get catalogFieldOrigin;

  /// Libellé de ligne du bloc d'import : le port par lequel le véhicule est arrivé. La valeur vient du serveur.
  ///
  /// In fr, this message translates to:
  /// **'Port d\'entrée'**
  String get catalogFieldPortOfEntry;

  /// Libellé de ligne du bloc d'import, affiché seulement pour une conduite à droite — une conduite à gauche est la norme et n'a pas à être dite.
  ///
  /// In fr, this message translates to:
  /// **'Conduite'**
  String get catalogFieldHandedness;

  /// Libellé de ligne du bloc de localisation : l'agence qui détient le véhicule. La valeur suit le gabarit « nom — ville » du serveur et n'est pas traduite.
  ///
  /// In fr, this message translates to:
  /// **'Agence'**
  String get catalogFieldBranch;

  /// Libellé de la ligne de couleur, qui porte aussi la pastille de teinte. Le NOM de la couleur vient du serveur ; la finition, elle, est rédigée ici — voir catalogColourMetallic.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get catalogFieldColour;

  /// La puissance et son unité. « ch » pour chevaux, « hp » pour horsepower : l'unité CHANGE DE NOM entre les deux langues, alors que la valeur est la même. C'est l'inverse de commonMileageKm, dont l'unité reste métrique parce que convertir ferait mentir un relevé — ici rien n'est converti, seul le symbole est traduit.
  ///
  /// In fr, this message translates to:
  /// **'{value} ch'**
  String catalogUnitHp(int value);

  /// La cylindrée et son unité. « cm³ » est la notation française, « cc » celle du vocabulaire automobile anglais ; la valeur est identique.
  ///
  /// In fr, this message translates to:
  /// **'{value} cm³'**
  String catalogUnitCc(int value);

  /// Le couple et son unité. Le newton-mètre s'écrit pareil dans les deux langues ; la clé existe quand même, pour que la ligne entière soit dans l'`.arb` comme ses voisines plutôt qu'à moitié.
  ///
  /// In fr, this message translates to:
  /// **'{value} Nm'**
  String catalogUnitTorque(int value);

  /// La consommation et son unité. L'UNITÉ RESTE MÉTRIQUE dans les deux langues, pour la raison écrite sur commonMileageKm : les clients visés comptent en litres aux cent kilomètres, et convertir en miles par gallon ferait mentir une valeur homologuée. La DÉCIMALE, elle, suit la langue — « 7,5 » en français, « 7.5 » en anglais — et c'est `formatDecimal` qui s'en charge, pas cette clé.
  ///
  /// In fr, this message translates to:
  /// **'{value} L/100 km'**
  String catalogUnitConsumption(String value);

  /// Valeur de la ligne « Condition » d'un véhicule.
  ///
  /// In fr, this message translates to:
  /// **'Neuf'**
  String get catalogConditionNew;

  /// Valeur de la ligne « Condition » d'un véhicule. Même mot français que catalogPartTypeSalvage, qui qualifie une PIÈCE de récupération ; deux clés, parce que l'anglais distingue l'état d'un véhicule de la provenance d'une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Occasion'**
  String get catalogConditionUsed;

  /// Valeur de la ligne « Condition » d'un véhicule.
  ///
  /// In fr, this message translates to:
  /// **'Accidenté'**
  String get catalogConditionDamaged;

  /// Valeur de la ligne « Dédouané » du bloc d'import. La coche fait partie de la valeur : elle porte l'information à elle seule pour qui parcourt la fiche des yeux.
  ///
  /// In fr, this message translates to:
  /// **'✓ Oui'**
  String get catalogCustomsYes;

  /// Valeur de la ligne « Dédouané » quand les droits ne sont pas acquittés. Le sablier fait partie de la valeur, comme la coche de catalogCustomsYes : c'est un montant restant à payer par l'acheteur, et il doit se voir sans être lu.
  ///
  /// In fr, this message translates to:
  /// **'⏳ En attente'**
  String get catalogCustomsPending;

  /// Valeur de la ligne « Conduite ». LE SIGLE EST CONSERVÉ DANS LES DEUX LANGUES : « RHD » est la mention qui figure sur les documents d'importation, et un acheteur la reconnaît même sans lire le mot qui la précède.
  ///
  /// In fr, this message translates to:
  /// **'Droite (RHD)'**
  String get catalogRightHandDrive;

  /// Le nom de la couleur et sa finition. LE NOM VIENT DU SERVEUR et n'est pas traduit ; la finition est rédigée ici, parce que le serveur n'envoie qu'un code (`metallise` / `nacre`).
  ///
  /// In fr, this message translates to:
  /// **'{name} (métallisé)'**
  String catalogColourMetallic(String name);

  /// Le nom de la couleur et sa finition nacrée. Voir catalogColourMetallic.
  ///
  /// In fr, this message translates to:
  /// **'{name} (nacré)'**
  String catalogColourPearl(String name);

  /// Sous-titre du bloc des équipements : cric, gilet, carnet d'entretien. Elle FERME LA MARCHE dans l'ordre d'affichage, parce qu'elle est présente sur tout le parc et ne départage aucun véhicule. Les six noms de catégorie sont écrits dans l'application et non reçus du serveur, donc ils entrent bien dans les `.arb` ; les ÉQUIPEMENTS eux-mêmes viennent du référentiel et restent en français.
  ///
  /// In fr, this message translates to:
  /// **'Dotation standard'**
  String get catalogFeatureCategoryStandard;

  /// Sous-titre du bloc des équipements. Voir catalogFeatureCategoryStandard. Même mot que catalogAccessoryCategoryComfort, qui est une catégorie d'ACCESSOIRES vendus : deux clés, deux référentiels.
  ///
  /// In fr, this message translates to:
  /// **'Confort'**
  String get catalogFeatureCategoryComfort;

  /// Sous-titre du bloc des équipements. Voir catalogFeatureCategoryStandard.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get catalogFeatureCategorySafety;

  /// Sous-titre du bloc des équipements. Voir catalogFeatureCategoryStandard.
  ///
  /// In fr, this message translates to:
  /// **'Multimédia'**
  String get catalogFeatureCategoryMultimedia;

  /// Sous-titre du bloc des équipements. LE PLUS LARGE DES SIX dans les deux langues — « Driver assistance » fait 18 signes contre 19 au français —, donc celui qui décide de la largeur de ce sous-titre.
  ///
  /// In fr, this message translates to:
  /// **'Aides à la conduite'**
  String get catalogFeatureCategoryDriverAid;

  /// Sous-titre du bloc des équipements, pour les catégories que le serveur enverrait et que l'application ne connaît pas. PLURIEL EN FRANÇAIS, SINGULIER EN ANGLAIS : « Autres » qualifie des équipements, « Other » est invariable et « Others » se lirait comme un nom.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get catalogFeatureCategoryOther;

  /// Titre de la feuille du personnel qui cocher les équipements. Plus long que catalogSectionFeatures, et c'était déjà le cas en français : une feuille qui s'ouvre par-dessus la fiche doit dire de quoi elle parle.
  ///
  /// In fr, this message translates to:
  /// **'Équipements du véhicule'**
  String get catalogFeaturesSheetTitle;

  /// Bouton qui valide la sélection d'équipements.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get catalogFeaturesSave;

  /// Message affiché quand le personnel ouvre l'édition des équipements avant que le référentiel soit arrivé. Il dit QUOI FAIRE — réessayer — au lieu de constater une panne, parce que la donnée arrive d'elle-même à la requête suivante.
  ///
  /// In fr, this message translates to:
  /// **'Données de référence non chargées, réessayez.'**
  String get catalogRefsUnavailable;

  /// Confirmation affichée après l'enregistrement des équipements. La coche fait partie de la valeur.
  ///
  /// In fr, this message translates to:
  /// **'Équipements mis à jour ✓'**
  String get catalogFeaturesUpdated;

  /// Étiquette d'un véhicule entièrement équipé. IDENTIQUE DANS LES DEUX LANGUES, et ce n'est pas une facilité : « full option » est l'expression employée sur place, en français comme en anglais, par les vendeurs comme par les acheteurs. La traduire en « fully loaded » aurait remplacé un terme du marché par un terme de catalogue.
  ///
  /// In fr, this message translates to:
  /// **'Full option'**
  String get catalogFullOption;

  /// Le compte d'équipements optionnels, accolé à l'étiquette « Full option » pour ne pas demander à l'acheteur de croire le mot sur parole. Le point médian et son espace font partie de la valeur : ils séparent le compte de l'étiquette à l'intérieur de la même pastille.
  ///
  /// In fr, this message translates to:
  /// **'· {count} équipements'**
  String catalogFullOptionCount(int count);

  /// Pastille posée à côté du prix de vente quand le vendeur accepte de discuter.
  ///
  /// In fr, this message translates to:
  /// **'Négociable'**
  String get catalogPriceNegotiable;

  /// La caution demandée pour une location. L'ESPACE DEVANT LES DEUX-POINTS EST UNE ESPACE ORDINAIRE (U+0020), relevée telle quelle dans le fichier : ce lot reporte la typographie existante et ne la corrige pas en passant. Le MONTANT est formaté par `formatXof`, qui suit la langue active — un banc qui monte un `MaterialApp` nu sans appeler `definirLocaleMontants` mesurerait ici un montant français sous un libellé anglais.
  ///
  /// In fr, this message translates to:
  /// **'Caution : {amount}'**
  String catalogRentalDeposit(String amount);

  /// Bouton de la barre d'action cliente qui ouvre le composeur sur le numéro commercial, et infobulle du bouton d'appel du bloc partenaire. « WhatsApp », le bouton voisin, N'EST PAS DANS LES `.arb` : c'est un nom de marque, comme « AutoParc ».
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get catalogCallAction;

  /// La consommation homologuée du modèle, affichée en FOURCHETTE et non en chiffre unique : l'annonce connaît son modèle et son millésime, rarement sa motorisation, et entre le 2,5 l quatre cylindres et le 3,5 l V6 d'une même Camry l'écart atteint 1,2 l/100. Choisir pour l'acheteur serait lui mentir sur une dépense hebdomadaire. L'espace devant les deux-points est ORDINAIRE, telle qu'elle existe dans le fichier.
  ///
  /// In fr, this message translates to:
  /// **'Consommation officielle : {range}'**
  String catalogOfficialConsumption(String range);

  /// La provenance de la fourchette quand une seule motorisation est connue pour ce millésime. « Millésime » PRÉCÈDE l'année en français et la SUIT en anglais (« 2016 model year ») : c'est un ordre de mots, pas un mot à mot, et une chaîne concaténée dans le code n'aurait pas pu l'exprimer.
  ///
  /// In fr, this message translates to:
  /// **'Millésime {year} — {source}, {cycle}'**
  String catalogOfficialConsumptionSingle(
    int year,
    String source,
    String cycle,
  );

  /// La provenance de la fourchette quand plusieurs motorisations sont connues. Elle était composée de QUATRE MORCEAUX concaténés dans le code, dont un se terminait par une espace pour tenir au suivant ; une phrase traduite ne peut pas être découpée ainsi — l'anglais ne met ni la parenthèse ni l'incise au même endroit. Les quatre morceaux sont donc une seule clé. Le `source` et le `cycle` viennent du serveur et restent en français.
  ///
  /// In fr, this message translates to:
  /// **'Selon la motorisation ({count} connues pour le millésime {year}) — {source}, {cycle}'**
  String catalogOfficialConsumptionRange(
    int count,
    int year,
    String source,
    String cycle,
  );

  /// Libellé de carrosserie DE LA FICHE. Jeu de clés distinct de catalogBodyStyle*, qui sert les puces de filtre de la liste : le français des deux écrans DIVERGE déjà pour `hatchback` et `van`, et cette divergence est antérieure à la traduction. L'unifier aurait changé le français de l'un des deux écrans, ce que ce lot n'a pas à faire en passant. Voir catalogBodyStyleSedan pour le choix de « Saloon ».
  ///
  /// In fr, this message translates to:
  /// **'Berline'**
  String get catalogBodyLabelSedan;

  /// Libellé de carrosserie de la fiche. LA DIVERGENCE NOMMÉE : la puce de filtre dit « Citadine » tout court. Les deux restent tels quels ; l'anglais les rend tous les deux par « Hatchback », qui est le mot unique de la langue — donc la divergence française disparaît à la traduction, et c'est un signe qu'elle n'avait pas de raison.
  ///
  /// In fr, this message translates to:
  /// **'Citadine / Hayon'**
  String get catalogBodyLabelHatchback;

  /// Libellé de carrosserie de la fiche, identique dans les deux langues. Le signe est une multiplication (U+00D7).
  ///
  /// In fr, this message translates to:
  /// **'SUV / 4×4'**
  String get catalogBodyLabelSuv;

  /// Libellé de carrosserie de la fiche. « Break » ne désigne aucune carrosserie en anglais, d'où « Estate ».
  ///
  /// In fr, this message translates to:
  /// **'Break'**
  String get catalogBodyLabelEstate;

  /// Libellé de carrosserie de la fiche. L'accent est conservé en anglais : voir catalogBodyStyleCoupe.
  ///
  /// In fr, this message translates to:
  /// **'Coupé'**
  String get catalogBodyLabelCoupe;

  /// Libellé de carrosserie de la fiche.
  ///
  /// In fr, this message translates to:
  /// **'Cabriolet'**
  String get catalogBodyLabelConvertible;

  /// Libellé de carrosserie de la fiche, identique dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'Pickup'**
  String get catalogBodyLabelPickup;

  /// Libellé de carrosserie de la fiche. LA SECONDE DIVERGENCE NOMMÉE : la puce de filtre dit « Fourgon ». Voir catalogBodyLabelHatchback.
  ///
  /// In fr, this message translates to:
  /// **'Fourgonnette'**
  String get catalogBodyLabelVan;

  /// Libellé de carrosserie de la fiche, identique dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'Minibus'**
  String get catalogBodyLabelMinibus;

  /// Libellé de carrosserie de la fiche. Le « Car » français désigne un autocar : voir catalogBodyStyleBus.
  ///
  /// In fr, this message translates to:
  /// **'Bus / Car'**
  String get catalogBodyLabelBus;

  /// Libellé de carrosserie de la fiche.
  ///
  /// In fr, this message translates to:
  /// **'Camion'**
  String get catalogBodyLabelTruck;

  /// Libellé de carrosserie de la fiche pour une valeur hors des onze autres. LA LISTE DES PUCES DE FILTRE N'A PAS CETTE VALEUR — onze contre douze —, et c'est pourquoi les deux jeux ne se recouvrent pas tout à fait : on ne filtre pas sur « autre ».
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get catalogBodyLabelOther;

  /// Valeur de la ligne « Boîte ». La transmission est le seul champ technique que le serveur envoie en CODE (`manual` / `cvt` / `automatic`) et non déjà rédigé — d'où ces trois clés, là où « Motorisation » n'en a aucune.
  ///
  /// In fr, this message translates to:
  /// **'Manuelle'**
  String get catalogTransmissionManual;

  /// Valeur de la ligne « Boîte ». Sigle identique dans les deux langues. Voir catalogTransmissionManual.
  ///
  /// In fr, this message translates to:
  /// **'CVT'**
  String get catalogTransmissionCvt;

  /// Valeur de la ligne « Boîte ». Voir catalogTransmissionManual.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get catalogTransmissionAutomatic;

  /// Infobulle du bouton qui ouvre le téléversement des photos, sur les fiches d'une pièce et d'un accessoire. Identique en anglais. Il existe parce que les photos ne s'ajoutaient QUE dans la seconde suivant la création — le formulaire basculait sur l'écran de téléversement, et plus rien n'y menait ensuite ; les dix filtres à huile publiés autrement que par le formulaire avaient des photos définitivement inaccessibles.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get catalogPhotosTooltip;

  /// Titre de la confirmation de suppression d'une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette pièce ?'**
  String get catalogPartDeleteTitle;

  /// Corps de la confirmation de suppression d'une pièce. « SupprimÉE » au féminin, là où catalogVehicleDeleteBody et catalogAccessoryDeleteBody écrivent « supprimé » : c'est cet accord qui interdit de fusionner les trois clés. L'anglais porte trois fois la même valeur, et c'est normal — il n'accorde pas.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera supprimée définitivement.'**
  String catalogPartDeleteBody(String name);

  /// Titre de la confirmation de suppression d'un accessoire.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet accessoire ?'**
  String get catalogAccessoryDeleteTitle;

  /// Corps de la confirmation de suppression d'un accessoire. Voir catalogPartDeleteBody pour la raison des trois clés.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera supprimé définitivement.'**
  String catalogAccessoryDeleteBody(String name);

  /// Titre du bloc de description libre d'une pièce ou d'un accessoire. Le TEXTE vient du serveur et n'est pas traduit. Identique en anglais.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get catalogSectionDescription;

  /// Titre de la carte d'informations produit d'une pièce ou d'un accessoire : type, état, catégorie, fabricant. PLURIEL EN FRANÇAIS, SINGULIER EN ANGLAIS — « Information » est indénombrable, et « Informations » s'y lirait comme une faute.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get catalogSectionInformation;

  /// Titre de la carte de prix d'une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get catalogSectionPrice;

  /// Libellé de la ligne de prix dans la carte de prix d'une pièce. Le MONTANT, à droite, reste entier : il passe à la ligne plutôt que d'être tronqué, un montant abrégé valant moins que pas de montant. La ligne débordait avant que ses deux textes soient contraints — un prix à sept chiffres sur un petit écran suffisait.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente'**
  String get catalogFieldSalePrice;

  /// Libellé de la ligne de nature d'une pièce. Identique en anglais.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get catalogFieldType;

  /// Libellé de la ligne d'état d'une pièce : neuf, reconditionné, usagé. Le français écrit « État » ici et « Condition » sur la fiche d'un VÉHICULE (catalogFieldCondition), pour la même notion ; l'anglais rend les deux par « Condition », et la divergence française disparaît donc à la traduction. Les deux lignes ne s'affichent JAMAIS sur le même écran — l'une est sur la fiche d'une pièce, l'autre sur celle d'un véhicule —, donc le même mot anglais n'y crée aucune ambiguïté. Clés distinctes quand même : les deux référentiels sont indépendants côté serveur, et une pièce « reconditionnée » n'a pas d'équivalent chez les véhicules.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get catalogFieldState;

  /// Libellé de la ligne de catégorie d'une pièce ou d'un accessoire. La VALEUR vient du référentiel du serveur et reste en français jusqu'à la vague serveur.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get catalogFieldCategory;

  /// Libellé de la ligne de référence interne d'un accessoire. Sigle identique dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'SKU'**
  String get catalogFieldSku;

  /// Libellé de la ligne de fabricant d'une pièce ou d'un accessoire. La valeur vient du serveur.
  ///
  /// « Brand » ET NON « Manufacturer », ET C'EST UNE MESURE QUI L'A DÉCIDÉ. La colonne des libellés de la fiche d'une pièce est un `SizedBox` de 100 points de LARGE FIXE, qui ne suit pas l'échelle de texte ; « Manufacturer » est un seul mot insécable de 106,0 points à l'échelle 1,3 et de 121,8 à 1,5, donc il débordait de sa colonne et se peignait par-dessus la valeur — sans ellipse, parce qu'un mot plus large que sa ligne n'est pas une troncature que `didExceedMaxLines` voit. Relevé par le banc « Les écrans de la vague 2 », sur la seule colonne ANGLAISE : « Fabricant » tient.
  ///
  /// « Brand » est aussi le mot des catalogues de pièces, et il ne se confond pas avec catalogFieldBrand (« Marque », rendu « Make »), qui est la marque d'un VÉHICULE et vit sur un autre écran.
  ///
  /// In fr, this message translates to:
  /// **'Fabricant'**
  String get catalogFieldManufacturer;

  /// La nature d'une pièce, DÉVELOPPÉE, telle que la fiche l'affiche. La liste, elle, n'a de place que pour le sigle : catalogPartTypeOem. Deux jeux de clés pour la même valeur `oem`, et c'était déjà deux chaînes différentes en français — une carte de catalogue n'a pas la largeur d'une ligne de fiche. Le tiret est un CADRATIN (U+2014), et il fait partie de la valeur.
  ///
  /// In fr, this message translates to:
  /// **'OEM — Constructeur d\'origine'**
  String get catalogPartTypeOemLong;

  /// La nature d'une pièce, développée. Voir catalogPartTypeOemLong.
  ///
  /// In fr, this message translates to:
  /// **'OES — Équipementier agréé'**
  String get catalogPartTypeOesLong;

  /// La nature d'une pièce, développée. Voir catalogPartTypeOemLong.
  ///
  /// In fr, this message translates to:
  /// **'Aftermarket — Marché libre'**
  String get catalogPartTypeAftermarketLong;

  /// La nature d'une pièce de récupération, développée. La seule des quatre sans sigle : elle n'a donc pas de cadratin, et sa barre oblique sépare deux synonymes du marché plutôt qu'un sigle de sa définition.
  ///
  /// In fr, this message translates to:
  /// **'Récupération / Occasion'**
  String get catalogPartTypeSalvageLong;

  /// Valeur de la ligne « État » d'une pièce. Même mot que catalogConditionNew, qui qualifie un VÉHICULE ; deux clés, parce que les deux référentiels sont indépendants côté serveur et qu'une pièce « reconditionnée » n'a pas d'équivalent chez les véhicules.
  ///
  /// In fr, this message translates to:
  /// **'Neuf'**
  String get catalogPartConditionNew;

  /// Valeur de la ligne « État » d'une pièce : remise en état par un atelier, avec garantie. Distinct de catalogPartConditionUsed, qui est vendu tel quel.
  ///
  /// In fr, this message translates to:
  /// **'Reconditionné'**
  String get catalogPartConditionRefurbished;

  /// Valeur de la ligne « État » d'une pièce, vendue en l'état. « Usagé » et non « Occasion », qui est le mot de la PROVENANCE (catalogPartTypeSalvage) : une pièce de récupération peut être reconditionnée, et une pièce neuve d'équipementier ne peut pas être usagée. Les deux colonnes sont indépendantes, et l'anglais garde la distinction avec « Used » contre « Salvage ».
  ///
  /// In fr, this message translates to:
  /// **'Usagé'**
  String get catalogPartConditionUsed;

  /// Bouton de bas de fiche d'une pièce ou d'un accessoire. CONTRE-EXEMPLE UTILE : l'anglais est ici plus COURT — « Add to cart », 11 signes contre 17 —, alors que catalogCustomsCleared fait l'inverse. C'est pourquoi la longueur est mesurée cas par cas et non supposée.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get catalogAddToCart;

  /// Le même bouton quand l'article est DÉJÀ au panier. Il n'est pas désactivé : on commande couramment deux plaquettes ou quatre bougies, et un bouton inerte ferait croire à une limite qui n'existe pas.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à nouveau'**
  String get catalogAddToCartAgain;

  /// Confirmation flottante après l'ajout au panier. Le NOM vient du serveur et n'est pas traduit. L'ACCORD EST AU MASCULIN et il est faux pour une pièce — « la pièce ajoutée » —, mais c'est le NOM de l'article qui occupe la place du sujet, et un nom de pièce peut être masculin (« Filtre à huile ajouté ») comme féminin (« Plaquette ajoutée ») : l'accord est indécidable sans connaître le genre du nom, que le serveur n'envoie pas. Le français existant fait ce choix ; ce lot le reporte au lieu de le corriger au hasard.
  ///
  /// In fr, this message translates to:
  /// **'{name} ajouté au panier'**
  String catalogAddedToCart(String name);

  /// Action de la confirmation flottante, qui ouvre le panier. COURTE PAR CONTRAINTE : un `SnackBarAction` partage sa ligne avec le message, et « Voir le panier » pousserait le nom de l'article à l'ellipse.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get catalogSeeCart;

  /// Libellé du bouton de panier désactivé et de la carte de stock d'une pièce, quand la quantité est nulle. La fiche d'un ACCESSOIRE écrit catalogOfferNone sur son bouton (« Indisponible ») et celle-ci sur sa carte de stock : les deux fiches divergent en français, et ce lot reporte la divergence sans la corriger.
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock'**
  String get catalogOutOfStock;

  /// La quantité disponible, sur la carte de stock d'une pièce ou d'un accessoire.
  ///
  /// In fr, this message translates to:
  /// **'{count} en stock'**
  String catalogStockQuantity(int count);

  /// La même quantité quand elle passe sous le seuil d'alerte du serveur. Le cadratin fait partie de la valeur. La fiche d'un ACCESSOIRE dit la même chose autrement — une pastille « Stock bas » à côté de la quantité, catalogStockLowChip —, et là encore ce lot reporte la divergence française au lieu de l'unifier.
  ///
  /// In fr, this message translates to:
  /// **'{count} en stock — stock faible'**
  String catalogStockQuantityLow(int count);

  /// Pastille d'alerte de la carte de stock d'un ACCESSOIRE. Voir catalogStockQuantityLow pour la divergence avec la fiche d'une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Stock bas'**
  String get catalogStockLowChip;

  /// L'emplacement physique de l'article en magasin, sous la quantité. L'espace devant les deux-points est ORDINAIRE (U+0020), relevée telle quelle. La VALEUR est saisie par le personnel et n'est pas traduite. La fiche d'un accessoire ne la montrait nulle part — on la saisissait au formulaire et elle disparaissait.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement : {location}'**
  String catalogStockLocation(String location);

  /// Ce qu'affiche le bloc des véhicules compatibles d'une PIÈCE qui n'en déclare aucune. Il dit la CONSÉQUENCE et non l'absence : « aucune compatibilité » seul laisserait croire à une donnée manquante sans importance, alors que la pièce est introuvable par le chemin que les clients empruntent.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compatibilité déclarée. La pièce ne remonte pas dans une recherche par véhicule.'**
  String get catalogPartNoFitments;

  /// La même phrase pour un ACCESSOIRE. Deux clés et non une interpolation : « La pièce ne remonte pas » et « L'accessoire ne remonte pas » diffèrent par l'ARTICLE ÉLIDÉ, que le français décide d'après l'initiale du nom. Un gabarit « {article} {nom} ne remonte pas » aurait demandé d'envoyer l'article avec le nom.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compatibilité déclarée. L\'accessoire ne remonte pas dans une recherche par véhicule.'**
  String get catalogAccessoryNoFitments;

  /// Titre du bloc qui confronte l'article au garage du client. Il répond à une question étroite — « est-ce que ça va sur MES véhicules » — et c'est pourquoi le bloc des compatibilités déclarées existe à côté : il énumère, pour qui achète pour un proche ou dont le modèle n'est pas au référentiel.
  ///
  /// In fr, this message translates to:
  /// **'Vos véhicules'**
  String get catalogGarageSectionTitle;

  /// Verdict vert d'une ligne du bloc « Vos véhicules » : le modèle ET la motorisation correspondent. QUATRE VERDICTS ET NON TROIS, et la distinction a coûté une correction : un Hilux AN10 existe en diesel 1KD et en V6 essence 1GR, la recherche renvoyait les deux, et les annonçait tous les deux en vert — l'un des deux filtres ne se visse pas.
  ///
  /// In fr, this message translates to:
  /// **'Compatible'**
  String get catalogFitmentYes;

  /// Verdict ambre : le modèle correspond, la motorisation du véhicule du client n'est pas renseignée. Voir catalogFitmentYes pour le défaut qui a imposé ce quatrième état.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer'**
  String get catalogFitmentUnsure;

  /// L'explication sous le verdict « À confirmer ». Elle dit QUOI FAIRE, parce que le client peut lever l'incertitude lui-même en complétant sa fiche de garage.
  ///
  /// In fr, this message translates to:
  /// **'Compatible avec ce modèle, mais la motorisation de votre véhicule n\'est pas renseignée. Complétez-la pour être sûr.'**
  String get catalogFitmentUnsureDetail;

  /// Verdict rouge d'une ligne du bloc « Vos véhicules ».
  ///
  /// In fr, this message translates to:
  /// **'Non compatible'**
  String get catalogFitmentNo;

  /// Verdict ambre quand ni le modèle ni la motorisation ne permettent de trancher.
  ///
  /// In fr, this message translates to:
  /// **'Non déterminé'**
  String get catalogFitmentUnknown;

  /// L'explication sous le verdict « Non déterminé ». Comme catalogFitmentUnsureDetail, elle désigne le geste qui lève l'incertitude.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez la motorisation de votre véhicule pour obtenir une réponse.'**
  String get catalogFitmentUnknownDetail;

  /// Le nom d'un véhicule du garage et son millésime, en titre d'une ligne du bloc « Vos véhicules ». Le NOM est le surnom du propriétaire ou la désignation du serveur, et n'est pas traduit ; la clé ne porte que les parenthèses, qui pourraient changer de forme dans une autre langue.
  ///
  /// In fr, this message translates to:
  /// **'{name} ({year})'**
  String catalogVehicleWithYear(String name, int year);

  /// Titre de la page du panier quand il est vide, et infobulle de l'icône de panier des barres de titre du catalogue. Deux sites d'appel, même mot : l'icône mène à la page qu'elle nomme.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get cartTitle;

  /// Titre de la page du panier avec le nombre d'articles, somme des QUANTITÉS et non nombre de lignes : deux plaquettes et quatre bougies font six articles, pas deux. Le compte est entre parenthèses et non suffixé par un mot, pour que le titre ne s'allonge pas d'un pluriel dans la barre.
  ///
  /// In fr, this message translates to:
  /// **'Panier ({count})'**
  String cartTitleCount(int count);

  /// Bouton de la barre de titre qui vide le panier, et bouton de confirmation de la boîte de dialogue qu'il ouvre. Même mot aux deux endroits, pour la raison écrite sur catalogDeleteAction : un bouton de confirmation qui ne reprend pas le mot du bouton déclencheur fait douter d'avoir déclenché la même action.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get cartClear;

  /// Titre de la confirmation de vidage du panier.
  ///
  /// In fr, this message translates to:
  /// **'Vider le panier ?'**
  String get cartClearTitle;

  /// Corps de la confirmation de vidage. « Retirés » et non « supprimés » : les articles restent au catalogue, c'est le panier qui se vide.
  ///
  /// In fr, this message translates to:
  /// **'Tous les articles seront retirés.'**
  String get cartClearBody;

  /// Le détail du calcul d'une ligne du panier. LE SIGNE EST UNE MULTIPLICATION (U+00D7) et non la lettre x. Les deux MONTANTS passent par `formatXof`, qui suit la langue active : un banc qui monte un `MaterialApp` nu sans appeler `definirLocaleMontants` mesurerait ici des montants français sous une interface anglaise.
  ///
  /// In fr, this message translates to:
  /// **'{unitPrice} × {quantity} = {lineTotal}'**
  String cartLineTotal(String unitPrice, int quantity, String lineTotal);

  /// Ligne du récapitulatif : la somme hors taxes. « HT » est l'abréviation employée sur les factures locales ; l'anglais dit « excl. VAT », qui est l'équivalent reconnu et NON une traduction mot à mot du sigle.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total HT'**
  String get cartSubtotalExclTax;

  /// Ligne du récapitulatif : le montant de la taxe. Le sigle change de langue — « TVA » contre « VAT » — alors que les trois mêmes lettres y sont : c'est le genre de piège qu'une chaîne laissée en dur passe sans bruit.
  ///
  /// In fr, this message translates to:
  /// **'TVA'**
  String get cartVat;

  /// Ligne du récapitulatif : le total à payer. Voir cartSubtotalExclTax pour le traitement du sigle.
  ///
  /// In fr, this message translates to:
  /// **'Total TTC'**
  String get cartTotalInclTax;

  /// Bouton de commande du client, qui ouvre WhatsApp avec le panier déjà composé. « WhatsApp » est un nom de marque et ne se traduit pas — même règle que « AutoParc ». C'EST LE PLUS LONG LIBELLÉ DE BOUTON DU PARCOURS CLIENT dans les deux langues, et il occupe toute la largeur de l'écran : c'est donc lui qui décide si la barre de commande tient.
  ///
  /// In fr, this message translates to:
  /// **'Commander via WhatsApp'**
  String get cartOrderViaWhatsApp;

  /// Remplace le libellé du bouton de commande pendant le lancement de WhatsApp. Il est COURT par nécessité : il partage la ligne avec un indicateur de chargement, qui prend la place de l'icône.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture…'**
  String get cartOpening;

  /// Première ligne du message envoyé à la boutique par WhatsApp. Les astérisques sont la mise en gras de WhatsApp ; ailleurs ils s'affichent tels quels, ce qui est inoffensif — même arbitrage que composerMessagePartage. « AutoParc » est un nom propre et ne se traduit pas.
  ///
  /// In fr, this message translates to:
  /// **'*Demande de commande — AutoParc*'**
  String get cartWhatsAppHeader;

  /// Dernière ligne du message envoyé à la boutique par WhatsApp : ce que l'expéditeur attend en retour.
  ///
  /// In fr, this message translates to:
  /// **'Merci de confirmer la disponibilité.'**
  String get cartWhatsAppFooter;

  /// Message affiché quand le lancement de WhatsApp échoue. Il nomme la CAUSE plutôt que l'échec : c'est une installation manquante, pas une panne de l'application, et l'utilisateur ne peut agir que s'il le sait.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp n\'est pas installé sur cet appareil.'**
  String get cartWhatsAppMissing;

  /// Bouton du PERSONNEL, qui ouvre la saisie d'une commande au comptoir. Il est traduit bien qu'il soit réservé au personnel : il s'affiche sur la page du panier, qui est par ailleurs cliente, et un bouton français au milieu d'une barre anglaise se lit comme un défaut.
  ///
  /// In fr, this message translates to:
  /// **'Facturer'**
  String get cartInvoice;

  /// Titre de la feuille de saisie d'une commande au comptoir. PLURIEL EN FRANÇAIS, SINGULIER EN ANGLAIS : voir catalogSectionInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations client'**
  String get cartCustomerSection;

  /// Libellé du champ de nom du client. L'ASTÉRISQUE FAIT PARTIE DE LA VALEUR : c'est la seule marque d'obligation de ce formulaire, et le téléphone juste en dessous n'en porte pas.
  ///
  /// In fr, this message translates to:
  /// **'Nom du client *'**
  String get cartCustomerName;

  /// Message de validation du champ de nom, le seul obligatoire de la feuille.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get cartFieldRequired;

  /// Libellé du champ de téléphone du client. Même mot que shellContactPhone, qui titre la ligne « appeler » de la feuille de contact ; deux clés, deux zones, et le seuil de `common` n'est pas franchi avec deux sites.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get cartCustomerPhone;

  /// Gabarit de saisie du téléphone. L'INDICATIF EST CELUI DU BURKINA FASO et il ne change pas avec la langue : un client anglophone de Ouagadougou a un numéro en +226 comme les autres. Les « xx » restent en minuscules dans les deux langues — ce sont des emplacements à remplir, pas des mots.
  ///
  /// In fr, this message translates to:
  /// **'+226 xx xx xx xx'**
  String get cartPhoneHint;

  /// Résumé compact au-dessus du bouton de confirmation de la feuille du personnel. LE « (s) » EST CONSERVÉ TEL QUEL, et c'est un report et non un choix : ce lot ne change pas le français, et le remplacer par un pluriel ICU — ce que les compteurs de résultats du catalogue ont fait — aurait rendu « 1 article » là où le français affiche « 1 article(s) ». L'anglais, lui, passe au pluriel ICU : il n'a pas de français à préserver, et « item(s) » dans une langue neuve serait une négligence recopiée.
  ///
  /// In fr, this message translates to:
  /// **'{count} article(s) · {total} TTC'**
  String cartItemCountSummary(int count, String total);

  /// Bouton qui enregistre la commande saisie au comptoir.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la commande'**
  String get cartConfirmOrder;

  /// Remplace le libellé du bouton pendant l'envoi. Court pour la même raison que cartOpening : il partage sa ligne avec un indicateur.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours…'**
  String get cartSubmitting;

  /// Confirmation affichée après l'enregistrement d'une commande. La coche fait partie de la valeur.
  ///
  /// In fr, this message translates to:
  /// **'Commande enregistrée avec succès ✓'**
  String get cartOrderSaved;

  /// Titre de l'écran du panier vide.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get cartEmptyTitle;

  /// Corps de l'écran du panier vide. LE RETOUR À LA LIGNE EST ÉCRIT DANS LA VALEUR et il est centré : c'est une coupure CHOISIE, qui met les deux familles d'articles sur la première ligne et leur provenance sur la seconde. Il est reporté tel quel en anglais, à une place qui équilibre la phrase anglaise — pas au même rang de mots, ce qui n'aurait aucun sens.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des accessoires ou des pièces\ndepuis le catalogue.'**
  String get cartEmptyBody;

  /// Onglet de connexion du sélecteur de l'écran d'authentification, et libellé du bouton principal quand cet onglet est actif. Même chaîne que shellSignIn, qui est l'entrée du tiroir vers cet écran ; clé distincte parce que les deux appartiennent à des zones différentes et que le seuil de `common` demande trois sites dans deux zones — ici, deux sites dans une zone plus un dans l'autre.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignInTab;

  /// Onglet d'inscription du sélecteur. Les deux onglets se PARTAGENT UNE LARGEUR D'ÉCRAN à parts égales — un `SegmentedButton` les répartit —, donc c'est le plus long des deux qui décide si le sélecteur tient. L'anglais est plus court sur les deux (« Sign in », « Register »).
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authRegisterTab;

  /// Libellé du champ d'adresse électronique. Identique en anglais, comme shellContactEmail ; clé propre à la zone parce que ce champ-ci porte aussi une validation.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// Message de validation de l'adresse. La règle vérifiée est MINIMALE — la présence d'un arobase — et le message ne prétend pas en dire plus : l'adresse est validée pour de bon par l'envoi, côté serveur.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get authEmailInvalid;

  /// Libellé du champ de mot de passe.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPassword;

  /// Message de validation du mot de passe. SIX EST LE MINIMUM DE FIREBASE, pas une règle de ce dépôt : l'énoncer ici évite un aller-retour au serveur pour un refus prévisible.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get authPasswordTooShort;

  /// Libellé du champ de confirmation, affiché à l'inscription seulement. LE PLUS LONG LIBELLÉ DE CHAMP DE L'ÉCRAN dans les deux langues, et celui qui décide de la largeur utile des étiquettes flottantes.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authPasswordConfirm;

  /// Message de validation de la confirmation. C'est le plus long message de validation de l'écran, et il s'affiche sous un champ de pleine largeur.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get authPasswordMismatch;

  /// Bouton principal quand l'onglet d'inscription est actif. Le bouton de connexion porte authSignInTab, la même chaîne que son onglet.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authCreateAccount;

  /// Mot posé au milieu du filet qui sépare l'identification par mot de passe de celle par Google. Deux lettres en français, deux en anglais, et il est centré entre deux `Divider` extensibles : sa largeur ne contraint rien, mais une chaîne affichée laissée en dur est une chaîne que personne ne retrouvera.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get authOrSeparator;

  /// Bouton d'identification par Google. « Google » est un nom de marque et ne se traduit pas — même règle que « WhatsApp » et « AutoParc ».
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authContinueWithGoogle;

  /// Lien de sortie de l'écran d'authentification, vers l'accueil. C'EST LE PLUS LONG TEXTE DE L'ÉCRAN, il occupe une ligne entière d'un `TextButton` et il n'a aucune ellipse : c'est donc lui qui tronquera le premier si une traduction s'allonge. L'anglais y est PLUS LONG en signes — 39 contre 34 —, ce qui est l'inverse de l'intuition et la raison pour laquelle le banc mesure cet écran dans les deux langues au lieu de supposer.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir le catalogue sans compte'**
  String get authBrowseWithoutAccount;

  /// Confirmation flottante affichée après une connexion réussie. Le NOM vient du compte et n'est pas traduit. L'ESPACE DEVANT LE POINT D'EXCLAMATION EST UNE ESPACE ORDINAIRE (U+0020), relevée telle quelle dans le fichier : la typographie française voudrait une espace fine insécable, et ce lot REPORTE ce qui existe au lieu de le corriger en passant — une correction de ponctuation serait un changement non demandé et invisible en relecture. L'anglais, lui, colle le point d'exclamation, comme sa typographie l'exige.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, {name} !'**
  String authWelcome(String name);

  /// La signature sous le nom de l'application, sur l'écran d'authentification. « AutoParc », juste au-dessus, N'EST PAS DANS LES `.arb` : c'est le nom de la marque. Les points médians et leurs espaces font partie de la valeur. QUATRE MOTS SUR UNE LIGNE À 320 POINTS : c'est la chaîne la plus dense de l'écran, et le banc la mesure dans les deux langues.
  ///
  /// In fr, this message translates to:
  /// **'Vente · Location · Pièces · Accessoires'**
  String get authTagline;

  /// Lien en haut à droite de la démonstration de première utilisation, qui la termine sans la parcourir. Il DISPARAÎT sur la dernière diapositive — il n'y a plus rien à passer —, par opacité et non par retrait, pour que le bouton principal ne remonte pas.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// Bouton principal de la démonstration, sur les deux premières diapositives.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// Bouton principal sur la dernière diapositive, qui termine la démonstration. Il est à PLEINE LARGEUR et sans ellipse, comme onboardingNext : les deux ne tronquent donc que si leur traduction dépasse l'écran entier.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// Titre de la première diapositive de la démonstration. LES TROIS DIAPOSITIVES ÉTAIENT UNE LISTE `const`, construite avant qu'aucune langue soit connue : les six chaînes y seraient restées françaises pour tout le monde.
  ///
  /// In fr, this message translates to:
  /// **'Explorez le catalogue'**
  String get onboardingCatalogTitle;

  /// Corps de la première diapositive. LE RETOUR À LA LIGNE EST ÉCRIT DANS LA VALEUR : il sépare ce que le catalogue contient de la façon de s'y repérer, et le texte est centré — sans lui, la coupure tomberait au milieu de la première phrase. C'est le plus long des trois corps dans les deux langues, donc celui qui décide de la hauteur de la diapositive.
  ///
  /// In fr, this message translates to:
  /// **'Véhicules, pièces et accessoires en un seul endroit.\nFiltrez par type, carrosserie, ville ou disponibilité pour trouver exactement ce qu\'il vous faut.'**
  String get onboardingCatalogBody;

  /// Titre de la deuxième diapositive.
  ///
  /// In fr, this message translates to:
  /// **'Exprimez vos besoins'**
  String get onboardingNeedsTitle;

  /// Corps de la deuxième diapositive. L'ESPACE DEVANT LE POINT D'INTERROGATION EST UNE ESPACE ORDINAIRE (U+0020), relevée telle quelle : ce lot reporte la typographie existante. Le retour à la ligne sépare la question de la réponse.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne trouvez pas votre bonheur ?\nCréez une alerte et recevez une notification dès qu\'un véhicule ou une pièce correspond à votre recherche.'**
  String get onboardingNeedsBody;

  /// Titre de la troisième et dernière diapositive.
  ///
  /// In fr, this message translates to:
  /// **'Votre garage personnel'**
  String get onboardingGarageTitle;

  /// Corps de la dernière diapositive. Le retour à la ligne sépare le bénéfice immédiat de celui qui dure.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos véhicules pour retrouver instantanément les pièces détachées compatibles.\nVotre historique vous suit à chaque visite.'**
  String get onboardingGarageBody;

  /// Titre du bloc qui ÉNUMÈRE les véhicules qu'une pièce ou un accessoire déclare. Il complète catalogGarageSectionTitle, qui confronte l'article au garage du client : l'un énumère, l'autre confronte. Les deux existent parce que le second ne dit rien à qui achète pour la voiture d'un proche, compare avant d'enregistrer son véhicule, ou dont le modèle n'est pas au référentiel.
  ///
  /// In fr, this message translates to:
  /// **'Véhicules compatibles'**
  String get catalogFitmentsTitle;

  /// Avertissement affiché quand TOUTES les compatibilités listées viennent du remplissage automatique du catalogue. Il existe parce qu'un client peut acheter la mauvaise pièce sur une ligne que personne n'a relue : `catalog:backfill-fitments` a fabriqué des compatibilités vraisemblables pour que la recherche par modèle rende quelque chose, et rien ne les distinguait d'une ligne vérifiée.
  ///
  /// In fr, this message translates to:
  /// **'Toutes proposées automatiquement : aucune n\'a été vérifiée.'**
  String get catalogFitmentsAllProposed;

  /// Le même avertissement quand une partie seulement des lignes est automatique. Voir catalogFitmentsAllProposed.
  ///
  /// In fr, this message translates to:
  /// **'{count} sur {total} proposées automatiquement, non vérifiées.'**
  String catalogFitmentsSomeProposed(int count, int total);

  /// Ce qui joint le modèle, la finition et la position sur UNE ligne de compatibilité : « Toyota Corolla · XLE · Avant gauche ». Distinct de catalogCompatibilitySeparator, qui joint deux NOMS DE MODÈLE sur la carte du catalogue : même signe aujourd'hui, deux rôles, et les séparer permet d'en changer un sans auditer l'autre. Les espaces font partie de la valeur — le point médian collé se lit comme une faute.
  ///
  /// In fr, this message translates to:
  /// **' · '**
  String get catalogFitmentSeparator;

  /// Les deux bornes d'années d'une ligne de compatibilité. Le tiret est un DEMI-CADRATIN (U+2013), celui des intervalles, et non un trait d'union. L'espace de tête et les parenthèses font partie de la valeur : elles suivent immédiatement le nom du modèle.
  ///
  /// In fr, this message translates to:
  /// **' ({from} – {to})'**
  String catalogFitmentYearRange(int from, int to);

  /// La borne basse seule d'une ligne de compatibilité : le modèle est compatible à partir de ce millésime, sans fin connue.
  ///
  /// In fr, this message translates to:
  /// **' (depuis {year})'**
  String catalogFitmentYearFrom(int year);

  /// La borne haute seule d'une ligne de compatibilité.
  ///
  /// In fr, this message translates to:
  /// **' (jusqu\'à {year})'**
  String catalogFitmentYearTo(int year);

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
