import 'package:auto/features/onboarding/data/onboarding_service.dart';
import 'package:auto/features/onboarding/data/profil_service.dart';
import 'package:auto/core/demarrage.dart' show destinationDeDepart;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La démo des fonctionnalités, et la porte qui décide de l'afficher.
///
/// C'est le tout premier écran qu'un utilisateur voit, et la décision se prend
/// une seule fois, dans `main()`, avant même que l'application soit montée :
///
///     final onboardingDone = await OnboardingService.isDone();
///     runApp(... AutoParcApp(onboardingDone: onboardingDone));
///     // puis, dans le routeur :
///     initialLocation: onboardingDone ? '/' : '/onboarding'
///
/// Cette porte n'était couverte par aucun test. Elle tient pourtant à un
/// `?? false` : si ce défaut passait un jour à `true` — par prudence mal
/// placée, ou par une relecture trop rapide — plus personne ne verrait jamais
/// la démo, et rien ne le signalerait. L'inverse est aussi muet : un
/// `markDone()` qui n'écrirait pas la ferait revenir à chaque ouverture, ce
/// qui se remarque, mais seulement une fois chez l'utilisateur.
///
/// Les deux sens sont donc figés ici.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('La porte de première utilisation', () {
    test('une installation neuve n\'a jamais vu la démo', () async {
      // Préférences vides : c'est exactement l'état d'un téléphone qui vient
      // d'installer l'application.
      expect(
        await OnboardingService.isDone(),
        isFalse,
        reason: 'Le défaut de isDone() décide de ce que voit tout nouvel '
            'utilisateur. À true, la démo ne s\'afficherait plus jamais.',
      );
    });

    test('la démo marquée vue ne revient pas', () async {
      await OnboardingService.markDone();

      expect(await OnboardingService.isDone(), isTrue);
    });

    test('elle reste vue d\'un lancement à l\'autre', () async {
      // markDone() écrit dans SharedPreferences, qui survit à la fermeture de
      // l'application. On relit depuis une instance neuve pour s'assurer que
      // la valeur est bien persistée et non gardée en mémoire.
      await OnboardingService.markDone();

      SharedPreferences.resetStatic();

      expect(
        await OnboardingService.isDone(),
        isTrue,
        reason: 'Revoir la démo à chaque ouverture est le symptôme d\'un '
            'markDone() qui n\'écrit pas.',
      );
    });

    test('la réinitialisation ramène la démo', () async {
      // Utilitaire de mise au point : il doit vraiment remettre la porte à
      // zéro, sans quoi on ne peut plus eprouver le premier lancement sans
      // désinstaller l'application.
      await OnboardingService.markDone();
      await OnboardingService.reset();

      expect(await OnboardingService.isDone(), isFalse);
    });
  });

  /// Ce que l'utilisateur a dit vouloir faire — acheter ou vendre.
  ///
  /// La même mécanique que la porte, et les mêmes deux pièges : un défaut qui
  /// inventerait un profil ferait partir TOUT nouvel utilisateur vers
  /// l'inscription vendeur ou lui cacherait la carte « Vous vendez ? » ; une
  /// écriture qui ne tiendrait pas d'un lancement à l'autre ferait oublier au
  /// vendeur qu'il a une inscription à finir.
  group('Le profil déclaré', () {
    test('une installation neuve n\'a pas de profil', () async {
      expect(
        await ProfilService.lire(),
        isNull,
        reason: 'Nul est aussi l\'état de tous les téléphones installés avant '
            'cette version : ils ont passé la porte sans qu\'on leur ait '
            'posé la question, et doivent garder l\'accueil qu\'ils '
            'connaissent.',
      );
    });

    test('chaque réponse se relit telle qu\'elle a été donnée', () async {
      for (final profil in ProfilUtilisateur.values) {
        await ProfilService.ecrire(profil);

        expect(await ProfilService.lire(), profil);
      }
    });

    test('elle survit d\'un lancement à l\'autre', () async {
      await ProfilService.ecrire(ProfilUtilisateur.vendeur);

      SharedPreferences.resetStatic();

      expect(await ProfilService.lire(), ProfilUtilisateur.vendeur);
    });

    test('une valeur inconnue ne devient pas un profil', () async {
      // Préférences écrites par une version future, ou abîmées : mieux vaut
      // « pas de profil » qu'un profil deviné — et surtout pas le premier de
      // l'enum par défaut.
      SharedPreferences.setMockInitialValues({'profil_utilisateur': 'garagiste'});

      expect(await ProfilService.lire(), isNull);
    });

    test('l\'effacement ramène à l\'absence de profil', () async {
      await ProfilService.ecrire(ProfilUtilisateur.acheteur);
      await ProfilService.effacer();

      expect(await ProfilService.lire(), isNull);
    });

    test('les mots stockés sont figés', () {
      // Réordonner ou renommer les cas de l'enum ne doit pas changer ce que
      // disent les téléphones déjà installés : ce sont ces deux mots, et
      // aucun autre, qui sont écrits dans leurs préférences.
      expect(ProfilUtilisateur.acheteur.cle, 'acheteur');
      expect(ProfilUtilisateur.vendeur.cle, 'vendeur');
    });
  });

  group('La destination de départ', () {
    // Le routeur n'est pas monté ici, mais c'est bien la règle de main.dart
    // qui est appelée — `destinationDeDepart` —, et non une recopie.
    test('première utilisation : la question « acheter ou vendre »', () {
      expect(
        destinationDeDepart(demoVue: false),
        '/bienvenue',
        reason: 'La question passe AVANT la démonstration : c\'est elle qui '
            'décide si l\'on voit les diapositives ou l\'inscription vendeur.',
      );
    });

    test('utilisations suivantes : l\'accueil', () {
      expect(destinationDeDepart(demoVue: true), '/');
    });
  });
}
