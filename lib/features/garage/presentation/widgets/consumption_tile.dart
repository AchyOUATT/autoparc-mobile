import '../garage_labels.dart';
import '../../../../core/l10n/consumption_labels.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/garage_repository.dart';
import '../../data/models/fuel_fill.dart';
import '../../data/models/motorisation.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';
import 'fuel_fill_dialog.dart';
import 'consumption_reference_details.dart';

/// Ce que cette voiture consomme — mesuré d'abord, homologué ensuite.
///
/// La tuile ne montrait que la cote constructeur. Elle répond maintenant avec
/// les passages à la pompe du véhicule lui-même, et relègue la cote au rang de
/// référence : les cycles d'homologation s'écartent de 20 à 30 % de la conduite
/// réelle, et davantage encore sur piste, à charge, climatisation allumée.
/// La cote reste affichée parce qu'elle situe — elle ne répond plus seule.
///
/// Quatre états, et chacun a son propriétaire :
///   — un chiffre mesuré existe : c'est lui en premier ;
///   — des passages, mais aucun intervalle retenu — le cas de celui qui
///     n'achète que pour un montant : on montre ce qu'il a dépensé et roulé,
///     sans jamais appeler cela une moyenne ;
///   — aucun passage : l'invitation ;
///   — consommation anormale : dit en premier, avec de quoi agir.
///
/// Une mention se superpose à ces quatre états sans en être un : le compteur
/// remplacé, qui explique pourquoi le nombre d'intervalles a chuté d'un relevé
/// à l'autre.
class ConsumptionTile extends ConsumerWidget {
  final OwnedVehicle vehicle;

  const ConsumptionTile({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suivi = vehicle.fuelTracking;

    // Clé absente : le serveur n'est pas encore déployé. On s'en tient alors à
    // ce qu'il sait rendre, plutôt que de proposer une saisie qui finirait sur
    // une route inconnue.
    if (suivi == null) return _CoteSeule(vehicle: vehicle);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (suivi.abnormal) _Anomalie(vehicle: vehicle, suivi: suivi),
          if (suivi.aUnChiffre)
            _ChiffreMesure(vehicle: vehicle, suivi: suivi)
          else if (!suivi.vide)
            _FaitsBruts(suivi: suivi)
          else
            _Invitation(vehicle: vehicle),
          if (suivi.seriesRompue) const _SerieRompue(),
          _CoteReference(vehicle: vehicle),
          _Actions(vehicle: vehicle, suivi: suivi),
        ],
      ),
    );
  }
}

/// Le chiffre réel, celui de la piste.
class _ChiffreMesure extends StatelessWidget {
  final OwnedVehicle vehicle;
  final FuelTracking suivi;

  const _ChiffreMesure({required this.vehicle, required this.suivi});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textes = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.local_gas_station, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).garageMeasuredConsumptionValue(
                  (_nombre(context, suivi.l100km!)).toString(),
                ),
                style: textes.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              Text(
                [
                  if (suivi.fcfa100km != null)
                    AppLocalizations.of(context).garageFuelCostValue(
                      (_entier(context, suivi.fcfa100km!)).toString(),
                    ),
                  // Sur combien de pleins repose le chiffre : à deux pleins il
                  // bouge encore beaucoup, à cinq il est posé. Le cacher
                  // laisserait croire à la même certitude dans les deux cas.
                  AppLocalizations.of(
                    context,
                  ).garageConsumptionMeasuredOn(suivi.basedOnFills),
                ].join(' · '),
                style: textes.bodySmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Des passages, aucun intervalle : ce qui a été dépensé et roulé, et rien de
/// plus.
///
/// Aucun taux n'est calculé sur ces totaux, et c'est volontaire : le niveau du
/// réservoir au premier et au dernier passage n'est pas le même, l'écart est
/// borné par une capacité que nous ne connaissons pas, et le taux serait faux
/// d'autant. On montre les faits, on nomme ce qui manque.
class _FaitsBruts extends StatelessWidget {
  final FuelTracking suivi;

  const _FaitsBruts({required this.suivi});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textes = Theme.of(context).textTheme;
    final t = suivi.totals;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.local_gas_station_outlined, size: 18, color: cs.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  AppLocalizations.of(
                    context,
                  ).garageLitresValue((_nombre(context, t.litres)).toString()),
                  if (t.amountFcfa > 0)
                    AppLocalizations.of(context).garageCurrencyValue(
                      (_entier(context, t.amountFcfa.toDouble())).toString(),
                    ),
                  AppLocalizations.of(context).garageMileageValue(
                    (_entier(context, t.distanceKm.toDouble())).toString(),
                  ),
                ].join(' · '),
                style: textes.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context).garageSinceFirstRefill,
                style: textes.bodySmall?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: 2),
              Text(
                suivi.fullFills == 0
                    ? AppLocalizations.of(context).garageNeedTwoFullRefills
                    : AppLocalizations.of(context).garageNeedOneFullRefill,
                style: textes.bodySmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ce que voit un propriétaire qui n'a jamais rien enregistré.
class _Invitation extends StatelessWidget {
  final OwnedVehicle vehicle;

  const _Invitation({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.local_gas_station_outlined, size: 18, color: cs.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).garageTrackConsumptionAction,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                AppLocalizations.of(context).garageTrackConsumptionBody,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// La surconsommation, dite visiblement et suivie de quoi faire.
///
/// Une hausse durable se traite par un contrôle — filtre à air encrassé,
/// pression des pneus — et mène au catalogue de pièces. C'est la raison d'être
/// de l'alerte : un chiffre qui ne débouche sur rien n'est qu'une inquiétude.
class _Anomalie extends StatelessWidget {
  final OwnedVehicle vehicle;
  final FuelTracking suivi;

  const _Anomalie({required this.vehicle, required this.suivi});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textes = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.trending_up, size: 18, color: cs.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                // Le chiffre cité est celui du VERDICT — `alerte_l_100km`, la
                // somme sur somme des deux derniers intervalles — et non
                // `l_100km`, qui porte les cinq derniers. Les deux grandeurs
                // étaient opposées ici, et sur la série 8 8 8 8 3,1 3,1 11 11
                // cela donnait « 7,2 l/100 km contre 8,0 d'habitude » sous le
                // titre « Votre consommation a augmenté » : l'encart annonçait
                // une baisse en criant à la hausse. Il faut les deux clés pour
                // une phrase chiffrée ; sans l'une d'elles on dit la hausse
                // sans l'illustrer, plutôt que de l'illustrer de travers.
                child: Text(
                  (suivi.baselineL100km == null || suivi.alerteL100km == null)
                      ? AppLocalizations.of(context).garageConsumptionIncreased
                      : AppLocalizations.of(
                          context,
                        ).garageConsumptionIncreasedCompared(
                          (_nombre(context, suivi.alerteL100km!)).toString(),
                          (_nombre(context, suivi.baselineL100km!)).toString(),
                        ),
                  style: textes.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).garageConsumptionCommonCauses,
            style: textes.bodySmall?.copyWith(color: cs.onErrorContainer),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  context.push('/garage/${vehicle.id}/parts', extra: vehicle),
              style: TextButton.styleFrom(
                foregroundColor: cs.onErrorContainer,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(AppLocalizations.of(context).garageViewPartsAction),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le compteur remplacé, dit en une ligne.
///
/// Sans elle, le propriétaire voit ses chiffres fondre sans explication : 7
/// pleins à 11,0 l/100 km depuis 200 000 km, puis compteur neuf et 4 pleins
/// réels à 7,0 depuis 1 800 km. Le serveur coupe la chaîne en séries et ne
/// calcule que la plus récente — « mesuré sur 3 intervalles » là où la tuile
/// en annonçait 9 la veille, et un historique qui porte toujours onze lignes.
/// L'écart entre les deux nombres n'a aucune lecture possible sauf celle-ci :
/// des saisies perdues.
///
/// On ne propose rien à faire, parce qu'il n'y a rien à faire : l'histoire
/// d'avant est intacte en base, elle ne se compare simplement plus à celle
/// d'après.
class _SerieRompue extends StatelessWidget {
  const _SerieRompue();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.restart_alt, size: 14, color: cs.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppLocalizations.of(context).garageOdometerReplacedExplanation,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ),
        ],
      ),
    );
  }
}

/// La référence choisie, distincte de la consommation mesurée.
class _CoteReference extends ConsumerWidget {
  final OwnedVehicle vehicle;

  const _CoteReference({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = vehicle.consumption;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 4),
      child: reference == null
          ? TextButton(
              onPressed: () => choisirMotorisation(context, ref, vehicle),
              child: Text(l10n.garageConsumptionChoose),
            )
          : ConsumptionReferenceSummary(
              reference: reference,
              vehicleYear: vehicle.year,
              onChange: () => choisirMotorisation(context, ref, vehicle),
            ),
    );
  }
}

/// Enregistrer un passage, et consulter l'historique.
///
/// L'historique n'apparaît qu'une fois qu'il y a quelque chose dedans : un
/// écran vide atteint par un bouton toujours présent se lit comme une panne.
class _Actions extends ConsumerWidget {
  final OwnedVehicle vehicle;
  final FuelTracking suivi;

  const _Actions({required this.vehicle, required this.suivi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, top: 2),
      // Wrap et non Row : à 320 points de large et au texte agrandi, les deux
      // libellés ne tiennent pas sur une ligne. Un débordement mesuré ici,
      // dans le test de densité du projet.
      child: Wrap(
        children: [
          TextButton.icon(
            onPressed: () => _enregistrer(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context).garageRecordRefillTitle),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (!suivi.vide)
            TextButton(
              onPressed: () =>
                  context.push('/garage/${vehicle.id}/fuel', extra: vehicle),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(
                  context,
                ).garageRefillHistoryCount((suivi.totalFills).toString()),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _enregistrer(BuildContext context, WidgetRef ref) async {
    final enregistre = await showFuelFillDialog(context, vehicle);

    if (!enregistre || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).garageRefillSaved)),
    );
  }
}

/// Sans suivi des pleins, la même qualification prudente s'applique.
class _CoteSeule extends ConsumerWidget {
  final OwnedVehicle vehicle;

  const _CoteSeule({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vehicle.consumption == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => choisirMotorisation(context, ref, vehicle),
          icon: const Icon(Icons.local_gas_station_outlined, size: 18),
          label: Text(AppLocalizations.of(context).garageConsumptionQuestion),
        ),
      );
    }
    return _CoteReference(vehicle: vehicle);
  }
}

/// Le propriétaire sélectionne une référence ; cela ne la vérifie pas.
Future<void> choisirMotorisation(
  BuildContext context,
  WidgetRef ref,
  OwnedVehicle vehicle,
) async {
  final l10n = AppLocalizations.of(context);
  // Les cotes de consommation sont indexées par modèle du catalogue : sans
  // lui, aucune source ne peut être interrogée. On le dit, plutôt que de
  // laisser partir une requête sans identifiant.
  final modelId = vehicle.vehicleModelId;

  if (modelId == null) {
    _dire(context, l10n.garageConsumptionMissingModel, erreur: false);
    return;
  }

  List<Motorisation> options;

  try {
    options = await ref
        .read(garageRepositoryProvider)
        .motorisations(
          vehicleModelId: modelId,
          year: vehicle.year,
          engineTypeId: vehicle.engineTypeId,
          drivetrainId: vehicle.drivetrainId,
          trimId: vehicle.trimId,
          engineCode: vehicle.engineCode,
        );
  } catch (_) {
    if (!context.mounted) return;
    _dire(context, l10n.garageConsumptionCandidatesUnavailable, erreur: true);
    return;
  }

  if (!context.mounted) return;

  if (options.isEmpty) {
    // Une liste vide ne permet pas de conclure à une absence mondiale de
    // données : le catalogue courant ne propose simplement aucun candidat.
    _dire(context, l10n.garageConsumptionNoCandidates, erreur: false);
    return;
  }

  final choix = await showDialog<Motorisation>(
    context: context,
    builder: (ctx) => _DialogueMotorisation(vehicle: vehicle, options: options),
  );

  if (choix == null || !context.mounted) return;

  final erreur = await ref.read(garageProvider.notifier).updateVehicle(
    vehicle.id,
    {'motorisation_id': choix.id},
  );

  if (!context.mounted) return;

  _dire(context, erreur ?? l10n.garageConsumptionSaved, erreur: erreur != null);
}

class _DialogueMotorisation extends StatelessWidget {
  final OwnedVehicle vehicle;
  final List<Motorisation> options;

  const _DialogueMotorisation({required this.vehicle, required this.options});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        l10n.garageConsumptionVersionTitle(
          vehicle.identity.model ?? vehicle.designation,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.garageConsumptionChooseInstruction,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final m = options[i];
                  final reference = m.consumption;
                  final mixte = reference.sourceCombinedL100km;

                  final choisie = m.id == vehicle.motorisationId;

                  return ListTile(
                    onTap: () => Navigator.pop(context, m),
                    title: Text(
                      [
                        if (reference.sourceModel?.isNotEmpty == true)
                          reference.sourceModel!,
                        consumptionEngineLabel(
                          m.label,
                          l10n,
                          engineL: m.engineL,
                          cylinders: m.cylinders,
                          transmissionCode: m.transmissionCode,
                        ),
                        if (reference.powerKw != null)
                          '${reference.powerKw} kW',
                      ].join(' · '),
                    ),
                    subtitle: Text(
                      [
                        consumptionMatchLabel(l10n, reference),
                        l10n.garageConsumptionVehicleYear(vehicle.year),
                        consumptionYearLabel(l10n, reference),
                        reference.market?.isNotEmpty == true
                            ? l10n.garageConsumptionMarket(reference.market!)
                            : l10n.garageConsumptionMarketUnknown,
                        if (m.fuel != null)
                          consumptionFuelLabel(m.fuel!, l10n, code: m.fuelCode),
                        if (mixte != null)
                          l10n.garageConsumptionSourceValue(
                            _nombre(context, mixte),
                          ),
                        if (reference.source.isNotEmpty)
                          consumptionSourceLabel(
                            reference.source,
                            l10n,
                            code: reference.sourceCode,
                          ),
                        if (reference.cycle.isNotEmpty)
                          consumptionCycleLabel(
                            reference.cycle,
                            l10n,
                            code: reference.cycleCode,
                          ),
                      ].join(' · '),
                    ),
                    trailing: IconButton(
                      tooltip: l10n.garageConsumptionDetails,
                      onPressed: () => showConsumptionReferenceDetails(
                        context,
                        reference,
                        vehicleYear: vehicle.year,
                      ),
                      icon: Icon(
                        choisie
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: choisie ? cs.primary : null,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

/// « 8,2 » et non « 8.2 » : la virgule décimale est celle du français.
String _nombre(BuildContext context, double valeur) =>
    garageDecimal(AppLocalizations.of(context), valeur);

/// « 6 800 » : l'espace insécable sépare les milliers, sinon « 133000 FCFA »
/// se lit de travers sur un écran de téléphone.
String _entier(BuildContext context, double valeur) =>
    garageInteger(AppLocalizations.of(context), valeur);

void _dire(BuildContext context, String message, {required bool erreur}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: erreur ? Theme.of(context).colorScheme.error : null,
    ),
  );
}
