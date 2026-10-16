import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/fuel_fill.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/fuel_fills_provider.dart';

/// Enregistre un passage à la pompe.
///
/// Rend `true` quand un passage a été enregistré, pour que l'appelant sache
/// s'il doit emmener le propriétaire ailleurs.
Future<bool> showFuelFillDialog(
  BuildContext context,
  OwnedVehicle vehicle,
) async {
  final enregistre = await showDialog<bool>(
    context: context,
    builder: (ctx) => _FuelFillDialog(vehicle: vehicle),
  );

  return enregistre ?? false;
}

/// La saisie se fait debout, à la station, sur un téléphone.
///
/// D'où la forme : on demande ce qu'on vient de faire — un montant et un prix
/// affichés sur la pompe — et non des litres, que personne ne relève. Les
/// litres se déduisent et s'affichent en direct, pour que le propriétaire voie
/// ce qui sera enregistré avant de valider.
///
/// L'envoi se fait ici, boîte encore ouverte, et non après sa fermeture : le
/// provider des passages est `autoDispose`, et un appel lancé depuis un `ref`
/// qui ne l'écoute plus se termine sur un notifier déjà détruit. Ouverte, la
/// boîte l'écoute ; fermée, plus personne. L'effet secondaire est voulu : sur
/// le réseau d'une station, un échec laisse la saisie à l'écran, prête à être
/// rejouée, au lieu de la perdre.
///
/// PIÈGE DÉJÀ PAYÉ ICI — voir le commentaire en tête de `_MileageDialog` :
/// les contrôleurs de texte appartiennent à l'état du widget, jamais à la
/// fonction qui appelle `showDialog`. Créés à l'extérieur, ils étaient
/// détruits pendant l'animation de sortie, et la fermeture du clavier
/// reconstruisait un champ branché sur un contrôleur mort — écran rouge
/// intermittent, impossible à reproduire à la demande.
class _FuelFillDialog extends ConsumerStatefulWidget {
  final OwnedVehicle vehicle;

  const _FuelFillDialog({required this.vehicle});

  @override
  ConsumerState<_FuelFillDialog> createState() => _FuelFillDialogState();
}

class _FuelFillDialogState extends ConsumerState<_FuelFillDialog> {
  late final TextEditingController _km = TextEditingController(
    text: widget.vehicle.mileageKm?.toString() ?? '',
  );
  final TextEditingController _montant = TextEditingController();
  final TextEditingController _prix = TextEditingController();
  final TextEditingController _litres = TextEditingController();

  /// Demi-plein par défaut, et c'est le cœur du formulaire.
  ///
  /// L'erreur n'est pas symétrique : un plein déclaré demi-plein coûte un
  /// point de mesure et le chiffre affiché reste juste ; un demi-plein déclaré
  /// plein ferme l'intervalle sur un niveau de réservoir inconnu et le chiffre
  /// devient faux. On incline donc du côté qui ne peut que perdre une mesure.
  bool _plein = false;

  /// Le champ des litres n'est pas un quatrième champ permanent : ici on
  /// achète pour un montant, et la pompe affiche le prix au litre. Celui qui
  /// connaît ses litres bascule d'un lien ; les autres ne voient pas une case
  /// de plus à remplir à la pompe, de nuit, moteur allumé.
  bool _litresDirects = false;

  bool _envoi = false;
  String? _erreur;

  /// Vrai dès que le propriétaire a touché au prix : le dernier prix connu
  /// arrive de façon asynchrone, et ne doit jamais écraser une saisie en
  /// cours.
  bool _prixTouche = false;

  @override
  void initState() {
    super.initState();
    _prix.addListener(() => _prixTouche = true);

    // La liste peut déjà être en mémoire — on arrive de l'historique. Le
    // `listen` du build ne se déclenche alors jamais, puisqu'il n'y a plus de
    // transition à observer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _preremplirPrix(
        ref.read(fuelFillsProvider(widget.vehicle.id)).valueOrNull,
      );
    });
  }

  @override
  void dispose() {
    _km.dispose();
    _montant.dispose();
    _prix.dispose();
    _litres.dispose();
    super.dispose();
  }

  /// Le prix au litre bouge peu d'un passage à l'autre et se lit mal sur la
  /// pompe : le reprendre du dernier passage évite la faute de frappe qui
  /// fausserait les litres, donc la consommation.
  void _preremplirPrix(List<FuelFill>? passages) {
    if (_prixTouche || passages == null || passages.isEmpty) return;

    final dernier = passages
        .where((p) => p.pricePerLitre != null)
        .fold<FuelFill?>(
          null,
          (garde, p) =>
              garde == null || p.mileageKm >= garde.mileageKm ? p : garde,
        );

    if (dernier == null) return;

    _prix.text = _nombre(dernier.pricePerLitre!, decimales: 0);
    _prixTouche = false; // le listener vient de se déclencher sur notre propre écriture
    setState(() {});
  }

  /// Les litres tels qu'ils partiront au serveur, ou nul si la saisie ne
  /// permet pas encore de les connaître.
  double? get _litresCalcules {
    if (_litresDirects) return _decimal(_litres.text);

    final montant = _decimal(_montant.text);
    final prix = _decimal(_prix.text);

    if (montant == null || prix == null || prix <= 0) return null;
    return double.parse((montant / prix).toStringAsFixed(2));
  }

  /// La clé d'idempotence, DÉRIVÉE de la saisie et non tirée au hasard.
  ///
  /// Elle était auparavant un UUID posé dans l'état de la boîte, donc détruit
  /// avec elle. Or le rejeu réellement vécu à la station n'est pas le re-tap
  /// dans la même boîte — le bouton se désactive pendant l'envoi — c'est le
  /// propriétaire qui, faute de réponse sur le réseau de la station, ferme la
  /// boîte, la rouvre et ressaisit. Il obtenait une seconde clé, le serveur
  /// n'y voyait pas un rejeu, et deux lignes identiques entraient en base.
  ///
  /// Mesure de l'incident : véhicule stable à 8,0 l/100, un demi-plein de
  /// 16 L saisi deux fois sur chacun des deux derniers intervalles — 10,7
  /// l/100 sur ces intervalles, encart rouge affiché et alerte de
  /// surconsommation partie, sur une consommation qui n'avait pas bougé d'un
  /// dixième.
  ///
  /// Le sens de l'erreur n'est pas celui qu'on croit, et le commentaire qui
  /// était ici l'avait à l'envers : il annonçait une consommation ABAISSÉE.
  /// C'est vrai d'un doublon de PLEIN — il se borne lui-même, la distance de
  /// son intervalle est nulle et le calcul l'écarte. C'est faux d'un doublon
  /// de DEMI-PLEIN, qui ne borne rien : ses litres s'ajoutent à l'intervalle
  /// en cours pendant que la distance, elle, ne bouge pas. Le chiffre MONTE.
  /// Et c'est ce doublon-là, le seul des deux qui passe inaperçu, qui fait
  /// sonner l'alerte.
  ///
  /// Dérivée plutôt que conservée hors de l'état de la boîte : une clé gardée
  /// en mémoire vive ne survivrait pas davantage à l'application tuée en
  /// arrière-plan pendant que le propriétaire remet le pistolet et paie, ce
  /// qui est exactement la séquence qui produit la ressaisie. Les quatre
  /// nombres qui identifient le passage, eux, sont les mêmes à chaque
  /// ressaisie puisque c'est le même passage qu'on retape.
  ///
  /// Le prix de ce choix est assumé : deux passages réellement distincts au
  /// MÊME compteur, aux mêmes litres et de même nature deviennent un seul.
  /// Cela ne coûte aucune mesure — entre eux la distance est nulle, donc leur
  /// intervalle ne vaut déjà rien — alors qu'un doublon, lui, fausse le
  /// chiffre affiché et déclenche l'alerte.
  String _reference(int km, double litres) =>
      'v${widget.vehicle.id}-k$km-l${litres.toStringAsFixed(2)}'
      '-${_plein ? 'p' : 'd'}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textes = Theme.of(context).textTheme;

    // Écouter la liste des passages tient aussi le provider en vie pendant
    // l'envoi, voir le commentaire de classe.
    ref.listen(fuelFillsProvider(widget.vehicle.id), (_, suivant) {
      _preremplirPrix(suivant.valueOrNull);
    });

    final litres = _litresCalcules;

    return AlertDialog(
      title: const Text('Passage à la pompe'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _km,
              decoration: const InputDecoration(
                labelText: 'Kilométrage au compteur',
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_envoi,
            ),
            const SizedBox(height: 8),

            if (!_litresDirects) ...[
              TextField(
                controller: _montant,
                decoration: const InputDecoration(
                  labelText: 'Montant payé',
                  suffixText: 'FCFA',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_envoi,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _prix,
                decoration: const InputDecoration(
                  labelText: 'Prix au litre',
                  suffixText: 'FCFA/l',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !_envoi,
                onChanged: (_) => setState(() {}),
              ),
            ] else
              TextField(
                controller: _litres,
                decoration: const InputDecoration(
                  labelText: 'Litres pris',
                  suffixText: 'l',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !_envoi,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),

            // Ce qui sera enregistré, sous les champs et en direct : les
            // litres sont la seule donnée qui entre dans le calcul, et le
            // propriétaire ne les a pas saisis.
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _litresDirects
                    ? 'Enregistré tel quel.'
                    : litres == null
                        ? 'Les litres se déduisent du montant et du prix.'
                        : 'Soit ${_nombre(litres)} l',
                style: textes.bodySmall?.copyWith(
                  color: litres == null ? cs.outline : cs.primary,
                  fontWeight: litres == null ? null : FontWeight.bold,
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _envoi
                    ? null
                    : () => setState(() => _litresDirects = !_litresDirects),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_litresDirects
                    ? 'Saisir le montant payé'
                    : 'Je connais les litres'),
              ),
            ),

            const SizedBox(height: 8),

            // Le choix se libelle par ce qui se constate à la pompe, pas par
            // une intention : « la moitié du réservoir » n'est pas un niveau
            // qu'un conducteur sait reproduire, l'arrêt automatique du
            // pistolet l'est.
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Demi-plein')),
                ButtonSegment(value: true, label: Text('Plein')),
              ],
              selected: {_plein},
              onSelectionChanged: _envoi
                  ? null
                  : (choix) => setState(() => _plein = choix.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Plein = la pompe s\'est arrêtée toute seule. Seul un plein '
                'permet de mesurer la consommation.',
                style: textes.bodySmall?.copyWith(color: cs.outline),
              ),
            ),

            if (_erreur != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _erreur!,
                  style: textes.bodySmall?.copyWith(color: cs.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _envoi ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _envoi ? null : _enregistrer,
          child: _envoi
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _enregistrer() async {
    final km = int.tryParse(_km.text.trim());
    final litres = _litresCalcules;

    // Seuls les champs du mode courant sont lus. Basculer masque les deux
    // autres sans les vider, et ils partaient quand même : 10 000 FCFA et
    // 730 FCFA/l tapés, puis « Je connais les litres » et 40 litres saisis,
    // et le serveur recevait litres=40, amount_fcfa=10000,
    // price_per_litre=730 — trois nombres incohérents, 40 l à 730 F faisant
    // 29 200 F. Le coût aux 100 km sortait divisé par près de trois, et rien
    // ne le signalait puisque chaque champ, pris isolément, passe la
    // validation.
    final montant = _litresDirects ? null : _decimal(_montant.text);
    final prix = _litresDirects ? null : _decimal(_prix.text);

    // Les mêmes bornes que le serveur, dites avant l'aller-retour : à la
    // station, un refus qui arrive trente secondes plus tard est un refus
    // qu'on ne lit pas.
    if (km == null) {
      setState(() => _erreur = 'Indiquez le kilométrage au compteur.');
      return;
    }
    if (litres == null || litres < 1 || litres > 200) {
      setState(() => _erreur = _litresDirects
          ? 'Les litres doivent être compris entre 1 et 200.'
          : 'Montant et prix au litre donnent une quantité impossible.');
      return;
    }

    setState(() {
      _erreur = null;
      _envoi = true;
    });

    final erreur =
        await ref.read(fuelFillsProvider(widget.vehicle.id).notifier).addFill({
      'mileage_km': km,
      'litres': litres,
      'is_full': _plein,
      if (montant != null) 'amount_fcfa': montant.round(),
      'price_per_litre': ?prix,

      // La date vient du téléphone, qui est le seul à connaître le fuseau du
      // propriétaire ; le serveur tourne en UTC. Sans ce champ la colonne
      // reste NULL — elle est nullable pour la saisie en retard — et la ligne
      // de l'historique s'affiche sans aucune date, ce qui rend impossible de
      // reconnaître lequel de deux passages au compteur voisin on regarde.
      'filled_at': _dateDuJour(),

      'client_reference': _reference(km, litres),
    });

    if (!mounted) return;

    if (erreur != null) {
      setState(() {
        _envoi = false;
        _erreur = erreur;
      });
      return;
    }

    Navigator.pop(context, true);
  }
}

/// « 8,2 » et non « 8.2 » ; et la saisie accepte la virgule, puisque c'est
/// ainsi qu'on écrit un décimal ici.
String _nombre(double valeur, {int decimales = 1}) =>
    valeur.toStringAsFixed(decimales).replaceAll('.', ',');

double? _decimal(String texte) {
  final propre = texte.trim().replaceAll(',', '.').replaceAll(' ', '');
  return propre.isEmpty ? null : double.tryParse(propre);
}

/// Le jour local du téléphone, au format que le serveur valide.
///
/// Date nue et non horodatage : la colonne est un `date`, et l'heure exacte
/// d'un passage à la pompe n'entre dans aucun calcul — c'est le compteur qui
/// ordonne la chaîne. Date LOCALE et non UTC : le serveur refuse le futur
/// (`before_or_equal:today`), et une date construite en UTC daterait d'hier
/// un passage fait après minuit dans un fuseau en avance.
String _dateDuJour() {
  final jour = DateTime.now();
  final mois = jour.month.toString().padLeft(2, '0');
  final quantieme = jour.day.toString().padLeft(2, '0');
  return '${jour.year.toString().padLeft(4, '0')}-$mois-$quantieme';
}
