import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../private_sales/data/private_listing_margin_repository.dart';

class PrivateListingMarginSettingsPage extends ConsumerStatefulWidget {
  const PrivateListingMarginSettingsPage({super.key});

  @override
  ConsumerState<PrivateListingMarginSettingsPage> createState() =>
      _PrivateListingMarginSettingsPageState();
}

class _PrivateListingMarginSettingsPageState
    extends ConsumerState<PrivateListingMarginSettingsPage> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _form = GlobalKey<FormState>();
  final _taux = TextEditingController();
  PrivateListingMargin? _saved;
  bool _loading = true;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _taux.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || !ref.read(authProvider).canManagePrivateListingMargin) {
      return;
    }
    setState(() {
      _loading = true;
      _loaded = false;
      _error = null;
    });
    try {
      final setting = await ref
          .read(privateListingMarginRepositoryProvider)
          .lireReglage();
      if (!mounted) return;
      _saved = setting;
      _taux.text = _afficherTaux(setting.taux);
      _loaded = true;
    } catch (error) {
      if (mounted) setState(() => _error = messageFor(error, l10n: l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving ||
        !_loaded ||
        !ref.read(authProvider).canManagePrivateListingMargin ||
        !_form.currentState!.validate()) {
      return;
    }
    final valeur = double.parse(_taux.text.trim().replaceAll(',', '.'));
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final setting = await ref
          .read(privateListingMarginRepositoryProvider)
          .enregistrer(valeur);
      if (!mounted) return;
      _saved = setting;
      _taux.text = _afficherTaux(setting.taux);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsPrivateListingMarginSaved)),
      );
    } catch (error) {
      if (mounted) setState(() => _error = messageFor(error, l10n: l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _afficherTaux(double taux) =>
      taux == taux.roundToDouble() ? '${taux.round()}' : '$taux';

  String? _valider(String? value) {
    final brut = (value ?? '').trim().replaceAll(',', '.');
    final nombre = double.tryParse(brut);
    if (nombre == null) return l10n.settingsPrivateListingMarginInvalid;
    if (nombre < 0 || nombre > 50) {
      return l10n.settingsPrivateListingMarginRange;
    }
    if ((nombre * 10 - (nombre * 10).round()).abs() > 0.0001) {
      return l10n.settingsPrivateListingMarginDecimals;
    }
    return null;
  }

  String? _derniereModification() {
    final saved = _saved;
    if (saved == null || saved.modifieLe == null) return null;
    final quand = DateFormat.yMMMd(
      l10n.localeName,
    ).add_Hm().format(saved.modifieLe!.toLocal());
    final auteur = saved.modifieParNom;
    final precedent = saved.tauxPrecedent;
    return l10n.settingsPrivateListingMarginLastChange(
      _afficherTaux(saved.taux),
      precedent == null ? '—' : _afficherTaux(precedent),
      auteur == null || auteur.isEmpty
          ? l10n.settingsPrivateListingMarginUnknownAuthor
          : auteur,
      quand,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (previous?.canManagePrivateListingMargin != true &&
          next.canManagePrivateListingMargin) {
        _load();
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivateListingMarginTitle)),
      body: auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !auth.canManagePrivateListingMargin
          ? Center(child: Text(l10n.settingsPrivateListingMarginAccessDenied))
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && !_loaded
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _load, child: Text(l10n.commonRetry)),
                  ],
                ),
              ),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    l10n.settingsPrivateListingMarginHeading,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.settingsPrivateListingMarginDescription),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('private-listing-margin-rate'),
                    controller: _taux,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.settingsPrivateListingMarginLabel,
                      suffixText: '%',
                      helperText: l10n.settingsPrivateListingMarginHelp,
                    ),
                    validator: _valider,
                    onFieldSubmitted: (_) {
                      if (!_saving) _save();
                    },
                  ),
                  if (_derniereModification() case final detail?) ...[
                    const SizedBox(height: 16),
                    Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  if (_error != null && _loaded) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving
                          ? l10n.settingsPrivateListingMarginSaving
                          : l10n.settingsPrivateListingMarginSave,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
