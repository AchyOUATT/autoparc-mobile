import 'dart:convert';
import 'package:dio/dio.dart';

/// Exception standard retournée par [ApiClient] à la place des [DioException] bruts.
///
/// Convertit la réponse JSON Laravel en message lisible.
/// Les erreurs de validation (422) exposent le champ [errors].
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  /// Champ "errors" des réponses 422 (validation Laravel).
  /// Ex : { "email": ["The email field is required."] }
  final Map<String, dynamic>? errors;

  const ApiException({
    this.statusCode,
    required this.message,
    this.errors,
  });

  factory ApiException.fromDioError(DioException e) {
    // Dio peut renvoyer la réponse comme Map (parsée) ou String (brute).
    final raw = e.response?.data;
    Map<String, dynamic>? parsed;
    if (raw is Map<String, dynamic>) {
      parsed = raw;
    } else if (raw is String && raw.isNotEmpty) {
      try { parsed = jsonDecode(raw) as Map<String, dynamic>?; } catch (_) {}
    }

    final message = (parsed != null && parsed.containsKey('message'))
        ? parsed['message'] as String
        : e.message ?? 'Erreur inconnue.';

    return ApiException(
      statusCode: e.response?.statusCode,
      message: message,
      errors: parsed?['errors'] as Map<String, dynamic>?,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden    => statusCode == 403;
  bool get isNotFound     => statusCode == 404;
  bool get isValidation   => statusCode == 422;
  bool get isServerError  => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiException(${statusCode ?? "?"}): $message';
}
