import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/demarrage.dart';
import '../../../../core/l10n/langue.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../private_sales/data/private_listing_repository.dart';
import '../../data/onboarding_service.dart';
import '../../data/profil_service.dart';

/// La question du premier lancement : « je cherche » ou « je vends » ?
///
/// ── POURQUOI ELLE PASSE AVANT LA DÉMONSTRATION ─────────────────────────────
///
/// La réponse décide de tout le reste. Un vendeur n'a que faire des trois
/// diapositives — catalogue, alertes, garage sont les écrans de l'acheteur — :
/// il part ouvrir son compte, avec le catalogue dessous pour le Retour. Un
/// acheteur les voit, puis l'accueil. Poser la question après aurait fait
/// défiler au vendeur un parcours qui n'est pas le sien.
///
/// ── CE QU'ELLE N'EST PAS ───────────────────────────────────────────────────
///
/// Pas un rôle, pas un compte : une déclaration, qui ne donne aucun droit (voir
/// [ProfilUtilisateur]). Et pas un choix définitif : la carte « Vous vendez ? »
/// de l'accueil ramène le vendeur à l'accueil acheteur par « Pas maintenant »,
/// et le menu garde « Espace partenaire » pour l'acheteur qui change d'avis.
/// Le sous-titre le promet ; ces deux chemins le tiennent.
///
/// « Je ne sais pas encore » prend le chemin de l'acheteur SANS rien écrire :
/// le catalogue est le défaut universel, et un profil deviné vaudrait moins
/// que pas de profil.
///
/// ── LA LANGUE ──────────────────────────────────────────────────────────────
///
/// La page n'est pas passable, et le tiroir — le seul autre endroit où changer
/// de langue — n'est pas encore accessible. D'où le bouton en haut à droite,
/// qui porte le nom de l'AUTRE langue dans sa propre graphie.
class ChoixDeProfilPage extends ConsumerWidget {
  const ChoixDeProfilPage({super.key});

  Future<void> _chercher(BuildContext context, WidgetRef ref) async {
    await ref
        .read(profilUtilisateurProvider.notifier)
        .definir(ProfilUtilisateur.acheteur);
    // La démonstration marque elle-même la porte comme passée, à sa dernière
    // diapositive — ou sur « Passer ». Pas ici : un acheteur qui quitte
    // l'application au milieu des diapositives doit les revoir.
    if (context.mounted) context.go('/onboarding');
  }

  Future<void> _vendre(BuildContext context, WidgetRef ref) async {
    await ref
        .read(profilUtilisateurProvider.notifier)
        .definir(ProfilUtilisateur.vendeur);
    // La porte est passée ICI : le vendeur ne voit pas la démonstration, et
    // rien d'autre ne la marquerait. Sans cette ligne, la question reviendrait
    // à chaque lancement tant que l'inscription n'est pas finie.
    await OnboardingService.markDone();
    if (context.mounted) ouvrirInscriptionVendeur(GoRouter.of(context));
  }

  void _indecis(BuildContext context) => context.go('/onboarding');

  void _changerDeLangue(WidgetRef ref) {
    final courante = ref.read(langueProvider);
    ref
        .read(langueProvider.notifier)
        .definir(courante == localeAnglais ? localeFrancais : localeAnglais);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        // Même construction que les diapositives : une hauteur MINIMALE égale à
        // la hauteur reçue, pour que le contenu reste centré tant qu'il tient,
        // et défile — plutôt que de déborder — quand le texte grossit.
        child: LayoutBuilder(
          builder: (context, contraintes) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: contraintes.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const Key('profil-langue'),
                        onPressed: () => _changerDeLangue(ref),
                        icon: const Icon(Icons.language, size: 18),
                        label: Text(l10n.onboardingProfileOtherLanguage),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Icon(Icons.handshake_outlined, size: 56, color: cs.primary),
                    const SizedBox(height: 20),
                    Text(
                      l10n.onboardingProfileTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.onboardingProfileSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _CarteDeProfil(
                      key: const Key('profil-cherche'),
                      icon: Icons.search,
                      couleur: const Color(0xFF1A3C5E),
                      titre: l10n.onboardingProfileBuyTitle,
                      // Match the availability of /sell; a profile choice
                      // never grants seller permissions or enables the module.
                      corps: privateSalesEnabled
                          ? '${l10n.onboardingProfileBuyBody}\n\n${l10n.onboardingProfileBuyOwnVehicleNotice}'
                          : l10n.onboardingProfileBuyBody,
                      onTap: () => _chercher(context, ref),
                    ),
                    const SizedBox(height: 12),
                    _CarteDeProfil(
                      key: const Key('profil-vends'),
                      icon: Icons.storefront_outlined,
                      couleur: const Color(0xFF2E7D32),
                      titre: l10n.onboardingProfileSellTitle,
                      corps: l10n.onboardingProfileSellBody,
                      onTap: () => _vendre(context, ref),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      key: const Key('profil-indecis'),
                      onPressed: () => _indecis(context),
                      child: Text(l10n.onboardingProfileUndecided),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une des deux cartes : l'icône dans son disque, le titre, le corps, et le
/// chevron qui dit qu'on peut appuyer. En pleine largeur et l'une SOUS l'autre,
/// jamais côte à côte : à 320 points et texte grossi, deux colonnes casseraient
/// les titres dans le mot.
class _CarteDeProfil extends StatelessWidget {
  const _CarteDeProfil({
    super.key,
    required this.icon,
    required this.couleur,
    required this.titre,
    required this.corps,
    required this.onTap,
  });

  final IconData icon;
  final Color couleur;
  final String titre;
  final String corps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: couleur, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: couleur,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      corps,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
