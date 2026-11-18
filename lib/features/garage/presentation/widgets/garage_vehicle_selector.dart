import 'package:flutter/material.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/models/owned_vehicle.dart';

/// Le choix du véhicule affiché, quand le garage en compte plusieurs.
///
/// POURQUOI UN SÉLECTEUR ET NON DES CARTES EMPILÉES : la fiche complète d'un
/// véhicule occupe plus d'un écran de téléphone. Avec deux ou trois véhicules
/// empilés, le deuxième n'apparaissait qu'après avoir fait défiler toute la
/// fiche du premier — le propriétaire ne voyait même pas qu'il était là. Le
/// sélecteur les montre tous d'un coup d'œil, avec leur plaque, et n'affiche
/// en dessous que la fiche du véhicule choisi.
///
/// Une rangée qui défile horizontalement, comme sur l'accueil : au-delà de ce
/// qui tient à l'écran, le bord du véhicule suivant dépasse et dit qu'il y en
/// a d'autres. Un point rouge signale un véhicule dont une échéance approche
/// ou est dépassée, sans obliger à en faire le tour.
class GarageVehicleSelector extends StatefulWidget {
  final List<OwnedVehicle> vehicles;
  final int selectedId;
  final ValueChanged<OwnedVehicle> onSelected;

  const GarageVehicleSelector({
    super.key,
    required this.vehicles,
    required this.selectedId,
    required this.onSelected,
  });

  /// La largeur d'un véhicule de la rangée : assez pour un surnom et une
  /// plaque, et assez étroite pour que le suivant dépasse à 320 points.
  static double itemWidth(double textScale) => 160 * textScale.clamp(1.0, 1.2);

  @override
  State<GarageVehicleSelector> createState() => _GarageVehicleSelectorState();
}

class _GarageVehicleSelectorState extends State<GarageVehicleSelector> {
  final _cles = <int, GlobalKey>{};

  GlobalKey _cle(int id) => _cles.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    // Le véhicule affiché peut être le deuxième ou le troisième — le plus
    // urgent, ou celui choisi sur l'accueil. Il doit être VISIBLE dans la
    // rangée dès l'ouverture, sinon la fiche affichée ne correspond à aucun
    // véhicule qu'on voit.
    _montrerLeChoix(animer: false);
  }

  @override
  void didUpdateWidget(covariant GarageVehicleSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _montrerLeChoix(animer: true);
    }
  }

  void _montrerLeChoix({required bool animer}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexte = _cles[widget.selectedId]?.currentContext;
      if (contexte == null || !contexte.mounted) return;
      Scrollable.ensureVisible(
        contexte,
        alignment: 0.5,
        duration: animer ? const Duration(milliseconds: 250) : Duration.zero,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = widget.vehicles;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Semantics(
            header: true,
            child: Text(
              l10n.garageMyVehiclesCount(vehicles.length.toString()),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < vehicles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  SizedBox(
                    key: _cle(vehicles[i].id),
                    width: GarageVehicleSelector.itemWidth(scale),
                    child: _VehicleChoice(
                      vehicle: vehicles[i],
                      selected: vehicles[i].id == widget.selectedId,
                      onTap: () => widget.onSelected(vehicles[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleChoice extends StatelessWidget {
  final OwnedVehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleChoice({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final alerte = needsAttention(vehicle);
    final texte = selected ? cs.onPrimaryContainer : cs.onSurface;
    final secondaire = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    final detail =
        vehicle.plateNumber ??
        [
          vehicle.identity.model,
          vehicle.year.toString(),
        ].whereType<String>().join(' · ');

    return Semantics(
      button: true,
      selected: selected,
      label: [
        vehicle.displayName,
        detail,
        if (alerte) l10n.garageVehicleNeedsAttention,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        key: Key('garage-vehicle-choice-${vehicle.id}'),
        color: selected ? cs.primaryContainer : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: BrandLogo(
                        slug: vehicle.identity.brandSlug,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: texte,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaire,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (alerte) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.circle, size: 10, color: cs.error),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
