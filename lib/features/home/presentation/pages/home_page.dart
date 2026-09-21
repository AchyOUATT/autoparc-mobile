import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/providers/shell_scaffold_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/catalog_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/data/models/part.dart';
import '../../../catalog/data/models/vehicle.dart';
import '../../../garage/data/models/owned_vehicle.dart';
import '../../../garage/presentation/providers/garage_provider.dart';
import '../../../garage/presentation/widgets/engine_prompt.dart';
import '../../../garage/presentation/widgets/mileage_dialog.dart';
import '../../../notifications/presentation/widgets/notification_icon_button.dart';
import '../providers/home_providers.dart';

/// Accueil.
///
/// L'application ouvrait sur la recherche de véhicules. C'est le bon choix
/// pour un acheteur, qui vient une fois puis disparaît trois ans — mais le
/// public principal est le propriétaire, qui revient. Or son garage était
/// derrière le menu : en lançant l'application, rien ne lui disait qu'une
/// échéance approchait.
///
/// D'où l'ordre : sa voiture d'abord, les pièces qui lui vont ensuite, la
/// vitrine en dernier.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () =>
              ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: const Text('Accueil'),
        actions: const [NotificationIconButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(garageProvider);
          ref.invalidate(homeDealsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            // Le personnel n'a pas de garage : on lui montre la vitrine.
            if (!auth.isStaff) const _MyVehicleSection(),
            const _DealsSection(),
            const _BrowseSection(),
            const SizedBox(height: 8),
            const _NeedPrompt(),
          ],
        ),
      ),
    );
  }
}

// ── Ma voiture ────────────────────────────────────────────────────────

class _MyVehicleSection extends ConsumerWidget {
  const _MyVehicleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Un visiteur non connecté n'a pas de garage : l'interroger lui vaudrait
    // un 401, et l'invitation lui annoncerait « votre session a expiré » —
    // pour une session qu'il n'a jamais ouverte.
    if (!ref.watch(authProvider).isClient) return const _AddVehicleCard();

    final garage = ref.watch(garageProvider);

    return garage.when(
      loading: () => const _SectionSkeleton(height: 180),
      // Un garage illisible ne doit pas emporter la page, ni faire croire à
      // son propriétaire qu'il n'a pas de véhicule : on dit l'échec et on
      // propose de réessayer. La vitrine, elle, ne dépend d'aucun compte.
      error: (e, _) => _GarageUnavailable(
        message: messageFor(e),
        onRetry: () => ref.invalidate(garageProvider),
      ),
      data: (vehicles) {
        if (vehicles.isEmpty) return const _AddVehicleCard();

        final vehicle = ref.watch(homeVehicleProvider);
        if (vehicle == null) return const _AddVehicleCard();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vehicles.length > 1) _VehicleSelector(vehicles: vehicles, selected: vehicle),
            _VehicleCard(vehicle: vehicle),
            _CompatiblePartsSection(vehicle: vehicle),
          ],
        );
      },
    );
  }
}

/// Sélecteur des véhicules du garage.
///
/// La pastille sur les puces non sélectionnées est le point important : elle
/// signale qu'un autre véhicule réclame de l'attention, sans obliger à en
/// faire le tour.
class _VehicleSelector extends ConsumerWidget {
  final List<OwnedVehicle> vehicles;
  final OwnedVehicle selected;

  const _VehicleSelector({required this.vehicles, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v       = vehicles[i];
          final actif   = v.id == selected.id;
          final alerte  = !actif && needsAttention(v);

          return Center(
            child: ChoiceChip(
              selected: actif,
              onSelected: (_) =>
                  ref.read(homeSelectedVehicleIdProvider.notifier).state = v.id,
              avatar: alerte
                  ? Icon(Icons.circle, size: 10, color: cs.error)
                  : null,
              label: Text(v.nickname ?? v.designation),
            ),
          );
        },
      ),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final OwnedVehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs        = Theme.of(context).colorScheme;
    final prochaine = vehicle.nextDeadline;
    final autres    = vehicle.deadlines.where((d) => d != prochaine).take(2);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le logo de la marque tient dans la ligne de titre.
          //
          // Il occupait auparavant un bandeau de 120 px en haut de la carte —
          // la moitie de sa hauteur pour une icone, qui repoussait les
          // echeances sous la ligne de flottaison. Or ce sont elles la raison
          // d'ouvrir l'application.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: BrandLogo(slug: _slug(vehicle.identity.brand), size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vehicle.nickname ?? vehicle.designation,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vehicle.mileageKm != null)
                      Text(
                        '${_fmtKm(vehicle.mileageKm!)} km',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (prochaine != null)
                  _UrgentDeadline(deadline: prochaine)
                else
                  _NoDeadline(vehicle: vehicle),

                // Une seule échéance est mise en couleur. Tout colorer
                // reviendrait à ne rien signaler.
                for (final d in autres)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        // Une echeance depassee reste rouge meme en seconde
                        // ligne : elle s'affichait en gris, de la meme encre
                        // qu'une date lointaine, et une visite technique
                        // expiree se lisait comme une formalite a venir.
                        Icon(
                          d.overdue ? Icons.error_outline : _iconFor(d.kind),
                          size: 16,
                          color: d.overdue ? cs.error : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _libelle(d),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: d.overdue ? cs.error : cs.onSurfaceVariant,
                              fontWeight:
                                  d.overdue ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Sous les échéances, et non au-dessus : les dates sont la
                // raison d'ouvrir l'application, le manque à combler vient
                // ensuite. Il disparaît de lui-même une fois renseigné.
                if (!vehicle.compatibilityReady) ...[
                  const SizedBox(height: 10),
                  MissingEngineBanner(vehicle: vehicle),
                ],

                const SizedBox(height: 10),
                // Le geste qui fait vivre le rappel de vidange : sans
                // kilométrage tenu à jour, il ne part jamais.
                OutlinedButton.icon(
                  onPressed: () => showMileageDialog(context, ref, vehicle),
                  icon: const Icon(Icons.speed_outlined, size: 18),
                  label: const Text('Mettre à jour le kilométrage'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentDeadline extends StatelessWidget {
  final VehicleDeadline deadline;
  const _UrgentDeadline({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final depasse = deadline.overdue;

    // Rouge pour ce qui est déjà dépassé, ambre pour ce qui approche : la
    // nuance porte l'urgence sans texte supplémentaire.
    final fond    = depasse ? cs.errorContainer : const Color(0xFFFAEEDA);
    final encre   = depasse ? cs.onErrorContainer : const Color(0xFF412402);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            depasse ? Icons.error_outline : Icons.schedule,
            size: 18,
            color: encre,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _libelle(deadline),
              style: TextStyle(
                color: encre,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aucune échéance connue : on demande les dates plutôt que d'afficher un vide.
class _NoDeadline extends StatelessWidget {
  final OwnedVehicle vehicle;
  const _NoDeadline({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => context.push('/garage'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.event_note_outlined, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Renseignez vos échéances pour être prévenu à temps',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Le garage n'a pas pu être chargé.
///
/// Distinct de l'invitation : dire « enregistrez votre véhicule » à quelqu'un
/// qui en a trois, parce que la requête a échoué, est pire que ne rien dire.
class _GarageUnavailable extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GarageUnavailable({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 22, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre garage n\'a pas pu être chargé',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

/// Pas encore de véhicule : c'est le moment de conversion vers les rappels.
class _AddVehicleCard extends StatelessWidget {
  const _AddVehicleCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 34, color: cs.primary),
            const SizedBox(height: 10),
            Text(
              'Enregistrez votre véhicule',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Visite technique, assurance, vidange : nous vous prévenons '
                  'avant l\'échéance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => context.push('/garage/add'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: const Text('Ajouter ma voiture'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pièces pour ce véhicule ───────────────────────────────────────────

class _CompatiblePartsSection extends ConsumerWidget {
  final OwnedVehicle vehicle;
  const _CompatiblePartsSection({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parts = ref.watch(homeCompatiblePartsProvider(vehicle.id));

    return parts.maybeWhen(
      // Une bande vide ou en erreur disparaît : mieux vaut rien qu'un cadre
      // creux au milieu de la page.
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  'Pièces pour ${vehicle.identity.model ?? 'votre véhicule'}',
                  onSeeAll: () => context.push('/garage/${vehicle.id}/parts',
                      extra: vehicle),
                ),
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _PartTile(part: list[i]),
                  ),
                ),
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _PartTile extends StatelessWidget {
  final Part part;
  const _PartTile({required this.part});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 118,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => context.push('/parts/${part.id}', extra: part),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 62,
                width: double.infinity,
                child: part.coverUrl != null
                    ? CatalogImage(
                        url: part.coverUrl!,
                        fallback: _PartFallback(cs: cs),
                      )
                    : _PartFallback(cs: cs),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.25),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatXof(part.pricing.sellingPrice),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartFallback extends StatelessWidget {
  final ColorScheme cs;
  const _PartFallback({required this.cs});

  @override
  Widget build(BuildContext context) => Container(
        color: cs.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.settings_outlined, size: 24, color: cs.onSurfaceVariant),
      );
}

// ── Bonnes affaires ───────────────────────────────────────────────────

class _DealsSection extends ConsumerWidget {
  const _DealsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(homeDealsProvider);

    return deals.maybeWhen(
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  'Bonnes affaires',
                  onSeeAll: () => context.go('/vehicles'),
                ),
                // Ajusté au contenu réel : une carte sans ville laissait
                // sinon un bandeau vide sous le prix.
                SizedBox(
                  height: 152,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _DealTile(vehicle: list[i]),
                  ),
                ),
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _DealTile extends StatelessWidget {
  final Vehicle vehicle;
  const _DealTile({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c  = vehicle.commercial;

    final couverture = Container(
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: BrandLogo(slug: vehicle.identity.brandSlug, size: 40),
    );

    return SizedBox(
      width: 168,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => context.push('/vehicles/${vehicle.id}', extra: vehicle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 86,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (vehicle.mediaUrls.isEmpty)
                      couverture
                    else
                      CatalogImage(
                        url: vehicle.mediaUrls.first,
                        fallback: couverture,
                      ),
                    if (c.dealLabel != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB26A00),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.dealLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.identity.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                    if (c.locationCity != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        c.locationCity!,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      c.salePrice != null
                          ? formatXof(c.salePrice)
                          : '${formatXof(c.rentalDailyRate)}/j',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Parcourir ─────────────────────────────────────────────────────────

class _BrowseSection extends StatelessWidget {
  const _BrowseSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: [
          Expanded(
            child: _BrowseTile(
              icon: Icons.directions_car_outlined,
              label: 'Véhicules',
              onTap: () => context.go('/vehicles'),
            ),
          ),
          const SizedBox(width: 8),
          // Même ordre que la barre du bas : deux rangements différents pour
          // les mêmes trois destinations obligeraient à relire à chaque fois.
          Expanded(
            child: _BrowseTile(
              icon: Icons.tune_outlined,
              label: 'Accessoires',
              onTap: () => context.go('/accessories'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BrowseTile(
              icon: Icons.settings_outlined,
              label: 'Pièces',
              onTap: () => context.go('/parts'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BrowseTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, size: 22, color: cs.primary),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Besoin non couvert ────────────────────────────────────────────────

class _NeedPrompt extends ConsumerWidget {
  const _NeedPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Le personnel traite les besoins, il ne les soumet pas.
    if (ref.watch(authProvider).isStaff) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Center(
        child: TextButton.icon(
          onPressed: () => context.push('/needs/new'),
          icon: const Icon(Icons.help_outline, size: 18),
          label: const Text('Vous ne trouvez pas ? Dites-nous ce que vous cherchez'),
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12.5),
          ),
        ),
      ),
    );
  }
}

// ── Communs ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  final VoidCallback? onSeeAll;

  const _SectionTitle(this.label, {this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12.5),
              ),
              child: const Text('Tout voir'),
            ),
        ],
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final double height;
  const _SectionSkeleton({required this.height});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────

/// Le garage renvoie le nom de la marque, pas son slug ; le logo se range sous
/// un nom de fichier normalisé.
String? _slug(String? brand) => brand
    ?.toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

String _fmtKm(int km) =>
    km.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');

IconData _iconFor(String kind) => switch (kind) {
      'technical_inspection' => Icons.fact_check_outlined,
      'insurance'            => Icons.shield_outlined,
      'service'              => Icons.oil_barrel_outlined,
      _                      => Icons.event_outlined,
    };

/// « Visite technique dans 21 jours », « Vidange dépassée de 300 km ».
String _libelle(VehicleDeadline d) {
  if (d.detail != null) return '${d.label} — ${d.detail}';

  final jours = d.daysLeft;
  if (jours == null) return d.label;

  if (d.overdue) {
    final depuis = jours.abs();
    return '${d.label} dépassée depuis $depuis jour${depuis > 1 ? 's' : ''}';
  }

  return switch (jours) {
    0 => '${d.label} expire aujourd\'hui',
    1 => '${d.label} expire demain',
    _ => '${d.label} dans $jours jours',
  };
}
