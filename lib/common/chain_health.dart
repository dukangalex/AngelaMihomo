import 'package:bett_box/common/path_score.dart';
import 'package:bett_box/common/profile_chain.dart';

/// One selectable chain target (a proxy or a group) found in a profile's
/// effective config. The chain settings page builds its entry/exit choice
/// lists from these, and the profile-card health projection reads the same
/// extraction, so both surfaces consume one definition of "what exists in
/// this profile".
class ChainTargetRef {
  final ChainTargetKind kind;
  final String name;

  const ChainTargetRef(this.kind, this.name);

  String get key => chainTargetKey(kind, name);
}

/// Extracts the chain-selectable targets of a profile config map (the
/// `proxies` become proxy targets, the `proxy-groups` become group
/// targets). Empty names and reserved path names are skipped and each
/// (kind, name) pair appears at most once — the exact rules the chain
/// settings page has always applied to its choice lists. Never throws:
/// malformed sections simply yield fewer (or no) targets.
List<ChainTargetRef> chainTargetsOf(Map<String, dynamic> config) {
  final targets = <ChainTargetRef>[];
  final seen = <String>{};
  void add(ChainTargetKind kind, dynamic name) {
    final text = name?.toString() ?? '';
    if (text.isEmpty || reservedPathNames.contains(text)) return;
    final target = ChainTargetRef(kind, text);
    if (seen.add(target.key)) targets.add(target);
  }

  final proxies = config['proxies'];
  if (proxies is List) {
    for (final proxy in proxies) {
      if (proxy is Map) add(ChainTargetKind.proxy, proxy['name']);
    }
  }
  final groups = config['proxy-groups'];
  if (groups is List) {
    for (final group in groups) {
      if (group is Map) add(ChainTargetKind.group, group['name']);
    }
  }
  return targets;
}

/// The [chainTargetKey] set of [chainTargetsOf], in the shape
/// [ProfileChain.selectionIssue] consumes.
Set<String> chainTargetKeysOf(Map<String, dynamic> config) => {
  for (final target in chainTargetsOf(config)) target.key,
};

/// Health of one profile's saved chain selection, as projected onto its
/// profile card (T152).
enum ChainCardHealth {
  /// The chain is not enabled; the card shows no chain marker.
  notEnabled,

  /// Both ends of the saved selection still resolve.
  healthy,

  /// The chain is enabled but at least one end no longer resolves (the
  /// exit profile is gone, the exit target is gone, the entry no longer
  /// resolves, or the selection is incomplete / points at its own
  /// profile).
  stale,
}

/// Pure, total projection of a saved chain selection onto
/// [ChainCardHealth]. It reads the same existence facts the assembly
/// path consumes — the profile list (via [landingProfileExists]) and the
/// target sets of the owning and exit profiles' effective configs (the
/// [ProfileChain.selectionIssue] inputs) — and never throws, so a card
/// renders normally no matter how stale the saved data is.
///
/// This is a display projection only, not a second authority: whether a
/// profile switch succeeds is still decided by the core assembly
/// (core/patch.go patchChainPolicy) and the T150 notice chain. The entry
/// existence read here feeds the marker only; per the T150 ruling the
/// Dart side runs no entry pre-check on the switch path.
ChainCardHealth chainCardHealth({
  required ProfileChain chain,
  required String currentProfileId,
  required bool landingProfileExists,
  required Set<String> entryTargets,
  required Set<String> landingTargets,
}) {
  if (!chain.enabled) return ChainCardHealth.notEnabled;
  final landingProfileId = chain.resolvedLandingProfileId(currentProfileId);
  if (landingProfileId == currentProfileId) return ChainCardHealth.stale;
  if (!landingProfileExists) return ChainCardHealth.stale;
  final issue = chain.selectionIssue(
    currentProfileId: currentProfileId,
    entryTargets: entryTargets,
    landingTargets: landingTargets,
  );
  return issue == null ? ChainCardHealth.healthy : ChainCardHealth.stale;
}
