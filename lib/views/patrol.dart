import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/profile_chain.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  bool get _checkingConfig => _configCheckScheduler.isRunning;

  @override
  void initState() {
    super.initState();
    ProfileChainStore.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _chainReady = true);
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
        if (previous != next) _runConfigCheck();
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

  PatrolReport _buildReport() {
    final logs = ref.watch(logsProvider.select((state) => state.list));
    final profile = ref.watch(currentProfileProvider);
    final groups = ref.watch(groupsProvider);
    final delayMap = ref.watch(delayDataSourceProvider);
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));

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
        // The app does not persist update failures today; the report
        // stays silent about them until the update flow records them.
        lastUpdateFailed: null,
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

  List<Widget> _logItems(BuildContext context, PatrolLogSection section) {
    if (!section.hasIssues) {
      return [
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.ok),
          title: Text(appLocalizations.patrolNoProblems),
        ),
      ];
    }
    final labels = {
      PatrolLogIssueKind.connection: appLocalizations.patrolLogConnection,
      PatrolLogIssueKind.dns: appLocalizations.patrolLogDns,
      PatrolLogIssueKind.timeout: appLocalizations.patrolLogTimeouts,
      PatrolLogIssueKind.rule: appLocalizations.patrolLogRule,
    };
    return [
      for (final kind in PatrolLogIssueKind.values)
        if (section.groupOf(kind) != null)
          ListItem(
            leading: _severityIcon(context, PatrolSeverity.problem),
            title: Text(labels[kind]!),
            trailing: Text('${section.groupOf(kind)!.count}'),
            subtitle: section.groupOf(kind)!.sample == null
                ? null
                : Text(
                    section.groupOf(kind)!.sample!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
    ];
  }

  List<Widget> _subscriptionItems(
    BuildContext context,
    PatrolSubscriptionSection section,
  ) {
    final input = section.input;
    if (!input.hasProfile) {
      return [
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.notice),
          title: Text(appLocalizations.patrolSubNoProfile),
        ),
      ];
    }
    final items = <Widget>[];
    if (section.isExpired) {
      items.add(
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.problem),
          title: Text(appLocalizations.patrolSubExpired),
        ),
      );
    }
    if (section.lastUpdateFailed) {
      items.add(
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.problem),
          title: Text(appLocalizations.patrolSubUpdateFailed),
        ),
      );
    }
    items.add(
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
    );
    if (section.isStale) {
      items.add(
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.notice),
          title: Text(appLocalizations.patrolSubStale),
        ),
      );
    }
    return items;
  }

  List<Widget> _nodeItems(BuildContext context, PatrolNodeSection section) {
    if (section.total == 0 || section.tested == 0) {
      return [
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.notice),
          title: Text(appLocalizations.patrolNodesNoData),
        ),
      ];
    }
    final counts =
        '${appLocalizations.patrolNodesWorking} ${section.alive}'
        ' · ${appLocalizations.patrolNodesUnavailable} ${section.dead}'
        ' · ${appLocalizations.patrolNodesUntested} ${section.untested}';
    if (section.widespreadOutage) {
      return [
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.problem),
          title: Text(appLocalizations.patrolNodesWidespread),
          subtitle: Text(counts),
        ),
      ];
    }
    return [
      ListItem(
        leading: _severityIcon(context, section.severity),
        title: Text(counts),
        subtitle: section.dead > 0
            ? Text(appLocalizations.patrolNodesSomeDown)
            : null,
      ),
    ];
  }

  List<Widget> _linkItems(BuildContext context, PatrolLinkSection section) {
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
    if (section.chainIncomplete) {
      items.add(
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.problem),
          title: Text(appLocalizations.patrolChainIncomplete),
        ),
      );
    } else if (section.chainHopDown) {
      items.add(
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.problem),
          title: Text(appLocalizations.patrolChainHopDown),
        ),
      );
    }
    return items;
  }

  List<Widget> _coreItems(BuildContext context, PatrolCoreSection section) {
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
    } else if (section.input.configCheck == PatrolConfigCheck.unavailable) {
      // Not a pass and not a failure: the check could not run yet.
      items.add(
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.notice),
          title: Text(appLocalizations.patrolConfigUnavailable),
        ),
      );
    } else {
      items.add(
        ListItem(
          leading: _severityIcon(context, PatrolSeverity.problem),
          title: Text(appLocalizations.patrolConfigInvalid),
          subtitle: section.input.configError.isEmpty
              ? null
              : Text(
                  section.input.configError,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final report = _buildReport();
    final attention = report.attentionCount;
    return CommonScaffold(
      title: appLocalizations.aiPatrol,
      actions: [
        IconButton(
          onPressed: () {
            _runConfigCheck();
            setState(() {});
          },
          tooltip: appLocalizations.patrolRecheck,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: ListView(
        children: [
          ListItem(
            leading: _severityIcon(
              context,
              report.hasProblems
                  ? PatrolSeverity.problem
                  : attention > 0
                  ? PatrolSeverity.notice
                  : PatrolSeverity.ok,
            ),
            title: Text(
              attention > 0
                  ? appLocalizations.patrolAttentionNeeded(attention)
                  : appLocalizations.patrolAllGood,
            ),
            subtitle: _checkingConfig
                ? Text(appLocalizations.patrolConfigChecking)
                : null,
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionLogs,
            _logItems(context, report.logs),
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionSubscription,
            _subscriptionItems(context, report.subscription),
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionNodes,
            _nodeItems(context, report.nodes),
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionLink,
            _linkItems(context, report.link),
          ),
          ..._section(
            context,
            appLocalizations.patrolSectionCore,
            _coreItems(context, report.core),
          ),
        ],
      ),
    );
  }
}
