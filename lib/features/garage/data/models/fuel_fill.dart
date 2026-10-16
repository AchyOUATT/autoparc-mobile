import 'package:equatable/equatable.dart';

/// Un passage à la pompe.
///
/// Quatre champs ne décrivent pas le passage mais l'intervalle qui **finit**
/// sur lui — [l100km], [distanceKm], [retenu], [motifEcart]. Ils restent nuls
/// sur un demi-plein : seul un plein ferme une mesure, parce que « la moitié
/// du réservoir » n'est pas un niveau qu'un conducteur sait reproduire, alors
/// que l'arrêt automatique du pistolet l'est.
///
/// Le calcul appartient au serveur, et à lui seul. Le refaire ici donnerait
/// deux consommations pour la même voiture dès que l'une des deux formules
/// bougerait — c'est déjà la règle posée pour les échéances d'entretien.
class FuelFill extends Equatable {
  final int id;

  /// Vrai quand la pompe s'est arrêtée toute seule.
  ///
  /// Le formulaire propose le demi-plein par défaut : ici on achète pour un
  /// montant — « mets-moi pour 10 000 » — et non jusqu'au débordement. Si
  /// l'application n'acceptait que les pleins, la majorité du parc
  /// n'enregistrerait jamais rien. L'erreur n'est pas symétrique : un plein
  /// déclaré demi-plein coûte un point de mesure et le chiffre reste JUSTE ;
  /// un demi-plein déclaré plein ferme l'intervalle sur un mauvais niveau et
  /// le chiffre devient FAUX.
  final bool isFull;

  /// Date du passage. Nulle quand le propriétaire ne l'a pas saisie : la
  /// station n'a pas de réseau, la saisie se fait souvent le soir même.
  final DateTime? filledAt;

  final int mileageKm;
  final double litres;
  final int? amountFcfa;
  final double? pricePerLitre;
  final String? note;
  final DateTime? createdAt;

  /// Consommation de l'intervalle fermé par ce passage, en l/100 km.
  /// Nulle si ce passage n'est pas un plein, ou s'il ouvre la série.
  final double? l100km;

  /// Distance de ce même intervalle, en kilomètres.
  final double? distanceKm;

  /// Faux quand l'intervalle a été écarté du chiffre affiché.
  final bool retenu;

  /// `trop_long`, `invraisemblable` ou `anormalement_bas`. Nul quand rien n'a
  /// été écarté. Nommé plutôt que muet : un intervalle qui disparaît sans
  /// raison visible passe pour un bug de l'application.
  ///
  /// `trop_court` a disparu du serveur : en dessous de 50 km l'intervalle se
  /// prolonge jusqu'au plein suivant au lieu d'être jeté — deux pleins à 30
  /// puis 40 km coûtaient 70 km de mesure valide.
  final String? motifEcart;

  /// Combien d'intervalles RETENUS ce passage borne : 0, 1 ou 2.
  ///
  /// Le nombre ne décrit pas le passage mais ce que sa suppression détruira.
  /// Un plein au milieu de la série en borne deux — il ferme celui d'avant et
  /// ouvre celui d'après — et le supprimer ne retire pas une ligne, il fusionne
  /// les deux intervalles en un seul. Mesure de la revue : 90 000/40 L,
  /// 90 600/48 L, 91 200/50 L affichent 8,2 l/100 km ; en supprimant le passage
  /// du milieu, les 98 L restants s'étalent sur 1 200 km et l'écran annonce
  /// 4,2 — présenté comme une mesure valide. La confirmation doit donc citer
  /// ce nombre, pas une phrase générique.
  ///
  /// Seuls les intervalles RETENUS sont comptés, côté serveur : avertir avant
  /// de supprimer n'a de sens que pour les mesures qui entrent dans le chiffre
  /// affiché. Un passage qui ne borne que des intervalles écartés ne coûte
  /// rien, et le signaler apprendrait à passer outre la confirmation.
  ///
  /// Clé `bornes_intervalles`. Absente sur un serveur d'avant le déploiement :
  /// on retombe alors sur `retenu ? 1 : 0`, ce que la ligne sait déjà
  /// d'elle-même. Ce repli sous-estime toujours — jamais l'inverse — donc il
  /// n'annonce jamais une destruction qui n'aura pas lieu.
  final int bornesIntervalles;

  const FuelFill({
    required this.id,
    required this.isFull,
    this.filledAt,
    required this.mileageKm,
    required this.litres,
    this.amountFcfa,
    this.pricePerLitre,
    this.note,
    this.createdAt,
    this.l100km,
    this.distanceKm,
    this.retenu = false,
    this.motifEcart,
    this.bornesIntervalles = 0,
  });

  factory FuelFill.fromJson(Map<String, dynamic> json) => FuelFill(
    id:            _int(json['id']) ?? 0,
    isFull:        _bool(json['is_full']),
    filledAt:      _date(json['filled_at']),
    mileageKm:     _int(json['mileage_km']) ?? 0,
    litres:        _double(json['litres']) ?? 0,
    amountFcfa:    _int(json['amount_fcfa']),
    pricePerLitre: _double(json['price_per_litre']),
    note:          json['note']?.toString(),
    createdAt:     _date(json['created_at']),
    l100km:        _double(json['l_100km']),
    distanceKm:    _double(json['distance_km']),
    retenu:        _bool(json['retenu']),
    motifEcart:    json['motif_ecart']?.toString(),
    bornesIntervalles: _int(json['bornes_intervalles']) ??
        (_bool(json['retenu']) ? 1 : 0),
  );

  /// Vrai quand ce passage ferme un intervalle que le chiffre affiché compte.
  bool get porteUneMesure => l100km != null;

  /// La raison de l'écart, rédigée. Les trois motifs signent un passage non
  /// enregistré, pas une anomalie du véhicule : le dire évite que le
  /// propriétaire cherche une panne — et surtout l'invite à tout saisir, parce
  /// que c'est lui, et lui seul, qui peut combler le trou.
  ///
  /// `anormalement_bas` est le motif le plus trompeur des trois, d'où sa
  /// phrase explicite : un oubli sur deux rend 4,0 l/100 km — 1 000 km pour
  /// 40 L — sur un véhicule qui fait 8,0, et 4,0 se lit comme une bonne
  /// nouvelle. Non écarté, il tirait la médiane de référence vers le bas, et
  /// les intervalles JUSTES à 8,0 déclenchaient ensuite l'alerte de
  /// surconsommation sur une voiture qui n'avait pas bougé d'un dixième.
  String? get motifLibelle => switch (motifEcart) {
    'trop_long'        => 'Un passage a probablement été oublié',
    'invraisemblable'  => 'Chiffre invraisemblable, un passage manque',
    'anormalement_bas' => 'Chiffre trop bas pour être vrai : un passage '
        'd\'avant n\'a pas été enregistré',
    _                  => null,
  };

  @override
  List<Object?> get props =>
      [id, mileageKm, litres, isFull, retenu, bornesIntervalles];
}

/// Le suivi carburant d'un véhicule, calculé par le serveur sur ses propres
/// passages.
///
/// Rien n'est comparé à la cote constructeur : les cycles d'homologation
/// s'écartent de 20 à 30 % de la conduite réelle, et une alerte gagée dessus
/// sonnerait en permanence sur un parc qui roule sur piste.
class FuelTracking extends Equatable {
  /// Consommation sur les 5 derniers intervalles retenus. Nulle tant qu'aucun
  /// intervalle n'est retenu — ce qui est le cas de tout propriétaire qui ne
  /// fait jamais le plein.
  final double? l100km;

  /// Coût aux 100 km. Nul si aucun passage de l'intervalle ne porte de
  /// montant : à la pompe on retient le montant payé plus souvent que les
  /// litres, mais pas toujours.
  final double? fcfa100km;

  final int basedOnFills;
  final int totalFills;
  final int fullFills;
  final int excludedIntervals;
  final DateTime? lastFilledAt;
  final int? lastMileageKm;

  /// La médiane de référence du véhicule, nulle en dessous de 6 intervalles
  /// retenus. Médiane et non moyenne : sur une série courte, une seule faute
  /// de frappe sur le compteur déplace la moyenne, pas la médiane.
  final double? baselineL100km;

  /// Vrai quand les deux derniers intervalles dépassent tous les deux la
  /// référence. Deux, parce qu'un seul peut venir d'une faute de frappe.
  final bool abnormal;

  /// Le chiffre QUI A TRANCHE, et non celui qui s'affiche en gros.
  ///
  /// [l100km] porte les cinq derniers intervalles ; le verdict se prend sur
  /// les DEUX derniers. Série 8 8 8 8 3,1 3,1 11 11 : référence 8,0, verdict
  /// vrai, [l100km] 7,2 — et l'encart disait « 7,2 l/100 km contre 8,0
  /// d'habitude » sous le titre « Votre consommation a augmenté ». Il annonçait
  /// une baisse. Nul tant que [abnormal] est faux : il n'y a pas de verdict à
  /// citer.
  final double? alerteL100km;

  /// Vrai quand le compteur a été remplacé : l'histoire d'avant existe toujours
  /// en base mais n'entre plus dans aucun de ces chiffres.
  ///
  /// 7 pleins à 11,0 depuis 200 000 km suivis de 4 pleins réels à 7,0 depuis
  /// 1 800 ne font pas une série : le serveur coupe et ne garde que la plus
  /// récente. Le propriétaire voit alors son nombre de pleins chuter de 11 à 4
  /// d'un relevé à l'autre — sans cette mention, il ne peut lire ça que comme
  /// des saisies perdues.
  final bool seriesRompue;

  /// Litres, francs et kilomètres depuis le premier passage. Toujours
  /// calculés, même sans un seul intervalle retenu : c'est ce qu'on montre au
  /// propriétaire qui ne fait jamais le plein. Ce ne sont pas une moyenne et
  /// on n'en tire aucun taux — l'écart de niveau entre le premier et le
  /// dernier passage le fausserait, borné par une capacité de réservoir que
  /// nous ne connaissons pas.
  final FuelTotals totals;

  const FuelTracking({
    this.l100km,
    this.fcfa100km,
    this.basedOnFills = 0,
    this.totalFills = 0,
    this.fullFills = 0,
    this.excludedIntervals = 0,
    this.lastFilledAt,
    this.lastMileageKm,
    this.baselineL100km,
    this.abnormal = false,
    this.alerteL100km,
    this.seriesRompue = false,
    this.totals = const FuelTotals(),
  });

  factory FuelTracking.fromJson(Map<String, dynamic> json) => FuelTracking(
    l100km:            _double(json['l_100km']),
    fcfa100km:         _double(json['fcfa_100km']),
    basedOnFills:      _int(json['based_on_fills'])      ?? 0,
    totalFills:        _int(json['total_fills'])         ?? 0,
    fullFills:         _int(json['full_fills'])          ?? 0,
    excludedIntervals: _int(json['excluded_intervals'])  ?? 0,
    lastFilledAt:      _date(json['last_filled_at']),
    lastMileageKm:     _int(json['last_mileage_km']),
    baselineL100km:    _double(json['baseline_l_100km']),
    abnormal:          _bool(json['abnormal']),
    alerteL100km:      _double(json['alerte_l_100km']),
    seriesRompue:      _bool(json['series_rompue']),
    totals: FuelTotals.fromJson(
        json['totals'] as Map<String, dynamic>? ?? const {}),
  );

  /// Vrai quand aucun passage n'a encore été saisi. La clé est toujours
  /// présente dans la réponse, compteurs à zéro : « aucun passage » et « pas
  /// demandé » ne doivent pas se ressembler à l'écran.
  bool get vide => totalFills == 0;

  /// Vrai quand le serveur rend un chiffre de consommation exploitable.
  bool get aUnChiffre => l100km != null;

  @override
  List<Object?> get props => [
        l100km,
        fcfa100km,
        basedOnFills,
        totalFills,
        abnormal,
        alerteL100km,
        seriesRompue,
      ];
}

/// Faits bruts cumulés depuis le premier passage.
class FuelTotals extends Equatable {
  final double litres;
  final int amountFcfa;

  /// L'écart de compteur entre le premier et le dernier passage, pas la somme
  /// d'étapes : c'est la seule distance que les saisies permettent d'affirmer.
  final int distanceKm;

  const FuelTotals({
    this.litres = 0,
    this.amountFcfa = 0,
    this.distanceKm = 0,
  });

  factory FuelTotals.fromJson(Map<String, dynamic> json) => FuelTotals(
    litres:     _double(json['litres'])      ?? 0,
    amountFcfa: _int(json['amount_fcfa'])    ?? 0,
    distanceKm: _int(json['distance_km'])    ?? 0,
  );

  @override
  List<Object?> get props => [litres, amountFcfa, distanceKm];
}

/// Laravel sérialise les colonnes `decimal` en chaînes : « 41.20 », pas 41.2.
/// Lire `as num?` avait fait remonter `type 'String' is not a subtype of type
/// 'num?'` sur le catalogue entier. `litres` et `price_per_litre` sont des
/// `decimal`, et les taux calculés peuvent arriver des deux façons selon que
/// le serveur les arrondit ou non.
double? _double(Object? value) =>
    value == null ? null : double.tryParse(value.toString());

/// Même précaution sur les entiers : un `unsignedInteger` agrégé par la base
/// (une somme SQL) remonte volontiers en chaîne, et `97400.0` est un entier
/// écrit en flottant.
int? _int(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.round();
}

/// `is_full` et `abnormal` arrivent en booléens JSON, mais un `tinyint(1)` non
/// casté remonte en 0/1 — et un `boolean` sérialisé par une vieille route en
/// « true ». Un faux `false` ici ferait passer un plein pour un demi-plein et
/// perdrait l'intervalle sans rien signaler.
bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final texte = value?.toString().toLowerCase();
  return texte == 'true' || texte == '1';
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
