import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/endpoints.dart';

enum PartnerListingKind {
  vehicles('Véhicules', 'véhicule'),
  parts('Pièces détachées', 'pièce'),
  accessories('Accessoires', 'accessoire');

  const PartnerListingKind(this.label, this.singular);
  final String label;
  final String singular;
  String get path => '/partner/$name';
}

class PartnerProfile {
  const PartnerProfile({required this.user, required this.account});
  factory PartnerProfile.fromJson(Map<String, dynamic> json) => PartnerProfile(
    user: Map<String, dynamic>.from(json['user'] as Map),
    account: Map<String, dynamic>.from(json['partner_account'] as Map),
  );
  final Map<String, dynamic> user;
  final Map<String, dynamic> account;
  String get companyName => account['company_name']?.toString() ?? '';
  String get contactName => account['contact_name']?.toString() ?? '';

  /// Le nom à AFFICHER, qui n'est jamais vide.
  ///
  /// `company_name` est facultatif à l'inscription : un revendeur particulier
  /// n'a pas de raison sociale. Le profil privé rend donc `null` — à dessein,
  /// pour que le titulaire voie que le champ est vide plutôt que son propre
  /// nom recopié. Mais un titre vide dans l'en-tête de l'espace partenaire ne
  /// dit rien à personne, d'où ce repli, côté affichage seulement.
  ///
  /// La vitrine PUBLIQUE a le sien, côté serveur
  /// (`PartnerListingPresentation::seller()`), parce que les téléphones déjà
  /// installés lisent ce champ en `String` nu et ne peuvent pas se replier.
  String get displayName => companyName.isNotEmpty ? companyName : contactName;
  String get status => account['status']?.toString() ?? 'pending';
  String? get reviewReason => account['review_reason']?.toString();
  bool get approved => status == 'approved';

  /// Pour retourner au coffre, d'où un démarrage optimiste le relira.
  ///
  /// Les clés sont celles du serveur, parce que c'est [PartnerProfile.fromJson]
  /// — la MEME fabrique que pour `/api/partner/me` — qui relira cet
  /// enregistrement. Un seul format, donc un seul endroit où se tromper.
  Map<String, dynamic> toJson() => {'user': user, 'partner_account': account};
}

class PartnerApiException implements Exception {
  const PartnerApiException(this.message, {this.statusCode, this.fields = const {}, this.accountStatus, this.reviewReason, this.code});
  final String message;
  final int? statusCode;
  final Map<String, String> fields;
  final String? accountStatus;
  final String? reviewReason;

  /// Code métier du serveur. Même rôle et même vocabulaire que
  /// [ApiException.code] — cette classe est parallèle, pas dérivée.
  final String? code;

  bool get isAccountDisabled => code == 'account_disabled';

  /// Refus d'autorisation : la session reste valable. Même nom et même
  /// vocabulaire que [ApiException.isPermissionDenied], à dessein.
  bool get isPermissionDenied => code == 'permission_denied';

  /// La session est définitivement rejetée.
  ///
  /// Tenait `statusCode == 401 || statusCode == 403`, et c'est CE getter qui
  /// déconnectait un partenaire sur n'importe quel 403 — « cette annonce
  /// n'est pas la vôtre » comprise. Six sites le lisent, dont deux qui
  /// renvoient l'utilisateur à l'écran de connexion. Voir le commentaire de
  /// [ApiException.sessionRejected] pour les deux fautes symétriques.
  bool get sessionRejected => statusCode == 401 || isAccountDisabled;
  @override
  String toString() => message;
}

/// Ce que le coffre partenaire rend : un jeton, et le profil quand on l'a.
///
/// Le profil est nul pour une session d'avant cette version — qui n'enregistrait
/// que le jeton — ou pour un enregistrement illisible.
class PartnerSessionStockee {
  const PartnerSessionStockee({required this.token, this.profile});

  final String token;
  final Map<String, dynamic>? profile;
}

abstract class PartnerTokenStore {
  /// L'enregistrement courant, ou l'ancienne clé en secours.
  Future<PartnerSessionStockee?> readSession();

  /// Enregistre jeton ET profil, et retire l'ancienne clé.
  Future<void> writeSession(String token, [Map<String, dynamic>? profile]);

  Future<void> clear();

  /// Le jeton seul, pour l'en-tête `Authorization`.
  Future<String?> read() async => (await readSession())?.token;
}

/// `extends` et non `implements` : `read()` est concret sur l'interface, et
/// se dérive de `readSession()`. Hériter en garde UNE seule définition.
class SecurePartnerTokenStore extends PartnerTokenStore {
  /// L'ANCIENNE clé, qui ne portait que le jeton. Toujours LUE : l'ignorer
  /// déconnecterait tous les partenaires déjà connectés, à la mise à jour,
  /// sans message et sans raison. Retirée au premier enregistrement complet.
  static const tokenKey = 'partner_sanctum_token';

  /// L'enregistrement courant : jeton et profil, en un seul JSON. Le profil y
  /// est pour permettre un démarrage optimiste — sans lui, l'espace partenaire
  /// n'a rien à montrer et doit de nouveau attendre le réseau.
  static const sessionKey = 'partner_sanctum_session';

  /// Forme de l'enregistrement. Meme role et meme tolerance que du cote
  /// personnel : un `v` inconnu ne fait pas rejeter un enregistrement qui
  /// porte un jeton.
  static const version = 1;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  );
  @override
  Future<PartnerSessionStockee?> readSession() async {
    final brut = await _storage.read(key: sessionKey);

    if (brut != null && brut.isNotEmpty) {
      try {
        final json = jsonDecode(brut);
        if (json is Map &&
            json['token'] is String &&
            (json['token'] as String).isNotEmpty) {
          final profile = json['profile'];

          return PartnerSessionStockee(
            token: json['token'] as String,
            profile: profile is Map<String, dynamic> ? profile : null,
          );
        }
      } catch (_) {
        // Format abîmé : on ne déconnecte pas pour ça, on retombe sur
        // l'ancienne clé.
      }
    }

    final ancien = await _storage.read(key: tokenKey);
    if (ancien != null && ancien.isNotEmpty) {
      return PartnerSessionStockee(token: ancien);
    }

    return null;
  }

  /// Ecrit l'enregistrement courant, ET tient l'ancienne cle a jour.
  ///
  /// Meme raison que [ApiClient.saveSession] : l'application PUBLIEE ne
  /// connait que `partner_sanctum_token`. L'effacer des la premiere ecriture
  /// deconnectait tous les partenaires au moindre retour arriere, et laissait
  /// au coffre un jeton que le binaire publie ne lit pas et n'efface pas.
  /// L'ancienne cle est donc un MIROIR, que `clear()` nettoie comme l'autre.
  @override
  Future<void> writeSession(String token, [Map<String, dynamic>? profile]) async {
    await _storage.write(
      key: sessionKey,
      value: jsonEncode({'v': version, 'token': token, 'profile': ?profile}),
    );

    await _storage.write(key: tokenKey, value: token);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: sessionKey);
    await _storage.delete(key: tokenKey);
  }
}

class PartnerListingPage {
  const PartnerListingPage({required this.items, required this.page, required this.lastPage, required this.total});
  final List<Map<String, dynamic>> items;
  final int page;
  final int lastPage;
  final int total;
}

class PartnerReferences {
  const PartnerReferences({required this.brands, required this.models, required this.engineTypes, required this.partCategories, required this.manufacturers});
  final List<Map<String, dynamic>> brands;
  final List<Map<String, dynamic>> models;
  final List<Map<String, dynamic>> engineTypes;
  final List<Map<String, dynamic>> partCategories;
  final List<Map<String, dynamic>> manufacturers;
}

List<Map<String, dynamic>> partnerMaps(dynamic data) => (data as List? ?? const [])
    .map((item) => Map<String, dynamic>.from(item as Map)).toList();

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) => PartnerRepository());

/// Own Dio and token key: a partner session never becomes a staff session.
class PartnerRepository {
  PartnerRepository({Dio? dio, PartnerTokenStore? tokenStore})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: Endpoints.baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Accept': 'application/json'},
        )),
        _tokens = tokenStore ?? SecurePartnerTokenStore();

  final Dio _dio;
  final PartnerTokenStore _tokens;

  Future<dynamic> _request(String method, String path, {dynamic data, Map<String, dynamic>? query}) async {
    final headers = <String, dynamic>{'Accept': 'application/json'};
    if (path.startsWith('/partner/') && path != '/partner/login' && path != '/partner/register') {
      final token = await _tokens.read();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    try {
      final response = await _dio.request<dynamic>(path, data: data, queryParameters: query,
        options: Options(method: method, headers: headers));
      return response.data;
    } on DioException catch (error) {
      final raw = error.response?.data;
      final body = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final fields = <String, String>{};
      if (body['errors'] is Map) {
        for (final entry in (body['errors'] as Map).entries) {
          final value = entry.value;
          fields[entry.key.toString()] = value is List ? value.join('\n') : value.toString();
        }
      }
      // Transtypé défensivement, pas par `toString()` : un `code` numérique
      // deviendrait une chaîne qui ne correspondrait à aucun code connu,
      // alors que `null` dit honnêtement « le serveur n'en a pas donné ».
      final code = body['code'];

      throw PartnerApiException(
        fields.isNotEmpty ? fields.values.first : body['message']?.toString() ?? 'Connexion impossible. Vérifiez votre réseau et réessayez.',
        statusCode: error.response?.statusCode,
        fields: fields,
        accountStatus: body['status']?.toString(),
        reviewReason: body['review_reason']?.toString(),
        code: code is String ? code : null,
      );
    }
  }

  Future<PartnerProfile> _authenticate(String action, Map<String, dynamic> fields) async {
    final response = Map<String, dynamic>.from(await _request('POST', '/partner/$action', data: fields));
    final profile = PartnerProfile.fromJson(response);
    if (profile.user['role'] != 'partner' || response['token'] is! String || (response['token'] as String).isEmpty) {
      throw const PartnerApiException('La réponse ne correspond pas à une session partenaire.');
    }
    // Le profil part au coffre avec le jeton : c'est lui qui permettra au
    // prochain démarrage d'ouvrir l'espace partenaire sans attendre le réseau.
    await _tokens.writeSession(response['token'] as String, profile.toJson());

    return profile;
  }

  /// Se connecter avec un NUMÉRO ou une adresse.
  ///
  /// Le courriel est devenu facultatif à l'inscription : il ne servait qu'à se
  /// connecter, aucun courriel n'étant envoyé nulle part. C'est le numéro qui
  /// identifie désormais un partenaire, et le serveur décide de la colonne à
  /// interroger selon la présence d'un « @ ».
  ///
  /// Le champ s'appelle `identifiant` et non `email` : le serveur accepte
  /// encore l'ancien nom, pour les téléphones qui n'ont pas mis à jour, mais
  /// cette version-ci n'a aucune raison de l'employer.
  Future<PartnerProfile> login(String identifiant, String password) => _authenticate('login', {
    'identifiant': identifiant.trim(), 'password': password, 'device_name': 'AutoParc partenaire',
  });
  Future<PartnerProfile> register(Map<String, dynamic> fields) => _authenticate('register', {
    ...fields, 'device_name': 'AutoParc partenaire',
  });
  // `restore()` a ete retire. Il faisait « pas de jeton -> null, sinon
  // getMe() », donc il ATTENDAIT le reseau avant de rendre quoi que ce soit —
  // exactement l'attente que le demarrage optimiste supprime. Le notifier lit
  // desormais `sessionStockee()` lui-meme, publie ce qu'il trouve, et appelle
  // `getMe()` ensuite. La garantie « ne pas appeler le serveur sans jeton »
  // vit donc dans `PartnerSessionNotifier.restore`, ou un banc l'eprouve.
  /// La session au coffre, SANS aucun appel réseau.
  ///
  /// C'est ce qui permet au notifier d'ouvrir l'espace partenaire sur ce qu'il
  /// sait déjà, puis de vérifier. Sans elle, il lui faudrait passer par
  /// `restore()`, qui appelle `/api/partner/me` — l'attente qu'on supprime.
  Future<PartnerSessionStockee?> sessionStockee() => _tokens.readSession();

  Future<PartnerProfile> getMe() async {
    try {
      final result = PartnerProfile.fromJson(Map<String, dynamic>.from(await _request('GET', '/partner/me')));
      if (result.user['role'] != 'partner') {
        await _tokens.clear();
        throw const PartnerApiException('Cette session partenaire est invalide.', statusCode: 401);
      }

      // Le profil frais retourne au coffre. C'est ce qui répare, en une
      // exécution, une session d'avant cette version : elle n'a que le jeton,
      // et le démarrage suivant aura de quoi s'ouvrir complet.
      final session = await _tokens.readSession();
      if (session != null) {
        await _tokens.writeSession(session.token, result.toJson());
      }

      return result;
    } on PartnerApiException catch (error) {
      if (error.sessionRejected) await _tokens.clear();
      rethrow;
    }
  }
  Future<void> logout() async {
    try { await _request('POST', '/partner/logout'); }
    finally { await _tokens.clear(); }
  }

  Future<PartnerListingPage> listListings(PartnerListingKind kind, {int page = 1, String? query}) async {
    final response = Map<String, dynamic>.from(await _request('GET', kind.path, query: {
      'page': page, 'per_page': 20, if (query?.trim().isNotEmpty == true) 'q': query!.trim(),
    }));
    final meta = response['meta'] as Map? ?? const {};
    return PartnerListingPage(items: partnerMaps(response['data']), page: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? page, total: (meta['total'] as num?)?.toInt() ?? 0);
  }
  Future<Map<String, dynamic>> listing(PartnerListingKind kind, int id) async =>
    Map<String, dynamic>.from((await _request('GET', '${kind.path}/$id'))['data'] as Map);
  Future<Map<String, dynamic>> saveListing(PartnerListingKind kind, Map<String, dynamic> data, {int? id}) async =>
    Map<String, dynamic>.from((await _request(id == null ? 'POST' : 'PATCH', id == null ? kind.path : '${kind.path}/$id', data: data))['data'] as Map);
  Future<void> publish(PartnerListingKind kind, int id, bool publish) =>
    _request('POST', '${kind.path}/$id/${publish ? 'publish' : 'unpublish'}');
  Future<void> archive(PartnerListingKind kind, int id) => _request('DELETE', '${kind.path}/$id');
  Future<void> setStock(PartnerListingKind kind, int id, int quantity) => _request('POST', '${kind.path}/$id/stock', data: {
    'operation': 'set', 'quantity': quantity, 'reason': 'Inventaire partenaire',
  });
  Future<void> toggleAvailability(PartnerListingKind kind, int id) => _request('PATCH', '${kind.path}/$id/availability');

  Future<PartnerReferences> references() async {
    final responses = await Future.wait([
      _request('GET', '/catalog/sync'),
      _request('GET', '/catalog/part-categories'),
      _request('GET', '/catalog/manufacturers'),
    ]);
    final sync = Map<String, dynamic>.from(responses[0]);
    return PartnerReferences(brands: partnerMaps(sync['brands']), models: partnerMaps(sync['vehicle_models']),
      engineTypes: partnerMaps(sync['engine_types']),
      partCategories: partnerMaps(responses[1] is Map ? responses[1]['data'] : responses[1]),
      manufacturers: partnerMaps(responses[2] is Map ? responses[2]['data'] : responses[2]));
  }

  Future<List<Map<String, dynamic>>> media(PartnerListingKind kind, int id) async =>
    partnerMaps((await _request('GET', '${kind.path}/$id/media'))['data']);
  Future<void> uploadPhotos(PartnerListingKind kind, int id, List<XFile> files) async {
    final form = FormData();
    for (final file in files) {
      form.files.add(MapEntry('photos[]', MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name)));
    }
    await _request('POST', '${kind.path}/$id/media', data: form);
  }
  Future<void> setCover(int mediaId) => _request('PATCH', '/partner/media/$mediaId/cover');
  Future<void> deleteMedia(int mediaId) => _request('DELETE', '/partner/media/$mediaId');
  Future<void> reorderMedia(PartnerListingKind kind, int id, List<int> ids) =>
    _request('PATCH', '${kind.path}/$id/media/reorder', data: {'ids': ids});
}
