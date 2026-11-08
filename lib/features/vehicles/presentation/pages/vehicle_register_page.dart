import 'dart:convert';

import '../../../catalog/presentation/catalog_reference_labels.dart';
import '../../../../core/l10n/reference_labels.dart';
import '../../../../core/l10n/transmission_labels.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_fr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/catalog_refs.dart';
import '../../data/models/fault_declaration.dart';
import '../../data/models/vehicle_classification_selection.dart';
import '../../data/vehicle_fault_repository.dart';
import '../providers/vehicle_refs_provider.dart';
import '../../data/vehicle_admin_repository.dart';
import 'vehicle_form_mode.dart';
// Le depot de l'ESPACE partenaire, a ne pas confondre avec l'annuaire des
// partenaires du personnel importe plus bas : les deux exposent un
// `partnerRepositoryProvider`, d'ou l'alias.
import '../../../../features/partner_accounts/data/partner_repository.dart'
    as espace;
import '../../../../features/partner_accounts/presentation/marge_recapitulatif.dart';
import '../../../../features/partner_accounts/presentation/champs_de_promotion.dart'
    as espace;
import '../../../../features/partner_accounts/presentation/partner_session.dart'
    as espace;
import '../../../../core/api/api_exception.dart';
import '../widgets/vehicle_reference_dropdown.dart';
import '../widgets/fault_declaration_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/transmission_selector.dart';
import '../../../../shared/presentation/pages/media_upload_page.dart';
import '../../../../shared/data/media_repository.dart';
import '../../../../features/catalog/data/models/vehicle.dart';
import '../../../../features/catalog/presentation/providers/catalog_providers.dart';
import '../../../../features/partners/data/models/partner.dart';
import '../../../../features/partners/data/partner_repository.dart';

// ── Provider partenaires pour le formulaire ──────────────────────
final _vehiclePartnersProvider = FutureProvider.autoDispose<List<Partner>>((
  ref,
) async {
  final page = await ref
      .read(partnerRepositoryProvider)
      .getPartners(perPage: 200);
  return page.data;
});

// ════════════════════════════════════════════════════════════════════
// Page
// ════════════════════════════════════════════════════════════════════

class VehicleRegisterPage extends ConsumerStatefulWidget {
  final Vehicle? existing; // null → création, non-null → édition

  /// Pour qui ce formulaire est ouvert. Voir [VehicleFormMode] : le defaut
  /// garde le comportement du back-office, et c'est l'espace partenaire qui
  /// demande explicitement l'autre.
  final VehicleFormMode mode;

  const VehicleRegisterPage({
    super.key,
    this.existing,
    this.mode = VehicleFormMode.personnel,
  });

  @override
  ConsumerState<VehicleRegisterPage> createState() =>
      _VehicleRegisterPageState();
}

class _VehicleRegisterPageState extends ConsumerState<VehicleRegisterPage> {
  AppLocalizations get l10n => AppLocalizations.of(context);

  /// Un formulaire PAR ETAPE, et non un seul pour les quatre.
  ///
  /// ── CE QUE LE `Stepper` GARDE DANS L'ARBRE ───────────────────────────
  ///
  /// Toutes les étapes, pas seulement la courante : leur contenu est monté
  /// puis masqué. Mesuré — `vehicle_classification_test.dart` atteint les
  /// champs de tarif de l'étape 3 alors que la page est sur l'étape 0.
  ///
  /// Un `Form` unique autour du `Stepper` validerait donc les QUATRE étapes à
  /// la fois : avancer de la première exigerait un prix de vente qui n'a même
  /// pas encore été demandé. C'est pourquoi la validation par champ n'était
  /// branchée nulle part, et pourquoi dix `validator:` ne s'exécutaient
  /// jamais — voir `_validerLEtape`.
  ///
  /// Une clef par étape rend chaque règle vérifiable au bon moment, et le
  /// message apparaît SOUS le champ fautif au lieu d'une bannière qui passe.
  final _clefsDEtape = List.generate(4, (_) => GlobalKey<FormState>());
  int _step = 0;
  bool _submitting = false;
  bool _refsInitialized = false; // pré-sélection refs (mode édition)
  FaultDeclaration _faultDeclaration = const FaultDeclaration.unknown();
  bool _faultsDirty = false;
  bool _faultsReady = false;
  bool _faultsLoading = false;
  Object? _faultsLoadError;
  String? _faultAccessKey;
  String _faultBaseline = '';
  int _faultLoadGeneration = 0;

  bool get _canDeclareFaults =>
      widget.mode.estPartenaire || ref.read(authProvider).canManageFaults;

  Vehicle? get _existing => widget.existing;

  // ── Step 0 — Type & Identification ───────────────────────────────
  String _vehicleType = 'passenger'; // 'passenger' | 'utility' | 'heavy'
  String? _bodyStyle; // 'sedan' | 'suv' | 'pickup' | …
  final _vinCtrl = TextEditingController();
  final _plateCtrl = TextEditingController(); // plaque (optionnel)

  /// Le véhicule est-il immatriculé ? Déclaré, pas déduit.
  ///
  /// Tout le formulaire se branchait sur la seule présence d'une plaque :
  /// avec plaque le compteur partait dans `registration`, sans plaque dans
  /// `import`, et le pays d'origine n'était même pas demandé. Un vendeur qui
  /// enregistrait un véhicule immatriculé sans avoir sa carte grise sous la
  /// main voyait donc sa fiche basculer du côté import, et le kilométrage
  /// qu'il venait de saisir partir dans « odomètre à l'import ».
  ///
  /// La plaque n'est pas la preuve de l'immatriculation, c'est une de ses
  /// données. On la relève quand on l'a ; on sait bien avant que le véhicule
  /// est immatriculé.
  ///
  /// Saisir une plaque coche ce commutateur — c'est le sens courant — mais
  /// on peut le cocher sans plaque, et le décocher avec : un importé qui
  /// porte encore sa plaque étrangère n'est pas immatriculé ici. L'API
  /// respecte les deux depuis `VehicleController::store()`, qui ne déduit
  /// plus que lorsque le champ est absent.
  bool _immatricule = false;

  // ── Step 2 — Identité ──────────────────────────────────────────────
  VehicleClassificationSelection _classification =
      VehicleClassificationSelection();
  BrandRef? get _brand => _classification.brand;
  ModelRef? get _model => _classification.model;
  TrimRef? get _trim => _classification.trim;
  set _trim(TrimRef? value) => _classification.trim = value;
  bool _classificationChanged = false;
  ColorRef? _color;
  final _yearCtrl = TextEditingController();

  // ── Step 3 — Technique ─────────────────────────────────────────────
  EngineTypeRef? get _engineType => _classification.engineType;
  set _engineType(EngineTypeRef? value) => _classification.engineType = value;
  DrivetrainRef? get _drivetrain => _classification.drivetrain;
  set _drivetrain(DrivetrainRef? value) => _classification.drivetrain = value;
  String _transmission =
      'automatic'; // Gearbox family, separate from wheel drive.
  final _powerCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '5');
  final _doorsCtrl = TextEditingController(text: '4');
  final Set<int> _selectedFeatureIds = {}; // IDs des équipements sélectionnés

  // ── Step 4 — Commercial ────────────────────────────────────────────
  String _condition = 'used'; // 'new' | 'used' | 'damaged'
  String _availability = 'sale'; // 'sale' | 'rent' | 'both'

  /// Mise en avant commerciale. Chaîne vide = aucune promotion : le
  /// `_ChoiceGroup` exige une valeur non nulle, on la traduit en `null` au
  /// moment de l'envoi.
  String _dealType = '';
  bool _negotiable = false;
  int? _selectedPartnerId;
  final _salePriceCtrl = TextEditingController();
  final _rentalDailyCtrl = TextEditingController();
  final _rentalMonthlyCtrl = TextEditingController();
  final _rentalDepositCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  LocationRef? _selectedLocation; // agence / showroom structuré

  /// Le pays d'origine d'un vehicule importe.
  ///
  /// Le serveur accepte `import.origin_country_id` depuis le debut, et la
  /// colonne existe. Le formulaire ne l'a jamais demande : la fiche affichait
  /// donc « Origine » vide sur tous les vehicules, et personne ne pouvait la
  /// renseigner autrement qu'en base.
  CountryRef? _paysOrigine;

  /// La promotion en cours de saisie, en mode PARTENAIRE seulement.
  ///
  /// Le personnel a sa propre mise en avant, `deal_type`, qui ne touche pas
  /// au prix. La promotion chiffree est l'outil du vendeur tiers.
  espace.PromotionSaisie _promotion = const espace.PromotionSaisie();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _faultDeclaration = e?.faultDeclaration ?? const FaultDeclaration.unknown();
    _faultsReady = e == null;
    _faultBaseline = jsonEncode(_faultDeclaration.toPayload());
    Future.microtask(_syncFaultAccess);
    if (e != null) {
      _vehicleType = e.vehicleType;
      _bodyStyle = e.bodyStyle;
      _transmission = e.transmission ?? '';
      _powerCtrl.text = e.powerHp?.toString() ?? '';
      _seatsCtrl.text = e.seats?.toString() ?? '';
      _doorsCtrl.text = e.doors?.toString() ?? '';
      _vinCtrl.text = e.vin ?? '';
      if (e.identity.year != null) _yearCtrl.text = e.identity.year.toString();
      _condition = e.commercial.condition;
      _mileageCtrl.text = e.mileageKm?.toString() ?? '';
      _availability = e.commercial.availability;
      _negotiable = e.commercial.priceNegotiable;
      _dealType = e.commercial.dealType ?? '';
      if (e.commercial.salePrice != null)
        _salePriceCtrl.text = _fmtPrice(e.commercial.salePrice!);
      if (e.commercial.rentalDailyRate != null)
        _rentalDailyCtrl.text = _fmtPrice(e.commercial.rentalDailyRate!);
      if (e.commercial.rentalMonthlyRate != null)
        _rentalMonthlyCtrl.text = _fmtPrice(e.commercial.rentalMonthlyRate!);
      if (e.commercial.rentalDeposit != null)
        _rentalDepositCtrl.text = _fmtPrice(e.commercial.rentalDeposit!);
      if (e.commercial.site != null) _siteCtrl.text = e.commercial.site!;
      _selectedFeatureIds.addAll(e.features.map((f) => f.id));
      // Sans cette ligne, modifier un véhicule immatriculé le renverrait
      // « non immatriculé » au premier enregistrement — le commutateur
      // partant à faux, et la charge utile le déclarant désormais
      // explicitement.
      _immatricule = e.isRegistered;

      // La promotion enregistree. Le serveur ne rend ce bloc que pendant
      // la fenetre : une promotion finie ne revient pas, et c'est exact —
      // il n'y a plus rien a modifier.
      final promo = e.deal;
      if (promo != null) {
        _promotion = espace.PromotionSaisie(
          prix: promo.price,
          debut: promo.startsAt,
          fin: promo.endsAt,
        );
      }
    }
  }

  /// Editing staff must fetch every internal row, not reuse public omissions.
  /// Partner detail has its own authorization and marks staff rows read-only.
  void _syncFaultAccess() {
    if (!mounted) return;
    final auth = widget.mode.estPartenaire ? null : ref.read(authProvider);
    final key = widget.mode.estPartenaire
        ? 'partner'
        : '${auth!.staffUser?.id}:${auth.staffUser?.role}:${auth.canManageFaults}';
    if (_faultAccessKey == key) return;
    _faultAccessKey = key;
    _faultLoadGeneration++;
    setState(() {
      _faultDeclaration =
          _existing?.faultDeclaration ?? const FaultDeclaration.unknown();
      _faultsDirty = false;
      _faultsReady = _existing == null;
      _faultsLoading = false;
      _faultsLoadError = null;
      _faultBaseline = jsonEncode(_faultDeclaration.toPayload());
    });
    if (_canDeclareFaults && _existing != null) _loadFaultDeclaration();
  }

  Future<void> _loadFaultDeclaration() async {
    final existing = _existing;
    if (existing == null || !_canDeclareFaults || _faultsLoading) return;
    final generation = ++_faultLoadGeneration;
    setState(() {
      _faultsLoading = true;
      _faultsLoadError = null;
    });
    try {
      final FaultDeclaration declaration;
      if (widget.mode.estPartenaire) {
        final detail = await ref
            .read(espace.partnerRepositoryProvider)
            .listing(espace.PartnerListingKind.vehicles, existing.id);
        declaration = FaultDeclaration.fromJson(detail['fault_declaration']);
      } else {
        final rows = await ref
            .read(vehicleFaultRepositoryProvider)
            .getFaults(existing.id);
        declaration = FaultDeclaration.fromJson({
          'state': existing.faultDeclaration.state,
          'faults': rows
              .map(
                (fault) => {
                  'id': fault.id,
                  'category': fault.category,
                  'title': fault.title,
                  'description': fault.description,
                  'severity': fault.severity,
                  'status': fault.status,
                  'affects_drivability': fault.affectsDrivability,
                  'is_safety_critical': fault.isSafetyCritical,
                  'disclosed_to_buyer': fault.disclosedToBuyer,
                  'editable': true,
                },
              )
              .toList(),
        });
      }
      if (!mounted || generation != _faultLoadGeneration || !_canDeclareFaults)
        return;
      setState(() {
        _faultDeclaration = declaration;
        _faultBaseline = jsonEncode(declaration.toPayload());
        _faultsDirty = false;
        _faultsReady = true;
      });
    } catch (error) {
      if (mounted && generation == _faultLoadGeneration) {
        setState(() => _faultsLoadError = error);
      }
    } finally {
      if (mounted && generation == _faultLoadGeneration) {
        setState(() => _faultsLoading = false);
      }
    }
  }

  Widget _faultDeclarationEditor() {
    if (!_canDeclareFaults) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_faultsReady) ...[
            Text(l10n.catalogFieldFaults),
            const SizedBox(height: 8),
            if (_faultsLoadError != null)
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(messageFor(_faultsLoadError!, l10n: l10n)),
                  TextButton(
                    onPressed: _loadFaultDeclaration,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              )
            else
              const LinearProgressIndicator(),
          ] else
            FaultDeclarationWidget(
              value: _faultDeclaration,
              enabled: !_submitting,
              staffStatuses: !widget.mode.estPartenaire,
              onChanged: (declaration) => setState(() {
                _faultDeclaration = declaration;
                _faultsDirty =
                    jsonEncode(declaration.toPayload()) != _faultBaseline;
              }),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _vinCtrl,
      _plateCtrl,
      _yearCtrl,
      _powerCtrl,
      _seatsCtrl,
      _doorsCtrl,
      _salePriceCtrl,
      _rentalDailyCtrl,
      _rentalMonthlyCtrl,
      _rentalDepositCtrl,
      _mileageCtrl,
      _siteCtrl,
      _descriptionCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  // ── Soumission ─────────────────────────────────────────────────────

  // ── Validation par étape ──────────────────────────────────────────

  /// Les règles d'une étape, telles que ses champs les déclarent.
  ///
  /// ── CE QUE CECI REMPLACE, ET POURQUOI ────────────────────────────────
  ///
  /// Une liste de conditions écrite à la main, qui redisait ce que les
  /// `validator:` des champs disaient déjà — marque, modèle, année,
  /// motorisation, prix de vente, tarifs de location. Deux formulations de la
  /// même règle, dont une seule s'exécutait.
  ///
  /// Et elle en OUBLIAIT deux, qui ne protégeaient donc rien :
  ///
  ///   — « Carrosserie * » portait son astérisque sans être exigée. Un
  ///     véhicule enregistré sans carrosserie prend le défaut de la colonne,
  ///     et le filtre public `?body_style=` ne le trouve jamais — ou le range
  ///     sous une carrosserie que personne n'a choisie.
  ///   — « Le VIN doit faire exactement 17 caractères » n'était jamais
  ///     appliqué : un VIN de cinq caractères partait au serveur.
  ///
  /// Les règles vivent désormais là où elles s'affichent : sous le champ.
  final _erreursDEtape = <int, List<String>>{};

  bool _validerLEtape(int etape) {
    final invalides = _clefsDEtape[etape].currentState?.validateGranularly();
    _erreursDEtape[etape] = [
      for (final champ in invalides ?? <FormFieldState<Object?>>{})
        if (champ.errorText != null) champ.errorText!,
    ].toSet().toList();
    return invalides == null || invalides.isEmpty;
  }

  void _expliquerLEtape(int etape) {
    // Reutiliser les validateurs : les raisons ne doivent pas diverger des
    // erreurs sous les champs. Remplacer le message precedent, sans file
    // d'attente de messages perimes apres plusieurs appuis sur Suivant.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _snackError(
      l10n.vehiclesStepBlocked(
        etape + 1,
        (_erreursDEtape[etape] ?? const <String>[]).join('\n'),
      ),
    );
  }

  /// La première étape qui ne passe pas, ou -1 si toutes passent.
  ///
  /// `validateGranularly()` est appelé sur CHACUNE, sans arrêt à la première qui
  /// échoue : chaque champ fautif doit porter son message, sinon le vendeur
  /// corrige la première erreur pour en découvrir une seconde.
  int _premiereEtapeFautive() {
    var premiere = -1;

    for (var etape = 0; etape < _clefsDEtape.length; etape++) {
      if (!_validerLEtape(etape) && premiere == -1) {
        premiere = etape;
      }
    }

    return premiere;
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Appelé par le bouton Suivant / Enregistrer du Stepper.
  Future<void> _onContinue(CatalogRefs refs) async {
    if (_submitting) return;
    // Avancer d'une étape → n'éprouver que l'étape courante. Les suivantes
    // sont montées mais vides, et les exiger ici interdirait d'avancer.
    if (_step < 3) {
      if (_validerLEtape(_step)) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setState(() => _step++);
      } else {
        _expliquerLEtape(_step);
      }

      return;
    }

    // ── AU MOMENT D'ENREGISTRER, TOUT EST EPROUVE ─────────────────────
    //
    // Et non la seule dernière étape. Un vendeur peut revenir en arrière,
    // vider un champ, puis repartir en avant : la page ne repasse alors par
    // aucune validation de l'étape touchée.
    //
    // Quand une étape antérieure ne passe pas, on y RETOURNE : son message
    // est sous un champ qui n'est pas à l'écran, et le laisser là reviendrait
    // à refuser sans rien dire.
    final fautive = _premiereEtapeFautive();

    if (fautive != -1) {
      setState(() => _step = fautive);
      _expliquerLEtape(fautive);

      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await _submit(refs);
  }

  // ── Soumission ─────────────────────────────────────────────────────

  Future<void> _submit(CatalogRefs refs) async {
    setState(() => _submitting = true);

    try {
      final payload = _buildPayload();
      final existing = _existing;

      // ── L'ESPACE PARTENAIRE : AUTRE DEPOT, AUTRE SUITE ─────────────────
      //
      // Le formulaire est le meme, la cible non. Le partenaire ecrit sur ses
      // propres routes, avec son propre jeton, et son parcours ne passe pas
      // par l'ecran de media du personnel : sa page d'annonces attend un
      // `pop(true)`, comme le faisait son ancien formulaire.
      //
      // On rend la main ici plutot que de brancher le reste : rien de ce qui
      // suit — invalidation des listes du back-office, SnackBar du personnel,
      // navigation vers /media-upload — n'a de sens dans son espace.
      if (widget.mode.estPartenaire) {
        await ref
            .read(espace.partnerRepositoryProvider)
            .saveListing(
              espace.PartnerListingKind.vehicles,
              payload,
              id: existing?.id,
            );

        if (mounted) Navigator.of(context).pop(true);

        return;
      }

      final repo = ref.read(vehicleAdminRepositoryProvider);
      final Vehicle vehicle;

      if (existing != null) {
        vehicle = await repo.updateVehicle(existing.id, payload);
      } else {
        vehicle = await repo.createVehicle(payload);
      }

      if (mounted) {
        ref.invalidate(vehicleListProvider);
        if (existing != null) {
          ref.invalidate(vehicleDetailProvider(vehicle.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.vehiclesUpdated),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.vehiclesCreated),
              backgroundColor: Colors.green,
            ),
          );
          context.pushReplacement(
            '/media-upload',
            extra: MediaUploadConfig(
              type: MediaOwnerType.vehicle,
              id: vehicle.id,
              title: vehicle.identity.fullName,
            ),
          );
        }
      }
    } on espace.PartnerApiException catch (e) {
      // Le depot partenaire a sa propre exception, et ses erreurs de validation
      // vivent dans `fields` et non dans `errors`. Sans cette branche elles
      // tombaient dans le `catch` generique, qui perd le detail champ par
      // champ — le seul utile avec une trentaine de champs a l'ecran.
      if (mounted) {
        _showErrors(
          titre: l10n.vehiclesSaveFailed,
          message: e.fields.isNotEmpty
              ? e.fields.values.map((texte) => '• $texte').join('\n')
              : e.message,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        // Les erreurs de validation restent detaillees champ par champ : avec
        // une trentaine de champs dans ce formulaire, « Le champ sale price
        // est obligatoire » seul n'indique pas ou regarder. Pour tout le
        // reste, c'est userMessage qui parle — il traduit les codes et porte
        // la reference, la ou e.message rendait le texte brut du serveur,
        // parfois en anglais, parfois vide.
        _showErrors(
          titre: titreErreurEnregistrement(e, l10n: l10n),
          message: e.errors != null && e.errors!.isNotEmpty
              ? e.errors!.entries
                    .map((entry) => '• ${entry.value.first}')
                    .join('\n')
              : messageFor(e, l10n: l10n),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrors(
          titre: l10n.vehiclesSaveFailed,
          message: messageFor(e, l10n: l10n),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final bool forSale = _availability == 'sale' || _availability == 'both';
    final bool forRent = _availability == 'rent' || _availability == 'both';
    final bool hasPlate = _plateCtrl.text.trim().isNotEmpty;
    // On retire le separateur avant de lire : int.tryParse refuse « 85 000 »
    // et rendrait null, c'est-a-dire un kilometrage silencieusement perdu.
    final int? mileage = _mileageCtrl.text.isNotEmpty
        ? int.tryParse(_mileageCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : null;
    final clearingMileage =
        _existing != null &&
        _existing!.isRegistered == _immatricule &&
        _existing!.mileageKm != null &&
        mileage == null;

    return <String, dynamic>{
      if (_canDeclareFaults && _faultsReady && _faultsDirty)
        ..._faultDeclaration.toPayload(),
      'vehicle_type': _vehicleType,
      if (_bodyStyle != null || _classificationChanged)
        'body_style': _bodyStyle,
      if (_vinCtrl.text.trim().isNotEmpty) 'vin': _vinCtrl.text.trim(),
      // DÉCLARÉ, PAS DÉDUIT. L'API ne retombe sur la présence d'une plaque
      // que lorsque ce champ est absent.
      'registration_status': _immatricule ? 'registered' : 'unregistered',
      if (hasPlate) 'plate_number': _plateCtrl.text.trim(),
      ..._classification.toPayload(editing: _existing != null),
      if (_color != null) 'color_id': _color!.id,
      'manufacturing_year': int.parse(_yearCtrl.text),
      'transmission': _transmission.isEmpty ? null : _transmission,
      if (_powerCtrl.text.isNotEmpty || _classificationChanged)
        'power_hp': int.tryParse(_powerCtrl.text),
      if (_existing != null && _classificationChanged) ...{
        'power_kw': null,
        'cylinders': null,
        'engine_displacement_cc': null,
        'torque_nm': null,
        'gear_count': null,
        'consumption_urban': null,
        'consumption_extra_urban': null,
        'consumption_combined': null,
        'electric_consumption_kwh': null,
        'battery_capacity_kwh': null,
        'electric_range_km': null,
      },
      if (_seatsCtrl.text.isNotEmpty || _classificationChanged)
        'seats': int.tryParse(_seatsCtrl.text),
      if (_doorsCtrl.text.isNotEmpty || _classificationChanged)
        'doors': int.tryParse(_doorsCtrl.text),
      'condition': _condition,
      'availability': _availability,
      'price_negotiable': _negotiable,
      // Explicitement null quand aucune promotion : c'est ce qui permet d'en
      // retirer une à l'édition.
      // Les trois champs de la boutique. Le serveur les REFUSE a un
      // partenaire (`missing`), donc les envoyer vaudrait 422.
      if (widget.mode.peutChoisirLaBoutique)
        'deal_type': _dealType.isEmpty ? null : _dealType,
      if (forSale && _salePriceCtrl.text.trim().isNotEmpty)
        'sale_price': int.parse(
          _salePriceCtrl.text.replaceAll(RegExp(r'\s'), ''),
        ),
      if (_existing != null ||
          forRent && _rentalDailyCtrl.text.trim().isNotEmpty)
        'rental_daily_rate': forRent
            ? _parsePrice(_rentalDailyCtrl.text)
            : null,
      if (_existing != null ||
          forRent && _rentalMonthlyCtrl.text.trim().isNotEmpty)
        'rental_monthly_rate': forRent
            ? _parsePrice(_rentalMonthlyCtrl.text)
            : null,
      if (_existing != null ||
          forRent && _rentalDepositCtrl.text.trim().isNotEmpty)
        'rental_deposit': forRent ? _parsePrice(_rentalDepositCtrl.text) : null,
      if (_siteCtrl.text.isNotEmpty) 'site': _siteCtrl.text.trim(),
      if (_descriptionCtrl.text.isNotEmpty)
        'description': _descriptionCtrl.text.trim(),
      'currency': 'XOF',
      if (_selectedFeatureIds.isNotEmpty)
        'features': _selectedFeatureIds.toList(),
      if (widget.mode.peutChoisirLaBoutique && _selectedLocation != null)
        'location_id': _selectedLocation!.id,
      if (widget.mode.peutChoisirLaBoutique && _selectedPartnerId != null)
        'partner_id': _selectedPartnerId,
      // Kilométrage → sous-objet selon le STATUT, et non plus selon la
      // présence d'une plaque :
      // - immatriculé     : registration.mileage_km
      // - non immatriculé : import.odometer_at_import_km
      //
      // C'est le même critère que celui dont l'API se sert pour choisir le
      // bloc qu'elle écrit (`syncTypeSpecificDetails`). Quand les deux
      // divergeaient, le bloc envoyé était ignoré sans un mot, et le
      // kilométrage avec lui.
      if (_immatricule && (mileage != null || clearingMileage))
        'registration': {'mileage_km': mileage},
      // Le bloc import part des qu'il a quelque chose a dire : le compteur,
      // le pays, ou les deux. Il etait conditionne au seul kilometrage, donc
      // un pays choisi sans compteur saisi ne partait pas.
      // ── LA PROMOTION, EN MODE PARTENAIRE SEULEMENT ──────────────────
      //
      // Le serveur refuse `deal_price` au personnel : sa mise en avant est
      // `deal_type`, qui signale sans chiffrer. Envoyer le champ depuis
      // l'ecran du personnel vaudrait un 422 sur une annonce par ailleurs
      // valide.
      if (widget.mode.estPartenaire && _promotion.active) ...{
        'deal_price': _promotion.prix,
        'deal_starts_at': _promotion.debut?.toIso8601String(),
        'deal_ends_at': _promotion.fin?.toIso8601String(),
      } else if (widget.mode.estPartenaire && _existing != null)
        'deal_price': null,
      if (!_immatricule &&
          (mileage != null || clearingMileage || _paysOrigine != null))
        'import': {
          if (mileage != null || clearingMileage)
            'odometer_at_import_km': mileage,
          'origin_country_id': ?_paysOrigine?.id,
        },
    };
  }

  /// Le récapitulatif de marge sous un champ de prix, en mode PARTENAIRE seul.
  ///
  /// Le personnel ne voit rien : la marge s'applique à ce qu'un TIERS propose,
  /// pas au prix que la boutique fixe elle-même pour son propre stock.
  ///
  /// Le taux vient du profil partenaire — `/partner/me` le porte — et non d'une
  /// annonce : c'est le taux DU JOUR, celui qui s'appliquera à cet
  /// enregistrement. Une annonce déjà enregistrée porte le sien, figé.
  Widget _marge(TextEditingController controller, {String? libelle}) {
    if (!widget.mode.estPartenaire) return const SizedBox.shrink();

    final taux =
        ref.watch(espace.partnerSessionProvider).profile?.margePourcentage ?? 0;

    return MargeRecapitulatif(
      prixPropose: _parsePrice(controller.text),
      pourcentage: taux,
      libelle: libelle ?? l10n.vehiclesBuyerPriceLabel,
    );
  }

  bool get _rentalRatesMissing =>
      _rentalDailyCtrl.text.trim().isEmpty &&
      _rentalMonthlyCtrl.text.trim().isEmpty;

  int? _parsePrice(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'\s'), ''));

  void _resetModelTechnicalFields() {
    _classificationChanged = true;
    _powerCtrl.clear();
    _transmission = '';
  }

  void _showErrors({required String titre, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(titre),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(l10n.vehiclesOk),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final refsAsync = ref.watch(catalogRefsProvider);
    if (!widget.mode.estPartenaire) {
      ref.listen<AuthState>(authProvider, (_, _) => _syncFaultAccess());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existing != null ? l10n.vehiclesEditTitle : l10n.vehiclesCreateTitle,
        ),
        centerTitle: false,
        actions: [
          // ── LES PHOTOS D'UN VÉHICULE DÉJÀ ENREGISTRÉ ─────────────────
          //
          // Elles étaient INJOIGNABLES. L'écran des médias ne s'ouvrait que
          // par le `pushReplacement` qui suit une création — « Véhicule
          // enregistré, ajoutez des photos ! » — et une MODIFICATION se
          // contentait de refermer l'écran. Passé ce premier instant, plus
          // aucun chemin de l'application n'y menait : ni ici, ni depuis la
          // fiche détaillée.
          //
          // L'asymétrie saute aux yeux une fois cherchée : la pièce et
          // l'accessoire ont DEUX accès chacun — ce bouton sur leur écran de
          // modification, et un autre sur leur fiche. Le véhicule n'en avait
          // aucun, alors que c'est l'article dont les photos comptent le
          // plus et qui en porte le plus.
          //
          // À la création, le bouton n'a pas lieu d'être : le véhicule n'a
          // pas encore d'identifiant auquel rattacher une photo. C'est
          // exactement la condition posée sur `add_part_page.dart`.
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: l10n.vehiclesPhotos,
              onPressed: () => context.push(
                '/media-upload',
                extra: MediaUploadConfig(
                  type: MediaOwnerType.vehicle,
                  id: _existing!.id,
                  title: _existing!.identity.fullName,
                ),
              ),
            ),
        ],
      ),
      body: refsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _LoadingError(
          error: messageFor(e, l10n: l10n),
          onRetry: () => ref.invalidate(catalogRefsProvider),
        ),
        data: _buildForm,
      ),
    );
  }

  Widget _buildForm(CatalogRefs refs) {
    // ── Pré-sélection des dropdowns en mode édition ──────────────────
    final e = _existing;
    if (e != null && !_refsInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final selection = VehicleClassificationSelection.fromIds(
          refs,
          brandId: e.brandId,
          modelId: e.vehicleModelId,
          trimId: e.trimId,
          engineTypeId: e.engineTypeId,
          drivetrainId: e.drivetrainId,
          engineCode: e.engineCode,
        );
        final color = refs.colors.where((c) => c.id == e.colorId).firstOrNull;
        final loc = e.commercial.locationId != null
            ? refs.locations
                  .where((l) => l.id == e.commercial.locationId)
                  .cast<LocationRef?>()
                  .firstOrNull
            : null;
        setState(() {
          _classification = selection;
          _color = color;
          _selectedLocation = loc;
          _refsInitialized = true;
        });
      });
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        // PAS de `Form` ici : il envelopperait les quatre étapes, que le
        // `Stepper` monte toutes. Chacune porte le sien — voir `_clefsDEtape`.
        child: Stepper(
          currentStep: _step,
          type: StepperType.vertical,
          onStepContinue: () => _onContinue(refs),
          onStepCancel: () {
            if (_step > 0) setState(() => _step--);
          },
          controlsBuilder: (context, details) => _StepControls(
            details: details,
            isLast: _step == 3,
            submitting: _submitting,
          ),
          steps: [
            _buildStep1(),
            _buildStep2(refs),
            _buildStep3(refs),
            _buildStep4(refs),
          ],
        ),
      ),
    );
  }

  // ── Step 0 — Type & Identification ───────────────────────────────

  Step _buildStep1() => Step(
    title: Text(l10n.vehiclesTypeTitle),
    subtitle: Text(switch (_vehicleType) {
      'utility' => l10n.vehiclesTypeUtility,
      'heavy' => l10n.vehiclesTypeHeavy,
      _ => l10n.vehiclesTypePassenger,
    }),
    isActive: _step >= 0,
    content: Form(
      key: _clefsDEtape[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type de véhicule ──────────────────────────────────────
          Text(
            l10n.catalogFieldCategory,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _ChoiceGroup<String>(
            options: [
              (value: 'passenger', label: l10n.vehiclesTypePassenger),
              (value: 'utility', label: l10n.vehiclesTypeUtility),
              (value: 'heavy', label: l10n.vehiclesTypeHeavy),
            ],
            selected: _vehicleType,
            onChanged: (v) => setState(() => _vehicleType = v),
          ),
          const SizedBox(height: 16),

          // ── Carrosserie ───────────────────────────────────────────
          DropdownButtonFormField<String>(
            value: _bodyStyle,
            // isExpanded, comme tous les autres menus de l'application : sans
            // lui, le menu prend la largeur de son item le plus long —
            // « Citadine / Hayon » ici — et deborde sur un petit ecran.
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.vehiclesBodyStyleLabel,
              hintText: l10n.vehiclesBodyStyleHint,
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: 'sedan',
                child: Text(l10n.catalogBodyLabelSedan),
              ),
              DropdownMenuItem(
                value: 'hatchback',
                child: Text(l10n.catalogBodyLabelHatchback),
              ),
              DropdownMenuItem(
                value: 'suv',
                child: Text(l10n.catalogBodyLabelSuv),
              ),
              DropdownMenuItem(
                value: 'estate',
                child: Text(l10n.catalogBodyLabelEstate),
              ),
              DropdownMenuItem(
                value: 'coupe',
                child: Text(l10n.catalogBodyLabelCoupe),
              ),
              DropdownMenuItem(
                value: 'convertible',
                child: Text(l10n.catalogBodyLabelConvertible),
              ),
              DropdownMenuItem(
                value: 'pickup',
                child: Text(l10n.catalogBodyLabelPickup),
              ),
              DropdownMenuItem(
                value: 'van',
                child: Text(l10n.catalogBodyLabelVan),
              ),
              DropdownMenuItem(
                value: 'minibus',
                child: Text(l10n.catalogBodyLabelMinibus),
              ),
              DropdownMenuItem(
                value: 'bus',
                child: Text(l10n.catalogBodyLabelBus),
              ),
              DropdownMenuItem(
                value: 'truck',
                child: Text(l10n.catalogBodyLabelTruck),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text(l10n.vehiclesFaultCategoryOther),
              ),
            ],
            onChanged: (v) => setState(() => _bodyStyle = v),
            validator: (v) => v == null ? l10n.vehiclesBodyStyleRequired : null,
          ),
          const SizedBox(height: 16),

          // ── VIN ───────────────────────────────────────────────────
          TextFormField(
            controller: _vinCtrl,
            decoration: InputDecoration(
              labelText: l10n.vehiclesVinOptional,
              hintText: 'WVWZZZ1KZ8W000001',
              helperText: l10n.vehiclesVinHelper,
              prefixIcon: Icon(Icons.qr_code_2),
            ),
            maxLength: 17,
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length != 17) {
                return l10n.vehiclesVinLengthError;
              }
              return null;
            },
          ),
          const SizedBox(height: 4),

          // ── Immatriculation ───────────────────────────────────────
          //
          // Le commutateur d'abord, la plaque ensuite : c'est l'ordre dans
          // lequel on sait les choses. Le statut décide de la suite du
          // formulaire — le pays d'origine n'est demandé que pour un importé,
          // et le kilométrage ne part pas au même endroit.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.assignment_turned_in_outlined),
            title: Text(l10n.vehiclesRegisteredLabel),
            subtitle: Text(
              _immatricule
                  ? l10n.vehiclesRegisteredHint
                  : l10n.vehiclesImportedHint,
            ),
            value: _immatricule,
            onChanged: (v) => setState(() {
              if (_immatricule != v) _mileageCtrl.clear();
              _immatricule = v;
            }),
          ),

          // ── CE QUE DECOCHER SUPPRIME, DIT AVANT L'ENREGISTREMENT ──────
          //
          // Le serveur ecrit le bloc qui correspond au statut, et quand il
          // ecrit un bloc IMPORT il SUPPRIME le carnet d'immatriculation
          // (`VehicleController::syncTypeSpecificDetails` : `if (Unregistered
          // && ! empty($data['import'])) { … registrationDetail()?->delete();
          // }`).
          //
          // Or le bloc `import` part des que ce formulaire a quelque chose a y
          // mettre : un kilometrage OU un pays d'origine. Decocher puis
          // choisir un pays suffit donc a effacer les informations
          // d'immatriculation d'un vehicule qui en avait — sans qu'aucun ecran
          // ne l'ait annonce.
          //
          // Et la bascule change le SENS du compteur : le kilometrage d'un
          // vehicule immatricule et le compteur au moment de l'import ne
          // mesurent pas la meme chose. D'ou « ressaisissez ».
          if (_existing?.isRegistered == true && !_immatricule)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.vehiclesRegistrationRemovalWarning,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextFormField(
            controller: _plateCtrl,
            decoration: InputDecoration(
              labelText: l10n.vehiclesPlateOptional,
              hintText: l10n.vehiclesPlateHint,
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            textCapitalization: TextCapitalization.characters,
            // Saisir une plaque déclare le véhicule immatriculé — c'est le sens
            // courant, et ça évite de demander deux fois la même chose. Le
            // décochage reste possible : un importé peut porter sa plaque
            // d'origine.
            onChanged: (v) {
              final saisie = v.trim().isNotEmpty;
              if (saisie && !_immatricule) {
                setState(() {
                  _mileageCtrl.clear();
                  _immatricule = true;
                });
              }
            },
          ),
        ],
      ),
    ),
  );

  // ── Step 2 — Identité ─────────────────────────────────────────────

  Step _buildStep2(CatalogRefs refs) {
    final models = _brand != null
        ? refs.modelsForBrand(_brand!.id)
        : <ModelRef>[];
    final trims = _model != null ? refs.trimsForModel(_model!.id) : <TrimRef>[];

    return Step(
      title: Text(l10n.vehiclesIdentityTitle),
      subtitle: _brand != null
          ? Text(
              _model == null
                  ? _brand!.name
                  : referenceModelDisplayName(_model!, l10n),
            )
          : null,
      isActive: _step >= 1,
      content: Form(
        key: _clefsDEtape[1],
        child: Column(
          children: [
            // Marque
            VehicleReferenceDropdown<BrandRef>(
              label: l10n.vehiclesBrandLabel,
              items: refs.brands
                  .where((b) => b.isActive || b.id == _brand?.id)
                  .toList(),
              value: _brand,
              itemLabel: (b) => b.name,
              onChanged: (b) => setState(() {
                if (_brand?.id == b?.id) return;
                _classification.selectBrand(b);
                _resetModelTechnicalFields();
              }),
              validator: (v) => v == null ? l10n.vehiclesBrandRequired : null,
            ),
            const SizedBox(height: 12),

            // Modèle
            VehicleReferenceDropdown<ModelRef>(
              label: l10n.vehiclesModelLabel,
              items: models,
              value: _model,
              itemLabel: (m) => referenceModelDisplayName(m, l10n),
              onChanged: (m) => setState(() {
                if (_model?.id == m?.id) return;
                _classification.selectModel(m);
                _resetModelTechnicalFields();
                if (m == null) return;

                // Carrosserie : valeur DB ou inférence depuis body_type
                final style = m.inferredBodyStyle;
                if (style != null) _bodyStyle = style;

                // Type de véhicule : valeur DB en priorité, sinon inférence
                final vtype = m.resolvedVehicleType;
                if (vtype != null) _vehicleType = vtype;

                // Transmission : valeur DB uniquement
                if (m.defaultTransmission != null)
                  _transmission = m.defaultTransmission!;

                // Places et portes : valeur DB uniquement
                if (m.defaultSeats != null)
                  _seatsCtrl.text = m.defaultSeats.toString();
                if (m.defaultDoors != null)
                  _doorsCtrl.text = m.defaultDoors.toString();

                // Puissance : valeur DB uniquement (indicative)
                if (m.defaultPowerHp != null)
                  _powerCtrl.text = m.defaultPowerHp.toString();
              }),
              validator: (v) => v == null ? l10n.vehiclesModelRequired : null,
              enabled: _brand != null,
            ),
            const SizedBox(height: 12),

            // Finition (optionnel)
            if (trims.isNotEmpty) ...[
              VehicleReferenceDropdown<TrimRef>(
                label: l10n.catalogFieldTrim,
                items: trims,
                value: _trim,
                itemLabel: (t) => t.name,
                onChanged: (t) => setState(() => _trim = t),
                enabled: _model != null,
              ),
              const SizedBox(height: 12),
            ],

            // Année
            TextFormField(
              controller: _yearCtrl,
              decoration: InputDecoration(
                labelText: l10n.vehiclesManufactureYearLabel,
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.vehiclesYearRequired;
                final y = int.tryParse(v);
                if (y == null || y < 1950 || y > DateTime.now().year) {
                  return l10n.vehiclesYearRangeInvalid(DateTime.now().year);
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Couleur
            VehicleReferenceDropdown<ColorRef>(
              label: l10n.catalogFieldColour,
              items: refs.colors,
              value: _color,
              itemLabel: (c) => referenceColourLabel(c.name, l10n),
              itemLeading: (c) => c.hexCode != null
                  ? Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _hexColor(c.hexCode!),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    )
                  : null,
              onChanged: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3 — Technique ────────────────────────────────────────────

  /// Ce qui a ete choisi a l'etape technique, sous son titre.
  ///
  /// Les etapes « Type de vehicule » et « Identite » affichaient leur
  /// selection sous leur titre ; les deux suivantes n'affichaient rien. Une
  /// fois l'etape repliee, plus rien ne disait ce qu'on venait d'y mettre, et
  /// verifier sa motorisation imposait de rouvrir l'etape — donc de la
  /// reparcourir en entier pour revenir ou l'on etait.
  ///
  /// Nul tant que rien n'est choisi : un sous-titre vide vaut mieux qu'une
  /// ligne qui annonce des tirets.
  Widget? _resumeTechnique() {
    final parts = <String>[
      if (_engineType != null)
        referenceFuelLabel(_engineType!.code, _engineType!.label, l10n),
      if (_transmission.isNotEmpty) transmissionLabel(_transmission, l10n),
      if (_drivetrain != null)
        referenceDrivetrainLabel(_drivetrain!.code, _drivetrain!.label, l10n),
      if (_powerCtrl.text.trim().isNotEmpty)
        l10n.vehiclesPowerSummary(_powerCtrl.text.trim()),
    ];

    // La transmission a toujours une valeur par defaut : seule, elle ne dit
    // rien de ce que le proprietaire a reellement choisi.
    if (_engineType == null) return null;

    return Text(parts.join(' · '));
  }

  /// Le prix, et la nature de l'offre.
  Widget? _resumeCommercial() {
    final prix = _salePriceCtrl.text.trim();

    final offre = switch (_availability) {
      'rent' => l10n.vehiclesOfferRentSummary,
      'both' => l10n.vehiclesOfferBothSummary,
      _ => l10n.vehiclesOfferSaleSummary,
    };

    if (prix.isEmpty) return Text(offre);

    return Text(l10n.vehiclesOfferSummary(offre, prix));
  }

  Step _buildStep3(CatalogRefs refs) => Step(
    title: Text(l10n.vehiclesTechnicalTitle),
    subtitle: _resumeTechnique(),
    isActive: _step >= 2,
    content: Form(
      key: _clefsDEtape[2],
      child: Column(
        children: [
          // Motorisation
          VehicleReferenceDropdown<EngineTypeRef>(
            label: l10n.vehiclesEngineTypeLabel,
            items: refs.engineTypes,
            value: _engineType,
            itemLabel: (e) => referenceFuelLabel(e.code, e.label, l10n),
            onChanged: (e) => setState(() => _engineType = e),
            validator: (v) =>
                v == null ? l10n.vehiclesEngineTypeRequired : null,
          ),
          const SizedBox(height: 12),

          TransmissionSelector(
            label: l10n.vehiclesTransmissionLabel,
            value: _transmission,
            onChanged: (value) => setState(() => _transmission = value ?? ''),
          ),
          const SizedBox(height: 16),

          // Roues motrices
          VehicleReferenceDropdown<DrivetrainRef>(
            label: l10n.vehiclesDrivetrainLabel,
            items: refs.drivetrains,
            value: _drivetrain,
            itemLabel: (d) => referenceDrivetrainLabel(d.code, d.label, l10n),
            onChanged: (d) => setState(() => _drivetrain = d),
          ),
          const SizedBox(height: 12),

          // Puissance / places / portes
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _powerCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.vehiclesPowerLabel,
                    suffixText: 'ch',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _seatsCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.catalogFieldSeats,
                    suffixText: 'p',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _doorsCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.catalogFieldDoors,
                    suffixText: 'p',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                ),
              ),
            ],
          ),

          _faultDeclarationEditor(),

          // ── Équipements / options ────────────────────────────────────
          if (refs.features.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              l10n.vehiclesFeaturesTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.vehiclesFeaturesHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Tri des catégories dans l'ordre défini par _categoryOrder.
            ...(() {
              final map = refs.featuresByCategory;
              final ordered = _categoryOrder
                  .where(map.containsKey)
                  .map((k) => MapEntry(k, map[k]!))
                  .toList();
              // Catégories inconnues à la fin (ex. : ajouts futurs côté serveur).
              final extra = map.entries
                  .where((e) => !_categoryOrder.contains(e.key))
                  .toList();
              return [...ordered, ...extra];
            })().map(
              (entry) => _FeatureCategorySection(
                category: entry.key,
                features: entry.value,
                selectedFeatureIds: _selectedFeatureIds,
                onToggle: (id, selected) => setState(() {
                  if (selected) {
                    _selectedFeatureIds.add(id);
                  } else {
                    _selectedFeatureIds.remove(id);
                  }
                }),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  // ── Step 4 — Commercial ───────────────────────────────────────────

  Step _buildStep4(CatalogRefs refs) {
    final forSale = _availability == 'sale' || _availability == 'both';
    final forRent = _availability == 'rent' || _availability == 'both';

    return Step(
      title: Text(l10n.vehiclesCommercialTitle),
      subtitle: _resumeCommercial(),
      isActive: _step >= 3,
      content: Form(
        key: _clefsDEtape[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Condition
            Text(
              l10n.vehiclesConditionLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            _ChoiceGroup<String>(
              options: [
                (value: 'new', label: l10n.catalogConditionNew),
                (value: 'used', label: l10n.catalogConditionUsed),
                (value: 'damaged', label: l10n.vehiclesConditionDamaged),
              ],
              selected: _condition,
              onChanged: (v) => setState(() {
                _condition = v;
                if (v == 'new') _mileageCtrl.clear();
              }),
            ),
            const SizedBox(height: 16),

            // Kilométrage (uniquement pour occasion / endommagé)
            if (_condition != 'new') ...[
              TextFormField(
                controller: _mileageCtrl,
                decoration: InputDecoration(
                  labelText: l10n.catalogFieldMileage,
                  suffixText: 'km',
                  hintText: '85 000',
                  prefixIcon: Icon(Icons.speed_outlined),
                ),
                keyboardType: TextInputType.number,
                // Le meme formateur que les champs monetaires. Le texte d'aide
                // de ce champ affiche « 85 000 » depuis toujours, mais la
                // saisie etait en chiffres nus : l'exemple montrait une forme
                // que le champ refusait, et un kilometrage a six chiffres se
                // relit mal sans separateur — c'est precisement la ou se glisse
                // le zero de trop.
                inputFormatters: [
                  _ThousandsSeparatorFormatter(),
                  // 9 caracteres : 7 chiffres et leurs deux separateurs.
                  LengthLimitingTextInputFormatter(9),
                ],
              ),
              const SizedBox(height: 16),

              // Pays d'origine — uniquement pour un véhicule NON IMMATRICULÉ.
              //
              // C'est la seule branche ou la charge utile porte un bloc
              // `import` : pour un immatricule, le compteur part dans
              // `registration`, et un pays envoye la serait ignore sans que
              // rien ne le dise. Mieux vaut ne pas demander ce qu'on ne saurait
              // pas enregistrer.
              //
              // La condition portait sur la PLAQUE, pas sur le statut. Un
              // vendeur qui declarait un importe tout en notant sa plaque
              // etrangere n'avait donc plus de champ « pays d'origine » —
              // alors que c'est exactement le vehicule pour lequel il compte.
              if (!_immatricule)
                Consumer(
                  builder: (context, ref, _) {
                    final pays =
                        ref.watch(countriesProvider).valueOrNull ??
                        const <CountryRef>[];

                    if (pays.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<CountryRef>(
                        initialValue: _paysOrigine,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.vehiclesOriginCountryLabel,
                          helperText: l10n.vehiclesOriginCountryHint,
                          prefixIcon: Icon(Icons.public_outlined),
                        ),
                        items: pays
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  referenceCountryLabel(c.iso2, c.name, l10n),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (c) => setState(() => _paysOrigine = c),
                      ),
                    );
                  },
                ),
            ],

            // Disponibilité
            Text(
              l10n.vehiclesAvailabilityLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            _ChoiceGroup<String>(
              options: [
                (value: 'sale', label: l10n.vehiclesForSale),
                (value: 'rent', label: l10n.vehiclesForRent),
                (value: 'both', label: l10n.vehiclesForBoth),
              ],
              selected: _availability,
              onChanged: (v) => setState(() => _availability = v),
            ),
            const SizedBox(height: 16),

            // Mise en avant commerciale — la vitrine est a la boutique.
            if (widget.mode.peutChoisirLaBoutique) ...[
              Text(
                l10n.vehiclesDealLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              _ChoiceGroup<String>(
                options: [
                  (value: '', label: l10n.vehiclesNoDeal),
                  (value: 'good_deal', label: l10n.vehiclesGoodDeal),
                  (value: 'flash_sale', label: l10n.vehiclesFlashSale),
                  (value: 'clearance', label: l10n.vehiclesClearance),
                ],
                selected: _dealType,
                onChanged: (v) => setState(() => _dealType = v),
              ),
              const SizedBox(height: 16),
            ],

            // Prix de vente
            if (forSale) ...[
              TextFormField(
                controller: _salePriceCtrl,
                decoration: InputDecoration(
                  labelText: l10n.vehiclesSalePriceLabel,
                  suffixText: 'FCFA',
                  hintText: '15 000 000',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsSeparatorFormatter()],
                validator: (v) {
                  if (forSale && (v == null || v.trim().isEmpty)) {
                    return l10n.vehiclesSalePriceRequired;
                  }
                  return null;
                },
                // Redessine a chaque frappe : sans cela le recapitulatif de
                // marge resterait sur le chiffre precedent pendant la saisie.
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _marge(_salePriceCtrl),
              if (widget.mode.estPartenaire)
                espace.ChampsDePromotion(
                  prixNormal: _parsePrice(_salePriceCtrl.text),
                  plafondPourcentage:
                      ref
                          .watch(espace.partnerSessionProvider)
                          .profile
                          ?.plafondRemisePourcentage ??
                      0,
                  valeur: _promotion,
                  onChanged: (valeur) => setState(() => _promotion = valeur),
                ),
            ],

            // Tarifs location
            if (forRent) ...[
              TextFormField(
                controller: _rentalDailyCtrl,
                decoration: InputDecoration(
                  labelText: l10n.vehiclesDailyRateLabel,
                  suffixText: 'FCFA${l10n.commonPerDaySuffix}',
                  hintText: '25 000',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsSeparatorFormatter()],
                validator: (v) {
                  if (forRent && _rentalRatesMissing) {
                    return l10n.vehiclesRentalRateRequired;
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _marge(_rentalDailyCtrl, libelle: l10n.vehiclesBuyerRateLabel),
              TextFormField(
                controller: _rentalMonthlyCtrl,
                decoration: InputDecoration(
                  labelText: l10n.vehiclesMonthlyRateLabel,
                  suffixText: 'FCFA${l10n.commonPerMonthSuffix}',
                  hintText: '450 000',
                  helperText: l10n.vehiclesRentalRateHint,
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsSeparatorFormatter()],
                validator: (_) => forRent && _rentalRatesMissing
                    ? l10n.vehiclesRentalRateRequired
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _marge(_rentalMonthlyCtrl, libelle: l10n.vehiclesBuyerRateLabel),
              // AUCUN recapitulatif sous la caution : elle est rendue au
              // locataire, donc le serveur ne la majore pas
              // (`MargePartenaire::CHAMPS_VEHICULE` l'exclut). Afficher une
              // marge ici annoncerait un total que personne n'encaissera.
              TextFormField(
                controller: _rentalDepositCtrl,
                decoration: InputDecoration(
                  labelText: l10n.vehiclesDepositLabel,
                  suffixText: 'FCFA',
                  hintText: '100 000',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsSeparatorFormatter()],
              ),
              const SizedBox(height: 12),
            ],

            // Prix négociable
            SwitchListTile(
              title: Text(l10n.vehiclesNegotiable),
              value: _negotiable,
              onChanged: (v) => setState(() => _negotiable = v),
              contentPadding: EdgeInsets.zero,
            ),

            // ── Localisation / agence ────────────────────────────────
            //
            // L'agence est une adresse de la boutique : `location_id` est refuse
            // a un partenaire par le serveur.
            if (widget.mode.peutChoisirLaBoutique &&
                refs.locations.isNotEmpty) ...[
              VehicleReferenceDropdown<LocationRef>(
                label: l10n.vehiclesBranchLabel,
                items: refs.locations,
                value: _selectedLocation,
                itemLabel: (l) => l.displayLabel,
                itemLeading: (l) => Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onChanged: (l) => setState(() => _selectedLocation = l),
              ),
              const SizedBox(height: 12),
            ] else if (widget.mode.peutChoisirLaBoutique) ...[
              // Fallback texte libre si aucune location configurée
              TextFormField(
                controller: _siteCtrl,
                decoration: InputDecoration(
                  labelText: l10n.vehiclesSiteLabel,
                  hintText: l10n.vehiclesSiteHint,
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Partenaire fournisseur ───────────────────────────────
            //
            // Le fournisseur source est une relation de la boutique. Un
            // partenaire n'a pas a rattacher son vehicule a un tiers, et le
            // serveur refuse `partner_id`.
            if (widget.mode.peutChoisirLaBoutique) ...[
              const SizedBox(height: 4),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                l10n.vehiclesSupplierLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.vehiclesSupplierHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              ref
                  .watch(_vehiclePartnersProvider)
                  .when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => Text(l10n.vehiclesPartnersLoadFailed),
                    data: (partners) => DropdownButtonFormField<int?>(
                      value: _selectedPartnerId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: l10n.vehiclesNoneOptional,
                        prefixIcon: Icon(Icons.handshake_outlined),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.vehiclesNone),
                        ),
                        ...partners.map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedPartnerId = v),
                    ),
                  ),
              const SizedBox(height: 16),
            ],

            // Description
            TextFormField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(
                labelText: l10n.catalogSectionDescription,
                hintText: l10n.vehiclesDescriptionHint,
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 2000,
            ),
          ],
        ),
      ),
    );
  }

  // ── Utilitaires ───────────────────────────────────────────────────

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ════════════════════════════════════════════════════════════════════
// Widgets génériques réutilisables dans le formulaire
// ════════════════════════════════════════════════════════════════════

// ── Contrôles du Stepper ────────────────────────────────────────────

class _StepControls extends StatelessWidget {
  final ControlsDetails details;
  final bool isLast;
  final bool submitting;

  const _StepControls({
    required this.details,
    required this.isLast,
    required this.submitting,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton(
            onPressed: submitting ? null : details.onStepContinue,
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isLast ? l10n.catalogFeaturesSave : l10n.vehiclesNext),
          ),
          if (details.stepIndex > 0)
            OutlinedButton(
              onPressed: details.onStepCancel,
              child: Text(l10n.vehiclesBack),
            ),
        ],
      ),
    );
  }
}

// ── Section équipements par catégorie ───────────────────────────────

/// Labels lisibles pour les catégories de features.
Map<String, String> _categoryLabels(AppLocalizations l10n) => {
  'dotation': l10n.vehiclesFeatureStandard,
  'confort': l10n.vehiclesFeatureComfort,
  'securite': l10n.vehiclesFeatureSafety,
  'multimedia': l10n.vehiclesFeatureMultimedia,
  'aide_conduite': l10n.vehiclesFeatureDriverAssistance,
  'autre': l10n.vehiclesFeatureOther,
};

/// Ordre d'affichage des catégories dans le formulaire.
const _categoryOrder = [
  'dotation',
  'confort',
  'securite',
  'multimedia',
  'aide_conduite',
  'autre',
];

class _FeatureCategorySection extends StatelessWidget {
  final String category;
  final List<FeatureRef> features;
  final Set<int> selectedFeatureIds;
  final void Function(int id, bool selected) onToggle;

  const _FeatureCategorySection({
    required this.category,
    required this.features,
    required this.selectedFeatureIds,
    required this.onToggle,
  });

  bool get _isDotation => category == 'dotation';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final label = _categoryLabels(l10n)[category] ?? category;
    final color = _isDotation ? Colors.amber.shade700 : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête de catégorie ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              if (_isDotation) ...[
                Icon(Icons.warning_amber_rounded, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              if (_isDotation) ...[
                const SizedBox(width: 6),
                Text(
                  l10n.vehiclesFeatureStandardHint,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: features.map((f) {
            final isSelected = selectedFeatureIds.contains(f.id);
            return FilterChip(
              label: Text(catalogFeatureLabel(f.name, l10n)),
              selected: isSelected,
              selectedColor: _isDotation ? Colors.amber.shade100 : null,
              checkmarkColor: _isDotation ? Colors.amber.shade800 : null,
              onSelected: (v) => onToggle(f.id, v),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Groupe de choix (remplace SegmentedButton sur petits écrans) ────
//
// Wrap + ChoiceChip : chaque chip prend sa largeur naturelle et passe
// à la ligne si besoin, sans rétrécir les autres.

class _ChoiceGroup<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T selected;
  final void Function(T) onChanged;

  const _ChoiceGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: options
        .map(
          (opt) => ChoiceChip(
            label: Text(opt.label),
            selected: selected == opt.value,
            onSelected: (_) => onChanged(opt.value),
          ),
        )
        .toList(),
  );
}

// ── Formateur : séparateur de milliers (espace) ─────────────────────

/// Formate un montant en entier avec séparateurs de milliers (espace).
/// Ex. : 15000000 → "15 000 000"
String _fmtPrice(double value) {
  final digits = value.toStringAsFixed(0);
  final buf = StringBuffer();
  final len = digits.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    final buf = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(' '); // espace fine insécable
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

// ── État de chargement en erreur ────────────────────────────────────

class _LoadingError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _LoadingError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56),
            const SizedBox(height: 12),
            Text(
              l10n.vehiclesReferencesLoadError(error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}

/// Nomme la cause, au lieu de l'appeler « Erreur serveur ».
///
/// Ce titre etait ecrit en dur. Toute panne de cet ecran — un champ refuse,
/// le reseau coupe, la session expiree — s'annoncait donc comme une panne du
/// serveur. Le defaut n'est pas cosmetique : il envoie chercher du cote du
/// serveur ce qui se repare a l'ecran, et il a reellement coute une enquete,
/// menee jusqu'a sonder la route de production, avant qu'on s'apercoive que
/// le titre ne disait rien de la cause.
String titreErreurEnregistrement(ApiException e, {AppLocalizations? l10n}) {
  l10n ??= AppLocalizationsFr();
  if (e.isNetworkFailure) return l10n.vehiclesErrorNetworkTitle;

  return switch (e.statusCode) {
    401 => l10n.vehiclesErrorSessionTitle,
    403 => l10n.vehiclesErrorForbiddenTitle,
    422 => l10n.vehiclesErrorValidationTitle,
    413 => l10n.vehiclesErrorTooLargeTitle,
    429 => l10n.vehiclesErrorThrottledTitle,
    final int c when c >= 500 => l10n.vehiclesErrorServerTitle,
    _ => l10n.vehiclesSaveFailed,
  };
}
