/// AI Patrol diagnosis layer (T68).
///
/// Turns a [PatrolReport] from a display into a diagnosis: every
/// problem becomes a [PatrolIssue] that answers the three patrol
/// questions — why (a plain-language cause conclusion), on what
/// evidence (log samples, recorded errors, live state the user can
/// check), and what to do (advice copy and/or the whitelist fix).
///
/// Pure Dart, like the report layer: the page localizes [PatrolCause]
/// and [PatrolFactLabel], renders evidence, runs the probes listed
/// in [PatrolIssue.probePlan] through the probe layer, and executes
/// [PatrolIssue.action] through the existing whitelist executor.
/// Nothing here touches providers, the core, or the file system.
library;

import 'package:bett_box/models/patrol.dart';

/// Which patrol section an issue is listed under. A subscription
/// fetch failure evidenced in the log buffer is homed in the log
/// section (that is where the user meets it); the same diagnosis is
/// reachable from the subscription section when only the recorded
/// failure exists — one diagnosis, at most two doors (bowel #2).
enum PatrolIssueSection { logs, subscription, nodes, link, core }

/// Plain-language cause conclusions. The page maps each value to
/// localized copy; for fetch failures the conclusion is refined by
/// [PatrolIssue.stage] (recorded) and, after probing, by the
/// measured stage.
enum PatrolCause {
  logConnection,
  logDns,
  logTimeout,
  logRule,
  fetchFailed,
  subExpired,
  subStale,
  subNeverUpdated,
  subNoProfile,
  nodesNoData,
  nodesSomeDown,
  nodesWidespread,
  chainIncomplete,
  chainHopDown,
  configInvalid,
  configUnavailable,
  webdavBackup,
}

/// The stage at which a subscription fetch failed, from the network
/// path outward: the app fetches through the local core proxy while
/// the core runs, so [proxy] (core stopped / local port unreachable /
/// tunnel refused) is a first-class stage of its own.
enum PatrolFetchStage { proxy, dns, tcp, tls, http, timeout, badContent, unknown }

/// Classifies a recorded fetch error into its failure stage.
///
/// Deliberately conservative: only known signatures map to a stage.
/// Anything else is [PatrolFetchStage.unknown] — the diagnosis then
/// says so plainly and lets live probes decide (measured, not
/// assumed; bowel #1). The field instance that motivated T68,
/// `DioException [unknown]: null`, is exactly such a case: the
/// record alone cannot name a stage.
({PatrolFetchStage stage, int? httpStatus}) classifyFetchFailure(
  String error,
) {
  final text = error.toLowerCase();
  if (text.contains('configuration is empty')) {
    return (stage: PatrolFetchStage.badContent, httpStatus: null);
  }
  final statusMatch =
      RegExp(r'status code of (\d{3})').firstMatch(text) ??
      RegExp(r'error code:?\s*\(?\s*(\d{3})').firstMatch(text) ??
      // Probe outcomes report a bare measured status ("HTTP 502").
      RegExp(r'^http (\d{3})$').firstMatch(text.trim());
  if (statusMatch != null) {
    return (
      stage: PatrolFetchStage.http,
      httpStatus: int.tryParse(statusMatch.group(1)!),
    );
  }
  if (text.contains('failed host lookup') ||
      text.contains('no such host') ||
      text.contains('name or service not known') ||
      text.contains('nodename nor servname') ||
      text.contains('failed to resolve') ||
      text.contains('name resolution')) {
    return (stage: PatrolFetchStage.dns, httpStatus: null);
  }
  if (text.contains('handshake') || text.contains('certificate')) {
    return (stage: PatrolFetchStage.tls, httpStatus: null);
  }
  if (text.contains('timed out') ||
      text.contains('timeout') ||
      text.contains('deadline exceeded')) {
    return (stage: PatrolFetchStage.timeout, httpStatus: null);
  }
  if (text.contains('proxy')) {
    return (stage: PatrolFetchStage.proxy, httpStatus: null);
  }
  if (text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('connection closed') ||
      text.contains('connection error') ||
      text.contains('network is unreachable') ||
      text.contains('no route to host') ||
      text.contains('socketexception') ||
      text.contains('broken pipe')) {
    return (stage: PatrolFetchStage.tcp, httpStatus: null);
  }
  return (stage: PatrolFetchStage.unknown, httpStatus: null);
}

/// Live probes the detail page can run for an issue. Executed by the
/// probe layer in plan order; the chain stops descending at the
/// first failed stage (a DNS failure makes a TCP probe meaningless).
enum PatrolProbeKind {
  proxyPort,
  dnsLookup,
  tcpConnect,
  tlsHandshake,
  directFetch,
  proxyFetch,
}

/// Labels for state facts, localized by the page.
enum PatrolFactLabel {
  mode,
  coreState,
  nodesSummary,
  subscriptionHost,
  lastUpdate,
  httpStatus,
}

/// One checkable basis item ("凭什么"). Rendered by the page:
/// occurrences and state facts as localized lines, samples and the
/// recorded error as redacted verbatim evidence.
enum PatrolFactKind { occurrences, state, sample, recordedError }

class PatrolFact {
  final PatrolFactKind kind;

  /// occurrences: how many log entries matched.
  final int count;
  final DateTime? firstAt;
  final DateTime? lastAt;

  /// state: which fact, and its (language-neutral) value.
  final PatrolFactLabel? label;
  final String value;

  /// sample / recordedError: raw text; the page redacts before
  /// display and before anything is offered to the AI layer.
  final String text;

  const PatrolFact.occurrences({
    required this.count,
    this.firstAt,
    this.lastAt,
  }) : kind = PatrolFactKind.occurrences,
       label = null,
       value = '',
       text = '';

  const PatrolFact.state({required PatrolFactLabel this.label, this.value = ''})
    : kind = PatrolFactKind.state,
      count = 0,
      firstAt = null,
      lastAt = null,
      text = '';

  const PatrolFact.sample(this.text)
    : kind = PatrolFactKind.sample,
      count = 0,
      firstAt = null,
      lastAt = null,
      label = null,
      value = '';

  const PatrolFact.recordedError(this.text)
    : kind = PatrolFactKind.recordedError,
      count = 0,
      firstAt = null,
      lastAt = null,
      label = null,
      value = '';
}

/// One diagnosable problem. [id] is stable across rebuilds so the
/// detail page and the AI summary can refer to it.
class PatrolIssue {
  final String id;
  final PatrolIssueSection section;
  final PatrolSeverity severity;
  final PatrolCause cause;

  /// Fetch failures only: stage from the recorded error, and the
  /// HTTP status when the server answered with one.
  final PatrolFetchStage? stage;
  final int? httpStatus;

  /// Whitelist fix offered on the detail page, when one exists.
  final PatrolAction? action;

  /// The evidence the conclusion rests on (before live probes).
  final List<PatrolFact> facts;

  /// Redacted-on-display raw material for the 原始信息 fold: log
  /// samples, the recorded error, the core's config message.
  final String rawInfo;

  /// Probes the detail page offers, in run order. Empty when live
  /// probing cannot add anything for this issue.
  final List<PatrolProbeKind> probePlan;

  /// Subscription URL the probes/fetch diagnosis refer to. Kept for
  /// on-device probing only: never rendered (the host is shown as a
  /// state fact), never sent to the AI layer.
  final String probeUrl;

  const PatrolIssue({
    required this.id,
    required this.section,
    required this.severity,
    required this.cause,
    this.stage,
    this.httpStatus,
    this.action,
    this.facts = const [],
    this.rawInfo = '',
    this.probePlan = const [],
    this.probeUrl = '',
  });

  bool get isFetch => cause == PatrolCause.fetchFailed;
}

/// Probe plan for a subscription fetch diagnosis: walk the same path
/// the app walks. The local proxy hop is probed only while the core
/// runs (otherwise the app fetches direct and the hop does not
/// exist); TLS only for https.
List<PatrolProbeKind> fetchProbePlan({
  required Uri? url,
  required bool coreRunning,
}) {
  if (url == null || url.host.isEmpty) return const [];
  return [
    if (coreRunning) PatrolProbeKind.proxyPort,
    PatrolProbeKind.dnsLookup,
    PatrolProbeKind.tcpConnect,
    if (url.scheme == 'https') PatrolProbeKind.tlsHandshake,
    PatrolProbeKind.directFetch,
    if (coreRunning) PatrolProbeKind.proxyFetch,
  ];
}

/// Builds the diagnosable issue list for [report].
///
/// [coreRunning] and [subscriptionUrl] are live state the report
/// deliberately does not carry; the page supplies them. The fetch
/// failure is merged from both of its sources — log lines and the
/// recorded update failure — into ONE issue: log evidence when the
/// buffer holds it (homed in the log section), otherwise the
/// subscription section's recorded failure.
List<PatrolIssue> buildPatrolIssues(
  PatrolReport report, {
  required bool coreRunning,
  String subscriptionUrl = '',
}) {
  final issues = <PatrolIssue>[];
  final url = Uri.tryParse(subscriptionUrl);
  final host = (url != null && url.host.isNotEmpty) ? url.host : null;

  PatrolFact coreStateFact() => PatrolFact.state(
    label: PatrolFactLabel.coreState,
    value: coreRunning ? 'running' : 'stopped',
  );

  // ---- log issues (fetch handled separately below) ----
  final logSection = report.logs;
  for (final kind in PatrolLogIssueKind.values) {
    if (kind == PatrolLogIssueKind.subscriptionFetch) continue;
    final group = logSection.groupOf(kind);
    if (group == null) continue;
    final cause = switch (kind) {
      PatrolLogIssueKind.dns => PatrolCause.logDns,
      PatrolLogIssueKind.timeout => PatrolCause.logTimeout,
      PatrolLogIssueKind.rule => PatrolCause.logRule,
      PatrolLogIssueKind.webdavBackup => PatrolCause.webdavBackup,
      _ => PatrolCause.logConnection,
    };
    issues.add(
      PatrolIssue(
        id: 'log.${kind.name}',
        section: PatrolIssueSection.logs,
        severity: PatrolSeverity.problem,
        cause: cause,
        action: kind == PatrolLogIssueKind.dns
            ? PatrolAction.flushDns
            : kind == PatrolLogIssueKind.rule
            ? PatrolAction.reloadConfig
            : kind == PatrolLogIssueKind.webdavBackup
            ? PatrolAction.retryBackup
            : PatrolAction.testNodes,
        facts: [
          PatrolFact.occurrences(
            count: group.count,
            firstAt: group.firstAt,
            lastAt: group.lastAt,
          ),
          for (final sample in group.samples) PatrolFact.sample(sample),
          if (kind == PatrolLogIssueKind.dns)
            PatrolFact.state(
              label: PatrolFactLabel.nodesSummary,
              value:
                  '${report.nodes.alive}/${report.nodes.tested} '
                  'alive',
            ),
          coreStateFact(),
        ],
        rawInfo: group.samples.join('\n'),
        probePlan: kind == PatrolLogIssueKind.dns && host != null
            ? const [PatrolProbeKind.dnsLookup]
            : const [],
        probeUrl: subscriptionUrl,
      ),
    );
  }

  // ---- the subscription fetch failure: one merged diagnosis ----
  final fetchGroup = logSection.groupOf(PatrolLogIssueKind.subscriptionFetch);
  final recordedError = report.subscription.input.lastUpdateError;
  final hasFetchFailure =
      fetchGroup != null || report.subscription.lastUpdateFailed;
  if (hasFetchFailure) {
    // Prefer the recorded error for classification: it is the raw
    // exception, while log lines passed through the log formatter.
    final errorText = recordedError.isNotEmpty
        ? recordedError
        : (fetchGroup?.sample ?? '');
    final classified = classifyFetchFailure(errorText);
    issues.add(
      PatrolIssue(
        id: 'subscription.fetch',
        section: fetchGroup != null
            ? PatrolIssueSection.logs
            : PatrolIssueSection.subscription,
        severity: PatrolSeverity.problem,
        cause: PatrolCause.fetchFailed,
        stage: classified.stage,
        httpStatus: classified.httpStatus,
        action: PatrolAction.updateSubscription,
        facts: [
          if (fetchGroup != null)
            PatrolFact.occurrences(
              count: fetchGroup.count,
              firstAt: fetchGroup.firstAt,
              lastAt: fetchGroup.lastAt,
            ),
          if (recordedError.isNotEmpty)
            PatrolFact.recordedError(recordedError),
          if (fetchGroup != null)
            for (final sample in fetchGroup.samples)
              PatrolFact.sample(sample),
          if (host != null)
            PatrolFact.state(
              label: PatrolFactLabel.subscriptionHost,
              value: host,
            ),
          if (classified.httpStatus != null)
            PatrolFact.state(
              label: PatrolFactLabel.httpStatus,
              value: '${classified.httpStatus}',
            ),
          coreStateFact(),
        ],
        rawInfo: [
          if (recordedError.isNotEmpty) recordedError,
          if (fetchGroup != null) ...fetchGroup.samples,
        ].join('\n'),
        probePlan: fetchProbePlan(url: url, coreRunning: coreRunning),
        probeUrl: subscriptionUrl,
      ),
    );
  }

  // ---- subscription state issues ----
  final sub = report.subscription;
  if (!sub.input.hasProfile) {
    issues.add(
      const PatrolIssue(
        id: 'subscription.none',
        section: PatrolIssueSection.subscription,
        severity: PatrolSeverity.notice,
        cause: PatrolCause.subNoProfile,
      ),
    );
  } else {
    if (sub.isExpired) {
      issues.add(
        PatrolIssue(
          id: 'subscription.expired',
          section: PatrolIssueSection.subscription,
          severity: PatrolSeverity.problem,
          cause: PatrolCause.subExpired,
          action: PatrolAction.updateSubscription,
          facts: [
            if (sub.input.expiresAt != null)
              PatrolFact.state(
                label: PatrolFactLabel.lastUpdate,
                value: sub.input.expiresAt!.toIso8601String(),
              ),
          ],
        ),
      );
    }
    if (sub.neverUpdated) {
      issues.add(
        PatrolIssue(
          id: 'subscription.never',
          section: PatrolIssueSection.subscription,
          severity: PatrolSeverity.notice,
          cause: PatrolCause.subNeverUpdated,
          action: PatrolAction.updateSubscription,
        ),
      );
    } else if (sub.isStale) {
      issues.add(
        PatrolIssue(
          id: 'subscription.stale',
          section: PatrolIssueSection.subscription,
          severity: PatrolSeverity.notice,
          cause: PatrolCause.subStale,
          action: PatrolAction.updateSubscription,
          facts: [
            if (sub.input.lastUpdateDate != null)
              PatrolFact.state(
                label: PatrolFactLabel.lastUpdate,
                value: sub.input.lastUpdateDate!.toIso8601String(),
              ),
          ],
        ),
      );
    }
  }

  // ---- node issues ----
  final nodes = report.nodes;
  if (nodes.total == 0 || nodes.tested == 0) {
    issues.add(
      PatrolIssue(
        id: 'nodes.nodata',
        section: PatrolIssueSection.nodes,
        severity: PatrolSeverity.notice,
        cause: PatrolCause.nodesNoData,
        action: PatrolAction.testNodes,
        facts: [
          PatrolFact.state(
            label: PatrolFactLabel.nodesSummary,
            value: '0/${nodes.total} tested',
          ),
        ],
      ),
    );
  } else if (nodes.widespreadOutage) {
    issues.add(
      PatrolIssue(
        id: 'nodes.widespread',
        section: PatrolIssueSection.nodes,
        severity: PatrolSeverity.problem,
        cause: PatrolCause.nodesWidespread,
        action: PatrolAction.testNodes,
        facts: [
          PatrolFact.state(
            label: PatrolFactLabel.nodesSummary,
            value: '${nodes.alive}/${nodes.tested} alive',
          ),
          coreStateFact(),
        ],
      ),
    );
  } else if (nodes.dead > 0) {
    issues.add(
      PatrolIssue(
        id: 'nodes.down',
        section: PatrolIssueSection.nodes,
        severity: PatrolSeverity.notice,
        cause: PatrolCause.nodesSomeDown,
        action: PatrolAction.testNodes,
        facts: [
          PatrolFact.state(
            label: PatrolFactLabel.nodesSummary,
            value: '${nodes.alive}/${nodes.tested} alive',
          ),
        ],
      ),
    );
  }

  // ---- link issues ----
  final link = report.link;
  if (link.chainIncomplete) {
    issues.add(
      PatrolIssue(
        id: 'link.incomplete',
        section: PatrolIssueSection.link,
        severity: PatrolSeverity.problem,
        cause: PatrolCause.chainIncomplete,
        facts: [
          PatrolFact.state(
            label: PatrolFactLabel.mode,
            value: link.input.mode,
          ),
        ],
      ),
    );
  } else if (link.chainHopDown) {
    issues.add(
      PatrolIssue(
        id: 'link.hopdown',
        section: PatrolIssueSection.link,
        severity: PatrolSeverity.problem,
        cause: PatrolCause.chainHopDown,
        action: PatrolAction.testNodes,
        facts: [
          PatrolFact.state(
            label: PatrolFactLabel.nodesSummary,
            value:
                'entry ${link.input.chainEntryAlive == false ? 'down' : 'ok'}'
                ' · landing ${link.input.chainLandingAlive == false ? 'down' : 'ok'}',
          ),
        ],
      ),
    );
  }

  // ---- core / config issues ----
  final core = report.core;
  if (core.input.configCheck == PatrolConfigCheck.failed) {
    issues.add(
      PatrolIssue(
        id: 'core.config',
        section: PatrolIssueSection.core,
        severity: PatrolSeverity.problem,
        cause: PatrolCause.configInvalid,
        action: PatrolAction.reloadConfig,
        facts: [
          if (core.input.configError.isNotEmpty)
            PatrolFact.sample(core.input.configError),
        ],
        rawInfo: core.input.configError,
      ),
    );
  } else if (core.input.configCheck == PatrolConfigCheck.unavailable) {
    issues.add(
      PatrolIssue(
        id: 'core.unavailable',
        section: PatrolIssueSection.core,
        severity: PatrolSeverity.notice,
        cause: PatrolCause.configUnavailable,
        // T69: the check has not run because applying the profile
        // is what runs it — reloading IS the on-target fix, and the
        // verify step re-reads the fresh check result.
        action: PatrolAction.reloadConfig,
        facts: [coreStateFact()],
      ),
    );
  }

  return issues;
}

/// Post-fix verification (T29): did the fix actually improve the
/// picture? Shared by the patrol page and the issue detail page so
/// both judge a fix by the same standard. [updateFailed] is the
/// recorded subscription failure state after the fix ran.
bool verifyPatrolFix(
  PatrolAction action,
  PatrolReport before,
  PatrolReport after, {
  required bool updateFailed,
}) {
  return switch (action) {
    PatrolAction.updateSubscription =>
      after.subscription.severity != PatrolSeverity.problem && !updateFailed,
    // A retest verifies when it strictly improves the picture:
    // fewer dead nodes, first data where there was none, a chain
    // hop back, or the section fully healthy.
    PatrolAction.testNodes =>
      after.nodes.dead < before.nodes.dead ||
          (before.nodes.tested == 0 && after.nodes.tested > 0) ||
          after.nodes.severity == PatrolSeverity.ok ||
          (before.link.chainHopDown && !after.link.chainHopDown),
    // A cache flush has no direct observable; execution is the
    // verification available, and the record says what ran.
    PatrolAction.flushDns => true,
    PatrolAction.reloadConfig =>
      after.core.input.configCheck != PatrolConfigCheck.failed &&
          after.core.input.configCheck != PatrolConfigCheck.unavailable,
    // The retry itself is the observable: the executor reports
    // executed only when the DAV upload round-trip succeeded, so
    // an executed retry IS a verified fix (T69).
    PatrolAction.retryBackup => true,
  };
}

/// Derives the measured failure stage from probe outcomes, in path
/// order (the local proxy hop first — it is the app's first hop —
/// then DNS → TCP → TLS → HTTP). [outcomes] maps each probed kind to
/// whether it succeeded plus its failure detail. Returns null when
/// every probe passed (the failure no longer reproduces live).
PatrolFetchStage? measuredStageFromProbes(
  Map<PatrolProbeKind, ({bool ok, String detail})> outcomes,
) => measuredDiagnosisFromProbes(outcomes)?.stage;

/// Like [measuredStageFromProbes], but also carries the HTTP status
/// a failed fetch probe measured, so the conclusion can name it
/// (a measured 502 must read as a server fault, with its code).
({PatrolFetchStage stage, int? httpStatus})? measuredDiagnosisFromProbes(
  Map<PatrolProbeKind, ({bool ok, String detail})> outcomes,
) {
  bool? ok(PatrolProbeKind kind) => outcomes[kind]?.ok;
  ({PatrolFetchStage stage, int? httpStatus})? wrap(
    ({PatrolFetchStage stage, int? httpStatus}) classified,
  ) => classified.stage == PatrolFetchStage.unknown ? null : classified;
  if (ok(PatrolProbeKind.proxyPort) == false) {
    return (stage: PatrolFetchStage.proxy, httpStatus: null);
  }
  if (ok(PatrolProbeKind.dnsLookup) == false) {
    return (stage: PatrolFetchStage.dns, httpStatus: null);
  }
  if (ok(PatrolProbeKind.tcpConnect) == false) {
    return (stage: PatrolFetchStage.tcp, httpStatus: null);
  }
  if (ok(PatrolProbeKind.tlsHandshake) == false) {
    return (stage: PatrolFetchStage.tls, httpStatus: null);
  }
  final direct = outcomes[PatrolProbeKind.directFetch];
  if (direct != null && !direct.ok) {
    return wrap(classifyFetchFailure(direct.detail));
  }
  final proxy = outcomes[PatrolProbeKind.proxyFetch];
  if (proxy != null && !proxy.ok) {
    final classified = classifyFetchFailure(proxy.detail);
    // A proxied fetch that fails while the direct path works is a
    // proxy-path failure regardless of the wrapped error's shape.
    if (direct?.ok ?? false) {
      return (stage: PatrolFetchStage.proxy, httpStatus: null);
    }
    return wrap(classified);
  }
  return null;
}
