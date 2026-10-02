import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../vehicles/data/models/catalog_refs.dart';

/// D'où vient une ligne de compatibilité.
///
/// L'API distingue les deux depuis que `catalog:backfill-fitments` a dû savoir
/// quoi épargner. Pour celui qui relit une liste, la distinction compte
/// davantage encore : une ligne proposée n'a été vérifiée par personne, et rien
/// ne le disait.
enum FitmentOrigin {
  declaree,
  proposee;

  static FitmentOrigin depuisApi(String? valeur) =>
      valeur == 'generated' ? FitmentOrigin.proposee : FitmentOrigin.declaree;

  String get libelle => this == FitmentOrigin.proposee ? 'Proposée' : 'Déclarée';
}

/// Un fitment = compatibilité déclarée entre une pièce/accessoire et un modèle.
///
/// La classe portait les objets du référentiel — une `BrandRef`, une
/// `ModelRef`, une `TrimRef`. Pratique pour construire une ligne depuis le
/// formulaire, impossible pour en relire une : l'API rend des identifiants, et
/// trois colonnes qu'aucun champ du formulaire ne propose (motorisation,
/// transmission, code moteur). Une ligne reconstruite à partir du seul
/// référentiel les perdait au premier enregistrement.
///
/// Elle porte donc désormais ce que l'API échange, plus les libellés
/// nécessaires à l'affichage. Un modèle absent du référentiel — retiré du
/// catalogue, par exemple — garde ainsi son identifiant et survit à
/// l'aller-retour, même si son nom ne peut plus être affiché.
class FitmentEntry {
  final int     vehicleModelId;
  final int?    brandId;
  final String  brandName;
  final String  modelName;
  final int?    trimId;
  final String? trimName;
  final int?    engineTypeId;
  final int?    drivetrainId;
  final String? engineCode;
  final int?    yearFrom;
  final int?    yearTo;
  final String? position; // pour les pièces uniquement
  final String? notes;
  final FitmentOrigin origin;

  const FitmentEntry({
    required this.vehicleModelId,
    required this.brandName,
    required this.modelName,
    this.brandId,
    this.trimId,
    this.trimName,
    this.engineTypeId,
    this.drivetrainId,
    this.engineCode,
    this.yearFrom,
    this.yearTo,
    this.position,
    this.notes,
    this.origin = FitmentOrigin.declaree,
  });

  /// Une ligne saisie dans le formulaire, depuis les objets du référentiel.
  factory FitmentEntry.saisie({
    required BrandRef brand,
    required ModelRef model,
    TrimRef? trim,
    int? yearFrom,
    int? yearTo,
    String? position,
  }) =>
      FitmentEntry(
        vehicleModelId: model.id,
        brandId:        brand.id,
        brandName:      brand.name,
        modelName:      model.displayName,
        trimId:         trim?.id,
        trimName:       trim?.name,
        yearFrom:       yearFrom,
        yearTo:         yearTo,
        position:       position,
      );

  /// Une ligne relue depuis l'API.
  ///
  /// Les libellés viennent du référentiel quand il connaît la ligne, sinon de
  /// ce que l'API a rendu. Aucun des deux n'est indispensable : perdre un nom
  /// dégrade l'affichage, perdre un identifiant perdrait la donnée.
  factory FitmentEntry.depuisJson(
    Map<String, dynamic> json, {
    CatalogRefs? refs,
  }) {
    final modelId = json['vehicle_model_id'] as int;
    final brandId = json['brand_id'] as int?;

    final modele = refs?.vehicleModels
        .where((m) => m.id == modelId)
        .firstOrNull;
    final marque = brandId == null
        ? null
        : refs?.brands.where((b) => b.id == brandId).firstOrNull;

    return FitmentEntry(
      vehicleModelId: modelId,
      brandId:        brandId ?? modele?.brandId,
      brandName:      marque?.name ?? '',
      modelName:      modele?.displayName
          ?? json['vehicle_model'] as String?
          ?? 'Modèle n° $modelId',
      trimId:         json['trim_id'] as int?,
      trimName:       json['trim'] as String?,
      engineTypeId:   json['engine_type_id'] as int?,
      drivetrainId:   json['drivetrain_id'] as int?,
      engineCode:     json['engine_code'] as String?,
      yearFrom:       json['year_from'] as int?,
      yearTo:         json['year_to'] as int?,
      position:       json['position'] as String?,
      notes:          json['notes'] as String?,
      origin:         FitmentOrigin.depuisApi(json['source'] as String?),
    );
  }

  /// Libellé affiché dans la liste.
  String get label {
    final buf = StringBuffer(
      brandName.isEmpty ? modelName : '$brandName $modelName',
    );
    if (trimName != null) buf.write(' · $trimName');
    if (yearFrom != null && yearTo != null) {
      buf.write(' ($yearFrom – $yearTo)');
    } else if (yearFrom != null) {
      buf.write(' (depuis $yearFrom)');
    } else if (yearTo != null) {
      buf.write(' (jusqu\'à $yearTo)');
    }
    if (position != null && position!.isNotEmpty) {
      buf.write(' · ${position!}');
    }
    return buf.toString();
  }

  /// L'initiale de l'avatar, qui doit tenir même sans libellé de marque.
  String get initiale {
    final source = brandName.isNotEmpty ? brandName : modelName;
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }

  /// Payload JSON pour l'API.
  ///
  /// Toute clé omise ici est une colonne vidée à l'enregistrement : le `PUT`
  /// remplace la liste entière. L'origine, elle, n'est pas envoyée — c'est le
  /// serveur qui en décide, et une requête ne doit pas pouvoir faire passer
  /// une saisie pour une proposition.
  Map<String, dynamic> toJson() => {
    'vehicle_model_id': vehicleModelId,
    if (trimId       != null) 'trim_id':        trimId,
    if (engineTypeId != null) 'engine_type_id': engineTypeId,
    if (drivetrainId != null) 'drivetrain_id':  drivetrainId,
    if (engineCode   != null && engineCode!.isNotEmpty) 'engine_code': engineCode,
    if (yearFrom     != null) 'year_from':      yearFrom,
    if (yearTo       != null) 'year_to':        yearTo,
    if (position     != null && position!.isNotEmpty) 'position': position,
    if (notes        != null && notes!.isNotEmpty)    'notes':    notes,
  };
}

// ════════════════════════════════════════════════════════════════════
// Widget principal
// ════════════════════════════════════════════════════════════════════

/// Section "Compatibilités véhicules" — réutilisable dans les formulaires
/// de pièces détachées et d'accessoires.
class FitmentsSection extends StatefulWidget {
  final CatalogRefs refs;
  final bool showPosition; // true pour les pièces, false pour les accessoires
  final void Function(List<FitmentEntry>) onChanged;

  /// Les compatibilités déjà enregistrées, en modification.
  ///
  /// Sans elles, la section démarrait vide sur une pièce qui en portait cinq.
  /// Ajouter une ligne puis enregistrer envoyait une liste d'un seul élément,
  /// et le `PUT` remplaçant la liste entière, les quatre autres disparaissaient
  /// sans un message. C'était exactement le geste qu'on vient faire ici.
  final List<FitmentEntry> initiales;

  const FitmentsSection({
    super.key,
    required this.refs,
    required this.onChanged,
    this.showPosition = false,
    this.initiales = const [],
  });

  @override
  State<FitmentsSection> createState() => _FitmentsSectionState();
}

class _FitmentsSectionState extends State<FitmentsSection> {
  late final List<FitmentEntry> _entries = [...widget.initiales];

  void _add(FitmentEntry entry) {
    setState(() => _entries.add(entry));
    widget.onChanged(List.unmodifiable(_entries));
  }

  void _remove(int index) {
    setState(() => _entries.removeAt(index));
    widget.onChanged(List.unmodifiable(_entries));
  }

  Future<void> _openAddSheet() async {
    final entry = await showModalBottomSheet<FitmentEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FitmentSheet(
        refs: widget.refs,
        showPosition: widget.showPosition,
      ),
    );
    if (entry != null) _add(entry);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Liste des fitments ajoutés ────────────────────────────
        if (_entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_car_outlined,
                    size: 32, color: cs.outline),
                const SizedBox(height: 8),
                Text(
                  'Aucune compatibilité déclarée',
                  style: TextStyle(color: cs.outline),
                ),
                const SizedBox(height: 4),
                Text(
                  'La pièce sera trouvable uniquement par SKU.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final e = _entries[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      e.initiale,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(e.label, style: const TextStyle(fontSize: 13)),
                  // Une ligne proposée n'a été vérifiée par personne : elle
                  // vient du remplissage automatique du catalogue. La garder
                  // en enregistrant, c'est en répondre.
                  subtitle: e.origin == FitmentOrigin.proposee
                      ? Text(
                          'Proposée automatiquement, non vérifiée',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.outline),
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _remove(i),
                    color: cs.error,
                  ),
                ),
              );
            },
          ),

        // ── Ce que l'enregistrement fera des lignes proposées ─────
        //
        // La conversion est volontaire — la liste affichée distingue les deux
        // origines, donc laisser une ligne, c'est en répondre. Mais une
        // décision que l'écran ne dit pas est une surprise, pas un choix.
        if (_entries.any((e) => e.origin == FitmentOrigin.proposee))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'En enregistrant, les lignes proposées que vous laissez ici '
              'deviennent des compatibilités déclarées : elles ne seront plus '
              'recalculées, et vous en répondez. Retirez celles que vous ne '
              'pouvez pas confirmer.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ),

        const SizedBox(height: 10),

        // ── Bouton Ajouter ────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: _openAddSheet,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter une compatibilité'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Bottom sheet de saisie d'un fitment
// ════════════════════════════════════════════════════════════════════

class _FitmentSheet extends StatefulWidget {
  final CatalogRefs refs;
  final bool showPosition;

  const _FitmentSheet({required this.refs, required this.showPosition});

  @override
  State<_FitmentSheet> createState() => _FitmentSheetState();
}

class _FitmentSheetState extends State<_FitmentSheet> {
  BrandRef?  _brand;
  ModelRef?  _model;
  TrimRef?   _trim;
  final _yearFromCtrl = TextEditingController();
  final _yearToCtrl   = TextEditingController();
  final _posCtrl      = TextEditingController();

  @override
  void dispose() {
    _yearFromCtrl.dispose();
    _yearToCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  List<ModelRef> get _models =>
      _brand == null ? [] : widget.refs.modelsForBrand(_brand!.id);

  List<TrimRef> get _trims =>
      _model == null ? [] : widget.refs.trimsForModel(_model!.id);

  void _confirm() {
    if (_model == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un modèle.')),
      );
      return;
    }

    final entry = FitmentEntry.saisie(
      brand:    _brand!,
      model:    _model!,
      trim:     _trim,
      yearFrom: int.tryParse(_yearFromCtrl.text),
      yearTo:   int.tryParse(_yearToCtrl.text),
      position: widget.showPosition ? _posCtrl.text.trim() : null,
    );

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.refs.brands.where((b) => b.isActive).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Compatibilité véhicule',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ── Marque ───────────────────────────────────────────────
          DropdownButtonFormField<BrandRef>(
            value: _brand,
            decoration: const InputDecoration(
              labelText: 'Marque *',
              prefixIcon: Icon(Icons.directions_car_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            isExpanded: true,
            hint: const Text('Sélectionner…'),
            items: brands.map((b) => DropdownMenuItem(
              value: b,
              child: Text(b.name),
            )).toList(),
            onChanged: (b) => setState(() {
              _brand = b;
              _model = null;
              _trim  = null;
            }),
          ),
          const SizedBox(height: 12),

          // ── Modèle ───────────────────────────────────────────────
          DropdownButtonFormField<ModelRef>(
            value: _model,
            decoration: InputDecoration(
              labelText: 'Modèle *',
              prefixIcon: const Icon(Icons.car_repair),
              border: const OutlineInputBorder(),
              isDense: true,
              helperText: _brand == null ? 'Choisir d\'abord une marque' : null,
            ),
            isExpanded: true,
            hint: const Text('Sélectionner…'),
            items: _models.map((m) => DropdownMenuItem(
              value: m,
              child: Text(m.displayName),
            )).toList(),
            onChanged: _brand == null ? null : (m) => setState(() {
              _model = m;
              _trim  = null;
            }),
          ),
          const SizedBox(height: 12),

          // ── Finition (optionnel) ─────────────────────────────────
          if (_trims.isNotEmpty) ...[
            DropdownButtonFormField<TrimRef>(
              value: _trim,
              decoration: const InputDecoration(
                labelText: 'Finition (optionnel)',
                prefixIcon: Icon(Icons.tune),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              isExpanded: true,
              hint: const Text('Toutes finitions'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Toutes finitions —')),
                ..._trims.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.name),
                )),
              ],
              onChanged: (t) => setState(() => _trim = t),
            ),
            const SizedBox(height: 12),
          ],

          // ── Années ───────────────────────────────────────────────
          Row(children: [
            Expanded(child: TextFormField(
              controller: _yearFromCtrl,
              decoration: const InputDecoration(
                labelText: 'Année de',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            )),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(
              controller: _yearToCtrl,
              decoration: const InputDecoration(
                labelText: 'Année à',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            )),
          ]),

          // ── Position (pièces seulement) ──────────────────────────
          if (widget.showPosition) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _posCtrl,
              decoration: const InputDecoration(
                labelText: 'Position (optionnel)',
                prefixIcon: Icon(Icons.location_searching),
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Ex. Avant gauche, Côté moteur…',
              ),
            ),
          ],

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter cette compatibilité'),
          ),
        ],
      ),
    );
  }
}
// ── Compatibilités illisibles ─────────────────────────────────────────

/// Ce qui s'affiche quand les compatibilités existantes n'ont pas pu être
/// relues.
///
/// La tentation serait d'afficher une section vide et de laisser enregistrer :
/// l'écran aurait l'air de marcher, et le premier enregistrement effacerait
/// des compatibilités que personne n'a demandé à retirer. Mieux vaut un bloc
/// qui dit ce qui manque et pourquoi le reste de la fiche reste modifiable.
///
/// Le reste l'est vraiment : l'enregistrement omet alors la clé, et l'API ne
/// touche aux compatibilités que si elle la reçoit. Elles sont donc conservées
/// telles quelles — ce que ce bloc doit dire, sans quoi il inquiéterait pour
/// rien.
class CompatibilitesIllisibles extends StatelessWidget {
  final Object erreur;

  const CompatibilitesIllisibles({required this.erreur});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Compatibilités non relues',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Elles n\'ont pas pu être chargées et ne sont donc pas modifiables '
            'pour l\'instant. Elles seront conservées telles quelles : '
            'enregistrer les autres champs ne leur fera rien. Rouvrez cet '
            'écran une fois la connexion revenue pour y toucher.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onErrorContainer),
          ),
          const SizedBox(height: 6),
          Text(
            '$erreur',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onErrorContainer.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

// ── Compatibilités déclarées (lecture, staff) ─────────────────────────

/// Les véhicules qu'une pièce ou un accessoire déclare, tels qu'enregistrés.
///
/// Le staff ne voyait rien : le seul bloc de compatibilité d'une fiche est
/// réservé aux clients, et confronte l'article au garage de celui qui regarde.
/// Impossible, donc, de savoir ce que l'article déclare — ni de vérifier ce
/// qu'on venait d'y saisir.
///
/// Distinguer « déclarée » de « proposée » est le point de ce bloc. Le
/// remplissage automatique du catalogue a fabriqué des compatibilités
/// vraisemblables pour que la recherche par modèle rende quelque chose ; elles
/// n'ont été vérifiées par personne, et rien ne les distinguait d'une
/// compatibilité relue. Un client peut acheter la mauvaise pièce sur l'une
/// d'elles.
class CompatibilitesDeclarees extends StatelessWidget {
  /// Les lignes brutes de l'API. `null` : la fiche n'a pas encore été relue en
  /// entier — afficher « aucune » serait un mensonge, et un mensonge qui
  /// invite à saisir en double.
  final List<Map<String, dynamic>>? lignes;

  /// Ce que l'article ne remonte pas s'il ne déclare rien.
  final String rienDeclare;

  final VoidCallback onModifier;

  const CompatibilitesDeclarees({
    super.key,
    required this.lignes,
    required this.onModifier,
    this.rienDeclare =
        'Aucune compatibilité déclarée. L\'article ne remonte pas dans une '
        'recherche par véhicule.',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brutes = lignes;

    if (brutes == null) return const SizedBox.shrink();

    final entrees = brutes.map(FitmentEntry.depuisJson).toList();
    final proposees =
        entrees.where((e) => e.origin == FitmentOrigin.proposee).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text('Véhicules compatibles',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Modifier'),
              onPressed: onModifier,
            ),
          ],
        ),
        if (entrees.isEmpty)
          Text(
            rienDeclare,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
          )
        else ...[
          if (proposees > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                proposees == entrees.length
                    ? 'Toutes proposées automatiquement : aucune n\'a été vérifiée.'
                    : '$proposees sur ${entrees.length} proposées automatiquement, '
                        'non vérifiées.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: cs.error),
              ),
            ),
          ...entrees.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    e.origin == FitmentOrigin.proposee
                        ? Icons.help_outline
                        : Icons.check_circle_outline,
                    size: 15,
                    color: e.origin == FitmentOrigin.proposee
                        ? cs.outline
                        : cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.label,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
