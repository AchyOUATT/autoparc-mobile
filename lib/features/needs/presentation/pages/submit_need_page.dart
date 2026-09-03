import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/needs_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Page ─────────────────────────────────────────────────────────────────

class SubmitNeedPage extends ConsumerStatefulWidget {
  const SubmitNeedPage({super.key});

  @override
  ConsumerState<SubmitNeedPage> createState() => _SubmitNeedPageState();
}

class _SubmitNeedPageState extends ConsumerState<SubmitNeedPage> {
  final _formKey = GlobalKey<FormState>();

  // Critères véhicule
  int?    _brandId;
  int?    _vehicleModelId;
  String? _bodyStyle;
  final _yearMinCtrl = TextEditingController();
  final _yearMaxCtrl = TextEditingController();

  // Champs communs
  final _descCtrl   = TextEditingController();
  final _budgetCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _yearMinCtrl.dispose();
    _yearMaxCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _onBrandChanged(int? brandId) {
    setState(() {
      _brandId        = brandId;
      _vehicleModelId = null; // réinitialise le modèle quand la marque change
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth   = ref.read(authProvider);
    final yearMin = int.tryParse(_yearMinCtrl.text.trim());
    final yearMax = int.tryParse(_yearMaxCtrl.text.trim());

    final payload = <String, dynamic>{
      'description': _descCtrl.text.trim(),
      // firebase_uid envoyé uniquement pour les clients Firebase
      if (auth.isClient && auth.firebaseUser != null)
        'firebase_uid': auth.firebaseUser!.uid,
      if (_budgetCtrl.text.isNotEmpty)
        'budget_max': double.parse(_budgetCtrl.text.replaceAll(RegExp(r'\s'), '')),
      // Critères structurés (tous optionnels)
      if (_brandId        != null) 'brand_id':         _brandId,
      if (_vehicleModelId != null) 'vehicle_model_id': _vehicleModelId,
      if (_bodyStyle      != null) 'body_style':       _bodyStyle,
      if (yearMin         != null) 'year_min':         yearMin,
      if (yearMax         != null) 'year_max':         yearMax,
    };

    try {
      await ref.read(needsRepositoryProvider).submitNeed(payload);
      if (mounted) _showSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Besoin enregistré !'),
        content: const Text(
          'Nous avons bien reçu votre demande.\n'
          'Notre équipe vous contactera dès qu\'une offre correspondante sera disponible.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // ── Garde : connexion requise (client OU staff) ───────────────────────
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exprimer un besoin'), centerTitle: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Connexion requise',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vous devez être connecté pour déposer un besoin.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exprimer un besoin'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [

                // ── En-tête ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous ne trouvez pas le véhicule que vous cherchez ? '
                          'Déposez votre besoin — nous vous contacterons '
                          'dès qu\'une offre correspondante sera disponible.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Critères véhicule ──────────────────────────────────
                _VehicleCriteriaSection(
                  brandId:        _brandId,
                  vehicleModelId: _vehicleModelId,
                  bodyStyle:      _bodyStyle,
                  yearMinCtrl:    _yearMinCtrl,
                  yearMaxCtrl:    _yearMaxCtrl,
                  onBrandChanged:     _onBrandChanged,
                  onModelChanged:     (v) => setState(() => _vehicleModelId = v),
                  onBodyStyleChanged: (v) => setState(() => _bodyStyle      = v),
                ),

                const SizedBox(height: 24),

                // ── Description ────────────────────────────────────────
                _label(context, 'Description du besoin *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Couleur préférée, options souhaitées, '
                        'kilométrage maximum, tout autre détail…',
                  ),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Décrivez votre besoin (10 caractères minimum).'
                      : null,
                ),

                const SizedBox(height: 20),

                // ── Budget ─────────────────────────────────────────────
                _label(context, 'Budget maximum (optionnel)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '0',
                    suffixText: 'FCFA',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (double.tryParse(v) == null) return 'Montant invalide';
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // ── Badge compte connecté ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Connecté en tant que ${auth.displayName} — '
                          'votre demande sera liée à votre compte.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined),
                  label: const Text('Soumettre mon besoin'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
  );
}

// ── Section critères véhicule ─────────────────────────────────────────────

class _VehicleCriteriaSection extends ConsumerWidget {
  final int?    brandId;
  final int?    vehicleModelId;
  final String? bodyStyle;
  final TextEditingController yearMinCtrl;
  final TextEditingController yearMaxCtrl;
  final void Function(int?)    onBrandChanged;
  final void Function(int?)    onModelChanged;
  final void Function(String?) onBodyStyleChanged;

  const _VehicleCriteriaSection({
    required this.brandId,
    required this.vehicleModelId,
    required this.bodyStyle,
    required this.yearMinCtrl,
    required this.yearMaxCtrl,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onBodyStyleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(publicBrandsProvider);
    final modelsAsync = brandId != null
        ? ref.watch(publicModelsProvider(brandId!))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Row(
          children: [
            Icon(Icons.tune_outlined,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Critères du véhicule recherché',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'optionnel',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Plus vous précisez, mieux nous ciblons les offres.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Divider(height: 20),

        // ── Marque ───────────────────────────────────────────────────
        Text('Marque', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        brandsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error:   (_, __) => const Text('Impossible de charger les marques.'),
          data: (brands) => DropdownButtonFormField<int?>(
            key: ValueKey('brands_${brands.length}'),
            value: brandId,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Toutes marques',
              prefixIcon: Icon(Icons.branding_watermark_outlined),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Toutes marques')),
              ...brands.map((b) => DropdownMenuItem(
                value: b.id,
                child: Text(b.name),
              )),
            ],
            onChanged: onBrandChanged,
          ),
        ),

        // ── Modèle (cascade sur la marque) ───────────────────────────
        if (brandId != null) ...[
          const SizedBox(height: 16),
          Text('Modèle', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          modelsAsync!.when(
            loading: () => const LinearProgressIndicator(),
            error:   (_, __) => const Text('Impossible de charger les modèles.'),
            data: (models) => models.isEmpty
                ? const Text('Aucun modèle disponible pour cette marque.')
                : DropdownButtonFormField<int?>(
                    key: ValueKey('models_${brandId}_${models.length}'),
                    value: vehicleModelId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'Tous modèles',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous modèles')),
                      ...models.map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.name),
                      )),
                    ],
                    onChanged: onModelChanged,
                  ),
          ),
        ],

        const SizedBox(height: 20),

        // ── Carrosserie ──────────────────────────────────────────────
        Text('Carrosserie', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _ChipGroup<String?>(
          options: const [
            (value: null,          label: 'Peu importe'),
            (value: 'sedan',       label: 'Berline'),
            (value: 'hatchback',   label: 'Compacte'),
            (value: 'suv',         label: 'SUV'),
            (value: 'estate',      label: 'Break'),
            (value: 'coupe',       label: 'Coupé'),
            (value: 'convertible', label: 'Cabriolet'),
            (value: 'pickup',      label: 'Pick-up'),
            (value: 'van',         label: 'Camionnette'),
            (value: 'minibus',     label: 'Minibus'),
            (value: 'bus',         label: 'Bus'),
            (value: 'truck',       label: 'Camion'),
          ],
          selected: bodyStyle,
          onChanged: onBodyStyleChanged,
        ),

        const SizedBox(height: 20),

        // ── Année ────────────────────────────────────────────────────
        Text('Année', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: yearMinCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  labelText: 'De',
                  hintText: '2000',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final y = int.tryParse(v);
                  if (y == null || y < 1950 || y > DateTime.now().year) {
                    return 'Année invalide (1950–${DateTime.now().year})';
                  }
                  return null;
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('—'),
            ),
            Expanded(
              child: TextFormField(
                controller: yearMaxCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  labelText: 'À',
                  hintText: '${DateTime.now().year}',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final y = int.tryParse(v);
                  if (y == null || y < 1950 || y > DateTime.now().year) {
                    return 'Année invalide (1950–${DateTime.now().year})';
                  }
                  final minText = yearMinCtrl.text.trim();
                  if (minText.isNotEmpty) {
                    final minY = int.tryParse(minText);
                    if (minY != null && y < minY) return 'Doit être ≥ année de départ';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────

class _ChipGroup<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T selected;
  final void Function(T) onChanged;

  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: options.map((opt) => ChoiceChip(
      label: Text(opt.label),
      selected: selected == opt.value,
      onSelected: (_) => onChanged(opt.value),
    )).toList(),
  );
}
