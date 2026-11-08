import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../partner_accounts/presentation/partner_dashboard_page.dart';
import '../../../partner_accounts/presentation/partner_session.dart';
import 'home_page.dart';

/// Ce que la route `/` affiche, selon qui tient le téléphone.
///
/// ── TROIS PUBLICS, UNE PRIORITÉ ÉCRITE ─────────────────────────────────────
///
/// Le personnel d'abord, le partenaire ensuite, l'acheteur sinon. Les sessions
/// sont indépendantes — un employé peut avoir ouvert un compte partenaire
/// d'essai sur le même téléphone — et sans règle écrite, c'est l'ordre des
/// `if` qui aurait décidé. Le personnel passe devant parce qu'il est le public
/// le plus rare et le plus outillé, et que ses tuiles de tiroir l'attendent
/// derrière l'accueil ; les annonces du partenaire, elles, restent à un appui
/// du tiroir (« Mes annonces »). Le tableau de bord n'a pas d'autre route que
/// `/` : sur ce téléphone-là, il n'existe pas tant que la session du personnel
/// est ouverte, et le tiroir ne le promet pas.
///
/// ── CE SUR QUOI ON NE BRANCHE PAS ──────────────────────────────────────────
///
/// Sur `profile` seulement, jamais sur `loading` : ce drapeau a quatre
/// producteurs — l'état de départ, la connexion, la déconnexion, un coffre
/// d'avant le profil enregistré — et il peut durer soixante secondes sur une
/// instance qui se réveille. Un écran vide pendant ce temps aurait été pire que
/// le clignotement qu'il voulait éviter ; et ce clignotement n'existe plus,
/// puisque `main()` lit le coffre avant la première trame
/// (`sessionPartenaireAuDemarrage`).
///
/// Une session REJETÉE (`deniedStatus`) ou un coffre qui n'a pas pu être
/// confirmé (`restoreFailed`) rendent l'accueil acheteur, qui porte alors une
/// carte ou un bandeau pour le dire — voir `home_page.dart`. Ici, seul le
/// profil décide.
class AccueilSelonProfil extends ConsumerWidget {
  const AccueilSelonProfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authProvider.select((a) => a.isStaff));
    final partenaire = ref.watch(
      partnerSessionProvider.select((s) => s.profile != null),
    );

    if (!personnel && partenaire) return const PartnerDashboardPage();

    return const HomePage();
  }
}
