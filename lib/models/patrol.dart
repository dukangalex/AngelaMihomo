/// AI Patrol data layer (phase 1, milestone 1).
///
/// Pure Dart aggregation over injected snapshots of app state. Nothing in
/// this file touches providers, the core, or the file system: callers map
/// live app state into the `*Input` values below, and [PatrolReport.build]
/// turns them into a structured, language-neutral report. The patrol page
/// is responsible for turning the report into localized, human-readable
/// text, so every rule here is unit-testable without a widget tree.
library;

/// How much a patrol section needs the user's attention.
enum PatrolSeverity { ok, notice, problem }

/// The four log problem classes from the patrol spec.
enum PatrolLogIssueKind { connection, dns, timeout, rule }

/// One log line, reduced to what classification needs.
class PatrolLogEntry {
  /// `LogLevel.name` of the source log (`warning` / `error` are counted).
  final String level;
  final String payload;
  final DateTime time;

  const PatrolLogEntry({
    required this.level,
    required this.payload,
    required this.time,
  });
}

class PatrolLogIssueGroup {
  final PatrolLogIssueKind kind;
  final int count;

  /// Payload of the most recent entry in this group (input order is
  /// oldest-first, matching the app log buffer).
  final String? sample;

  const PatrolLogIssueGroup({
    required this.kind,
    required this.count,
    this.sample,
  });
}

class PatrolLogSection {
  final int totalIssues;
  final Map<PatrolLogIssueKind, PatrolLogIssueGroup> groups;

  const PatrolLogSection({required this.totalIssues, required this.groups});

  bool get hasIssues => totalIssues > 0;

  PatrolSeverity get severity =>
      hasIssues ? PatrolSeverity.problem : PatrolSeverity.ok;

  PatrolLogIssueGroup? groupOf(PatrolLogIssueKind kind) => groups[kind];
}

/// Subscription state for the current profile.
class PatrolSubscriptionInput {
  final bool hasProfile;

  /// True when the profile has a subscription URL (local files never go
  /// stale and never expire).
  final bool isRemote;
  final DateTime? lastUpdateDate;

  /// Whether the app auto-updates this profile on [autoUpdateDuration].
  final bool autoUpdateEnabled;
  final Duration autoUpdateDuration;

  /// Subscription expiry from the subscription-info header, when known.
  final DateTime? expiresAt;

  /// Whether the most recent update attempt failed. Null means the app
  /// keeps no such record (current state: update failures are only shown
  /// transiently), so the report stays silent about it.
  final bool? lastUpdateFailed;

  const PatrolSubscriptionInput({
    required this.hasProfile,
    required this.isRemote,
    this.lastUpdateDate,
    this.autoUpdateEnabled = false,
    this.autoUpdateDuration = Duration.zero,
    this.expiresAt,
    this.lastUpdateFailed,
  });
}

class PatrolSubscriptionSection {
  final PatrolSubscriptionInput input;
  final bool isExpired;
  final bool isStale;
  final bool neverUpdated;

  const PatrolSubscriptionSection({
    required this.input,
    required this.isExpired,
    required this.isStale,
    required this.neverUpdated,
  });

  bool get lastUpdateFailed => input.lastUpdateFailed == true;

  PatrolSeverity get severity {
    if (!input.hasProfile) return PatrolSeverity.notice;
    if (isExpired || lastUpdateFailed) return PatrolSeverity.problem;
    if (isStale || neverUpdated) return PatrolSeverity.notice;
    return PatrolSeverity.ok;
  }
}

/// One node's most recent speed-test result. [delay] is null when the node
/// has never been tested; a value <= 0 means the last test failed.
class PatrolNodeSample {
  final String name;
  final int? delay;

  const PatrolNodeSample({required this.name, this.delay});

  bool get tested => delay != null;
  bool get alive => delay != null && delay! > 0;
  bool get dead => delay != null && delay! <= 0;
}

class PatrolNodeSection {
  final int total;
  final int alive;
  final int dead;
  final int untested;

  /// Most tested nodes are down: the pattern of a broken network or a
  /// dead subscription rather than a few bad nodes.
  final bool widespreadOutage;

  const PatrolNodeSection({
    required this.total,
    required this.alive,
    required this.dead,
    required this.untested,
    required this.widespreadOutage,
  });

  int get tested => alive + dead;

  PatrolSeverity get severity {
    if (total == 0 || tested == 0) return PatrolSeverity.notice;
    if (widespreadOutage || dead == tested) return PatrolSeverity.problem;
    if (dead > 0) return PatrolSeverity.notice;
    return PatrolSeverity.ok;
  }
}

/// Outbound mode and chain-proxy state.
class PatrolLinkInput {
  /// `Mode.name` of the patched config (`rule` / `global` / `direct`).
  final String mode;
  final bool chainEnabled;
  final String chainEntry;
  final String chainLanding;

  /// Whether each chain hop's latest speed test succeeded. Null when the
  /// hop has no test data, so the report does not guess.
  final bool? chainEntryAlive;
  final bool? chainLandingAlive;

  const PatrolLinkInput({
    required this.mode,
    this.chainEnabled = false,
    this.chainEntry = '',
    this.chainLanding = '',
    this.chainEntryAlive,
    this.chainLandingAlive,
  });
}

class PatrolLinkSection {
  final PatrolLinkInput input;

  const PatrolLinkSection({required this.input});

  bool get chainIncomplete =>
      input.chainEnabled &&
      (input.chainEntry.trim().isEmpty || input.chainLanding.trim().isEmpty);

  bool get chainHopDown =>
      input.chainEnabled &&
      (input.chainEntryAlive == false || input.chainLandingAlive == false);

  PatrolSeverity get severity => (chainIncomplete || chainHopDown)
      ? PatrolSeverity.problem
      : PatrolSeverity.ok;
}

/// Outcome of a config validation run, as the patrol report needs it.
///
/// [unavailable] is deliberately distinct from both other states: the
/// check could not run at all, so the report must neither claim the
/// config passed nor blame it for failing.
enum PatrolConfigCheck { passed, failed, unavailable }

/// Translates the raw string returned by the core's config validation
/// (an empty string means success) into a [PatrolConfigCheck].
///
/// Why [PatrolConfigCheck.unavailable] exists: validation is not a pure
/// parse of the profile text. The core validates the *runtime* setup,
/// and `loadSetupConfig` in the Go core refuses to run at all when
/// `SetupParams.ProfilePath` is empty, answering `profile path is empty`
/// before any config content is looked at. That path only exists once a
/// profile is bound to the runtime; before the service has ever started
/// it stays empty, and the sibling not-ready situations in this call
/// chain funnel into the same guard (on the Dart side,
/// `buildSetupParams` likewise returns params without a profile path
/// when no profile is bound to the runtime yet). So this message means
/// "could not check", not "check failed": surfacing it as a failure
/// blames a healthy config for a runtime that simply has not started.
/// Only that known not-ready signature maps to
/// [PatrolConfigCheck.unavailable]; every other non-empty answer is a
/// genuine validation failure and keeps its original text as detail.
PatrolConfigCheck translateConfigCheck(String rawMessage) {
  if (rawMessage.isEmpty) return PatrolConfigCheck.passed;
  if (rawMessage.contains('profile path is empty')) {
    return PatrolConfigCheck.unavailable;
  }
  return PatrolConfigCheck.failed;
}

/// Core version label and config validation outcome.
class PatrolCoreInput {
  final String versionLabel;

  /// Null when validation has not run (or is still running).
  final PatrolConfigCheck? configCheck;

  /// Original core message, kept only for a failed check.
  final String configError;

  const PatrolCoreInput({
    required this.versionLabel,
    this.configCheck,
    this.configError = '',
  });
}

class PatrolCoreSection {
  final PatrolCoreInput input;

  const PatrolCoreSection({required this.input});

  /// An unavailable check is worth a glance (notice) but is not a
  /// problem: nothing was found wrong with the config.
  PatrolSeverity get severity => switch (input.configCheck) {
    PatrolConfigCheck.failed => PatrolSeverity.problem,
    PatrolConfigCheck.unavailable => PatrolSeverity.notice,
    _ => PatrolSeverity.ok,
  };
}

/// The full patrol report: five sections plus headline counts.
class PatrolReport {
  final DateTime generatedAt;
  final PatrolLogSection logs;
  final PatrolSubscriptionSection subscription;
  final PatrolNodeSection nodes;
  final PatrolLinkSection link;
  final PatrolCoreSection core;

  const PatrolReport({
    required this.generatedAt,
    required this.logs,
    required this.subscription,
    required this.nodes,
    required this.link,
    required this.core,
  });

  List<PatrolSeverity> get _severities => [
    logs.severity,
    subscription.severity,
    nodes.severity,
    link.severity,
    core.severity,
  ];

  /// Sections that need a fix.
  int get problemCount =>
      _severities.where((s) => s == PatrolSeverity.problem).length;

  /// Sections worth a glance but not broken.
  int get noticeCount =>
      _severities.where((s) => s == PatrolSeverity.notice).length;

  /// Sections marked as needing attention (problems + notices), used by
  /// the headline summary.
  int get attentionCount => problemCount + noticeCount;

  bool get hasProblems => problemCount > 0;

  factory PatrolReport.build({
    required DateTime now,
    required List<PatrolLogEntry> logs,
    required PatrolSubscriptionInput subscription,
    required List<PatrolNodeSample> nodes,
    required PatrolLinkInput link,
    required PatrolCoreInput core,
  }) {
    return PatrolReport(
      generatedAt: now,
      logs: classifyLogs(logs),
      subscription: evaluateSubscription(subscription, now),
      nodes: evaluateNodes(nodes),
      link: PatrolLinkSection(input: link),
      core: PatrolCoreSection(input: core),
    );
  }
}

/// Classifies warning/error log entries into the four spec classes.
///
/// Precedence matters: DNS first (a failed lookup is the root cause, not
/// a generic connection failure), then timeout (more specific than the
/// dial failure it usually rides on), then generic connection failures,
/// then rule/provider problems. Info and debug entries never count:
/// at those levels the same words appear in healthy traffic logs.
PatrolLogSection classifyLogs(List<PatrolLogEntry> entries) {
  final counts = <PatrolLogIssueKind, int>{};
  final samples = <PatrolLogIssueKind, String>{};
  var total = 0;
  for (final entry in entries) {
    if (entry.level != 'warning' && entry.level != 'error') continue;
    final kind = _classifyPayload(entry.payload);
    if (kind == null) continue;
    total++;
    counts[kind] = (counts[kind] ?? 0) + 1;
    samples[kind] = entry.payload;
  }
  return PatrolLogSection(
    totalIssues: total,
    groups: {
      for (final kind in PatrolLogIssueKind.values)
        if (counts.containsKey(kind))
          kind: PatrolLogIssueGroup(
            kind: kind,
            count: counts[kind]!,
            sample: samples[kind],
          ),
    },
  );
}

PatrolLogIssueKind? _classifyPayload(String payload) {
  final text = payload.toLowerCase();
  if (text.contains('dns') ||
      text.contains('no such host') ||
      text.contains('name resolution') ||
      text.contains('failed to resolve')) {
    return PatrolLogIssueKind.dns;
  }
  if (text.contains('timeout') ||
      text.contains('timed out') ||
      text.contains('deadline exceeded')) {
    return PatrolLogIssueKind.timeout;
  }
  if (text.contains('dial') ||
      text.contains('connect') ||
      text.contains('handshake') ||
      text.contains('unreachable') ||
      text.contains('no route to host') ||
      text.contains('broken pipe')) {
    return PatrolLogIssueKind.connection;
  }
  if (text.contains('rule-set') ||
      text.contains('ruleset') ||
      text.contains('rule provider') ||
      text.contains('geosite') ||
      text.contains('geoip') ||
      text.contains('mmdb')) {
    return PatrolLogIssueKind.rule;
  }
  return null;
}

PatrolSubscriptionSection evaluateSubscription(
  PatrolSubscriptionInput input,
  DateTime now,
) {
  final lastUpdate = input.lastUpdateDate;
  final isExpired =
      input.isRemote &&
      input.expiresAt != null &&
      input.expiresAt!.isBefore(now);
  final neverUpdated = input.isRemote && lastUpdate == null;
  var isStale = false;
  if (input.isRemote && lastUpdate != null) {
    final age = now.difference(lastUpdate);
    if (input.autoUpdateEnabled && input.autoUpdateDuration > Duration.zero) {
      isStale = age > input.autoUpdateDuration;
    } else if (!input.autoUpdateEnabled) {
      // Without auto-update nothing refreshes the profile on its own;
      // a month-old copy is worth a nudge, not an alarm.
      isStale = age > const Duration(days: 30);
    }
  }
  return PatrolSubscriptionSection(
    input: input,
    isExpired: isExpired,
    isStale: isStale,
    neverUpdated: neverUpdated,
  );
}

/// Minimum tested-node count before the outage ratio is meaningful.
const patrolOutageMinSamples = 5;

/// Share of dead nodes (of tested) that counts as a widespread outage.
const patrolOutageDeadRatio = 0.6;

PatrolNodeSection evaluateNodes(List<PatrolNodeSample> samples) {
  var alive = 0;
  var dead = 0;
  var untested = 0;
  for (final sample in samples) {
    if (sample.alive) {
      alive++;
    } else if (sample.dead) {
      dead++;
    } else {
      untested++;
    }
  }
  final tested = alive + dead;
  final widespread =
      tested >= patrolOutageMinSamples &&
      dead / tested >= patrolOutageDeadRatio;
  return PatrolNodeSection(
    total: samples.length,
    alive: alive,
    dead: dead,
    untested: untested,
    widespreadOutage: widespread,
  );
}
