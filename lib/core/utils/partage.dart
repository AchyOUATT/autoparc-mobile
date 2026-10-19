import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';

// `currency_format.dart` n'est plus importé : plus aucun prix ne traverse ce
// fichier depuis que la vignette de la page publique le porte.
import 'contact_info.dart';

/// [TypeArticle] voyage avec `partagerArticle` : une fiche nomme ce qu'elle
/// partage sans avoir à connaître le fichier où vivent les adresses.
export 'contact_info.dart' show TypeArticle;

/// Compose le texte d'un article partagé.
///
/// Séparée de l'envoi parce qu'elle est la seule moitié vérifiable : `SharePlus`
/// passe par un MethodChannel, absent sous `flutter test`, alors que le texte se
/// teste en une ligne. Et c'est le texte qui porte tout le travail — c'est lui
/// qui arrive dans la conversation.
///
/// LE MESSAGE NE REDIT PLUS CE QUE L'APERÇU PORTE, et c'est le propriétaire
/// qui a vu le défaut : « le partage duplique les informations de l'article ».
///
/// Il avait raison, et la faute est de conception. Tant que le lien menait au
/// magasin d'applications, le texte devait tout porter — le destinataire
/// n'avait que lui. Depuis que le lien mène à la page publique de l'article,
/// WhatsApp va chercher ses balises Open Graph et affiche une vignette qui dit
/// DÉJÀ le nom, le prix et les caractéristiques. Brancher le lien sans alléger
/// le texte a produit, dans chaque partage réussi :
///
///     *Mazda CX-9 (2018)*              ← le texte
///     9 500 000 FCFA
///     111 000 km · Automatique · Essence
///     Disponible sur AutoParc :
///     https://…/v/86
///     ┌──────────────────────────────┐
///     │ [photo]                      │ ← la vignette, juste en dessous
///     │ Mazda CX-9 2018 — 9 500 000 FCFA
///     │ 2018 · D'occasion · 111 000 km · Automatique · Essence
///     └──────────────────────────────┘
///
/// Vérifié sur les trois types : la page en dit PLUS que le message dans
/// chacun — elle ajoute le fabricant, la garantie et la ville pour une pièce,
/// l'année et l'état pour un véhicule. Le texte n'apportait donc rien.
///
/// CE QU'ON PERD, et c'est assumé : quand l'instance Render dort, son robot
/// abandonne avant d'avoir lu la page — 35 secondes mesurées au réveil — et le
/// destinataire ne voit que ce texte. Il a alors le nom et un lien, plus le
/// prix. Le compromis penche du bon côté : la duplication se voyait à chaque
/// partage réussi, l'absence de prix ne gêne que quand le serveur dort.
///
/// [mentionBoutique] est passée par l'appelant plutôt que lue ici : cette
/// fonction est PURE — c'est ce qui la rend testable sans MethodChannel — et
/// n'a donc pas de `BuildContext` pour atteindre les traductions.
///
/// [type] et [id] donnent l'adresse de la page publique de l'article, et non
/// celle du magasin d'applications — voir `adresseArticle`, où est écrit
/// pourquoi ce lien-là est le seul qui mène quelque part.
///
/// Les astérisques autour du titre sont la mise en gras de WhatsApp. Ailleurs —
/// SMS, Facebook, presse-papier — ils s'affichent tels quels : deux caractères
/// inoffensifs. C'est le seul balisage qui ne dégrade rien nulle part.
String composerMessagePartage({
  required String titre,
  required String mentionBoutique,
  required TypeArticle type,
  required int id,
}) {
  return [
    '*${titre.trim()}* — ${mentionBoutique.trim()}',
    // L'adresse de l'article, et non celle du magasin : c'est elle que le robot
    // d'aperçu de WhatsApp va chercher. Sans elle, les balises Open Graph du
    // serveur ne sont lues par personne, et tout ce lot n'aurait servi à rien.
    adresseArticle(type, id),
  ].join('\n');
}

/// Ouvre la feuille de partage d'Android sur un article, et le dit quand elle
/// ne s'ouvre pas. Rend `true` si elle s'est ouverte.
///
/// Même principe que `ouvrirLien` dans `lien_externe.dart`, et pour la même
/// raison : « Nous contacter » appelait `launchUrl` sans garde, l'exception
/// partait dans le vide depuis un rappel de `onTap`, et rien ne se passait à
/// l'écran. Un bouton « Partager » sans effet serait exactement la même panne
/// muette, et personne ne saurait la signaler autrement que par « ça ne marche
/// pas ».
///
/// **Texte seul : aucun fichier n'est joint, et c'est délibéré.** La photo de
/// couverture partait auparavant en pièce jointe, puisée dans le cache de
/// `cached_network_image`. Sur WhatsApp, une image jointe produit un message
/// IMAGE dont le texte devient la légende — et les aperçus de lien ne se
/// rendent pas dans une légende. Photo jointe et aperçu sont donc mutuellement
/// exclusifs : garder la photo, c'était garantir qu'aucune vignette ne
/// s'afficherait jamais et que le destinataire recopierait le lien à la main.
/// L'aperçu rend la photo, le titre et le prix, et rend le tout cliquable ;
/// l'arbitrage lui revient.
///
/// Le contrecoup est réel et il faut le savoir : l'aperçu dépend du serveur.
/// L'instance gratuite de Render s'endort au bout de quinze minutes, et son
/// premier appel a été mesuré à 25 secondes. Quand le robot d'aperçu abandonne
/// avant, le destinataire reçoit un lien nu au lieu d'une vignette. Le lien
/// reste juste et la page s'affiche au clic : c'est la vignette seule qui se
/// perd, jamais la destination.
///
/// Le chemin photo — `_photoEnCache`, `_typeImage`, le paramètre `photoUrl` —
/// a été retiré plutôt que laissé en place : du code mort au raisonnement
/// subtil se fait rebrancher par quelqu'un qui n'a pas lu ce qui précède, et
/// toutes les vignettes disparaîtraient en silence. Il reste récupérable dans
/// l'historique.
///
/// Le repli n'est pas un message d'excuse : il copie le message. Quelqu'un dont
/// le téléphone refuse la feuille de partage peut encore le coller dans sa
/// conversation à la main. Une impasse devient une gêne.
///
/// On ne regarde pas le `ShareResultStatus` rendu : `dismissed` veut dire que
/// la feuille s'est bien ouverte et que l'utilisateur a renoncé — son droit —
/// et `unavailable` veut dire que la plateforme a partagé sans savoir dire
/// quoi, pas qu'elle a échoué. Les traiter en échec afficherait un avertissement
/// après un partage réussi. Seule une exception signale une vraie impasse :
/// c'est ce que lève `ACTION_SEND` quand aucune application ne sait recevoir.
/// `prix` et `precisions` ont DISPARU de cette signature, et c'est volontaire :
/// les laisser en paramètres ignorés aurait laissé croire aux trois fiches
/// qu'elles servaient encore à quelque chose. La vignette de l'aperçu les
/// porte — voir [composerMessagePartage].
Future<bool> partagerArticle(
  BuildContext context, {
  required String titre,
  required TypeArticle type,
  required int id,
}) async {
  final texte = composerMessagePartage(
    titre: titre,
    // Lue ici, où le contexte existe, et passée à la fonction pure.
    // Sans `!` : `l10n.yaml` pose `nullable-getter: false`, et un `!` de plus
    // était signalé par l'analyse — un `MaterialApp` sans délégué doit lever
    // au premier écran, pas se faire rattraper ici.
    mentionBoutique: AppLocalizations.of(context).partageMentionBoutique,
    type: type,
    id: id,
  );

  try {
    await SharePlus.instance.share(
      ShareParams(
        text: texte,
        // Sert de ligne d'objet si l'utilisateur choisit une messagerie.
        subject: titre,
      ),
    );
    return true;
  } catch (_) {
    // On ne distingue pas « aucune application capable » d'un refus du système :
    // les deux laissent l'utilisateur devant le même bouton sans effet.
    if (context.mounted) await _signalerEchec(context, texte);
    return false;
  }
}

/// Le repli : on copie, puis on le dit.
///
/// CE PAVÉ ÉTAIT LA DERNIÈRE PHRASE EN DUR DU PARCOURS CLIENT, et elle se
/// montrait là où elle coûtait le plus cher. Ce chemin n'est atteint que
/// lorsque la feuille de partage d'Android refuse de s'ouvrir ; un appareil
/// dont le propriétaire a changé la langue du système est précisément un
/// appareil dont l'inventaire d'applications n'est pas celui qu'on suppose.
/// Un anglophone recevait donc la panne EN FRANÇAIS, sur les trois fiches
/// clientes — pièce, accessoire, véhicule — qui passent toutes par
/// `partagerArticle`.
///
/// La clé `commonShareUnavailable` existait déjà dans les deux `.arb`, et
/// `gen-l10n` l'avait déjà rendue : seul ce site d'écriture ne la lisait pas.
/// Rien ne manquait donc, ni clé ni traduction — c'est le dernier maillon qui
/// n'avait pas été rebranché. Le contexte, lui, est là : `partagerArticle` le
/// reçoit, s'en sert dans la même fonction pour `partageMentionBoutique`, et
/// le passe ici en premier paramètre.
///
/// `const` a dû sauter devant `SnackBar` : `AppLocalizations.of` est une
/// lecture de l'arbre de widgets, qui n'a pas de valeur à la compilation. Le
/// `const` de `Duration` reste, lui. Comportement inchangé par ailleurs —
/// mêmes `behavior` et `duration` que `commonLinkUnavailable` dans
/// `lien_externe.dart`, dont ce repli est le jumeau.
Future<void> _signalerEchec(BuildContext context, String texte) async {
  await Clipboard.setData(ClipboardData(text: texte));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context).commonShareUnavailable),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ),
  );
}
