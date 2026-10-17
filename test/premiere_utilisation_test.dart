import 'package:auto/features/onboarding/data/onboarding_service.dart';
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

  group('La destination de départ', () {
    // Le routeur n'est pas monté ici : on fige la règle elle-même, qui vit
    // dans main.dart sous la forme `onboardingDone ? '/' : '/onboarding'`.
    String destination({required bool demoVue}) =>
        demoVue ? '/' : '/onboarding';

    test('première utilisation : la démo', () {
      expect(destination(demoVue: false), '/onboarding');
    });

    test('utilisations suivantes : l\'accueil', () {
      expect(destination(demoVue: true), '/');
    });
  });
}
