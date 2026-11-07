import 'dart:convert';
import 'dart:io';

import 'package:bett_box/models/patrol.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live problem count for the patrol navigation badge. Updated by the
/// patrol page after each full report and by the controller's light
/// evaluation (startup, after profile updates).
final patrolAttentionCount = ValueNotifier<int>(0);

/// One recorded repair attempt (T29): what ran, how it ended, and —
/// when the action mutated persistent state — where the pre-action
/// snapshot lives so the user can undo it from the records page.
class PatrolRepairRecord {
  final String id;
  final DateTime at;
  final PatrolAction action;

  /// applied | failedRolledBack | failed | undone
  final String outcome;
  final String detail;

  /// True when the action was a downgrade (kept the service usable
  /// without removing the root cause). Records must say so plainly.
  final bool downgrade;

  /// Path of the pre-action profile file backup, when the action
  /// replaced a profile file. Null for non-mutating actions.
  final String? profileBackupPath;
  final String? profileId;

  const PatrolRepairRecord({
    required this.id,
    required this.at,
    required this.action,
    required this.outcome,
    this.detail = '',
    this.downgrade = false,
    this.profileBackupPath,
    this.profileId,
  });

  PatrolRepairRecord copyWith({String? outcome}) => PatrolRepairRecord(
    id: id,
    at: at,
    action: action,
    outcome: outcome ?? this.outcome,
    detail: detail,
    downgrade: downgrade,
    profileBackupPath: profileBackupPath,
    profileId: profileId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'action': action.name,
    'outcome': outcome,
    'detail': detail,
    'downgrade': downgrade,
    'profileBackupPath': profileBackupPath,
    'profileId': profileId,
  };

  factory PatrolRepairRecord.fromJson(Map<String, dynamic> json) =>
      PatrolRepairRecord(
        id: json['id']?.toString() ?? '',
        at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime(0),
        action: PatrolAction.values.firstWhere(
          (a) => a.name == json['action']?.toString(),
          orElse: () => PatrolAction.testNodes,
        ),
        outcome: json['outcome']?.toString() ?? 'failed',
        detail: json['detail']?.toString() ?? '',
        downgrade: json['downgrade'] == true,
        profileBackupPath: json['profileBackupPath']?.toString(),
        profileId: json['profileId']?.toString(),
      );
}

/// Persistence for patrol state that must survive restarts: profile
/// update failure marks (the report's "last update failed" input) and
/// the repair history. Deliberately a standalone SharedPreferences
/// store — like SystemExplicitStore it is NOT part of the backed-up
/// app config: failure marks and repair history are device-local
/// operational state, not user settings.
class PatrolStore {
  static const _failuresKey = 'patrol.profileUpdateFailures.v1';
  static const _recordsKey = 'patrol.repairRecords.v1';
  static const _maxRecords = 50;

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ---- profile update failure marks ----

  static Future<Map<String, dynamic>> _failureMap() async {
    final raw = (await _prefs).getString(_failuresKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> markUpdateFailed(String profileId, String error) async {
    final map = await _failureMap();
    map[profileId] = {
      'at': DateTime.now().toIso8601String(),
      'error': error,
    };
    await (await _prefs).setString(_failuresKey, jsonEncode(map));
  }

  static Future<void> clearUpdateFailure(String profileId) async {
    final map = await _failureMap();
    if (map.remove(profileId) != null) {
      await (await _prefs).setString(_failuresKey, jsonEncode(map));
    }
  }

  /// The recorded failure for [profileId], or null when the last
  /// update succeeded (or none was ever recorded).
  static Future<({DateTime at, String error})?> updateFailureFor(
    String profileId,
  ) async {
    final entry = (await _failureMap())[profileId];
    if (entry is! Map) return null;
    return (
      at: DateTime.tryParse(entry['at']?.toString() ?? '') ?? DateTime(0),
      error: entry['error']?.toString() ?? '',
    );
  }

  // ---- repair records ----

  static Future<List<PatrolRepairRecord>> records() async {
    final raw = (await _prefs).getString(_recordsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PatrolRepairRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRecord(PatrolRepairRecord record) async {
    final list = await records();
    list.insert(0, record);
    final trimmed = list.take(_maxRecords).toList();
    await (await _prefs).setString(
      _recordsKey,
      jsonEncode(trimmed.map((r) => r.toJson()).toList()),
    );
  }

  static Future<void> updateRecord(PatrolRepairRecord record) async {
    final list = await records();
    final index = list.indexWhere((r) => r.id == record.id);
    if (index < 0) return;
    list[index] = record;
    await (await _prefs).setString(
      _recordsKey,
      jsonEncode(list.map((r) => r.toJson()).toList()),
    );
  }

  // ---- profile file snapshots ----

  /// Copies the profile file at [profileFile] to a timestamped backup
  /// next to it and returns the backup path (null when the source does
  /// not exist — e.g. a profile that was never fetched).
  static Future<String?> snapshotProfileFile(File profileFile) async {
    if (!await profileFile.exists()) return null;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final backup = File('${profileFile.path}.patrolbak-$stamp');
    await profileFile.copy(backup.path);
    return backup.path;
  }

  /// Restores a snapshot taken by [snapshotProfileFile] over the
  /// profile file it came from. Returns false when the backup is gone.
  static Future<bool> restoreProfileSnapshot(
    String backupPath,
    File profileFile,
  ) async {
    final backup = File(backupPath);
    if (!await backup.exists()) return false;
    await backup.copy(profileFile.path);
    return true;
  }
}
