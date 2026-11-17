import 'dart:async';
import 'dart:io';

import 'package:angelamihomo/models/common.dart' show redactSensitiveText;
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

import 'path.dart';

/// T148: persistent on-device app event log.
///
/// App-level events (core start/stop, profile switches and their failure
/// reasons, config setup failures, profile updates, core restarts) are
/// appended to per-day files under the app data directory. Unlike the
/// in-memory log list — which a profile-switch rollback floods and the
/// switch flow itself resets — these files survive process death and
/// rollback storms, so a failure stays diagnosable after the fact.
///
/// Retention is a rolling three days: day files older than the cutoff
/// (today minus three days) are deleted opportunistically on write.
/// Every line passes through [redactSensitiveText] before it is written;
/// unredacted content never reaches disk. The log never leaves the
/// device except as part of a user-initiated log export.
class AppEventLog {
  AppEventLog({
    Future<Directory> Function()? directoryProvider,
    DateTime Function()? clock,
  }) : _directoryProvider = directoryProvider ?? _defaultDirectory,
       _clock = clock ?? DateTime.now;

  static Future<Directory> _defaultDirectory() async {
    final home = await appPath.homeDirPath;
    return Directory(p.join(home, 'event_logs'));
  }

  final Future<Directory> Function() _directoryProvider;
  final DateTime Function() _clock;
  final Lock _lock = Lock();
  String? _lastCleanupDay;

  static String dayStamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year.toString().padLeft(4, '0')}-${two(time.month)}-${two(time.day)}';
  }

  static File dayFile(Directory dir, DateTime time) =>
      File(p.join(dir.path, 'event-${dayStamp(time)}.log'));

  static final _dayFilePattern = RegExp(
    r'^event-(\d{4})-(\d{2})-(\d{2})\.log$',
  );

  /// Records one event. Fire-and-forget: logging must never break or
  /// block the flow it observes, so errors are swallowed here; tests use
  /// [recordAndFlush] to await the write.
  void record(String category, String message) {
    unawaited(recordAndFlush(category, message).catchError((_) {}));
  }

  Future<void> recordAndFlush(String category, String message) {
    return _lock.synchronized(() async {
      final now = _clock();
      final dir = await _directoryProvider();
      await dir.create(recursive: true);
      final safe = redactSensitiveText(message).replaceAll('\n', ' ');
      final line = '${now.toIso8601String()} [$category] $safe\n';
      await dayFile(
        dir,
        now,
      ).writeAsString(line, mode: FileMode.append, flush: true);
      final today = dayStamp(now);
      if (_lastCleanupDay != today) {
        _lastCleanupDay = today;
        await cleanupExpired(dir, now);
      }
    });
  }

  /// Deletes day files outside the rolling three-day retention window.
  static Future<void> cleanupExpired(Directory dir, DateTime now) async {
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 3));
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final match = _dayFilePattern.firstMatch(p.basename(entity.path));
      if (match == null) continue;
      final date = DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
      if (date.isBefore(cutoff)) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  /// All retained event lines, oldest day first, for log export.
  Future<String> readAllRetained() {
    return _lock.synchronized(() async {
      final dir = await _directoryProvider();
      if (!await dir.exists()) return '';
      final files = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File &&
            _dayFilePattern.hasMatch(p.basename(entity.path))) {
          files.add(entity);
        }
      }
      files.sort((a, b) => a.path.compareTo(b.path));
      final buffer = StringBuffer();
      for (final file in files) {
        try {
          buffer.write(await file.readAsString());
        } catch (_) {}
      }
      return buffer.toString();
    });
  }
}

final appEventLog = AppEventLog();
