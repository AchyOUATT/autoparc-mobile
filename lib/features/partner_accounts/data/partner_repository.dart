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
  String get status => account['status']?.toString() ?? 'pending';
  String? get reviewReason => account['review_reason']?.toString();
  bool get approved => status == 'approved';
}

class PartnerApiException implements Exception {
  const PartnerApiException(this.message, {this.statusCode, this.fields = const {}, this.accountStatus, this.reviewReason});
  final String message;
  final int? statusCode;
  final Map<String, String> fields;
  final String? accountStatus;
  final String? reviewReason;
  bool get sessionRejected => statusCode == 401 || statusCode == 403;
  @override
  String toString() => message;
}

abstract class PartnerTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecurePartnerTokenStore implements PartnerTokenStore {
  static const tokenKey = 'partner_sanctum_token';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  );
  @override
  Future<String?> read() => _storage.read(key: tokenKey);
  @override
  Future<void> write(String token) => _storage.write(key: tokenKey, value: token);
  @override
  Future<void> clear() => _storage.delete(key: tokenKey);
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
      throw PartnerApiException(
        fields.isNotEmpty ? fields.values.first : body['message']?.toString() ?? 'Connexion impossible. Vérifiez votre réseau et réessayez.',
        statusCode: error.response?.statusCode,
        fields: fields,
        accountStatus: body['status']?.toString(),
        reviewReason: body['review_reason']?.toString(),
      );
    }
  }

  Future<PartnerProfile> _authenticate(String action, Map<String, dynamic> fields) async {
    final response = Map<String, dynamic>.from(await _request('POST', '/partner/$action', data: fields));
    final profile = PartnerProfile.fromJson(response);
    if (profile.user['role'] != 'partner' || response['token'] is! String || (response['token'] as String).isEmpty) {
      throw const PartnerApiException('La réponse ne correspond pas à une session partenaire.');
    }
    await _tokens.write(response['token'] as String);
    return profile;
  }

  Future<PartnerProfile> login(String email, String password) => _authenticate('login', {
    'email': email.trim(), 'password': password, 'device_name': 'AutoParc partenaire',
  });
  Future<PartnerProfile> register(Map<String, dynamic> fields) => _authenticate('register', {
    ...fields, 'device_name': 'AutoParc partenaire',
  });
  Future<PartnerProfile?> restore() async {
    if ((await _tokens.read())?.isNotEmpty != true) return null;
    return getMe();
  }
  Future<PartnerProfile> getMe() async {
    try {
      final result = PartnerProfile.fromJson(Map<String, dynamic>.from(await _request('GET', '/partner/me')));
      if (result.user['role'] != 'partner') {
        await _tokens.clear();
        throw const PartnerApiException('Cette session partenaire est invalide.', statusCode: 401);
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
