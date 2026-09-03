import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_exception.dart';
import 'endpoints.dart';

const _kTokenKey = 'sanctum_token';
// encryptedSharedPreferences évite le blocage sur Android (Keystore sans
// écran de verrouillage configuré — courant sur émulateur).
// resetOnError nettoie le store en cas de corruption du Keystore.
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
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
    // 1. Token Sanctum (staff)
    final sanctumToken = await _kStorage.read(key: _kTokenKey);
    if (sanctumToken != null) {
      options.headers['Authorization'] = 'Bearer $sanctumToken';
      return handler.next(options);
    }

    // 2. ID token Firebase (client mobile) — se rafraîchit automatiquement
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null) {
        options.headers['Authorization'] = 'Bearer $idToken';
      }
    } catch (_) {
      // Firebase pas initialisé ou pas d'utilisateur connecté → pas d'header
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

      final formData = FormData.fromMap({
        field: files,
        ...extra,
      });

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

  // ── Token Sanctum (staff) ─────────────────────────────────────────

  static Future<void> saveToken(String token) =>
      _kStorage.write(key: _kTokenKey, value: token);

  static Future<void> deleteToken() =>
      _kStorage.delete(key: _kTokenKey);

  static Future<String?> readToken() =>
      _kStorage.read(key: _kTokenKey);
}
