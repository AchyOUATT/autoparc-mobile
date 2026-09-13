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

  /// Référence posée par le serveur sur chaque requête (`X-Request-Id`).
  ///
  /// C'est le seul fil entre ce que voit l'utilisateur et ce qu'on peut lire
  /// dans le journal : en production, une erreur serveur ne dit rien de plus
  /// que « Server Error ». Affichée à l'écran, elle transforme un signalement
  /// vague en un `grep`.
  final String? requestId;

  /// Vrai quand la requête n'a jamais atteint le serveur : pas de réseau,
  /// serveur injoignable, délai dépassé. À distinguer d'une erreur renvoyée
  /// *par* le serveur — la conduite à tenir n'est pas la même.
  final bool isNetworkFailure;

  const ApiException({
    this.statusCode,
    required this.message,
    this.errors,
    this.requestId,
    this.isNetworkFailure = false,
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
      requestId: (parsed?['request_id'] as String?) ??
          e.response?.headers.value('x-request-id'),
      isNetworkFailure: e.response == null,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden    => statusCode == 403;
  bool get isNotFound     => statusCode == 404;
  bool get isValidation   => statusCode == 422;
  bool get isServerError  => statusCode != null && statusCode! >= 500;

  /// Le serveur est joignable mais ne peut pas traiter la demande pour le
  /// moment — vérification de session impossible, maintenance.
  bool get isUnavailable => statusCode == 503;

  /// Trop de requêtes : le serveur demande de patienter.
  bool get isThrottled => statusCode == 429;

  /// Ce qu'on montre à l'utilisateur.
  ///
  /// L'application affichait jusqu'ici l'exception brute :
  /// « ApiException(500): Server Error », ou pire, le message anglais de Dio
  /// sur une coupure réseau. Visible, mais inexploitable — ni pour
  /// l'utilisateur, qui ne sait pas quoi faire, ni pour le développeur, qui
  /// n'a rien à chercher.
  ///
  /// Le détail technique n'est pas perdu : il reste dans [message] et part
  /// dans `debugPrint` via l'intercepteur.
  String get userMessage {
    if (isNetworkFailure) {
      return 'Pas de connexion. Vérifiez votre réseau puis réessayez.';
    }

    return switch (statusCode) {
      401 => 'Votre session a expiré. Reconnectez-vous.',
      // Le serveur renvoie ici un message utile (« Votre rôle ne permet pas
      // cette action »), on le préfère au nôtre.
      403 => message,
      404 => 'Introuvable. L\'élément a peut-être été supprimé.',
      422 => _validationMessage(),
      // Le serveur dit combien de temps patienter et pourquoi : son message
      // est plus utile que « trop de requêtes ».
      429 => message,
      503 => '$message${_reference()}',
      _   => statusCode != null && statusCode! >= 500
                ? 'Erreur du serveur.${_reference()}'
                : '$message${_reference()}',
    };
  }

  /// Première erreur de validation, celle que l'utilisateur peut corriger.
  String _validationMessage() {
    final premier = errors?.values.firstOrNull;

    if (premier is List && premier.isNotEmpty) {
      return premier.first.toString();
    }

    return message;
  }

  String _reference() => requestId == null ? '' : ' (réf. $requestId)';

  @override
  String toString() => 'ApiException(${statusCode ?? "?"}): $message'
      '${requestId == null ? '' : ' [réf. $requestId]'}';
}

/// Message présentable pour n'importe quelle erreur remontée à l'écran.
///
/// Les pages reçoivent parfois autre chose qu'une [ApiException] — une erreur
/// de parsing, une exception Firebase. Plutôt que d'afficher `toString()`, on
/// dit au moins quelque chose d'utilisable, sans prétendre connaître la cause.
String messageFor(Object? error) {
  if (error is ApiException) return error.userMessage;

  if (error is DioException) return ApiException.fromDioError(error).userMessage;

  return 'Une erreur est survenue. Réessayez.';
}
