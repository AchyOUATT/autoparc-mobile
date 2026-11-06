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

  /// Valeur affichée quand aucun kilométrage n'a été renseigné. Un zéro explicitement relevé s'affiche toujours comme 0 km.
  ///
  /// In fr, this message translates to:
  /// **'Kilométrage non renseigné'**
  String get commonMileageNotProvided;

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
  /// **'Boîte de vitesses'**
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

  /// Type de boîte de vitesses. Les codes et libellés des familles sont partagés par les formulaires et les fiches.
  ///
  /// In fr, this message translates to:
  /// **'Manuelle'**
  String get catalogTransmissionManual;

  /// Boîte mécanique à variation continue, distincte du système hybride e-CVT.
  ///
  /// In fr, this message translates to:
  /// **'Variation continue (CVT)'**
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

  /// Titre du formulaire et action de vente.
  ///
  /// In fr, this message translates to:
  /// **'Vendre ma voiture'**
  String get privateSalesSellTitle;

  /// Titre de la liste personnelle du vendeur.
  ///
  /// In fr, this message translates to:
  /// **'Mes annonces'**
  String get privateSalesMineTitle;

  /// Titre de la liste publique des véhicules de particuliers.
  ///
  /// In fr, this message translates to:
  /// **'Voitures de particuliers'**
  String get privateSalesBrowseTitle;

  /// Titre de la file de modération.
  ///
  /// In fr, this message translates to:
  /// **'Valider les annonces'**
  String get privateSalesReviewTitle;

  /// État d’une annonce non soumise.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get privateSalesStatusDraft;

  /// État d’une annonce soumise au personnel.
  ///
  /// In fr, this message translates to:
  /// **'En cours de validation'**
  String get privateSalesStatusPending;

  /// État d’une annonce publique.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get privateSalesStatusPublished;

  /// État d’une annonce refusée avec motif.
  ///
  /// In fr, this message translates to:
  /// **'À corriger'**
  String get privateSalesStatusRejected;

  /// État d’une annonce retirée.
  ///
  /// In fr, this message translates to:
  /// **'Retirée'**
  String get privateSalesStatusWithdrawn;

  /// État d’un véhicule vendu.
  ///
  /// In fr, this message translates to:
  /// **'Vendue'**
  String get privateSalesStatusSold;

  /// Pastille distinguant le vendeur du stock professionnel.
  ///
  /// In fr, this message translates to:
  /// **'Particulier'**
  String get privateSalesPrivateSeller;

  /// Explication des confirmations de retrait ou de vente.
  ///
  /// In fr, this message translates to:
  /// **'L’annonce ne sera plus visible par les acheteurs.'**
  String get privateSalesConfirmRemovalBody;

  /// Action confirmant la vente ou le retrait.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get privateSalesConfirm;

  /// Titre de la boîte de refus.
  ///
  /// In fr, this message translates to:
  /// **'Motif à communiquer au vendeur'**
  String get privateSalesRejectReasonTitle;

  /// Aide de saisie du motif de refus.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez ce qui doit être corrigé.'**
  String get privateSalesRejectReasonHint;

  /// Action de modération pour refuser ou retirer.
  ///
  /// In fr, this message translates to:
  /// **'Refuser / retirer'**
  String get privateSalesRejectAction;

  /// Erreur de modération avant publication d’une annonce sans téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Cette annonce n’indique aucun numéro : elle ne peut pas être publiée. Refusez-la en demandant au vendeur de le renseigner.'**
  String get privateSalesMissingPhonePublication;

  /// Bouton d’appel et titre de confirmation téléphonique.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le vendeur'**
  String get privateSalesCallSeller;

  /// Consigne précise de l’appel de vérification au modérateur.
  ///
  /// In fr, this message translates to:
  /// **'Demandez-lui si c’est bien LUI qui a déposé cette annonce — pas seulement si le numéro est le sien.'**
  String get privateSalesCallCheckInstructions;

  /// Bouton ouvrant le composeur téléphonique dans la modération.
  ///
  /// In fr, this message translates to:
  /// **'Composer'**
  String get privateSalesDial;

  /// Attestation explicite du modérateur avant publication.
  ///
  /// In fr, this message translates to:
  /// **'J’ai appelé ce numéro et le vendeur a confirmé avoir déposé cette annonce.'**
  String get privateSalesCallConfirmed;

  /// Action de publication après modération.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get privateSalesPublish;

  /// Refus d’accès à la modération.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé au personnel chargé du catalogue.'**
  String get privateSalesReviewAccessDenied;

  /// Action de connexion sur la liste personnelle.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter pour gérer mes annonces'**
  String get privateSalesSignInManage;

  /// Infobulle d’actualisation des annonces.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get privateSalesRefresh;

  /// Libellé de recherche publique.
  ///
  /// In fr, this message translates to:
  /// **'Chercher une voiture ou une ville'**
  String get privateSalesSearchHint;

  /// Libellé du filtre de modération.
  ///
  /// In fr, this message translates to:
  /// **'État des annonces'**
  String get privateSalesReviewFilterLabel;

  /// Option de filtre des annonces en attente.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get privateSalesReviewFilterPending;

  /// Option de filtre des annonces publiées.
  ///
  /// In fr, this message translates to:
  /// **'Publiées'**
  String get privateSalesReviewFilterPublished;

  /// Explication de la limite d’une annonce active.
  ///
  /// In fr, this message translates to:
  /// **'Une annonce en cours gratuite. Retirez-la ou marquez-la vendue pour en créer une autre.'**
  String get privateSalesOneActiveListingHint;

  /// Liste personnelle vide.
  ///
  /// In fr, this message translates to:
  /// **'Votre première annonce commence ici.'**
  String get privateSalesEmptyMine;

  /// File de modération vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce à examiner.'**
  String get privateSalesEmptyReview;

  /// Liste publique vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce pour le moment.'**
  String get privateSalesEmptyBrowse;

  /// Bouton de pagination précédent.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get privateSalesPrevious;

  /// Bouton de pagination suivant.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get privateSalesNext;

  /// Action d’édition d’une annonce personnelle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier / compléter'**
  String get privateSalesEdit;

  /// Confirmation de vente.
  ///
  /// In fr, this message translates to:
  /// **'Marquer ce véhicule vendu ?'**
  String get privateSalesConfirmSoldTitle;

  /// Action du vendeur sur une annonce publiée.
  ///
  /// In fr, this message translates to:
  /// **'Marquer vendu'**
  String get privateSalesMarkSold;

  /// Confirmation de retrait.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette annonce ?'**
  String get privateSalesConfirmWithdrawTitle;

  /// Action de retrait du vendeur.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get privateSalesWithdraw;

  /// Information lors d’un préremplissage sans véhicule enregistré.
  ///
  /// In fr, this message translates to:
  /// **'Votre garage est vide. Vous pouvez saisir le véhicule directement ici.'**
  String get privateSalesGarageEmpty;

  /// Titre de la sélection pour préremplir l’annonce.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un véhicule de mon garage'**
  String get privateSalesChooseGarageTitle;

  /// Erreur d’ajout au-delà de dix photos.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez ajouter au plus 10 photos au total.'**
  String get privateSalesPhotosLimit;

  /// Erreur d’envoi d’un formulaire modifié sans sauvegarde.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez vos modifications avant d’envoyer l’annonce.'**
  String get privateSalesSaveBeforeSubmit;

  /// Confirmation de soumission.
  ///
  /// In fr, this message translates to:
  /// **'Annonce envoyée. Vous retrouverez la décision dans « Mes annonces ».'**
  String get privateSalesSubmitted;

  /// Action de connexion avant création.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter pour vendre'**
  String get privateSalesSignInSell;

  /// Refus d’éditer après changement de compte.
  ///
  /// In fr, this message translates to:
  /// **'Le compte a changé. Fermez ce formulaire et rouvrez « Mes annonces ».'**
  String get privateSalesAccountChanged;

  /// En-tête du formulaire.
  ///
  /// In fr, this message translates to:
  /// **'Votre voiture, votre annonce'**
  String get privateSalesFormHeading;

  /// Explication de l’accès aux particuliers.
  ///
  /// In fr, this message translates to:
  /// **'Une annonce en cours gratuite. Aucun compte partenaire nécessaire.'**
  String get privateSalesNoPartnerRequired;

  /// Action de préremplissage.
  ///
  /// In fr, this message translates to:
  /// **'Préremplir depuis mon garage'**
  String get privateSalesPrefillGarage;

  /// Explication de confidentialité du préremplissage.
  ///
  /// In fr, this message translates to:
  /// **'Votre garage reste privé. Seuls les détails du véhicule et ses photos sont publiés.'**
  String get privateSalesGaragePrivacy;

  /// Libellé du prix de l’annonce ; devise inchangée.
  ///
  /// In fr, this message translates to:
  /// **'Prix en FCFA'**
  String get privateSalesPriceLabel;

  /// Libellé de la ville de vente.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get privateSalesCityLabel;

  /// Libellé de la description publique.
  ///
  /// In fr, this message translates to:
  /// **'État du véhicule et informations utiles'**
  String get privateSalesDescriptionLabel;

  /// Nom du vendeur réservé à AutoParc, au propriétaire et à la modération.
  ///
  /// In fr, this message translates to:
  /// **'Nom du vendeur'**
  String get privateSalesSellerNameLabel;

  /// Libellé du numéro de contact.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone avec indicatif'**
  String get privateSalesPhoneLabel;

  /// Interrupteur du canal WhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser AutoParc à me joindre sur WhatsApp'**
  String get privateSalesWhatsappOptIn;

  /// Action d’enregistrement initial.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le brouillon'**
  String get privateSalesSaveDraft;

  /// Action de mise à jour.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get privateSalesSaveChanges;

  /// Avertissement après modification d’une annonce soumise ou publiée.
  ///
  /// In fr, this message translates to:
  /// **'Une modification remettra l’annonce en brouillon et demandera une nouvelle validation.'**
  String get privateSalesChangesNeedReview;

  /// Explication des photos de l’annonce.
  ///
  /// In fr, this message translates to:
  /// **'La première photo sera la couverture. Ajoutez uniquement des photos destinées à être publiques.'**
  String get privateSalesPhotosPrivacy;

  /// Libellé d’une photo enregistrée.
  ///
  /// In fr, this message translates to:
  /// **'Photo du véhicule'**
  String get privateSalesVehiclePhoto;

  /// Infobulle de suppression d’une photo.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get privateSalesDeletePhoto;

  /// Action de sélection de photos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get privateSalesAddPhotos;

  /// Titre de la section de consentement.
  ///
  /// In fr, this message translates to:
  /// **'Avant la mise en ligne'**
  String get privateSalesBeforePublication;

  /// Explication de la vérification humaine du téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Une personne d’AutoParc vous appellera au numéro indiqué pour confirmer que l’annonce vient bien de vous. Votre numéro reste réservé à AutoParc.'**
  String get privateSalesPhoneCallNotice;

  /// Confirmation de propriété ou d’autorisation de vente.
  ///
  /// In fr, this message translates to:
  /// **'Je suis propriétaire de ce véhicule ou autorisé à le vendre.'**
  String get privateSalesOwnerConfirmation;

  /// Consentement au contact privé par AutoParc pour le traitement de l’annonce.
  ///
  /// In fr, this message translates to:
  /// **'J’autorise AutoParc à me contacter au sujet de cette annonce. Mon nom et mon numéro ne sont pas rendus publics.'**
  String get privateSalesContactConsent;

  /// Action de soumission d’un brouillon.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer pour validation'**
  String get privateSalesSubmit;

  /// Validation d’un champ obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez ce champ.'**
  String get privateSalesRequiredField;

  /// Validation de longueur minimale de la description.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le véhicule en au moins 20 caractères.'**
  String get privateSalesDescriptionTooShort;

  /// Validation du format téléphonique international.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le numéro avec l’indicatif, par exemple +22670000000.'**
  String get privateSalesPhoneInvalid;

  /// Validation d’un champ numérique.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nombre entier valide.'**
  String get privateSalesIntegerInvalid;

  /// Validation de l’année commerciale.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’année.'**
  String get privateSalesYearInvalid;

  /// Titre de la fiche publique ou personnelle.
  ///
  /// In fr, this message translates to:
  /// **'Annonce de particulier'**
  String get privateSalesDetailTitle;

  /// Infobulle du bouton de partage.
  ///
  /// In fr, this message translates to:
  /// **'Partager l’annonce'**
  String get privateSalesShare;

  /// Libellé du carburant dans l’identité du véhicule.
  ///
  /// In fr, this message translates to:
  /// **'Carburant'**
  String get privateSalesFuel;

  /// Libellé de motricité dans l’identité du véhicule.
  ///
  /// In fr, this message translates to:
  /// **'Roues motrices'**
  String get privateSalesDrivetrain;

  /// Indication d’une vérification du numéro par le personnel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone vérifié'**
  String get privateSalesPhoneVerified;

  /// Information de la fiche sur l’absence d’inspection.
  ///
  /// In fr, this message translates to:
  /// **'Le véhicule n’a pas été inspecté par AutoParc.'**
  String get privateSalesNotInspected;

  /// Bouton de contact WhatsApp du vendeur.
  ///
  /// In fr, this message translates to:
  /// **'Contacter sur WhatsApp'**
  String get privateSalesContactWhatsapp;

  /// Explication du canal de contact public des annonces de particuliers.
  ///
  /// In fr, this message translates to:
  /// **'Pour cette annonce, contactez AutoParc. Les coordonnées du vendeur restent privées.'**
  String get privateSalesAutoParcContactNotice;

  /// Action publique pour joindre AutoParc au sujet d’une annonce.
  ///
  /// In fr, this message translates to:
  /// **'Appeler AutoParc'**
  String get privateSalesCallAutoParc;

  /// Action publique pour envoyer à AutoParc un message identifiant l’annonce.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp AutoParc'**
  String get privateSalesWhatsappAutoParc;

  /// Message WhatsApp public adressé à AutoParc, sans coordonnées personnelles du vendeur.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour AutoParc, je souhaite des informations sur cette annonce : {title}\n{url}'**
  String privateSalesAutoParcMessage(String title, String url);

  /// Libellé de la marque obligatoire dans le formulaire.
  ///
  /// In fr, this message translates to:
  /// **'Marque *'**
  String get privateSalesBrandRequiredLabel;

  /// Validation de la marque.
  ///
  /// In fr, this message translates to:
  /// **'Marque obligatoire'**
  String get privateSalesBrandRequiredError;

  /// Libellé du modèle obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Modèle *'**
  String get privateSalesModelRequiredLabel;

  /// Validation du choix du modèle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un modèle ou saisissez le vôtre.'**
  String get privateSalesModelSelectionError;

  /// Aide de saisie du modèle absent du catalogue.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le nom de votre modèle'**
  String get privateSalesFreeModelHint;

  /// Validation du modèle libre.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez le modèle.'**
  String get privateSalesFreeModelRequired;

  /// Action quittant le modèle libre.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à la liste des modèles'**
  String get privateSalesModelListAction;

  /// Action de saisie d’un modèle libre.
  ///
  /// In fr, this message translates to:
  /// **'Mon modèle n’est pas dans la liste'**
  String get privateSalesFreeModelAction;

  /// Libellé de l’année de fabrication obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Année de fabrication *'**
  String get privateSalesManufactureYearLabel;

  /// Validation de l’année de fabrication.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’année de fabrication.'**
  String get privateSalesManufactureYearInvalid;

  /// Validation du kilométrage.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un kilométrage valide.'**
  String get privateSalesMileageInvalid;

  /// Action de remise à zéro de la finition.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la finition'**
  String get privateSalesClearTrim;

  /// Action de remise à zéro du carburant.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le carburant'**
  String get privateSalesClearFuel;

  /// Action de remise à zéro de la motricité.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la motricité'**
  String get privateSalesClearDrivetrain;

  /// Action de remise à zéro de la couleur.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la couleur'**
  String get privateSalesClearColour;

  /// Libellé du choix facultatif de boîte.
  ///
  /// In fr, this message translates to:
  /// **'Boîte de vitesses (facultatif)'**
  String get privateSalesTransmissionOptional;

  /// Type de boîte à double embrayage.
  ///
  /// In fr, this message translates to:
  /// **'Double embrayage (DCT)'**
  String get privateSalesTransmissionDualClutch;

  /// Type de transmission à rapport unique.
  ///
  /// In fr, this message translates to:
  /// **'Rapport unique'**
  String get privateSalesTransmissionSingleSpeed;

  /// Action de remise à zéro de la boîte.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la boîte'**
  String get privateSalesClearTransmission;

  /// Motif de correction transmis par la modération.
  ///
  /// In fr, this message translates to:
  /// **'À corriger : {reason}'**
  String privateSalesReviewReason(String reason);

  /// Titre du bloc photos avec nombre actuel.
  ///
  /// In fr, this message translates to:
  /// **'Photos ({count}/10)'**
  String privateSalesPhotosHeading(int count);

  /// Numéro confirmé par le personnel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro vérifié : {number}'**
  String privateSalesVerifiedNumber(String number);

  /// Avertissement d’incohérence année/génération.
  ///
  /// In fr, this message translates to:
  /// **'Cette génération est indiquée {years}. Vérifiez le modèle et l’année.'**
  String privateSalesGenerationWarning(String years);

  /// Résumé du véhicule ; valeurs et unité métrique inchangées.
  ///
  /// In fr, this message translates to:
  /// **'{year} · {mileage} km · {city}'**
  String privateSalesVehicleSummary(int year, int mileage, String city);

  /// Numéro de page et dernière page des annonces.
  ///
  /// In fr, this message translates to:
  /// **'{page} / {lastPage}'**
  String privateSalesPagination(int page, int lastPage);

  /// Présentation d’une caractéristique libellée.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {value}'**
  String privateSalesFieldValue(String label, String value);

  /// Interface partenaire : partnerAccountsPromotionStartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Début de la promotion'**
  String get partnerAccountsPromotionStartTitle;

  /// Interface partenaire : partnerAccountsPromotionEndTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fin de la promotion'**
  String get partnerAccountsPromotionEndTitle;

  /// Interface partenaire : partnerAccountsPromotionEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en promotion'**
  String get partnerAccountsPromotionEnabled;

  /// Interface partenaire : partnerAccountsPromotionPriceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez d’abord un prix de vente.'**
  String get partnerAccountsPromotionPriceRequired;

  /// Interface partenaire : partnerAccountsPromotionDurationHelp.
  ///
  /// In fr, this message translates to:
  /// **'Pendant une durée que vous choisissez.'**
  String get partnerAccountsPromotionDurationHelp;

  /// Interface partenaire : partnerAccountsPromotionPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix pendant la promotion (FCFA)'**
  String get partnerAccountsPromotionPrice;

  /// Interface partenaire : partnerAccountsPromotionPriceInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le prix promotionnel doit être inférieur au prix normal.'**
  String get partnerAccountsPromotionPriceInvalid;

  /// Interface partenaire : partnerAccountsPromotionDiscountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Remise trop forte.'**
  String get partnerAccountsPromotionDiscountInvalid;

  /// Interface partenaire : partnerAccountsPromotionStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get partnerAccountsPromotionStart;

  /// Interface partenaire : partnerAccountsPromotionEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get partnerAccountsPromotionEnd;

  /// Interface partenaire : partnerAccountsMarginYourPrice.
  ///
  /// In fr, this message translates to:
  /// **'Votre prix'**
  String get partnerAccountsMarginYourPrice;

  /// Interface partenaire : partnerAccountsMarginPublicPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix affiché à l’acheteur'**
  String get partnerAccountsMarginPublicPrice;

  /// Interface partenaire : partnerAccountsMarginLockedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ce total est figé au moment où vous enregistrez.'**
  String get partnerAccountsMarginLockedHelp;

  /// Interface partenaire : partnerAccountsSpaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace partenaire'**
  String get partnerAccountsSpaceTitle;

  /// Interface partenaire : partnerAccountsCompanyIntro.
  ///
  /// In fr, this message translates to:
  /// **'Présentez votre entreprise'**
  String get partnerAccountsCompanyIntro;

  /// Interface partenaire : partnerAccountsActivityIntro.
  ///
  /// In fr, this message translates to:
  /// **'Développez votre activité'**
  String get partnerAccountsActivityIntro;

  /// Interface partenaire : partnerAccountsRegisterIntro.
  ///
  /// In fr, this message translates to:
  /// **'Après validation de votre compte, publiez vos véhicules, pièces et accessoires.'**
  String get partnerAccountsRegisterIntro;

  /// Interface partenaire : partnerAccountsLoginIntro.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos annonces de vente et de location dans votre espace professionnel.'**
  String get partnerAccountsLoginIntro;

  /// Interface partenaire : partnerAccountsLoginTab.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get partnerAccountsLoginTab;

  /// Interface partenaire : partnerAccountsRegisterTab.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get partnerAccountsRegisterTab;

  /// Interface partenaire : partnerAccountsCompanyOptional.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’entreprise (facultatif)'**
  String get partnerAccountsCompanyOptional;

  /// Interface partenaire : partnerAccountsCompanyFallbackHelp.
  ///
  /// In fr, this message translates to:
  /// **'Sans entreprise, vos annonces porteront votre nom.'**
  String get partnerAccountsCompanyFallbackHelp;

  /// Interface partenaire : partnerAccountsContactName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du responsable'**
  String get partnerAccountsContactName;

  /// Interface partenaire : partnerAccountsBusinessPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone professionnel'**
  String get partnerAccountsBusinessPhone;

  /// Interface partenaire : partnerAccountsWhatsappOptional.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp (facultatif)'**
  String get partnerAccountsWhatsappOptional;

  /// Interface partenaire : partnerAccountsEmailOptional.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email (facultatif)'**
  String get partnerAccountsEmailOptional;

  /// Interface partenaire : partnerAccountsPhoneLoginHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vous vous connecterez avec votre numéro de téléphone.'**
  String get partnerAccountsPhoneLoginHelp;

  /// Interface partenaire : partnerAccountsInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez une adresse email valide.'**
  String get partnerAccountsInvalidEmail;

  /// Interface partenaire : partnerAccountsLoginIdentifier.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone ou adresse email'**
  String get partnerAccountsLoginIdentifier;

  /// Interface partenaire : partnerAccountsIdentifierRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre numéro ou votre adresse email.'**
  String get partnerAccountsIdentifierRequired;

  /// Interface partenaire : partnerAccountsIdentifierInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un numéro de téléphone ou une adresse email.'**
  String get partnerAccountsIdentifierInvalid;

  /// Interface partenaire : partnerAccountsPasswordHelp.
  ///
  /// In fr, this message translates to:
  /// **'12 caractères minimum, avec des lettres et des chiffres.'**
  String get partnerAccountsPasswordHelp;

  /// Interface partenaire : partnerAccountsShowPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get partnerAccountsShowPassword;

  /// Interface partenaire : partnerAccountsHidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get partnerAccountsHidePassword;

  /// Interface partenaire : partnerAccountsPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre mot de passe.'**
  String get partnerAccountsPasswordRequired;

  /// Interface partenaire : partnerAccountsPasswordInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez au moins 12 caractères, des lettres et des chiffres.'**
  String get partnerAccountsPasswordInvalid;

  /// Interface partenaire : partnerAccountsPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get partnerAccountsPasswordMismatch;

  /// Interface partenaire : partnerAccountsRestoreSession.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer de restaurer ma session'**
  String get partnerAccountsRestoreSession;

  /// Interface partenaire : partnerAccountsRequestAccount.
  ///
  /// In fr, this message translates to:
  /// **'Demander mon compte partenaire'**
  String get partnerAccountsRequestAccount;

  /// Interface partenaire : partnerAccountsPublishingAfterApproval.
  ///
  /// In fr, this message translates to:
  /// **'La publication devient disponible après validation de votre entreprise.'**
  String get partnerAccountsPublishingAfterApproval;

  /// Interface partenaire : partnerAccountsRequiredField.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get partnerAccountsRequiredField;

  /// Interface partenaire : partnerAccountsStatusUnconfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Statut à confirmer…'**
  String get partnerAccountsStatusUnconfirmed;

  /// Interface partenaire : partnerAccountsAccountApproved.
  ///
  /// In fr, this message translates to:
  /// **'Compte approuvé'**
  String get partnerAccountsAccountApproved;

  /// Interface partenaire : partnerAccountsCreateListingHelp.
  ///
  /// In fr, this message translates to:
  /// **'Créez une annonce, ajoutez vos photos puis publiez-la. Vos coordonnées accompagneront vos annonces.'**
  String get partnerAccountsCreateListingHelp;

  /// Interface partenaire : partnerAccountsSaleAndRental.
  ///
  /// In fr, this message translates to:
  /// **'Vente et location'**
  String get partnerAccountsSaleAndRental;

  /// Interface partenaire : partnerAccountsInventorySummary.
  ///
  /// In fr, this message translates to:
  /// **'Prix, disponibilité et stock'**
  String get partnerAccountsInventorySummary;

  /// Interface partenaire : partnerAccountsCustomerRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes clients'**
  String get partnerAccountsCustomerRequests;

  /// Interface partenaire : partnerAccountsCustomerRequestsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce que la boutique vous transmet'**
  String get partnerAccountsCustomerRequestsSubtitle;

  /// Interface partenaire : partnerAccountsRefreshAccount.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser mon compte'**
  String get partnerAccountsRefreshAccount;

  /// Interface partenaire : partnerAccountsRejectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée'**
  String get partnerAccountsRejectedTitle;

  /// Interface partenaire : partnerAccountsRejectedDescription.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande n’a pas été approuvée. Consultez le motif ci-dessous.'**
  String get partnerAccountsRejectedDescription;

  /// Interface partenaire : partnerAccountsSuspendedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu'**
  String get partnerAccountsSuspendedTitle;

  /// Interface partenaire : partnerAccountsSuspendedDescription.
  ///
  /// In fr, this message translates to:
  /// **'La gestion et la publication de vos annonces sont suspendues.'**
  String get partnerAccountsSuspendedDescription;

  /// Interface partenaire : partnerAccountsReceivedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription reçue'**
  String get partnerAccountsReceivedTitle;

  /// Interface partenaire : partnerAccountsReceivedDescription.
  ///
  /// In fr, this message translates to:
  /// **'Votre entreprise est en attente de validation. Vous pourrez gérer vos annonces après approbation.'**
  String get partnerAccountsReceivedDescription;

  /// Interface partenaire : partnerAccountsRefreshing.
  ///
  /// In fr, this message translates to:
  /// **'Actualisation…'**
  String get partnerAccountsRefreshing;

  /// Interface partenaire : partnerAccountsCheckStatus.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier mon statut'**
  String get partnerAccountsCheckStatus;

  /// Interface partenaire : partnerAccountsBackToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à la connexion'**
  String get partnerAccountsBackToLogin;

  /// Interface partenaire : partnerAccountsPendingStatus.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get partnerAccountsPendingStatus;

  /// Interface partenaire : partnerAccountsApprovedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Approuvés'**
  String get partnerAccountsApprovedStatus;

  /// Interface partenaire : partnerAccountsRejectedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Refusés'**
  String get partnerAccountsRejectedStatus;

  /// Interface partenaire : partnerAccountsSuspendedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Suspendus'**
  String get partnerAccountsSuspendedStatus;

  /// Interface partenaire : partnerAccountsRejectApplication.
  ///
  /// In fr, this message translates to:
  /// **'Refuser la demande'**
  String get partnerAccountsRejectApplication;

  /// Interface partenaire : partnerAccountsSuspendAccount.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre le compte'**
  String get partnerAccountsSuspendAccount;

  /// Interface partenaire : partnerAccountsReviewReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif communiqué au partenaire'**
  String get partnerAccountsReviewReasonLabel;

  /// Interface partenaire : partnerAccountsReviewReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Précisez le motif de cette décision.'**
  String get partnerAccountsReviewReasonRequired;

  /// Interface partenaire : partnerAccountsConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get partnerAccountsConfirm;

  /// Interface partenaire : partnerAccountsApplicationIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Cette candidature est incomplète. Rafraîchissez la liste.'**
  String get partnerAccountsApplicationIncomplete;

  /// Interface partenaire : partnerAccountsDecisionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Décision enregistrée.'**
  String get partnerAccountsDecisionSaved;

  /// Interface partenaire : partnerAccountsApplicationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Validation des partenaires'**
  String get partnerAccountsApplicationsTitle;

  /// Interface partenaire : partnerAccountsManagerOnly.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé aux responsables.'**
  String get partnerAccountsManagerOnly;

  /// Interface partenaire : partnerAccountsApplicationsFilter.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get partnerAccountsApplicationsFilter;

  /// Interface partenaire : partnerAccountsNoApplications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande dans cette catégorie.'**
  String get partnerAccountsNoApplications;

  /// Interface partenaire : partnerAccountsPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get partnerAccountsPrevious;

  /// Interface partenaire : partnerAccountsNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get partnerAccountsNext;

  /// Interface partenaire : partnerAccountsUnnamedCompany.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise sans nom'**
  String get partnerAccountsUnnamedCompany;

  /// Interface partenaire : partnerAccountsMissingContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact non renseigné'**
  String get partnerAccountsMissingContact;

  /// Interface partenaire : partnerAccountsMissingPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone non renseigné'**
  String get partnerAccountsMissingPhone;

  /// Interface partenaire : partnerAccountsReactivate.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get partnerAccountsReactivate;

  /// Interface partenaire : partnerAccountsApprove.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get partnerAccountsApprove;

  /// Interface partenaire : partnerAccountsReject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get partnerAccountsReject;

  /// Interface partenaire : partnerAccountsSuspend.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre'**
  String get partnerAccountsSuspend;

  /// Interface partenaire : partnerAccountsListingIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Cette annonce est incomplète. Rafraîchissez la liste.'**
  String get partnerAccountsListingIncomplete;

  /// Interface partenaire : partnerAccountsArchiveQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Archiver cette annonce ?'**
  String get partnerAccountsArchiveQuestion;

  /// Interface partenaire : partnerAccountsArchiveDescription.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera retirée de votre inventaire et du catalogue public.'**
  String get partnerAccountsArchiveDescription;

  /// Interface partenaire : partnerAccountsArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get partnerAccountsArchive;

  /// Interface partenaire : partnerAccountsAdjustStock.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster le stock'**
  String get partnerAccountsAdjustStock;

  /// Interface partenaire : partnerAccountsAvailableQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité disponible'**
  String get partnerAccountsAvailableQuantity;

  /// Interface partenaire : partnerAccountsQuantityInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez une quantité valide.'**
  String get partnerAccountsQuantityInvalid;

  /// Interface partenaire : partnerAccountsSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get partnerAccountsSave;

  /// Interface partenaire : partnerAccountsListingFallback.
  ///
  /// In fr, this message translates to:
  /// **'Annonce'**
  String get partnerAccountsListingFallback;

  /// Interface partenaire : partnerAccountsRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get partnerAccountsRefresh;

  /// Interface partenaire : partnerAccountsCreateListing.
  ///
  /// In fr, this message translates to:
  /// **'Créer une annonce'**
  String get partnerAccountsCreateListing;

  /// Interface partenaire : partnerAccountsSearchListings.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans mes annonces'**
  String get partnerAccountsSearchListings;

  /// Interface partenaire : partnerAccountsSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get partnerAccountsSearch;

  /// Interface partenaire : partnerAccountsInventoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre inventaire commence ici'**
  String get partnerAccountsInventoryEmpty;

  /// Interface partenaire : partnerAccountsNoMatchingListings.
  ///
  /// In fr, this message translates to:
  /// **'Aucune annonce correspondante'**
  String get partnerAccountsNoMatchingListings;

  /// Interface partenaire : partnerAccountsInventoryEmptyHelp.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre annonce, ajoutez ses photos puis choisissez de la publier.'**
  String get partnerAccountsInventoryEmptyHelp;

  /// Interface partenaire : partnerAccountsCreateFirstListing.
  ///
  /// In fr, this message translates to:
  /// **'Créer ma première annonce'**
  String get partnerAccountsCreateFirstListing;

  /// Interface partenaire : partnerAccountsPreviousPage.
  ///
  /// In fr, this message translates to:
  /// **'Page précédente'**
  String get partnerAccountsPreviousPage;

  /// Interface partenaire : partnerAccountsNextPage.
  ///
  /// In fr, this message translates to:
  /// **'Page suivante'**
  String get partnerAccountsNextPage;

  /// Interface partenaire : partnerAccountsManageListing.
  ///
  /// In fr, this message translates to:
  /// **'Gérer cette annonce'**
  String get partnerAccountsManageListing;

  /// Interface partenaire : partnerAccountsManagePhotos.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les photos'**
  String get partnerAccountsManagePhotos;

  /// Interface partenaire : partnerAccountsMakeAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Rendre disponible'**
  String get partnerAccountsMakeAvailable;

  /// Interface partenaire : partnerAccountsMakeUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Marquer indisponible'**
  String get partnerAccountsMakeUnavailable;

  /// Interface partenaire : partnerAccountsPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publiée'**
  String get partnerAccountsPublished;

  /// Interface partenaire : partnerAccountsDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get partnerAccountsDraft;

  /// Interface partenaire : partnerAccountsWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get partnerAccountsWithdraw;

  /// Interface partenaire : partnerAccountsPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get partnerAccountsPublish;

  /// Interface partenaire : partnerAccountsRequestFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de terminer la demande. Vérifiez votre connexion et réessayez.'**
  String get partnerAccountsRequestFailed;

  /// Interface partenaire : partnerAccountsPriceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un prix.'**
  String get partnerAccountsPriceRequired;

  /// Interface partenaire : partnerAccountsMoneyInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un montant positif ou nul.'**
  String get partnerAccountsMoneyInvalid;

  /// Interface partenaire : partnerAccountsNotProvided.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get partnerAccountsNotProvided;

  /// Interface partenaire : partnerAccountsChoiceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une valeur.'**
  String get partnerAccountsChoiceRequired;

  /// Interface partenaire : partnerAccountsEditListingHelp.
  ///
  /// In fr, this message translates to:
  /// **'Mettez à jour votre annonce.'**
  String get partnerAccountsEditListingHelp;

  /// Interface partenaire : partnerAccountsNewListingHelp.
  ///
  /// In fr, this message translates to:
  /// **'L’annonce sera créée en brouillon. Vous pourrez ensuite ajouter ses photos et la publier.'**
  String get partnerAccountsNewListingHelp;

  /// Interface partenaire : partnerAccountsSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get partnerAccountsSaving;

  /// Interface partenaire : partnerAccountsSaveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get partnerAccountsSaveChanges;

  /// Interface partenaire : partnerAccountsSaveDraft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le brouillon'**
  String get partnerAccountsSaveDraft;

  /// Interface partenaire : partnerAccountsItemName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’article'**
  String get partnerAccountsItemName;

  /// Interface partenaire : partnerAccountsNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un nom.'**
  String get partnerAccountsNameRequired;

  /// Interface partenaire : partnerAccountsPartCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie de pièce'**
  String get partnerAccountsPartCategory;

  /// Interface partenaire : partnerAccountsPartOrigin.
  ///
  /// In fr, this message translates to:
  /// **'Origine de la pièce'**
  String get partnerAccountsPartOrigin;

  /// Interface partenaire : partnerAccountsPartOem.
  ///
  /// In fr, this message translates to:
  /// **'Constructeur (OEM)'**
  String get partnerAccountsPartOem;

  /// Interface partenaire : partnerAccountsPartOes.
  ///
  /// In fr, this message translates to:
  /// **'Équipementier (OES)'**
  String get partnerAccountsPartOes;

  /// Interface partenaire : partnerAccountsPartAftermarket.
  ///
  /// In fr, this message translates to:
  /// **'Adaptable'**
  String get partnerAccountsPartAftermarket;

  /// Interface partenaire : partnerAccountsPartSalvage.
  ///
  /// In fr, this message translates to:
  /// **'Pièce de récupération'**
  String get partnerAccountsPartSalvage;

  /// Interface partenaire : partnerAccountsCondition.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get partnerAccountsCondition;

  /// Interface partenaire : partnerAccountsConditionNew.
  ///
  /// In fr, this message translates to:
  /// **'Neuve'**
  String get partnerAccountsConditionNew;

  /// Interface partenaire : partnerAccountsConditionRefurbished.
  ///
  /// In fr, this message translates to:
  /// **'Reconditionnée'**
  String get partnerAccountsConditionRefurbished;

  /// Interface partenaire : partnerAccountsConditionUsed.
  ///
  /// In fr, this message translates to:
  /// **'D’occasion'**
  String get partnerAccountsConditionUsed;

  /// Interface partenaire : partnerAccountsDonorRequiredHelp.
  ///
  /// In fr, this message translates to:
  /// **'Une pièce d’occasion doit être rattachée à un véhicule donneur de votre propre inventaire.'**
  String get partnerAccountsDonorRequiredHelp;

  /// Interface partenaire : partnerAccountsReloadDonors.
  ///
  /// In fr, this message translates to:
  /// **'Recharger les véhicules donneurs'**
  String get partnerAccountsReloadDonors;

  /// Interface partenaire : partnerAccountsDonorsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d’abord le véhicule donneur dans vos annonces de véhicules.'**
  String get partnerAccountsDonorsEmpty;

  /// Interface partenaire : partnerAccountsDonorVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule donneur'**
  String get partnerAccountsDonorVehicle;

  /// Interface partenaire : partnerAccountsManufacturerReferenceOptional.
  ///
  /// In fr, this message translates to:
  /// **'Référence fabricant (facultatif)'**
  String get partnerAccountsManufacturerReferenceOptional;

  /// Interface partenaire : partnerAccountsAccessoryCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie d’accessoire'**
  String get partnerAccountsAccessoryCategory;

  /// Interface partenaire : partnerAccountsManufacturerOptional.
  ///
  /// In fr, this message translates to:
  /// **'Fabricant (facultatif)'**
  String get partnerAccountsManufacturerOptional;

  /// Interface partenaire : partnerAccountsSkuOptional.
  ///
  /// In fr, this message translates to:
  /// **'Référence interne / SKU (facultatif)'**
  String get partnerAccountsSkuOptional;

  /// Interface partenaire : partnerAccountsSalePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente (FCFA)'**
  String get partnerAccountsSalePrice;

  /// Interface partenaire : partnerAccountsStockQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité en stock'**
  String get partnerAccountsStockQuantity;

  /// Interface partenaire : partnerAccountsStockInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un nombre entier positif ou nul.'**
  String get partnerAccountsStockInvalid;

  /// Interface partenaire : partnerAccountsPhotosTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photos de l’annonce'**
  String get partnerAccountsPhotosTitle;

  /// Interface partenaire : partnerAccountsAddPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get partnerAccountsAddPhotos;

  /// Interface partenaire : partnerAccountsPhotosHelp.
  ///
  /// In fr, this message translates to:
  /// **'JPEG, PNG ou WebP. Choisissez une couverture et ordonnez votre galerie.'**
  String get partnerAccountsPhotosHelp;

  /// Interface partenaire : partnerAccountsPhotosEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez les premières photos de votre annonce.'**
  String get partnerAccountsPhotosEmpty;

  /// Interface partenaire : partnerAccountsCover.
  ///
  /// In fr, this message translates to:
  /// **'Couverture'**
  String get partnerAccountsCover;

  /// Interface partenaire : partnerAccountsSetCover.
  ///
  /// In fr, this message translates to:
  /// **'En couverture'**
  String get partnerAccountsSetCover;

  /// Interface partenaire : partnerAccountsMoveBefore.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer avant'**
  String get partnerAccountsMoveBefore;

  /// Interface partenaire : partnerAccountsMoveAfter.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer après'**
  String get partnerAccountsMoveAfter;

  /// Interface partenaire : partnerAccountsDeletePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get partnerAccountsDeletePhoto;

  /// Interface partenaire : partnerAccountsDeletePhotoQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette photo ?'**
  String get partnerAccountsDeletePhotoQuestion;

  /// Interface partenaire : partnerAccountsDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get partnerAccountsDelete;

  /// Interface partenaire : partnerAccountsPhotoLimit.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez au plus 10 photos par envoi.'**
  String get partnerAccountsPhotoLimit;

  /// Interface partenaire : partnerAccountsMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get partnerAccountsMarkAllRead;

  /// Interface partenaire : partnerAccountsNoRequests.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande pour le moment.'**
  String get partnerAccountsNoRequests;

  /// Interface partenaire : partnersEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le partenaire'**
  String get partnersEditTitle;

  /// Interface partenaire : partnersCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau partenaire'**
  String get partnersCreateTitle;

  /// Interface partenaire : partnersSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get partnersSave;

  /// Interface partenaire : partnersCompanySection.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get partnersCompanySection;

  /// Interface partenaire : partnersCompanyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'entreprise *'**
  String get partnersCompanyName;

  /// Interface partenaire : partnersRequiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get partnersRequiredField;

  /// Interface partenaire : partnersContactName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'interlocuteur'**
  String get partnersContactName;

  /// Interface partenaire : partnersContactsSection.
  ///
  /// In fr, this message translates to:
  /// **'Contacts'**
  String get partnersContactsSection;

  /// Interface partenaire : partnersPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone *'**
  String get partnersPhone;

  /// Interface partenaire : partnersWhatsappDifferent.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp (si différent)'**
  String get partnersWhatsappDifferent;

  /// Interface partenaire : partnersEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get partnersEmail;

  /// Interface partenaire : partnersInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide'**
  String get partnersInvalidEmail;

  /// Interface partenaire : partnersNotesSection.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get partnersNotesSection;

  /// Interface partenaire : partnersInternalNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes internes'**
  String get partnersInternalNotes;

  /// Interface partenaire : partnersNotesHint.
  ///
  /// In fr, this message translates to:
  /// **'Spécialité, conditions, horaires…'**
  String get partnersNotesHint;

  /// Interface partenaire : partnersActive.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire actif'**
  String get partnersActive;

  /// Interface partenaire : partnersInactiveHelp.
  ///
  /// In fr, this message translates to:
  /// **'Inactif = masqué dans les listes'**
  String get partnersInactiveHelp;

  /// Interface partenaire : partnersSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, contact, téléphone…'**
  String get partnersSearchHint;

  /// Interface partenaire : partnersNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partenaire trouvé'**
  String get partnersNoResults;

  /// Interface partenaire : partnersDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get partnersDelete;

  /// Interface partenaire : partnersDeleteQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce partenaire ?'**
  String get partnersDeleteQuestion;

  /// Interface partenaire : partnersAttach.
  ///
  /// In fr, this message translates to:
  /// **'Associer'**
  String get partnersAttach;

  /// Interface partenaire : partnersNoLinkedPartners.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partenaire associé.'**
  String get partnersNoLinkedPartners;

  /// Interface partenaire : partnersAttachTitle.
  ///
  /// In fr, this message translates to:
  /// **'Associer un partenaire'**
  String get partnersAttachTitle;

  /// Interface partenaire : partnersPartnerRequired.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire *'**
  String get partnersPartnerRequired;

  /// Interface partenaire : partnersRoleOptional.
  ///
  /// In fr, this message translates to:
  /// **'Rôle (optionnel)'**
  String get partnersRoleOptional;

  /// Interface partenaire : partnersRoleHint.
  ///
  /// In fr, this message translates to:
  /// **'fournisseur, importateur…'**
  String get partnersRoleHint;

  /// Interface partenaire : partnersNotesOptional.
  ///
  /// In fr, this message translates to:
  /// **'Notes (optionnel)'**
  String get partnersNotesOptional;

  /// Interface partenaire : partnersRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get partnersRemove;

  /// Interface partenaire : partnersRemoveQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce partenaire ?'**
  String get partnersRemoveQuestion;

  /// Interface partenaire : partnerAccountsReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String partnerAccountsReason(String reason);

  /// Interface partenaire : partnerAccountsApplicationPagination.
  ///
  /// In fr, this message translates to:
  /// **'Page {page} / {lastPage} · {total} demande(s)'**
  String partnerAccountsApplicationPagination(
    int page,
    int lastPage,
    int total,
  );

  /// Interface partenaire : partnerAccountsMarginIncluded.
  ///
  /// In fr, this message translates to:
  /// **'dont {amount} de marge boutique ({rate} %)'**
  String partnerAccountsMarginIncluded(String amount, String rate);

  /// Interface partenaire : partnerAccountsStockSummary.
  ///
  /// In fr, this message translates to:
  /// **'Stock : {quantity}'**
  String partnerAccountsStockSummary(String quantity);

  /// Interface partenaire : partnerAccountsRentalDaily.
  ///
  /// In fr, this message translates to:
  /// **'Location : {amount} / jour'**
  String partnerAccountsRentalDaily(String amount);

  /// Interface partenaire : partnerAccountsRentalMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Location : {amount} / mois'**
  String partnerAccountsRentalMonthly(String amount);

  /// Interface partenaire : partnerAccountsPromotionMaximum.
  ///
  /// In fr, this message translates to:
  /// **'Remise de {maximum} % au maximum.'**
  String partnerAccountsPromotionMaximum(String maximum);

  /// Interface partenaire : partnerAccountsPromotionExceeded.
  ///
  /// In fr, this message translates to:
  /// **'La remise ne peut pas dépasser {maximum} % : celle-ci est de {discount} %.'**
  String partnerAccountsPromotionExceeded(String maximum, String discount);

  /// Interface partenaire : partnerAccountsPromotionPreview.
  ///
  /// In fr, this message translates to:
  /// **'L’acheteur verra −{discount} %, {price} FCFA barré.'**
  String partnerAccountsPromotionPreview(String discount, String price);

  /// Interface partenaire : partnerAccountsMarginRate.
  ///
  /// In fr, this message translates to:
  /// **'Marge boutique ({rate} %)'**
  String partnerAccountsMarginRate(String rate);

  /// Interface partenaire : partnerAccountsMyVehicles.
  ///
  /// In fr, this message translates to:
  /// **'Mes véhicules'**
  String get partnerAccountsMyVehicles;

  /// Interface partenaire : partnerAccountsMyParts.
  ///
  /// In fr, this message translates to:
  /// **'Mes pièces détachées'**
  String get partnerAccountsMyParts;

  /// Interface partenaire : partnerAccountsMyAccessories.
  ///
  /// In fr, this message translates to:
  /// **'Mes accessoires'**
  String get partnerAccountsMyAccessories;

  /// Interface partenaire : partnerAccountsAddPart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une pièce'**
  String get partnerAccountsAddPart;

  /// Interface partenaire : partnerAccountsEditPart.
  ///
  /// In fr, this message translates to:
  /// **'Modifier une pièce'**
  String get partnerAccountsEditPart;

  /// Interface partenaire : partnerAccountsAddAccessory.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un accessoire'**
  String get partnerAccountsAddAccessory;

  /// Interface partenaire : partnerAccountsEditAccessory.
  ///
  /// In fr, this message translates to:
  /// **'Modifier un accessoire'**
  String get partnerAccountsEditAccessory;

  /// Interface partenaire : partnersDeleteDescription.
  ///
  /// In fr, this message translates to:
  /// **'{name} sera retiré de tous les produits.'**
  String partnersDeleteDescription(String name);

  /// Interface partenaire : partnersRemoveDescription.
  ///
  /// In fr, this message translates to:
  /// **'L’association avec {name} sera supprimée.'**
  String partnersRemoveDescription(String name);

  /// Interface partenaire : partnerAccountsNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau et réessayez.'**
  String get partnerAccountsNetworkError;

  /// Interface partenaire : partnerAccountsSessionResponseInvalid.
  ///
  /// In fr, this message translates to:
  /// **'La réponse ne correspond pas à une session partenaire.'**
  String get partnerAccountsSessionResponseInvalid;

  /// Interface partenaire : partnerAccountsSessionInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Cette session partenaire est invalide.'**
  String get partnerAccountsSessionInvalid;

  /// Interface partenaire : partnerAccountsSessionCheckFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier votre session. Réessayez.'**
  String get partnerAccountsSessionCheckFailed;

  /// Interface partenaire : partnerAccountsLoginFailed.
  ///
  /// In fr, this message translates to:
  /// **'La connexion n’a pas abouti. Réessayez.'**
  String get partnerAccountsLoginFailed;

  /// Interface partenaire : partnerAccountsRefreshFailed.
  ///
  /// In fr, this message translates to:
  /// **'Actualisation impossible. Réessayez.'**
  String get partnerAccountsRefreshFailed;

  /// Titre du bloc d’annonces de particuliers sur l’accueil.
  ///
  /// In fr, this message translates to:
  /// **'Les voitures de particuliers'**
  String get privateSalesHomeTitle;

  /// Présentation du parcours de vente particulier.
  ///
  /// In fr, this message translates to:
  /// **'Vendez votre voiture depuis votre compte habituel. Une annonce en cours gratuite.'**
  String get privateSalesHomeBody;

  /// Action d’accès aux annonces publiques.
  ///
  /// In fr, this message translates to:
  /// **'Voir les annonces'**
  String get privateSalesBrowseAction;

  /// Action de vente depuis le garage.
  ///
  /// In fr, this message translates to:
  /// **'Vendre ce véhicule'**
  String get privateSalesSellThisVehicle;

  /// Entrée de modération des inscriptions partenaires.
  ///
  /// In fr, this message translates to:
  /// **'Validation des partenaires'**
  String get shellPartnerApplications;

  /// Entrée du compte et des annonces du partenaire.
  ///
  /// In fr, this message translates to:
  /// **'Espace partenaire'**
  String get shellPartnerSpace;

  /// Erreur réseau commune.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifiez votre réseau puis réessayez.'**
  String get commonErrorNetwork;

  /// Session expirée.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Reconnectez-vous.'**
  String get commonErrorSessionExpired;

  /// Ressource introuvable.
  ///
  /// In fr, this message translates to:
  /// **'Introuvable. L’élément a peut-être été supprimé.'**
  String get commonErrorNotFound;

  /// Envoi de photos trop volumineux.
  ///
  /// In fr, this message translates to:
  /// **'Envoi trop volumineux. Retirez quelques photos ou réduisez-les, puis réessayez.'**
  String get commonErrorUploadTooLarge;

  /// Échec serveur sans détails techniques.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du serveur.'**
  String get commonErrorServer;

  /// Erreur inattendue commune.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get commonErrorGeneric;

  /// Refus de capacité.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle ne permet pas cette action.'**
  String get commonErrorPermission;

  /// Compte désactivé.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte a été désactivé. Contactez le support.'**
  String get commonErrorDisabled;

  /// Indisponibilité temporaire.
  ///
  /// In fr, this message translates to:
  /// **'Service indisponible pour le moment. Réessayez plus tard.'**
  String get commonErrorUnavailable;

  /// Limite de requêtes commune.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez dans quelques minutes.'**
  String get commonErrorThrottled;

  /// Erreur avec référence de requête à communiquer au support.
  ///
  /// In fr, this message translates to:
  /// **'{message} (réf. {reference})'**
  String commonErrorReference(String message, String reference);

  /// Explication de la boîte des demandes clients du partenaire.
  ///
  /// In fr, this message translates to:
  /// **'Les demandes des clients vous parviennent ici dès que la boutique les transmet.'**
  String get partnerAccountsRequestsHelp;

  /// Texte du parcours garage : BrandRequiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une marque.'**
  String get garageBrandRequiredMessage;

  /// Texte du parcours garage : ModelRequiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un modèle, ou tapez le vôtre.'**
  String get garageModelRequiredMessage;

  /// Texte du parcours garage : SignInReminderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un compte pour vos rappels'**
  String get garageSignInReminderTitle;

  /// Texte du parcours garage : SignInReminderBody.
  ///
  /// In fr, this message translates to:
  /// **'Visite technique, assurance, vidange : ces rappels vous sont envoyés, il faut donc savoir à qui.\n\nVotre saisie est conservée.'**
  String get garageSignInReminderBody;

  /// Texte du parcours garage : SignInLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get garageSignInLater;

  /// Texte du parcours garage : SignInAction.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get garageSignInAction;

  /// Texte du parcours garage : SignInCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Connexion annulée — votre saisie est conservée.'**
  String get garageSignInCancelled;

  /// Texte du parcours garage : AddVehicleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à mon garage'**
  String get garageAddVehicleTitle;

  /// Texte du parcours garage : ReferencesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les références : {value0}'**
  String garageReferencesLoadError(String value0);

  /// Texte du parcours garage : IdentitySection.
  ///
  /// In fr, this message translates to:
  /// **'Identification'**
  String get garageIdentitySection;

  /// Texte du parcours garage : BrandRequiredLabel.
  ///
  /// In fr, this message translates to:
  /// **'Marque *'**
  String get garageBrandRequiredLabel;

  /// Texte du parcours garage : SelectPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner…'**
  String get garageSelectPlaceholder;

  /// Texte du parcours garage : BrandRequired.
  ///
  /// In fr, this message translates to:
  /// **'Marque obligatoire'**
  String get garageBrandRequired;

  /// Texte du parcours garage : ModelRequiredLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle *'**
  String get garageModelRequiredLabel;

  /// Texte du parcours garage : SelectBrandFirst.
  ///
  /// In fr, this message translates to:
  /// **'Choisir d\'abord une marque'**
  String get garageSelectBrandFirst;

  /// Texte du parcours garage : ModelRequired.
  ///
  /// In fr, this message translates to:
  /// **'Modèle obligatoire'**
  String get garageModelRequired;

  /// Texte du parcours garage : ModelExample.
  ///
  /// In fr, this message translates to:
  /// **'CX-9, Tribute, Prado…'**
  String get garageModelExample;

  /// Texte du parcours garage : EnterModel.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le modèle'**
  String get garageEnterModel;

  /// Texte du parcours garage : BackToModels.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à la liste des modèles'**
  String get garageBackToModels;

  /// Texte du parcours garage : ModelNotListed.
  ///
  /// In fr, this message translates to:
  /// **'Mon modèle n\'est pas dans la liste'**
  String get garageModelNotListed;

  /// Texte du parcours garage : ManufacturingYearLabel.
  ///
  /// In fr, this message translates to:
  /// **'Année de fabrication *'**
  String get garageManufacturingYearLabel;

  /// Texte du parcours garage : YearRequired.
  ///
  /// In fr, this message translates to:
  /// **'Année obligatoire'**
  String get garageYearRequired;

  /// Texte du parcours garage : InvalidYear.
  ///
  /// In fr, this message translates to:
  /// **'Année invalide'**
  String get garageInvalidYear;

  /// Texte du parcours garage : EngineCompatibilityExplanation.
  ///
  /// In fr, this message translates to:
  /// **'C\'est elle qui détermine quelles pièces vont sur votre véhicule. La finition suffit souvent à la déduire.'**
  String get garageEngineCompatibilityExplanation;

  /// Texte du parcours garage : FuelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Carburant'**
  String get garageFuelLabel;

  /// Texte du parcours garage : OptionalDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails (optionnels)'**
  String get garageOptionalDetails;

  /// Texte du parcours garage : NicknameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Surnom'**
  String get garageNicknameLabel;

  /// Texte du parcours garage : NicknameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Ma Corolla, La familiale…'**
  String get garageNicknameHint;

  /// Texte du parcours garage : RegistrationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plaque d\'immatriculation'**
  String get garageRegistrationLabel;

  /// Texte du parcours garage : RegistrationHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : AA 1234 BF'**
  String get garageRegistrationHint;

  /// Texte du parcours garage : CurrentMileage.
  ///
  /// In fr, this message translates to:
  /// **'Kilométrage actuel'**
  String get garageCurrentMileage;

  /// Texte du parcours garage : Saving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get garageSaving;

  /// Texte du parcours garage : CompatibilityAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Les pièces compatibles avec ce véhicule pourront être filtrées.'**
  String get garageCompatibilityAvailable;

  /// Texte du parcours garage : UnlistedModelCompatibility.
  ///
  /// In fr, this message translates to:
  /// **'Votre modèle n\'étant pas au catalogue, la recherche de pièces compatibles restera indisponible — même en renseignant le carburant.'**
  String get garageUnlistedModelCompatibility;

  /// Texte du parcours garage : MissingEngineCompatibility.
  ///
  /// In fr, this message translates to:
  /// **'Sans cette information, la liste des pièces compatibles restera vide. Vous pourrez la compléter plus tard depuis votre garage.'**
  String get garageMissingEngineCompatibility;

  /// Texte du parcours garage : UnlistedModelServices.
  ///
  /// In fr, this message translates to:
  /// **'Échéances, kilométrage, contrôles et rappels d\'entretien fonctionneront normalement. Seule la recherche de pièces compatibles restera indisponible : elle s\'appuie sur le catalogue. Votre saisie nous aide à l\'enrichir.'**
  String get garageUnlistedModelServices;

  /// Texte du parcours garage : VinAutomaticTitle.
  ///
  /// In fr, this message translates to:
  /// **'Décodage automatique par VIN'**
  String get garageVinAutomaticTitle;

  /// Texte du parcours garage : VinAutomaticExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le VIN (numéro de châssis, 17 caractères) et le formulaire sera pré-rempli automatiquement.'**
  String get garageVinAutomaticExplanation;

  /// Texte du parcours garage : VinLabel.
  ///
  /// In fr, this message translates to:
  /// **'VIN (numéro de châssis)'**
  String get garageVinLabel;

  /// Texte du parcours garage : VinLength.
  ///
  /// In fr, this message translates to:
  /// **'{value0}/17 caractères'**
  String garageVinLength(String value0);

  /// Texte du parcours garage : VinInvalidLength.
  ///
  /// In fr, this message translates to:
  /// **'Le VIN doit faire exactement 17 caractères.'**
  String get garageVinInvalidLength;

  /// Texte du parcours garage : VinDecodeAction.
  ///
  /// In fr, this message translates to:
  /// **'Décoder'**
  String get garageVinDecodeAction;

  /// Texte du parcours garage : VinInvalidTitle.
  ///
  /// In fr, this message translates to:
  /// **'VIN invalide'**
  String get garageVinInvalidTitle;

  /// Texte du parcours garage : VinCompletedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Formulaire pré-rempli'**
  String get garageVinCompletedTitle;

  /// Texte du parcours garage : VinCompletedBody.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez et complétez si nécessaire.'**
  String get garageVinCompletedBody;

  /// Texte du parcours garage : VinPartialTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pré-remplissage partiel'**
  String get garageVinPartialTitle;

  /// Texte du parcours garage : VinPartialBody.
  ///
  /// In fr, this message translates to:
  /// **'Certains champs n\'ont pas pu être résolus — vérifiez.'**
  String get garageVinPartialBody;

  /// Texte du parcours garage : VinLimitedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Données limitées'**
  String get garageVinLimitedTitle;

  /// Texte du parcours garage : VinOfflineYearOnly.
  ///
  /// In fr, this message translates to:
  /// **'API NHTSA inaccessible — seule l\'année a été décodée localement.'**
  String get garageVinOfflineYearOnly;

  /// Texte du parcours garage : VinUnknownModel.
  ///
  /// In fr, this message translates to:
  /// **'Marque ou modèle introuvable dans le catalogue — saisissez manuellement.'**
  String get garageVinUnknownModel;

  /// Texte du parcours garage : VinNoMatchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune correspondance'**
  String get garageVinNoMatchTitle;

  /// Texte du parcours garage : VinNoMatchBody.
  ///
  /// In fr, this message translates to:
  /// **'Remplissez le formulaire manuellement.'**
  String get garageVinNoMatchBody;

  /// Texte du parcours garage : VinTwoYears.
  ///
  /// In fr, this message translates to:
  /// **'Deux années possibles — choisissez :'**
  String get garageVinTwoYears;

  /// Texte du parcours garage : GenerationMismatch.
  ///
  /// In fr, this message translates to:
  /// **'{value0} ne correspond peut-être pas à {value1}.'**
  String garageGenerationMismatch(String value0, String value1);

  /// Texte du parcours garage : GenerationYearMismatch.
  ///
  /// In fr, this message translates to:
  /// **'La {value0} est produite {value1}. Votre véhicule est de {value2}.'**
  String garageGenerationYearMismatch(
    String value0,
    String value1,
    String value2,
  );

  /// Texte du parcours garage : GenerationAlternativeQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Vouliez-vous celle-ci ?'**
  String get garageGenerationAlternativeQuestion;

  /// Texte du parcours garage : GenerationAlternatives.
  ///
  /// In fr, this message translates to:
  /// **'Générations produites en {value0} :'**
  String garageGenerationAlternatives(String value0);

  /// Texte du parcours garage : GenerationNoAlternative.
  ///
  /// In fr, this message translates to:
  /// **'Aucune autre génération de {value0} n\'est enregistrée pour cette année. Vous pouvez continuer : la recherche de pièces sera simplement moins précise.'**
  String garageGenerationNoAlternative(String value0);

  /// Texte du parcours garage : MatchingPartsForVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Pièces — {value0}'**
  String garageMatchingPartsForVehicle(String value0);

  /// Texte du parcours garage : MatchingPartsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pièces compatibles'**
  String get garageMatchingPartsTitle;

  /// Texte du parcours garage : MatchingPartsLimited.
  ///
  /// In fr, this message translates to:
  /// **'Précision limitée — ajoutez la motorisation pour un résultat plus fin.'**
  String get garageMatchingPartsLimited;

  /// Nombre de pièces compatibles trouvées.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 pièce trouvée} other{{count} pièces trouvées}}'**
  String garageMatchingPartsCount(int count);

  /// Texte du parcours garage : UnknownEngineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Motorisation inconnue'**
  String get garageUnknownEngineTitle;

  /// Texte du parcours garage : NoMatchingPartsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pièce déclarée pour ce modèle'**
  String get garageNoMatchingPartsTitle;

  /// Texte du parcours garage : UnknownEngineBody.
  ///
  /// In fr, this message translates to:
  /// **'Sans la motorisation, impossible de savoir quelles pièces vont sur ce véhicule. Renseignez-la, ou saisissez le numéro de série : il la retrouve tout seul.'**
  String get garageUnknownEngineBody;

  /// Texte du parcours garage : NoVehiclePartsBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pièce du catalogue n\'est rattachée à ce véhicule pour le moment.'**
  String get garageNoVehiclePartsBody;

  /// Texte du parcours garage : NoModelPartsBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pièce du catalogue n\'est rattachée à ce modèle — une {value0} — pour le moment.'**
  String garageNoModelPartsBody(String value0);

  /// Texte du parcours garage : CompleteVehicleAction.
  ///
  /// In fr, this message translates to:
  /// **'Compléter mon véhicule'**
  String get garageCompleteVehicleAction;

  /// Texte du parcours garage : BrowseAllPartsAction.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir toutes les pièces'**
  String get garageBrowseAllPartsAction;

  /// Texte du parcours garage : RefillsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passages à la pompe'**
  String get garageRefillsTitle;

  /// Texte du parcours garage : FuelForVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Carburant — {value0}'**
  String garageFuelForVehicle(String value0);

  /// Texte du parcours garage : RefillLabel.
  ///
  /// In fr, this message translates to:
  /// **'Passage'**
  String get garageRefillLabel;

  /// Texte du parcours garage : RefillSaved.
  ///
  /// In fr, this message translates to:
  /// **'Passage enregistré.'**
  String get garageRefillSaved;

  /// Texte du parcours garage : FullRefillExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Plein — la pompe s\'est arrêtée toute seule'**
  String get garageFullRefillExplanation;

  /// Texte du parcours garage : PartialRefill.
  ///
  /// In fr, this message translates to:
  /// **'Demi-plein'**
  String get garagePartialRefill;

  /// Texte du parcours garage : RefillSummary.
  ///
  /// In fr, this message translates to:
  /// **'{value0} km · {value1} l{value2}'**
  String garageRefillSummary(String value0, String value1, String value2);

  /// Texte du parcours garage : FullRefill.
  ///
  /// In fr, this message translates to:
  /// **'Plein'**
  String get garageFullRefill;

  /// Texte du parcours garage : RefillConsumption.
  ///
  /// In fr, this message translates to:
  /// **'{value0} l/100 km{value1}{value2}'**
  String garageRefillConsumption(String value0, String value1, String value2);

  /// Texte du parcours garage : DeleteRefillAction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce passage'**
  String get garageDeleteRefillAction;

  /// Texte du parcours garage : DeleteRefillTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce passage ?'**
  String get garageDeleteRefillTitle;

  /// Texte du parcours garage : RefillDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Passage supprimé.'**
  String get garageRefillDeleted;

  /// Texte du parcours garage : DeleteTwoIntervals.
  ///
  /// In fr, this message translates to:
  /// **'Ce passage ferme une mesure et en ouvre une autre. En le supprimant, ces deux mesures disparaissent et leurs intervalles n\'en font plus qu\'un, deux fois plus long : votre consommation sera recalculée dessus, et elle peut changer beaucoup.'**
  String get garageDeleteTwoIntervals;

  /// Texte du parcours garage : DeleteOneInterval.
  ///
  /// In fr, this message translates to:
  /// **'Ce passage ferme une des mesures retenues. En le supprimant, cette mesure disparaît et votre consommation sera recalculée.'**
  String get garageDeleteOneInterval;

  /// Texte du parcours garage : DeleteRefillLitres.
  ///
  /// In fr, this message translates to:
  /// **'Les litres de ce passage sortiront du calcul et votre consommation sera recalculée.'**
  String get garageDeleteRefillLitres;

  /// Texte du parcours garage : NoRefillsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun passage enregistré'**
  String get garageNoRefillsTitle;

  /// Texte du parcours garage : NoRefillsBody.
  ///
  /// In fr, this message translates to:
  /// **'Notez ce que vous mettez à la pompe : le montant et le prix au litre suffisent. Après deux pleins, l\'application vous dit ce que votre véhicule consomme vraiment, et vous prévient le jour où ça monte.'**
  String get garageNoRefillsBody;

  /// Texte du parcours garage : SignInGarageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à votre garage'**
  String get garageSignInGarageTitle;

  /// Texte du parcours garage : SignInGarageBody.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez rapidement les pièces compatibles avec vos véhicules.'**
  String get garageSignInGarageBody;

  /// Texte du parcours garage : SignInOrRegister.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter / S\'inscrire'**
  String get garageSignInOrRegister;

  /// Texte du parcours garage : Title.
  ///
  /// In fr, this message translates to:
  /// **'Mon garage'**
  String get garageTitle;

  /// Texte du parcours garage : RefreshAction.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get garageRefreshAction;

  /// Texte du parcours garage : AccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get garageAccountTitle;

  /// Texte du parcours garage : AddVehicleAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un véhicule'**
  String get garageAddVehicleAction;

  /// Texte du parcours garage : SignOutAction.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get garageSignOutAction;

  /// Texte du parcours garage : SignedOut.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes déconnecté.'**
  String get garageSignedOut;

  /// Texte du parcours garage : DeleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get garageDeleteAccountTitle;

  /// Texte du parcours garage : AccountDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte et vos données ont été supprimés.'**
  String get garageAccountDeleted;

  /// Texte du parcours garage : AccountDeletionListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Seront supprimés définitivement :'**
  String get garageAccountDeletionListTitle;

  /// Texte du parcours garage : AccountDeletionList.
  ///
  /// In fr, this message translates to:
  /// **'• vos véhicules et leurs échéances\n• vos demandes de recherche\n• vos notifications\n• votre compte de connexion'**
  String get garageAccountDeletionList;

  /// Texte du parcours garage : InvoicesRetained.
  ///
  /// In fr, this message translates to:
  /// **'Les factures des commandes déjà honorées sont conservées, la comptabilité l\'impose.'**
  String get garageInvoicesRetained;

  /// Texte du parcours garage : DeleteAccountConfirmText.
  ///
  /// In fr, this message translates to:
  /// **'Pour confirmer, saisissez {value0} :'**
  String garageDeleteAccountConfirmText(String value0);

  /// Texte du parcours garage : DeletePermanently.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get garageDeletePermanently;

  /// Texte du parcours garage : MileageValue.
  ///
  /// In fr, this message translates to:
  /// **'{value0} km'**
  String garageMileageValue(String value0);

  /// Texte du parcours garage : PreciseCompatibility.
  ///
  /// In fr, this message translates to:
  /// **'Compatibilité précise'**
  String get garagePreciseCompatibility;

  /// Texte du parcours garage : TrackDeadlinesAction.
  ///
  /// In fr, this message translates to:
  /// **'Suivre mes échéances'**
  String get garageTrackDeadlinesAction;

  /// Texte du parcours garage : CheckVehicleAction.
  ///
  /// In fr, this message translates to:
  /// **'Contrôler mon véhicule'**
  String get garageCheckVehicleAction;

  /// Texte du parcours garage : RepeatCheckAction.
  ///
  /// In fr, this message translates to:
  /// **'Refaire un contrôle'**
  String get garageRepeatCheckAction;

  /// Texte du parcours garage : SellThisVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Vendre ce véhicule'**
  String get garageSellThisVehicle;

  /// Texte du parcours garage : UpdateAction.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get garageUpdateAction;

  /// Texte du parcours garage : CompactThousands.
  ///
  /// In fr, this message translates to:
  /// **'{value0} k'**
  String garageCompactThousands(String value0);

  /// Texte du parcours garage : ServiceMissingBoth.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez le kilométrage ci-dessus, ainsi que le kilométrage actuel du véhicule via « Mettre à jour ».'**
  String get garageServiceMissingBoth;

  /// Texte du parcours garage : ServiceMissingLastMileage.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez le kilométrage de la dernière vidange ci-dessus.'**
  String get garageServiceMissingLastMileage;

  /// Texte du parcours garage : ServiceMissingCurrentMileage.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez le kilométrage actuel du véhicule via « Mettre à jour ».'**
  String get garageServiceMissingCurrentMileage;

  /// Texte du parcours garage : MaintenanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échéances d\'entretien'**
  String get garageMaintenanceTitle;

  /// Texte du parcours garage : MaintenanceReminders.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez prévenu 30 jours avant, puis en cas de dépassement.'**
  String get garageMaintenanceReminders;

  /// Texte du parcours garage : InspectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Visite technique'**
  String get garageInspectionLabel;

  /// Texte du parcours garage : InsuranceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Assurance'**
  String get garageInsuranceLabel;

  /// Texte du parcours garage : OilChangeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vidange'**
  String get garageOilChangeLabel;

  /// Texte du parcours garage : LastOilChangeMileage.
  ///
  /// In fr, this message translates to:
  /// **'Kilométrage de la dernière vidange'**
  String get garageLastOilChangeMileage;

  /// Texte du parcours garage : OilReminderMileageExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Le rappel de vidange dépend du kilométrage que vous tenez à jour.'**
  String get garageOilReminderMileageExplanation;

  /// Texte du parcours garage : ClearAction.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get garageClearAction;

  /// Texte du parcours garage : LastCheckTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dernier contrôle · {value0}'**
  String garageLastCheckTitle(String value0);

  /// Texte du parcours garage : CheckNothingToFix.
  ///
  /// In fr, this message translates to:
  /// **'Rien à reprendre'**
  String get garageCheckNothingToFix;

  /// Texte du parcours garage : CheckOnePointToFix.
  ///
  /// In fr, this message translates to:
  /// **'1 point à reprendre'**
  String get garageCheckOnePointToFix;

  /// Texte du parcours garage : CheckPointsToFix.
  ///
  /// In fr, this message translates to:
  /// **'{value0} points à reprendre'**
  String garageCheckPointsToFix(String value0);

  /// Texte du parcours garage : DaysAgoLower.
  ///
  /// In fr, this message translates to:
  /// **'il y a {value0} jours'**
  String garageDaysAgoLower(String value0);

  /// Texte du parcours garage : LastWeekLower.
  ///
  /// In fr, this message translates to:
  /// **'la semaine dernière'**
  String get garageLastWeekLower;

  /// Texte du parcours garage : WeeksAgoLower.
  ///
  /// In fr, this message translates to:
  /// **'il y a {value0} semaines'**
  String garageWeeksAgoLower(String value0);

  /// Texte du parcours garage : MonthsAgoLower.
  ///
  /// In fr, this message translates to:
  /// **'il y a {value0} mois'**
  String garageMonthsAgoLower(String value0);

  /// Texte du parcours garage : RemoveVehicleAction.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du garage'**
  String get garageRemoveVehicleAction;

  /// Texte du parcours garage : RemoveVehicleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du garage ?'**
  String get garageRemoveVehicleTitle;

  /// Texte du parcours garage : RemoveVehicleBody.
  ///
  /// In fr, this message translates to:
  /// **'{value0} sera retiré de votre garage. Cette action est irréversible.'**
  String garageRemoveVehicleBody(String value0);

  /// Texte du parcours garage : RemoveAction.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get garageRemoveAction;

  /// Texte du parcours garage : EmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre garage est vide'**
  String get garageEmptyTitle;

  /// Texte du parcours garage : EmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos véhicules pour retrouver rapidement les pièces compatibles.'**
  String get garageEmptyBody;

  /// Texte du parcours garage : ProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get garageProfileTitle;

  /// Texte du parcours garage : StaffLabel.
  ///
  /// In fr, this message translates to:
  /// **'Staff'**
  String get garageStaffLabel;

  /// Texte du parcours garage : CheckRejected.
  ///
  /// In fr, this message translates to:
  /// **'Le contrôle n\'a pas été accepté : {value0}\nCorrige la saisie, puis termine à nouveau.'**
  String garageCheckRejected(String value0);

  /// Texte du parcours garage : CheckDeferred.
  ///
  /// In fr, this message translates to:
  /// **'Envoi impossible pour le moment : {value0}\nLe contrôle est gardé sur ce téléphone et repartira dès que le réseau revient.'**
  String garageCheckDeferred(String value0);

  /// Texte du parcours garage : VehicleFallback.
  ///
  /// In fr, this message translates to:
  /// **'Mon véhicule'**
  String get garageVehicleFallback;

  /// Texte du parcours garage : CheckFinishedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle terminé'**
  String get garageCheckFinishedTitle;

  /// Texte du parcours garage : CheckWaitingToSend.
  ///
  /// In fr, this message translates to:
  /// **'Un contrôle rempli n\'est pas encore parti. Il repartira dès que le réseau revient.'**
  String get garageCheckWaitingToSend;

  /// Texte du parcours garage : TripDestinationQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Où vas-tu ?'**
  String get garageTripDestinationQuestion;

  /// Texte du parcours garage : TripOptionDistance.
  ///
  /// In fr, this message translates to:
  /// **'{value0} · {value1} km'**
  String garageTripOptionDistance(String value0, String value1);

  /// Texte du parcours garage : OdometerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Kilométrage au compteur'**
  String get garageOdometerLabel;

  /// Texte du parcours garage : OdometerExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Tu es devant le tableau de bord : c\'est le moment. Sans ce relevé, le rappel de vidange ne peut pas partir.'**
  String get garageOdometerExplanation;

  /// Texte du parcours garage : CheckComposing.
  ///
  /// In fr, this message translates to:
  /// **'Composition…'**
  String get garageCheckComposing;

  /// Texte du parcours garage : ViewCheckItems.
  ///
  /// In fr, this message translates to:
  /// **'Voir ce qu\'il faut vérifier'**
  String get garageViewCheckItems;

  /// Texte du parcours garage : TripCheckItemsExplanation.
  ///
  /// In fr, this message translates to:
  /// **'{value0} points pour ce véhicule et ce trajet. Ils ne sont pas les mêmes pour tous : chacun dit pourquoi il est là.'**
  String garageTripCheckItemsExplanation(String value0);

  /// Texte du parcours garage : SeasonCheckItemsExplanation.
  ///
  /// In fr, this message translates to:
  /// **'{value0} points à vérifier une fois avant la saison, pas à chaque trajet.'**
  String garageSeasonCheckItemsExplanation(String value0);

  /// Texte du parcours garage : ChooseTripAction.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le trajet'**
  String get garageChooseTripAction;

  /// Texte du parcours garage : ChangeTripDistance.
  ///
  /// In fr, this message translates to:
  /// **'Trajet de {value0} km · Modifier'**
  String garageChangeTripDistance(String value0);

  /// Texte du parcours garage : ChangeCheckAction.
  ///
  /// In fr, this message translates to:
  /// **'Changer de contrôle'**
  String get garageChangeCheckAction;

  /// Texte du parcours garage : FinishCheckAction.
  ///
  /// In fr, this message translates to:
  /// **'Terminer le contrôle'**
  String get garageFinishCheckAction;

  /// Texte du parcours garage : CheckOkay.
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get garageCheckOkay;

  /// Texte du parcours garage : CheckWatch.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get garageCheckWatch;

  /// Texte du parcours garage : CheckFault.
  ///
  /// In fr, this message translates to:
  /// **'Défaut'**
  String get garageCheckFault;

  /// Texte du parcours garage : CheckOneUnchecked.
  ///
  /// In fr, this message translates to:
  /// **'1 point n\'a pas été vérifié.'**
  String get garageCheckOneUnchecked;

  /// Texte du parcours garage : CheckUnchecked.
  ///
  /// In fr, this message translates to:
  /// **'{value0} points n\'ont pas été vérifiés.'**
  String garageCheckUnchecked(String value0);

  /// Texte du parcours garage : CheckOdometerRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Compteur relevé : {value0} km'**
  String garageCheckOdometerRecorded(String value0);

  /// Texte du parcours garage : CheckFixNow.
  ///
  /// In fr, this message translates to:
  /// **'À régler'**
  String get garageCheckFixNow;

  /// Texte du parcours garage : CheckCanWait.
  ///
  /// In fr, this message translates to:
  /// **'Peut attendre'**
  String get garageCheckCanWait;

  /// Texte du parcours garage : BackToGarageAction.
  ///
  /// In fr, this message translates to:
  /// **'Revenir au garage'**
  String get garageBackToGarageAction;

  /// Texte du parcours garage : ViewPartsAction.
  ///
  /// In fr, this message translates to:
  /// **'Voir les pièces'**
  String get garageViewPartsAction;

  /// No description provided for @garageConsumptionValue.
  ///
  /// In fr, this message translates to:
  /// **'Référence : {value} L/100 km'**
  String garageConsumptionValue(String value);

  /// Texte du parcours garage : FuelCostValue.
  ///
  /// In fr, this message translates to:
  /// **'{value0} FCFA/100 km'**
  String garageFuelCostValue(String value0);

  /// Nombre de mesures utilisées dans la consommation.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{mesuré sur 1 intervalle} other{mesuré sur {count} intervalles}}'**
  String garageConsumptionMeasuredOn(int count);

  /// Texte du parcours garage : LitresValue.
  ///
  /// In fr, this message translates to:
  /// **'{value0} l'**
  String garageLitresValue(String value0);

  /// Texte du parcours garage : CurrencyValue.
  ///
  /// In fr, this message translates to:
  /// **'{value0} FCFA'**
  String garageCurrencyValue(String value0);

  /// Texte du parcours garage : SinceFirstRefill.
  ///
  /// In fr, this message translates to:
  /// **'depuis votre premier passage'**
  String get garageSinceFirstRefill;

  /// Texte du parcours garage : NeedTwoFullRefills.
  ///
  /// In fr, this message translates to:
  /// **'Deux pleins — pompe arrêtée toute seule — et votre consommation réelle s\'affiche ici.'**
  String get garageNeedTwoFullRefills;

  /// Texte du parcours garage : NeedOneFullRefill.
  ///
  /// In fr, this message translates to:
  /// **'Encore un plein et votre consommation réelle s\'affiche ici.'**
  String get garageNeedOneFullRefill;

  /// Texte du parcours garage : TrackConsumptionAction.
  ///
  /// In fr, this message translates to:
  /// **'Suivre ma consommation'**
  String get garageTrackConsumptionAction;

  /// Texte du parcours garage : TrackConsumptionBody.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez vos passages à la pompe : l\'application calcule ce que vous consommez vraiment.'**
  String get garageTrackConsumptionBody;

  /// Texte du parcours garage : ConsumptionIncreased.
  ///
  /// In fr, this message translates to:
  /// **'Votre consommation a augmenté.'**
  String get garageConsumptionIncreased;

  /// Texte du parcours garage : ConsumptionIncreasedCompared.
  ///
  /// In fr, this message translates to:
  /// **'Votre consommation a augmenté : {value0} l/100 km contre {value1} d\'habitude.'**
  String garageConsumptionIncreasedCompared(String value0, String value1);

  /// Texte du parcours garage : ConsumptionCommonCauses.
  ///
  /// In fr, this message translates to:
  /// **'Filtre à air encrassé, pression des pneus : ce sont les deux causes les plus courantes.'**
  String get garageConsumptionCommonCauses;

  /// Texte du parcours garage : OdometerReplacedExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Compteur remplacé : les passages d\'avant restent dans votre historique, mais n\'entrent plus dans ce calcul.'**
  String get garageOdometerReplacedExplanation;

  /// Texte du parcours garage : OfficialConsumptionUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Cote constructeur inconnue'**
  String get garageOfficialConsumptionUnknown;

  /// Texte du parcours garage : OfficialConsumptionValue.
  ///
  /// In fr, this message translates to:
  /// **'Cote constructeur {value0} l/100 km'**
  String garageOfficialConsumptionValue(String value0);

  /// Texte du parcours garage : SpecifyEngineAction.
  ///
  /// In fr, this message translates to:
  /// **'Préciser'**
  String get garageSpecifyEngineAction;

  /// Texte du parcours garage : ChangeAction.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get garageChangeAction;

  /// Texte du parcours garage : RecordRefillTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passage à la pompe'**
  String get garageRecordRefillTitle;

  /// Texte du parcours garage : RefillHistoryCount.
  ///
  /// In fr, this message translates to:
  /// **'Historique ({value0})'**
  String garageRefillHistoryCount(String value0);

  /// Texte du parcours garage : ConsumptionQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Quelle est ma consommation ?'**
  String get garageConsumptionQuestion;

  /// Texte du parcours garage : OfficialCityHighway.
  ///
  /// In fr, this message translates to:
  /// **'ville {value0} · route {value1}'**
  String garageOfficialCityHighway(String value0, String value1);

  /// Texte du parcours garage : ConsumptionNoModel.
  ///
  /// In fr, this message translates to:
  /// **'Consommation indisponible : le modèle de ce véhicule n\'est pas encore au catalogue.'**
  String get garageConsumptionNoModel;

  /// Texte du parcours garage : EnginesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Liste des motorisations indisponible. Réessayez plus tard.'**
  String get garageEnginesUnavailable;

  /// Texte du parcours garage : NoOfficialConsumption.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée officielle de consommation pour ce modèle.'**
  String get garageNoOfficialConsumption;

  /// Texte du parcours garage : EngineSaved.
  ///
  /// In fr, this message translates to:
  /// **'Motorisation enregistrée.'**
  String get garageEngineSaved;

  /// Texte du parcours garage : EngineForVehicle.
  ///
  /// In fr, this message translates to:
  /// **'Motorisation de votre {value0}'**
  String garageEngineForVehicle(String value0);

  /// Texte du parcours garage : ChooseEngineExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le moteur qui se trouve sous le capot. La finition ne change pas la consommation.'**
  String get garageChooseEngineExplanation;

  /// Texte du parcours garage : EngineSavedCompatibility.
  ///
  /// In fr, this message translates to:
  /// **'Motorisation enregistrée : les pièces compatibles sont à jour.'**
  String get garageEngineSavedCompatibility;

  /// Texte du parcours garage : FuelQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Avec quel carburant roule ce véhicule ?'**
  String get garageFuelQuestion;

  /// Texte du parcours garage : RefillAmountPaid.
  ///
  /// In fr, this message translates to:
  /// **'Montant payé'**
  String get garageRefillAmountPaid;

  /// Texte du parcours garage : RefillPricePerLitre.
  ///
  /// In fr, this message translates to:
  /// **'Prix au litre'**
  String get garageRefillPricePerLitre;

  /// Texte du parcours garage : RefillLitres.
  ///
  /// In fr, this message translates to:
  /// **'Litres pris'**
  String get garageRefillLitres;

  /// Texte du parcours garage : RefillValueUnchanged.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré tel quel.'**
  String get garageRefillValueUnchanged;

  /// Texte du parcours garage : RefillLitresCalculated.
  ///
  /// In fr, this message translates to:
  /// **'Les litres se déduisent du montant et du prix.'**
  String get garageRefillLitresCalculated;

  /// Texte du parcours garage : RefillCalculatedLitres.
  ///
  /// In fr, this message translates to:
  /// **'Soit {value0} l'**
  String garageRefillCalculatedLitres(String value0);

  /// Texte du parcours garage : RefillEnterAmount.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le montant payé'**
  String get garageRefillEnterAmount;

  /// Texte du parcours garage : RefillKnowLitres.
  ///
  /// In fr, this message translates to:
  /// **'Je connais les litres'**
  String get garageRefillKnowLitres;

  /// Texte du parcours garage : RefillFullTankExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Plein = la pompe s\'est arrêtée toute seule. Seul un plein permet de mesurer la consommation.'**
  String get garageRefillFullTankExplanation;

  /// Texte du parcours garage : RefillMileageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le kilométrage au compteur.'**
  String get garageRefillMileageRequired;

  /// Texte du parcours garage : RefillLitresRange.
  ///
  /// In fr, this message translates to:
  /// **'Les litres doivent être compris entre 1 et 200.'**
  String get garageRefillLitresRange;

  /// Texte du parcours garage : RefillImpossibleQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Montant et prix au litre donnent une quantité impossible.'**
  String get garageRefillImpossibleQuantity;

  /// Texte du parcours garage : MileageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un nombre de kilomètres.'**
  String get garageMileageRequired;

  /// Texte du parcours garage : MileageOutOfRange.
  ///
  /// In fr, this message translates to:
  /// **'Ce kilométrage est hors de portée.'**
  String get garageMileageOutOfRange;

  /// Texte du parcours garage : MileageConfirmDecrease.
  ///
  /// In fr, this message translates to:
  /// **'Le compteur affichait {value0} km. Appuyez à nouveau pour enregistrer {value1} km.'**
  String garageMileageConfirmDecrease(String value0, String value1);

  /// Texte du parcours garage : ConfirmAction.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get garageConfirmAction;

  /// Texte du parcours garage : SaveMileageAction.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get garageSaveMileageAction;

  /// Texte du parcours needs : MyNeedsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes besoins'**
  String get needsMyNeedsTitle;

  /// Texte du parcours needs : NewNeedAction.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau besoin'**
  String get needsNewNeedAction;

  /// Texte du parcours needs : YearFromValue.
  ///
  /// In fr, this message translates to:
  /// **'À partir de {value0}'**
  String needsYearFromValue(String value0);

  /// Texte du parcours needs : BudgetValue.
  ///
  /// In fr, this message translates to:
  /// **'Budget : {value0}'**
  String needsBudgetValue(String value0);

  /// Texte du parcours needs : Today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get needsToday;

  /// Texte du parcours needs : Yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get needsYesterday;

  /// Texte du parcours needs : DaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {value0} jours'**
  String needsDaysAgo(String value0);

  /// Texte du parcours needs : BodyHatchback.
  ///
  /// In fr, this message translates to:
  /// **'Compacte'**
  String get needsBodyHatchback;

  /// Texte du parcours needs : BodyPickup.
  ///
  /// In fr, this message translates to:
  /// **'Pick-up'**
  String get needsBodyPickup;

  /// Texte du parcours needs : BodyVan.
  ///
  /// In fr, this message translates to:
  /// **'Camionnette'**
  String get needsBodyVan;

  /// Texte du parcours needs : BodyBus.
  ///
  /// In fr, this message translates to:
  /// **'Bus'**
  String get needsBodyBus;

  /// Texte du parcours needs : EmptyMineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun besoin déposé'**
  String get needsEmptyMineTitle;

  /// Texte du parcours needs : EmptyMineBody.
  ///
  /// In fr, this message translates to:
  /// **'Exprimez votre recherche — nous vous\ncontacterons dès qu\'une offre correspond.'**
  String get needsEmptyMineBody;

  /// Texte du parcours needs : StaffListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Besoins clients'**
  String get needsStaffListTitle;

  /// Texte du parcours needs : StatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get needsStatusPending;

  /// Texte du parcours needs : StatusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Transmise'**
  String get needsStatusApproved;

  /// Texte du parcours needs : StatusContacted.
  ///
  /// In fr, this message translates to:
  /// **'Contacté'**
  String get needsStatusContacted;

  /// Texte du parcours needs : StatusFulfilled.
  ///
  /// In fr, this message translates to:
  /// **'Satisfait'**
  String get needsStatusFulfilled;

  /// Texte du parcours needs : StatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get needsStatusCancelled;

  /// Texte du parcours needs : TypePart.
  ///
  /// In fr, this message translates to:
  /// **'Pièce'**
  String get needsTypePart;

  /// Texte du parcours needs : TypeAccessory.
  ///
  /// In fr, this message translates to:
  /// **'Accessoire'**
  String get needsTypeAccessory;

  /// Texte du parcours needs : FilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get needsFilterAll;

  /// Texte du parcours needs : FilterAllTypes.
  ///
  /// In fr, this message translates to:
  /// **'Tous types'**
  String get needsFilterAllTypes;

  /// Texte du parcours needs : MaximumBudgetValue.
  ///
  /// In fr, this message translates to:
  /// **'Budget max : {value0}'**
  String needsMaximumBudgetValue(String value0);

  /// Texte du parcours needs : NoContact.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contact renseigné'**
  String get needsNoContact;

  /// Texte du parcours needs : UpdateAction.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get needsUpdateAction;

  /// Texte du parcours needs : TodayAtTime.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui {value0}:{value1}'**
  String needsTodayAtTime(String value0, String value1);

  /// Texte du parcours needs : UpdateStatusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le statut'**
  String get needsUpdateStatusTitle;

  /// Texte du parcours needs : StaffNotesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Notes internes (optionnel)'**
  String get needsStaffNotesLabel;

  /// Texte du parcours needs : StaffNotesHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Client rappelé le 02/09, devis envoyé…'**
  String get needsStaffNotesHint;

  /// Texte du parcours needs : EmptyPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun besoin en attente'**
  String get needsEmptyPendingTitle;

  /// Texte du parcours needs : EmptyResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun besoin trouvé'**
  String get needsEmptyResultsTitle;

  /// Texte du parcours needs : EmptyStaffBody.
  ///
  /// In fr, this message translates to:
  /// **'Les besoins soumis par les clients\napparaîtront ici.'**
  String get needsEmptyStaffBody;

  /// Texte du parcours needs : SubmittedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Besoin enregistré !'**
  String get needsSubmittedTitle;

  /// Texte du parcours needs : SubmittedBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous avons bien reçu votre demande.\nNotre équipe vous contactera dès qu\'une offre correspondante sera disponible.'**
  String get needsSubmittedBody;

  /// Texte du parcours needs : SubmittedConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get needsSubmittedConfirm;

  /// Texte du parcours needs : SignInRequiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise'**
  String get needsSignInRequiredTitle;

  /// Texte du parcours needs : SignInRequiredBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour déposer un besoin.'**
  String get needsSignInRequiredBody;

  /// Texte du parcours needs : SignInAction.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get needsSignInAction;

  /// Texte du parcours needs : Introduction.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne trouvez pas ce que vous cherchez ? Déposez votre besoin — nous vous contacterons dès qu\'une offre correspondante sera disponible.'**
  String get needsIntroduction;

  /// Texte du parcours needs : TypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de recherche'**
  String get needsTypeLabel;

  /// Texte du parcours needs : DescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description du besoin *'**
  String get needsDescriptionLabel;

  /// Texte du parcours needs : VehicleDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Couleur préférée, kilométrage max, options souhaitées…'**
  String get needsVehicleDescriptionHint;

  /// Texte du parcours needs : PartDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Référence, compatibilité véhicule, état souhaité…'**
  String get needsPartDescriptionHint;

  /// Texte du parcours needs : AccessoryDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Dimensions, compatibilité, couleur…'**
  String get needsAccessoryDescriptionHint;

  /// Texte du parcours needs : DescriptionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez votre besoin (10 caractères minimum).'**
  String get needsDescriptionRequired;

  /// Texte du parcours needs : BudgetLabel.
  ///
  /// In fr, this message translates to:
  /// **'Budget maximum (optionnel)'**
  String get needsBudgetLabel;

  /// Texte du parcours needs : BudgetInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get needsBudgetInvalid;

  /// Texte du parcours needs : CallbackPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone pour vous rappeler *'**
  String get needsCallbackPhoneLabel;

  /// Texte du parcours needs : CallbackPhoneExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Sans numéro, nous ne pouvons pas vous répondre. Vous pouvez en donner un second, d’un autre opérateur.'**
  String get needsCallbackPhoneExplanation;

  /// Texte du parcours needs : PrimaryPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro principal'**
  String get needsPrimaryPhoneLabel;

  /// Texte du parcours needs : SecondaryPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Autre numéro (optionnel)'**
  String get needsSecondaryPhoneLabel;

  /// Texte du parcours needs : PhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un numéro.'**
  String get needsPhoneRequired;

  /// Texte du parcours needs : PhoneTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Numéro trop court.'**
  String get needsPhoneTooShort;

  /// Texte du parcours needs : RemovePhoneAction.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce numéro'**
  String get needsRemovePhoneAction;

  /// Texte du parcours needs : AddPhoneAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un numéro'**
  String get needsAddPhoneAction;

  /// Texte du parcours needs : CustomerAccountNotice.
  ///
  /// In fr, this message translates to:
  /// **'Connecté en tant que {value0} — votre demande sera liée à votre compte.'**
  String needsCustomerAccountNotice(String value0);

  /// Texte du parcours needs : StaffAccountNotice.
  ///
  /// In fr, this message translates to:
  /// **'Saisie par {value0}, pour le compte d’un client. La demande ne sera rattachée à aucun compte : le numéro ci-dessus est le seul moyen de le rappeler.'**
  String needsStaffAccountNotice(String value0);

  /// Texte du parcours needs : SubmitAction.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre mon besoin'**
  String get needsSubmitAction;

  /// Texte du parcours needs : VehicleCriteriaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Critères du véhicule recherché'**
  String get needsVehicleCriteriaTitle;

  /// Texte du parcours needs : BrandsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les marques.'**
  String get needsBrandsLoadError;

  /// Texte du parcours needs : AnyBrand.
  ///
  /// In fr, this message translates to:
  /// **'Toutes marques'**
  String get needsAnyBrand;

  /// Texte du parcours needs : ModelsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les modèles.'**
  String get needsModelsLoadError;

  /// Texte du parcours needs : NoModels.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle disponible pour cette marque.'**
  String get needsNoModels;

  /// Texte du parcours needs : AnyModel.
  ///
  /// In fr, this message translates to:
  /// **'Tous modèles'**
  String get needsAnyModel;

  /// Texte du parcours needs : AnyOption.
  ///
  /// In fr, this message translates to:
  /// **'Peu importe'**
  String get needsAnyOption;

  /// Texte du parcours needs : YearFromLabel.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get needsYearFromLabel;

  /// Texte du parcours needs : YearRangeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Année invalide (1950–{value0})'**
  String needsYearRangeInvalid(String value0);

  /// Texte du parcours needs : YearEndBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'Doit être ≥ année de départ'**
  String get needsYearEndBeforeStart;

  /// Texte du parcours needs : PartCriteriaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Critères de la pièce recherchée'**
  String get needsPartCriteriaTitle;

  /// Texte du parcours needs : CategoriesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les catégories.'**
  String get needsCategoriesLoadError;

  /// Texte du parcours needs : AnyCategory.
  ///
  /// In fr, this message translates to:
  /// **'Toutes catégories'**
  String get needsAnyCategory;

  /// Texte du parcours needs : ManufacturerOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fabricant (optionnel)'**
  String get needsManufacturerOptionalLabel;

  /// Texte du parcours needs : AnyManufacturer.
  ///
  /// In fr, this message translates to:
  /// **'Tous fabricants'**
  String get needsAnyManufacturer;

  /// Texte du parcours needs : OemOptionalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence OEM (optionnel)'**
  String get needsOemOptionalLabel;

  /// Texte du parcours needs : OemHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 90915-YZZD4'**
  String get needsOemHint;

  /// Texte du parcours needs : OemTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Référence trop longue (max 100 caractères)'**
  String get needsOemTooLong;

  /// Texte du parcours needs : AccessoryCriteriaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Critères de l\'accessoire recherché'**
  String get needsAccessoryCriteriaTitle;

  /// Texte du parcours needs : BrandManufacturerOptional.
  ///
  /// In fr, this message translates to:
  /// **'Marque / Fabricant (optionnel)'**
  String get needsBrandManufacturerOptional;

  /// Texte du parcours needs : CriteriaExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Plus vous précisez, mieux nous ciblons les offres.'**
  String get needsCriteriaExplanation;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'Motorisation non renseignée'**
  String get garageEngineMissingTitle;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'Sans elle, impossible de savoir quelles pièces vont sur ce véhicule.'**
  String get garageEngineMissingBody;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'Compléter'**
  String get garageCompleteAction;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'En ville'**
  String get garageTripCity;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'Une centaine de km'**
  String get garageTripHundredKm;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'Une autre ville'**
  String get garageTripOtherCity;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'Une autre région'**
  String get garageTripOtherRegion;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'Un autre pays'**
  String get garageTripOtherCountry;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'récemment'**
  String get garageRecentlyLower;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get garageTodayLower;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get garageYesterdayLower;

  /// Texte du parcours garage ou demandes clients.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get garageNoInterval;

  /// Confirmation de mise à jour du stock.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule mis à jour ✓'**
  String get vehiclesUpdated;

  /// Confirmation de création avant les photos.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule enregistré — ajoutez des photos !'**
  String get vehiclesCreated;

  /// Titre d’erreur d’enregistrement.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible'**
  String get vehiclesSaveFailed;

  /// Libellé du récapitulatif partenaire.
  ///
  /// In fr, this message translates to:
  /// **'Prix affiché à l’acheteur'**
  String get vehiclesBuyerPriceLabel;

  /// Libellé du tarif partenaire ; conserve le texte français existant.
  ///
  /// In fr, this message translates to:
  /// **'Tarif affiche a l’acheteur'**
  String get vehiclesBuyerRateLabel;

  /// Fermeture de la boîte d’erreur.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get vehiclesOk;

  /// Titre du formulaire d’édition.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le véhicule'**
  String get vehiclesEditTitle;

  /// Titre du formulaire de création.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un véhicule'**
  String get vehiclesCreateTitle;

  /// Infobulle de gestion des photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get vehiclesPhotos;

  /// Titre de la première étape.
  ///
  /// In fr, this message translates to:
  /// **'Type de véhicule'**
  String get vehiclesTypeTitle;

  /// Catégorie de véhicule léger, pas un vendeur particulier.
  ///
  /// In fr, this message translates to:
  /// **'Particulier'**
  String get vehiclesTypePassenger;

  /// Catégorie de véhicule utilitaire.
  ///
  /// In fr, this message translates to:
  /// **'Utilitaire'**
  String get vehiclesTypeUtility;

  /// Catégorie des poids lourds.
  ///
  /// In fr, this message translates to:
  /// **'Poids lourd'**
  String get vehiclesTypeHeavy;

  /// Champ obligatoire de carrosserie.
  ///
  /// In fr, this message translates to:
  /// **'Carrosserie *'**
  String get vehiclesBodyStyleLabel;

  /// Exemples de carrosseries.
  ///
  /// In fr, this message translates to:
  /// **'Berline, SUV, Pickup…'**
  String get vehiclesBodyStyleHint;

  /// Validation de carrosserie.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne un type de carrosserie'**
  String get vehiclesBodyStyleRequired;

  /// Libellé du VIN facultatif.
  ///
  /// In fr, this message translates to:
  /// **'VIN (optionnel)'**
  String get vehiclesVinOptional;

  /// Aide de saisie du VIN.
  ///
  /// In fr, this message translates to:
  /// **'17 caractères — numéro de châssis international'**
  String get vehiclesVinHelper;

  /// Validation du VIN facultatif.
  ///
  /// In fr, this message translates to:
  /// **'Le VIN doit faire exactement 17 caractères.'**
  String get vehiclesVinLengthError;

  /// Commutateur de statut d’immatriculation.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule immatriculé'**
  String get vehiclesRegisteredLabel;

  /// Explication lorsque le véhicule est immatriculé.
  ///
  /// In fr, this message translates to:
  /// **'Déjà immatriculé — la plaque peut être ajoutée plus tard.'**
  String get vehiclesRegisteredHint;

  /// Explication lorsque le véhicule est importé non immatriculé.
  ///
  /// In fr, this message translates to:
  /// **'Importé, pas encore immatriculé ici.'**
  String get vehiclesImportedHint;

  /// Avertissement avant changement destructif du statut d’immatriculation ; aucune règle changée.
  ///
  /// In fr, this message translates to:
  /// **'Ce véhicule est enregistré comme immatriculé. En le déclarant importé, ses informations d’immatriculation seront supprimées. Ressaisissez le kilométrage : il ne mesure pas la même chose pour un véhicule immatriculé et pour un import.'**
  String get vehiclesRegistrationRemovalWarning;

  /// Champ facultatif de la plaque.
  ///
  /// In fr, this message translates to:
  /// **'Plaque d\'immatriculation (optionnel)'**
  String get vehiclesPlateOptional;

  /// Exemple de plaque, valeur fictive inchangée.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : AA 1234 BF'**
  String get vehiclesPlateHint;

  /// Titre de l’étape d’identification.
  ///
  /// In fr, this message translates to:
  /// **'Identité'**
  String get vehiclesIdentityTitle;

  /// Champ obligatoire de la marque.
  ///
  /// In fr, this message translates to:
  /// **'Marque *'**
  String get vehiclesBrandLabel;

  /// Validation de marque.
  ///
  /// In fr, this message translates to:
  /// **'Marque obligatoire'**
  String get vehiclesBrandRequired;

  /// Champ obligatoire de modèle.
  ///
  /// In fr, this message translates to:
  /// **'Modèle *'**
  String get vehiclesModelLabel;

  /// Validation du modèle.
  ///
  /// In fr, this message translates to:
  /// **'Modèle obligatoire'**
  String get vehiclesModelRequired;

  /// Champ de l’année de fabrication.
  ///
  /// In fr, this message translates to:
  /// **'Année de fabrication *'**
  String get vehiclesManufactureYearLabel;

  /// Validation d’année absente.
  ///
  /// In fr, this message translates to:
  /// **'Année obligatoire'**
  String get vehiclesYearRequired;

  /// Boîte manuelle dans le récapitulatif technique.
  ///
  /// In fr, this message translates to:
  /// **'manuelle'**
  String get vehiclesTransmissionManualSummary;

  /// Boîte automatique dans le récapitulatif technique.
  ///
  /// In fr, this message translates to:
  /// **'automatique'**
  String get vehiclesTransmissionAutomaticSummary;

  /// Disponibilité dans le récapitulatif commercial.
  ///
  /// In fr, this message translates to:
  /// **'location'**
  String get vehiclesOfferRentSummary;

  /// Disponibilité dans le récapitulatif commercial.
  ///
  /// In fr, this message translates to:
  /// **'vente et location'**
  String get vehiclesOfferBothSummary;

  /// Disponibilité dans le récapitulatif commercial.
  ///
  /// In fr, this message translates to:
  /// **'vente'**
  String get vehiclesOfferSaleSummary;

  /// Titre de l’étape technique.
  ///
  /// In fr, this message translates to:
  /// **'Caractéristiques techniques'**
  String get vehiclesTechnicalTitle;

  /// Champ obligatoire de motorisation.
  ///
  /// In fr, this message translates to:
  /// **'Type de motorisation *'**
  String get vehiclesEngineTypeLabel;

  /// Validation de motorisation.
  ///
  /// In fr, this message translates to:
  /// **'Motorisation obligatoire'**
  String get vehiclesEngineTypeRequired;

  /// Titre du choix de boîte.
  ///
  /// In fr, this message translates to:
  /// **'Boîte de vitesses'**
  String get vehiclesTransmissionLabel;

  /// Libellé de la motricité.
  ///
  /// In fr, this message translates to:
  /// **'Roues motrices'**
  String get vehiclesDrivetrainLabel;

  /// Libellé de puissance sans conversion de quantité.
  ///
  /// In fr, this message translates to:
  /// **'Puissance (ch)'**
  String get vehiclesPowerLabel;

  /// Titre du choix des équipements.
  ///
  /// In fr, this message translates to:
  /// **'Équipements & options'**
  String get vehiclesFeaturesTitle;

  /// Aide du choix des équipements.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez les équipements présents sur ce véhicule.'**
  String get vehiclesFeaturesHint;

  /// Titre de l’étape commerciale.
  ///
  /// In fr, this message translates to:
  /// **'Informations commerciales'**
  String get vehiclesCommercialTitle;

  /// Titre du choix de condition.
  ///
  /// In fr, this message translates to:
  /// **'État du véhicule'**
  String get vehiclesConditionLabel;

  /// Condition de véhicule endommagé.
  ///
  /// In fr, this message translates to:
  /// **'Endommagé'**
  String get vehiclesConditionDamaged;

  /// Libellé du pays d’origine de l’import.
  ///
  /// In fr, this message translates to:
  /// **'Pays d\'origine'**
  String get vehiclesOriginCountryLabel;

  /// Aide du pays d’origine.
  ///
  /// In fr, this message translates to:
  /// **'Provenance du véhicule importé'**
  String get vehiclesOriginCountryHint;

  /// Titre du choix de disponibilité.
  ///
  /// In fr, this message translates to:
  /// **'Disponible pour'**
  String get vehiclesAvailabilityLabel;

  /// Disponibilité à la vente.
  ///
  /// In fr, this message translates to:
  /// **'Vente'**
  String get vehiclesForSale;

  /// Disponibilité à la location.
  ///
  /// In fr, this message translates to:
  /// **'Location'**
  String get vehiclesForRent;

  /// Double disponibilité.
  ///
  /// In fr, this message translates to:
  /// **'Vente & Location'**
  String get vehiclesForBoth;

  /// Titre de la mise en avant du personnel.
  ///
  /// In fr, this message translates to:
  /// **'Mise en avant'**
  String get vehiclesDealLabel;

  /// Option sans promotion.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get vehiclesNoDeal;

  /// Option promotion bonne affaire.
  ///
  /// In fr, this message translates to:
  /// **'Bonne affaire'**
  String get vehiclesGoodDeal;

  /// Option de vente flash.
  ///
  /// In fr, this message translates to:
  /// **'Vente flash'**
  String get vehiclesFlashSale;

  /// Option déstockage.
  ///
  /// In fr, this message translates to:
  /// **'Déstockage'**
  String get vehiclesClearance;

  /// Libellé du prix obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente *'**
  String get vehiclesSalePriceLabel;

  /// Validation du prix de vente.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente obligatoire'**
  String get vehiclesSalePriceRequired;

  /// Libellé du tarif journalier.
  ///
  /// In fr, this message translates to:
  /// **'Tarif journalier'**
  String get vehiclesDailyRateLabel;

  /// Libellé du tarif mensuel.
  ///
  /// In fr, this message translates to:
  /// **'Tarif mensuel'**
  String get vehiclesMonthlyRateLabel;

  /// Validation de présence d’un des deux tarifs.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un tarif journalier ou mensuel'**
  String get vehiclesRentalRateRequired;

  /// Aide des tarifs de location.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez au moins un tarif : par jour ou par mois.'**
  String get vehiclesRentalRateHint;

  /// Libellé de la caution de location.
  ///
  /// In fr, this message translates to:
  /// **'Caution'**
  String get vehiclesDepositLabel;

  /// Commutateur de prix négociable.
  ///
  /// In fr, this message translates to:
  /// **'Prix négociable'**
  String get vehiclesNegotiable;

  /// Libellé de l’agence.
  ///
  /// In fr, this message translates to:
  /// **'Agence / Showroom'**
  String get vehiclesBranchLabel;

  /// Libellé du lieu libre.
  ///
  /// In fr, this message translates to:
  /// **'Site / Agence'**
  String get vehiclesSiteLabel;

  /// Exemple de lieu.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Showroom Ouagadougou Nord'**
  String get vehiclesSiteHint;

  /// Titre du fournisseur professionnel.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur / Partenaire source'**
  String get vehiclesSupplierLabel;

  /// Explication du fournisseur.
  ///
  /// In fr, this message translates to:
  /// **'Source du véhicule (importateur, enchère, concessionnaire partenaire…)'**
  String get vehiclesSupplierHint;

  /// Erreur de chargement de l’annuaire.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les partenaires.'**
  String get vehiclesPartnersLoadFailed;

  /// Aide du fournisseur facultatif.
  ///
  /// In fr, this message translates to:
  /// **'Aucun (optionnel)'**
  String get vehiclesNoneOptional;

  /// Option de fournisseur absent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get vehiclesNone;

  /// Aide de la description.
  ///
  /// In fr, this message translates to:
  /// **'Détails supplémentaires sur le véhicule…'**
  String get vehiclesDescriptionHint;

  /// Action d’étape suivante.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get vehiclesNext;

  /// Action d’étape précédente.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get vehiclesBack;

  /// Catégorie des équipements standard.
  ///
  /// In fr, this message translates to:
  /// **'Dotation standard'**
  String get vehiclesFeatureStandard;

  /// Catégorie des équipements de confort.
  ///
  /// In fr, this message translates to:
  /// **'Confort'**
  String get vehiclesFeatureComfort;

  /// Catégorie des équipements de sécurité.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get vehiclesFeatureSafety;

  /// Catégorie multimédia.
  ///
  /// In fr, this message translates to:
  /// **'Multimédia'**
  String get vehiclesFeatureMultimedia;

  /// Catégorie d’aide à la conduite.
  ///
  /// In fr, this message translates to:
  /// **'Aides à la conduite'**
  String get vehiclesFeatureDriverAssistance;

  /// Autre catégorie d’équipements.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get vehiclesFeatureOther;

  /// Consigne des équipements standard.
  ///
  /// In fr, this message translates to:
  /// **'— cochez ce qui est présent'**
  String get vehiclesFeatureStandardHint;

  /// Titre d’échec réseau.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion'**
  String get vehiclesErrorNetworkTitle;

  /// Titre d’échec d’authentification.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée'**
  String get vehiclesErrorSessionTitle;

  /// Titre d’échec d’autorisation.
  ///
  /// In fr, this message translates to:
  /// **'Action non autorisée'**
  String get vehiclesErrorForbiddenTitle;

  /// Titre des erreurs de validation.
  ///
  /// In fr, this message translates to:
  /// **'Formulaire incomplet'**
  String get vehiclesErrorValidationTitle;

  /// Titre d’envoi excessif.
  ///
  /// In fr, this message translates to:
  /// **'Envoi trop volumineux'**
  String get vehiclesErrorTooLargeTitle;

  /// Titre de limitation de fréquence.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives'**
  String get vehiclesErrorThrottledTitle;

  /// Titre d’échec serveur.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du serveur'**
  String get vehiclesErrorServerTitle;

  /// Action pour déclarer une panne.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer'**
  String get vehiclesFaultDeclare;

  /// Action pour enregistrer une réparation.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre'**
  String get vehiclesFaultResolve;

  /// Pastille d’effet sur la conduite.
  ///
  /// In fr, this message translates to:
  /// **'Conduite affectée'**
  String get vehiclesFaultDrivingAffected;

  /// Pastille de divulgation.
  ///
  /// In fr, this message translates to:
  /// **'Divulguée acheteur'**
  String get vehiclesFaultDisclosed;

  /// Confirmation de suppression.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette panne ?'**
  String get vehiclesFaultDeleteTitle;

  /// Section des pannes vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune panne déclarée'**
  String get vehiclesFaultEmpty;

  /// Aide de la liste vide pour le personnel autorisé.
  ///
  /// In fr, this message translates to:
  /// **'Déclarez les défauts connus pour informer les acheteurs.'**
  String get vehiclesFaultEmptyStaffHint;

  /// Information de liste vide sans droit de déclaration.
  ///
  /// In fr, this message translates to:
  /// **'Ce véhicule ne présente aucun défaut connu.'**
  String get vehiclesFaultEmptyViewerHint;

  /// Titre du formulaire de panne.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer une panne'**
  String get vehiclesFaultCreateTitle;

  /// Libellé du titre obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Titre *'**
  String get vehiclesFaultTitleLabel;

  /// Exemple de titre de panne.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Fuite d\'huile moteur'**
  String get vehiclesFaultTitleHint;

  /// Validation du titre de panne.
  ///
  /// In fr, this message translates to:
  /// **'Le titre est obligatoire'**
  String get vehiclesFaultTitleRequired;

  /// Libellé de catégorie de panne.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie *'**
  String get vehiclesFaultCategoryLabel;

  /// Libellé de gravité de panne.
  ///
  /// In fr, this message translates to:
  /// **'Sévérité *'**
  String get vehiclesFaultSeverityLabel;

  /// Commutateur d’effet sur la conduite.
  ///
  /// In fr, this message translates to:
  /// **'Affecte la conduite'**
  String get vehiclesFaultAffectsDriving;

  /// Explication du commutateur de conduite.
  ///
  /// In fr, this message translates to:
  /// **'Le véhicule est difficile ou dangereux à conduire'**
  String get vehiclesFaultDrivingHint;

  /// Commutateur de danger pour la sécurité.
  ///
  /// In fr, this message translates to:
  /// **'Critique pour la sécurité'**
  String get vehiclesFaultSafetyCritical;

  /// Commutateur de divulgation.
  ///
  /// In fr, this message translates to:
  /// **'Divulguée à l\'acheteur'**
  String get vehiclesFaultDisclosureLabel;

  /// Explication de divulgation.
  ///
  /// In fr, this message translates to:
  /// **'Cette panne est mentionnée dans l\'annonce'**
  String get vehiclesFaultDisclosureHint;

  /// Description facultative de panne.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get vehiclesFaultDescriptionLabel;

  /// Aide de description de panne.
  ///
  /// In fr, this message translates to:
  /// **'Détails sur la panne, symptômes, conditions…'**
  String get vehiclesFaultDescriptionHint;

  /// Code diagnostic facultatif.
  ///
  /// In fr, this message translates to:
  /// **'Code OBD (optionnel)'**
  String get vehiclesFaultObdLabel;

  /// Exemple de code diagnostic.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : P0301'**
  String get vehiclesFaultObdHint;

  /// Date facultative de détection.
  ///
  /// In fr, this message translates to:
  /// **'Date de détection (optionnel)'**
  String get vehiclesFaultDetectionDate;

  /// Format de date ISO ; valeur enregistrée inchangée.
  ///
  /// In fr, this message translates to:
  /// **'AAAA-MM-JJ'**
  String get vehiclesDateHint;

  /// Relevé facultatif du compteur.
  ///
  /// In fr, this message translates to:
  /// **'Kilométrage à la détection (optionnel)'**
  String get vehiclesFaultDetectionMileage;

  /// Champ du coût estimé.
  ///
  /// In fr, this message translates to:
  /// **'Coût estimé de réparation (optionnel)'**
  String get vehiclesFaultEstimatedCost;

  /// Validation du montant.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get vehiclesAmountInvalid;

  /// Nom de la personne qui a signalé la panne.
  ///
  /// In fr, this message translates to:
  /// **'Signalé par (optionnel)'**
  String get vehiclesFaultReportedBy;

  /// Exemple de déclarant.
  ///
  /// In fr, this message translates to:
  /// **'Nom du technicien ou du client'**
  String get vehiclesFaultReporterHint;

  /// Action de création de panne.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la panne'**
  String get vehiclesFaultSave;

  /// Date de réparation du formulaire de résolution.
  ///
  /// In fr, this message translates to:
  /// **'Date de réparation'**
  String get vehiclesFaultRepairDate;

  /// Champ du coût réel.
  ///
  /// In fr, this message translates to:
  /// **'Coût réel de réparation (optionnel)'**
  String get vehiclesFaultActualCost;

  /// Action finale de résolution.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme réparée'**
  String get vehiclesFaultMarkRepaired;

  /// Catégorie de panne moteur.
  ///
  /// In fr, this message translates to:
  /// **'Moteur'**
  String get vehiclesFaultCategoryEngine;

  /// Catégorie de panne transmission.
  ///
  /// In fr, this message translates to:
  /// **'Transmission'**
  String get vehiclesFaultCategoryTransmission;

  /// Catégorie de panne électrique.
  ///
  /// In fr, this message translates to:
  /// **'Électricité'**
  String get vehiclesFaultCategoryElectrical;

  /// Catégorie de panne de freinage.
  ///
  /// In fr, this message translates to:
  /// **'Freinage'**
  String get vehiclesFaultCategoryBraking;

  /// Catégorie de panne suspension.
  ///
  /// In fr, this message translates to:
  /// **'Suspension'**
  String get vehiclesFaultCategorySuspension;

  /// Catégorie de panne de direction.
  ///
  /// In fr, this message translates to:
  /// **'Direction'**
  String get vehiclesFaultCategorySteering;

  /// Catégorie de panne refroidissement.
  ///
  /// In fr, this message translates to:
  /// **'Refroidissement'**
  String get vehiclesFaultCategoryCooling;

  /// Catégorie de panne climatisation.
  ///
  /// In fr, this message translates to:
  /// **'Climatisation'**
  String get vehiclesFaultCategoryAirConditioning;

  /// Catégorie de panne carrosserie.
  ///
  /// In fr, this message translates to:
  /// **'Carrosserie'**
  String get vehiclesFaultCategoryBodywork;

  /// Catégorie de panne intérieur.
  ///
  /// In fr, this message translates to:
  /// **'Intérieur'**
  String get vehiclesFaultCategoryInterior;

  /// Catégorie de panne électronique.
  ///
  /// In fr, this message translates to:
  /// **'Électronique'**
  String get vehiclesFaultCategoryElectronics;

  /// Catégorie de panne pneus.
  ///
  /// In fr, this message translates to:
  /// **'Pneumatiques'**
  String get vehiclesFaultCategoryTyres;

  /// Autre catégorie de panne.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get vehiclesFaultCategoryOther;

  /// Gravité mineure.
  ///
  /// In fr, this message translates to:
  /// **'Mineur'**
  String get vehiclesFaultSeverityMinor;

  /// Gravité modérée.
  ///
  /// In fr, this message translates to:
  /// **'Modéré'**
  String get vehiclesFaultSeverityModerate;

  /// Gravité majeure.
  ///
  /// In fr, this message translates to:
  /// **'Majeur'**
  String get vehiclesFaultSeverityMajor;

  /// Gravité critique.
  ///
  /// In fr, this message translates to:
  /// **'Critique'**
  String get vehiclesFaultSeverityCritical;

  /// État panne déclarée.
  ///
  /// In fr, this message translates to:
  /// **'Déclaré'**
  String get vehiclesFaultStatusDeclared;

  /// État diagnostic effectué.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostiqué'**
  String get vehiclesFaultStatusDiagnosed;

  /// État devis réalisé.
  ///
  /// In fr, this message translates to:
  /// **'Devisé'**
  String get vehiclesFaultStatusQuoted;

  /// État réparation en cours.
  ///
  /// In fr, this message translates to:
  /// **'En réparation'**
  String get vehiclesFaultStatusRepairing;

  /// État réparation terminée.
  ///
  /// In fr, this message translates to:
  /// **'Réparé'**
  String get vehiclesFaultStatusRepaired;

  /// État sans réparation prévue.
  ///
  /// In fr, this message translates to:
  /// **'Sans suite'**
  String get vehiclesFaultStatusWontFix;

  /// Alerte d’étape incomplète.
  ///
  /// In fr, this message translates to:
  /// **'Il manque quelque chose à l\'étape {step}.'**
  String vehiclesMissingStep(int step);

  /// Validation de l’intervalle d’année.
  ///
  /// In fr, this message translates to:
  /// **'Année invalide (1950–{year})'**
  String vehiclesYearRangeInvalid(int year);

  /// Puissance dans le récapitulatif technique.
  ///
  /// In fr, this message translates to:
  /// **'{power} ch'**
  String vehiclesPowerSummary(String power);

  /// Récapitulatif de l’offre et du prix.
  ///
  /// In fr, this message translates to:
  /// **'{offer} · {price} FCFA'**
  String vehiclesOfferSummary(String offer, String price);

  /// Chargement des référentiels impossible.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les référentiels :\n{error}'**
  String vehiclesReferencesLoadError(String error);

  /// Coût estimé formaté de la carte panne.
  ///
  /// In fr, this message translates to:
  /// **'Estimé : {cost}'**
  String vehiclesFaultEstimatedCostValue(String cost);

  /// Coût réel formaté de la carte panne.
  ///
  /// In fr, this message translates to:
  /// **'Réel : {cost}'**
  String vehiclesFaultActualCostValue(String cost);

  /// Titre de résolution avec le titre rédigé par l’utilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre : {title}'**
  String vehiclesFaultResolveTitle(String title);

  /// Validation de catégorie pour les formulaires de pièce et d’accessoire.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une catégorie.'**
  String get catalogAdminSelectCategory;

  /// Confirmation de mise à jour d’une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Pièce mise à jour.'**
  String get catalogAdminPartUpdated;

  /// Confirmation de création de pièce avant ajout de photos.
  ///
  /// In fr, this message translates to:
  /// **'Pièce enregistrée — ajoutez des photos !'**
  String get catalogAdminPartCreated;

  /// Confirmation de mise à jour d’un accessoire.
  ///
  /// In fr, this message translates to:
  /// **'Accessoire mis à jour.'**
  String get catalogAdminAccessoryUpdated;

  /// Confirmation de création d’accessoire.
  ///
  /// In fr, this message translates to:
  /// **'Accessoire enregistré — ajoutez des photos !'**
  String get catalogAdminAccessoryCreated;

  /// Titre d’édition de pièce.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la pièce'**
  String get catalogAdminEditPart;

  /// Titre de création de pièce.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle pièce'**
  String get catalogAdminNewPart;

  /// Titre d’édition d’accessoire.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'accessoire'**
  String get catalogAdminEditAccessory;

  /// Titre de création d’accessoire.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel accessoire'**
  String get catalogAdminNewAccessory;

  /// En-tête d’identification des formulaires de stock.
  ///
  /// In fr, this message translates to:
  /// **'Identification'**
  String get catalogAdminIdentification;

  /// Champ du nom obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Désignation *'**
  String get catalogAdminNameLabel;

  /// Validation d’un champ obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get catalogAdminRequired;

  /// Champ de référence interne facultatif.
  ///
  /// In fr, this message translates to:
  /// **'SKU / Référence interne'**
  String get catalogAdminSkuLabel;

  /// Exemple de SKU de pièce.
  ///
  /// In fr, this message translates to:
  /// **'Ex. PDT-BRQ-0042 (optionnel)'**
  String get catalogAdminPartSkuHint;

  /// Exemple de SKU d’accessoire.
  ///
  /// In fr, this message translates to:
  /// **'Ex. ACC-EST-0012 (optionnel)'**
  String get catalogAdminAccessorySkuHint;

  /// Libellé du type obligatoire de pièce.
  ///
  /// In fr, this message translates to:
  /// **'Type *'**
  String get catalogAdminTypeLabel;

  /// Libellé de l’état de pièce.
  ///
  /// In fr, this message translates to:
  /// **'État *'**
  String get catalogAdminConditionLabel;

  /// État neuf, formulation féminine française conservée.
  ///
  /// In fr, this message translates to:
  /// **'Neuve'**
  String get catalogAdminConditionNew;

  /// État reconditionné, formulation féminine française conservée.
  ///
  /// In fr, this message translates to:
  /// **'Reconditionnée'**
  String get catalogAdminConditionRefurbished;

  /// État de pièce d’occasion.
  ///
  /// In fr, this message translates to:
  /// **'D\'occasion'**
  String get catalogAdminConditionUsed;

  /// En-tête de classification du stock.
  ///
  /// In fr, this message translates to:
  /// **'Classification'**
  String get catalogAdminClassification;

  /// Libellé de catégorie obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie *'**
  String get catalogAdminCategoryLabel;

  /// Libellé du fabricant d’une pièce.
  ///
  /// In fr, this message translates to:
  /// **'Fabricant / Équipementier'**
  String get catalogAdminManufacturerLabel;

  /// En-tête des prix de stock.
  ///
  /// In fr, this message translates to:
  /// **'Tarification'**
  String get catalogAdminPricing;

  /// Libellé du prix de vente obligatoire.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente *'**
  String get catalogAdminSalePrice;

  /// Validation de nombre mal formé.
  ///
  /// In fr, this message translates to:
  /// **'Nombre invalide'**
  String get catalogAdminInvalidNumber;

  /// Libellé du prix d’achat.
  ///
  /// In fr, this message translates to:
  /// **'Prix d\'achat'**
  String get catalogAdminPurchasePrice;

  /// Aide d’un champ facultatif.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get catalogAdminOptional;

  /// En-tête des champs de stock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get catalogAdminStock;

  /// Libellé du stock initial.
  ///
  /// In fr, this message translates to:
  /// **'Quantité initiale'**
  String get catalogAdminInitialQuantity;

  /// Libellé du seuil de stock.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte'**
  String get catalogAdminAlertThreshold;

  /// Libellé du rangement physique.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement physique'**
  String get catalogAdminPhysicalLocation;

  /// Exemple d’emplacement physique.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Étagère B3, Tiroir 12'**
  String get catalogAdminLocationHint;

  /// Libellé de l’agence de stock.
  ///
  /// In fr, this message translates to:
  /// **'Agence / Showroom'**
  String get catalogAdminBranch;

  /// Option de stock non limité à une agence.
  ///
  /// In fr, this message translates to:
  /// **'— Toutes agences —'**
  String get catalogAdminAllBranches;

  /// En-tête du choix des compatibilités.
  ///
  /// In fr, this message translates to:
  /// **'Compatibilités véhicules'**
  String get catalogAdminFitments;

  /// Explication des compatibilités de stock.
  ///
  /// In fr, this message translates to:
  /// **'Déclarez les véhicules compatibles pour permettre la recherche par modèle — même sans numéro OEM.'**
  String get catalogAdminFitmentsHint;

  /// Option de champ facultatif sans sélection.
  ///
  /// In fr, this message translates to:
  /// **'— Aucun —'**
  String get catalogAdminNone;

  /// Erreur de chargement des modèles avec message localisé.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les modèles : {error}'**
  String catalogAdminModelsLoadError(String error);

  /// Confirmation de suppression de photo.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette photo ?'**
  String get mediaDeletePhotoTitle;

  /// Avertissement de suppression définitive.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get mediaDeletePhotoBody;

  /// Action fermant la gestion des photos.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get mediaFinish;

  /// Libellé du bouton pendant l’envoi.
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get mediaUploading;

  /// Action sélectionnant les photos de la galerie.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get mediaGallery;

  /// Action ouvrant l’appareil photo.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get mediaCamera;

  /// Pastille de la photo de couverture, texte français historique conservé.
  ///
  /// In fr, this message translates to:
  /// **'Cover'**
  String get mediaCover;

  /// Titre d’échec du chargement des photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos non chargées'**
  String get mediaLoadFailed;

  /// État vide de la gestion des photos.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo'**
  String get mediaEmpty;

  /// Aide de l’état vide.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur \"Galerie\" pour ajouter des photos.'**
  String get mediaEmptyHint;

  /// Action d’ajout de photos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get mediaAddPhotos;

  /// Confirmation de l’ajout de photos.
  ///
  /// In fr, this message translates to:
  /// **'{count} photo(s) ajoutée(s).'**
  String mediaPhotosAdded(int count);

  /// Aide de la section facultative de compatibilité d’accessoire.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel — déclarez les véhicules compatibles pour faciliter la recherche.'**
  String get catalogAdminAccessoryFitmentsHint;

  /// Libellé localisé du garage ou des demandes.
  ///
  /// In fr, this message translates to:
  /// **'Pièce détachée'**
  String get needsTypeSparePart;

  /// Libellé localisé du garage ou des demandes.
  ///
  /// In fr, this message translates to:
  /// **'Un passage a probablement été oublié'**
  String get garageRefillMissing;

  /// Libellé localisé du garage ou des demandes.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre invraisemblable, un passage manque'**
  String get garageRefillImplausible;

  /// Libellé localisé du garage ou des demandes.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre trop bas pour être vrai : un passage d\'avant n\'a pas été enregistré'**
  String get garageRefillTooLow;

  /// Nombre de jours de retard.
  ///
  /// In fr, this message translates to:
  /// **'Dépassée de {days} j'**
  String garageDeadlineOverdue(int days);

  /// Libellé localisé du garage ou des demandes.
  ///
  /// In fr, this message translates to:
  /// **'Expire aujourd\'hui'**
  String get garageDeadlineToday;

  /// Nombre de jours avant échéance.
  ///
  /// In fr, this message translates to:
  /// **'Dans {days} j'**
  String garageDeadlineInDays(int days);

  /// Libellé localisé du garage ou des demandes.
  ///
  /// In fr, this message translates to:
  /// **' sur {value0} km'**
  String garageRefillDistanceSuffix(String value0);

  /// Libellé localisé du garage ou des demandes.
  ///
  /// In fr, this message translates to:
  /// **' — écarté'**
  String get garageRefillExcludedSuffix;

  /// Fin de la plage des années recherchées.
  ///
  /// In fr, this message translates to:
  /// **'À'**
  String get needsYearToLabel;

  /// Nom de repli du véhicule dans le choix de moteur.
  ///
  /// In fr, this message translates to:
  /// **'véhicule'**
  String get garageGenericVehicle;

  /// Texte localisé du garage ou des besoins.
  ///
  /// In fr, this message translates to:
  /// **'FCFA'**
  String get garageCurrencyUnit;

  /// Texte localisé du garage ou des besoins.
  ///
  /// In fr, this message translates to:
  /// **'FCFA/l'**
  String get garageCurrencyPerLitre;

  /// Texte localisé du garage ou des besoins.
  ///
  /// In fr, this message translates to:
  /// **' · {value0} FCFA'**
  String garageRefillAmountSuffix(String value0);

  /// Texte localisé du garage ou des besoins.
  ///
  /// In fr, this message translates to:
  /// **'depuis {value0}'**
  String garageModelSinceYear(String value0);

  /// Repli de nom de modèle absent du référentiel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle n° {value}'**
  String catalogFitmentModelNumber(String value);

  /// Description du canal système Android des notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications importantes AutoParc'**
  String get notificationsChannelDescription;

  /// Message de mise à jour obligatoire par défaut.
  ///
  /// In fr, this message translates to:
  /// **'Cette version de l\'application n\'est plus prise en charge. Installez la dernière version pour continuer.'**
  String get updateUnsupportedMessage;

  /// Texte de auth_repository.dart (loginStaff).
  ///
  /// In fr, this message translates to:
  /// **'Token manquant dans la réponse.'**
  String get authErrorTokenMissing;

  /// Texte de auth_repository.dart (signInWithGoogle).
  ///
  /// In fr, this message translates to:
  /// **'Google n\'a pas fourni de jeton d\'identité.'**
  String get authErrorGoogleTokenMissing;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google interrompue. Si vous n\'avez pas fermé la fenêtre, vérifiez votre connexion internet puis réessayez.'**
  String get authErrorGoogleInterrupted;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google interrompue. Vérifiez votre connexion internet puis réessayez.'**
  String get authErrorGoogleInterruptedNetwork;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'La connexion Google n\'est pas correctement configurée pour cette version de l\'application.'**
  String get authErrorGoogleConfiguration;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'La connexion Google n\'est pas disponible sur cet appareil.'**
  String get authErrorGoogleUnavailable;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'afficher la fenêtre de connexion Google.'**
  String get authErrorGoogleWindow;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google impossible ({value0}).'**
  String authErrorGoogleCode(String value0);

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte trouvé pour cet email.'**
  String get authErrorAccountMissing;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get authErrorWrongPassword;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect.'**
  String get authErrorCredentials;

  /// No description provided for @authErrorPartnerAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est un compte partenaire. Connectez-vous à l’espace partenaire.'**
  String get authErrorPartnerAccount;

  /// No description provided for @authErrorStaffAccount.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte appartient au personnel. Utilisez la connexion du personnel.'**
  String get authErrorStaffAccount;

  /// No description provided for @authOpenPartnerSpace.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l’espace partenaire'**
  String get authOpenPartnerSpace;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet email.'**
  String get authErrorEmailInUse;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible (6 caractères minimum).'**
  String get authErrorWeakPassword;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide.'**
  String get authErrorEmailInvalid;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau. Vérifiez votre connexion internet.'**
  String get authErrorNetwork;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Cette méthode de connexion n\'est pas activée.'**
  String get authErrorMethodDisabled;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Ce compte existe déjà avec un autre mode de connexion.'**
  String get authErrorOtherMethod;

  /// Texte de auth_provider.dart (_extractMessage).
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion ({value0}).'**
  String authErrorCode(String value0);

  /// Texte de auth_provider.dart (signIn).
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible pour le moment. Réessayez.'**
  String get authErrorUnavailable;

  /// Texte de auth_provider.dart (deleteAccount).
  ///
  /// In fr, this message translates to:
  /// **'Seuls les comptes clients se suppriment ici.'**
  String get authErrorDeleteClientOnly;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get notificationsMarkAllRead;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un conseil'**
  String get notificationsBroadcastTooltip;

  /// Texte de notifications_page.dart (_formatDate).
  ///
  /// In fr, this message translates to:
  /// **'Il y a {value0} min'**
  String notificationsMinutesAgo(String value0);

  /// Texte de notifications_page.dart (_formatDate).
  ///
  /// In fr, this message translates to:
  /// **'Il y a {value0} h'**
  String notificationsHoursAgo(String value0);

  /// Texte de notifications_page.dart (_formatDate).
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get notificationsYesterday;

  /// Texte de notifications_page.dart (_formatDate).
  ///
  /// In fr, this message translates to:
  /// **'Il y a {value0} jours'**
  String notificationsDaysAgo(String value0);

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsEmptyTitle;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Vous serez notifié ici des activités importantes.'**
  String get notificationsEmptyBody;

  /// Texte de notifications_page.dart (_send).
  ///
  /// In fr, this message translates to:
  /// **'Titre et message sont obligatoires.'**
  String get notificationsTitleBodyRequired;

  /// Texte de notifications_page.dart (_send).
  ///
  /// In fr, this message translates to:
  /// **'Conseil envoyé à tous les clients ✓'**
  String get notificationsBroadcastSent;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Conseil aux propriétaires'**
  String get notificationsBroadcastTitle;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Ce message sera envoyé par notification push à tous les clients de l\'app.'**
  String get notificationsBroadcastBody;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Titre *'**
  String get notificationsTitleField;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Vérifiez votre pression des pneus'**
  String get notificationsTitleHint;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Message *'**
  String get notificationsBodyField;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Une bonne pression de gonflage améliore la durée de vie des pneus de 20 %…'**
  String get notificationsBodyHint;

  /// Texte de notifications_page.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Envoyer à tous les clients'**
  String get notificationsBroadcastAction;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Aucune compatibilité déclarée'**
  String get catalogFitmentEmptyTitle;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'La pièce sera trouvable uniquement par SKU.'**
  String get catalogFitmentEmptyBody;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Proposée automatiquement, non vérifiée'**
  String get catalogFitmentUnverified;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'En enregistrant, les lignes proposées que vous laissez ici deviennent des compatibilités déclarées : elles ne seront plus recalculées, et vous en répondez. Retirez celles que vous ne pouvez pas confirmer.'**
  String get catalogFitmentConfirmationHint;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une compatibilité'**
  String get catalogFitmentAdd;

  /// Texte de fitments_section.dart (_confirm).
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un modèle.'**
  String get catalogFitmentModelRequired;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Compatibilité véhicule'**
  String get catalogFitmentDialogTitle;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Marque *'**
  String get catalogFitmentBrandRequired;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner…'**
  String get catalogFitmentSelect;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Modèle *'**
  String get catalogFitmentModelField;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Choisir d\'abord une marque'**
  String get catalogFitmentChooseBrand;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Finition (optionnel)'**
  String get catalogFitmentTrimOptional;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Toutes finitions'**
  String get catalogFitmentAllTrims;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'— Toutes finitions —'**
  String get catalogFitmentAllTrimsOption;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Année de'**
  String get catalogFitmentYearFromField;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Année à'**
  String get catalogFitmentYearToField;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Position (optionnel)'**
  String get catalogFitmentPositionField;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Ex. Avant gauche, Côté moteur…'**
  String get catalogFitmentPositionHint;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter cette compatibilité'**
  String get catalogFitmentConfirmAction;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Compatibilités non relues'**
  String get catalogFitmentUnavailableTitle;

  /// Texte de fitments_section.dart (build).
  ///
  /// In fr, this message translates to:
  /// **'Elles n\'ont pas pu être chargées et ne sont donc pas modifiables pour l\'instant. Elles seront conservées telles quelles : enregistrer les autres champs ne leur fera rien. Rouvrez cet écran une fois la connexion revenue pour y toucher.'**
  String get catalogFitmentUnavailableBody;

  /// Carburant du référentiel identifié par son code stable.
  ///
  /// In fr, this message translates to:
  /// **'Essence'**
  String get vehiclesReferenceFuelPetrol;

  /// Carburant du référentiel identifié par son code stable.
  ///
  /// In fr, this message translates to:
  /// **'Diesel'**
  String get vehiclesReferenceFuelDiesel;

  /// Carburant du référentiel identifié par son code stable.
  ///
  /// In fr, this message translates to:
  /// **'Électrique'**
  String get vehiclesReferenceFuelElectric;

  /// Carburant du référentiel identifié par son code stable.
  ///
  /// In fr, this message translates to:
  /// **'Hybride'**
  String get vehiclesReferenceFuelHybrid;

  /// Roues motrices du référentiel identifiées par leur code stable.
  ///
  /// In fr, this message translates to:
  /// **'Traction avant'**
  String get vehiclesReferenceDriveFrontWheel;

  /// Roues motrices du référentiel identifiées par leur code stable.
  ///
  /// In fr, this message translates to:
  /// **'Propulsion arrière'**
  String get vehiclesReferenceDriveRearWheel;

  /// Motricité AWD, sans présumer un fonctionnement permanent ou à la demande.
  ///
  /// In fr, this message translates to:
  /// **'Intégrale (AWD)'**
  String get vehiclesReferenceDriveAllWheel;

  /// Motricité 4WD, sans présumer que le système soit débrayable ou permanent.
  ///
  /// In fr, this message translates to:
  /// **'4×4 (4WD)'**
  String get vehiclesReferenceDriveFourWheel;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Blanc'**
  String get vehiclesReferenceColourWhite;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Blanc nacré'**
  String get vehiclesReferenceColourPearlWhite;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Gris clair'**
  String get vehiclesReferenceColourLightGrey;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Gris anthracite'**
  String get vehiclesReferenceColourAnthraciteGrey;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Gris titanium'**
  String get vehiclesReferenceColourTitaniumGrey;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Argent'**
  String get vehiclesReferenceColourSilver;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Noir'**
  String get vehiclesReferenceColourBlack;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Noir métallisé'**
  String get vehiclesReferenceColourMetallicBlack;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Rouge'**
  String get vehiclesReferenceColourRed;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Rouge métallisé'**
  String get vehiclesReferenceColourMetallicRed;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Bordeaux'**
  String get vehiclesReferenceColourBurgundy;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Bleu marine'**
  String get vehiclesReferenceColourNavyBlue;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Bleu métallisé'**
  String get vehiclesReferenceColourMetallicBlue;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Bleu ciel'**
  String get vehiclesReferenceColourSkyBlue;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Vert foncé'**
  String get vehiclesReferenceColourDarkGreen;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Vert olive'**
  String get vehiclesReferenceColourOliveGreen;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Beige'**
  String get vehiclesReferenceColourBeige;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Marron'**
  String get vehiclesReferenceColourBrown;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Or / Champagne'**
  String get vehiclesReferenceColourGoldChampagne;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Orange'**
  String get vehiclesReferenceColourOrange;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Jaune'**
  String get vehiclesReferenceColourYellow;

  /// Couleur standard exacte de ColorsSeeder ; les couleurs personnalisées sont conservées.
  ///
  /// In fr, this message translates to:
  /// **'Violet'**
  String get vehiclesReferenceColourPurple;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Burkina Faso'**
  String get vehiclesReferenceCountryBf;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Côte d\'Ivoire'**
  String get vehiclesReferenceCountryCi;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Sénégal'**
  String get vehiclesReferenceCountrySn;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Mali'**
  String get vehiclesReferenceCountryMl;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Niger'**
  String get vehiclesReferenceCountryNe;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Togo'**
  String get vehiclesReferenceCountryTg;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Bénin'**
  String get vehiclesReferenceCountryBj;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Guinée-Bissau'**
  String get vehiclesReferenceCountryGw;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Guinée'**
  String get vehiclesReferenceCountryGn;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Ghana'**
  String get vehiclesReferenceCountryGh;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Nigéria'**
  String get vehiclesReferenceCountryNg;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Libéria'**
  String get vehiclesReferenceCountryLr;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Sierra Leone'**
  String get vehiclesReferenceCountrySl;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Gambie'**
  String get vehiclesReferenceCountryGm;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Cap-Vert'**
  String get vehiclesReferenceCountryCv;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Mauritanie'**
  String get vehiclesReferenceCountryMr;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Cameroun'**
  String get vehiclesReferenceCountryCm;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'République centrafricaine'**
  String get vehiclesReferenceCountryCf;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Tchad'**
  String get vehiclesReferenceCountryTd;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'République du Congo'**
  String get vehiclesReferenceCountryCg;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Gabon'**
  String get vehiclesReferenceCountryGa;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Guinée équatoriale'**
  String get vehiclesReferenceCountryGq;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'République démocratique du Congo'**
  String get vehiclesReferenceCountryCd;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Éthiopie'**
  String get vehiclesReferenceCountryEt;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Kenya'**
  String get vehiclesReferenceCountryKe;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Tanzanie'**
  String get vehiclesReferenceCountryTz;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Ouganda'**
  String get vehiclesReferenceCountryUg;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Rwanda'**
  String get vehiclesReferenceCountryRw;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Afrique du Sud'**
  String get vehiclesReferenceCountryZa;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Angola'**
  String get vehiclesReferenceCountryAo;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Mozambique'**
  String get vehiclesReferenceCountryMz;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Maroc'**
  String get vehiclesReferenceCountryMa;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Algérie'**
  String get vehiclesReferenceCountryDz;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Tunisie'**
  String get vehiclesReferenceCountryTn;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Égypte'**
  String get vehiclesReferenceCountryEg;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Libye'**
  String get vehiclesReferenceCountryLy;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Japon'**
  String get vehiclesReferenceCountryJp;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Corée du Sud'**
  String get vehiclesReferenceCountryKr;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Allemagne'**
  String get vehiclesReferenceCountryDe;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'France'**
  String get vehiclesReferenceCountryFr;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Royaume-Uni'**
  String get vehiclesReferenceCountryGb;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Pays-Bas'**
  String get vehiclesReferenceCountryNl;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Belgique'**
  String get vehiclesReferenceCountryBe;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Italie'**
  String get vehiclesReferenceCountryIt;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Espagne'**
  String get vehiclesReferenceCountryEs;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Suède'**
  String get vehiclesReferenceCountrySe;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Chine'**
  String get vehiclesReferenceCountryCn;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Inde'**
  String get vehiclesReferenceCountryIn;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'États-Unis'**
  String get vehiclesReferenceCountryUs;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Canada'**
  String get vehiclesReferenceCountryCa;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Australie'**
  String get vehiclesReferenceCountryAu;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Brésil'**
  String get vehiclesReferenceCountryBr;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Mexique'**
  String get vehiclesReferenceCountryMx;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Turquie'**
  String get vehiclesReferenceCountryTr;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Émirats arabes unis'**
  String get vehiclesReferenceCountryAe;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Arabie saoudite'**
  String get vehiclesReferenceCountrySa;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Pakistan'**
  String get vehiclesReferenceCountryPk;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Indonésie'**
  String get vehiclesReferenceCountryId;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Thaïlande'**
  String get vehiclesReferenceCountryTh;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Malaisie'**
  String get vehiclesReferenceCountryMy;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Singapour'**
  String get vehiclesReferenceCountrySg;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Zimbabwe'**
  String get vehiclesReferenceCountryZw;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Liban'**
  String get vehiclesReferenceCountryLb;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Portugal'**
  String get vehiclesReferenceCountryPt;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Suisse'**
  String get vehiclesReferenceCountryCh;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Autriche'**
  String get vehiclesReferenceCountryAt;

  /// Pays de CountriesSeeder identifié par ISO 3166-1 alpha-2 ; nom anglais issu des données CLDR d’Intl.DisplayNames.
  ///
  /// In fr, this message translates to:
  /// **'Pologne'**
  String get vehiclesReferenceCountryPl;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Moteur'**
  String get catalogPartCategoryEngine;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get catalogPartCategoryFilters;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Filtre à huile'**
  String get catalogPartCategoryOilFilter;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Filtre à air'**
  String get catalogPartCategoryAirFilter;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Filtre habitacle'**
  String get catalogPartCategoryCabinFilter;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Filtre à carburant'**
  String get catalogPartCategoryFuelFilter;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Distribution'**
  String get catalogPartCategoryTimingSystem;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Courroie de distribution'**
  String get catalogPartCategoryTimingBelt;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Kit distribution'**
  String get catalogPartCategoryTimingBeltKit;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Chaîne de distribution'**
  String get catalogPartCategoryTimingChain;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Lubrification'**
  String get catalogPartCategoryLubrication;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Huile moteur'**
  String get catalogPartCategoryEngineOil;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Joint de culasse'**
  String get catalogPartCategoryCylinderHeadGasket;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Carter d\'huile'**
  String get catalogPartCategoryOilSump;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Refroidissement'**
  String get catalogPartCategoryCooling;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Radiateur'**
  String get catalogPartCategoryRadiator;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Thermostat'**
  String get catalogPartCategoryThermostat;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Pompe à eau'**
  String get catalogPartCategoryWaterPump;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Liquide de refroidissement'**
  String get catalogPartCategoryCoolant;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Injection & Allumage'**
  String get catalogPartCategoryInjectionIgnition;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Bougies d\'allumage'**
  String get catalogPartCategorySparkPlugs;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Injecteurs'**
  String get catalogPartCategoryInjectors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Bobines d\'allumage'**
  String get catalogPartCategoryIgnitionCoils;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Freinage'**
  String get catalogPartCategoryBraking;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Disques & Plaquettes'**
  String get catalogPartCategoryDiscsPads;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Disques avant'**
  String get catalogPartCategoryFrontBrakeDiscs;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Disques arrière'**
  String get catalogPartCategoryRearBrakeDiscs;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Plaquettes avant'**
  String get catalogPartCategoryFrontBrakePads;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Plaquettes arrière'**
  String get catalogPartCategoryRearBrakePads;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Étriers'**
  String get catalogPartCategoryBrakeCalipers;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Maître-cylindre'**
  String get catalogPartCategoryBrakeMasterCylinder;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Flexibles de frein'**
  String get catalogPartCategoryBrakeHoses;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Liquide de frein'**
  String get catalogPartCategoryBrakeFluid;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Suspension & Direction'**
  String get catalogPartCategorySuspensionSteering;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Amortisseurs'**
  String get catalogPartCategoryShockAbsorbers;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Amortisseurs avant'**
  String get catalogPartCategoryFrontShockAbsorbers;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Amortisseurs arrière'**
  String get catalogPartCategoryRearShockAbsorbers;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Ressorts'**
  String get catalogPartCategorySprings;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Rotules & Biellettes'**
  String get catalogPartCategoryBallJointsLinks;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Rotule de direction'**
  String get catalogPartCategoryTieRodEnd;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Biellette de barre stabilisatrice'**
  String get catalogPartCategoryAntiRollBarLink;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Roulements & Moyeux'**
  String get catalogPartCategoryWheelBearingsHubs;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Soufflets & Joints homocinétiques'**
  String get catalogPartCategoryCVBootsJoints;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Direction'**
  String get catalogPartCategorySteering;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Crémaillère de direction'**
  String get catalogPartCategorySteeringRack;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Colonne de direction'**
  String get catalogPartCategorySteeringColumn;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Transmission'**
  String get catalogPartCategoryTransmission;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Boîte de vitesses'**
  String get catalogPartCategoryGearbox;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Embrayage'**
  String get catalogPartCategoryClutch;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Kit embrayage'**
  String get catalogPartCategoryClutchKit;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Volant moteur'**
  String get catalogPartCategoryFlywheel;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Cardan & Demi-arbre'**
  String get catalogPartCategoryDriveShaftsHalfShafts;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Différentiel'**
  String get catalogPartCategoryDifferential;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Électricité'**
  String get catalogPartCategoryElectricalSystem;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Batterie & Alternateur'**
  String get catalogPartCategoryBatteryAlternator;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Batterie 12V'**
  String get catalogPartCategory12VBattery;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Alternateur'**
  String get catalogPartCategoryAlternator;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Démarreur'**
  String get catalogPartCategoryStarterMotor;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Éclairage'**
  String get catalogPartCategoryLighting;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Phares'**
  String get catalogPartCategoryHeadlights;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Feux arrière'**
  String get catalogPartCategoryTailLights;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Ampoules'**
  String get catalogPartCategoryBulbs;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Capteurs & Sondes'**
  String get catalogPartCategorySensors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Sonde lambda'**
  String get catalogPartCategoryOxygenSensor;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Capteur ABS'**
  String get catalogPartCategoryABSSensor;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Capteur de pression'**
  String get catalogPartCategoryPressureSensor;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Carrosserie'**
  String get catalogPartCategoryBodywork;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Vitrage'**
  String get catalogPartCategoryGlass;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Pare-brise'**
  String get catalogPartCategoryWindscreen;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Vitre latérale'**
  String get catalogPartCategorySideWindow;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Lunette arrière'**
  String get catalogPartCategoryRearWindow;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Rétroviseurs'**
  String get catalogPartCategoryMirrors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Pare-chocs'**
  String get catalogPartCategoryBumpers;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Capot & Portes'**
  String get catalogPartCategoryBonnetDoors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Joints d\'étanchéité'**
  String get catalogPartCategorySeals;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Climatisation'**
  String get catalogPartCategoryAirConditioning;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Compresseur de clim'**
  String get catalogPartCategoryAirConditioningCompressor;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Condenseur'**
  String get catalogPartCategoryCondenser;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Détendeur'**
  String get catalogPartCategoryExpansionValve;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Gaz réfrigérant'**
  String get catalogPartCategoryRefrigerant;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Pneus & Roues'**
  String get catalogPartCategoryTyresWheels;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Pneus'**
  String get catalogPartCategoryTyres;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Jantes'**
  String get catalogPartCategoryRims;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Valves & Accessoires'**
  String get catalogPartCategoryValvesAccessories;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Échappement'**
  String get catalogPartCategoryExhaust;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Silencieux'**
  String get catalogPartCategorySilencer;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Collecteur'**
  String get catalogPartCategoryExhaustManifold;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Catalyseur'**
  String get catalogPartCategoryCatalyticConverter;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'FAP / DPF'**
  String get catalogPartCategoryDPF;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Climatisation manuelle'**
  String get catalogEquipmentManualAirConditioning;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Climatisation automatique'**
  String get catalogEquipmentAutomaticAirConditioning;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Sièges ventilés'**
  String get catalogEquipmentVentilatedSeats;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Toit ouvrant'**
  String get catalogEquipmentSunroof;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Toit panoramique'**
  String get catalogEquipmentPanoramicRoof;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Vitres électriques avant'**
  String get catalogEquipmentFrontElectricWindows;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Vitres électriques arrière'**
  String get catalogEquipmentRearElectricWindows;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Rétroviseurs électriques'**
  String get catalogEquipmentElectricMirrors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Rétroviseurs rabattables électr.'**
  String get catalogEquipmentPowerFoldingMirrors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Volant réglable en hauteur'**
  String get catalogEquipmentHeightAdjustableSteeringWheel;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Siège conducteur électrique'**
  String get catalogEquipmentElectricDriverSSeat;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Accès et démarrage sans clé'**
  String get catalogEquipmentKeylessEntryAndStart;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Direction assistée électrique'**
  String get catalogEquipmentElectricPowerSteering;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'ABS'**
  String get catalogEquipmentABS;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'ESP / Contrôle de stabilité'**
  String get catalogEquipmentESPStabilityControl;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Aide au freinage d\'urgence (BA)'**
  String get catalogEquipmentEmergencyBrakeAssistBA;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Airbags frontaux'**
  String get catalogEquipmentFrontAirbags;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Airbags latéraux'**
  String get catalogEquipmentSideAirbags;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Airbags rideaux'**
  String get catalogEquipmentCurtainAirbags;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle de traction (ASR)'**
  String get catalogEquipmentTractionControlASR;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Aide au démarrage en côte'**
  String get catalogEquipmentHillStartAssist;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Freins à disques avant'**
  String get catalogEquipmentFrontDiscBrakes;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Freins à disques 4 roues'**
  String get catalogEquipmentFourWheelDiscBrakes;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Ancrage siège enfant'**
  String get catalogEquipmentChildSeatAnchors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Autoradio'**
  String get catalogEquipmentCarRadio;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Écran tactile'**
  String get catalogEquipmentTouchscreen;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Bluetooth'**
  String get catalogEquipmentBluetooth;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Android Auto'**
  String get catalogEquipmentAndroidAuto;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Apple CarPlay'**
  String get catalogEquipmentAppleCarPlay;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'GPS intégré'**
  String get catalogEquipmentBuiltInGPS;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Prise USB'**
  String get catalogEquipmentUSBPort;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Haut-parleurs premium'**
  String get catalogEquipmentPremiumSpeakers;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Chargeur à induction'**
  String get catalogEquipmentWirelessCharger;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Triangle de signalisation'**
  String get catalogEquipmentWarningTriangle;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Roue de secours'**
  String get catalogEquipmentSpareWheel;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Cric'**
  String get catalogEquipmentJack;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Clé de roue'**
  String get catalogEquipmentWheelWrench;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Boîte à pharmacie'**
  String get catalogEquipmentFirstAidKit;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Gilet réfléchissant'**
  String get catalogEquipmentReflectiveVest;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Câbles de démarrage'**
  String get catalogEquipmentJumpLeads;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Manuel du propriétaire'**
  String get catalogEquipmentOwnerSManual;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Carnet d\'entretien'**
  String get catalogEquipmentServiceBook;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Caméra de recul'**
  String get catalogEquipmentReversingCamera;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Caméra 360°'**
  String get catalogEquipment360Camera;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Radar de recul'**
  String get catalogEquipmentRearParkingSensors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Radar avant'**
  String get catalogEquipmentFrontParkingSensors;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Régulateur de vitesse'**
  String get catalogEquipmentCruiseControl;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Régulateur adaptatif (ACC)'**
  String get catalogEquipmentAdaptiveCruiseControlACC;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Alerte sortie de voie'**
  String get catalogEquipmentLaneDepartureWarning;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Détecteur d\'angle mort'**
  String get catalogEquipmentBlindSpotMonitor;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Freinage automatique d\'urgence'**
  String get catalogEquipmentAutomaticEmergencyBraking;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Affichage tête haute (HUD)'**
  String get catalogEquipmentHeadUpDisplayHUD;

  /// Controlled catalogue reference; custom names remain unchanged.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance des panneaux'**
  String get catalogEquipmentTrafficSignRecognition;

  /// Fourchette de consommation officielle, nombres formatés dans la langue choisie.
  ///
  /// In fr, this message translates to:
  /// **'{min} à {max} l/100 km'**
  String garageConsumptionRange(String min, String max);

  /// Consommation officielle réduite à une seule valeur — la fourchette quand ses deux bornes se confondent. En minuscule comme la fourchette : c'est la forme que l'application a toujours écrite en français.
  ///
  /// In fr, this message translates to:
  /// **'{value} l/100 km'**
  String garageConsumptionSingle(String value);

  /// Organisme canadien source des cotes officielles, code nrcan.
  ///
  /// In fr, this message translates to:
  /// **'Ressources naturelles Canada'**
  String get garageConsumptionSourceCanada;

  /// Organisme européen source des cotes officielles, code eea.
  ///
  /// In fr, this message translates to:
  /// **'Agence europeenne pour l\'environnement'**
  String get garageConsumptionSourceEurope;

  /// Protocole d'homologation canadien à cinq cycles, code 5-cycle.
  ///
  /// In fr, this message translates to:
  /// **'Protocole canadien équivalent cinq cycles'**
  String get garageConsumptionCycleCanadianFive;

  /// Ancien protocole d'homologation canadien à deux cycles, code 2-cycle.
  ///
  /// In fr, this message translates to:
  /// **'essai canadien, deux cycles'**
  String get garageConsumptionCycleCanadianTwo;

  /// Protocole d'homologation WLTP, code wltp.
  ///
  /// In fr, this message translates to:
  /// **'norme WLTP'**
  String get garageConsumptionCycleWltp;

  /// Ancien protocole d'homologation NEDC, code nedc.
  ///
  /// In fr, this message translates to:
  /// **'ancienne norme NEDC'**
  String get garageConsumptionCycleNedc;

  /// Boîte automatique des cotes de consommation, codes A et AS.
  ///
  /// In fr, this message translates to:
  /// **'boîte auto.'**
  String get garageEngineAutomatic;

  /// Boîte manuelle des cotes de consommation, code M.
  ///
  /// In fr, this message translates to:
  /// **'boîte manuelle'**
  String get garageEngineManual;

  /// Boîte robotisée des cotes de consommation, code AM.
  ///
  /// In fr, this message translates to:
  /// **'boîte robotisée'**
  String get garageEngineAutomatedManual;

  /// Boîte à variation continue des cotes de consommation, code AV.
  ///
  /// In fr, this message translates to:
  /// **'boîte à variation continue'**
  String get garageEngineCvt;

  /// Transmission et nombre de rapports pour identifier une motorisation officielle.
  ///
  /// In fr, this message translates to:
  /// **'{transmission} {gears}'**
  String garageEngineTransmissionGears(String transmission, int gears);

  /// Carburant de la cote NRCan, code X.
  ///
  /// In fr, this message translates to:
  /// **'Essence ordinaire'**
  String get garageConsumptionFuelRegularPetrol;

  /// Carburant de la cote NRCan, code Z.
  ///
  /// In fr, this message translates to:
  /// **'Essence super'**
  String get garageConsumptionFuelPremiumPetrol;

  /// Carburant de la cote NRCan, code E.
  ///
  /// In fr, this message translates to:
  /// **'Ethanol (E85)'**
  String get garageConsumptionFuelEthanol;

  /// Carburant de la cote NRCan, code N.
  ///
  /// In fr, this message translates to:
  /// **'Gaz naturel'**
  String get garageConsumptionFuelNaturalGas;

  /// Carburant de la cote NRCan, code L.
  ///
  /// In fr, this message translates to:
  /// **'GPL'**
  String get garageConsumptionFuelLpg;

  /// Carburant de la cote NRCan, code H.
  ///
  /// In fr, this message translates to:
  /// **'Hybride rechargeable'**
  String get garageConsumptionFuelPlugInHybrid;

  /// Véhicule de repli dans le titre des pièces compatibles d'une catégorie.
  ///
  /// In fr, this message translates to:
  /// **'mon véhicule'**
  String get garageMyVehicle;

  /// Placeholder for a vehicle reference selector.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner…'**
  String get vehiclesReferenceSelect;

  /// Disabled dependent vehicle reference selector.
  ///
  /// In fr, this message translates to:
  /// **'Choisir d\'abord la valeur précédente'**
  String get vehiclesReferenceChoosePrevious;

  /// Legacy controlled equipment reference; custom names are preserved.
  ///
  /// In fr, this message translates to:
  /// **'Sièges cuir'**
  String get catalogEquipmentLeatherSeats;

  /// No description provided for @garageConsumptionCorresponding.
  ///
  /// In fr, this message translates to:
  /// **'Référence de cette version'**
  String get garageConsumptionCorresponding;

  /// No description provided for @garageConsumptionApproximate.
  ///
  /// In fr, this message translates to:
  /// **'Référence approchante'**
  String get garageConsumptionApproximate;

  /// No description provided for @garageConsumptionIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Version à préciser'**
  String get garageConsumptionIncomplete;

  /// No description provided for @garageConsumptionLegacy.
  ///
  /// In fr, this message translates to:
  /// **'Référence héritée à vérifier'**
  String get garageConsumptionLegacy;

  /// No description provided for @garageConsumptionWithdrawn.
  ///
  /// In fr, this message translates to:
  /// **'Référence retirée'**
  String get garageConsumptionWithdrawn;

  /// No description provided for @garageConsumptionUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Consommation de référence indisponible'**
  String get garageConsumptionUnavailable;

  /// No description provided for @garageConsumptionDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails et source'**
  String get garageConsumptionDetails;

  /// No description provided for @garageConsumptionChoose.
  ///
  /// In fr, this message translates to:
  /// **'Préciser la version'**
  String get garageConsumptionChoose;

  /// No description provided for @garageConsumptionChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer la référence'**
  String get garageConsumptionChange;

  /// No description provided for @garageConsumptionSelectionNotice.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une référence ne constitue pas une vérification documentaire du véhicule.'**
  String get garageConsumptionSelectionNotice;

  /// No description provided for @garageConsumptionNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Correspondance documentaire non vérifiée'**
  String get garageConsumptionNotVerified;

  /// No description provided for @garageConsumptionMarketUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Marché d’origine inconnu'**
  String get garageConsumptionMarketUnknown;

  /// No description provided for @garageConsumptionYearMissing.
  ///
  /// In fr, this message translates to:
  /// **'Année de référence inconnue'**
  String get garageConsumptionYearMissing;

  /// No description provided for @garageConsumptionSourceUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Source non renseignée'**
  String get garageConsumptionSourceUnknown;

  /// No description provided for @garageConsumptionCycleUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Protocole non renseigné'**
  String get garageConsumptionCycleUnknown;

  /// No description provided for @garageConsumptionMethodTest.
  ///
  /// In fr, this message translates to:
  /// **'Méthode : essai'**
  String get garageConsumptionMethodTest;

  /// No description provided for @garageConsumptionMethodAdjustment.
  ///
  /// In fr, this message translates to:
  /// **'Méthode : ajustement'**
  String get garageConsumptionMethodAdjustment;

  /// No description provided for @garageConsumptionMethodAggregation.
  ///
  /// In fr, this message translates to:
  /// **'Méthode : agrégation d’immatriculations'**
  String get garageConsumptionMethodAggregation;

  /// No description provided for @garageConsumptionMethodTranscription.
  ///
  /// In fr, this message translates to:
  /// **'Méthode : transcription documentaire'**
  String get garageConsumptionMethodTranscription;

  /// No description provided for @garageConsumptionMethodUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Méthode non établie'**
  String get garageConsumptionMethodUnknown;

  /// No description provided for @garageConsumptionLimitedSample.
  ///
  /// In fr, this message translates to:
  /// **'Résultat issu d’un échantillon limité ; il ne décrit pas un exemplaire précis.'**
  String get garageConsumptionLimitedSample;

  /// No description provided for @garageConsumptionMissingDetails.
  ///
  /// In fr, this message translates to:
  /// **'Les informations absentes restent inconnues. Aucun rapprochement exact n’est déduit du seul modèle.'**
  String get garageConsumptionMissingDetails;

  /// No description provided for @garageConsumptionChooseInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Comparez l’année, le marché, le moteur et la boîte. Plusieurs références peuvent décrire des variantes ou des protocoles différents.'**
  String get garageConsumptionChooseInstruction;

  /// No description provided for @garageConsumptionNoCandidates.
  ///
  /// In fr, this message translates to:
  /// **'Aucune référence de consommation disponible pour ce modèle.'**
  String get garageConsumptionNoCandidates;

  /// No description provided for @garageConsumptionCandidatesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Liste des références indisponible. Réessayez plus tard.'**
  String get garageConsumptionCandidatesUnavailable;

  /// No description provided for @garageConsumptionMissingModel.
  ///
  /// In fr, this message translates to:
  /// **'Consommation indisponible : le modèle de ce véhicule n’est pas encore au catalogue.'**
  String get garageConsumptionMissingModel;

  /// No description provided for @garageConsumptionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Référence sélectionnée. Consultez son niveau de correspondance.'**
  String get garageConsumptionSaved;

  /// No description provided for @garageConsumptionSourceTarget.
  ///
  /// In fr, this message translates to:
  /// **'le document source'**
  String get garageConsumptionSourceTarget;

  /// No description provided for @garageConsumptionOpenSource.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le document source'**
  String get garageConsumptionOpenSource;

  /// No description provided for @garageConsumptionReasonYear.
  ///
  /// In fr, this message translates to:
  /// **'Le millésime de la référence diffère de l’année renseignée.'**
  String get garageConsumptionReasonYear;

  /// No description provided for @garageConsumptionReasonMarket.
  ///
  /// In fr, this message translates to:
  /// **'Le marché de commercialisation n’est pas confirmé.'**
  String get garageConsumptionReasonMarket;

  /// No description provided for @garageConsumptionReasonAggregation.
  ///
  /// In fr, this message translates to:
  /// **'Une agrégation ne constitue pas la cote exacte de ce véhicule.'**
  String get garageConsumptionReasonAggregation;

  /// No description provided for @garageConsumptionReasonLegacy.
  ///
  /// In fr, this message translates to:
  /// **'Cette ancienne référence reste à requalifier.'**
  String get garageConsumptionReasonLegacy;

  /// No description provided for @garageConsumptionReasonIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Des caractéristiques nécessaires au rapprochement restent inconnues.'**
  String get garageConsumptionReasonIncomplete;

  /// No description provided for @garageConsumptionReasonContradiction.
  ///
  /// In fr, this message translates to:
  /// **'La référence contredit les caractéristiques renseignées.'**
  String get garageConsumptionReasonContradiction;

  /// No description provided for @garageConsumptionReasonUnverified.
  ///
  /// In fr, this message translates to:
  /// **'La version sélectionnée n’a pas été vérifiée sur un document.'**
  String get garageConsumptionReasonUnverified;

  /// No description provided for @garageConsumptionSourceValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur de la source : {value} L/100 km'**
  String garageConsumptionSourceValue(String value);

  /// No description provided for @garageConsumptionVehicleYear.
  ///
  /// In fr, this message translates to:
  /// **'Année renseignée : {year}'**
  String garageConsumptionVehicleYear(int year);

  /// No description provided for @garageConsumptionModelYear.
  ///
  /// In fr, this message translates to:
  /// **'Millésime de référence : {year}'**
  String garageConsumptionModelYear(int year);

  /// No description provided for @garageConsumptionRegistrationYear.
  ///
  /// In fr, this message translates to:
  /// **'Année du registre : {year}'**
  String garageConsumptionRegistrationYear(int year);

  /// No description provided for @garageConsumptionUnknownYear.
  ///
  /// In fr, this message translates to:
  /// **'Année de référence : {year} (type non établi)'**
  String garageConsumptionUnknownYear(int year);

  /// No description provided for @garageConsumptionMarket.
  ///
  /// In fr, this message translates to:
  /// **'Marché de référence : {market}'**
  String garageConsumptionMarket(String market);

  /// No description provided for @garageConsumptionSource.
  ///
  /// In fr, this message translates to:
  /// **'Source : {source}'**
  String garageConsumptionSource(String source);

  /// No description provided for @garageConsumptionProtocol.
  ///
  /// In fr, this message translates to:
  /// **'Protocole : {cycle}'**
  String garageConsumptionProtocol(String cycle);

  /// No description provided for @garageConsumptionVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérification documentaire : {date}'**
  String garageConsumptionVerified(String date);

  /// No description provided for @garageConsumptionImported.
  ///
  /// In fr, this message translates to:
  /// **'Import : {date}'**
  String garageConsumptionImported(String date);

  /// No description provided for @garageConsumptionPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publication : {date}'**
  String garageConsumptionPublished(String date);

  /// No description provided for @garageConsumptionRevision.
  ///
  /// In fr, this message translates to:
  /// **'Révision : {revision}'**
  String garageConsumptionRevision(String revision);

  /// No description provided for @garageConsumptionResource.
  ///
  /// In fr, this message translates to:
  /// **'Ressource : {resource}'**
  String garageConsumptionResource(String resource);

  /// No description provided for @garageConsumptionHash.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte SHA-256 : {hash}'**
  String garageConsumptionHash(String hash);

  /// No description provided for @garageConsumptionRecords.
  ///
  /// In fr, this message translates to:
  /// **'Effectif : {count}'**
  String garageConsumptionRecords(String count);

  /// No description provided for @garageConsumptionVersionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Références pour votre {model}'**
  String garageConsumptionVersionTitle(String model);

  /// No description provided for @garageConsumptionReasonRevision.
  ///
  /// In fr, this message translates to:
  /// **'Une révision plus récente existe ; ce choix conserve sa référence initiale.'**
  String get garageConsumptionReasonRevision;

  /// No description provided for @garageConsumptionSourceRecord.
  ///
  /// In fr, this message translates to:
  /// **'Ligne/enregistrement source : {record}'**
  String garageConsumptionSourceRecord(String record);

  /// No description provided for @garageConsumptionOriginalUnit.
  ///
  /// In fr, this message translates to:
  /// **'Unité d’origine : {unit}'**
  String garageConsumptionOriginalUnit(String unit);

  /// No description provided for @garageConsumptionLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence indiquée par la ressource : {license}'**
  String garageConsumptionLicense(String license);

  /// No description provided for @catalogDeclaredConsumption.
  ///
  /// In fr, this message translates to:
  /// **'Consommation déclarée par le vendeur'**
  String get catalogDeclaredConsumption;

  /// No description provided for @catalogConsumptionReferences.
  ///
  /// In fr, this message translates to:
  /// **'Comparer les références de consommation'**
  String get catalogConsumptionReferences;

  /// No description provided for @catalogConsumptionComparisonNotice.
  ///
  /// In fr, this message translates to:
  /// **'Ces références décrivent des versions et protocoles distincts. Aucune n’est attribuée à cette annonce.'**
  String get catalogConsumptionComparisonNotice;

  /// No description provided for @garageConsumptionRetrieved.
  ///
  /// In fr, this message translates to:
  /// **'Récupération : {date}'**
  String garageConsumptionRetrieved(String date);

  /// No description provided for @garageConsumptionSourceCity.
  ///
  /// In fr, this message translates to:
  /// **'Valeur ville de la source : {value} L/100 km'**
  String garageConsumptionSourceCity(String value);

  /// No description provided for @garageConsumptionSourceHighway.
  ///
  /// In fr, this message translates to:
  /// **'Valeur route de la source : {value} L/100 km'**
  String garageConsumptionSourceHighway(String value);

  /// No description provided for @garageConsumptionFuelHybridUnspecified.
  ///
  /// In fr, this message translates to:
  /// **'Hybride (type à préciser)'**
  String get garageConsumptionFuelHybridUnspecified;

  /// No description provided for @garageMeasuredConsumptionValue.
  ///
  /// In fr, this message translates to:
  /// **'{value} l/100 km'**
  String garageMeasuredConsumptionValue(String value);

  /// No description provided for @privateSalesSubmitPhotosRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins une photo.'**
  String get privateSalesSubmitPhotosRequired;

  /// No description provided for @privateSalesSubmitConsentRequired.
  ///
  /// In fr, this message translates to:
  /// **'Cochez les deux cases ci-dessus.'**
  String get privateSalesSubmitConsentRequired;

  /// No description provided for @privateSalesRejectReasonMinimumHint.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 5 caractères.'**
  String get privateSalesRejectReasonMinimumHint;

  /// No description provided for @privateSalesRejectReasonTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 5 caractères : le vendeur doit comprendre quoi corriger.'**
  String get privateSalesRejectReasonTooShort;

  /// No description provided for @settingsContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contact AutoParc'**
  String get settingsContactTitle;

  /// No description provided for @settingsContactSaved.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de contact AutoParc enregistré.'**
  String get settingsContactSaved;

  /// No description provided for @settingsContactAccessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé aux administrateurs et responsables.'**
  String get settingsContactAccessDenied;

  /// No description provided for @settingsContactPhoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Numéro pour joindre AutoParc'**
  String get settingsContactPhoneTitle;

  /// No description provided for @settingsContactPhoneDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est utilisé pour les appels et WhatsApp dans l’application.'**
  String get settingsContactPhoneDescription;

  /// No description provided for @settingsContactPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone avec indicatif international'**
  String get settingsContactPhoneLabel;

  /// No description provided for @settingsContactCountryCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Incluez + et l’indicatif du pays.'**
  String get settingsContactCountryCodeHelp;

  /// No description provided for @settingsContactPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro international valide, par exemple +226 75 57 04 84.'**
  String get settingsContactPhoneInvalid;

  /// No description provided for @settingsContactSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le numéro'**
  String get settingsContactSave;

  /// No description provided for @settingsContactSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get settingsContactSaving;

  /// No description provided for @shellContactSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres · Contact AutoParc'**
  String get shellContactSettings;

  /// No description provided for @inspectionBadgeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Inspecté par AutoParc'**
  String get inspectionBadgeLabel;

  /// No description provided for @inspectionAttentionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Points à prévoir'**
  String get inspectionAttentionLabel;

  /// No description provided for @inspectionBlockingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Défauts bloquants signalés'**
  String get inspectionBlockingLabel;

  /// No description provided for @inspectionReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport d’inspection'**
  String get inspectionReportTitle;

  /// No description provided for @inspectionScopeNote.
  ///
  /// In fr, this message translates to:
  /// **'Constat à la date et au kilométrage indiqués, limité aux points ci-dessous.'**
  String get inspectionScopeNote;

  /// No description provided for @inspectionDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date du contrôle'**
  String get inspectionDateLabel;

  /// No description provided for @inspectionMileageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Kilométrage relevé'**
  String get inspectionMileageLabel;

  /// No description provided for @inspectionValidUntilLabel.
  ///
  /// In fr, this message translates to:
  /// **'Valable jusqu’au'**
  String get inspectionValidUntilLabel;

  /// Nombre de points réellement contrôlés, hors points non contrôlés.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 point contrôlé} other{{count} points contrôlés}}'**
  String inspectionCheckedCount(int count);

  /// No description provided for @inspectionSummaryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compte rendu'**
  String get inspectionSummaryLabel;

  /// No description provided for @inspectionStatusOk.
  ///
  /// In fr, this message translates to:
  /// **'Contrôlé : aucun défaut relevé'**
  String get inspectionStatusOk;

  /// No description provided for @inspectionStatusAttention.
  ///
  /// In fr, this message translates to:
  /// **'À prévoir'**
  String get inspectionStatusAttention;

  /// No description provided for @inspectionStatusBlocking.
  ///
  /// In fr, this message translates to:
  /// **'Défaut bloquant'**
  String get inspectionStatusBlocking;

  /// No description provided for @inspectionStatusNotChecked.
  ///
  /// In fr, this message translates to:
  /// **'Non contrôlé'**
  String get inspectionStatusNotChecked;

  /// No description provided for @inspectionReportUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce rapport n’est plus disponible. Actualisez la fiche du véhicule.'**
  String get inspectionReportUnavailable;

  /// No description provided for @inspectionClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get inspectionClose;

  /// No description provided for @inspectionAdd.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une inspection'**
  String get inspectionAdd;

  /// No description provided for @inspectionReplace.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une nouvelle inspection'**
  String get inspectionReplace;

  /// No description provided for @inspectionWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l’inspection'**
  String get inspectionWithdraw;

  /// No description provided for @inspectionHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des inspections'**
  String get inspectionHistory;

  /// No description provided for @inspectionHistoryActive.
  ///
  /// In fr, this message translates to:
  /// **'Inspection en cours'**
  String get inspectionHistoryActive;

  /// No description provided for @inspectionHistoryWithdrawn.
  ///
  /// In fr, this message translates to:
  /// **'Retirée'**
  String get inspectionHistoryWithdrawn;

  /// No description provided for @inspectionHistorySuperseded.
  ///
  /// In fr, this message translates to:
  /// **'Remplacée'**
  String get inspectionHistorySuperseded;

  /// No description provided for @inspectionHistoryExpired.
  ///
  /// In fr, this message translates to:
  /// **'Validité expirée'**
  String get inspectionHistoryExpired;

  /// No description provided for @inspectionHistoryInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inspection inactive'**
  String get inspectionHistoryInactive;

  /// No description provided for @inspectionMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir les inspections précédentes'**
  String get inspectionMore;

  /// No description provided for @inspectionFormTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inspection AutoParc'**
  String get inspectionFormTitle;

  /// No description provided for @inspectionFormIntro.
  ///
  /// In fr, this message translates to:
  /// **'À remplir après un contrôle physique du véhicule. Sélectionnez uniquement les points réellement contrôlés et consignez les défauts constatés.'**
  String get inspectionFormIntro;

  /// No description provided for @inspectionDateFuture.
  ///
  /// In fr, this message translates to:
  /// **'La date du contrôle ne peut pas être dans le futur.'**
  String get inspectionDateFuture;

  /// No description provided for @inspectionMileageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le kilométrage relevé en kilomètres.'**
  String get inspectionMileageRequired;

  /// No description provided for @inspectionSummaryRequired.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez le compte rendu du contrôle.'**
  String get inspectionSummaryRequired;

  /// No description provided for @inspectionPointLabel.
  ///
  /// In fr, this message translates to:
  /// **'Point de contrôle'**
  String get inspectionPointLabel;

  /// No description provided for @inspectionPointHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. freinage, moteur, carrosserie'**
  String get inspectionPointHint;

  /// No description provided for @inspectionPointNote.
  ///
  /// In fr, this message translates to:
  /// **'Observation (facultatif)'**
  String get inspectionPointNote;

  /// No description provided for @inspectionPointStatus.
  ///
  /// In fr, this message translates to:
  /// **'Résultat du contrôle'**
  String get inspectionPointStatus;

  /// No description provided for @inspectionPointRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nommez le point de contrôle.'**
  String get inspectionPointRequired;

  /// No description provided for @inspectionAddPoint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un point de contrôle'**
  String get inspectionAddPoint;

  /// No description provided for @inspectionRemovePoint.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce point'**
  String get inspectionRemovePoint;

  /// No description provided for @inspectionAtLeastOneChecked.
  ///
  /// In fr, this message translates to:
  /// **'Contrôlez au moins un point avant d’enregistrer l’inspection.'**
  String get inspectionAtLeastOneChecked;

  /// No description provided for @inspectionConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Je confirme qu’AutoParc a physiquement contrôlé ce véhicule et que ce rapport décrit les points vérifiés.'**
  String get inspectionConfirmation;

  /// No description provided for @inspectionConfirmationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le contrôle physique du véhicule.'**
  String get inspectionConfirmationRequired;

  /// No description provided for @inspectionSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer l’inspection'**
  String get inspectionSave;

  /// No description provided for @inspectionSaved.
  ///
  /// In fr, this message translates to:
  /// **'Inspection enregistrée.'**
  String get inspectionSaved;

  /// No description provided for @inspectionValidityOptional.
  ///
  /// In fr, this message translates to:
  /// **'Préciser une fin de validité (facultatif)'**
  String get inspectionValidityOptional;

  /// No description provided for @inspectionValidityDateError.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une fin de validité postérieure au contrôle.'**
  String get inspectionValidityDateError;

  /// No description provided for @inspectionChooseDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get inspectionChooseDate;

  /// No description provided for @inspectionWithdrawTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette inspection ?'**
  String get inspectionWithdrawTitle;

  /// No description provided for @inspectionWithdrawReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif du retrait'**
  String get inspectionWithdrawReason;

  /// No description provided for @inspectionWithdrawReasonRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le motif du retrait.'**
  String get inspectionWithdrawReasonRequired;

  /// No description provided for @inspectionWithdrawConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get inspectionWithdrawConfirm;

  /// No description provided for @inspectionWithdrawn.
  ///
  /// In fr, this message translates to:
  /// **'Inspection retirée.'**
  String get inspectionWithdrawn;

  /// No description provided for @faultDeclarationTitle.
  ///
  /// In fr, this message translates to:
  /// **'État déclaré'**
  String get faultDeclarationTitle;

  /// No description provided for @faultDeclarationUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get faultDeclarationUnknown;

  /// No description provided for @faultDeclarationNoneSeller.
  ///
  /// In fr, this message translates to:
  /// **'Aucun défaut déclaré par le vendeur'**
  String get faultDeclarationNoneSeller;

  /// No description provided for @faultDeclarationHasFaults.
  ///
  /// In fr, this message translates to:
  /// **'Des défauts sont déclarés'**
  String get faultDeclarationHasFaults;

  /// No description provided for @faultDeclarationSellerNote.
  ///
  /// In fr, this message translates to:
  /// **'Informations déclarées par le vendeur. Elles ne constituent pas un contrôle AutoParc.'**
  String get faultDeclarationSellerNote;

  /// Date de déclaration du vendeur, fournie par le serveur. Ce n’est pas une date d’inspection.
  ///
  /// In fr, this message translates to:
  /// **'Déclaration du {date}'**
  String faultDeclarationDate(String date);

  /// Défauts dont le statut est différent de repaired. wont_fix compte comme non réparé, même si la maintenance est clôturée.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun défaut non réparé déclaré} one{1 défaut non réparé déclaré} other{{count} défauts non réparés déclarés}}'**
  String faultDeclarationUnresolvedCount(int count);

  /// No description provided for @faultDeclarationUnrepaired.
  ///
  /// In fr, this message translates to:
  /// **'Non réparé'**
  String get faultDeclarationUnrepaired;

  /// No description provided for @faultDeclarationDetailsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Des défauts ont été déclarés. Contactez AutoParc pour consulter les détails.'**
  String get faultDeclarationDetailsUnavailable;

  /// No description provided for @faultDeclarationPrivateSubmitRequired.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez l’état du véhicule : aucun défaut déclaré ou une liste de défauts.'**
  String get faultDeclarationPrivateSubmitRequired;

  /// No description provided for @faultDeclarationListRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins un défaut ou choisissez explicitement un autre état.'**
  String get faultDeclarationListRequired;

  /// No description provided for @faultDeclarationInvalidFault.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les défauts déclarés avant d’enregistrer.'**
  String get faultDeclarationInvalidFault;

  /// No description provided for @faultDeclarationFilterNoUnrepaired.
  ///
  /// In fr, this message translates to:
  /// **'Sans défaut non réparé déclaré'**
  String get faultDeclarationFilterNoUnrepaired;

  /// No description provided for @faultDeclarationChoiceHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez explicitement l’état déclaré. Une liste vide ne vaut pas une déclaration d’absence de défaut.'**
  String get faultDeclarationChoiceHint;

  /// No description provided for @faultDeclarationAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un défaut'**
  String get faultDeclarationAdd;

  /// No description provided for @faultDeclarationEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le défaut'**
  String get faultDeclarationEdit;

  /// No description provided for @faultDeclarationStatusLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statut déclaré'**
  String get faultDeclarationStatusLabel;

  /// No description provided for @faultDeclarationClearTitle.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les défauts saisis ?'**
  String get faultDeclarationClearTitle;

  /// No description provided for @faultDeclarationClearMessage.
  ///
  /// In fr, this message translates to:
  /// **'Choisir « Aucun défaut déclaré » retirera les défauts saisis de cette déclaration.'**
  String get faultDeclarationClearMessage;

  /// No description provided for @faultDeclarationClearConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Effacer et continuer'**
  String get faultDeclarationClearConfirm;

  /// No description provided for @faultDeclarationReadOnlyNotice.
  ///
  /// In fr, this message translates to:
  /// **'Ce défaut est géré par AutoParc. Sa modification est réservée au personnel.'**
  String get faultDeclarationReadOnlyNotice;

  /// No description provided for @faultDeclarationReadOnlyBlocksNone.
  ///
  /// In fr, this message translates to:
  /// **'Des défauts gérés par AutoParc restent présents. Vous ne pouvez pas effacer cette liste.'**
  String get faultDeclarationReadOnlyBlocksNone;

  /// No description provided for @faultDeclarationKeepFaultsBeforeUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Retirez d’abord les défauts modifiables pour passer à « Non renseigné ». Les défauts gérés par AutoParc restent conservés.'**
  String get faultDeclarationKeepFaultsBeforeUnknown;

  /// No description provided for @faultDeclarationChangedElsewhere.
  ///
  /// In fr, this message translates to:
  /// **'La déclaration a été actualisée pendant la saisie. Vérifiez son contenu avant de réessayer.'**
  String get faultDeclarationChangedElsewhere;

  /// No description provided for @faultDeclarationFaultLimit.
  ///
  /// In fr, this message translates to:
  /// **'La déclaration est limitée à 100 défauts.'**
  String get faultDeclarationFaultLimit;

  /// No description provided for @faultDeclarationTitleTooLong.
  ///
  /// In fr, this message translates to:
  /// **'L’intitulé ne doit pas dépasser 180 caractères.'**
  String get faultDeclarationTitleTooLong;

  /// No description provided for @faultDeclarationDescriptionTooLong.
  ///
  /// In fr, this message translates to:
  /// **'La description ne doit pas dépasser 5 000 caractères.'**
  String get faultDeclarationDescriptionTooLong;

  /// No description provided for @faultDeclarationApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get faultDeclarationApply;

  /// Type de boîte enregistré que cette version de l’application ne reconnaît pas.
  ///
  /// In fr, this message translates to:
  /// **'Boîte enregistrée : {type}'**
  String vehiclesSavedTransmissionType(String type);

  /// Boîte manuelle robotisée à simple embrayage, distincte du double embrayage.
  ///
  /// In fr, this message translates to:
  /// **'Robotisée (AMT)'**
  String get catalogTransmissionAutomatedManual;

  /// Transmission hybride de type e-CVT, distincte de la CVT mécanique.
  ///
  /// In fr, this message translates to:
  /// **'Hybride e-CVT'**
  String get catalogTransmissionECvt;

  /// Filter for vehicles inspected and validated by AutoParc.
  ///
  /// In fr, this message translates to:
  /// **'Validés par AutoParc'**
  String get catalogValidatedByAutoParc;

  /// No description provided for @passwordRecoveryForgot.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get passwordRecoveryForgot;

  /// No description provided for @passwordRecoveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer mon compte'**
  String get passwordRecoveryTitle;

  /// No description provided for @passwordRecoveryIntro.
  ///
  /// In fr, this message translates to:
  /// **'Recevez un lien par email pour choisir un nouveau mot de passe.'**
  String get passwordRecoveryIntro;

  /// No description provided for @passwordRecoveryAccountType.
  ///
  /// In fr, this message translates to:
  /// **'Quel espace utilisez-vous ?'**
  String get passwordRecoveryAccountType;

  /// No description provided for @passwordRecoveryClient.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get passwordRecoveryClient;

  /// No description provided for @passwordRecoveryStaff.
  ///
  /// In fr, this message translates to:
  /// **'Personnel AutoParc'**
  String get passwordRecoveryStaff;

  /// No description provided for @passwordRecoveryPartner.
  ///
  /// In fr, this message translates to:
  /// **'Compte partenaire'**
  String get passwordRecoveryPartner;

  /// No description provided for @passwordRecoveryPartnerHelp.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez l’email associé à votre compte partenaire. Si vous vous êtes inscrit uniquement avec un téléphone, contactez AutoParc pour une récupération assistée.'**
  String get passwordRecoveryPartnerHelp;

  /// No description provided for @passwordRecoveryGoogleHelp.
  ///
  /// In fr, this message translates to:
  /// **'Si vous vous connectez avec Google, utilisez « Continuer avec Google ». Le mot de passe Google se récupère auprès de Google.'**
  String get passwordRecoveryGoogleHelp;

  /// No description provided for @passwordRecoverySend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get passwordRecoverySend;

  /// No description provided for @passwordRecoveryConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Si un compte correspondant peut recevoir un lien, vous recevrez un email de réinitialisation. Vérifiez aussi vos courriers indésirables.'**
  String get passwordRecoveryConfirmation;

  /// No description provided for @passwordRecoveryBackToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get passwordRecoveryBackToLogin;

  /// No description provided for @passwordRecoveryRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de demandes. Patientez quelques minutes avant de réessayer.'**
  String get passwordRecoveryRateLimited;

  /// No description provided for @passwordRecoveryUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La récupération par email est indisponible pour le moment. Réessayez plus tard ou contactez AutoParc.'**
  String get passwordRecoveryUnavailable;

  /// No description provided for @passwordRecoverySupportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d’aide ?'**
  String get passwordRecoverySupportTitle;

  /// No description provided for @passwordRecoverySupportHelp.
  ///
  /// In fr, this message translates to:
  /// **'Contactez AutoParc si vous n’avez pas d’email associé au compte ou si vous n’y avez plus accès. Votre identité devra être vérifiée avant toute récupération.'**
  String get passwordRecoverySupportHelp;
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
