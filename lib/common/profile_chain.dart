import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum ProfileChainIssue {
  incomplete,
  sameNode,
  otherProfileRequired,
  unavailable,
}

enum ChainTargetKind { proxy, group }

String chainTargetKey(ChainTargetKind kind, String name) =>
    '${kind.name}\u0000$name';

/// Health-check floors the bridge raises chain-carrying groups to
/// (core/patch.go floorChainHopHealthCheck: interval ≥ 180 s,
/// tolerance ≥ 200 ms, timeout ≥ 5000 ms, so a two-hop chain does not
/// flap on ordinary link jitter). Mirrored here so the group editor
/// can echo the effective value when a setting sits below the floor
/// instead of the runtime silently diverging from what the user
/// dialed in (T81 C-4).
class ChainHealthFloor {
  final int interval;
  final int tolerance;
  final int timeout;

  const ChainHealthFloor({
    required this.interval,
    required this.tolerance,
    required this.timeout,
  });
}

const chainHopHealthFloor = ChainHealthFloor(
  interval: 180,
  tolerance: 200,
  timeout: 5000,
);

/// The chain health floor applying to [groupName] under [chain], or
/// null when the group carries no chain hop. The bridge floors the
/// entry group of an enabled chain and the exit group when it lives
/// in the same profile (patchChainPolicy in core/patch.go).
ChainHealthFloor? chainHealthFloorForGroup(
  ProfileChain chain, {
  required String currentProfileId,
  required String groupName,
}) {
  if (!chain.enabled) return null;
  if (chain.entryKind == ChainTargetKind.group && chain.entry == groupName) {
    return chainHopHealthFloor;
  }
  if (chain.landingKind == ChainTargetKind.group &&
      chain.landing == groupName &&
      chain.resolvedLandingProfileId(currentProfileId) == currentProfileId) {
    return chainHopHealthFloor;
  }
  return null;
}

/// The value the core will actually run when [value] is configured
/// under a chain floor of [floor]: the bridge raises present values
/// below the floor and leaves absent or higher values untouched.
/// Returns the raised value, or null when the floor changes nothing.
int? chainFlooredValue(int? value, int floor) =>
    value != null && value < floor ? floor : null;

class ProfileChain {
  bool enabled;
  String entry;
  ChainTargetKind entryKind;
  String landing;
  ChainTargetKind landingKind;

  /// Empty means the profile owning this chain (also the legacy v1 default).
  String landingProfileId;

  ProfileChain({
    this.enabled = false,
    this.entry = '',
    this.entryKind = ChainTargetKind.proxy,
    this.landing = '',
    this.landingKind = ChainTargetKind.proxy,
    this.landingProfileId = '',
  });

  String resolvedLandingProfileId(String currentProfileId) =>
      landingProfileId.isEmpty ? currentProfileId : landingProfileId;

  ProfileChain copyWith({
    bool? enabled,
    String? entry,
    ChainTargetKind? entryKind,
    String? landing,
    ChainTargetKind? landingKind,
    String? landingProfileId,
  }) => ProfileChain(
    enabled: enabled ?? this.enabled,
    entry: entry ?? this.entry,
    entryKind: entryKind ?? this.entryKind,
    landing: landing ?? this.landing,
    landingKind: landingKind ?? this.landingKind,
    landingProfileId: landingProfileId ?? this.landingProfileId,
  );

  ProfileChainIssue? selectionIssue({
    required String currentProfileId,
    required Set<String> entryTargets,
    required Set<String> landingTargets,
  }) {
    if (!enabled) return null;
    if (entry.trim().isEmpty || landing.trim().isEmpty) {
      return ProfileChainIssue.incomplete;
    }
    final landingSource = resolvedLandingProfileId(currentProfileId);
    if (landingSource == currentProfileId) {
      return ProfileChainIssue.otherProfileRequired;
    }
    if (!entryTargets.contains(chainTargetKey(entryKind, entry)) ||
        !landingTargets.contains(chainTargetKey(landingKind, landing))) {
      return ProfileChainIssue.unavailable;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'entry': entry,
    'entry-kind': entryKind.name,
    'landing': landing,
    'landing-kind': landingKind.name,
    if (landingProfileId.isNotEmpty) 'landing-profile-id': landingProfileId,
  };

  factory ProfileChain.fromJson(Map<String, dynamic> json) {
    ChainTargetKind parseKind(Object? value) {
      for (final kind in ChainTargetKind.values) {
        if (kind.name == value) return kind;
      }
      return ChainTargetKind.proxy;
    }

    return ProfileChain(
      enabled: json['enabled'] == true,
      entry: (json['entry'] ?? '').toString(),
      entryKind: parseKind(json['entry-kind']),
      landing: (json['landing'] ?? '').toString(),
      landingKind: parseKind(json['landing-kind']),
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
