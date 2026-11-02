import '../../l10n/app_localizations.dart';

/// Local application messages produced outside the widget tree.
String localizeExceptionMessage(String message, AppLocalizations l10n) {
  if (l10n.localeName.startsWith('fr')) return message;
  switch (message) {
    case "Token manquant dans la réponse.": return l10n.authErrorTokenMissing;
    case "Google n'a pas fourni de jeton d'identité.": return l10n.authErrorGoogleTokenMissing;
    case "Connexion Google interrompue. Si vous n'avez pas fermé la fenêtre, vérifiez votre connexion internet puis réessayez.": return l10n.authErrorGoogleInterrupted;
    case "Connexion Google interrompue. Vérifiez votre connexion internet puis réessayez.": return l10n.authErrorGoogleInterruptedNetwork;
    case "La connexion Google n'est pas correctement configurée pour cette version de l'application.": return l10n.authErrorGoogleConfiguration;
    case "La connexion Google n'est pas disponible sur cet appareil.": return l10n.authErrorGoogleUnavailable;
    case "Impossible d'afficher la fenêtre de connexion Google.": return l10n.authErrorGoogleWindow;
    case "Aucun compte trouvé pour cet email.": return l10n.authErrorAccountMissing;
    case "Mot de passe incorrect.": return l10n.authErrorWrongPassword;
    case "Email ou mot de passe incorrect.": return l10n.authErrorCredentials;
    case "Un compte existe déjà avec cet email.": return l10n.authErrorEmailInUse;
    case "Mot de passe trop faible (6 caractères minimum).": return l10n.authErrorWeakPassword;
    case "Adresse email invalide.": return l10n.authErrorEmailInvalid;
    case "Ce compte a été désactivé. Contactez le support.": return l10n.commonErrorDisabled;
    case "Trop de tentatives. Réessayez dans quelques minutes.": return l10n.commonErrorThrottled;
    case "Erreur réseau. Vérifiez votre connexion internet.": return l10n.authErrorNetwork;
    case "Cette méthode de connexion n'est pas activée.": return l10n.authErrorMethodDisabled;
    case "Ce compte existe déjà avec un autre mode de connexion.": return l10n.authErrorOtherMethod;
    case "Connexion impossible pour le moment. Réessayez.": return l10n.authErrorUnavailable;
    case "Seuls les comptes clients se suppriment ici.": return l10n.authErrorDeleteClientOnly;
    case "Connexion impossible. Vérifiez votre réseau et réessayez.": return l10n.partnerAccountsNetworkError;
    case "La réponse ne correspond pas à une session partenaire.": return l10n.partnerAccountsSessionResponseInvalid;
    case "Cette session partenaire est invalide.": return l10n.partnerAccountsSessionInvalid;
    case "Impossible de vérifier votre session. Réessayez.": return l10n.partnerAccountsSessionCheckFailed;
    case "La connexion n’a pas abouti. Réessayez.": return l10n.partnerAccountsLoginFailed;
    case "La connexion n'a pas abouti. Réessayez.": return l10n.partnerAccountsLoginFailed;
    case "Actualisation impossible. Réessayez.": return l10n.partnerAccountsRefreshFailed;
    case "Pas de connexion. Vérifiez votre réseau puis réessayez.": return l10n.commonErrorNetwork;
    case "Votre session a expiré. Reconnectez-vous.": return l10n.commonErrorSessionExpired;
    case "Introuvable. L’élément a peut-être été supprimé.": return l10n.commonErrorNotFound;
    case "Introuvable. L'élément a peut-être été supprimé.": return l10n.commonErrorNotFound;
    case "Envoi trop volumineux. Retirez quelques photos ou réduisez-les, puis réessayez.": return l10n.commonErrorUploadTooLarge;
    case "Erreur du serveur.": return l10n.commonErrorServer;
    case "Une erreur est survenue. Réessayez.": return l10n.commonErrorGeneric;
    case "Votre rôle ne permet pas cette action.": return l10n.commonErrorPermission;
    case "Service indisponible pour le moment. Réessayez plus tard.": return l10n.commonErrorUnavailable;
    case "Cette version de l'application n'est plus prise en charge. Installez la dernière version pour continuer.": return l10n.updateUnsupportedMessage;
    case "Erreur inconnue.": return l10n.commonErrorGeneric;
  }
  final match0 = RegExp("^Connexion Google impossible \\((.+?)\\)\\.\$").firstMatch(message);
  if (match0 != null) return l10n.authErrorGoogleCode(match0.group(1)!);
  final match1 = RegExp("^Erreur de connexion \\((.+?)\\)\\.\$").firstMatch(message);
  if (match1 != null) return l10n.authErrorCode(match1.group(1)!);
  final google = RegExp(r'^Connexion Google impossible \(([^)]+)\)\.(.*)$').firstMatch(message);
  if (google != null) return '${l10n.authErrorGoogleCode(google.group(1)!)}${google.group(2)!}';
  final reference = RegExp(r'^(.*) \(réf\. ([^)]+)\)$').firstMatch(message);
  if (reference != null) return l10n.commonErrorReference(localizeExceptionMessage(reference.group(1)!, l10n), reference.group(2)!);
  return message;
}
