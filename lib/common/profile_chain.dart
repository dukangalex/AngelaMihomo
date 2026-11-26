import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum ProfileChainIssue {
  incomplete,
  sameNode,
  otherProfileRequired,
  unavailable,
}

/// Which end of a saved chain selection can no longer be resolved against
/// the current profile contents. Selections go stale when the referenced
/// profile is re-imported (new id) or updated (renamed groups/nodes).
enum ChainStaleReference { exitProfile, exitTarget, entry, exitSameProfile }

/// Thrown when a saved chain selection points at a profile, group or node
/// that no longer exists. The presentation layer maps this to a dedicated
/// notice that names the stale end and tells the user to reselect the
/// entry/exit in the chain settings (see common/failure_notice.dart).
/// It extends [FormatException] and carries the legacy English wording as
/// its message, so fail-closed checks and event-log lines keep the exact
/// shape they had when these were plain FormatExceptions.
class ChainSelectionStaleException extends FormatException {
  final ChainStaleReference reference;

  const ChainSelectionStaleException(this.reference, String detail)
    : super(detail);
}

enum ChainTargetKind { proxy, group }

String chainTargetKey(ChainTargetKind kind, String name) =>
    '${kind.name}\u0000$name';

/// One chain exit: a node or strategy group taken from another profile.
/// A chain has exactly one exit in effect (T310, superseding the T303
/// multi-exit reading): when the exit is a group, the generated chain
/// landing group lists that group's nodes side by side and the user
/// picks one at runtime on the proxies page.
class ChainLanding {
  /// The profile the exit is taken from. Empty is the legacy v1 shape,
  /// where it meant the profile owning the chain.
  String profileId;
  ChainTargetKind kind;
  String name;

  ChainLanding({
    this.profileId = '',
    this.kind = ChainTargetKind.proxy,
    this.name = '',
  });

  String get key => chainTargetKey(kind, name);

  String resolvedProfileId(String currentProfileId) =>
      profileId.isEmpty ? currentProfileId : profileId;

  ChainLanding copyWith({
    String? profileId,
    ChainTargetKind? kind,
    String? name,
  }) => ChainLanding(
    profileId: profileId ?? this.profileId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
  );

  Map<String, dynamic> toJson() => {
    'profile-id': profileId,
    'kind': kind.name,
    'name': name,
  };

  factory ChainLanding.fromJson(Map<String, dynamic> json) => ChainLanding(
    profileId: (json['profile-id'] ?? '').toString(),
    kind: _parseChainTargetKind(json['kind']),
    name: (json['name'] ?? '').toString(),
  );
}

ChainTargetKind _parseChainTargetKind(Object? value) {
  for (final kind in ChainTargetKind.values) {
    if (kind.name == value) return kind;
  }
  return ChainTargetKind.proxy;
}

class ProfileChain {
  bool enabled;
  String entry;
  ChainTargetKind entryKind;

  /// The stored chain exits. Only the first is in effect (T310); the
  /// list shape is kept so T303-era stored settings still parse, and
  /// the first exit is mirrored into the legacy fields on write, so a
  /// downgrade still sees a working single-exit chain.
  List<ChainLanding> landings;

  ProfileChain({
    this.enabled = false,
    this.entry = '',
    this.entryKind = ChainTargetKind.proxy,
    List<ChainLanding>? landings,
    String landing = '',
    ChainTargetKind landingKind = ChainTargetKind.proxy,
    String landingProfileId = '',
  }) : landings =
           landings ??
           [
             if (landing.isNotEmpty)
               ChainLanding(
                 profileId: landingProfileId,
                 kind: landingKind,
                 name: landing,
               ),
           ];

  /// Legacy single-exit accessors over the first exit.
  String get landing => landings.isEmpty ? '' : landings.first.name;
  ChainTargetKind get landingKind =>
      landings.isEmpty ? ChainTargetKind.proxy : landings.first.kind;

  /// Empty means the profile owning this chain (also the legacy v1 default).
  String get landingProfileId =>
      landings.isEmpty ? '' : landings.first.profileId;

  String resolvedLandingProfileId(String currentProfileId) =>
      landingProfileId.isEmpty ? currentProfileId : landingProfileId;

  ProfileChain copyWith({
    bool? enabled,
    String? entry,
    ChainTargetKind? entryKind,
    List<ChainLanding>? landings,
    String? landing,
    ChainTargetKind? landingKind,
    String? landingProfileId,
  }) {
    var nextLandings = landings ?? List<ChainLanding>.of(this.landings);
    if (landing != null || landingKind != null || landingProfileId != null) {
      final first = nextLandings.isEmpty ? ChainLanding() : nextLandings.first;
      final rewritten = first.copyWith(
        name: landing,
        kind: landingKind,
        profileId: landingProfileId,
      );
      if (nextLandings.isEmpty) {
        if (rewritten.name.isNotEmpty) nextLandings = [rewritten];
      } else {
        nextLandings[0] = rewritten;
      }
    }
    return ProfileChain(
      enabled: enabled ?? this.enabled,
      entry: entry ?? this.entry,
      entryKind: entryKind ?? this.entryKind,
      landings: nextLandings,
    );
  }

  ProfileChainIssue? selectionIssue({
    required String currentProfileId,
    required Set<String> entryTargets,
    required Map<String, Set<String>> landingTargetsByProfile,
  }) {
    if (!enabled) return null;
    // T310: only the first stored landing is in effect; stale extras
    // from the T303 layout must not flag the chain as broken.
    final effective = landings.take(1).toList();
    if (entry.trim().isEmpty ||
        effective.isEmpty ||
        effective.any((landing) => landing.name.trim().isEmpty)) {
      return ProfileChainIssue.incomplete;
    }
    for (final landing in effective) {
      if (landing.resolvedProfileId(currentProfileId) == currentProfileId) {
        return ProfileChainIssue.otherProfileRequired;
      }
    }
    if (!entryTargets.contains(chainTargetKey(entryKind, entry))) {
      return ProfileChainIssue.unavailable;
    }
    for (final landing in effective) {
      final targets =
          landingTargetsByProfile[landing.resolvedProfileId(currentProfileId)];
      if (targets == null || !targets.contains(landing.key)) {
        return ProfileChainIssue.unavailable;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'entry': entry,
    'entry-kind': entryKind.name,
    'landings': [for (final landing in landings) landing.toJson()],
    if (landings.isNotEmpty) ...{
      'landing': landings.first.name,
      'landing-kind': landings.first.kind.name,
      if (landings.first.profileId.isNotEmpty)
        'landing-profile-id': landings.first.profileId,
    },
  };

  factory ProfileChain.fromJson(Map<String, dynamic> json) {
    final rawLandings = json['landings'];
    if (rawLandings is List && rawLandings.isNotEmpty) {
      return ProfileChain(
        enabled: json['enabled'] == true,
        entry: (json['entry'] ?? '').toString(),
        entryKind: _parseChainTargetKind(json['entry-kind']),
        landings: [
          for (final raw in rawLandings)
            if (raw is Map)
              ChainLanding.fromJson(raw.cast<String, dynamic>()),
        ],
      );
    }
    return ProfileChain(
      enabled: json['enabled'] == true,
      entry: (json['entry'] ?? '').toString(),
      entryKind: _parseChainTargetKind(json['entry-kind']),
      landing: (json['landing'] ?? '').toString(),
      landingKind: _parseChainTargetKind(json['landing-kind']),
      landingProfileId: (json['landing-profile-id'] ?? '').toString(),
    );
  }
}

/// Per-profile chain. The subscription file itself is not rewritten.
class ProfileChainStore {
  ProfileChainStore._();

  static final instance = ProfileChainStore._();
  static const _key = 'profile_chain_v1';

  final Map<String, ProfileChain> byProfile = {};
  Future<void>? _loading;

  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  ProfileChain of(String profileId) {
    return byProfile.putIfAbsent(profileId, ProfileChain.new);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        if (value is Map) {
          byProfile[key.toString()] = ProfileChain.fromJson(
            value.cast<String, dynamic>(),
          );
        }
      });
    } catch (_) {}
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _key,
      jsonEncode({
        for (final entry in byProfile.entries) entry.key: entry.value.toJson(),
      }),
    );
    if (!saved) throw StateError('Could not save chain settings');
  }

  /// Note: the config mutation that used to live here is now applied
  /// Go-side in core/patch.go (see patchChainPolicy), because the Dart
  /// full-config hook no longer exists in the typed-patch pipeline.
  /// The original Dart spec is kept in common/explicit_policy.dart
  /// for reference.
}
