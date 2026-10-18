import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'contact_info.dart';
import 'currency_format.dart';

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
/// Le message doit se suffire à lui-même. Il atterrit sur le WhatsApp de
/// quelqu'un qui n'a probablement pas l'application : il lui faut le nom, le
/// prix, de quoi reconnaître l'article, et un moyen de revenir vers nous, sans
/// avoir à redemander quoi que ce soit.
///
/// [type] et [id] donnent l'adresse de la page publique de l'article, et non
/// plus celle du magasin d'applications — voir `adresseArticle`, où est écrit
/// pourquoi ce lien-là est le seul qui mène quelque part.
///
/// Les astérisques autour du titre sont la mise en gras de WhatsApp. Ailleurs —
/// SMS, Facebook, presse-papier — ils s'affichent tels quels : deux caractères
/// inoffensifs. C'est le seul balisage qui ne dégrade rien nulle part.
///
/// [precisions] est jointe par « · », et toute entrée nulle ou vide disparaît
/// plutôt que de laisser un séparateur orphelin ou un « null » dans le message.
/// Les trois types d'article n'ont pas les mêmes champs renseignés : un
/// accessoire n'a pas de référence constructeur, une pièce n'a pas de
/// kilométrage.
///
/// Un [prix] nul disparaît pour la même raison. Un véhicule en location seule
/// n'a pas de `sale_price`, et `formatXof(null)` rendrait un tiret cadratin
/// seul sur sa ligne — le destinataire y lirait une panne. Au besoin, le tarif
/// de location passe par [precisions].
String composerMessagePartage({
  required String titre,
  required TypeArticle type,
  required int id,
  double? prix,
  List<String?> precisions = const [],
}) {
  final details = precisions
      .whereType<String>()
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .join(' · ');

  return [
    '*${titre.trim()}*',
    if (prix != null) formatXof(prix),
    if (details.isNotEmpty) details,
    '',
    'Disponible sur AutoParc :',
    // L'adresse de l'article, et non celle du magasin : c'est elle que le robot
    // d'aperçu de WhatsApp va chercher. Sans elle, les balises Open Graph du
    // serveur ne sont lues par personne.
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
Future<bool> partagerArticle(
  BuildContext context, {
  required String titre,
  required TypeArticle type,
  required int id,
  double? prix,
  List<String?> precisions = const [],
}) async {
  final texte = composerMessagePartage(
    titre: titre,
    type: type,
    id: id,
    prix: prix,
    precisions: precisions,
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

Future<void> _signalerEchec(BuildContext context, String texte) async {
  await Clipboard.setData(ClipboardData(text: texte));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Impossible d\'ouvrir le partage sur cet appareil. '
        'Le message a été copié.',
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 5),
    ),
  );
}
