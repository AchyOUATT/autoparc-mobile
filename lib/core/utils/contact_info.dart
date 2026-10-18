/// Coordonnées de contact AutoParc, et l'adresse publique d'un article.
///
/// Rassemblées ici parce que le numéro vivait auparavant en trois exemplaires
/// — `main.dart`, `whatsapp_helper.dart`, et implicitement la fiche véhicule —
/// avec trois valeurs fictives différentes qui divergeaient silencieusement.
library;

import '../api/endpoints.dart';

/// Numéro d'appel, au format international avec indicatif.
const kContactPhone = '+22675570484';

/// Même numéro, mis en forme pour l'affichage.
const kContactPhoneDisplay = '+226 75 57 04 84';

/// Numéro WhatsApp. `wa.me` n'accepte ni le « + » ni les espaces.
const kContactWhatsApp = '22675570484';

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
String adresseArticle(TypeArticle type, int id) =>
    '$kSiteUrl/${type.segment}/$id';
