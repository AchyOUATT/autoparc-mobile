import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/contact/feuille_contact.dart';
import '../../../core/providers/shell_scaffold_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/pages/home_page.dart' show BrowseSection;
import '../../vehicles/presentation/pages/vehicle_form_mode.dart';
import '../../vehicles/presentation/pages/vehicle_register_page.dart';
import '../data/notice_tableau_de_bord.dart';
import '../data/partner_repository.dart';
import 'partner_listing_form.dart';
import 'partner_listings_page.dart';
import 'partner_localizations.dart';
import 'partner_notifications_page.dart';
import 'partner_session.dart';

export '../data/notice_tableau_de_bord.dart' show NoticeTableauDeBord;

/// Les compteurs du tableau de bord, RATTACHÉS AU COMPTE.
///
/// `select` sur l'identifiant du compte, et non sur la session entière : une
/// déconnexion ou une connexion sous un autre compte invalident les compteurs
/// d'eux-mêmes — sans cela, un `FutureProvider` aurait gardé en cache les
/// chiffres du compte A après une connexion sous B —, tandis qu'une
/// vérification silencieuse au retour au premier plan, qui ne change pas le
/// compte, ne les relit pas.
final partnerDashboardProvider = FutureProvider.autoDispose<PartnerDashboard>((
  ref,
) {
  ref.watch(partnerSessionProvider.select((s) => s.profile?.account['id']));

  return ref.watch(partnerRepositoryProvider).dashboard();
});

/// L'accueil d'un partenaire connecté.
///
/// ── CE QU'ELLE REMPLACE, ET CE QU'ELLE GARDE ──────────────────────────────
///
/// L'accueil acheteur — sa voiture, ses pièces, la vitrine — ne parle pas à un
/// vendeur. Il ouvre ici : son compte, ce qui réclame son attention, ses trois
/// inventaires, sa boîte aux lettres. Et, en bas, LA MÊME rangée de recherche
/// que l'accueil acheteur, parce qu'un partenaire cherche comme tout le monde
/// — et les quatre onglets du bas restent les siens.
///
/// ── UN COMPTE EN ATTENTE OUVRE ICI AUSSI ──────────────────────────────────
///
/// Il n'a rien à compter, mais trois questions : qui examine, comment il le
/// saura, ce qu'il peut faire en attendant. La page y répond, donne un bouton
/// pour vérifier tout de suite, et le moyen de joindre la boutique.
///
/// ── LES COMPTEURS PEUVENT MANQUER, LA PAGE NON ────────────────────────────
///
/// Un serveur antérieur à la route rend 404 ; un réseau coupé, rien. Les
/// cartes restent navigables avec un tiret à la place du chiffre, et seul un
/// 503 — l'espace fermé — montre le motif du serveur : les autres messages
/// (« The route … could not be found ») ne sont pas pour l'utilisateur.
class PartnerDashboardPage extends ConsumerStatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  ConsumerState<PartnerDashboardPage> createState() =>
      _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends ConsumerState<PartnerDashboardPage> {
  /// Nul tant que la préférence n'est pas lue ; la ligne ne s'affiche que sur
  /// un `false` lu, jamais pendant la lecture.
  bool? _noticeVue;

  @override
  void initState() {
    super.initState();
    NoticeTableauDeBord.estVue().then((vue) {
      if (mounted) setState(() => _noticeVue = vue);
    });
  }

  Future<void> _fermerLaNotice() async {
    setState(() => _noticeVue = true);
    await NoticeTableauDeBord.marquerVue();
  }

  Future<void> _actualiser() async {
    ref.invalidate(partnerDashboardProvider);
    ref.invalidate(partnerUnreadCountProvider);
    await ref.read(partnerSessionProvider.notifier).refresh(silencieux: true);
  }

  /// Le formulaire de création, par les DEUX chemins de la liste des annonces
  /// (`partner_listings_page.dart`) : le véhicule passe par le formulaire du
  /// personnel en mode partenaire, pièces et accessoires par le leur. Au
  /// retour d'un enregistrement, les compteurs sont relus.
  /// ── `rootNavigator: true`, ET C'EST MESURÉ ─────────────────────────────
  ///
  /// Cette page vit DANS la coque (`ShellRoute`, route `/`), donc dans un
  /// Navigator imbriqué dont la barre du bas et le tiroir sont les frères.
  /// Un `push` sur ce Navigator-là empilait le formulaire SOUS la barre du
  /// bas, toujours visible et touchable ; un appui sur « Pièces » remplaçait
  /// la page `/` de la coque, et Flutter achevait les routes sans page qui
  /// y étaient accrochées : dix champs remplis, formulaire disparu, sans un
  /// mot. Reproduit par `tableau_de_bord_dans_la_coque_test.dart`. Le même
  /// écran ouvert par le tiroir (`/partner`, Navigator racine) était plein
  /// écran : deux habillages pour un même formulaire. La racine, donc —
  /// comme `product_gallery.dart` le fait déjà pour la vue plein écran.
  Future<void> _creer(PartnerListingKind kind) async {
    final enregistre = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => kind == PartnerListingKind.vehicles
            ? const VehicleRegisterPage(mode: VehicleFormMode.partenaire)
            : PartnerListingFormPage(kind: kind),
      ),
    );
    if (enregistre == true && mounted) ref.invalidate(partnerDashboardProvider);
  }

  Future<void> _ouvrir(PartnerListingKind kind) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => PartnerListingsPage(kind: kind)),
    );
    // La liste publie, dépublie, archive : les chiffres ont pu bouger.
    if (mounted) ref.invalidate(partnerDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(partnerSessionProvider);
    final profile = session.profile;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: l10n.commonMenuTooltip,
          onPressed: () =>
              ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: Text(l10n.partnerDashboardTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _actualiser,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            if (_noticeVue == false)
              _Bienvenue(key: const Key('partner-dashboard-notice'), onOk: _fermerLaNotice),
            if (profile != null) _EnTete(profile: profile, session: session),
            // Un 503 sur une session connue : l'espace est refermé — pour
            // maintenance, le plus souvent. Une carte qui le dit, et non le
            // texte brut du serveur, qui parle d'inscription à un inscrit.
            if (session.espaceFerme)
              Card(
                key: const Key('partner-dashboard-espace-ferme'),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.lock_clock_outlined),
                  title: Text(l10n.partnerDashboardSpaceClosed),
                ),
              )
            else if (session.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  messageFor(session.error!, l10n: l10n),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (profile != null && !profile.approved)
              _Attente(profile: profile, session: session)
            else if (profile != null) ...[
              _AFaire(onOuvrir: _ouvrir),
              for (final kind in PartnerListingKind.values)
                _CarteInventaire(
                  kind: kind,
                  onOuvrir: () => _ouvrir(kind),
                  onCreer: () => _creer(kind),
                ),
              const _ReessayerLesCompteurs(),
            ],
            const _TuileDemandes(),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                l10n.partnerDashboardSearchTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const BrowseSection(),
          ],
        ),
      ),
    );
  }
}

class _Bienvenue extends StatelessWidget {
  const _Bienvenue({super.key, required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).partnerDashboardWelcomeNotice,
              style: TextStyle(color: cs.onSecondaryContainer),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('partner-dashboard-notice-ok'),
                onPressed: onOk,
                child: Text(
                  AppLocalizations.of(context).partnerDashboardWelcomeDismiss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le nom et la puce de statut — la même puce que l'espace partenaire, et la
/// même règle : pendant la fenêtre optimiste, le statut vient du coffre et
/// peut être périmé, donc « à confirmer » REMPLACE le libellé.
class _EnTete extends StatelessWidget {
  const _EnTete({required this.profile, required this.session});

  final PartnerProfile profile;
  final PartnerSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icone, String libelle) = session.sessionAConfirmer
        ? (Icons.sync, l10n.partnerAccountsStatusUnconfirmed)
        : profile.approved
        ? (Icons.verified_outlined, l10n.partnerAccountsAccountApproved)
        : (Icons.hourglass_top_outlined, l10n.shellAccountPartnerPending);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Chip(avatar: Icon(icone, size: 18), label: Text(libelle)),
        ],
      ),
    );
  }
}

/// Le tableau de bord d'un compte pas encore approuvé — ou refusé, ou
/// suspendu, quand le serveur rend encore le profil.
class _Attente extends ConsumerWidget {
  const _Attente({required this.profile, required this.session});

  final PartnerProfile profile;
  final PartnerSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final (String titre, String corps, IconData icone) = switch (profile.status) {
      'rejected' => (
        l10n.partnerAccountsRejectedTitle,
        l10n.partnerAccountsRejectedDescription,
        Icons.info_outline,
      ),
      'suspended' => (
        l10n.partnerAccountsSuspendedTitle,
        l10n.partnerAccountsSuspendedDescription,
        Icons.pause_circle_outline,
      ),
      _ => (
        l10n.partnerDashboardPendingTitle,
        l10n.partnerDashboardPendingBody,
        Icons.hourglass_top_outlined,
      ),
    };
    final motif = profile.reviewReason;

    return Card(
      key: const Key('partner-dashboard-attente'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icone, size: 44, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(corps, textAlign: TextAlign.center),
            if (motif != null && motif.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.partnerAccountsReason(motif),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
            if (profile.status == 'pending') ...[
              const SizedBox(height: 12),
              Text(
                l10n.partnerDashboardPendingMeanwhile,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('partner-dashboard-verifier'),
              onPressed: session.loading
                  ? null
                  : ref.read(partnerSessionProvider.notifier).refresh,
              icon: const Icon(Icons.refresh),
              label: Text(
                session.loading
                    ? l10n.partnerAccountsRefreshing
                    : l10n.partnerAccountsCheckStatus,
              ),
            ),
            TextButton.icon(
              key: const Key('partner-dashboard-contact'),
              onPressed: () => afficherFeuilleContact(context, ref),
              icon: const Icon(Icons.phone_outlined),
              label: Text(l10n.partnerDashboardContactUs),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une ligne « À faire » : ce qu'elle compte, et l'inventaire qu'elle ouvre.
class _LigneAFaire {
  const _LigneAFaire(this.count, this.libelle, this.icone, this.kind);

  final int count;
  final String libelle;
  final IconData icone;

  /// L'inventaire qui contribue le plus à ce compte : c'est lui que la ligne
  /// ouvre.
  final PartnerListingKind kind;
}

/// Trois lignes au plus, classées par ce qui coûte le plus au vendeur : une
/// annonce en ligne sans photo ne se vend pas ; une rupture publiée fait venir
/// pour rien ; un brouillon ne se vend pas non plus mais ne trompe personne ;
/// une promotion qui finit se prolonge ou pas ; un stock faible attend.
///
/// Rien quand tout est à zéro : un titre « À faire » sans ligne apprendrait à
/// ne plus regarder.
class _AFaire extends ConsumerWidget {
  const _AFaire({required this.onOuvrir});

  final Future<void> Function(PartnerListingKind) onOuvrir;

  static PartnerListingKind _dominant(
    PartnerDashboard tableau,
    int Function(PartnerDashboardCounts) lecture,
  ) {
    var meilleur = PartnerListingKind.vehicles;
    var max = -1;
    for (final kind in PartnerListingKind.values) {
      final valeur = lecture(tableau.counts[kind] ?? const PartnerDashboardCounts());
      if (valeur > max) {
        max = valeur;
        meilleur = kind;
      }
    }

    return meilleur;
  }

  static List<_LigneAFaire> lignes(PartnerDashboard tableau, AppLocalizations l10n) {
    int somme(int Function(PartnerDashboardCounts) lecture) => tableau.counts.values
        .fold(0, (total, counts) => total + lecture(counts));

    final candidates = <_LigneAFaire>[
      _LigneAFaire(
        somme((c) => c.withoutPhoto),
        l10n.partnerDashboardTodoWithoutPhoto(somme((c) => c.withoutPhoto)),
        Icons.no_photography_outlined,
        _dominant(tableau, (c) => c.withoutPhoto),
      ),
      _LigneAFaire(
        somme((c) => c.outOfStock),
        l10n.partnerDashboardTodoOutOfStock(somme((c) => c.outOfStock)),
        Icons.remove_shopping_cart_outlined,
        _dominant(tableau, (c) => c.outOfStock),
      ),
      _LigneAFaire(
        somme((c) => c.drafts),
        l10n.partnerDashboardTodoDrafts(somme((c) => c.drafts)),
        Icons.edit_note_outlined,
        _dominant(tableau, (c) => c.drafts),
      ),
      _LigneAFaire(
        somme((c) => c.promotionEndingSoon),
        l10n.partnerDashboardTodoPromotionEnding(somme((c) => c.promotionEndingSoon)),
        Icons.timer_outlined,
        _dominant(tableau, (c) => c.promotionEndingSoon),
      ),
      _LigneAFaire(
        somme((c) => c.lowStock),
        l10n.partnerDashboardTodoLowStock(somme((c) => c.lowStock)),
        Icons.inventory_2_outlined,
        _dominant(tableau, (c) => c.lowStock),
      ),
    ];

    return candidates.where((ligne) => ligne.count > 0).take(3).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableau = ref.watch(partnerDashboardProvider).valueOrNull;
    if (tableau == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final aFaire = lignes(tableau, l10n);
    if (aFaire.isEmpty) return const SizedBox.shrink();

    return Card(
      key: const Key('partner-dashboard-a-faire'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.partnerDashboardTodoTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final ligne in aFaire)
            ListTile(
              dense: true,
              leading: Icon(ligne.icone),
              title: Text(ligne.libelle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOuvrir(ligne.kind),
            ),
        ],
      ),
    );
  }
}

/// Un inventaire : son nom, son total, son résumé, et le « + » qui crée.
///
/// ── POURQUOI LE NOMBRE N'EST PAS À DROITE ──────────────────────────────────
///
/// Il y était, en gros caractères à côté du « + », dans le `trailing` de la
/// tuile. Mesuré à 320 points et texte ×1,3 : le titre « Véhicules » ne
/// recevait plus que 90,4 points pour 94,0 voulus et se cassait DANS le mot —
/// et la rangée de droite, trop large pour sa boîte, débordait en silence
/// jusqu'à rendre le « + » intouchable (le test l'appuyait sans effet). Le
/// nombre vit donc sous le titre, en première ligne du résumé, et la droite
/// ne porte que le « + ». Un nombre coupé est un nombre FAUX, voir
/// test/support/echelles.dart.
class _CarteInventaire extends ConsumerWidget {
  const _CarteInventaire({
    required this.kind,
    required this.onOuvrir,
    required this.onCreer,
  });

  final PartnerListingKind kind;
  final VoidCallback onOuvrir;
  final VoidCallback onCreer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tableau = ref.watch(partnerDashboardProvider);
    final counts = tableau.valueOrNull?.counts[kind];

    final String total;
    final String? resume;
    if (counts != null) {
      total = l10n.partnerDashboardTotal(counts.total);
      resume = counts.total == 0
          ? null
          : '${l10n.partnerDashboardPublished(counts.published)} · ${l10n.partnerDashboardDrafts(counts.drafts)}';
    } else {
      final erreur = tableau.error;
      total = '—';
      // Seul le 503 porte un motif pour l'utilisateur ; tout le reste — 404
      // d'un serveur antérieur, réseau — se dit par « compteurs
      // indisponibles », jamais par le texte brut du serveur.
      resume = erreur is PartnerApiException && erreur.statusCode == 503
          ? messageFor(erreur, l10n: l10n)
          : tableau.isLoading
          ? null
          : l10n.partnerDashboardCountsUnavailable;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('partner-dashboard-carte-${kind.name}'),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        leading: Icon(switch (kind) {
          PartnerListingKind.vehicles => Icons.directions_car_outlined,
          PartnerListingKind.parts => Icons.build_outlined,
          PartnerListingKind.accessories => Icons.shopping_bag_outlined,
        }, size: 30),
        title: Text(partnerListingKindLabel(l10n, kind)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total,
              key: Key('partner-dashboard-total-${kind.name}'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (resume != null) Text(resume),
          ],
        ),
        trailing: IconButton(
          key: Key('partner-dashboard-creer-${kind.name}'),
          tooltip: l10n.partnerAccountsCreateListing,
          onPressed: onCreer,
          icon: const Icon(Icons.add_circle_outline),
        ),
        onTap: onOuvrir,
      ),
    );
  }
}

/// « Réessayer », UNE fois sous les trois cartes quand les compteurs manquent
/// — et non dans chaque carte : trois boutons pour un seul appel, et une
/// rangée « texte + bouton » dans un résumé de 36 points qui cassait
/// « Compteurs » dans le mot.
class _ReessayerLesCompteurs extends ConsumerWidget {
  const _ReessayerLesCompteurs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableau = ref.watch(partnerDashboardProvider);
    if (!tableau.hasError || tableau.isLoading) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        key: const Key('partner-dashboard-reessayer'),
        onPressed: () => ref.invalidate(partnerDashboardProvider),
        icon: const Icon(Icons.refresh),
        label: Text(AppLocalizations.of(context).commonRetry),
      ),
    );
  }
}

/// La boîte aux lettres, avec sa pastille — la même tuile que le hub, y
/// compris pour un compte en attente : la route des notifications est hors
/// de `partner.approved`, c'est par elle qu'il apprendra son approbation.
class _TuileDemandes extends ConsumerWidget {
  const _TuileDemandes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final compte = ref.watch(partnerUnreadCountProvider).valueOrNull ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('partner-dashboard-demandes'),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        leading: const Icon(Icons.campaign_outlined, size: 30),
        title: Text(l10n.partnerAccountsCustomerRequests),
        subtitle: Text(l10n.partnerAccountsCustomerRequestsSubtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rien plutôt qu'un « 0 » : une pastille à zéro attire l'œil sur
            // une absence, et apprend à ne plus la regarder.
            if (compte > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  key: const Key('partner-dashboard-demandes-pastille'),
                  visualDensity: VisualDensity.compact,
                  label: Text('$compte'),
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/partner/demandes'),
      ),
    );
  }
}
