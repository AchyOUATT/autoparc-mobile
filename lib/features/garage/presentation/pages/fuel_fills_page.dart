import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/models/fuel_fill.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/fuel_fills_provider.dart';
import '../providers/garage_provider.dart';
import '../widgets/fuel_fill_dialog.dart';

/// L'historique des passages à la pompe — et surtout, de quoi le corriger.
///
/// C'est la raison d'être de l'écran. Une faute de frappe sur le compteur ne
/// gâche pas une ligne, elle en gâche deux : l'intervalle qui finit sur elle et
/// celui qui en part. Tant qu'elle reste, le chiffre affiché est faux ; une
/// fois la ligne supprimée, le serveur rechaîne les pleins et la moyenne
/// redevient juste. C'est pourquoi la table ne porte pas de suppression douce,
/// contrairement aux véhicules.
///
/// Chaque ligne dit aussi ce que son intervalle a donné — ou, en clair, la
/// raison pour laquelle il a été écarté. Un intervalle qui disparaît sans
/// motif visible passe pour un défaut de l'application, et le propriétaire
/// cesse de saisir.
class FuelFillsPage extends ConsumerWidget {
  final int ownedVehicleId;

  /// Nul après un lien profond ou un rechargement à chaud : la page doit
  /// fonctionner sans, comme l'écran des pièces compatibles.
  final OwnedVehicle? vehicle;

  const FuelFillsPage({
    super.key,
    required this.ownedVehicleId,
    this.vehicle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passages = ref.watch(fuelFillsProvider(ownedVehicleId));

    // Le véhicule du garage l'emporte sur celui passé en `extra` : il porte le
    // kilométrage relevé au dernier passage, que la boîte de saisie
    // pré-remplit. Celui de `extra` a été capturé à l'ouverture de la page et
    // vieillit dès le premier enregistrement.
    final courant = (ref.watch(garageProvider).valueOrNull ?? const <OwnedVehicle>[])
            .where((v) => v.id == ownedVehicleId)
            .cast<OwnedVehicle?>()
            .firstOrNull ??
        vehicle;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          courant == null
              ? 'Passages à la pompe'
              : 'Carburant — ${courant.displayName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
      ),
      floatingActionButton: courant == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _enregistrer(context, courant),
              icon: const Icon(Icons.add),
              label: const Text('Passage'),
            ),
      body: passages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Erreur(
          message: messageFor(e),
          onRetry: () =>
              ref.read(fuelFillsProvider(ownedVehicleId).notifier).refresh(),
        ),
        data: (liste) {
          if (liste.isEmpty) return const _Vide();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(fuelFillsProvider(ownedVehicleId).notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              // Tel quel, sans retourner la liste : l'index rend DÉJÀ le
              // compteur le plus haut en premier — `reorder()` puis
              // `orderByDesc('mileage_km')`, `orderByDesc('id')`. Le code
              // précédent lisait `liste[liste.length - 1 - i]` en croyant
              // l'ordre croissant, et remontait donc la liste du plus ancien
              // au plus récent : sur la fixture du contrat — 96 000, 95 400,
              // 95 100, 94 800 km — le passage que le propriétaire vient de
              // saisir, et qu'il ouvre cet écran pour corriger, arrivait en
              // quatrième position. Les deux jeux de test qui couvraient
              // l'écran étaient posés en ordre croissant, donc l'inversion y
              // produisait par hasard le bon affichage.
              itemCount: liste.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _LignePassage(
                passage: liste[i],
                ownedVehicleId: ownedVehicleId,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _enregistrer(BuildContext context, OwnedVehicle v) async {
    final enregistre = await showFuelFillDialog(context, v);

    if (!enregistre || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passage enregistré.')),
    );
  }
}

class _LignePassage extends ConsumerWidget {
  final FuelFill passage;
  final int ownedVehicleId;

  const _LignePassage({required this.passage, required this.ownedVehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textes = Theme.of(context).textTheme;

    return ListTile(
      leading: Tooltip(
        message: passage.isFull
            ? 'Plein — la pompe s\'est arrêtée toute seule'
            : 'Demi-plein',
        child: Icon(
          passage.isFull
              ? Icons.local_gas_station
              : Icons.local_gas_station_outlined,
          color: passage.isFull ? cs.primary : cs.outline,
        ),
      ),
      title: Text(
        '${_entier(passage.mileageKm)} km · ${_nombre(passage.litres)} l'
        '${passage.amountFcfa == null ? '' : ' · ${_entier(passage.amountFcfa!)} FCFA'}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              passage.isFull ? 'Plein' : 'Demi-plein',
              if (passage.filledAt != null) _jour(passage.filledAt!),
            ].join(' · '),
            style: textes.bodySmall?.copyWith(color: cs.outline),
          ),
          // Le résultat de l'intervalle qui finit ici, ou la raison nommée de
          // son écart. Un demi-plein n'en porte aucun des deux : il apporte ses
          // litres au calcul mais ne borne jamais un intervalle.
          if (passage.l100km != null)
            Text(
              '${_nombre(passage.l100km!)} l/100 km'
              '${passage.distanceKm == null ? '' : ' sur ${_entier(passage.distanceKm!.round())} km'}'
              '${passage.retenu ? '' : ' — écarté'}',
              style: textes.bodySmall?.copyWith(
                color: passage.retenu ? cs.primary : cs.outline,
                fontWeight: passage.retenu ? FontWeight.bold : null,
              ),
            ),
          if (passage.motifLibelle != null)
            Text(
              passage.motifLibelle!,
              style: textes.bodySmall?.copyWith(color: cs.error),
            ),
        ],
      ),
      isThreeLine: passage.motifLibelle != null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Supprimer ce passage',
        onPressed: () => _supprimer(context, ref),
      ),
    );
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce passage ?'),
        // On annonce l'effet réel : la suppression ne retire pas une ligne
        // d'une liste, elle détruit des mesures et change le chiffre affiché
        // sur la fiche.
        content: Text(_effetDeLaSuppression(passage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    final erreur = await ref
        .read(fuelFillsProvider(ownedVehicleId).notifier)
        .deleteFill(passage.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erreur ?? 'Passage supprimé.'),
        backgroundColor:
            erreur == null ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Ce que la suppression va détruire, dit avant de la faire.
///
/// Le texte générique d'avant — « les litres sortiront du calcul » — était
/// juste et inoffensif pour une saisie fautive, qui est le cas prévu de cet
/// écran. Il l'était beaucoup moins pour un passage CORRECT, qui borne deux
/// intervalles : le supprimer ne retranche pas une mesure, il en fusionne
/// deux. Mesure de la revue — 90 000/40 L, 90 600/48 L, 91 200/50 L affichent
/// 8,2 l/100 km ; en supprimant celui du milieu, les 98 L restants s'étalent
/// sur les 1 200 km du seul intervalle survivant et l'écran passe à 4,2,
/// présenté comme une mesure valide. Un chiffre divisé par deux sans qu'une
/// seule phrase l'ait annoncé.
///
/// [FuelFill.bornesIntervalles] vient du serveur, seul à chaîner les pleins :
/// deviner ici depuis la ligne seule reviendrait à recopier la chaîne.
String _effetDeLaSuppression(FuelFill passage) => switch (passage.bornesIntervalles) {
      // Un plein au milieu de la série : il ferme un intervalle retenu et en
      // ouvre un autre. Les deux chiffres disparaissent, un seul les remplace.
      >= 2 => 'Ce passage ferme une mesure et en ouvre une autre. En le '
          'supprimant, ces deux mesures disparaissent et leurs intervalles '
          'n\'en font plus qu\'un, deux fois plus long : votre consommation '
          'sera recalculée dessus, et elle peut changer beaucoup.',
      // Le dernier plein de la série, ou le premier : une seule mesure tombe.
      1 => 'Ce passage ferme une des mesures retenues. En le supprimant, '
          'cette mesure disparaît et votre consommation sera recalculée.',
      // Un demi-plein, ou un plein dont l'intervalle est écarté : il n'apporte
      // que ses litres, et aucun chiffre affiché ne s'effondre.
      _ => 'Les litres de ce passage sortiront du calcul et votre '
          'consommation sera recalculée.',
    };

/// L'état vide dit à quoi sert l'écran, et pas seulement qu'il est vide.
class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_gas_station_outlined, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              'Aucun passage enregistré',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Notez ce que vous mettez à la pompe : le montant et le prix au '
              'litre suffisent. Après deux pleins, l\'application vous dit ce '
              'que votre véhicule consomme vraiment, et vous prévient le jour '
              'où ça monte.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Erreur extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _Erreur({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// « 8,2 » et non « 8.2 ».
String _nombre(double valeur) =>
    valeur.toStringAsFixed(1).replaceAll('.', ',');

/// « 97 400 » : sans séparateur, un compteur à six chiffres ne se relit pas.
String _entier(int valeur) {
  final chiffres = valeur.toString();
  final tampon = StringBuffer();

  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) tampon.write(' ');
    tampon.write(chiffres[i]);
  }

  return tampon.toString();
}

const _mois = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _jour(DateTime d) => '${d.day} ${_mois[d.month - 1]} ${d.year}';
