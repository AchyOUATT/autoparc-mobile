import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La langue de l'interface : où elle est rangée, et pourquoi elle ne suit pas
/// l'appareil.
///
/// ── LE FRANÇAIS RESTE LE DÉFAUT, ET ON NE SUIT PAS LA LOCALE SYSTÈME ────────
///
/// C'est la décision qui demande le plus d'explication, parce qu'elle va contre
/// le réflexe : un `MaterialApp` sans `locale:` choisit tout seul parmi ses
/// `supportedLocales` d'après le réglage du téléphone, et c'est en général ce
/// qu'on veut.
///
/// Pas ici. Dans la sous-région, beaucoup d'appareils sortent de boîte en
/// anglais — y compris ceux de propriétaires qui ne lisent que le français, et
/// qui n'ont jamais touché à ce réglage parce que rien ne le leur a demandé.
/// Suivre la locale du système ferait donc basculer en anglais une partie du
/// parc DÉJÀ INSTALLÉ, à la simple mise à jour, sans que personne ne l'ait
/// demandé : un utilisateur qui ouvre l'application le lendemain trouve une
/// interface qu'il ne lit pas, et aucun moyen évident de revenir.
///
/// Un réglage explicite et persistant ne surprend personne : le parc existant
/// continue en français, et un anglophone trouve « Language » dans le tiroir —
/// c'est le seul endroit où l'application ait jamais rangé un réglage.
///
/// Conséquence assumée : un nouveau client anglophone voit son premier écran
/// en français. Le prix est payé une fois, par les arrivants, au lieu d'être
/// payé une fois par chaque utilisateur en place.
///
/// ── LE REPLI ────────────────────────────────────────────────────────────────
///
/// Le français est aussi le REPLI, et c'est vérifié et non supposé :
/// `app_fr.arb` est le gabarit de `gen-l10n`, donc une clé absente de
/// `app_en.arb` est générée avec le texte FRANÇAIS dans la classe anglaise.
/// Mesuré en ajoutant une clé au seul gabarit : `app_localizations_en.dart`
/// contenait alors
///
///     String get zzTestReplis => 'Texte de repli non traduit';
///
/// Le repli se décide donc à la GÉNÉRATION et non à l'exécution — il n'y a
/// aucune recherche de secours à l'affichage, et rien ne peut lever faute de
/// traduction. Avec 1 200 à 1 500 chaînes à traduire par vagues, c'est ce
/// repli qui permet de livrer un écran à la fois : les clés passent en
/// français, et l'anglais les rattrape.

/// Les deux locales servies. Écrites ici plutôt que relues de
/// `AppLocalizations.supportedLocales` : le code a besoin de DÉSIGNER le
/// français et l'anglais (le défaut, le repli, la comparaison du réglage), pas
/// seulement de parcourir une liste.
const Locale localeFrancais = Locale('fr');
const Locale localeAnglais = Locale('en');

/// Persistance du choix de langue.
///
/// Même forme que `OnboardingService` — des statiques, `shared_preferences`,
/// aucun provider — et pour la même raison : la valeur est lue dans `main()`,
/// avant que l'arbre de widgets existe, donc avant qu'un conteneur Riverpod
/// puisse la servir.
class LangueService {
  static const _cle = 'langue';

  /// La langue choisie, ou le français si personne n'a choisi.
  ///
  /// Le défaut est ici, en un seul endroit, et il est volontairement INSENSIBLE
  /// à `Platform.localeName` : voir l'en-tête de ce fichier.
  static Future<Locale> lire() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cle) == localeAnglais.languageCode
        ? localeAnglais
        : localeFrancais;
  }

  static Future<void> ecrire(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, locale.languageCode);
  }
}

/// La langue lue par `main()` avant `runApp`, injectée par surcharge.
///
/// Sans elle, l'application s'ouvrirait en français puis sauterait en anglais
/// dès la fin de la lecture asynchrone des préférences : un clignotement sur le
/// premier écran, à chaque lancement, pour tout utilisateur anglophone.
/// `main()` attend déjà `OnboardingService.isDone()` — une lecture de plus sur
/// la même instance de `SharedPreferences` ne coûte pas un aller-retour de
/// plus.
final localeInitialeProvider = Provider<Locale>((_) => localeFrancais);

/// La langue active, et le seul chemin pour la changer.
class Langue extends Notifier<Locale> {
  @override
  Locale build() => ref.read(localeInitialeProvider);

  /// Change la langue et l'écrit sur le disque.
  ///
  /// L'état est posé AVANT l'écriture : la bascule doit être immédiate à
  /// l'écran, et un échec d'écriture — disque plein, préférences inaccessibles
  /// — ramène au français au lancement suivant, c'est-à-dire à la locale de
  /// repli. L'ordre inverse rendrait la bascule muette le temps de l'écriture,
  /// pour se prémunir contre une panne dont la conséquence est bénigne.
  Future<void> definir(Locale locale) async {
    if (locale == state) return;
    state = locale;
    await LangueService.ecrire(locale);
  }
}

final langueProvider = NotifierProvider<Langue, Locale>(Langue.new);
