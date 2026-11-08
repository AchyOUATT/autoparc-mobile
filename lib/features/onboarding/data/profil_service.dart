import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ce que l'utilisateur a dit vouloir faire, au premier lancement.
///
/// Ce n'est PAS un rôle : le rôle, c'est la session — personnel, client,
/// partenaire — et c'est le serveur qui le dit. Ceci est une DÉCLARATION, faite
/// avant toute connexion, qui ne donne aucun droit. Elle sert à deux choses :
/// aiguiller le premier lancement (le vendeur part ouvrir son compte, l'acheteur
/// voit la démonstration), et rappeler à un vendeur qui n'a pas fini son
/// inscription qu'il peut la reprendre.
///
/// Les valeurs stockées sont des mots français stables, pas l'index de l'enum :
/// réordonner les cas ne doit pas changer ce que disent les téléphones déjà
/// installés.
enum ProfilUtilisateur {
  acheteur('acheteur'),
  vendeur('vendeur');

  const ProfilUtilisateur(this.cle);

  /// Le mot écrit dans les préférences.
  final String cle;

  /// Nul pour une valeur inconnue — préférences d'une version future, ou
  /// abîmées : mieux vaut « pas de profil » qu'un profil deviné.
  static ProfilUtilisateur? depuis(String? valeur) {
    for (final profil in values) {
      if (profil.cle == valeur) return profil;
    }

    return null;
  }
}

/// Persistance du profil déclaré. Même forme que [OnboardingService] et
/// [LangueService], et pour la même raison : la valeur est lue dans `main()`,
/// avant que l'arbre de widgets existe, donc avant qu'un conteneur Riverpod
/// puisse la servir.
class ProfilService {
  static const _cle = 'profil_utilisateur';

  /// Le profil déclaré, ou nul si personne n'a encore répondu à la question.
  ///
  /// Nul est l'état de TOUTE installation antérieure à cette version : la
  /// question n'est posée qu'au premier lancement, et ces téléphones l'ont
  /// déjà passé. Ils gardent donc l'accueil qu'ils connaissent.
  static Future<ProfilUtilisateur?> lire() async {
    final prefs = await SharedPreferences.getInstance();

    return ProfilUtilisateur.depuis(prefs.getString(_cle));
  }

  static Future<void> ecrire(ProfilUtilisateur profil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, profil.cle);
  }

  // Utilitaire de mise au point uniquement, comme `OnboardingService.reset()`.
  static Future<void> effacer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cle);
  }
}

/// Le profil lu par `main()` avant `runApp`, injecté par surcharge — le même
/// montage que `localeInitialeProvider`, pour que la première trame soit déjà
/// la bonne.
final profilInitialProvider = Provider<ProfilUtilisateur?>((_) => null);

/// Le profil déclaré, et le seul chemin pour le changer.
class Profil extends Notifier<ProfilUtilisateur?> {
  @override
  ProfilUtilisateur? build() => ref.read(profilInitialProvider);

  /// L'état est posé AVANT l'écriture, comme pour la langue : l'aiguillage qui
  /// suit la réponse doit être immédiat. Un échec d'écriture — disque plein,
  /// préférences inaccessibles — ne coûte que l'accueil ordinaire au prochain
  /// lancement : la question, elle, ne revient pas, puisque c'est la porte de
  /// la démonstration qui en décide.
  Future<void> definir(ProfilUtilisateur profil) async {
    if (profil == state) return;
    state = profil;
    await ProfilService.ecrire(profil);
  }
}

final profilUtilisateurProvider =
    NotifierProvider<Profil, ProfilUtilisateur?>(Profil.new);
