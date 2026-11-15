import 'package:bett_box/common/app_localizations.dart';
import 'package:bett_box/common/profile_chain.dart';
import 'package:bett_box/common/string.dart';
import 'package:bett_box/models/common.dart' show redactSensitiveText;

/// User-facing failure wording (T150, user directive 2026-11-15: every
/// failure must state its concrete reason plus a workable next step —
/// a bare "failed" banner left users guessing, most visibly when a stale
/// chain selection silently rolled profile switches back).
///
/// This file only maps an already-produced error to display text; it
/// introduces no failure machinery of its own. Reasons pass through
/// [redactSensitiveText] so subscription URLs and credentials never
/// reach the screen.

/// Classifies [error] as a stale chain selection, or returns null.
///
/// Dart-side assembly throws [ChainSelectionStaleException] directly.
/// The entry end is resolved by the core (patchChainPolicy), so its
/// staleness comes back as a plain setup-error string; the core's
/// entry/exit "not found" wordings are matched explicitly. The legacy
/// combined "entry ... or exit ... not found" wording is ambiguous
/// about which end is stale, so it is left unclassified — the generic
/// path still shows its (redacted) text, which names both candidates.
ChainStaleReference? chainStaleReferenceOf(Object error) {
  if (error is ChainSelectionStaleException) return error.reference;
  final text = error.toString();
  if (text.contains(
    'is not a directly verifiable node or group in the active profile',
  )) {
    return ChainStaleReference.entry;
  }
  if (text.contains(' or exit ')) return null;
  final notFound = RegExp(
    r'(entry|exit) "[^"]*" not found in this profile',
  ).firstMatch(text);
  if (notFound != null) {
    return notFound.group(1) == 'entry'
        ? ChainStaleReference.entry
        : ChainStaleReference.exitTarget;
  }
  return null;
}

/// The dedicated notice for a stale chain selection: which end went
/// stale, and the remedy (reselect the entry/exit in chain settings).
/// Wording is context-neutral so switch, restart and apply surfaces can
/// all share it.
String chainStaleNotice(ChainStaleReference reference) => switch (reference) {
  ChainStaleReference.exitProfile => appLocalizations.chainStaleExitProfile,
  ChainStaleReference.exitTarget => appLocalizations.chainStaleExitTarget,
  ChainStaleReference.entry => appLocalizations.chainStaleEntry,
  ChainStaleReference.exitSameProfile =>
    appLocalizations.chainStaleExitSameProfile,
};

/// The dedicated chain notice when [error] is a stale chain selection,
/// otherwise null.
String? chainStaleNoticeOf(Object error) {
  final reference = chainStaleReferenceOf(error);
  return reference == null ? null : chainStaleNotice(reference);
}

/// The error's own message with credentials masked out.
String redactedReasonOf(Object error) =>
    redactSensitiveText(error.formatError);

/// Display text for failures that have no dedicated wording: the
/// redacted reason, or the chain notice when the chain selection is
/// what went stale.
String failureNoticeOf(Object error) =>
    chainStaleNoticeOf(error) ?? redactedReasonOf(error);

/// Full text for a failed profile switch. A stale chain selection gets
/// its dedicated notice; anything else keeps the rollback wording and
/// gains the concrete reason plus the next step.
String profileSwitchFailureNotice(Object error, {required bool rolledBack}) {
  final stale = chainStaleNoticeOf(error);
  if (stale != null) return stale;
  final reason = redactedReasonOf(error);
  return rolledBack
      ? appLocalizations.profileSwitchFailedRollbackReason(reason)
      : appLocalizations.profileSwitchFailedReason(reason);
}

/// Full text for a failed core restart.
String coreRestartFailureNotice(Object error) {
  final stale = chainStaleNoticeOf(error);
  if (stale != null) return stale;
  return '${appLocalizations.restartCoreTitle}: ${redactedReasonOf(error)} '
      '${appLocalizations.restartCoreFailedSolution}';
}

/// Full text for a failed service start/stop from the home toggle.
String serviceToggleFailureNotice(Object error) {
  final stale = chainStaleNoticeOf(error);
  if (stale != null) return stale;
  return appLocalizations.serviceStartStopFailed(redactedReasonOf(error));
}

/// Full text for a failed profile update, manual or automatic.
String profileUpdateFailureNotice(
  String name,
  Object error, {
  required bool automatic,
}) {
  final stale = chainStaleNoticeOf(error);
  if (stale != null) return stale;
  final reason = redactedReasonOf(error);
  return automatic
      ? appLocalizations.profileAutoUpdateFailed(name, reason)
      : appLocalizations.profileUpdateFailed(name, reason);
}
