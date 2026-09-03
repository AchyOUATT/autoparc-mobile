import 'package:shared_preferences/shared_preferences.dart';

/// Persistance minimale du statut d'onboarding.
/// N'expose pas de Provider — utilisé directement dans main() et OnboardingPage.
class OnboardingService {
  static const _key = 'onboarding_done';

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  // Utilitaire de debug uniquement (réinitialise l'onboarding).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
