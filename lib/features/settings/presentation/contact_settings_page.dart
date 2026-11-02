import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/contact/autoparc_contact_provider.dart';
import '../../../l10n/app_localizations.dart';

class ContactSettingsPage extends ConsumerStatefulWidget {
  const ContactSettingsPage({super.key});

  @override
  ConsumerState<ContactSettingsPage> createState() =>
      _ContactSettingsPageState();
}

class _ContactSettingsPageState extends ConsumerState<ContactSettingsPage> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
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
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || !ref.read(authProvider).canManageSettings) return;
    setState(() {
      _loading = true;
      _loaded = false;
      _error = null;
    });
    try {
      final contact = await ref
          .read(autoparcContactProvider.notifier)
          .loadSettings();
      if (!mounted) return;
      _phone.text = contact.phoneDisplay;
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
        !ref.read(authProvider).canManageSettings ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final contact = await ref
          .read(autoparcContactProvider.notifier)
          .save(_phone.text);
      if (!mounted) return;
      _phone.text = contact.phoneDisplay;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsContactSaved)));
    } catch (error) {
      if (mounted) setState(() => _error = messageFor(error, l10n: l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (previous?.canManageSettings != true && next.canManageSettings) {
        _load();
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsContactTitle)),
      body: auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !auth.canManageSettings
          ? Center(child: Text(l10n.settingsContactAccessDenied))
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
                    l10n.settingsContactPhoneTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.settingsContactPhoneDescription),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('autoparc-contact-phone'),
                    controller: _phone,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      labelText: l10n.settingsContactPhoneLabel,
                      hintText: '+226 75 57 04 84',
                      helperText: l10n.settingsContactCountryCodeHelp,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (value) => AutoParcContact.isValid(value ?? '')
                        ? null
                        : l10n.settingsContactPhoneInvalid,
                    onFieldSubmitted: (_) {
                      if (!_saving) _save();
                    },
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('save-autoparc-contact'),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving
                          ? l10n.settingsContactSaving
                          : l10n.settingsContactSave,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
