import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../../../core/api/api_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/equipment_documents_repository.dart';
import 'vehicle_form_mode.dart';

const equipmentDocumentMaxBytes = 8 * 1024 * 1024;
const _documentExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];
typedef EquipmentDocumentPicker = Future<PlatformFile?> Function();
typedef EquipmentDocumentExporter =
    Future<void> Function({
      required Uint8List bytes,
      required String filename,
      required String mimeType,
      required Rect origin,
    });

final equipmentDocumentPickerProvider = Provider<EquipmentDocumentPicker>(
  (ref) => () async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _documentExtensions,
      withData: false,
      withReadStream: true,
    );
    return result?.files.firstOrNull;
  },
);

final equipmentDocumentExporterProvider = Provider<EquipmentDocumentExporter>(
  (ref) =>
      ({
        required bytes,
        required filename,
        required mimeType,
        required origin,
      }) async {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(bytes, mimeType: mimeType, name: filename)],
            fileNameOverrides: [filename],
            sharePositionOrigin: origin,
          ),
        );
      },
);

class EquipmentDocumentTooLarge implements Exception {
  const EquipmentDocumentTooLarge();
}

/// Rejects large picker metadata before reading, then bounds every stream chunk.
Future<Uint8List> readEquipmentDocument(PlatformFile file) async {
  if (file.size > equipmentDocumentMaxBytes) {
    throw const EquipmentDocumentTooLarge();
  }
  final stream = file.readStream;
  if (stream == null) {
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('The selected file has no readable data.');
    }
    if (bytes.length > equipmentDocumentMaxBytes) {
      throw const EquipmentDocumentTooLarge();
    }
    return bytes;
  }
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    if (builder.length + chunk.length > equipmentDocumentMaxBytes) {
      throw const EquipmentDocumentTooLarge();
    }
    builder.add(chunk);
  }
  return builder.takeBytes();
}

String _typeLabel(AppLocalizations l10n, EquipmentDocumentType type) =>
    switch (type) {
      EquipmentDocumentType.ownership => l10n.equipmentDocumentOwnership,
      EquipmentDocumentType.registration => l10n.equipmentDocumentRegistration,
      EquipmentDocumentType.inspection => l10n.equipmentDocumentInspection,
      EquipmentDocumentType.insurance => l10n.equipmentDocumentInsurance,
      EquipmentDocumentType.other => l10n.equipmentDocumentOther,
    };

/// Optional administrative documents, always accessed with the current session.
class EquipmentDocumentsPage extends ConsumerStatefulWidget {
  const EquipmentDocumentsPage({
    super.key,
    required this.vehicleId,
    required this.mode,
  });
  final int vehicleId;
  final VehicleFormMode mode;

  @override
  ConsumerState<EquipmentDocumentsPage> createState() =>
      _EquipmentDocumentsPageState();
}

class _EquipmentDocumentsPageState
    extends ConsumerState<EquipmentDocumentsPage> {
  List<EquipmentDocument>? _documents;
  Object? _loadError;
  bool _loading = true;
  bool _busy = false;
  AppLocalizations get l10n => AppLocalizations.of(context);
  EquipmentDocumentsRepository get _repository =>
      ref.read(equipmentDocumentsRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EquipmentDocumentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleId != widget.vehicleId ||
        oldWidget.mode != widget.mode) {
      _documents = null;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final vehicleId = widget.vehicleId;
    final mode = widget.mode;
    try {
      final documents = await _repository.documents(vehicleId, mode: mode);
      if (!mounted || vehicleId != widget.vehicleId || mode != widget.mode) {
        return;
      }
      setState(() => _documents = documents);
    } catch (error) {
      if (!mounted || vehicleId != widget.vehicleId || mode != widget.mode) {
        return;
      }
      setState(() => _loadError = error);
    } finally {
      if (mounted && vehicleId == widget.vehicleId && mode == widget.mode) {
        setState(() => _loading = false);
      }
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _add() async {
    final added = await showDialog<EquipmentDocument>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddEquipmentDocumentDialog(
        vehicleId: widget.vehicleId,
        mode: widget.mode,
      ),
    );
    if (!mounted || added == null) return;
    setState(() => _documents = [...?_documents, added]);
    _message(l10n.equipmentDocumentSaved);
  }

  Future<void> _export(
    EquipmentDocument document,
    BuildContext buttonContext,
  ) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _busy = true);
    try {
      final bytes = await _repository.download(
        widget.vehicleId,
        document.id,
        mode: widget.mode,
      );
      if (!mounted) return;
      await ref.read(equipmentDocumentExporterProvider)(
        bytes: Uint8List.fromList(bytes),
        filename: document.originalName,
        mimeType: document.mimeType,
        origin: origin,
      );
    } catch (error) {
      if (mounted) _message(messageFor(error, l10n: l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(EquipmentDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.equipmentDocumentDeleteConfirm),
        content: Text(document.originalName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.equipmentDocumentDelete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _repository.delete(
        widget.vehicleId,
        document.id,
        mode: widget.mode,
      );
      if (!mounted) return;
      setState(
        () => _documents = _documents
            ?.where((item) => item.id != document.id)
            .toList(),
      );
      _message(l10n.equipmentDocumentDeleted);
    } catch (error) {
      if (mounted) _message(messageFor(error, l10n: l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _document(EquipmentDocument document) => Card(
    key: ValueKey('equipment-document-${document.id}'),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.originalName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(_typeLabel(l10n, document.type)),
          if (document.uploadedAt != null)
            Text(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(document.uploadedAt!.toLocal()),
            ),
          const SizedBox(height: 8),
          Text(l10n.equipmentDocumentProvided),
          if (document.expiresOn != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(document.expiresOn!)),
              ],
            ),
          ],
          if (document.isExpired())
            Text(
              l10n.equipmentDocumentExpired,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Builder(
                builder: (buttonContext) => IconButton(
                  key: ValueKey('equipment-document-export-${document.id}'),
                  tooltip: l10n.equipmentDocumentExport,
                  onPressed: _busy
                      ? null
                      : () => _export(document, buttonContext),
                  icon: const Icon(Icons.save_alt_outlined),
                ),
              ),
              IconButton(
                key: ValueKey('equipment-document-delete-${document.id}'),
                tooltip: l10n.equipmentDocumentDelete,
                onPressed: _busy ? null : () => _delete(document),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l10n.equipmentDocuments)),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Icon(Icons.lock_outline),
              const SizedBox(height: 8),
              Text(l10n.equipmentDocumentsPrivateHint),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_loadError != null) ...[
                Text(messageFor(_loadError, l10n: l10n)),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRetry),
                ),
              ] else ...[
                if (_documents?.isEmpty ?? true)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(l10n.equipmentDocumentEmpty),
                  ),
                ...?_documents?.map(_document),
                FilledButton.icon(
                  key: const ValueKey('equipment-document-add'),
                  onPressed: _busy ? null : _add,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.equipmentDocumentAdd),
                ),
              ],
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AddEquipmentDocumentDialog extends ConsumerStatefulWidget {
  const _AddEquipmentDocumentDialog({
    required this.vehicleId,
    required this.mode,
  });
  final int vehicleId;
  final VehicleFormMode mode;
  @override
  ConsumerState<_AddEquipmentDocumentDialog> createState() =>
      _AddEquipmentDocumentDialogState();
}

class _AddEquipmentDocumentDialogState
    extends ConsumerState<_AddEquipmentDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _expiry = TextEditingController();
  EquipmentDocumentType _type = EquipmentDocumentType.other;
  PlatformFile? _file;
  Uint8List? _selectedBytes;
  String? _error;
  bool _busy = false;
  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void dispose() {
    _expiry.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ref.read(equipmentDocumentPickerProvider)();
      if (!mounted || file == null) return;
      setState(() {
        _file = null;
        _selectedBytes = null;
      });
      if (file.size > equipmentDocumentMaxBytes) {
        setState(() => _error = l10n.equipmentDocumentTooLarge);
      } else if (!_documentExtensions.contains(file.extension?.toLowerCase())) {
        setState(() => _error = l10n.equipmentDocumentFormats);
      } else {
        setState(() => _file = file);
      }
    } catch (error) {
      if (mounted) setState(() => _error = messageFor(error, l10n: l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateExpiry(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final date = DateTime.tryParse(text);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
        date == null ||
        date.toIso8601String().substring(0, 10) != text) {
      return l10n.equipmentDocumentDateInvalid;
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy || _file == null || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = _file!;
      // Picker streams may be single-subscription. Keep the bounded data while
      // this dialog is open so an unsuccessful request can be retried.
      final bytes = _selectedBytes ??= await readEquipmentDocument(file);
      if (!mounted) return;
      final expiry = _expiry.text.trim();
      final document = await ref
          .read(equipmentDocumentsRepositoryProvider)
          .upload(
            widget.vehicleId,
            mode: widget.mode,
            filename: file.name,
            bytes: bytes,
            type: _type,
            expiresOn: expiry.isEmpty ? null : expiry,
          );
      if (mounted) Navigator.pop(context, document);
    } on EquipmentDocumentTooLarge {
      if (mounted) setState(() => _error = l10n.equipmentDocumentTooLarge);
    } catch (error) {
      if (mounted) setState(() => _error = messageFor(error, l10n: l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(l10n.equipmentDocumentAdd),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<EquipmentDocumentType>(
                  key: const ValueKey('equipment-document-type'),
                  initialValue: _type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.equipmentDocumentType,
                  ),
                  items: EquipmentDocumentType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_typeLabel(l10n, type)),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (type) => setState(() => _type = type!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('equipment-document-expiry'),
                  controller: _expiry,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: l10n.equipmentDocumentExpiry,
                  ),
                  keyboardType: TextInputType.datetime,
                  validator: _validateExpiry,
                ),
                const SizedBox(height: 16),
                Text(l10n.equipmentDocumentFormats),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('equipment-document-select'),
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.attach_file),
                  label: Text(l10n.equipmentDocumentSelect),
                ),
                if (_file != null) Text(_file!.name),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('equipment-document-save'),
          onPressed: _busy || _file == null ? null : _save,
          child: Text(l10n.equipmentDocumentAdd),
        ),
      ],
    ),
  );
}
