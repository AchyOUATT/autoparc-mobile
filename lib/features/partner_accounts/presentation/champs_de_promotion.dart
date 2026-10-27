import 'package:flutter/material.dart';

import 'marge_recapitulatif.dart';

/// Ce qu'un vendeur saisit pour mettre une annonce en promotion.
///
/// ── POURQUOI UN SEUL BLOC POUR LES DEUX FORMULAIRES ───────────────────────
///
/// Le véhicule et l'article ont deux écrans distincts, et la promotion y obéit
/// aux mêmes règles : un prix inférieur au prix normal, une remise plafonnée,
/// une fenêtre bornée. Deux copies divergeraient au premier changement de
/// plafond, et l'une des deux laisserait passer ce que l'autre refuse.
///
/// ── POURQUOI LE REFUS EST DIT ICI, ALORS QUE LE SERVEUR REFUSE AUSSI ──────
///
/// Le serveur reste l'autorité : c'est lui qui connaît le plafond du jour et
/// lui qui tranche. Mais un vendeur qui compose sa promotion doit lire « au-delà
/// de 40 %, ce n'est pas accepté » PENDANT qu'il tape, et non recevoir un refus
/// après avoir tout rempli. Le plafond voyage avec son profil pour cela.
///
/// Les deux ne peuvent pas diverger sans qu'un banc tombe : le calcul de remise
/// est le même des deux côtés, et le plafond vient du serveur.
class ChampsDePromotion extends StatefulWidget {
  const ChampsDePromotion({
    super.key,
    required this.prixNormal,
    required this.plafondPourcentage,
    required this.valeur,
    required this.onChanged,
  });

  /// Le prix habituel, tel que le vendeur vient de le taper. `null` tant qu'il
  /// n'en a pas saisi : la promotion est alors impossible, et on le dit.
  final num? prixNormal;

  /// La remise maximale autorisée, venue du profil partenaire.
  final double plafondPourcentage;

  final PromotionSaisie valeur;
  final ValueChanged<PromotionSaisie> onChanged;

  @override
  State<ChampsDePromotion> createState() => _ChampsDePromotionState();
}

/// L'état d'une promotion en cours de saisie.
///
/// Immuable : chaque modification produit une nouvelle valeur, remontée au
/// formulaire. C'est lui qui compose la charge utile, et lui seul — ce bloc ne
/// connaît ni les routes ni les noms de champs du serveur.
class PromotionSaisie {
  const PromotionSaisie({this.prix, this.debut, this.fin});

  final num? prix;
  final DateTime? debut;
  final DateTime? fin;

  bool get active => prix != null;

  PromotionSaisie copier({
    Object? prix = _rien,
    Object? debut = _rien,
    Object? fin = _rien,
  }) => PromotionSaisie(
    prix: prix == _rien ? this.prix : prix as num?,
    debut: debut == _rien ? this.debut : debut as DateTime?,
    fin: fin == _rien ? this.fin : fin as DateTime?,
  );

  /// Un marqueur pour distinguer « ne change pas » de « passe à null ».
  static const Object _rien = Object();

  /// La remise en pourcentage, ou `null` quand elle ne se calcule pas.
  ///
  /// Le MÊME calcul que `PromotionPartenaire::remise()` côté serveur. Les deux
  /// doivent s'accorder : un écran qui annonce 39,9 % sur ce que le serveur
  /// compte à 40,1 % ferait refuser une promotion qu'il venait d'accepter.
  double? remise(num? normal) {
    final p = prix;
    if (p == null || normal == null || normal <= 0) return null;

    return (normal - p) / normal * 100;
  }
}

class _ChampsDePromotionState extends State<ChampsDePromotion> {
  final _prix = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.valeur.prix != null) {
      _prix.text = widget.valeur.prix!.round().toString();
    }
  }

  @override
  void dispose() {
    _prix.dispose();
    super.dispose();
  }

  void _activer(bool actif) {
    if (!actif) {
      _prix.clear();
      widget.onChanged(const PromotionSaisie());

      return;
    }

    // Une semaine par défaut, à partir d'aujourd'hui : c'est la durée la plus
    // courante, et elle épargne deux sélecteurs au vendeur pressé. Il reste
    // libre de les changer.
    final maintenant = DateTime.now();
    widget.onChanged(PromotionSaisie(
      debut: DateTime(maintenant.year, maintenant.month, maintenant.day),
      fin: DateTime(maintenant.year, maintenant.month, maintenant.day)
          .add(const Duration(days: 7)),
    ));
  }

  Future<void> _choisirDate({required bool debut}) async {
    final maintenant = DateTime.now();
    final initiale = (debut ? widget.valeur.debut : widget.valeur.fin) ?? maintenant;

    final choisie = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: DateTime(maintenant.year, maintenant.month, maintenant.day),
      lastDate: maintenant.add(const Duration(days: 365)),
      helpText: debut ? 'Début de la promotion' : 'Fin de la promotion',
    );

    if (choisie == null) return;

    widget.onChanged(debut
        ? widget.valeur.copier(debut: choisie)
        : widget.valeur.copier(fin: choisie));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textes = Theme.of(context).textTheme;
    final valeur = widget.valeur;
    final remise = valeur.remise(widget.prixNormal);
    final depasse = remise != null &&
        widget.plafondPourcentage > 0 &&
        remise > widget.plafondPourcentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('promotion-activer'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.local_offer_outlined),
          title: const Text('Mettre en promotion'),
          subtitle: Text(
            widget.prixNormal == null
                ? 'Indiquez d’abord un prix de vente.'
                : widget.plafondPourcentage > 0
                    ? 'Remise de ${MargeRecapitulatif.formaterMontant(widget.plafondPourcentage)} % au maximum.'
                    : 'Pendant une durée que vous choisissez.',
          ),
          value: valeur.active || valeur.debut != null,
          // Grisé tant qu'il n'y a pas de prix à remiser : le serveur refuse
          // ce cas, et le laisser cliquable ferait composer une promotion
          // impossible.
          onChanged: widget.prixNormal == null ? null : _activer,
        ),
        if (valeur.active || valeur.debut != null) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('promotion-prix'),
            controller: _prix,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Prix pendant la promotion (FCFA)',
              border: const OutlineInputBorder(),
              // TROIS LIGNES, ET C EST UNE CAPTURE QUI L A MONTRE : le
              // refus par defaut tient sur UNE ligne et se coupait en
              // « La remise ne peut pas depasser 40 % : celle-ci es… ».
              // Le vendeur lisait le plafond sans jamais lire SA remise,
              // c est-a-dire sans savoir de combien il depassait.
              errorMaxLines: 3,
              errorText: depasse
                  ? 'La remise ne peut pas dépasser '
                      '${MargeRecapitulatif.formaterMontant(widget.plafondPourcentage)} % : '
                      'celle-ci est de ${remise.toStringAsFixed(1)} %.'
                  : null,
            ),
            onChanged: (texte) {
              final nombre = num.tryParse(texte.replaceAll(RegExp(r'[^0-9.]'), ''));
              widget.onChanged(valeur.copier(prix: nombre));
            },
            validator: (_) {
              if (!valeur.active) return null;
              if (widget.prixNormal != null && valeur.prix! >= widget.prixNormal!) {
                return 'Le prix promotionnel doit être inférieur au prix normal.';
              }

              return depasse ? 'Remise trop forte.' : null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _bouton(context, debut: true)),
              const SizedBox(width: 8),
              Expanded(child: _bouton(context, debut: false)),
            ],
          ),
          if (remise != null && !depasse && remise > 0) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('promotion-resume'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'L’acheteur verra −${remise.toStringAsFixed(remise == remise.roundToDouble() ? 0 : 1)} %, '
                '${MargeRecapitulatif.formaterMontant(widget.prixNormal!)} FCFA barré.',
                style: textes.bodySmall,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _bouton(BuildContext context, {required bool debut}) {
    final date = debut ? widget.valeur.debut : widget.valeur.fin;

    return OutlinedButton.icon(
      key: Key(debut ? 'promotion-debut' : 'promotion-fin'),
      onPressed: () => _choisirDate(debut: debut),
      icon: const Icon(Icons.event_outlined, size: 18),
      label: Text(
        date == null
            ? (debut ? 'Début' : 'Fin')
            : '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
