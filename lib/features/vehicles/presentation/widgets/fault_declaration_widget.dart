import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/fault_declaration.dart';
import '../../data/models/repair_estimate.dart';
import '../../data/models/vehicle_fault.dart';
import 'declared_faults_section.dart';
import 'vehicle_fault_labels.dart';

/// Controlled draft editor. An empty list never confirms absence of faults.
/// The owning form saves [FaultDeclaration.toPayload] on its own API route.
class FaultDeclarationWidget extends StatefulWidget {
  final FaultDeclaration value;
  final ValueChanged<FaultDeclaration> onChanged;
  final bool enabled;
  final bool staffStatuses;
  final bool requireChoice;

  const FaultDeclarationWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.staffStatuses = false,
    this.requireChoice = false,
  });

  @override
  State<FaultDeclarationWidget> createState() => _FaultDeclarationWidgetState();
}

class _FaultDeclarationWidgetState extends State<FaultDeclarationWidget> {
  final _field = GlobalKey<FormFieldState<FaultDeclaration>>();
  bool _busy = false;

  void _notify(FaultDeclaration next) {
    if (!mounted || !widget.enabled) return;
    widget.onChanged(next);
    _field.currentState?.didChange(next);
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _select(String? state) async {
    if (state == null ||
        !widget.enabled ||
        _busy ||
        state == widget.value.state) {
      return;
    }
    final l = AppLocalizations.of(context);
    final original = widget.value;
    if (state == 'unknown' && original.faults.isNotEmpty) {
      _message(l.faultDeclarationKeepFaultsBeforeUnknown);
      return;
    }
    if (state == 'none' && original.hasReadOnlyFaults) {
      _message(l.faultDeclarationReadOnlyBlocksNone);
      return;
    }
    if (state == 'none' && original.faults.isNotEmpty) {
      setState(() => _busy = true);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.faultDeclarationClearTitle),
          content: Text(l.faultDeclarationClearMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.faultDeclarationClearConfirm),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (!widget.enabled || confirmed != true) return;
      if (!identical(original, widget.value)) {
        _message(l.faultDeclarationChangedElsewhere);
        return;
      }
      _notify(original.copyWith(state: 'none', faults: const []));
      return;
    }
    _notify(original.copyWith(state: state));
  }

  Future<void> _edit([DeclaredVehicleFault? fault]) async {
    if (!widget.enabled || _busy || fault?.editable == false) return;
    final original = widget.value;
    if (fault == null && original.faults.length >= 100) {
      _message(AppLocalizations.of(context).faultDeclarationFaultLimit);
      return;
    }
    setState(() => _busy = true);
    final updated = await showModalBottomSheet<DeclaredVehicleFault>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _FaultDraftSheet(fault: fault, staffStatuses: widget.staffStatuses),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!widget.enabled || updated == null) return;
    if (!identical(original, widget.value)) {
      _message(AppLocalizations.of(context).faultDeclarationChangedElsewhere);
      return;
    }
    final faults = [...original.faults];
    if (fault == null) {
      faults.add(updated);
    } else {
      final index = faults.indexOf(fault);
      if (index < 0) return;
      faults[index] = updated;
    }
    _notify(original.copyWith(state: 'has_faults', faults: faults));
  }

  void _remove(DeclaredVehicleFault fault) {
    if (!widget.enabled || _busy || !fault.editable) return;
    final faults = [...widget.value.faults]..remove(fault);
    // Removing the last entry does not make an affirmative "none" statement.
    _notify(widget.value.copyWith(faults: faults));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final value = widget.value;
    final enabled = widget.enabled && !_busy;
    return FormField<FaultDeclaration>(
      key: _field,
      initialValue: value,
      enabled: widget.enabled,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) {
        if (!widget.enabled) return null;
        if (widget.value.state == 'unknown') {
          return widget.requireChoice
              ? l.faultDeclarationPrivateSubmitRequired
              : null;
        }
        if (widget.value.state == 'has_faults' && widget.value.faults.isEmpty) {
          return l.faultDeclarationListRequired;
        }
        return widget.value.canSubmit ? null : l.faultDeclarationInvalidFault;
      },
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.faultDeclarationTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(l.faultDeclarationChoiceHint),
          RadioGroup<String>(
            groupValue: value.state,
            onChanged: _select,
            child: Column(
              children: [
                RadioListTile<String>(
                  key: const ValueKey('fault-declaration-state-unknown'),
                  value: 'unknown',
                  enabled: enabled,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.faultDeclarationUnknown),
                ),
                RadioListTile<String>(
                  key: const ValueKey('fault-declaration-state-none'),
                  value: 'none',
                  enabled: enabled,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.faultDeclarationNoneSeller),
                ),
                RadioListTile<String>(
                  key: const ValueKey('fault-declaration-state-has_faults'),
                  value: 'has_faults',
                  enabled: enabled,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.faultDeclarationHasFaults),
                ),
              ],
            ),
          ),
          // Preserve and show received rows even for an unknown legacy state.
          for (var index = 0; index < value.faults.length; index++)
            DeclaredFaultCard(
              fault: value.faults[index],
              actions: value.faults[index].editable
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          key: ValueKey('fault-declaration-edit-$index'),
                          onPressed: enabled
                              ? () => _edit(value.faults[index])
                              : null,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l.catalogEditTooltip),
                        ),
                        TextButton.icon(
                          key: ValueKey('fault-declaration-remove-$index'),
                          onPressed: enabled
                              ? () => _remove(value.faults[index])
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l.catalogDeleteAction),
                        ),
                      ],
                    )
                  : Text(
                      l.faultDeclarationReadOnlyNotice,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
            ),
          if (value.state == 'has_faults')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                key: const ValueKey('fault-declaration-add'),
                onPressed: enabled && value.faults.length < 100
                    ? () => _edit()
                    : null,
                icon: const Icon(Icons.add),
                label: Text(l.faultDeclarationAdd),
              ),
            ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            l.faultDeclarationSellerNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FaultDraftSheet extends StatefulWidget {
  final DeclaredVehicleFault? fault;
  final bool staffStatuses;
  const _FaultDraftSheet({this.fault, required this.staffStatuses});
  @override
  State<_FaultDraftSheet> createState() => _FaultDraftSheetState();
}

class _FaultDraftSheetState extends State<_FaultDraftSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _category, _severity, _status, _necessity;
  late bool _affectsDrivability, _isSafetyCritical, _disclosedToBuyer;
  late final TextEditingController _costMin;
  late final TextEditingController _costMax;
  String? _source;
  DateTime? _estimatedAt;

  @override
  void initState() {
    super.initState();
    final fault = widget.fault;
    _title = TextEditingController(text: fault?.title ?? '');
    _description = TextEditingController(text: fault?.description ?? '');
    _category = fault?.category ?? 'other';
    _severity = fault?.severity ?? 'minor';
    _status = fault?.status ?? 'declared';
    _affectsDrivability = fault?.affectsDrivability ?? false;
    _isSafetyCritical = fault?.isSafetyCritical ?? false;
    _disclosedToBuyer = fault?.disclosedToBuyer ?? true;
    _necessity = fault?.repairNecessity == 'optional'
        ? 'optional'
        : 'necessary';
    final estimate = fault?.repairEstimate;
    _costMin = TextEditingController(
      text: estimate == null ? '' : '${estimate.costMin}',
    );
    _costMax = TextEditingController(
      text: estimate == null ? '' : '${estimate.costMax}',
    );
    _source = estimate?.source;
    _estimatedAt = estimate?.estimatedAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _costMin.dispose();
    _costMax.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      DeclaredVehicleFault(
        id: widget.fault?.id,
        category: _category,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        severity: _severity,
        status: _status,
        affectsDrivability: _affectsDrivability,
        isSafetyCritical: _isSafetyCritical,
        disclosedToBuyer: _disclosedToBuyer,
        editable: widget.fault?.editable ?? true,
        repairNecessity: _necessity,
        repairEstimate: _estimateOrNull(),
      ),
    );
  }

  bool get _anyEstimateField =>
      _costMin.text.trim().isNotEmpty ||
      _costMax.text.trim().isNotEmpty ||
      _source != null ||
      _estimatedAt != null;

  RepairEstimate? _estimateOrNull() {
    if (!_anyEstimateField) return null;
    final min = int.tryParse(_costMin.text.trim().replaceAll(' ', ''));
    final max = int.tryParse(_costMax.text.trim().replaceAll(' ', ''));
    if (min == null || max == null || _source == null || _estimatedAt == null) {
      return null;
    }
    return RepairEstimate(
      costMin: min,
      costMax: max,
      source: _source!,
      estimatedAt: _estimatedAt!,
    );
  }

  String? _validateEstimate(AppLocalizations l) {
    if (!_anyEstimateField) return null;
    final min = int.tryParse(_costMin.text.trim().replaceAll(' ', ''));
    final max = int.tryParse(_costMax.text.trim().replaceAll(' ', ''));
    if (min == null || max == null || _source == null || _estimatedAt == null) {
      return l.repairEstimateIncomplete;
    }
    if (min < 0 || min > max) return l.repairEstimateMinMax;
    final today = DateTime.now();
    final day = DateTime(
      _estimatedAt!.year,
      _estimatedAt!.month,
      _estimatedAt!.day,
    );
    final last = DateTime(today.year, today.month, today.day);
    if (day.isAfter(last)) return l.repairEstimateFutureDate;
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _estimatedAt == null || _estimatedAt!.isAfter(last)
          ? last
          : _estimatedAt!,
      firstDate: DateTime(now.year - 20),
      lastDate: last,
    );
    if (picked != null) setState(() => _estimatedAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final categories = faultCategories
        .map((category) => category.value)
        .toList();
    final severities = faultSeverities
        .map((severity) => severity.value)
        .toList();
    final statuses = widget.staffStatuses
        ? DeclaredVehicleFault.staffStatuses
        : DeclaredVehicleFault.privateStatuses;
    final sources = widget.staffStatuses
        ? RepairEstimate.sources
        : const ['seller', 'workshop'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.fault == null
                      ? l.vehiclesFaultCreateTitle
                      : l.faultDeclarationEdit,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('fault-declaration-title'),
                  controller: _title,
                  maxLength: 180,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.vehiclesFaultTitleLabel,
                    hintText: l.vehiclesFaultTitleHint,
                  ),
                  validator: (value) => value?.trim().isEmpty != false
                      ? l.vehiclesFaultTitleRequired
                      : value!.runes.length > 180
                      ? l.faultDeclarationTitleTooLong
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('fault-declaration-category'),
                  initialValue: categories.contains(_category)
                      ? _category
                      : null,
                  hint: Text(vehicleFaultCategoryLabel(_category, l)),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.vehiclesFaultCategoryLabel,
                  ),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category,
                        child: Text(vehicleFaultCategoryLabel(category, l)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                  validator: (_) => categories.contains(_category)
                      ? null
                      : l.faultDeclarationInvalidFault,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('fault-declaration-description'),
                  controller: _description,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 5000,
                  decoration: InputDecoration(
                    labelText: l.vehiclesFaultDescriptionLabel,
                    hintText: l.vehiclesFaultDescriptionHint,
                  ),
                  validator: (value) => (value?.runes.length ?? 0) > 5000
                      ? l.faultDeclarationDescriptionTooLong
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('fault-declaration-severity'),
                  initialValue: severities.contains(_severity)
                      ? _severity
                      : null,
                  hint: Text(vehicleFaultSeverityLabel(_severity, l)),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.vehiclesFaultSeverityLabel,
                  ),
                  items: [
                    for (final severity in severities)
                      DropdownMenuItem(
                        value: severity,
                        child: Text(vehicleFaultSeverityLabel(severity, l)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _severity = value ?? _severity),
                  validator: (_) => severities.contains(_severity)
                      ? null
                      : l.faultDeclarationInvalidFault,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('fault-declaration-status'),
                  initialValue: statuses.contains(_status) ? _status : null,
                  hint: Text(vehicleFaultStatusLabel(_status, l)),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.faultDeclarationStatusLabel,
                  ),
                  items: [
                    for (final status in statuses)
                      DropdownMenuItem(
                        value: status,
                        child: Text(vehicleFaultStatusLabel(status, l)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                  validator: (_) => statuses.contains(_status)
                      ? null
                      : l.faultDeclarationInvalidFault,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.vehiclesFaultAffectsDriving),
                  value: _affectsDrivability,
                  onChanged: (value) =>
                      setState(() => _affectsDrivability = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.vehiclesFaultSafetyCritical),
                  value: _isSafetyCritical,
                  onChanged: (value) =>
                      setState(() => _isSafetyCritical = value),
                ),
                if (widget.staffStatuses)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.vehiclesFaultDisclosureLabel),
                    subtitle: Text(l.vehiclesFaultDisclosureHint),
                    value: _disclosedToBuyer,
                    onChanged: (value) =>
                        setState(() => _disclosedToBuyer = value),
                  ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  key: const ValueKey('fault-declaration-necessity'),
                  initialValue: _necessity,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.repairNecessityLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'necessary',
                      child: Text(
                        l.repairEstimateNecessary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'optional',
                      child: Text(
                        l.repairEstimateOptional,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _necessity = value ?? _necessity),
                ),
                const SizedBox(height: 16),
                Text(
                  l.repairEstimateTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l.repairEstimateOptionalHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('fault-declaration-cost-min'),
                  controller: _costMin,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.repairEstimateCostMin,
                  ),
                  validator: (_) => _validateEstimate(l),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('fault-declaration-cost-max'),
                  controller: _costMax,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.repairEstimateCostMax,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('fault-declaration-estimate-source'),
                  initialValue: sources.contains(_source) ? _source : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.repairEstimateSource,
                  ),
                  items: [
                    for (final source in sources)
                      DropdownMenuItem(
                        value: source,
                        child: Text(
                          repairEstimateSourceLabel(source, l),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _source = value),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(labelText: l.repairEstimateDate),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          key: const ValueKey(
                            'fault-declaration-estimate-date',
                          ),
                          _estimatedAt == null
                              ? '—'
                              : DateFormat('yyyy-MM-dd').format(_estimatedAt!),
                        ),
                      ),
                      IconButton(
                        onPressed: _pickDate,
                        tooltip: l.repairEstimateDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.fault?.id == null
                      ? l.repairQuoteAttachAfterSave
                      : l.repairQuotePrivateNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 8),
                Text(
                  l.faultDeclarationSellerNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.commonCancel),
                    ),
                    FilledButton(
                      key: const ValueKey('fault-declaration-apply'),
                      onPressed: _save,
                      child: Text(l.faultDeclarationApply),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
