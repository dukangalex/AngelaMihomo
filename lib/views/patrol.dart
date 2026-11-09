import 'package:bett_box/common/ai_client.dart';
import 'package:bett_box/common/ai_config.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/patrol_actions.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/views/ai_config.dart';
import 'package:bett_box/views/patrol_detail.dart';
import 'package:bett_box/views/patrol_text.dart';
import 'package:bett_box/common/profile_chain.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// material_ui, not Flutter's material (T30 class): the app registers
// only the fork's MaterialLocalizations, so Flutter's showDialog /
// AlertDialog throw "Null check operator used on a null value" here.
import 'package:material_ui/material_ui.dart';

/// AI Patrol page (phase 1): runs the local inspection over logs,
/// subscription, nodes, mode/chain and core/config, and renders the
/// structured [PatrolReport] conclusion-first in plain language.
///
/// The page is only an adapter + renderer: it maps live app state into
/// the patrol data layer's injected inputs and turns the report back
/// into localized rows. Fixes are a later milestone; nothing here
/// changes any app state except re-running config validation.
class PatrolView extends ConsumerStatefulWidget {
  const PatrolView({super.key});

  @override
  ConsumerState<PatrolView> createState() => _PatrolViewState();
}

/// Proxy types that are groups or built-in pseudo nodes, not real nodes.
const _nonNodeTypes = {
  'SELECTOR',
  'URLTEST',
  'FALLBACK',
  'LOADBALANCE',
  'RELAY',
  'DIRECT',
  'REJECT',
  'REJECT-DROP',
  'COMPATIBLE',
  'PASS',
  'PASSTHROUGH',
};

/// Coalesces config-check runs for the patrol page: at most one check
/// runs at a time, and requests that arrive while a check is running
/// collapse into a single follow-up run, so a burst of input changes
/// never starts parallel checks and no change is silently dropped.
class PatrolConfigCheckScheduler {
  bool _running = false;
  bool _rerunRequested = false;

  bool get isRunning => _running;

  /// Starts a check when idle and returns true; while a check is
  /// running, remembers one follow-up run instead and returns false.
  bool tryStart() {
    if (_running) {
      _rerunRequested = true;
      return false;
    }
    _running = true;
    return true;
  }

  /// Ends the current check; returns true when a follow-up run was
  /// requested while it was running and should start now.
  bool finish() {
    _running = false;
    if (!_rerunRequested) return false;
    _rerunRequested = false;
    return true;
  }
}

class _PatrolViewState extends ConsumerState<PatrolView> {
  bool _chainReady = false;
  final _configCheckScheduler = PatrolConfigCheckScheduler();
  PatrolConfigCheck? _configCheck;
  String _configError = '';
  ProviderSubscription? _profileSubscription;
  ProviderSubscription? _runStateSubscription;

  /// Recorded last-update failure for the current profile (recorded
  /// by the update flow via PatrolStore), keyed by profile id so a
  /// profile switch never shows another profile's failure.
  bool _updateFailed = false;
  String _failureProfileId = '';

  /// The recorded error text behind [_updateFailed], fed to the
  /// diagnosis layer (T68) so the failure is classified by stage
  /// instead of displayed raw.
  String _updateError = '';

  /// "Fix all low-risk items without asking" lasts for this page
  /// session only (spec: 本次全权修复）. It is never persisted.
  bool _sessionTrust = false;
  bool _fixing = false;

  /// On-page fix feedback (T29 repair round). The fix loop must be
  /// visible HERE — authorization, progress, outcome and the failure
  /// reason — not only as a transient snackbar or on the records
  /// page. [_fixStatusText] keeps the last run's outcome on the page
  /// until the next run starts.
  PatrolAction? _fixStatusAction;
  String? _fixStatusText;
  bool _fixStatusFailed = false;

  /// BYOK AI config (T30). Null until loaded; the interpretation
  /// entry only appears when a config exists and is complete — with
  /// no key there is no AI UI anywhere (zero disturbance rule).
  AiConfig? _aiConfig;

  bool get _checkingConfig => _configCheckScheduler.isRunning;

  Future<void> _loadUpdateFailure() async {
    final profileId = ref.read(currentProfileProvider)?.id;
    if (profileId == null) {
      _failureProfileId = '';
      _updateFailed = false;
      _updateError = '';
      return;
    }
    final failure = await PatrolStore.updateFailureFor(profileId);
    if (!mounted) return;
    setState(() {
      _failureProfileId = profileId;
      _updateFailed = failure != null;
      _updateError = failure?.error ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    ProfileChainStore.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _chainReady = true);
    });
    _loadUpdateFailure();
    AiConfigStore.load().then((config) {
      if (mounted) setState(() => _aiConfig = config);
    });
    _runConfigCheck();
    // This page is kept alive across page switches, so a result from
    // when it was opened goes stale when its inputs change elsewhere:
    // switching or deleting the current profile, or starting/stopping
    // the service. Re-run the check on those changes instead of
    // leaving the old result on screen until a manual recheck.
    _profileSubscription = ref.listenManual(
      currentProfileProvider.select((state) => state?.id),
      (previous, next) {
        if (previous != next) {
          _runConfigCheck();
          _loadUpdateFailure();
        }
      },
    );
    _runStateSubscription = ref.listenManual(
      runTimeProvider.select((state) => state != null),
      (previous, next) {
        if (previous != next) _runConfigCheck();
      },
    );
  }

  @override
  void dispose() {
    _profileSubscription?.close();
    _runStateSubscription?.close();
    super.dispose();
  }

  Future<void> _runConfigCheck() async {
    if (!_configCheckScheduler.tryStart()) return;
    setState(() {});
    var rerun = false;
    try {
      final message = await globalState.validatePatchedConfig(
        patchConfig: ref.read(patchClashConfigProvider),
      );
      if (!mounted) return;
      // The raw core answer goes through the data layer's translator:
      // a runtime that has not started yet answers "could not check",
      // which must not be reported as a failed config.
      final check = translateConfigCheck(message);
      setState(() {
        _configCheck = check;
        _configError = check == PatrolConfigCheck.failed ? message : '';
      });
    } catch (error) {
      // A core call that throws is a failed check, not a silent pass:
      // surface the original error as the failure message.
      if (!mounted) return;
      setState(() {
        _configCheck = PatrolConfigCheck.failed;
        _configError = '$error';
      });
    } finally {
      rerun = _configCheckScheduler.finish();
      if (mounted) setState(() {});
    }
    // An input changed while this check was running: its result may
    // already be stale, so run once more with the current inputs.
    if (rerun && mounted) await _runConfigCheck();
  }

  int? _delayFor(DelayMap delayMap, String? testUrl, String name) {
    if (testUrl != null) {
      final value = delayMap[testUrl]?[name];
      if (value != null) return value;
    }
    for (final byName in delayMap.values) {
      final value = byName[name];
      if (value != null) return value;
    }
    return null;
  }

  bool? _hopAlive(DelayMap delayMap, String name) {
    if (name.trim().isEmpty) return null;
    for (final byName in delayMap.values) {
      final value = byName[name];
      if (value != null) return value > 0;
    }
    return null;
  }

  PatrolReport _buildReport() => _reportFrom(
    logs: ref.watch(logsProvider.select((state) => state.list)),
    profile: ref.watch(currentProfileProvider),
    groups: ref.watch(groupsProvider),
    delayMap: ref.watch(delayDataSourceProvider),
    mode: ref.watch(patchClashConfigProvider.select((s) => s.mode)),
  );

  /// Same report built from one-shot reads, for the fix flow's
  /// before/after verification (ref.watch is build-only).
  PatrolReport _readReport() => _reportFrom(
    logs: ref.read(logsProvider).list,
    profile: ref.read(currentProfileProvider),
    groups: ref.read(groupsProvider),
    delayMap: ref.read(delayDataSourceProvider),
    mode: ref.read(patchClashConfigProvider).mode,
  );

  PatrolReport _reportFrom({
    required List<Log> logs,
    required Profile? profile,
    required List<Group> groups,
    required DelayMap delayMap,
    required Mode mode,
  }) {
    final seen = <String>{};
    final nodeSamples = <PatrolNodeSample>[];
    for (final group in groups) {
      for (final proxy in group.all) {
        if (_nonNodeTypes.contains(proxy.type.toUpperCase())) continue;
        if (!seen.add(proxy.name)) continue;
        nodeSamples.add(
          PatrolNodeSample(
            name: proxy.name,
            delay: _delayFor(delayMap, group.testUrl, proxy.name),
          ),
        );
      }
    }

    final chain = profile == null || !_chainReady
        ? null
        : ProfileChainStore.instance.of(profile.id);
    final expireSeconds = profile?.subscriptionInfo?.expire ?? 0;

    return PatrolReport.build(
      now: DateTime.now(),
      logs: [
        for (final log in logs)
          PatrolLogEntry(
            level: log.logLevel.name,
            payload: log.payload,
            time: log.time,
          ),
      ],
      subscription: PatrolSubscriptionInput(
        hasProfile: profile != null,
        isRemote: (profile?.url.isNotEmpty ?? false),
        lastUpdateDate: profile?.lastUpdateDate,
        autoUpdateEnabled: profile?.realAutoUpdate ?? false,
        autoUpdateDuration: profile?.autoUpdateDuration ?? Duration.zero,
        expiresAt: expireSeconds > 0
            ? DateTime.fromMillisecondsSinceEpoch(expireSeconds * 1000)
            : null,
        // Recorded by the update flow (T29): the profile's last
        // update failure, shown until a later update succeeds.
        lastUpdateFailed: profile != null && _failureProfileId == profile.id
            ? _updateFailed
            : null,
        lastUpdateError: profile != null && _failureProfileId == profile.id
            ? _updateError
            : '',
      ),
      nodes: nodeSamples,
      link: PatrolLinkInput(
        mode: mode.name,
        chainEnabled: chain?.enabled ?? false,
        chainEntry: chain?.entry ?? '',
        chainLanding: chain?.landing ?? '',
        chainEntryAlive: chain == null
            ? null
            : _hopAlive(delayMap, chain.entry),
        chainLandingAlive: chain == null
            ? null
            : _hopAlive(delayMap, chain.landing),
      ),
      core: PatrolCoreInput(
        versionLabel:
            '${globalState.packageInfo.version}'
            '+${globalState.packageInfo.buildNumber}',
        configCheck: _configCheck,
        configError: _configError,
      ),
    );
  }

  Icon _severityIcon(BuildContext context, PatrolSeverity severity) {
    final scheme = context.colorScheme;
    return switch (severity) {
      PatrolSeverity.problem => Icon(Icons.error_outline, color: scheme.error),
      PatrolSeverity.notice => Icon(Icons.info_outline, color: scheme.tertiary),
      PatrolSeverity.ok => Icon(
        Icons.check_circle_outline,
        color: scheme.primary,
      ),
    };
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return [ListHeader(title: title), ...items];
  }

  /// One tappable row per diagnosable issue (T68): the row names
  /// the problem and its plain-language cause in one line — never a
  /// raw error string — and opens the detail page that answers the
  /// three patrol questions (why / on what evidence / what to do).
  Widget _issueItem(BuildContext context, PatrolIssue issue) {
    return ListItem(
      leading: _severityIcon(context, issue.severity),
      title: Text(patrolIssueTitle(issue)),
      subtitle: Text(
        patrolIssueConclusion(issue),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openIssue(issue),
    );
  }

  List<Widget> _issueItems(
    BuildContext context,
    List<PatrolIssue> issues,
    PatrolIssueSection section,
  ) {
    return [
      for (final issue in issues)
        if (issue.section == section) _issueItem(context, issue),
    ];
  }

  Future<void> _openIssue(PatrolIssue issue) async {
    final profile = ref.read(currentProfileProvider);
    final names = <String>{};
    for (final group in ref.read(groupsProvider)) {
      for (final proxy in group.all) {
        names.add(proxy.name);
      }
    }
    final chain = _reportFrom(
      logs: ref.read(logsProvider).list,
      profile: profile,
      groups: ref.read(groupsProvider),
      delayMap: ref.read(delayDataSourceProvider),
      mode: ref.read(patchClashConfigProvider).mode,
    ).link.input;
    if (chain.chainEntry.isNotEmpty) names.add(chain.chainEntry);
    if (chain.chainLanding.isNotEmpty) names.add(chain.chainLanding);
    await BaseNavigator.push(
      context,
      PatrolDetailView(
        issue: issue,
        profile: profile,
        aiConfig: _aiConfig,
        nodeNames: names.toList(),
        coreRunning: ref.read(runTimeProvider) != null,
        proxyPort: ref.read(patchClashConfigProvider).mixedPort,
        readReport: _readReport,
        refreshConfigCheck: _runConfigCheck,
        reloadUpdateFailure: _loadUpdateFailure,
      ),
    );
    if (mounted) {
      _loadUpdateFailure();
      setState(() {});
    }
  }

  List<Widget> _logItems(
    BuildContext context,
    PatrolLogSection section,
    List<PatrolIssue> issues,
  ) {
    final rows = _issueItems(context, issues, PatrolIssueSection.logs);
    if (rows.isNotEmpty) return rows;
    return [
      ListItem(
        leading: _severityIcon(context, PatrolSeverity.ok),
        title: Text(appLocalizations.patrolNoProblems),
      ),
    ];
  }

  List<Widget> _subscriptionItems(
    BuildContext context,
    PatrolSubscriptionSection section,
    List<PatrolIssue> issues,
  ) {
    final input = section.input;
    if (!input.hasProfile) {
      return _issueItems(context, issues, PatrolIssueSection.subscription);
    }
    // Diagnosis rows first (expired / stale / never / a fetch
    // failure homed here), then the informational last-updated row.
    return [
      ..._issueItems(context, issues, PatrolIssueSection.subscription),
      ListItem(
        leading: section.neverUpdated
            ? _severityIcon(context, PatrolSeverity.notice)
            : _severityIcon(context, PatrolSeverity.ok),
        title: Text(appLocalizations.patrolSubLastUpdated),
        trailing: Text(
          input.lastUpdateDate == null
              ? appLocalizations.patrolSubNeverUpdated
              : input.lastUpdateDate!.lastUpdateTimeDesc,
        ),
      ),
    ];
  }

  List<Widget> _nodeItems(
    BuildContext context,
    PatrolNodeSection section,
    List<PatrolIssue> issues,
  ) {
    final rows = _issueItems(context, issues, PatrolIssueSection.nodes);
    if (rows.isNotEmpty) return rows;
    final counts =
        '${appLocalizations.patrolNodesWorking} ${section.alive}'
        ' · ${appLocalizations.patrolNodesUnavailable} ${section.dead}'
        ' · ${appLocalizations.patrolNodesUntested} ${section.untested}';
    return [
      ListItem(
        leading: _severityIcon(context, section.severity),
        title: Text(counts),
      ),
    ];
  }

  List<Widget> _linkItems(
    BuildContext context,
    PatrolLinkSection section,
    List<PatrolIssue> issues,
  ) {
    final input = section.input;
    final modeLabel = switch (input.mode) {
      'global' => appLocalizations.global,
      'direct' => appLocalizations.direct,
      _ => appLocalizations.rule,
    };
    final items = <Widget>[
      ListItem(title: Text(appLocalizations.mode), trailing: Text(modeLabel)),
    ];
    if (!input.chainEnabled) {
      items.add(ListItem(title: Text(appLocalizations.patrolChainOff)));
      return items;
    }
    items.add(
      ListItem(
        leading: _severityIcon(
          context,
          section.chainHopDown || section.chainIncomplete
              ? PatrolSeverity.problem
              : PatrolSeverity.ok,
        ),
        title: Text(appLocalizations.patrolChainOn),
        subtitle: Text('${input.chainEntry} → ${input.chainLanding}'),
      ),
    );
    items.addAll(_issueItems(context, issues, PatrolIssueSection.link));
    return items;
  }

  List<Widget> _coreItems(
    BuildContext context,
    PatrolCoreSection section,
    List<PatrolIssue> issues,
  ) {
    final items = <Widget>[
      ListItem(
        title: Text(appLocalizations.patrolVersion),
        trailing: Text(section.input.versionLabel),
      ),
    ];
    if (_checkingConfig || section.input.configCheck == null) {
      items.add(ListItem(title: Text(appLocalizations.patrolConfigChecking)));
    } else if (section.input.configCheck == PatrolConfigCheck.passed) {
      items.add(
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.ok),
          title: Text(appLocalizations.patrolConfigValid),
        ),
      );
    } else {
      // Failed and unavailable are diagnosable issues now (T68):
      // tappable rows into the detail page, no raw error on the list.
      items.addAll(_issueItems(context, issues, PatrolIssueSection.core));
    }
    return items;
  }

  String _actionLabel(PatrolAction action) => patrolActionLabel(action);

  /// Appends the section's whitelist fix action (T29) when the
  /// section is not healthy: every problem on this page carries its
  /// executable next step instead of being a display-only warning.
  List<Widget> _withAction(
    List<Widget> items,
    PatrolAction? action,
    PatrolSeverity severity,
  ) {
    if (action == null || severity == PatrolSeverity.ok) return items;
    return [
      ...items,
      ListItem(
        leading: const Icon(Icons.build_outlined),
        title: Text(_actionLabel(action)),
        trailing: FilledButton.tonal(
          onPressed: _fixing ? null : () => _runFix(action),
          child: Text(appLocalizations.patrolFix),
        ),
      ),
    ];
  }

  /// Authorization prompt for a fix. Shown through the app-wide
  /// dialog route (root navigator, the same path as every other
  /// prompt in the app) — a page-local dialog route is exactly the
  /// kind of wiring that can swallow a tap without a trace.
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
                    _actionLabel(action),
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(appLocalizations.patrolFixConfirmDesc),
                  const SizedBox(height: 8),
                  // Plain Row + Checkbox instead of CheckboxListTile:
                  // the compound tile rendered as an empty grey block
                  // in this dialog on device (same grey-box signature
                  // as the T30 form repair).
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

  /// The persistent on-page status line for the fix loop: a spinner
  /// while a fix runs, then its outcome (with the failure reason)
  /// until the next run replaces it.
  Widget _fixStatusBand(BuildContext context) {
    final scheme = context.colorScheme;
    final action = _fixStatusAction;
    return ListItem(
      leading: _fixing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _fixStatusFailed
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: _fixStatusFailed ? scheme.error : scheme.primary,
            ),
      title: Text(
        action == null
            ? appLocalizations.patrolFix
            : '${appLocalizations.patrolFix} · ${_actionLabel(action)}',
      ),
      subtitle: Text(
        _fixing ? appLocalizations.patrolFixRunning : (_fixStatusText ?? ''),
      ),
    );
  }

  bool _verifyFix(
    PatrolAction action,
    PatrolReport before,
    PatrolReport after,
  ) {
    return verifyPatrolFix(
      action,
      before,
      after,
      updateFailed: _updateFailed,
    );
  }

  /// One authorized fix run: snapshot → whitelist action → rebuild
  /// the report → verify → auto-rollback when verification fails and
  /// a snapshot exists → record the outcome (T29 phase-1 loop).
  ///
  /// Every step reports back on THIS page (see [_fixStatusBand]): the
  /// authorization prompt, the running state, the outcome and — on
  /// any failure, including an executor that could not run at all —
  /// the reason. An exception anywhere in the chain lands in the
  /// status line instead of vanishing: a fix tap with zero visible
  /// effect is itself the defect this page must never reproduce.
  Future<void> _runFix(PatrolAction action) async {
    if (_fixing) return;
    setState(() {
      _fixing = true;
      _fixStatusAction = action;
      _fixStatusText = null;
      _fixStatusFailed = false;
    });
    try {
      if (!_sessionTrust) {
        final trust = await _confirmFix(action);
        if (!mounted) return;
        if (trust == null) {
          setState(() => _fixStatusText = appLocalizations.patrolFixCancelled);
          return;
        }
        _sessionTrust = trust;
      }
      final before = _readReport();
      final profile = ref.read(currentProfileProvider);
      final result = await executePatrolAction(
        globalState.appController,
        action,
        profile: profile,
      );
      if (action == PatrolAction.reloadConfig) {
        await _runConfigCheck();
      }
      if (action == PatrolAction.updateSubscription) {
        await _loadUpdateFailure();
      }
      final after = _readReport();
      final verified = result.executed && _verifyFix(action, before, after);
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
        // Keep the snapshot so the records page can undo this fix.
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
      patrolAttentionCount.value = _readReport().problemCount;
      if (mounted) {
        final headline = switch (outcome) {
          'applied' => appLocalizations.patrolFixApplied,
          'failedRolledBack' => appLocalizations.patrolFixRolledBack,
          _ => appLocalizations.patrolFixFailed,
        };
        setState(() {
          _fixStatusFailed = outcome != 'applied';
          // The executor's reason rides along: 'no current profile',
          // a core error, the group counts — never a bare failure.
          _fixStatusText = result.detail.isEmpty
              ? headline
              : '$headline · ${result.detail}';
        });
        globalState.showNotifier(headline);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _fixStatusFailed = true;
          _fixStatusText = '${appLocalizations.patrolFixFailed} · $error';
        });
      }
    } finally {
      if (mounted) setState(() => _fixing = false);
    }
  }

  /// AI interpretation flow (T30): build the redacted summary, show
  /// it verbatim for confirmation, only then call the provider and
  /// show its answer. The AI never executes anything itself — any
  /// fix still goes through the page's whitelist executor.
  Future<void> _runAiInterpretation() async {
    final config = _aiConfig;
    if (config == null || !config.configured) return;
    final report = _readReport();
    final names = <String>{};
    for (final group in ref.read(groupsProvider)) {
      for (final proxy in group.all) {
        names.add(proxy.name);
      }
    }
    if (report.link.input.chainEntry.isNotEmpty) {
      names.add(report.link.input.chainEntry);
    }
    if (report.link.input.chainLanding.isNotEmpty) {
      names.add(report.link.input.chainLanding);
    }
    final issues = buildPatrolIssues(
      report,
      coreRunning: ref.read(
        runTimeProvider.select((state) => state != null),
      ),
      subscriptionUrl: ref.read(
        currentProfileProvider.select((state) => state?.url ?? ''),
      ),
    );
    final summary = buildPatrolSummary(
      report,
      nodeNames: names.toList(),
      // T69: local diagnoses ride along as established facts.
      localConclusions: [
        for (final issue in issues) patrolIssueConclusion(issue),
      ],
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
      result = await fetchAiInterpretation(config, summary);
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

  /// The page's verdict band (T38 composition + glass): the patrol
  /// conclusion leads the page as a live-glass card with a severity badge,
  /// lifted out of the flat list rhythm of the sections below it. The
  /// content is unchanged — same verdict text, same checking subtitle —
  /// only the hierarchy and surface change.
  Widget _verdictBand(BuildContext context, PatrolReport report) {
    final attention = report.attentionCount;
    final severity = report.hasProblems
        ? PatrolSeverity.problem
        : attention > 0
        ? PatrolSeverity.notice
        : PatrolSeverity.ok;
    final scheme = context.colorScheme;
    final badgeColor = switch (severity) {
      PatrolSeverity.problem => scheme.error,
      PatrolSeverity.notice => scheme.tertiary,
      PatrolSeverity.ok => scheme.primary,
    };
    return GlassScope(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: CommonCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withValues(alpha: 0.12),
                  ),
                  child: _severityIcon(context, severity),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attention > 0
                            ? appLocalizations.patrolAttentionNeeded(attention)
                            : appLocalizations.patrolAllGood,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_checkingConfig) ...[
                        const SizedBox(height: 2),
                        Text(
                          appLocalizations.patrolConfigChecking,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _buildReport();
    final issues = buildPatrolIssues(
      report,
      coreRunning: ref.watch(
        runTimeProvider.select((state) => state != null),
      ),
      subscriptionUrl: ref.watch(
        currentProfileProvider.select((state) => state?.url ?? ''),
      ),
    );
    // Keep the navigation badge on the full report's problem count.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      patrolAttentionCount.value = report.problemCount;
    });
    return CommonScaffold(
      title: appLocalizations.aiPatrol,
      actions: [
        if (_aiConfig?.configured ?? false)
          IconButton(
            onPressed: _runAiInterpretation,
            tooltip: appLocalizations.aiInterpret,
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
        IconButton(
          onPressed: () async {
            await BaseNavigator.push(context, const AiConfigView());
            final config = await AiConfigStore.load();
            if (mounted) setState(() => _aiConfig = config);
          },
          tooltip: appLocalizations.aiConfigTitle,
          icon: const Icon(Icons.tune_outlined),
        ),
        IconButton(
          onPressed: () =>
              BaseNavigator.push(context, const PatrolRecordsView()),
          tooltip: appLocalizations.patrolRecords,
          icon: const Icon(Icons.history),
        ),
        IconButton(
          onPressed: () {
            _runConfigCheck();
            _loadUpdateFailure();
            setState(() {});
          },
          tooltip: appLocalizations.patrolRecheck,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: ListView(
        children: [
          _verdictBand(context, report),
          if (_fixing || _fixStatusText != null) _fixStatusBand(context),
          ..._section(
            context,
            appLocalizations.patrolSectionLogs,
            _withAction(
              _logItems(context, report.logs, issues),
              report.logs.suggestedAction,
              report.logs.severity,
            ),
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionSubscription,
            _withAction(
              _subscriptionItems(context, report.subscription, issues),
              report.subscription.suggestedAction,
              report.subscription.severity,
            ),
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionNodes,
            _withAction(
              _nodeItems(context, report.nodes, issues),
              report.nodes.suggestedAction,
              report.nodes.severity,
            ),
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionLink,
            _withAction(
              _linkItems(context, report.link, issues),
              report.link.suggestedAction,
              report.link.severity,
            ),
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionCore,
            _withAction(
              _coreItems(context, report.core, issues),
              report.core.suggestedAction,
              report.core.severity,
            ),
          ),
        ],
      ),
    );
  }
}

/// Repair history (T29): every fix attempt with its outcome, and a
/// manual undo for subscription updates that kept their snapshot.
class PatrolRecordsView extends ConsumerStatefulWidget {
  const PatrolRecordsView({super.key});

  @override
  ConsumerState<PatrolRecordsView> createState() => _PatrolRecordsViewState();
}

class _PatrolRecordsViewState extends ConsumerState<PatrolRecordsView> {
  List<PatrolRepairRecord>? _records;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await PatrolStore.records();
    if (mounted) setState(() => _records = records);
  }

  Future<void> _undo(PatrolRepairRecord record) async {
    final backup = record.profileBackupPath;
    if (backup == null) return;
    Profile? profile;
    for (final candidate in ref.read(profilesProvider)) {
      if (candidate.id == record.profileId) {
        profile = candidate;
        break;
      }
    }
    if (profile == null) return;
    final restored = await rollbackSubscriptionSnapshot(
      globalState.appController,
      profile: profile,
      backupPath: backup,
    );
    if (restored) {
      await PatrolStore.updateRecord(record.copyWith(outcome: 'undone'));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    return CommonScaffold(
      title: appLocalizations.patrolRecords,
      body: records == null
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? Center(child: Text(appLocalizations.patrolRecordsEmpty))
          : ListView(
              children: [
                for (final record in records)
                  ListItem(
                    title: Text(patrolActionLabel(record.action)),
                    subtitle: Text(
                      '${record.at.lastUpdateTimeDesc} · '
                      '${patrolOutcomeLabel(record.outcome)}'
                      '${record.detail.isEmpty ? '' : ' · ${record.detail}'}',
                    ),
                    trailing:
                        record.outcome == 'applied' &&
                            record.profileBackupPath != null
                        ? TextButton(
                            onPressed: () => _undo(record),
                            child: Text(appLocalizations.patrolRecordUndo),
                          )
                        : null,
                  ),
              ],
            ),
    );
  }
}
