import 'package:bett_box/common/app_localizations.dart';
import 'package:bett_box/models/models.dart';

/// Localized text for patrol issues (T68), shared by the patrol
/// list rows and the issue detail page so a problem is named and
/// explained identically wherever it appears. All strings come from
/// the arb resources — nothing here hardcodes copy.
String patrolIssueTitle(PatrolIssue issue) => switch (issue.cause) {
  PatrolCause.logConnection => appLocalizations.patrolLogConnection,
  PatrolCause.logDns => appLocalizations.patrolLogDns,
  PatrolCause.logTimeout => appLocalizations.patrolLogTimeouts,
  PatrolCause.logRule => appLocalizations.patrolLogRule,
  PatrolCause.fetchFailed => appLocalizations.patrolSubUpdateFailed,
  PatrolCause.subExpired => appLocalizations.patrolSubExpired,
  PatrolCause.subStale => appLocalizations.patrolSubStale,
  PatrolCause.subNeverUpdated => appLocalizations.patrolSubNeverUpdated,
  PatrolCause.subNoProfile => appLocalizations.patrolSubNoProfile,
  PatrolCause.nodesNoData => appLocalizations.patrolNodesNoData,
  PatrolCause.nodesSomeDown => appLocalizations.patrolNodesSomeDown,
  PatrolCause.nodesWidespread => appLocalizations.patrolNodesWidespread,
  PatrolCause.chainIncomplete => appLocalizations.patrolChainIncomplete,
  PatrolCause.chainHopDown => appLocalizations.patrolChainHopDown,
  PatrolCause.configInvalid => appLocalizations.patrolConfigInvalid,
  PatrolCause.configUnavailable => appLocalizations.patrolConfigUnavailable,
};

/// The "why" answer for an issue. For fetch failures the stage
/// decides: [measuredStage] (from live probes) wins over the stage
/// classified from the recorded error — measured, not assumed.
String patrolIssueConclusion(
  PatrolIssue issue, {
  PatrolFetchStage? measuredStage,
  int? measuredHttpStatus,
}) {
  if (issue.cause == PatrolCause.fetchFailed) {
    // A live probe that measured an HTTP status outranks the
    // recorded one: it is what the server answers right now.
    final status =
        (measuredStage == PatrolFetchStage.http ||
            measuredStage == null && issue.stage == PatrolFetchStage.http)
        ? (measuredHttpStatus ?? issue.httpStatus)
        : issue.httpStatus;
    return patrolStageConclusion(
      measuredStage ?? issue.stage ?? PatrolFetchStage.unknown,
      status,
    );
  }
  return switch (issue.cause) {
    PatrolCause.logConnection => appLocalizations.patrolCauseLogConnection,
    PatrolCause.logDns => appLocalizations.patrolCauseLogDns,
    PatrolCause.logTimeout => appLocalizations.patrolCauseLogTimeout,
    PatrolCause.logRule => appLocalizations.patrolCauseLogRule,
    PatrolCause.subExpired => appLocalizations.patrolCauseSubExpired,
    PatrolCause.subStale => appLocalizations.patrolCauseSubStale,
    PatrolCause.subNeverUpdated => appLocalizations.patrolCauseSubNever,
    PatrolCause.subNoProfile => appLocalizations.patrolCauseSubNoProfile,
    PatrolCause.nodesNoData => appLocalizations.patrolCauseNodesNoData,
    PatrolCause.nodesSomeDown => appLocalizations.patrolCauseNodesSomeDown,
    PatrolCause.nodesWidespread =>
      appLocalizations.patrolCauseNodesWidespread,
    PatrolCause.chainIncomplete =>
      appLocalizations.patrolCauseChainIncomplete,
    PatrolCause.chainHopDown => appLocalizations.patrolCauseChainHopDown,
    PatrolCause.configInvalid => appLocalizations.patrolCauseConfigInvalid,
    PatrolCause.configUnavailable =>
      appLocalizations.patrolCauseConfigUnavailable,
    PatrolCause.fetchFailed => appLocalizations.patrolStageUnknown,
  };
}

String patrolStageName(PatrolFetchStage stage) => switch (stage) {
  PatrolFetchStage.proxy => appLocalizations.patrolStageNameProxy,
  PatrolFetchStage.dns => appLocalizations.patrolStageNameDns,
  PatrolFetchStage.tcp => appLocalizations.patrolStageNameTcp,
  PatrolFetchStage.tls => appLocalizations.patrolStageNameTls,
  PatrolFetchStage.http => appLocalizations.patrolStageNameHttp,
  PatrolFetchStage.timeout => appLocalizations.patrolStageNameTimeout,
  PatrolFetchStage.badContent => appLocalizations.patrolStageNameBadContent,
  PatrolFetchStage.unknown => appLocalizations.patrolStageUnknown,
};

/// A 5xx answer means the provider's server itself failed: the link
/// was reached and is not at fault, so it gets its own conclusion —
/// never the 4xx "your link looks wrong" wording.
bool patrolHttpIsServerError(int? httpStatus) =>
    httpStatus != null && httpStatus >= 500 && httpStatus < 600;

String patrolStageConclusion(PatrolFetchStage stage, int? httpStatus) =>
    switch (stage) {
      PatrolFetchStage.proxy => appLocalizations.patrolStageProxy,
      PatrolFetchStage.dns => appLocalizations.patrolStageDns,
      PatrolFetchStage.tcp => appLocalizations.patrolStageTcp,
      PatrolFetchStage.tls => appLocalizations.patrolStageTls,
      PatrolFetchStage.http =>
        patrolHttpIsServerError(httpStatus)
            ? appLocalizations.patrolStageHttpServer(httpStatus ?? 0)
            : appLocalizations.patrolStageHttp(httpStatus ?? 0),
      PatrolFetchStage.timeout => appLocalizations.patrolStageTimeout,
      PatrolFetchStage.badContent => appLocalizations.patrolStageBadContent,
      PatrolFetchStage.unknown => appLocalizations.patrolStageUnknown,
    };

/// The "what to do" answer. Fetch failures get the generic update
/// advice plus the stage-specific extra (start the service for a
/// proxy-hop failure, replace the link for a server refusal, check
/// the clock for TLS).
String patrolIssueAdvice(
  PatrolIssue issue, {
  PatrolFetchStage? stage,
  int? httpStatus,
}) {
  if (issue.cause == PatrolCause.fetchFailed) {
    final effective = stage ?? issue.stage ?? PatrolFetchStage.unknown;
    final status = httpStatus ?? issue.httpStatus;
    final extra = switch (effective) {
      PatrolFetchStage.proxy => appLocalizations.patrolAdviceFetchProxy,
      PatrolFetchStage.http =>
        patrolHttpIsServerError(status)
            ? appLocalizations.patrolAdviceFetchHttpServer
            : appLocalizations.patrolAdviceFetchHttp,
      PatrolFetchStage.tls => appLocalizations.patrolAdviceFetchTls,
      _ => null,
    };
    return extra == null
        ? appLocalizations.patrolAdviceFetch
        : '${appLocalizations.patrolAdviceFetch}\n$extra';
  }
  return switch (issue.cause) {
    PatrolCause.logConnection => appLocalizations.patrolAdviceLogConnection,
    PatrolCause.logDns => appLocalizations.patrolAdviceLogDns,
    PatrolCause.logTimeout => appLocalizations.patrolAdviceLogTimeout,
    PatrolCause.logRule => appLocalizations.patrolAdviceLogRule,
    PatrolCause.subExpired => appLocalizations.patrolAdviceSubExpired,
    PatrolCause.subStale => appLocalizations.patrolAdviceSubStale,
    PatrolCause.subNeverUpdated => appLocalizations.patrolAdviceSubNever,
    PatrolCause.subNoProfile => appLocalizations.patrolAdviceSubNoProfile,
    PatrolCause.nodesNoData => appLocalizations.patrolAdviceNodesNoData,
    PatrolCause.nodesSomeDown => appLocalizations.patrolAdviceNodesSomeDown,
    PatrolCause.nodesWidespread =>
      appLocalizations.patrolAdviceNodesWidespread,
    PatrolCause.chainIncomplete =>
      appLocalizations.patrolAdviceChainIncomplete,
    PatrolCause.chainHopDown => appLocalizations.patrolAdviceChainHopDown,
    PatrolCause.configInvalid => appLocalizations.patrolAdviceConfigInvalid,
    PatrolCause.configUnavailable =>
      appLocalizations.patrolAdviceConfigUnavailable,
    PatrolCause.fetchFailed => appLocalizations.patrolAdviceFetch,
  };
}

/// How the user can reproduce/check this class of problem by hand,
/// when a meaningful path exists.
String? patrolIssueRepro(PatrolIssue issue) => switch (issue.cause) {
  PatrolCause.fetchFailed => appLocalizations.patrolReproFetch,
  PatrolCause.logConnection ||
  PatrolCause.logDns ||
  PatrolCause.logTimeout ||
  PatrolCause.logRule => appLocalizations.patrolReproLogs,
  PatrolCause.nodesNoData ||
  PatrolCause.nodesSomeDown ||
  PatrolCause.nodesWidespread ||
  PatrolCause.chainHopDown => appLocalizations.patrolReproNodes,
  PatrolCause.configInvalid ||
  PatrolCause.configUnavailable => appLocalizations.patrolReproConfig,
  _ => null,
};

String patrolActionLabel(PatrolAction action) => switch (action) {
  PatrolAction.updateSubscription =>
    appLocalizations.patrolActionUpdateSubscription,
  PatrolAction.testNodes => appLocalizations.patrolActionTestNodes,
  PatrolAction.flushDns => appLocalizations.patrolActionFlushDns,
  PatrolAction.reloadConfig => appLocalizations.patrolActionReloadConfig,
};

String patrolOutcomeLabel(String outcome) => switch (outcome) {
  'applied' => appLocalizations.patrolOutcomeApplied,
  'failedRolledBack' => appLocalizations.patrolOutcomeRolledBack,
  'undone' => appLocalizations.patrolOutcomeUndone,
  _ => appLocalizations.patrolOutcomeFailed,
};

