import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';

/// Met à jour le kilométrage d'un véhicule du garage.
///
/// Extrait de la page garage pour être appelé aussi depuis l'accueil : c'est
/// le geste le plus important de l'application côté propriétaire. Le rappel de
/// vidange se calcule à partir du kilométrage courant — sans mise à jour, il
/// ne part jamais. Le mettre à deux endroits multiplie les occasions de le
/// faire ; le dupliquer multiplierait les occasions de le voir diverger.
Future<void> showMileageDialog(
  BuildContext context,
  WidgetRef ref,
  OwnedVehicle vehicle,
) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _MileageDialog(vehicle: vehicle),
  );

  if (result == null || !context.mounted) return;

  final erreur = await ref.read(garageProvider.notifier).updateVehicle(vehicle.id, result);

  if (erreur != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erreur),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Le contrôleur appartient à la boîte de dialogue, pas à la fonction.
///
/// Il était créé avant `showDialog` et détruit juste après, à la ligne
/// suivante. Or `showDialog` rend la main dès que `Navigator.pop` est appelé :
/// la boîte est alors encore en train de s'animer, et son champ de saisie
/// toujours monté. Le clavier qui se referme modifie les `MediaQuery`,
/// l'overlay se reconstruit, le champ se réabonne à un contrôleur déjà
/// détruit — et Flutter lève « A TextEditingController was used after being
/// disposed », suivi de « '_dependents.isEmpty': is not true » et d'un écran
/// rouge.
///
/// C'est le plantage intermittent qu'on n'arrivait pas à reproduire : il
/// demande que le clavier soit ouvert et que sa fermeture tombe pendant les
/// quelques dixièmes de seconde de l'animation de sortie.
///
/// En confiant le contrôleur à l'état du widget, Flutter le détruit lui-même
/// une fois la route entièrement retirée.
class _MileageDialog extends StatefulWidget {
  final OwnedVehicle vehicle;

  const _MileageDialog({required this.vehicle});

  @override
  State<_MileageDialog> createState() => _MileageDialogState();
}

class _MileageDialogState extends State<_MileageDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.vehicle.mileageKm?.toString() ?? '',
  );

  /// Le message affiché sous le champ. Nul quand la saisie est recevable.
  String? _erreur;

  /// Vrai une fois que le propriétaire a vu l'avertissement de recul et
  /// maintenu sa saisie. Un deuxième appui vaut alors confirmation.
  bool _reculSignale = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Le garde-fou du kilométrage.
  ///
  /// Ce bouton rendait auparavant `int.tryParse(texte) ?? ancienne valeur`, et
  /// les deux moitiés de cette ligne étaient fausses.
  ///
  /// La retombée ne joue que sur un texte illisible : « Sauvegarder » se
  /// refermait alors sur un succès apparent sans rien avoir changé.
  ///
  /// Surtout, un compteur plus PETIT se parse très bien et partait tel quel —
  /// 9 600 tapé pour 96 000. Rien ne l'arrêtait ensuite : côté serveur,
  /// `mileage_km` n'est validé que `min:0`, et UpdateOwnedVehicleRequest
  /// hérite de cette règle. Le dégât n'est pas cosmétique :
  /// `OwnedVehicle::kilometresAvantVidange()` calcule
  /// `intervalle − (kilométrage − kilométrage de la dernière vidange)`. Avec
  /// 9 600 contre 90 000 de dernière vidange, il rend 80 400 km de plus que
  /// l'intervalle : le rappel de vidange est repoussé si loin qu'il ne part
  /// jamais, et aucune erreur ne le signale.
  ///
  /// Le recul n'est pas interdit pour autant — un compteur remplacé existe sur
  /// un parc importé, et une saisie trop haute corrigée plus tard aussi. Il
  /// est seulement rendu délibéré : on nomme les deux chiffres et on demande
  /// un second appui. Ce qui disparaît, c'est le recul silencieux.
  void _valider() {
    // Les espaces de séparation des milliers se tapent, et « 96 000 » ne se
    // parse pas. Les refuser ferait passer une saisie correcte pour une faute.
    final saisi = int.tryParse(_ctrl.text.replaceAll(RegExp(r'[\s ]'), ''));

    if (saisi == null) {
      setState(() => _erreur = 'Entrez un nombre de kilomètres.');
      return;
    }

    // Deux millions de kilomètres : la borne déjà retenue côté serveur pour le
    // kilométrage d'un contrôle (StoreVehicleCheckRequest). Elle attrape le
    // zéro de trop, pas un véhicule réellement très usé.
    if (saisi > 2000000) {
      setState(() => _erreur = 'Ce kilométrage est hors de portée.');
      return;
    }

    final ancien = widget.vehicle.mileageKm;

    if (ancien != null && saisi < ancien && !_reculSignale) {
      setState(() {
        _reculSignale = true;
        _erreur = 'Le compteur affichait ${_km(ancien)} km. '
            'Appuyez à nouveau pour enregistrer ${_km(saisi)} km.';
      });
      return;
    }

    Navigator.pop(context, {'mileage_km': saisi});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mettre à jour'),
      content: TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          labelText: 'Kilométrage actuel',
          suffixText: 'km',
          errorText: _erreur,
          // Le message de recul fait deux lignes : sans cela il est tronqué,
          // et c'est le chiffre précédent qu'il perdrait.
          errorMaxLines: 3,
        ),
        keyboardType: TextInputType.number,
        autofocus: true,
        // Repartir d'une saisie propre : le message précédent ne vaut plus dès
        // que le texte change, et le recul redemande sa confirmation.
        onChanged: (_) {
          if (_erreur == null && !_reculSignale) return;
          setState(() {
            _erreur = null;
            _reculSignale = false;
          });
        },
        onSubmitted: (_) => _valider(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _valider,
          child: Text(_reculSignale ? 'Confirmer' : 'Sauvegarder'),
        ),
      ],
    );
  }
}

/// « 96 000 » — l'espace de séparation des milliers du français.
String _km(int valeur) => NumberFormat.decimalPattern('fr_FR').format(valeur);
