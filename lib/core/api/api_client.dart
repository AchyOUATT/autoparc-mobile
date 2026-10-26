import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_exception.dart';
import 'endpoints.dart';

/// L'ANCIENNE clé. Elle ne portait que le jeton, et on la lit encore.
///
/// Tout utilisateur connecté avant cette version n'a que celle-ci. L'ignorer
/// déconnecterait tout le monde à la mise à jour, sans message et sans raison.
/// Elle est effacée au premier enregistrement d'une session complète.
const _kTokenKey = 'sanctum_token';

/// L'enregistrement COURANT : jeton et profil, en un seul JSON.
///
/// Un seul enregistrement, et non deux, parce que deux peuvent se désaccorder :
/// un jeton sans profil, ou un profil sans jeton, sont des états qu'il faudrait
/// alors savoir réparer. Ici l'écriture est atomique du point de vue de
/// l'application — on a les deux, ou rien.
///
/// Le profil y est pour une raison précise : permettre un démarrage OPTIMISTE.
/// Sans lui, afficher l'application sans attendre le réseau n'a rien à montrer
/// — pas de nom, pas de rôle, donc pas de tuiles — et il faudrait de nouveau
/// bloquer le premier écran sur un appel qui peut prendre 35 secondes sur une
/// instance endormie.
const _kSessionKey = 'sanctum_session';

/// Forme de l'enregistrement. Inscrite dedans pour qu'une version future
/// puisse la reconnaitre au lieu de la deviner.
///
/// La lecture n'exige PAS de connaitre cette version : un enregistrement dont
/// le `v` lui est inconnu reste utilisable tant qu'il porte un jeton. C'est
/// voulu — refuser l'inconnu deconnecterait a chaque retour arriere.
const _versionSession = 1;
// encryptedSharedPreferences évite le blocage sur Android (Keystore sans
// écran de verrouillage configuré — courant sur émulateur).
//
// ── resetOnError : IL RESTE, MAIS IL A FAILLI ÊTRE LA CAUSE ───────────────
//
// Son commentaire disait « nettoie le store en cas de corruption du
// Keystore ». C'est vrai, et pendant un temps ça a produit l'inverse de ce
// qu'on attendait : le personnel se reconnectait à CHAQUE ouverture de
// l'application.
//
// Le mécanisme, mesuré sur le téléphone du propriétaire le 20/10/2026 (app
// 1.5.0 installée depuis Play), au démarrage à froid suivant une connexion
// réussie :
//
//     E keystore2: Error::Km(r#VERIFICATION_FAILED)
//     E SecureStorageAndroid: EncryptedSharedPreferences initialization failed
//     E SecureStorageAndroid: javax.crypto.AEADBadTagException
//
// L'initialisation chiffrée lève, l'exception remonte au gestionnaire du
// greffon, `resetOnError` déclenche un `deleteAll()`, le jeton disparaît. Au
// lancement suivant la clé est toujours désaccordée : la boucle se referme, et
// un garde-fou prévu pour une corruption occasionnelle en fabrique une
// permanente.
//
// LA CAUSE N'ÉTAIT PAS ICI. Le manifeste ne déclarait aucune règle de
// sauvegarde, donc Android sauvegardait le fichier chiffré du coffre — alors
// que sa clé maîtresse vit dans le Keystore matériel et n'est jamais
// sauvegardée. Restauré sans sa clé, le fichier est illisible pour toujours.
// Corrigé par android/app/src/main/res/xml/{backup_rules,data_extraction_rules}.xml.
//
// POURQUOI LE GARDER MALGRÉ TOUT, et ce n'est pas de la prudence molle : c'est
// lui qui RÉPARE les appareils déjà touchés. Leur coffre reste corrompu après
// la mise à jour ; au premier lancement il est vidé, l'utilisateur se
// reconnecte une dernière fois, et le coffre se reconstruit avec la clé
// courante. Sans lui, ces appareils resteraient bloqués jusqu'à une
// désinstallation.
const _kStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  ),
);

/// Provider global — un seul client Dio partagé dans toute l'app.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Client HTTP configuré pour l'API AutoParc.
///
/// Stratégie d'auth (par ordre de priorité) :
///   1. Token Sanctum stocké → staff connecté
///   2. ID token Firebase → client mobile connecté (auto-rafraîchi)
///   3. Aucun header → routes publiques du catalogue
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl:        Endpoints.baseUrl,
      // 60 s et non 30 : le service Render est sur le plan gratuit, il s'endort
      // après inactivité et son réveil est lent. Mesuré le 2026-10-15 depuis un
      // poste : 34,8 s sur /up à froid — soit au-delà des 30 s précédentes. Le
      // 11 octobre, aucune réponse en 180 s. À 30 s, tout utilisateur ouvrant
      // l'application alors que le service dormait dépassait le délai, sans
      // aucun moyen de comprendre pourquoi.
      //
      // Il n'y a volontairement pas de sendTimeout : l'envoi de photos sur un
      // réseau mobile lent le dépasserait. Son absence a un coût connu — un
      // envoi vers un serveur muet reste suspendu indéfiniment.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept':       'application/json',
        'Content-Type': 'application/json',
        // Bypass l'interstitiel ngrok sur les URLs *.ngrok-free.dev / *.ngrok.io
        if (Endpoints.baseUrl.contains('ngrok'))
          'ngrok-skip-browser-warning': 'true',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachToken,
        onError:   _handleError,
      ),
    );
  }

  // ── Intercepteurs ─────────────────────────────────────────────────

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Le jeton dépend de la route, pas de ce qui traîne en mémoire.
    //
    // Les routes `/my/…` sont vérifiées par Firebase côté serveur
    // (`Route::middleware('firebase')->prefix('my')`), les autres par Sanctum.
    // Le jeton Sanctum était auparavant prioritaire partout : un membre du
    // staff connecté envoyait donc son jeton Sanctum au garage, que Firebase
    // rejetait en 401 « token invalide » — le garage devenait inutilisable dès
    // qu'on s'était connecté côté personnel.
    final isClientRoute = options.path.startsWith('/my/');

    if (!isClientRoute) {
      // Passe par `readToken()`, qui lit l'enregistrement courant puis
      // retombe sur l'ancienne clé : une session d'avant la mise à jour
      // continue d'authentifier ses requêtes.
      final sanctumToken = await readToken();
      if (sanctumToken != null) {
        options.headers['Authorization'] = 'Bearer $sanctumToken';
        return handler.next(options);
      }
    }

    // ID token Firebase (client mobile) — se rafraîchit automatiquement.
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null) {
        options.headers['Authorization'] = 'Bearer $idToken';
      }
    } catch (e) {
      // Cas normal : Firebase pas initialisé, ou personne de connecté. La
      // requête part alors sans en-tête, et le serveur répondra 401 — ce qui
      // est correct, mais donne un message qui parle de jeton invalide alors
      // que le jeton n'a jamais été demandé. La trace évite de chercher du
      // mauvais côté.
      debugPrint('[API] jeton Firebase indisponible (${options.path}) : $e');
    }

    handler.next(options);
  }

  void _handleError(DioException e, ErrorInterceptorHandler handler) {
    debugPrint('[API] type=${e.type} status=${e.response?.statusCode} '
        'msg=${e.message} url=${e.requestOptions.uri}');
    // Ne pas convertir ici : on laisse le DioException original se propager
    // avec sa réponse intacte. Chaque méthode (post/get/…) le convertit en
    // ApiException via fromDioError, qui peut alors lire e.response?.data.
    handler.next(e);
  }

  // ── Helpers HTTP ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: params,
      );
      return res.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Retourne une liste JSON (ex. : /catalog/countries).
  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(path, queryParameters: params);
      return res.data ?? [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: data);
      return res.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(path, data: data);
      return res.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(path, data: data);
      return res.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload multipart de fichiers.
  /// [filePaths] : chemins locaux des fichiers à envoyer.
  /// [field]     : nom du champ array attendu par Laravel (ex. 'photos').
  /// [extra]     : champs supplémentaires (ex. {'collection': 'gallery'}).
  Future<Map<String, dynamic>> uploadFiles(
    String path, {
    required List<String> filePaths,
    String field = 'photos',
    Map<String, String> extra = const {},
  }) async {
    try {
      final files = await Future.wait(
        filePaths.map((p) => MultipartFile.fromFile(p)),
      );

      // PHP n'interprète un champ multi-valeurs comme tableau QUE si le nom
      // se termine par []. Sans les crochets, seul le dernier fichier survit
      // et Laravel reçoit un scalaire au lieu d'un array → 422.
      final formData = FormData();
      for (final file in files) {
        formData.files.add(MapEntry('$field[]', file));
      }
      for (final entry in extra.entries) {
        formData.fields.add(MapEntry(entry.key, entry.value));
      }

      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Session Sanctum (staff) ───────────────────────────────────────

  /// Enregistre la session complete, ET tient l'ancienne cle a jour.
  ///
  /// ── POURQUOI ON ECRIT LES DEUX, ET NON PLUS UNE SEULE ──────────────────
  ///
  /// La premiere version de ce code EFFAÇAIT `sanctum_token` des la premiere
  /// ecriture, au motif qu'un jeton laisse la ne serait plus jamais lu. Le
  /// raisonnement avait un angle mort : l'application PUBLIEE ne connait que
  /// cette cle-la. Des que cette version avait tourne une fois, revenir au
  /// binaire publie — exactement le geste qu'on fait quand un lot pose
  /// probleme — montrait l'ecran visiteur a tout le monde, et laissait au
  /// coffre un jeton que ce binaire ne lit pas et n'efface pas. Avec
  /// `'expiration' => null` cote Sanctum, ce jeton reste valable
  /// indefiniment.
  ///
  /// L'ancienne cle est donc tenue a jour comme un MIROIR du jeton courant.
  /// Elle n'est plus un residu : `deleteSession()` efface les deux, donc une
  /// deconnexion la nettoie, et un retour arriere retrouve une session
  /// utilisable.
  ///
  /// C'est transitoire. Ce miroir pourra partir quand la version publiee sera
  /// assez vieille pour qu'un retour vers elle n'ait plus de sens.
  ///
  /// L'ordre compte : l'enregistrement AUTORITAIRE d'abord. Si la seconde
  /// ecriture echoue, cette version reste juste, et un retour arriere lirait
  /// un jeton perime — donc un 401, donc une deconnexion propre. L'ordre
  /// inverse laisserait cette version lire un jeton perime, ce qui est pire.
  static Future<void> saveSession(
    String token, [
    Map<String, dynamic>? user,
  ]) async {
    await _kStorage.write(
      key: _kSessionKey,
      value: jsonEncode({'v': _versionSession, 'token': token, 'user': ?user}),
    );

    await _kStorage.write(key: _kTokenKey, value: token);
  }

  /// Lit la session : l'enregistrement courant, sinon l'ancienne clé.
  static Future<SessionStockee?> readSession() async {
    final brut = await _kStorage.read(key: _kSessionKey);

    if (brut != null && brut.isNotEmpty) {
      try {
        final json = jsonDecode(brut);
        if (json is Map &&
            json['token'] is String &&
            (json['token'] as String).isNotEmpty) {
          final user = json['user'];

          return SessionStockee(
            token: json['token'] as String,
            user: user is Map<String, dynamic> ? user : null,
          );
        }
      } catch (_) {
        // Enregistrement illisible. On ne déconnecte PAS sur une erreur de
        // format : on retombe sur l'ancienne clé, et si elle est absente la
        // session est perdue de toute façon.
      }
    }

    final ancien = await _kStorage.read(key: _kTokenKey);
    if (ancien != null && ancien.isNotEmpty) {
      // Profil inconnu : la vérification en arrière-plan le ramènera. En
      // attendant, l'application démarre avec un jeton et sans nom, ce qui
      // est exactement ce qu'elle faisait avant cette version.
      return SessionStockee(token: ancien);
    }

    return null;
  }

  /// Efface LES DEUX clés. Laisser l'ancienne reviendrait à ne pas déconnecter.
  static Future<void> deleteSession() async {
    await _kStorage.delete(key: _kSessionKey);
    await _kStorage.delete(key: _kTokenKey);
  }

  /// Le jeton seul, pour l'en-tête `Authorization`.
  static Future<String?> readToken() async => (await readSession())?.token;
}

/// Ce que le coffre rend : un jeton, et le profil quand on l'a.
///
/// Le profil est nul dans deux cas, et un seul compte : une session d'avant
/// cette version, qui n'avait que le jeton. L'autre est un enregistrement dont
/// le profil était illisible.
class SessionStockee {
  const SessionStockee({required this.token, this.user});

  final String token;
  final Map<String, dynamic>? user;
}
