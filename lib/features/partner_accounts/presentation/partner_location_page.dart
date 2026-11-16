import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import 'partner_session.dart';

/// L'emplacement par defaut du compte partenaire.
class PartnerLocationPage extends ConsumerStatefulWidget {
  const PartnerLocationPage({super.key});

  @override
  ConsumerState<PartnerLocationPage> createState() =>
      _PartnerLocationPageState();
}

class _PartnerLocationPageState extends ConsumerState<PartnerLocationPage> {
  final _form = GlobalKey<FormState>();
  final _city = TextEditingController();
  final _address = TextEditingController();
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(partnerSessionProvider).profile;
    _city.text = profile?.city ?? '';
    _address.text = profile?.address ?? '';
    _ready = true;
  }

  @override
  void dispose() {
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false) || _saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(partnerSessionProvider.notifier)
          .updateEmplacement(
            city: _city.text.trim().isEmpty ? null : _city.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            clearAddress: _address.text.trim().isEmpty,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.partnerLocationSaved)));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messageFor(error, l10n: l10n))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerLocationTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: !_ready
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _form,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          l10n.partnerLocationSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          key: const Key('partner-location-city'),
                          controller: _city,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          maxLength: 100,
                          decoration: InputDecoration(
                            labelText: l10n.partnerLocationCityLabel,
                            prefixIcon: const Icon(
                              Icons.location_city_outlined,
                            ),
                            border: const OutlineInputBorder(),
                            counterText: '',
                          ),
                          // Le defaut est facultatif : le partenaire peut
                          // l'effacer, et remplir la ville sur chaque annonce.
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('partner-location-address'),
                          controller: _address,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 120,
                          decoration: InputDecoration(
                            labelText: l10n.partnerLocationAddressLabel,
                            hintText: l10n.partnerLocationAddressHint,
                            prefixIcon: const Icon(Icons.place_outlined),
                            border: const OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            _saving
                                ? l10n.partnerLocationSaving
                                : l10n.partnerLocationSave,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
