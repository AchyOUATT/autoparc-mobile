import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../data/staff_inspection.dart';
import '../data/staff_inspection_repository.dart';

Future<void> showStaffInspectionReport(
  BuildContext context, {
  required int inspectionId,
  StaffInspectionReport? report,
}) => showDialog<void>(
  context: context,
  builder: (_) => _InspectionReportDialog(id: inspectionId, report: report),
);

class _InspectionReportDialog extends ConsumerStatefulWidget {
  final int id;
  final StaffInspectionReport? report;
  const _InspectionReportDialog({required this.id, this.report});

  @override
  ConsumerState<_InspectionReportDialog> createState() =>
      _InspectionReportState();
}

class _InspectionReportState extends ConsumerState<_InspectionReportDialog> {
  late Future<StaffInspectionReport> _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _report = widget.report == null
        ? ref.read(staffInspectionRepositoryProvider).report(widget.id)
        : Future.value(widget.report);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.inspectionReportTitle),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<StaffInspectionReport>(
          future: _report,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              final unavailable = error is ApiException && error.isNotFound;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unavailable
                          ? l.inspectionReportUnavailable
                          : messageFor(error, l10n: l),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.refresh),
                      label: Text(l.commonRetry),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              child: _ReportBody(report: snapshot.requireData),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.inspectionClose),
        ),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  final StaffInspectionReport report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = report.inspection;
    final locale = Localizations.localeOf(context).languageCode;
    final dates = DateFormat.yMMMd(locale);
    final km = NumberFormat.decimalPattern(locale).format(data.mileageKm);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.inspectionBadgeLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${l.inspectionDateLabel} : ${dates.format(data.inspectedAt.toLocal())}',
        ),
        Text('${l.inspectionMileageLabel} : ${l.commonMileageKm(km)}'),
        Text(l.inspectionCheckedCount(data.checkedCount)),
        if (data.validUntil != null)
          Text(
            '${l.inspectionValidUntilLabel} : ${dates.format(data.validUntil!.toLocal())}',
          ),
        const SizedBox(height: 8),
        Text(
          l.inspectionScopeNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (data.hasFindings) ...[
          const SizedBox(height: 12),
          _StatusLine(
            status: data.blockingCount > 0 ? 'blocking' : 'attention',
            label: data.blockingCount > 0
                ? l.inspectionBlockingLabel
                : l.inspectionAttentionLabel,
          ),
        ],
        if (report.summary.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l.inspectionSummaryLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(report.summary),
        ],
        const Divider(height: 28),
        for (final item in report.items) ...[
          Text(item.label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          _StatusLine(status: item.status),
          if (item.note?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(item.note!),
          ],
          const SizedBox(height: 16),
        ],
        if (report.withdrawalReason?.trim().isNotEmpty == true)
          Text('${l.inspectionWithdrawReason} : ${report.withdrawalReason}'),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String status;
  final String? label;
  const _StatusLine({required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final icon = switch (status) {
      'ok' => Icons.check_circle_outline,
      'attention' => Icons.warning_amber_outlined,
      'blocking' => Icons.error_outline,
      _ => Icons.help_outline,
    };
    final color = switch (status) {
      'blocking' => colors.error,
      'attention' => colors.onSurface,
      _ => colors.onSurfaceVariant,
    };
    final text =
        label ??
        switch (status) {
          'ok' => l.inspectionStatusOk,
          'attention' => l.inspectionStatusAttention,
          'blocking' => l.inspectionStatusBlocking,
          _ => l.inspectionStatusNotChecked,
        };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
