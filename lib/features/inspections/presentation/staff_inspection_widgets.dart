import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../data/staff_inspection.dart';
import '../data/staff_inspection_repository.dart';
import 'staff_inspection_form.dart';
import 'staff_inspection_report_dialog.dart';

export 'staff_inspection_report_dialog.dart' show showStaffInspectionReport;

/// Fits narrow cards and intrinsic-height carousels. A badge denotes an actual
/// staff inspection; issues remain readable without opening the report.
class StaffInspectionBadge extends StatelessWidget {
  final StaffInspectionSummary inspection;
  final bool compact;
  final VoidCallback? onTap;

  const StaffInspectionBadge({
    super.key,
    required this.inspection,
    this.compact = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!inspection.isCurrent()) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap:
            onTap ??
            () =>
                showStaffInspectionReport(context, inspectionId: inspection.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 5,
                  runSpacing: 3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: compact ? 18 : 22,
                      color: colors.primary,
                    ),
                    Text(
                      l.inspectionBadgeLabel,
                      style:
                          (compact
                                  ? theme.textTheme.labelSmall
                                  : theme.textTheme.labelLarge)
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
                if (inspection.hasFindings) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        inspection.blockingCount > 0
                            ? Icons.error_outline
                            : Icons.warning_amber_outlined,
                        size: 16,
                        color: inspection.blockingCount > 0
                            ? colors.error
                            : colors.onSurface,
                      ),
                      Text(
                        inspection.blockingCount > 0
                            ? l.inspectionBlockingLabel
                            : l.inspectionAttentionLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: inspection.blockingCount > 0
                              ? colors.error
                              : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StaffInspectionSection extends ConsumerStatefulWidget {
  final String source;
  final int sourceId;
  final StaffInspectionSummary? inspectionSummary;
  final bool canManage;
  final String? uninspectedLabel;
  final VoidCallback? onChanged;

  const StaffInspectionSection({
    super.key,
    required this.source,
    required this.sourceId,
    this.inspectionSummary,
    this.canManage = false,
    this.uninspectedLabel,
    this.onChanged,
  });

  @override
  ConsumerState<StaffInspectionSection> createState() =>
      _StaffInspectionSectionState();
}

class _StaffInspectionSectionState
    extends ConsumerState<StaffInspectionSection> {
  StaffInspectionSummary? _summary;
  final List<StaffInspectionReport> _reports = [];
  Object? _historyError;
  bool _loading = false;
  bool _busy = false;
  int? _nextPage;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _summary = widget.inspectionSummary;
    if (widget.canManage) _loadHistory();
  }

  @override
  void didUpdateWidget(StaffInspectionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedTarget =
        oldWidget.source != widget.source ||
        oldWidget.sourceId != widget.sourceId;
    if (changedTarget ||
        oldWidget.inspectionSummary != widget.inspectionSummary) {
      _summary = widget.inspectionSummary;
    }
    if (changedTarget || oldWidget.canManage != widget.canManage) {
      _summary = widget.inspectionSummary;
      _request++;
      _reports.clear();
      _nextPage = null;
      _historyError = null;
      _loading = false;
      if (widget.canManage) _loadHistory();
    }
  }

  Future<void> _loadHistory({bool more = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _historyError = null;
    });
    try {
      final page = await ref
          .read(staffInspectionRepositoryProvider)
          .history(
            widget.source,
            widget.sourceId,
            page: more ? (_nextPage ?? 1) : 1,
          );
      if (!mounted || request != _request || !widget.canManage) return;
      setState(() {
        if (!more) _reports.clear();
        _reports.addAll(page.reports);
        _nextPage = page.nextPage;
        if (!more) {
          final current = page.reports.where(
            (report) =>
                report.state == 'active' && report.inspection.isCurrent(),
          );
          _summary = current.isEmpty ? null : current.first.inspection;
        }
        _loading = false;
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _historyError = error;
        });
      }
    }
  }

  Future<void> _showReport() async {
    final summary = _summary;
    if (summary == null) return;
    if (!widget.canManage) {
      await showStaffInspectionReport(context, inspectionId: summary.id);
      return;
    }
    // Private/pending targets intentionally have no public report. Staff reads
    // its authenticated history and never falls back to the public endpoint.
    final matches = _reports.where(
      (report) => report.inspection.id == summary.id,
    );
    if (matches.isNotEmpty) {
      await showStaffInspectionReport(
        context,
        inspectionId: summary.id,
        report: matches.first,
      );
    } else {
      await _loadHistory();
      if (!mounted) return;
      final loaded = _reports.where(
        (report) => report.inspection.id == summary.id,
      );
      if (loaded.isNotEmpty) {
        await showStaffInspectionReport(
          context,
          inspectionId: summary.id,
          report: loaded.first,
        );
      }
    }
  }

  Future<void> _create() async {
    if (!widget.canManage || _busy) return;
    setState(() => _busy = true);
    final report = await showStaffInspectionForm(
      context,
      source: widget.source,
      sourceId: widget.sourceId,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (report != null) {
        _summary = report.inspection;
        _reports.insert(0, report);
      }
    });
    if (report != null) {
      widget.onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).inspectionSaved)),
      );
      await _loadHistory();
    }
  }

  Future<void> _withdraw(StaffInspectionReport report) async {
    if (!widget.canManage || _busy) return;
    setState(() => _busy = true);
    final withdrawn = await showDialog<StaffInspectionReport>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WithdrawInspectionDialog(report: report),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (withdrawn != null && _summary?.id == report.inspection.id) {
        _summary = null;
      }
    });
    if (withdrawn != null) {
      widget.onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).inspectionWithdrawn),
        ),
      );
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final summary = _summary?.isCurrent() == true ? _summary : null;
    final dates = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary != null)
          StaffInspectionBadge(
            inspection: summary,
            compact: false,
            onTap: _showReport,
          )
        else if (widget.uninspectedLabel != null)
          Text(widget.uninspectedLabel!),
        if (widget.canManage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('inspection-manage'),
            onPressed: _busy || _loading ? null : _create,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(
              summary == null ? l.inspectionAdd : l.inspectionReplace,
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          if (_historyError != null) ...[
            Text(messageFor(_historyError, l10n: l)),
            TextButton.icon(
              onPressed: _loading || _busy ? null : () => _loadHistory(),
              icon: const Icon(Icons.refresh),
              label: Text(l.commonRetry),
            ),
          ],
          if (_reports.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l.inspectionHistory),
              children: [
                for (final report in _reports)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      dates.format(report.inspection.inspectedAt.toLocal()),
                    ),
                    subtitle: Text(_stateLabel(report, l)),
                    onTap: () => showStaffInspectionReport(
                      context,
                      inspectionId: report.inspection.id,
                      report: report,
                    ),
                    trailing: report.canWithdraw
                        ? IconButton(
                            tooltip: l.inspectionWithdraw,
                            onPressed: _busy || _loading
                                ? null
                                : () => _withdraw(report),
                            icon: const Icon(Icons.remove_circle_outline),
                          )
                        : null,
                  ),
                if (_nextPage != null)
                  TextButton(
                    onPressed: _loading || _busy
                        ? null
                        : () => _loadHistory(more: true),
                    child: Text(l.inspectionMore),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  String _stateLabel(StaffInspectionReport report, AppLocalizations l) =>
      switch (report.state) {
        'withdrawn' => l.inspectionHistoryWithdrawn,
        'superseded' => l.inspectionHistorySuperseded,
        'active' =>
          report.inspection.isCurrent()
              ? l.inspectionHistoryActive
              : l.inspectionHistoryExpired,
        'outdated' =>
          report.inspection.isCurrent()
              ? l.inspectionHistoryInactive
              : l.inspectionHistoryExpired,
        _ => l.inspectionHistoryInactive,
      };
}

class _WithdrawInspectionDialog extends ConsumerStatefulWidget {
  final StaffInspectionReport report;
  const _WithdrawInspectionDialog({required this.report});

  @override
  ConsumerState<_WithdrawInspectionDialog> createState() =>
      _WithdrawInspectionState();
}

class _WithdrawInspectionState
    extends ConsumerState<_WithdrawInspectionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final report = await ref
          .read(staffInspectionRepositoryProvider)
          .withdraw(widget.report.inspection.id, _reason.text);
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
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(l.inspectionWithdrawTitle),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('inspection-withdraw-reason'),
                    controller: _reason,
                    enabled: !_saving,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: l.inspectionWithdrawReason,
                    ),
                    validator: (value) => value?.trim().isEmpty != false
                        ? l.inspectionWithdrawReasonRequired
                        : null,
                  ),
                  if (_error != null)
                    Text(
                      messageFor(_error, l10n: l),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
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
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.inspectionWithdrawConfirm),
          ),
        ],
      ),
    );
  }
}
