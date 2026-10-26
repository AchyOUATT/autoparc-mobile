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

  /// Code métier stable posé par le serveur à côté du statut.
  ///
  /// Le statut seul ne suffit pas, et 403 est le cas qui le prouve : il
  /// couvre deux situations opposées que le client doit traiter à l'inverse
  /// l'une de l'autre.
  ///
  ///   `permission_denied` — la session est VALABLE, l'action est refusée.
  ///                         On affiche le refus et on garde le jeton.
  ///   `account_disabled`  — le jeton existe peut-être encore, mais le COMPTE
  ///                         ne vaut plus rien. On vide le coffre.
  ///
  /// Un `message` ne peut pas tenir ce rôle : il change avec la traduction et
  /// la formulation. Le code, lui, est un vocabulaire fermé, énuméré côté
  /// serveur dans `App\Exceptions\RefusMetier`.
  ///
  /// Nullable et nommé à dessein : toutes les réponses n'en portent pas, et
  /// cinq fichiers de test construisent cette classe en `const` sans lui.
  final String? code;

  const ApiException({
    this.statusCode,
    required this.message,
    this.errors,
    this.requestId,
    this.isNetworkFailure = false,
    this.code,
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

    // Lu défensivement : un `code` non textuel ferait lever le transtypage,
    // et on perdrait l'exception d'origine au profit d'une erreur de cast.
    final code = parsed?['code'];

    return ApiException(
      statusCode: e.response?.statusCode,
      message: message,
      errors: parsed?['errors'] as Map<String, dynamic>?,
      requestId: (parsed?['request_id'] as String?) ??
          e.response?.headers.value('x-request-id'),
      isNetworkFailure: e.response == null,
      code: code is String ? code : null,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden    => statusCode == 403;
  bool get isNotFound     => statusCode == 404;

  /// Le compte est désactivé. La session est morte, où qu'en soit le jeton.
  bool get isAccountDisabled => code == 'account_disabled';

  /// Un refus d'AUTORISATION. La session est valable ; c'est l'action qui est
  /// refusée, et il ne faut surtout pas déconnecter là-dessus.
  bool get isPermissionDenied => code == 'permission_denied';

  /// La session est définitivement rejetée : le coffre doit être vidé.
  ///
  /// ── CE QUE CE GETTER REMPLACE, ET POURQUOI C'ÉTAIT FAUX ────────────────
  ///
  /// `partner_repository.dart` tenait la règle `statusCode == 401 ||
  /// statusCode == 403`. Elle effaçait le jeton sur N'IMPORTE QUEL 403 :
  /// « cette annonce n'est pas la vôtre », « votre rôle ne permet pas cette
  /// action », un refus de capacité. Un partenaire perdait sa session en
  /// touchant une annonce qui n'était pas la sienne.
  ///
  /// L'erreur symétrique existe aussi, et le lot 1 vient de la créer côté
  /// personnel : `auth_provider` ne vidait le coffre que sur 401, pour une
  /// bonne raison — le plan gratuit de Render s'endort, et un délai dépassé
  /// ne doit pas déconnecter (34,8 s mesurées sur `/up` à froid le
  /// 2026-10-15). Mais un compte désactivé rend désormais 403, qui atterrit
  /// donc dans le panier « le serveur est juste lent » : l'employé passait en
  /// mode visiteur sans un mot, le jeton mort restant au coffre.
  ///
  /// Les deux fautes ont la même cause : avoir demandé au STATUT de dire ce
  /// que seul le CODE peut dire. 401 reste décisif à lui seul — le jeton
  /// n'existe plus — et `account_disabled` le rejoint. Rien d'autre.
  bool get sessionRejected => isUnauthorized || isAccountDisabled;

  /// Le corps de la requete depasse ce que le serveur accepte.
  ///
  /// Sur un envoi de photos, c'est `post_max_size` : le refus tombe dans un
  /// middleware de Laravel, avant l'authentification et avant toute
  /// validation. Il peut aussi venir d'un mandataire place devant
  /// l'application, qui ne renvoie alors aucun JSON.
  bool get isTooLarge     => statusCode == 413;
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
      // Tombait jusqu'ici dans le cas par defaut, qui rend le message du
      // serveur : « The POST data is too large. » — en anglais, et sans dire
      // quoi faire. Derriere un mandataire, il arrive meme qu'il n'y ait
      // aucun JSON a rendre, et l'utilisateur lisait alors la seule
      // reference de requete. Ce refus-la se repare a l'ecran : il vaut
      // mieux dire comment.
      413 => 'Envoi trop volumineux. Retirez quelques photos ou '
             'réduisez-les, puis réessayez.',
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
