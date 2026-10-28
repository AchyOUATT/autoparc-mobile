/// Adresse courriel AutoParc et adresses publiques des articles.
/// Le téléphone est chargé par core/contact/autoparc_contact_provider.dart.
library;

import '../api/endpoints.dart';

const kContactEmail = 'contact@autoparc.com';

/// Le type d'article, tel que les routes publiques du serveur le nomment.
///
/// Les segments sont d'une seule lettre parce que le serveur en a décidé
/// ainsi : `/v/{id}`, `/p/{id}`, `/a/{id}`. Ils ne sont donc pas négociables
/// ici — une lettre changée mène à une page absente, et le destinataire du
/// partage tombe sur une 404 sans que rien ne plante de notre côté.
enum TypeArticle {
  vehicule('v'),
  piece('p'),
  accessoire('a');

  const TypeArticle(this.segment);

  /// Le segment d'URL servi par le backend.
  final String segment;
}

/// La racine du site public, déduite de l'adresse de l'API.
///
/// Déduite, et non écrite à part : le backend qui sert `/api` sert aussi les
/// pages publiques, sur le même hôte. Les quatre adresses d'[Endpoints] —
/// émulateur, téléphone du réseau local, ngrok, Render — restent donc alignées
/// sans second réglage, et un `--dart-define=API_BASE_URL=...` déplace l'API
/// et les liens partagés du même coup. Une racine réglée séparément, c'est le
/// build ngrok qui envoie des liens de production dans les conversations de
/// test, ou l'inverse.
///
/// Aucun appel réseau : `Endpoints.baseUrl` est une constante de compilation,
/// et ce qui suit n'est que du découpage de chaîne. C'est la condition même du
/// partage — on partage un article dans un couloir, avec une barre de réseau,
/// et un partage qui attendrait une réponse HTTP n'ouvrirait rien. `final` et
/// non `const` pour la seule raison que `substring` n'est pas une opération
/// constante en Dart.
final kSiteUrl = racineSiteDepuisApi(Endpoints.baseUrl);

/// Retire le `/api` final de [urlApi] pour obtenir la racine du site.
///
/// Rend [urlApi] inchangée quand elle ne finit pas par `/api`, au lieu de
/// couper les quatre derniers caractères à l'aveugle : un `API_BASE_URL` sans
/// ce suffixe — un backend monté à la racine d'un sous-domaine — donnerait
/// sinon `https://autoparc-backend.onrender.c`, et chaque lien partagé
/// mènerait à un hôte qui n'existe pas. Le défaut serait muet du côté de
/// l'application : rien ne lève, le message part, c'est le destinataire qui
/// récolte l'erreur de résolution.
///
/// Les barres finales tombent d'abord, pour que `.../api/` et `.../api`
/// donnent la même racine et qu'aucune adresse ne se retrouve avec un `//` au
/// milieu. *Toutes* les barres, et non une seule : mesuré, un
/// `API_BASE_URL=https://hôte/api//` ne perdait qu'une barre, ne finissait
/// donc plus par `/api`, et ressortait tel quel — le lien partagé devenait
/// `https://hôte/api//v/12`, c'est-à-dire la racine de l'API et non celle des
/// pages publiques. Même défaut muet que ci-dessus : une 404 chez le
/// destinataire, rien chez l'expéditeur.
///
/// Une racine qui porte un chemin est conservée : `https://hôte/v1/api` donne
/// `https://hôte/v1`, donc `https://hôte/v1/v/12`. C'est le comportement
/// voulu — les pages publiques sont servies par le même montage que l'API,
/// sous le même préfixe.
String racineSiteDepuisApi(String urlApi) {
  const suffixe = '/api';

  var sansBarre = urlApi;
  while (sansBarre.endsWith('/')) {
    sansBarre = sansBarre.substring(0, sansBarre.length - 1);
  }

  return sansBarre.endsWith(suffixe)
      ? sansBarre.substring(0, sansBarre.length - suffixe.length)
      : sansBarre;
}

/// L'adresse de la page publique d'un article — le lien qu'on joint à un
/// partage.
///
/// **Le seul endroit où une URL d'article se fabrique.** Elle tenait avant en
/// une constante unique, la fiche du magasin d'applications, faute de page par
/// article : un vendeur partageait une Corolla, et son contact recevait
/// « *Toyota Corolla 2015*, 4 500 000 FCFA » suivi du lien Play Store. Il lui
/// fallait installer l'application, puis retrouver l'article lui-même. C'est
/// cette amputation que les pages `/v`, `/p`, `/a` réparent, et elles portent
/// les balises Open Graph qui font apparaître photo, titre et prix dans la
/// conversation.
///
/// [id] est la clef primaire de l'article, celle que ces routes attendent.
///
/// ## [version] : pourquoi l'adresse doit CHANGER quand l'article change
///
/// Signalé par le propriétaire : « un véhicule déjà partagé ne met pas à jour
/// ses données de partage après maj ». Le serveur n'y est pour rien, et c'est
/// mesuré — la page `/v/86` annonce « Mazda CX-9 2018 — 9 500 000 FCFA » et
/// l'API rend `sale_price: 9500000.00`. Les deux concordent.
///
/// Ce qui ne bouge pas, c'est la VIGNETTE DÉJÀ CONSTRUITE chez l'opérateur de
/// messagerie. WhatsApp et Facebook la fabriquent au premier partage et la
/// gardent ; aucun en-tête HTTP ne les en fait changer — ni `Cache-Control`,
/// ni `Expires`, ni `ETag`. La seule prise qu'on ait sur eux est l'ADRESSE
/// APPELÉE, et c'est tout l'objet de ce paramètre :
///
///     sans version   https://autoparc-backend.onrender.com/v/86
///     avec version   https://autoparc-backend.onrender.com/v/86?m=t3uwow
///
/// **Et pourquoi ce côté-ci, alors que le serveur pose déjà le marqueur dans
/// son `og:url`.** Facebook identifie un objet par son `og:url` : pour lui, le
/// serveur suffirait. WhatsApp non — il clef sa vignette sur l'adresse qu'il a
/// APPELÉE. Tant que l'application partage `/v/86`, il ressort la vignette du
/// premier partage, quel que soit le contenu de la page. WhatsApp est le canal
/// principal de cette boutique : sans ce paramètre, le lot serveur ne répare
/// rien là où le défaut a été vu.
///
/// [version] est le `share_version` de l'API, recopié TEL QUEL. L'application
/// ne le lit pas, ne le compare pas, ne le fabrique pas : c'est une chaîne
/// opaque dont le serveur choisit le format (la seconde UNIX d'`updated_at` en
/// base 36 — voir `app/Support/VersionPartage.php`). Rien ici ne dépend de ce
/// format, et c'est voulu : le jour où il change, ce fichier n'a pas à suivre.
///
/// ## Null et chaîne vide rendent l'adresse NUE, à l'identique d'avant
///
/// C'est la garantie que rien ne casse. Un serveur d'une version antérieure,
/// un chemin d'API qui ne rend pas la clef, un `updated_at` nul : dans les
/// trois cas [version] arrive nulle, et l'adresse est exactement celle que
/// cette fonction rendait auparavant. Elle reste valable — elle perd seulement
/// le rafraîchissement de vignette.
///
/// **Ce dont ce dépôt a déjà payé le prix.** Le partage d'un véhicule a été
/// MORT pour tout le parc parce qu'une règle exigeait `publishedAt`, que rien
/// ne peuple — voir `Vehicle.aUnePagePublique`. Trois relectures adversariales
/// l'ont manqué ; le propriétaire l'a vu en une minute. Un champ cosmétique ne
/// doit donc jamais pouvoir fabriquer une adresse fausse : ni `?m=null`, ni
/// `?m=`, ni un bouton inerte.
///
/// La chaîne vide est traitée comme l'absence, et ce n'est pas théorique : ce
/// dépôt normalise déjà de cette façon, `json['published_at'] as String? ?? ''`
/// dans `Vehicle.fromJson`. Un appelant qui ferait de même obtiendrait
/// `/v/86?m=` — une adresse neuve pour chaque article, donc une vignette
/// fabriquée depuis cette adresse-là et mise en cache à la place de la bonne.
///
/// Le marqueur est échappé avant d'être collé. L'alphabet de la base 36 est
/// `[0-9a-z]`, et l'échappement ne change donc RIEN sur le format réel —
/// mesuré par le test « un marqueur de base 36 traverse sans être échappé ».
/// Il n'est là que parce que cette chaîne vient du réseau et que l'application
/// n'en choisit pas le format : un « & » y inventerait un second paramètre, et
/// un « # » couperait l'adresse — le marqueur partirait en fragment, que le
/// robot d'aperçu n'envoie jamais au serveur, et la vignette resterait figée
/// sans que rien ne le signale.
String adresseArticle(TypeArticle type, int id, {String? version}) {
  final nue = '$kSiteUrl/${type.segment}/$id';

  if (version == null || version.isEmpty) return nue;

  return '$nue?m=${Uri.encodeQueryComponent(version)}';
}
