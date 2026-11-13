import 'dart:io';

import 'package:bett_box/common/print.dart';
import 'package:path/path.dart' as p;

/// Reconciles on-disk profile storage with the profile records
/// (T111 E-02/E-03). Import flows write the profile file before
/// the record is persisted, so an interrupted import (process
/// kill, crash, a failed follow-up step) leaves a yaml that no
/// profile card will ever reference; interrupted atomic writes
/// leave `*.tmp` residue behind (profile writes, and the
/// config.json mirror in Preferences.saveConfig). At startup no
/// write is in flight, so both classes are safe to remove.
/// Conservative by construction: only yaml files inside the
/// profiles directory whose id has no record, temp files there,
/// and config.json temp siblings in the data directory are
/// touched — subdirectories (rule providers) and every other
/// file are left alone.
Future<int> reconcileProfileStorage({
  required String profilesPath,
  required String configPath,
  required Set<String> knownProfileIds,
}) async {
  var removed = 0;
  Future<void> removeQuietly(File entity) async {
    try {
      await entity.delete();
      removed++;
    } catch (_) {}
  }

  final profilesDir = Directory(profilesPath);
  if (await profilesDir.exists()) {
    await for (final entity in profilesDir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.endsWith('.tmp')) {
        await removeQuietly(entity);
        continue;
      }
      if (name.endsWith('.yaml') || name.endsWith('.yml')) {
        final extension = p.extension(name);
        final id = name.substring(0, name.length - extension.length);
        if (!knownProfileIds.contains(id)) {
          await removeQuietly(entity);
        }
      }
    }
  }
  final configDir = Directory(p.dirname(configPath));
  if (await configDir.exists()) {
    await for (final entity in configDir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('config.json.') && name.endsWith('.tmp')) {
        await removeQuietly(entity);
      }
    }
  }
  if (removed > 0) {
    commonPrint.log('Reconciled storage: removed $removed orphan file(s)');
  }
  return removed;
}
