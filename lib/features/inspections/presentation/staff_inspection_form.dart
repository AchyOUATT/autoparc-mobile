import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../data/staff_inspection.dart';
import '../data/staff_inspection_repository.dart';

Future<StaffInspectionReport?> showStaffInspectionForm(
  BuildContext context, {
  required String source,
  required int sourceId,
}) => showDialog<StaffInspectionReport>(
  context: context,
  barrierDismissible: false,
  builder: (_) => StaffInspectionForm(source: source, sourceId: sourceId),
);

/// Staff-only entry point. The section controls visibility, the server enforces
/// the actual permission, confirmation and target validity on every save.
class StaffInspectionForm extends ConsumerStatefulWidget {
  final String source;
  final int sourceId;
  const StaffInspectionForm({
    super.key,
    required this.source,
    required this.sourceId,
  });

  @override
  ConsumerState<StaffInspectionForm> createState() =>
      _StaffInspectionFormState();
}

class _InspectionPointDraft {
  final label = TextEditingController();
  final note = TextEditingController();
  String status = 'not_checked';
  void dispose() {
    label.dispose();
    note.dispose();
  }
}

class _StaffInspectionFormState extends ConsumerState<StaffInspectionForm> {
  final _form = GlobalKey<FormState>();
  final _mileage = TextEditingController();
  final _summary = TextEditingController();
  final _points = [_InspectionPointDraft()];
  DateTime _date = DateTime.now();
  DateTime? _validUntil;
  bool _hasValidity = false;
  bool _confirmed = false;
  bool _saving = false;
  String? _validation;
  Object? _error;

  @override
  void dispose() {
    _mileage.dispose();
    _summary.dispose();
    for (final point in _points) {
      point.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({bool validity = false}) async {
    final today = DateTime.now();
    final first = validity
        ? DateTime(_date.year, _date.month, _date.day)
        : DateTime(1900);
    final last = validity ? DateTime(today.year + 20, 12, 31) : today;
    var initial = validity ? (_validUntil ?? today) : _date;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (validity) {
        _validUntil = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final fieldsValid = _form.currentState!.validate();
    String? invalid;
    if (_date.isAfter(DateTime.now())) invalid = l.inspectionDateFuture;
    if (_hasValidity && (_validUntil == null || !_validUntil!.isAfter(_date))) {
      invalid = l.inspectionValidityDateError;
    }
    if (!_points.any((point) => point.status != 'not_checked')) {
      invalid = l.inspectionAtLeastOneChecked;
    }
    if (!_confirmed) invalid = l.inspectionConfirmationRequired;
    setState(() {
      _validation = invalid;
      _error = null;
    });
    if (!fieldsValid || invalid != null) return;
    setState(() => _saving = true);
    try {
      final report = await ref
          .read(staffInspectionRepositoryProvider)
          .create(widget.source, widget.sourceId, {
            'inspected_at': _date.toUtc().toIso8601String(),
            'mileage_km': int.parse(_mileage.text.trim()),
            'valid_until': _hasValidity
                ? _validUntil!.toUtc().toIso8601String()
                : null,
            'summary': _summary.text.trim(),
            'items': _points
                .map(
                  (point) => StaffInspectionItem(
                    label: point.label.text,
                    status: point.status,
                    note: point.note.text,
                  ).toJson(),
                )
                .toList(growable: false),
            'confirmed': true,
          });
      if (mounted) Navigator.pop(context, report);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dates = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    );
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(l.inspectionFormTitle),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.inspectionFormIntro),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _pickDate(),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${l.inspectionDateLabel} : ${dates.format(_date)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('inspection-mileage'),
                    controller: _mileage,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l.inspectionMileageLabel,
                      suffixText: 'km',
                    ),
                    validator: (value) =>
                        int.tryParse(value?.trim() ?? '') == null
                        ? l.inspectionMileageRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('inspection-summary'),
                    controller: _summary,
                    enabled: !_saving,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 4000,
                    decoration: InputDecoration(
                      labelText: l.inspectionSummaryLabel,
                    ),
                    validator: (value) => value?.trim().isEmpty != false
                        ? l.inspectionSummaryRequired
                        : null,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _points.length; i++)
                    _pointFields(_points[i], i, l),
                  OutlinedButton.icon(
                    key: const ValueKey('inspection-add-point'),
                    onPressed: _saving || _points.length >= 100
                        ? null
                        : () => setState(
                            () => _points.add(_InspectionPointDraft()),
                          ),
                    icon: const Icon(Icons.add),
                    label: Text(l.inspectionAddPoint),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.inspectionValidityOptional),
                    value: _hasValidity,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _hasValidity = value),
                  ),
                  if (_hasValidity)
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _pickDate(validity: true),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        _validUntil == null
                            ? l.inspectionChooseDate
                            : '${l.inspectionValidUntilLabel} : ${dates.format(_validUntil!)}',
                      ),
                    ),
                  CheckboxListTile(
                    key: const ValueKey('inspection-confirmation'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l.inspectionConfirmation),
                    value: _confirmed,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _confirmed = value == true),
                  ),
                  if (_validation != null)
                    Text(
                      _validation!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        messageFor(_error, l10n: l),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(l.commonCancel),
          ),
          FilledButton.icon(
            key: const ValueKey('inspection-save'),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(l.inspectionSave),
          ),
        ],
      ),
    );
  }

  Widget _pointFields(
    _InspectionPointDraft point,
    int index,
    AppLocalizations l,
  ) => Card(
    key: ObjectKey(point),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('inspection-point-label-$index'),
            controller: point.label,
            enabled: !_saving,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: l.inspectionPointLabel,
              hintText: l.inspectionPointHint,
            ),
            validator: (value) => value?.trim().isEmpty != false
                ? l.inspectionPointRequired
                : null,
          ),
          DropdownButtonFormField<String>(
            key: ValueKey('inspection-point-status-$index'),
            initialValue: point.status,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.inspectionPointStatus),
            items: [
              DropdownMenuItem(
                value: 'not_checked',
                child: Text(l.inspectionStatusNotChecked),
              ),
              DropdownMenuItem(value: 'ok', child: Text(l.inspectionStatusOk)),
              DropdownMenuItem(
                value: 'attention',
                child: Text(l.inspectionStatusAttention),
              ),
              DropdownMenuItem(
                value: 'blocking',
                child: Text(l.inspectionStatusBlocking),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) =>
                      setState(() => point.status = value ?? 'not_checked'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('inspection-point-note-$index'),
            controller: point.note,
            enabled: !_saving,
            minLines: 1,
            maxLines: 3,
            maxLength: 2000,
            decoration: InputDecoration(labelText: l.inspectionPointNote),
          ),
          if (_points.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() => _points.remove(point));
                        // Text fields release their listeners at the end of the frame.
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => point.dispose(),
                        );
                      },
                icon: const Icon(Icons.delete_outline),
                label: Text(l.inspectionRemovePoint),
              ),
            ),
        ],
      ),
    ),
  );
}
