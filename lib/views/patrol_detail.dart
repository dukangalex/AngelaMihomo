import 'package:bett_box/common/ai_client.dart';
import 'package:bett_box/common/ai_config.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/patrol_actions.dart';
import 'package:bett_box/common/patrol_probes.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/patrol_text.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// material_ui, not Flutter's material (T30 class): the app registers
// only the fork's MaterialLocalizations, so Flutter's dialogs throw
// in this tree.
import 'package:material_ui/material_ui.dart';

/// AI Patrol issue detail (T68): one problem, three answers.
///
/// 为什么 — a plain-language cause conclusion leads the page (for
/// fetch failures it is stage-precise, and live probe results
/// replace the recorded guess with a measured stage).
/// 凭什么 — the evidence the conclusion rests on: matched log
/// lines, the recorded error, live state — plus on-demand probes
/// that re-walk the failing path right now (bowel #1).
/// 怎么办 — advice and, where a whitelist fix exists, the fix
/// itself, run through the established charter (confirm → snapshot
/// → execute → verify → auto-rollback) with its outcome reported
/// on THIS page (bowel #4, 联动反馈原则）.
///
/// The AI layer (T30 BYOK) is an optional strengthening section at
/// the bottom; with no key configured it does not exist here, and
/// the local diagnosis above is complete without it.
class PatrolDetailView extends ConsumerStatefulWidget {
  final PatrolIssue issue;
  final Profile? profile;
  final AiConfig? aiConfig;
  final List<String> nodeNames;
  final bool coreRunning;
  final int proxyPort;

  /// Rebuilds the full patrol report from live state (fix verify).
  final PatrolReport Function() readReport;

  /// Re-runs the patrol page's config validation (reloadConfig
  /// fixes verify against a fresh check, like on the list page).
  final Future<void> Function() refreshConfigCheck;

  /// Reloads the recorded update-failure state after a fix.
  final Future<void> Function() reloadUpdateFailure;

  const PatrolDetailView({
    super.key,
    required this.issue,
    required this.profile,
    required this.aiConfig,
    required this.nodeNames,
    required this.coreRunning,
    required this.proxyPort,
    required this.readReport,
    required this.refreshConfigCheck,
    required this.reloadUpdateFailure,
  });

  @override
  ConsumerState<PatrolDetailView> createState() => _PatrolDetailViewState();
}

class _PatrolDetailViewState extends ConsumerState<PatrolDetailView> {
  PatrolProbeResults? _probeResults;
  bool _probing = false;

  bool _fixing = false;
  bool _sessionTrust = false;
  String? _fixOutcome;
  bool _fixFailed = false;

  PatrolIssue get issue => widget.issue;

  PatrolFetchStage? get _measuredStage {
    final results = _probeResults;
    if (results == null) return null;
    return measuredStageFromProbes(results.byKind);
  }

  /// The HTTP status a failed fetch probe measured live, if any —
  /// feeds the conclusion so a measured 502 reads as a server fault.
  int? get _measuredHttpStatus {
    final results = _probeResults;
    if (results == null) return null;
    return measuredDiagnosisFromProbes(results.byKind)?.httpStatus;
  }

  bool get _probesAllOk =>
      _probeResults != null &&
      _probeResults!.values.every((o) => o.ok) &&
      _measuredStage == null;

  String _clean(String text) {
    var result = redactLogText(text);
    final names = [...widget.nodeNames]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final name in names) {
      if (name.trim().length < 2) continue;
      result = result.replaceAll(name, maskPatrolName(name));
    }
    return result;
  }

  Future<void> _runProbes() async {
    final url = Uri.tryParse(issue.probeUrl);
    if (url == null || url.host.isEmpty) return;
    setState(() => _probing = true);
    try {
      final results = await runPatrolProbes(
        issue.probePlan,
        url: url,
        proxyPort: widget.proxyPort,
      );
      if (mounted) setState(() => _probeResults = results);
    } catch (error) {
      if (mounted) {
        globalState.showNotifier('$error');
      }
    } finally {
      if (mounted) setState(() => _probing = false);
    }
  }

  /// Same authorization prompt as the patrol list page (root
  /// navigator route, plain checkbox row).
  Future<bool?> _confirmFix(PatrolAction action) async {
    var trust = false;
    return globalState.showCommonDialog<bool>(
      child: StatefulBuilder(
        builder: (context, setDialogState) => CommonDialog(
          title: appLocalizations.patrolFixConfirmTitle,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(appLocalizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(trust),
              child: Text(appLocalizations.patrolFix),
            ),
          ],
          child: Container(
            width: 300,
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patrolActionLabel(action),
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(appLocalizations.patrolFixConfirmDesc),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setDialogState(() => trust = !trust),
                    child: Row(
                      children: [
                        Checkbox(
                          value: trust,
                          onChanged: (value) =>
                              setDialogState(() => trust = value ?? false),
                        ),
                        Expanded(
                          child: Text(appLocalizations.patrolFixTrustSession),
                        ),
                      ],
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

  /// The T29 fix charter, run from the detail page: confirm →
  /// snapshot → whitelist action → rebuild → verify → auto-rollback
  /// on a failed subscription update → record. The outcome stays on
  /// this page, and the probes reset (their results predate the fix).
  Future<void> _runFix(PatrolAction action) async {
    if (_fixing) return;
    setState(() {
      _fixing = true;
      _fixOutcome = null;
      _fixFailed = false;
    });
    try {
      if (!_sessionTrust) {
        final trust = await _confirmFix(action);
        if (!mounted) return;
        if (trust == null) {
          setState(
            () => _fixOutcome = appLocalizations.patrolFixCancelled,
          );
          return;
        }
        _sessionTrust = trust;
      }
      final before = widget.readReport();
      final profile = widget.profile;
      final result = await executePatrolAction(
        globalState.appController,
        action,
        profile: profile,
      );
      if (action == PatrolAction.reloadConfig) {
        await widget.refreshConfigCheck();
      }
      if (action == PatrolAction.updateSubscription) {
        await widget.reloadUpdateFailure();
      }
      final after = widget.readReport();
      final verified =
          result.executed &&
          verifyPatrolFix(
            action,
            before,
            after,
            updateFailed: after.subscription.lastUpdateFailed,
          );
      var outcome = verified ? 'applied' : 'failed';
      String? keptBackup;
      if (!verified &&
          action == PatrolAction.updateSubscription &&
          result.profileBackupPath != null &&
          profile != null) {
        final rolledBack = await rollbackSubscriptionSnapshot(
          globalState.appController,
          profile: profile,
          backupPath: result.profileBackupPath!,
        );
        if (rolledBack) outcome = 'failedRolledBack';
      }
      if (verified && action == PatrolAction.updateSubscription) {
        keptBackup = result.profileBackupPath;
      }
      await PatrolStore.addRecord(
        PatrolRepairRecord(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          at: DateTime.now(),
          action: action,
          outcome: outcome,
          detail: result.detail,
          profileBackupPath: keptBackup,
          profileId: profile?.id,
        ),
      );
      patrolAttentionCount.value = widget.readReport().problemCount;
      if (mounted) {
        final headline = switch (outcome) {
          'applied' => appLocalizations.patrolFixApplied,
          'failedRolledBack' => appLocalizations.patrolFixRolledBack,
          _ => appLocalizations.patrolFixFailed,
        };
        setState(() {
          _fixFailed = outcome != 'applied';
          _fixOutcome = result.detail.isEmpty
              ? headline
              : '$headline · ${result.detail}';
          // Probe results predate the fix; they no longer describe
          // the path, so the next probe run starts clean.
          _probeResults = null;
        });
        globalState.showNotifier(headline);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _fixFailed = true;
          _fixOutcome = '${appLocalizations.patrolFixFailed} · $error';
        });
      }
    } finally {
      if (mounted) setState(() => _fixing = false);
    }
  }

  /// Per-issue AI interpretation: preview the exact redacted text,
  /// send only on confirmation, show the answer. The AI executes
  /// nothing; fixes stay with the whitelist executor above.
  Future<void> _runAi() async {
    final config = widget.aiConfig;
    if (config == null || !config.configured) return;
    final summary = buildPatrolIssueSummary(
      issue,
      nodeNames: widget.nodeNames,
      probes: _probeResults?.byKind ?? const {},
      measuredStage: _measuredStage,
    );
    if (!mounted) return;
    final send = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appLocalizations.aiPreviewTitle),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appLocalizations.aiPreviewDesc),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    summary,
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appLocalizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(appLocalizations.aiSend),
          ),
        ],
      ),
    );
    if (send != true || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(appLocalizations.aiThinking)),
          ],
        ),
      ),
    );
    String result;
    try {
      result = await fetchAiIssueInterpretation(config, summary);
    } catch (error) {
      result = '${appLocalizations.aiError}: $error';
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appLocalizations.aiResultTitle),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: SelectableText(result)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appLocalizations.confirm),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: context.textTheme.titleSmall?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _bodyText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SelectableText(text, style: context.textTheme.bodyMedium),
    );
  }

  Widget _factRow(BuildContext context, PatrolFact fact) {
    final small = context.textTheme.bodySmall;
    switch (fact.kind) {
      case PatrolFactKind.occurrences:
        final window = fact.firstAt != null && fact.lastAt != null
            ? appLocalizations.patrolFactWindow(
                fact.firstAt!.toIso8601String().substring(11, 19),
                fact.lastAt!.toIso8601String().substring(11, 19),
              )
            : null;
        return ListItem(
          title: Text(appLocalizations.patrolFactOccurrences(fact.count)),
          subtitle: window == null ? null : Text(window),
        );
      case PatrolFactKind.state:
        return ListItem(
          title: Text(_factLabel(fact.label!)),
          trailing: Text(_factValue(fact)),
        );
      case PatrolFactKind.recordedError:
        return ListItem(
          title: Text(appLocalizations.patrolFactRecordedError),
          subtitle: SelectableText(_clean(fact.text), style: small),
        );
      case PatrolFactKind.sample:
        return ListItem(
          title: Text(appLocalizations.patrolFactSample),
          subtitle: SelectableText(_clean(fact.text), style: small),
        );
    }
  }

  String _factLabel(PatrolFactLabel label) => switch (label) {
    PatrolFactLabel.mode => appLocalizations.patrolFactMode,
    PatrolFactLabel.coreState => appLocalizations.patrolFactCore,
    PatrolFactLabel.nodesSummary => appLocalizations.patrolFactNodes,
    PatrolFactLabel.subscriptionHost => appLocalizations.patrolFactHost,
    PatrolFactLabel.lastUpdate => appLocalizations.patrolFactTime,
    PatrolFactLabel.httpStatus => appLocalizations.patrolFactHttpStatus,
  };

  String _factValue(PatrolFact fact) {
    if (fact.label == PatrolFactLabel.coreState) {
      return fact.value == 'running'
          ? appLocalizations.patrolFactCoreRunning
          : appLocalizations.patrolFactCoreStopped;
    }
    return fact.value;
  }

  String _probeLabel(PatrolProbeKind kind) => switch (kind) {
    PatrolProbeKind.proxyPort => appLocalizations.patrolProbeProxyPort,
    PatrolProbeKind.dnsLookup => appLocalizations.patrolProbeDns,
    PatrolProbeKind.tcpConnect => appLocalizations.patrolProbeTcp,
    PatrolProbeKind.tlsHandshake => appLocalizations.patrolProbeTls,
    PatrolProbeKind.directFetch => appLocalizations.patrolProbeDirect,
    PatrolProbeKind.proxyFetch => appLocalizations.patrolProbeProxy,
  };

  List<Widget> _probeWidgets(BuildContext context) {
    if (issue.probePlan.isEmpty) return const [];
    final scheme = context.colorScheme;
    final widgets = <Widget>[
      _sectionTitle(context, appLocalizations.patrolDetailProbes),
      _bodyText(context, appLocalizations.patrolDetailProbesDesc),
    ];
    final results = _probeResults;
    if (results != null) {
      for (final kind in issue.probePlan) {
        final outcome = results[kind];
        if (outcome == null) continue;
        final skipped = outcome.detail.startsWith('skipped');
        widgets.add(
          ListItem(
            leading: Icon(
              skipped
                  ? Icons.remove_circle_outline
                  : outcome.ok
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: skipped
                  ? scheme.onSurfaceVariant
                  : outcome.ok
                  ? scheme.primary
                  : scheme.error,
            ),
            title: Text(_probeLabel(kind)),
            subtitle: Text(
              skipped
                  ? appLocalizations.patrolProbeSkipped
                  : _clean(outcome.detail),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
      final measured = _measuredStage;
      if (measured != null) {
        widgets.add(
          _bodyText(
            context,
            '✓ ${appLocalizations.patrolDetailMeasured}: '
            '${appLocalizations.patrolMeasuredStage(patrolStageName(measured))}',
          ),
        );
      } else if (_probesAllOk) {
        widgets.add(_bodyText(context, appLocalizations.patrolDetailProbesAllOk));
      }
    }
    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FilledButton.tonal(
          onPressed: _probing ? null : _runProbes,
          child: Text(
            _probing
                ? appLocalizations.patrolDetailProbing
                : appLocalizations.patrolDetailRunProbes,
          ),
        ),
      ),
    );
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final measured = _measuredStage;
    final action = issue.action;
    return CommonScaffold(
      title: patrolIssueTitle(issue),
      body: ListView(
        children: [
          // 为什么 — the conclusion leads.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(
                  issue.severity == PatrolSeverity.problem
                      ? Icons.error_outline
                      : Icons.info_outline,
                  color: issue.severity == PatrolSeverity.problem
                      ? scheme.error
                      : scheme.tertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appLocalizations.patrolDetailWhy,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (measured != null)
                  Chip(
                    label: Text(appLocalizations.patrolDetailMeasured),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          _bodyText(
            context,
            patrolIssueConclusion(
              issue,
              measuredStage: measured,
              measuredHttpStatus: _measuredHttpStatus,
            ),
          ),
          // 凭什么 — evidence, then live probes.
          _sectionTitle(context, appLocalizations.patrolDetailBasis),
          if (issue.facts.isEmpty)
            _bodyText(context, patrolIssueConclusion(issue))
          else
            for (final fact in issue.facts) _factRow(context, fact),
          ..._probeWidgets(context),
          // 怎么办 — advice, the fix itself, its outcome, and the
          // manual reproduction path.
          _sectionTitle(context, appLocalizations.patrolDetailAdvice),
          _bodyText(
            context,
            patrolIssueAdvice(
              issue,
              stage: measured,
              httpStatus: _measuredHttpStatus,
            ),
          ),
          if (action != null)
            ListItem(
              leading: _fixing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.build_outlined),
              title: Text(patrolActionLabel(action)),
              subtitle: _fixing
                  ? Text(appLocalizations.patrolFixRunning)
                  : _fixOutcome == null
                  ? null
                  : Text(
                      _fixOutcome!,
                      style: TextStyle(
                        color: _fixFailed ? scheme.error : scheme.primary,
                      ),
                    ),
              trailing: FilledButton.tonal(
                onPressed: _fixing ? null : () => _runFix(action),
                child: Text(appLocalizations.patrolFix),
              ),
            ),
          if (patrolIssueRepro(issue) != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                appLocalizations.patrolDetailRepro,
                style: context.textTheme.labelLarge,
              ),
            ),
            _bodyText(context, patrolIssueRepro(issue)!),
          ],
          // AI strengthening layer — present only with a configured
          // key; the local diagnosis above never depends on it.
          if (widget.aiConfig?.configured ?? false) ...[
            _sectionTitle(context, appLocalizations.patrolDetailAi),
            _bodyText(context, appLocalizations.patrolDetailAiDesc),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.tonal(
                onPressed: _runAi,
                child: Text(appLocalizations.aiInterpret),
              ),
            ),
          ],
          // 原始信息 — raw material, redacted, folded away.
          if (issue.rawInfo.isNotEmpty)
            ExpansionTile(
              title: Text(appLocalizations.patrolDetailRaw),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      _clean(issue.rawInfo),
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
