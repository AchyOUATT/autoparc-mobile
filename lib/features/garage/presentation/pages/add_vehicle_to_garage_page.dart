import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../data/engine_data.dart';
import '../providers/garage_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/vin_decode_provider.dart';
import '../../data/models/vin_decode_result.dart';
import '../../../vehicles/data/models/catalog_refs.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AddVehicleToGaragePage extends ConsumerStatefulWidget {
  const AddVehicleToGaragePage({super.key});

  @override
  ConsumerState<AddVehicleToGaragePage> createState() =>
      _AddVehicleToGaragePageState();
}

class _AddVehicleToGaragePageState
    extends ConsumerState<AddVehicleToGaragePage> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  // Champs de formulaire
  BrandRef?      _brand;
  ModelRef?      _model;
  TrimRef?       _trim;
  EngineTypeRef? _engineType;
  ColorRef?      _color;

  /// Code moteur issu du décodage VIN NHTSA (ex: "1NZ", "K20").
  /// Optionnel — transmis tel quel au backend, non affiché dans le formulaire.
  String? _engineCode;

  final _yearCtrl     = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _plateCtrl    = TextEditingController();
  final _mileageCtrl  = TextEditingController();
  final _vinCtrl      = TextEditingController();

  // Suivi des champs pré-remplis par le décodage VIN (pour le style visuel)
  final _prefilledFields = <String>{};

  @override
  void dispose() {
    for (final c in [_yearCtrl, _nicknameCtrl, _plateCtrl, _mileageCtrl, _vinCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Décodage VIN ──────────────────────────────────────────────────

  void _onVinChanged(String value, CatalogRefs refs) {
    if (value.trim().length == 17) {
      ref.read(vinDecodeProvider.notifier).decode(value);
    } else if (value.trim().isEmpty) {
      ref.read(vinDecodeProvider.notifier).reset();
    }
  }

  /// Applique les résultats du décodage aux champs du formulaire.
  void _applyVinResult(VinDecodeResult result, CatalogRefs refs) {
    _prefilledFields.clear();

    // Année
    if (result.bestYear != null) {
      _yearCtrl.text = result.bestYear.toString();
      _prefilledFields.add('year');
    }

    // Marque → lookup dans CatalogRefs par id
    if (result.brand != null) {
      final brand = refs.brands
          .where((b) => b.id == result.brand!.id && b.isActive)
          .firstOrNull;
      if (brand != null) {
        _brand = brand;
        _model = null;
        _trim  = null;
        _prefilledFields.add('brand');
      }
    }

    // Modèle → lookup dans CatalogRefs par id (après avoir fixé la marque)
    if (result.vehicleModel != null && _brand != null) {
      final model = refs.modelsForBrand(_brand!.id)
          .where((m) => m.id == result.vehicleModel!.id)
          .firstOrNull;
      if (model != null) {
        _model = model;
        _prefilledFields.add('model');
      }
    }

    // Motorisation
    if (result.engineType != null) {
      final eng = refs.engineTypes
          .where((e) => e.id == result.engineType!.id)
          .firstOrNull;
      if (eng != null) {
        _engineType = eng;
        _prefilledFields.add('engine');
      }
    }

    // Code moteur NHTSA (optionnel — non affiché, transmis silencieusement)
    // Priorité : EngineCode NHTSA complet > char 8 VIN (moins précis)
    final nhtsaCode = result.nhtsa?.engineCodeNhtsa;
    final vinChar8  = result.engineCode; // char 8 du VIN
    _engineCode = (nhtsaCode != null && nhtsaCode.isNotEmpty)
        ? nhtsaCode
        : (vinChar8 != null && vinChar8.isNotEmpty ? vinChar8 : null);

    setState(() {});
  }

  /// Vrai si le serveur pourra calculer la compatibilité de ce véhicule.
  bool get _motorisationConnue => motorisationResolue(
        engineType: _engineType,
        trim:       _trim,
        engineCode: _engineCode,
      );

  // ── Soumission du formulaire ───────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_brand == null) { _snack('Veuillez sélectionner une marque.'); return; }
    if (_model == null) { _snack('Veuillez sélectionner un modèle.'); return; }

    // Le compte n'est demandé qu'ici, une fois la saisie faite. Le réclamer
    // d'entrée fait renoncer avant d'avoir rien montré ; le réclamer après
    // coup, sans rien conserver, fait perdre dix champs. La connexion s'ouvre
    // par-dessus ce formulaire, qui reste vivant en dessous : au retour, la
    // saisie est intacte et l'enregistrement reprend tout seul.
    if (!ref.read(authProvider).isClient) {
      final connecte = await _demanderConnexion();
      if (!connecte) return;
    }

    setState(() => _submitting = true);

    final payload = <String, dynamic>{
      'brand_id':           _brand!.id,
      'vehicle_model_id':   _model!.id,
      'manufacturing_year': int.parse(_yearCtrl.text),
      if (_trim != null)        'trim_id':        _trim!.id,
      if (_engineType != null)  'engine_type_id': _engineType!.id,
      if (_color != null)       'color_id':       _color!.id,
      if (_nicknameCtrl.text.trim().isNotEmpty) 'nickname':     _nicknameCtrl.text.trim(),
      if (_plateCtrl.text.trim().isNotEmpty)    'plate_number': _plateCtrl.text.trim().toUpperCase(),
      if (_mileageCtrl.text.isNotEmpty)         'mileage_km':   int.parse(_mileageCtrl.text),
      if (_vinCtrl.text.trim().isNotEmpty)      'vin':          _vinCtrl.text.trim().toUpperCase(),
      // engine_code issu du décodage VIN — optionnel, améliore la recherche de pièces
      if (_engineCode != null && _engineCode!.isNotEmpty) 'engine_code': _engineCode!.toUpperCase(),
    };

    final error = await ref.read(garageProvider.notifier).addVehicle(payload);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      _snack(error, isError: true);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Explique pourquoi un compte est nécessaire, puis ouvre la connexion.
  ///
  /// L'explication n'est pas de la politesse : arriver sur un écran de
  /// connexion sans savoir pourquoi donne l'impression d'un péage. Dire que
  /// les rappels ont besoin d'un destinataire, c'est rappeler ce qu'on vient
  /// justement de gagner en remplissant le formulaire.
  Future<bool> _demanderConnexion() async {
    final veutSeConnecter = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Un compte pour vos rappels'),
        content: const Text(
          'Visite technique, assurance, vidange : ces rappels vous sont '
          'envoyés, il faut donc savoir à qui.\n\n'
          'Votre saisie est conservée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );

    if (veutSeConnecter != true || !mounted) return false;

    // `push` : l'écran de connexion se pose au-dessus, ce formulaire reste
    // monté en dessous avec ses valeurs.
    await context.push('/login');

    if (!mounted) return false;

    final connecte = ref.read(authProvider).isClient;

    if (!connecte) {
      _snack('Connexion annulée — votre saisie est conservée.');
    }

    return connecte;
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError
          ? Theme.of(context).colorScheme.error
          : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final refsAsync = ref.watch(catalogRefsProvider);
    final vinState  = ref.watch(vinDecodeProvider);

    // Quand un nouveau résultat arrive, on l'applique une fois
    ref.listen<VinDecodeState>(vinDecodeProvider, (prev, next) {
      final result = next.result.valueOrNull;
      if (result != null && result.valid) {
        final refs = refsAsync.valueOrNull;
        if (refs != null) _applyVinResult(result, refs);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter à mon garage'),
        centerTitle: false,
      ),
      body: refsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text('Impossible de charger les références : $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(catalogRefsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (refs) => _buildForm(refs, vinState),
      ),
    );
  }

  Widget _buildForm(CatalogRefs refs, VinDecodeState vinState) {
    final models = _brand != null ? refs.modelsForBrand(_brand!.id) : <ModelRef>[];
    final trims  = _model != null ? refs.trimsForModel(_model!.id)  : <TrimRef>[];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [

              // ═══════════════════════════════════════════════════════
              // 1. Bloc VIN — scan automatique
              // ═══════════════════════════════════════════════════════
              _VinScanBlock(
                controller: _vinCtrl,
                vinState:   vinState,
                onChanged:  (v) => _onVinChanged(v, refs),
                onDecodePressed: () =>
                    ref.read(vinDecodeProvider.notifier).decode(_vinCtrl.text),
              ),

              // Bandeau de confiance (visible seulement après décodage)
              if (vinState.hasResult) ...[
                const SizedBox(height: 12),
                _ConfidenceBanner(result: vinState.result.valueOrNull!),
              ],

              const SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════
              // 2. Identification obligatoire
              // ═══════════════════════════════════════════════════════
              _SectionTitle('Identification'),
              const SizedBox(height: 16),

              // Marque
              _PrefilledDropdown<BrandRef>(
                prefilled: _prefilledFields.contains('brand'),
                child: DropdownButtonFormField<BrandRef>(
                  value: _brand,
                  decoration: const InputDecoration(labelText: 'Marque *'),
                  isExpanded: true,
                  hint: const Text('Sélectionner…'),
                  items: refs.brands
                      .where((b) => b.isActive)
                      .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                      .toList(),
                  onChanged: (b) => setState(() {
                    _brand = b;
                    _model = null;
                    _trim  = null;
                    _prefilledFields.remove('brand');
                    _prefilledFields.remove('model');
                  }),
                  validator: (v) => v == null ? 'Marque obligatoire' : null,
                ),
              ),
              const SizedBox(height: 12),

              // Modèle
              _PrefilledDropdown<ModelRef>(
                prefilled: _prefilledFields.contains('model'),
                child: DropdownButtonFormField<ModelRef>(
                  value: _model,
                  decoration: const InputDecoration(labelText: 'Modèle *'),
                  isExpanded: true,
                  hint: Text(_brand == null
                      ? 'Choisir d\'abord une marque'
                      : 'Sélectionner…'),
                  items: models
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName)))
                      .toList(),
                  onChanged: _brand == null
                      ? null
                      : (m) => setState(() {
                            _model = m;
                            _trim  = null;
                            _prefilledFields.remove('model');
                          }),
                  validator: (v) => v == null ? 'Modèle obligatoire' : null,
                ),
              ),
              const SizedBox(height: 12),

              // Année
              _PrefilledField(
                prefilled: _prefilledFields.contains('year'),
                child: TextFormField(
                  controller: _yearCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Année de fabrication *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (_) => _prefilledFields.remove('year'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Année obligatoire';
                    final y = int.tryParse(v);
                    if (y == null || y < 1950 || y > DateTime.now().year + 1) {
                      return 'Année invalide';
                    }
                    return null;
                  },
                ),
              ),

              // Avertissement si plusieurs années candidates
              if (vinState.hasResult &&
                  (vinState.result.valueOrNull?.yearCandidates.length ?? 0) > 1)
                _YearCandidatesHint(
                  candidates: vinState.result.valueOrNull!.yearCandidates,
                  onSelect: (y) {
                    setState(() {
                      _yearCtrl.text = y.toString();
                      _prefilledFields.add('year');
                    });
                  },
                ),

              const SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════
              // 3. Motorisation
              // ═══════════════════════════════════════════════════════
              //
              // Sortie de « Détails (optionnels) », où elle était rangée sous
              // un titre qui invitait à la sauter. Elle reste facultative — on
              // n'a pas le droit de bloquer quelqu'un qui ignore sa
              // motorisation — mais elle n'est pas un détail : c'est elle qui
              // décide de la compatibilité des pièces, cote serveur, via
              // `effective_engine_type_id`.
              _SectionTitle('Motorisation'),
              const SizedBox(height: 4),
              Text(
                'C\'est elle qui détermine quelles pièces vont sur votre '
                'véhicule. La finition suffit souvent à la déduire.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),

              // Finition
              if (trims.isNotEmpty) ...[
                DropdownButtonFormField<TrimRef>(
                  value: _trim,
                  decoration: const InputDecoration(labelText: 'Finition'),
                  isExpanded: true,
                  hint: const Text('Sélectionner…'),
                  items: trims
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (t) => setState(() => _trim = t),
                ),
                const SizedBox(height: 12),
              ],

              // Motorisation
              _PrefilledDropdown<EngineTypeRef>(
                prefilled: _prefilledFields.contains('engine'),
                child: DropdownButtonFormField<EngineTypeRef>(
                  value: _engineType,
                  decoration: InputDecoration(
                    labelText: 'Carburant',
                    suffixIcon: _engineType != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _engineType = null;
                              _prefilledFields.remove('engine');
                            }),
                          )
                        : null,
                  ),
                  isExpanded: true,
                  hint: const Text('Sélectionner…'),
                  items: refs.engineTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  onChanged: (e) => setState(() {
                    _engineType = e;
                    _prefilledFields.remove('engine');
                  }),
                ),
              ),

              // Conséquence, dite ici et non à l'enregistrement : la personne
              // a encore le champ sous les yeux et peut y répondre. Une boîte
              // de dialogue au moment d'enregistrer arriverait après l'effort,
              // pour un reproche qu'on ne peut pas toujours satisfaire.
              const SizedBox(height: 8),
              _CompatibiliteHint(resolue: _motorisationConnue),

              const SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════
              // 4. Détails optionnels
              // ═══════════════════════════════════════════════════════
              _SectionTitle('Détails (optionnels)'),
              const SizedBox(height: 16),

              // Couleur
              DropdownButtonFormField<ColorRef>(
                value: _color,
                decoration: const InputDecoration(labelText: 'Couleur'),
                isExpanded: true,
                hint: const Text('Sélectionner…'),
                items: refs.colors
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (c) => setState(() => _color = c),
              ),
              const SizedBox(height: 12),

              // Surnom
              TextFormField(
                controller: _nicknameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Surnom',
                  hintText: 'Ex. : Ma Corolla, La familiale…',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
              ),
              const SizedBox(height: 4),

              // Plaque
              TextFormField(
                controller: _plateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Plaque d\'immatriculation',
                  hintText: 'Ex. : AA 1234 BF',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 30,
              ),
              const SizedBox(height: 4),

              // Kilométrage
              TextFormField(
                controller: _mileageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kilométrage actuel',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.speed),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════════
              // 4. Bouton Ajouter
              // ═══════════════════════════════════════════════════════
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.garage_outlined),
                label: Text(_submitting
                    ? 'Enregistrement…'
                    : 'Ajouter à mon garage'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires
// ─────────────────────────────────────────────────────────────────────────────

/// Titre de section.
/// Dit, sous le champ, ce que son absence coûtera.
///
/// Deux états et non un seul : confirmer que c'est bon vaut autant qu'avertir
/// que ça ne l'est pas — sans le retour vert, on ne sait pas si choisir une
/// finition a suffi, et on croit le champ toujours vide.
class _CompatibiliteHint extends StatelessWidget {
  const _CompatibiliteHint({required this.resolue});

  final bool resolue;

  @override
  Widget build(BuildContext context) {
    final couleur = resolue ? const Color(0xFF2E7D32) : const Color(0xFF8A5A00);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          resolue ? Icons.check_circle_outline : Icons.info_outline,
          size: 16,
          color: couleur,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            resolue
                ? 'Les pièces compatibles avec ce véhicule pourront être filtrées.'
                : 'Sans cette information, la liste des pièces compatibles '
                    'restera vide. Vous pourrez la compléter plus tard depuis '
                    'votre garage.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: couleur),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      );
}

/// Entoure un champ texte d'une bordure verte subtile s'il a été pré-rempli.
class _PrefilledField extends StatelessWidget {
  final bool prefilled;
  final Widget child;
  const _PrefilledField({required this.prefilled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!prefilled) return child;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

/// Idem pour les Dropdown.
class _PrefilledDropdown<T> extends StatelessWidget {
  final bool prefilled;
  final Widget child;
  const _PrefilledDropdown({required this.prefilled, required this.child});

  @override
  Widget build(BuildContext context) => _PrefilledField(
        prefilled: prefilled,
        child: child,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bloc saisie VIN
// ─────────────────────────────────────────────────────────────────────────────

class _VinScanBlock extends StatelessWidget {
  final TextEditingController controller;
  final VinDecodeState vinState;
  final ValueChanged<String> onChanged;
  final VoidCallback onDecodePressed;

  const _VinScanBlock({
    required this.controller,
    required this.vinState,
    required this.onChanged,
    required this.onDecodePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre avec badge "Nouveau"
        Row(
          children: [
            const Icon(Icons.qr_code_2, size: 20),
            const SizedBox(width: 8),
            Text(
              'Décodage automatique par VIN',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'BETA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Saisissez le VIN (numéro de châssis, 17 caractères) et le formulaire sera pré-rempli automatiquement.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),

        // Champ VIN + bouton décoder
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'VIN (numéro de châssis)',
                  hintText: 'JTDBE30K453012345',
                  prefixIcon: const Icon(Icons.numbers),
                  // Icône d'état à droite
                  suffixIcon: _VinStatusIcon(vinState: vinState),
                  helperText: controller.text.isNotEmpty
                      ? '${controller.text.trim().length}/17 caractères'
                      : null,
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 17,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null, // on gère le compteur via helperText
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-HJ-NPR-Z0-9a-hj-npr-z]')),
                  LengthLimitingTextInputFormatter(17),
                  _UpperCaseFormatter(),
                ],
                onChanged: onChanged,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length != 17) {
                    return 'Le VIN doit faire exactement 17 caractères.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton.tonal(
                onPressed: vinState.isLoading ? null : onDecodePressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 56),
                  padding: EdgeInsets.zero,
                ),
                child: vinState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, size: 20),
                          Text('Décoder', style: TextStyle(fontSize: 11)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Icône d'état dans le champ VIN (spinner / check / erreur).
class _VinStatusIcon extends StatelessWidget {
  final VinDecodeState vinState;
  const _VinStatusIcon({required this.vinState});

  @override
  Widget build(BuildContext context) {
    if (vinState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final result = vinState.result.valueOrNull;
    if (result == null) return const SizedBox.shrink();

    if (!result.valid) {
      return const Icon(Icons.error_outline, color: Colors.red);
    }

    return Icon(
      Icons.check_circle_outline,
      color: result.hasMatches ? Colors.green : Colors.orange,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bandeau de confiance
// ─────────────────────────────────────────────────────────────────────────────

class _ConfidenceBanner extends StatelessWidget {
  final VinDecodeResult result;
  const _ConfidenceBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.valid) {
      return _Banner(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'VIN invalide',
        subtitle: result.warnings.isNotEmpty ? result.warnings.first : null,
      );
    }

    final (icon, color, title, subtitle) = switch (result.confidence) {
      'high' => (
          Icons.verified_outlined,
          Colors.green,
          'Formulaire pré-rempli',
          'Vérifiez et complétez si nécessaire.',
        ),
      'medium' => (
          Icons.info_outline,
          Colors.orange,
          'Pré-remplissage partiel',
          'Certains champs n\'ont pas pu être résolus — vérifiez.',
        ),
      'low' => (
          Icons.warning_amber_outlined,
          Colors.amber.shade700,
          'Données limitées',
          result.nhtsa == null
              ? 'API NHTSA inaccessible — seule l\'année a été décodée localement.'
              : 'Marque ou modèle introuvable dans le catalogue — saisissez manuellement.',
        ),
      _ => (
          Icons.help_outline,
          Colors.grey,
          'Aucune correspondance',
          'Remplissez le formulaire manuellement.',
        ),
    };

    final warnings = result.warnings
        .where((w) => !w.contains('inaccessible')) // déjà dans subtitle si low
        .toList();

    return Column(
      children: [
        _Banner(icon: icon, color: color, title: title, subtitle: subtitle),
        for (final w in warnings)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _Banner(
              icon: Icons.info_outline,
              color: Colors.blueGrey,
              title: w,
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint années candidates
// ─────────────────────────────────────────────────────────────────────────────

/// Affiché quand le VIN a 2 années candidates (cycles 30 ans) :
/// chips cliquables pour choisir rapidement.
class _YearCandidatesHint extends StatelessWidget {
  final List<int> candidates;
  final ValueChanged<int> onSelect;

  const _YearCandidatesHint({
    required this.candidates,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        children: [
          Text(
            'Deux années possibles — choisissez :',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          ...candidates.map(
            (y) => ActionChip(
              label: Text('$y'),
              onPressed: () => onSelect(y),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatter
// ─────────────────────────────────────────────────────────────────────────────

/// Convertit la saisie en majuscules à la volée.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
