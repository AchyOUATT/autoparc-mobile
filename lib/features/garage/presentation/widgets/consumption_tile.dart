import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/garage_repository.dart';
import '../../data/models/fuel_fill.dart';
import '../../data/models/motorisation.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';
import 'fuel_fill_dialog.dart';

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
                '${_nombre(suivi.l100km!)} l/100 km',
                style: textes.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              Text(
                [
                  if (suivi.fcfa100km != null)
                    '${_entier(suivi.fcfa100km!)} FCFA/100 km',
                  // Sur combien de pleins repose le chiffre : à deux pleins il
                  // bouge encore beaucoup, à cinq il est posé. Le cacher
                  // laisserait croire à la même certitude dans les deux cas.
                  'mesuré sur ${suivi.basedOnFills} '
                      '${suivi.basedOnFills > 1 ? 'intervalles' : 'intervalle'}',
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
                  '${_nombre(t.litres)} l',
                  if (t.amountFcfa > 0) '${_entier(t.amountFcfa.toDouble())} FCFA',
                  '${_entier(t.distanceKm.toDouble())} km',
                ].join(' · '),
                style: textes.bodyMedium,
              ),
              Text(
                'depuis votre premier passage',
                style: textes.bodySmall?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: 2),
              Text(
                suivi.fullFills == 0
                    ? 'Deux pleins — pompe arrêtée toute seule — et votre '
                        'consommation réelle s\'affiche ici.'
                    : 'Encore un plein et votre consommation réelle s\'affiche '
                        'ici.',
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
                'Suivre ma consommation',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Enregistrez vos passages à la pompe : l\'application calcule '
                'ce que vous consommez vraiment.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.outline),
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
                      ? 'Votre consommation a augmenté.'
                      : 'Votre consommation a augmenté : '
                          '${_nombre(suivi.alerteL100km!)} l/100 km contre '
                          '${_nombre(suivi.baselineL100km!)} d\'habitude.',
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
            'Filtre à air encrassé, pression des pneus : ce sont les deux '
            'causes les plus courantes.',
            style: textes.bodySmall?.copyWith(color: cs.onErrorContainer),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push(
                '/garage/${vehicle.id}/parts',
                extra: vehicle,
              ),
              style: TextButton.styleFrom(
                foregroundColor: cs.onErrorContainer,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Voir les pièces'),
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
              'Compteur remplacé : les passages d\'avant restent dans votre '
              'historique, mais n\'entrent plus dans ce calcul.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ),
        ],
      ),
    );
  }
}

/// La cote d'homologation, en second et comme repère.
///
/// Elle ne disparaît pas avec le chiffre mesuré : elle dit ce que la voiture
/// devrait faire en laboratoire, et l'écart entre les deux est une information
/// en soi. Le choix de motorisation reste accessible d'ici — il a cessé d'être
/// la seule réponse à la question, pas d'être utile.
class _CoteReference extends ConsumerWidget {
  final OwnedVehicle vehicle;

  const _CoteReference({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textes = Theme.of(context).textTheme;
    final mixte = vehicle.consumption?.combinedL100km;

    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              mixte == null
                  ? 'Cote constructeur inconnue'
                  : 'Cote constructeur ${_nombre(mixte)} l/100 km',
              style: textes.bodySmall?.copyWith(color: cs.outline),
            ),
          ),
          TextButton(
            onPressed: () => choisirMotorisation(context, ref, vehicle),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(mixte == null ? 'Préciser' : 'Changer'),
          ),
        ],
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
            label: const Text('Passage à la pompe'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (!suivi.vide)
            TextButton(
              onPressed: () => context.push(
                '/garage/${vehicle.id}/fuel',
                extra: vehicle,
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Historique (${suivi.totalFills})'),
            ),
        ],
      ),
    );
  }

  Future<void> _enregistrer(BuildContext context, WidgetRef ref) async {
    final enregistre = await showFuelFillDialog(context, vehicle);

    if (!enregistre || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passage enregistré.')),
    );
  }
}

/// L'ancienne tuile, conservée pour un serveur qui ne rend pas encore
/// `fuel_tracking`.
class _CoteSeule extends ConsumerWidget {
  final OwnedVehicle vehicle;

  const _CoteSeule({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conso = vehicle.consumption;
    final cs = Theme.of(context).colorScheme;

    if (conso == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => choisirMotorisation(context, ref, vehicle),
          icon: const Icon(Icons.local_gas_station_outlined, size: 18),
          label: const Text('Quelle est ma consommation ?'),
        ),
      );
    }

    final mixte = conso.combinedL100km;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_gas_station_outlined, size: 18, color: cs.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mixte == null ? '—' : '${_nombre(mixte)} l/100 km',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (conso.cityL100km != null && conso.highwayL100km != null)
                  Text(
                    'ville ${_nombre(conso.cityL100km!)} · '
                    'route ${_nombre(conso.highwayL100km!)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => choisirMotorisation(context, ref, vehicle),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }
}

/// Demande sa motorisation au propriétaire, puis enregistre son choix.
///
/// On ne demande ni la finition ni la puissance : ce qui détermine la
/// consommation, c'est le moteur et la boîte. Une Camry 2013 existe en 2,5 l
/// quatre cylindres et en 3,5 l V6 — 8,2 contre 9,4 l/100.
Future<void> choisirMotorisation(
  BuildContext context,
  WidgetRef ref,
  OwnedVehicle vehicle,
) async {
  // Les cotes de consommation sont indexées par modèle du catalogue : sans
  // lui, aucune source ne peut être interrogée. On le dit, plutôt que de
  // laisser partir une requête sans identifiant.
  final modelId = vehicle.vehicleModelId;

  if (modelId == null) {
    _dire(
      context,
      'Consommation indisponible : le modèle de ce véhicule n\'est pas '
      'encore au catalogue.',
      erreur: false,
    );
    return;
  }

  List<Motorisation> options;

  try {
    options = await ref.read(garageRepositoryProvider).motorisations(
          vehicleModelId: modelId,
          year: vehicle.year,
        );
  } catch (_) {
    if (!context.mounted) return;
    _dire(context, 'Liste des motorisations indisponible. Réessayez plus tard.',
        erreur: true);
    return;
  }

  if (!context.mounted) return;

  if (options.isEmpty) {
    // Aucune source publique ne couvre ce modèle — Fortuner, Prado, D-Max et
    // les autres, vendus ni en Amérique du Nord ni en Europe. Le dire
    // franchement vaut mieux qu'une liste vide sans explication.
    _dire(
      context,
      'Aucune donnée officielle de consommation pour ce modèle.',
      erreur: false,
    );
    return;
  }

  final choix = await showDialog<Motorisation>(
    context: context,
    builder: (ctx) => _DialogueMotorisation(
      vehicle: vehicle,
      options: options,
    ),
  );

  if (choix == null || !context.mounted) return;

  final erreur = await ref
      .read(garageProvider.notifier)
      .updateVehicle(vehicle.id, {'motorisation_id': choix.id});

  if (!context.mounted) return;

  _dire(
    context,
    erreur ?? 'Motorisation enregistrée.',
    erreur: erreur != null,
  );
}

class _DialogueMotorisation extends StatelessWidget {
  final OwnedVehicle vehicle;
  final List<Motorisation> options;

  const _DialogueMotorisation({required this.vehicle, required this.options});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text('Motorisation de votre ${vehicle.identity.model ?? 'véhicule'}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisissez le moteur qui se trouve sous le capot. '
              'La finition ne change pas la consommation.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final m = options[i];
                  final mixte = m.consumption.combinedL100km;

                  final choisie = m.id == vehicle.motorisationId;

                  return ListTile(
                    onTap: () => Navigator.pop(context, m),
                    title: Text(m.label),
                    // Le cycle d'essai accompagne chaque ligne, pas seulement
                    // celle qui sera choisie : la liste melange des cotes
                    // canadiennes et europeennes, et 5,2 l/100 en WLTP ne se
                    // compare pas a 8,9 en cinq cycles. Sans cette mention,
                    // l'ecart passerait pour une difference de moteur.
                    subtitle: Text([
                      if (m.fuel != null) m.fuel!,
                      if (mixte != null) '${_nombre(mixte)} l/100 km',
                      if (m.consumption.cycle.isNotEmpty) m.consumption.cycle,
                    ].join(' · ')),
                    trailing: choisie
                        ? Icon(Icons.check, color: cs.primary)
                        : null,
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
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

/// « 8,2 » et non « 8.2 » : la virgule décimale est celle du français.
String _nombre(double valeur) =>
    valeur.toStringAsFixed(1).replaceAll('.', ',');

/// « 6 800 » : l'espace insécable sépare les milliers, sinon « 133000 FCFA »
/// se lit de travers sur un écran de téléphone.
String _entier(double valeur) {
  final chiffres = valeur.round().toString();
  final tampon = StringBuffer();

  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) tampon.write(' ');
    tampon.write(chiffres[i]);
  }

  return tampon.toString();
}

void _dire(BuildContext context, String message, {required bool erreur}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: erreur ? Theme.of(context).colorScheme.error : null,
    ),
  );
}
