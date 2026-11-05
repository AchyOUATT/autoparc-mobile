import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/owned_vehicle.dart';
import '../providers/garage_provider.dart';

/// Values are independent: a commercial 1.8 L never invents an exact cc value.
class EngineDetailsController {
  EngineDetailsController({OwnedVehicle? vehicle})
    : litres = TextEditingController(
        text: vehicle?.engineDisplacementL?.toString() ?? '',
      ),
      cc = TextEditingController(
        text: vehicle?.engineDisplacementCc?.toString() ?? '',
      ),
      cylinders = TextEditingController(
        text: vehicle?.cylinders?.toString() ?? '',
      ),
      code = TextEditingController(text: vehicle?.engineCode ?? ''),
      power = TextEditingController(text: vehicle?.powerHp?.toString() ?? ''),
      layout = vehicle?.engineLayout;

  final TextEditingController litres, cc, cylinders, code, power;
  String? layout;

  Map<String, dynamic> toPayload() => {
    'engine_displacement_l': double.tryParse(
      litres.text.trim().replaceAll(',', '.'),
    ),
    'engine_displacement_cc': int.tryParse(cc.text.trim()),
    'cylinders': int.tryParse(cylinders.text.trim()),
    'engine_layout': layout,
    'engine_code': code.text.trim().isEmpty
        ? null
        : code.text.trim().toUpperCase(),
    'power_hp': int.tryParse(power.text.trim()),
  };

  void dispose() {
    for (final controller in [litres, cc, cylinders, code, power]) {
      controller.dispose();
    }
  }
}

class EngineDetailsFields extends StatefulWidget {
  const EngineDetailsFields({
    super.key,
    required this.controller,
    this.onCodeChanged,
  });
  final EngineDetailsController controller;
  final ValueChanged<String>? onCodeChanged;

  @override
  State<EngineDetailsFields> createState() => _EngineDetailsFieldsState();
}

class _EngineDetailsFieldsState extends State<EngineDetailsFields> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.controller;
    Widget number(
      String key,
      String label,
      TextEditingController controller,
      int max, {
      bool decimal = false,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: ValueKey(key),
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            helperText: decimal ? '> 0 – $max L' : '1 – $max',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          validator: (raw) {
            final text = (raw ?? '').trim().replaceAll(',', '.');
            if (text.isEmpty) return null;
            final validFormat = RegExp(
              decimal ? r'^\d+(?:\.\d{1,3})?$' : r'^\d+$',
            ).hasMatch(text);
            final value = num.tryParse(text);
            return validFormat && value != null && value > 0 && value <= max
                ? null
                : l10n.garageEngineNumberInvalid;
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.garageEngineDetailsHelp),
        const SizedBox(height: 16),
        number(
          'engine-litres',
          l10n.garageEngineLitres,
          c.litres,
          30,
          decimal: true,
        ),
        number('engine-cc', l10n.garageEngineCc, c.cc, 30000),
        number('engine-cylinders', l10n.garageEngineCylinders, c.cylinders, 24),
        DropdownButtonFormField<String>(
          key: const ValueKey('engine-layout'),
          initialValue:
              const ['inline', 'v', 'boxer', 'w', 'other'].contains(c.layout)
              ? c.layout
              : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.garageEngineLayout),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(l10n.garageEngineUnspecified),
            ),
            for (final value in ['inline', 'v', 'boxer', 'w', 'other'])
              DropdownMenuItem(
                value: value,
                child: Text(engineLayoutLabel(value, l10n)),
              ),
          ],
          onChanged: (value) => setState(() => c.layout = value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('engine-code'),
          controller: c.code,
          decoration: InputDecoration(
            labelText: l10n.garageEngineCode,
            hintText: '2ZR-FE',
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: widget.onCodeChanged,
          validator: (value) => (value?.trim().length ?? 0) > 20
              ? l10n.garageEngineCodeInvalid
              : null,
        ),
        const SizedBox(height: 12),
        number('engine-power', l10n.garageEnginePower, c.power, 5000),
      ],
    );
  }
}

String engineLayoutLabel(String value, AppLocalizations l10n) =>
    switch (value) {
      'inline' => l10n.garageEngineInline,
      'v' => l10n.garageEngineV,
      'boxer' => l10n.garageEngineBoxer,
      'w' => l10n.garageEngineW,
      _ => l10n.garageEngineOther,
    };

Future<bool> showEngineDetailsDialog(
  BuildContext context,
  OwnedVehicle vehicle,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _EngineDetailsDialog(vehicle: vehicle),
    ) ??
    false;

class EngineDetailsTile extends StatelessWidget {
  const EngineDetailsTile({super.key, required this.vehicle});
  final OwnedVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final number = NumberFormat(
      '0.###',
      Localizations.localeOf(context).toString(),
    );
    final details = [
      if (vehicle.engineDisplacementL != null)
        '${number.format(vehicle.engineDisplacementL)} L',
      if (vehicle.engineDisplacementCc != null)
        '${vehicle.engineDisplacementCc} cm³',
      if (vehicle.cylinders != null)
        l10n.garageEngineCylindersValue(vehicle.cylinders!),
      if (vehicle.engineLayout != null)
        engineLayoutLabel(vehicle.engineLayout!, l10n),
      if (vehicle.engineCode?.trim().isNotEmpty == true) vehicle.engineCode!,
      if (vehicle.powerHp != null)
        l10n.garageEnginePowerValue(vehicle.powerHp!),
    ];
    return ListTile(
      leading: const Icon(Icons.settings_outlined),
      title: Text(l10n.garageEngineDetailsTitle),
      subtitle: Text(
        details.isEmpty ? l10n.garageEngineAddDetails : details.join(' · '),
      ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => showEngineDetailsDialog(context, vehicle),
    );
  }
}

class _EngineDetailsDialog extends ConsumerStatefulWidget {
  const _EngineDetailsDialog({required this.vehicle});
  final OwnedVehicle vehicle;
  @override
  ConsumerState<_EngineDetailsDialog> createState() =>
      _EngineDetailsDialogState();
}

class _EngineDetailsDialogState extends ConsumerState<_EngineDetailsDialog> {
  late final _details = EngineDetailsController(vehicle: widget.vehicle);
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref
        .read(garageProvider.notifier)
        .updateVehicle(widget.vehicle.id, _details.toPayload());
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.garageEngineDetailsTitle),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EngineDetailsFields(controller: _details),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.catalogFeaturesSave),
        ),
      ],
    );
  }
}
