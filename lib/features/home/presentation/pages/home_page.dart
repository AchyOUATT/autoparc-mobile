import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/providers/shell_scaffold_provider.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/catalog_image.dart';
import '../../../../core/widgets/navigation_bar_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/data/models/part.dart';
import '../../../catalog/data/models/vehicle.dart';
import '../../../garage/data/models/owned_vehicle.dart';
import '../../../garage/presentation/providers/garage_provider.dart';
import '../../../garage/presentation/widgets/engine_prompt.dart';
import '../../../garage/presentation/widgets/mileage_dialog.dart';
import '../../../notifications/presentation/widgets/notification_icon_button.dart';
import '../providers/home_providers.dart';
import '../../../../l10n/app_localizations.dart';

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
          tooltip: AppLocalizations.of(context).commonMenuTooltip,
          onPressed: () =>
              ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: Text(AppLocalizations.of(context).commonHome),
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
                      // Le slug vient du serveur. Il était fabriqué ici à partir
                      // du nom, ce qui tenait tant qu'aucune marque n'avait
                      // d'accent : « Citroën » devenait « citro-n » et perdait
                      // son logo sans que rien ne le signale.
                      child: BrandLogo(slug: vehicle.identity.brandSlug, size: 26),
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
                        // Le compteur passe par le formateur de la locale
                        // active. Il était ponctué ici par une expression
                        // régulière et une espace ORDINAIRE U+0020, quand le
                        // catalogue employait l'espace fine insécable U+202F
                        // de `decimalPattern('fr_FR')` : le même kilométrage
                        // changeait de forme entre l'accueil et la fiche.
                        //
                        // LE FRANÇAIS A DONC BOUGÉ, AU RÉGLAGE PAR DÉFAUT, ET
                        // EN GÉOMÉTRIE. Ce n'est pas qu'un changement de
                        // caractère : U+202F est plus étroite que l'espace
                        // ordinaire. « 246 965 km » réclame 65,49 points avec
                        // la nouvelle ponctuation contre 66,97 avec
                        // l'ancienne, soit 1,49 point RENDU — et 1,93 au
                        // deuxième cran d'Android, 2,23 au troisième, 2,97 au
                        // dernier. Les quatre écarts sont identiques à 320,
                        // 360 et 411 points de large, parce que ce paragraphe
                        // n'est pas borné : il est posé nu dans la rangée,
                        // donc il prend sa largeur naturelle et c'est
                        // l'`Expanded` du surnom qui encaisse la différence.
                        // Celui-ci reçoit 154,51 points à 320, 194,51 à 360 et
                        // 245,51 à 411, au réglage par défaut.
                        //
                        // Le surnom s'ellipse par construction, donc 1,49
                        // point de plus ne se voit pas comme un gain ; il est
                        // écrit ici pour que personne ne découvre l'écart en
                        // cherchant autre chose. Le sens du changement est la
                        // COHÉRENCE : U+202F est la ponctuation française des
                        // milliers, et c'est déjà celle du reste de
                        // l'application.
                        AppLocalizations.of(context).commonMileageKm(
                          formatEntier(vehicle.mileageKm!),
                        ),
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
                            _libelle(AppLocalizations.of(context), d),
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
                  label: Text(AppLocalizations.of(context).homeUpdateMileage),
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
              _libelle(AppLocalizations.of(context), deadline),
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
                AppLocalizations.of(context).homeNoDeadlinePrompt,
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
                    AppLocalizations.of(context).homeGarageUnavailable,
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
            TextButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).commonRetry),
            ),
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
              AppLocalizations.of(context).homeAddVehicleTitle,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).homeAddVehicleBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => context.push('/garage/add'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: Text(AppLocalizations.of(context).homeAddVehicleCta),
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
    final l10n  = AppLocalizations.of(context);

    return parts.maybeWhen(
      // Une bande vide ou en erreur disparaît : mieux vaut rien qu'un cadre
      // creux au milieu de la page.
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  l10n.homeCompatiblePartsSection(
                    vehicle.identity.model ??
                        l10n.homeCompatiblePartsFallbackModel,
                  ),
                  onSeeAll: () => context.push('/garage/${vehicle.id}/parts',
                      extra: vehicle),
                ),
                // LA HAUTEUR VIENT DU CONTENU, et plus d'un nombre écrit ici.
                //
                // `SizedBox(height: 132)` DÉBORDAIT, dans dix-huit
                // configurations sur vingt-quatre. La bande réclame 142,00
                // points à l'échelle de texte 1,3, 152,00 à 1,5 et 174,00 à
                // 2,0, soit 10,0, 20,0 et 42,0 points de débordement — aux
                // trois largeurs d'écran du parc, et à l'identique dans les
                // deux langues. Flutter peignait sa bande rayée en travers du
                // prix de la pièce.
                //
                // LE CHIFFRE DE 2,0 ÉTAIT FAUX ICI, et il penchait du côté qui
                // justifiait le changement : ce commentaire annonçait 76
                // points de débordement. Remesuré sur la bande montée dans sa
                // coque, c'est 42,0 — 174,00 réclamés contre 132 posés. Le
                // relecteur avait raison, et les deux autres crans (10,0 et
                // 20,0) se reproduisent au centième.
                //
                // ET ELLE RÉTRÉCIT AU RÉGLAGE PAR DÉFAUT, ce qui n'était dit
                // nulle part : à l'échelle 1,0 le contenu ne réclame que
                // 127,00 points, donc `IntrinsicHeight` REND 5,0 points aux
                // sections du dessous, aux trois largeurs. Rien n'est coupé
                // pour autant — c'est le `SizedBox` qui était trop généreux à
                // ce cran-là, du même nombre écrit à la main qui débordait aux
                // trois autres.
                //
                // LE DÉFAUT EST ANTÉRIEUR À LA TRADUCTION, et il n'était pas
                // mesuré. Le seul banc qui montait l'accueil le montait avec
                // une session du PERSONNEL ; or le personnel n'a pas de
                // garage, `_MyVehicleSection` disparaît pour lui, et cette
                // bande n'existait donc dans aucun rendu de test. Elle a
                // surgi au premier banc monté en session CLIENT.
                //
                // C'est exactement le défaut que `_DealsSection` a corrigé un
                // lot plus tôt — son commentaire raconte le même
                // « ajusté au contenu réel » qui était faux —, et la
                // correction est la même, pour la même raison : la hauteur
                // juste dépend de la police, de la langue et du réglage
                // système, elle se mesure et ne se décide pas. Un `ListView`
                // est un viewport, il ne sait pas dire la hauteur de ce qu'il
                // contient, et c'est ce silence qui obligeait à l'écrire à la
                // main.
                //
                // Le coût d'`IntrinsicHeight` est une seconde passe de mise en
                // page, et il est borné : `homeCompatiblePartsProvider` fait
                // `parts.take(6)`.
                IntrinsicHeight(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _PartTile(part: list[i]),
                        ],
                      ],
                    ),
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
                    // LE PRIX RÉTRÉCIT, IL NE SE COUPE PAS, et c'est la
                    // décision déjà prise pour les cartes du catalogue :
                    // « un prix rendu plus petit reste VRAI, un prix coupé
                    // devient FAUX ».
                    //
                    // MESURE DU DÉFAUT. La tuile fait 118 points de large en
                    // dur, soit 102,0 de texte. À l'échelle de texte 2,0,
                    // « 3 000 FCFA » en réclame 106,0 et « 3,000 FCFA » —
                    // l'anglais, dont la virgule est plus large que l'espace
                    // fine insécable — 108,9. Or un prix est un seul segment
                    // INSÉCABLE : U+202F comme U+00A0 interdisent la coupure,
                    // et c'est voulu, un prix cassé en deux lignes étant
                    // illisible. Le paragraphe ne se déclare donc pas tronqué
                    // — `didExceedMaxLines` reste faux — et les derniers
                    // glyphes sortaient de la tuile pour être rognés SANS
                    // ELLIPSE, donc sans qu'aucun signe n'avertisse que le
                    // nombre lu n'est pas le prix.
                    //
                    // Le défaut existait avant la traduction, aux trois
                    // largeurs d'écran ; l'anglais l'aggrave de 2,9 points.
                    //
                    // `BoxFit.scaleDown` ne réduit que lorsqu'il faut : au
                    // réglage par défaut le prix ne réclame que 62,5 points
                    // sur les 102,0 disponibles, et n'est pas touché. Ce n'est
                    // qu'à partir du moment où il dépasse qu'il rétrécit, et
                    // jamais plus qu'il ne faut.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatXof(part.pricing.sellingPrice),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
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
                  AppLocalizations.of(context).homeDealsSection,
                  onSeeAll: () => context.go('/vehicles'),
                ),
                // La hauteur vient du contenu, et plus d'un nombre écrit ici.
                //
                // `SizedBox(height: 152)` portait le commentaire « ajusté au
                // contenu réel » : c'était faux, et c'est l'écran que tout le
                // monde voit à chaque ouverture. Mesuré avec un seul véhicule
                // en vitrine, la tuile réclame 178 points à l'échelle de texte
                // 1,0 et 217 à 1,3 — soit 26 et 65 de débordement, dès le
                // premier rendu, identiques à 320, 360 et 411 points de large
                // et indépendants de la photo. Flutter peint alors sa bande
                // rayée en travers du prix.
                //
                // L'écart entre les deux échelles dit pourquoi aucun nombre ne
                // tiendrait : il ne s'agit pas de choisir 178 plutôt que 152.
                // La ville et le prix passent sur deux lignes quand les
                // caractères grossissent, et la hauteur juste dépend donc de la
                // police, de la langue et du réglage système. Elle se mesure,
                // elle ne se décide pas.
                //
                // D'où `IntrinsicHeight` sur un `Row` défilant, et non un
                // `ListView` : un ListView est un viewport, il ne sait pas dire
                // la hauteur de ce qu'il contient, et c'est bien ce silence qui
                // obligeait à l'écrire à la main. `CrossAxisAlignment.stretch`
                // garde ce que la hauteur fixe donnait gratuitement — des
                // tuiles de même hauteur, alignées.
                //
                // Le coût d'`IntrinsicHeight` est une seconde passe de mise en
                // page, et il est borné : `homeDealsProvider` demande
                // `perPage: 6`. Construire six tuiles d'un coup au lieu de les
                // bâtir à la demande ne se discute pas à cette taille.
                IntrinsicHeight(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _DealTile(vehicle: list[i]),
                        ],
                      ],
                    ),
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
                    // Voir la carte de la grille du catalogue : `coverUrl`
                    // dit qu'on ne veut qu'une image, là où `.first` laissait
                    // croire que l'ordre de `mediaUrls` était indifférent.
                    if (vehicle.coverUrl == null)
                      couverture
                    else
                      CatalogImage(
                        url: vehicle.coverUrl!,
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
                    // MÊME DÉCISION QUE LA TUILE DE PIÈCE, ET MÊME MESURE.
                    // La tuile fait 168 points de large, soit 150,0 de texte.
                    // À l'échelle 2,0, « 99,999,999 FCFA » — huit chiffres,
                    // la borne du catalogue — réclame 178,1 points en un seul
                    // segment insécable : il ne peut donc pas se replier, le
                    // paragraphe ne se déclare pas tronqué, et les derniers
                    // glyphes sortaient de la tuile pour être rognés SANS
                    // ELLIPSE — donc sans qu'aucun signe n'avertisse que le
                    // nombre lu n'est pas le prix. Un prix coupé devient FAUX ;
                    // réduit, il reste VRAI.
                    //
                    // Au réglage par défaut rien ne change : le même prix à
                    // huit chiffres ne réclame que 96,5 points sur les 150,0
                    // disponibles.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        c.salePrice != null
                            ? formatXof(c.salePrice)
                            : '${formatXof(c.rentalDailyRate)}'
                                  '${AppLocalizations.of(context).commonPerDaySuffix}',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
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
      // LA MÊME BORNE D'ÉCHELLE QUE LA BARRE DU BAS, et la même constante —
      // voir `echelleMaxLibellesDestinations`.
      //
      // LE DÉFAUT MESURÉ. Les trois tuiles se partagent la rangée à parts
      // égales : 93,3 points chacune à 320 points d'écran, 106,7 à 360, et
      // cette largeur ne dépend pas du réglage de texte. À l'échelle 2,0,
      // « Accessoires » réclame 120,9 points et « Accessories » 121,1 — en un
      // seul mot, donc en un seul segment INSÉCABLE. Un mot plus large que sa
      // ligne est posé seul et déborde horizontalement sans que le paragraphe
      // se déclare tronqué : `didExceedMaxLines` restait faux, et les derniers
      // glyphes étaient rognés EN SILENCE. Le défaut est antérieur à la
      // traduction et presque identique dans les deux langues — l'anglais y
      // perd 0,2 point de plus.
      //
      // Sous la borne, le même mot ne demande plus que 77,9 points pour les
      // 93,3 reçus — exactement la largeur qu'il demande dans la barre du bas,
      // puisque c'est la même borne et le même corps 12. Il tient donc aux
      // trois largeurs, avec de la marge. Le compromis est celui qui était
      // déjà assumé pour la barre du bas : quelqu'un qui a grossi ses polices
      // lit ces trois intitulés plus petits qu'il ne l'a demandé, et les lit
      // ENTIERS. Les icônes, elles, ne sont pas touchées — elles tirent leur
      // taille du thème.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: echelleMaxLibellesDestinations,
        child: Row(
        children: [
          Expanded(
            child: _BrowseTile(
              icon: Icons.directions_car_outlined,
              label: AppLocalizations.of(context).commonVehicles,
              onTap: () => context.go('/vehicles'),
            ),
          ),
          const SizedBox(width: 8),
          // Même ordre que la barre du bas : deux rangements différents pour
          // les mêmes trois destinations obligeraient à relire à chaque fois.
          Expanded(
            child: _BrowseTile(
              icon: Icons.tune_outlined,
              label: AppLocalizations.of(context).commonAccessories,
              onTap: () => context.go('/accessories'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BrowseTile(
              icon: Icons.settings_outlined,
              label: AppLocalizations.of(context).commonParts,
              onTap: () => context.go('/parts'),
            ),
          ),
        ],
        ),
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
          label: Text(AppLocalizations.of(context).homeNeedPrompt),
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
              child: Text(AppLocalizations.of(context).homeSeeAll),
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

IconData _iconFor(String kind) => switch (kind) {
      'technical_inspection' => Icons.fact_check_outlined,
      'insurance'            => Icons.shield_outlined,
      'service'              => Icons.oil_barrel_outlined,
      _                      => Icons.event_outlined,
    };

/// « Visite technique dans 21 jours », « Roadworthiness test in 21 days ».
///
/// LE LIBELLÉ ET LE DÉTAIL VIENNENT DU SERVEUR et ne sont pas traduits par ce
/// lot : `label` vaut « Visite technique », « Assurance », « Vidange », et
/// `detail` vaut « dépassée de 300 km ». En anglais, cette fonction rend donc
/// « Assurance expires today » — la phrase est traduite, le nom de l'échéance
/// non. C'est l'état attendu jusqu'à la vague serveur, et c'est écrit ici plutôt
/// que découvert sur une capture d'écran.
///
/// Le pluriel passe par ICU plutôt que par un `depuis > 1 ? 's' : ''` : la règle
/// n'est pas la même dans les deux langues — le français écrit « 0 jour » au
/// singulier, l'anglais « 0 days » au pluriel — et un ternaire sur la place du
/// « s » ne sait pas le dire.
String _libelle(AppLocalizations l10n, VehicleDeadline d) {
  if (d.detail != null) return l10n.homeDeadlineDetail(d.label, d.detail!);

  final jours = d.daysLeft;
  if (jours == null) return d.label;

  if (d.overdue) return l10n.homeDeadlineOverdue(d.label, jours.abs());

  return switch (jours) {
    0 => l10n.homeDeadlineToday(d.label),
    1 => l10n.homeDeadlineTomorrow(d.label),
    _ => l10n.homeDeadlineInDays(d.label, jours),
  };
}
