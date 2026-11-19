import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/common.dart' show Log;
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

import 'event_log.dart';
import 'path.dart';

/// T263: persistent on-device runtime (core) log store — the app's
/// flight recorder.
///
/// The in-memory log list used to be the only home of core runtime
/// logs, and the profile-switch flow reset it, so the run-up to a
/// failure vanished exactly when it was needed. This store appends
/// every flushed batch of [Log] entries to per-day files in the same
/// `event_logs` directory as [AppEventLog] (prefix `runtime-`, so the
/// two never interfere), and the app seeds the in-memory list back
/// from it on startup.
///
/// Black-box discipline: each batch is written with `flush: true`,
/// so once a batch lands it survives the process being killed — at
/// most the one throttled batch still in flight (300 ms) can be
/// lost. Entries reach this store only after [Log.core]/[Log.app]
/// have redacted them, so unredacted content never reaches disk.
///
/// Retention mirrors [AppEventLog]: a rolling three days, cleaned up
/// opportunistically on write. A per-day size cap (32 MiB by default)
/// keeps a debug-level log flood from filling the disk; hitting it
/// stops appending for the rest of the day and leaves one event in
/// the [AppEventLog] saying so.
class RuntimeLogStore {
  RuntimeLogStore({
    Future<Directory> Function()? directoryProvider,
    DateTime Function()? clock,
    AppEventLog? eventLog,
    int maxDailyBytes = defaultMaxDailyBytes,
  }) : _directoryProvider = directoryProvider ?? _defaultDirectory,
       _clock = clock ?? DateTime.now,
       _eventLog = eventLog ?? appEventLog,
       _maxDailyBytes = maxDailyBytes;

  static const defaultMaxDailyBytes = 32 * 1024 * 1024;

  /// How often the cached day-file size is recalibrated against the
  /// real file length, in appended batches.
  static const _recalibrateEveryBatches = 100;

  static Future<Directory> _defaultDirectory() async {
    final home = await appPath.homeDirPath;
    return Directory(p.join(home, 'event_logs'));
  }

  final Future<Directory> Function() _directoryProvider;
  final DateTime Function() _clock;
  final AppEventLog _eventLog;
  final int _maxDailyBytes;
  final Lock _lock = Lock();
  String? _lastCleanupDay;

  /// Cached size accounting for the current day file. Recalibrated
  /// from disk on the first batch of a day (the file may already
  /// exist from a previous process run) and every
  /// [_recalibrateEveryBatches] batches after that.
  String? _countedDay;
  int _countedBytes = 0;
  int _batchesSinceCalibration = 0;

  /// Day stamp for which the size cap already fired; appending is
  /// suspended for that day and the truncation event is recorded
  /// only once.
  String? _truncatedDay;

  static File dayFile(Directory dir, DateTime time) =>
      File(p.join(dir.path, 'runtime-${AppEventLog.dayStamp(time)}.log'));

  static final _dayFilePattern = RegExp(
    r'^runtime-(\d{4})-(\d{2})-(\d{2})\.log$',
  );

  static DateTime? _fileDate(String name) {
    final match = _dayFilePattern.firstMatch(name);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  /// One stored line: ISO time, level, source, module, payload,
  /// tab-separated. Payload and module have tabs/newlines flattened
  /// to spaces so a line always stays a single physical line.
  static String formatLine(Log log) {
    final payload = log.payload
        .replaceAll('\n', ' ')
        .replaceAll('\t', ' ')
        .replaceAll('\r', ' ');
    final module = (log.module ?? '')
        .replaceAll('\n', ' ')
        .replaceAll('\t', ' ')
        .replaceAll('\r', ' ');
    return '${log.time.toIso8601String()}\t${log.logLevel.name}'
        '\t${log.source.name}\t$module\t$payload';
  }

  /// Parses one stored line back into a [Log]; null when the line is
  /// not a well-formed record (bad lines are skipped, never fatal).
  /// Unknown level/source names fall back to error/core.
  static Log? parseLine(String line) {
    final parts = line.split('\t');
    if (parts.length < 5) return null;
    final time = DateTime.tryParse(parts[0]);
    if (time == null) return null;
    final level =
        LogLevel.values.asNameMap()[parts[1]] ?? LogLevel.error;
    final source =
        LogSource.values.asNameMap()[parts[2]] ?? LogSource.core;
    final module = parts[3].isEmpty ? null : parts[3];
    return Log(
      logLevel: level,
      payload: parts.sublist(4).join('\t'),
      time: time,
      source: source,
      module: module,
    );
  }

  /// Appends one flushed batch of logs to today's file. The write is
  /// flushed to disk before the future completes; a process kill can
  /// therefore lose at most a batch that has not been flushed yet.
  Future<void> appendBatch(List<Log> logs) {
    if (logs.isEmpty) return Future.value();
    return _lock.synchronized(() async {
      final now = _clock();
      final today = AppEventLog.dayStamp(now);
      final dir = await _directoryProvider();
      await dir.create(recursive: true);
      if (_lastCleanupDay != today) {
        _lastCleanupDay = today;
        await cleanupExpired(dir, now);
      }
      if (_truncatedDay == today) return;
      final file = dayFile(dir, now);
      if (_countedDay != today) {
        _countedDay = today;
        _countedBytes = await _fileLength(file);
        _batchesSinceCalibration = 0;
      } else if (++_batchesSinceCalibration >= _recalibrateEveryBatches) {
        _batchesSinceCalibration = 0;
        _countedBytes = await _fileLength(file);
      }
      final text = '${logs.map(formatLine).join('\n')}\n';
      final bytes = utf8.encode(text).length;
      if (_countedBytes + bytes > _maxDailyBytes) {
        _truncatedDay = today;
        _eventLog.record(
          'log',
          'runtime log for $today reached the '
          '${_maxDailyBytes ~/ (1024 * 1024)} MiB daily cap; further '
          'runtime logs today are kept in memory only',
        );
        return;
      }
      await file.writeAsString(text, mode: FileMode.append, flush: true);
      _countedBytes += bytes;
    });
  }

  static Future<int> _fileLength(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  /// The newest [maxLines] retained entries, oldest first, reading
  /// day files newest-to-oldest down to the retention window edge.
  Future<List<Log>> readTail({int maxLines = 2000}) {
    return _lock.synchronized(() async {
      final dir = await _directoryProvider();
      if (!await dir.exists()) return const [];
      final now = _clock();
      final cutoff = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 3));
      final files = <File>[];
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final date = _fileDate(p.basename(entity.path));
        if (date == null || date.isBefore(cutoff)) continue;
        files.add(entity);
      }
      files.sort((a, b) => b.path.compareTo(a.path));
      final collected = <Log>[];
      for (final file in files) {
        if (collected.length >= maxLines) break;
        List<String> lines;
        try {
          lines = await file.readAsLines();
        } catch (_) {
          continue;
        }
        for (var i = lines.length - 1; i >= 0; i--) {
          if (collected.length >= maxLines) break;
          final log = parseLine(lines[i]);
          if (log != null) collected.add(log);
        }
      }
      return collected.reversed.toList();
    });
  }

  /// Deletes all retained runtime day files (the log page's clear
  /// action), and resets the size accounting with them.
  Future<void> clear() {
    return _lock.synchronized(() async {
      final dir = await _directoryProvider();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File &&
              _dayFilePattern.hasMatch(p.basename(entity.path))) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
      _countedDay = null;
      _countedBytes = 0;
      _batchesSinceCalibration = 0;
      _truncatedDay = null;
    });
  }

  /// Deletes runtime day files outside the rolling three-day
  /// retention window. Same cutoff rule as [AppEventLog]; only
  /// `runtime-` files are touched.
  static Future<void> cleanupExpired(Directory dir, DateTime now) async {
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 3));
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final date = _fileDate(p.basename(entity.path));
      if (date == null) continue;
      if (date.isBefore(cutoff)) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }
}

final runtimeLogStore = RuntimeLogStore();
