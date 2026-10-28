import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../garage/data/models/owned_vehicle.dart';
import '../../garage/presentation/providers/garage_provider.dart';
import '../../vehicles/data/models/catalog_refs.dart';
import '../../vehicles/data/models/vehicle_classification_selection.dart';
import '../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../vehicles/presentation/widgets/vehicle_identity_fields.dart';
import '../data/private_listing_repository.dart';

class PrivateListingForm extends ConsumerStatefulWidget {
  const PrivateListingForm({super.key, this.existing, this.vehicle});
  final PrivateListing? existing;
  final OwnedVehicle? vehicle;
  @override
  ConsumerState<PrivateListingForm> createState() => _PrivateListingFormState();
}

class _PrivateListingFormState extends ConsumerState<PrivateListingForm> {
  final _formKey = GlobalKey<FormState>();
  final _inputs = <String, TextEditingController>{};
  final _freeModelController = TextEditingController();
  VehicleClassificationSelection _classification =
      VehicleClassificationSelection();
  ColorRef? _color;
  CatalogRefs? _boundRefs;
  bool _freeModel = false;
  PrivateListing? _saved;
  OwnedVehicle? _source;
  bool _busy = false, _whatsapp = false, _owner = false, _consent = false;
  bool _dirty = false;
  String? _error, _transmission;
  String? _editingSession;
  PrivateListingRepository get _repo =>
      ref.read(privateListingRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _saved = widget.existing;
    _source = widget.vehicle;
    for (final key in [
      'year',
      'mileage_km',
      'price',
      'city',
      'description',
      'seller_name',
    ]) {
      _inputs[key] = TextEditingController(text: _saved?.text(key) ?? '');
    }
    // ASYMETRIE VOULUE : on ECRIT `phone` et on LIT `phone_claimed`.
    //
    // Le serveur distingue deux numeros. `phone` dans la reponse est le numero
    // VERIFIE par un appel du personnel — vide tant que personne n'a appele, et
    // ce n'est pas au vendeur de le remplir. `phone_claimed` est ce qu'il a
    // tape. C'est donc `phone_claimed` qui revient dans le champ, et le champ
    // repart sous la cle `phone`, la seule que le formulaire ait le droit
    // d'ecrire.
    _inputs['phone'] = TextEditingController(
      text: _saved?.text('phone_claimed') ?? '',
    );
    _freeModelController.text = _saved?.text('model_libre') ?? '';
    _freeModel =
        _saved?.fields['vehicle_model_id'] == null &&
        _freeModelController.text.isNotEmpty;
    _transmission = _saved?.fields['transmission'] as String?;
    _whatsapp = _saved?.fields['whatsapp_enabled'] == true;
    if (_source != null) _prefill(_source!);
  }

  @override
  void dispose() {
    for (final controller in _inputs.values) {
      controller.dispose();
    }
    _freeModelController.dispose();
    super.dispose();
  }

  void _prefill(OwnedVehicle vehicle) {
    _source = vehicle;
    _boundRefs = null;
    _freeModelController.text = vehicle.modelLibre ?? '';
    _freeModel =
        vehicle.vehicleModelId == null && _freeModelController.text.isNotEmpty;
    _inputs['year']!.text = '${vehicle.year}';
    _inputs['mileage_km']!.text = vehicle.mileageKm?.toString() ?? '';
    _dirty = true;
  }

  int? _id(Object? value) => value == null || readListingInt(value) <= 0
      ? null
      : readListingInt(value);

  void _bindRefs(CatalogRefs refs) {
    if (identical(_boundRefs, refs)) return;
    final restoring = _boundRefs == null;
    _classification = VehicleClassificationSelection.fromIds(
      refs,
      brandId: restoring
          ? _id(_saved?.fields['brand_id']) ?? _source?.brandId
          : _classification.brand?.id,
      modelId: restoring
          ? _id(_saved?.fields['vehicle_model_id']) ?? _source?.vehicleModelId
          : _classification.model?.id,
      trimId: restoring
          ? _id(_saved?.fields['trim_id']) ?? _source?.trimId
          : _classification.trim?.id,
      engineTypeId: restoring
          ? _id(_saved?.fields['engine_type_id']) ?? _source?.engineTypeId
          : _classification.engineType?.id,
      drivetrainId: restoring
          ? _id(_saved?.fields['drivetrain_id']) ?? _source?.drivetrainId
          : _classification.drivetrain?.id,
    );
    final colorId = restoring
        ? _id(_saved?.fields['color_id']) ?? _source?.colorId
        : _color?.id;
    _color = refs.colors.where((entry) => entry.id == colorId).firstOrNull;
    _boundRefs = refs;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = messageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      final fields = <String, dynamic>{
        for (final entry in _inputs.entries) entry.key: entry.value.text.trim(),
        'whatsapp_enabled': _whatsapp,
        'brand_id': _classification.brand?.id,
        'vehicle_model_id': _classification.model?.id,
        'model_libre': _classification.model == null
            ? _freeModelController.text.trim()
            : null,
        'trim_id': _classification.trim?.id,
        'engine_type_id': _classification.engineType?.id,
        'drivetrain_id': _classification.drivetrain?.id,
        'color_id': _color?.id,
        'transmission': _transmission,
        if (_saved == null && _source != null) 'owned_vehicle_id': _source!.id,
      };
      final saved = await _repo.save(fields, id: _saved?.id);
      if (mounted) {
        setState(() {
          _saved = saved;
          _dirty = false;
        });
      }
    });
  }

  Future<void> _chooseGarage() async {
    await _run(() async {
      final vehicles = await ref.read(garageProvider.future);
      if (!mounted) return;
      if (vehicles.isEmpty) {
        setState(
          () => _error =
              'Votre garage est vide. Vous pouvez saisir le véhicule directement ici.',
        );
        return;
      }
      final selected = await showModalBottomSheet<OwnedVehicle>(
        context: context,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Choisir un véhicule de mon garage')),
              for (final vehicle in vehicles)
                ListTile(
                  title: Text(vehicle.displayName),
                  subtitle: Text('${vehicle.year}'),
                  onTap: () => Navigator.pop(context, vehicle),
                ),
            ],
          ),
        ),
      );
      if (mounted && selected != null) setState(() => _prefill(selected));
    });
  }

  Future<void> _upload() async {
    await _run(() async {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
        limit: 10,
      );
      if (files.isEmpty || !mounted) return;
      if (files.length + (_saved?.photos.length ?? 0) > 10) {
        throw StateError('Vous pouvez ajouter au plus 10 photos au total.');
      }
      // One image per request keeps a mobile upload below PHP's total body limit.
      for (final file in files) {
        final saved = await _repo.upload(_saved!.id, [file]);
        if (mounted) setState(() => _saved = saved);
      }
    });
  }


  Future<void> _submit() => _run(() async {
    if (_dirty) {
      throw StateError(
        'Enregistrez vos modifications avant d’envoyer l’annonce.',
      );
    }
    final saved = await _repo.action(
      _saved!.id,
      'submit',
      fields: {'owner_confirmed': _owner, 'contact_consent': _consent},
    );
    if (mounted) {
      setState(() => _saved = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Annonce envoyée. Vous retrouverez la décision dans « Mes annonces ».',
          ),
        ),
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (!auth.isClient) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vendre ma voiture')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.push('/login'),
            child: const Text('Se connecter pour vendre'),
          ),
        ),
      );
    }
    final session = auth.firebaseUser?.uid ?? 'client';
    _editingSession ??= session;
    if (_editingSession != session) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vendre ma voiture')),
        body: const Center(
          child: Text(
            'Le compte a changé. Fermez ce formulaire et rouvrez « Mes annonces ».',
          ),
        ),
      );
    }
    final references = ref.watch(catalogRefsProvider);
    return references.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Vendre ma voiture')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Vendre ma voiture')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(messageFor(error)),
                TextButton(
                  onPressed: () => ref.invalidate(catalogRefsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (refs) {
        _bindRefs(refs);
        return _buildForm(refs);
      },
    );
  }

  Widget _buildForm(CatalogRefs refs) {
    final saved = _saved;
    final editable = saved == null || saved.editable;
    final canSubmit =
        saved != null && const ['draft', 'rejected'].contains(saved.status);
    return Scaffold(
      appBar: AppBar(title: const Text('Vendre ma voiture')),
      body: Form(
        key: _formKey,
        onChanged: () {
          if (!_dirty) setState(() => _dirty = true);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Votre voiture, votre annonce',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text(
              'Une annonce en cours gratuite. Aucun compte partenaire nécessaire.',
            ),
            const SizedBox(height: 12),
            if (saved == null)
              OutlinedButton.icon(
                onPressed: _busy ? null : _chooseGarage,
                icon: const Icon(Icons.garage_outlined),
                label: const Text('Préremplir depuis mon garage'),
              ),
            const Text(
              'Votre garage reste privé. Seules les informations saisies ici seront publiées.',
            ),
            if (saved != null) Chip(label: Text(saved.statusLabel)),
            if (saved?.text('review_reason').isNotEmpty == true)
              Text(
                'À corriger : ${saved!.text('review_reason')}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            VehicleIdentityFields(
              refs: refs,
              selection: _classification,
              yearController: _inputs['year']!,
              mileageController: _inputs['mileage_km']!,
              freeModelController: _freeModelController,
              freeModel: _freeModel,
              enabled: editable && !_busy,
              onFreeModelChanged: (value) => setState(() {
                _freeModel = value;
                _dirty = true;
              }),
              onChanged: () => setState(() => _dirty = true),
              onModelChanged: () => setState(() {
                _transmission = null;
                _dirty = true;
              }),
              color: _color,
              onColorChanged: (value) => setState(() {
                _color = value;
                _dirty = true;
              }),
              transmission: _transmission,
              onTransmissionChanged: (value) => setState(() {
                _transmission = value;
                _dirty = true;
              }),
            ),
            _field('price', 'Prix en FCFA', numeric: true, enabled: editable),
            _field('city', 'Ville', maxLength: 100, enabled: editable),
            _field(
              'description',
              'État du véhicule et informations utiles',
              maxLength: 5000,
              lines: 4,
              enabled: editable,
            ),
            _field(
              'seller_name',
              'Nom affiché aux acheteurs',
              maxLength: 80,
              enabled: editable,
            ),
            _field(
              'phone',
              'Téléphone avec indicatif',
              maxLength: 20,
              enabled: editable,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Être contacté sur WhatsApp'),
              value: _whatsapp,
              onChanged: !editable || _busy
                  ? null
                  : (value) => setState(() {
                      _whatsapp = value;
                      _dirty = true;
                    }),
            ),
            if (editable)
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  saved == null
                      ? 'Enregistrer le brouillon'
                      : 'Enregistrer les modifications',
                ),
              ),
            if (saved?.status == 'published' || saved?.status == 'pending')
              const Text(
                'Une modification remettra l’annonce en brouillon et demandera une nouvelle validation.',
              ),
            if (saved != null) ...[
              const Divider(height: 32),
              Text(
                'Photos (${saved.photos.length}/10)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'La première photo sera la couverture. Ajoutez uniquement des photos destinées à être publiques.',
              ),
              for (final photo in saved.photos)
                ListTile(
                  leading: SizedBox(
                    width: 64,
                    child: Image.network(
                      '${photo['url']}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_outlined),
                    ),
                  ),
                  title: const Text('Photo du véhicule'),
                  trailing: !editable
                      ? null
                      : IconButton(
                          tooltip: 'Supprimer la photo',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  await _repo.deletePhoto(
                                    saved.id,
                                    readListingInt(photo['id']),
                                  );
                                  final updated = await _repo.getOwned(
                                    saved.id,
                                  );
                                  if (mounted) setState(() => _saved = updated);
                                }),
                        ),
                ),
              if (editable && saved.photos.length < 10)
                OutlinedButton.icon(
                  onPressed: _busy || _dirty ? null : _upload,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Ajouter des photos'),
                ),
            ],
            if (canSubmit) ...[
              const Divider(height: 32),
              Text(
                'Avant la mise en ligne',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Une personne d’AutoParc vous appellera au numéro indiqué pour '
                'confirmer que l’annonce vient bien de vous. Votre numéro ne '
                'sera affiché aux acheteurs qu’après cet appel.',
              ),
              if (_saved?.phoneVerified ?? false)
                Text('Numéro vérifié : ${_saved!.verifiedPhone}'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _owner,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _owner = v ?? false),
                title: const Text(
                  'Je suis propriétaire de ce véhicule ou autorisé à le vendre.',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _consent = v ?? false),
                title: const Text(
                  'J’accepte que mon nom affiché et mon téléphone vérifié soient publics sur cette annonce.',
                ),
              ),
              FilledButton(
                onPressed:
                    _busy ||
                        _dirty ||
                        !_owner ||
                        !_consent ||
                        saved.photos.isEmpty
                    ? null
                    : _submit,
                child: const Text('Envoyer pour validation'),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    bool numeric = false,
    int? maxLength,
    int lines = 1,
    bool enabled = true,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: _inputs[key],
      enabled: enabled && !_busy,
      maxLength: maxLength,
      maxLines: lines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Renseignez ce champ.';
        if (key == 'description' && text.length < 20) {
          return 'Décrivez le véhicule en au moins 20 caractères.';
        }
        // LE GARDE DU NUMERO VIT ICI, et pas dans une exception.
        //
        // Il refusait auparavant depuis `_sendCode`, par un StateError dont
        // `messageFor` jetait le texte : l'ecran affichait « Une erreur est
        // survenue » et le vendeur ne savait pas qu'il manquait « +226 ». Dans
        // le `validator`, Material pose la phrase SOUS le champ fautif, et
        // c'est le meme format que le serveur exige — un numero qu'on ne peut
        // pas composer ne vaut rien a qui doit appeler.
        if (key == 'phone' && !RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(text)) {
          return 'Indiquez le numéro avec l’indicatif, par exemple +22670000000.';
        }
        if (numeric) {
          final number = int.tryParse(text);
          if (number == null || number < (key == 'mileage_km' ? 0 : 1)) {
            return 'Saisissez un nombre entier valide.';
          }
          if (key == 'year' &&
              (number < 1900 || number > DateTime.now().year + 1)) {
            return 'Vérifiez l’année.';
          }
        }
        return null;
      },
    ),
  );
}
