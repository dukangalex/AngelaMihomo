import 'dart:convert';

// T88: resilience for the Android service-engine quick/boot start
// sequence (main.dart `_service`).
//
// Audit (hidden_files/t88-background-disconnect-audit.md): when the
// main process is killed by OEM power/memory management in the
// background, the always-on restart path ran this sequence exactly
// once; any failure ended in a silent `vpn.stop()` and the core never
// came back until the user opened the app. The sequence now retries a
// bounded number of times with growing delays, and an exhausted run
// leaves a persistent failure marker in the app-private data dir so
// the next UI launch can surface it in the log instead of failing
// silently.

/// Delays waited *between* attempts of the quick start sequence.
/// Total attempts = delays + 1 = 3.
const List<Duration> quickStartRetryDelays = <Duration>[
  Duration(seconds: 2),
  Duration(seconds: 5),
];

typedef QuickStartSleeper = Future<void> Function(Duration delay);

Future<void> _defaultSleeper(Duration delay) => Future.delayed(delay);

/// Runs [action] until it reports success, retrying after each delay
/// in [delays]. A `true` result means success (including the
/// legitimate "nothing to start" outcome, e.g. no current profile);
/// `false` or a thrown error counts as a failed attempt and triggers
/// [onFailure] (best-effort cleanup of half-started state) before the
/// next attempt. Returns `true` on success; after the last attempt
/// fails, returns `false` without throwing.
Future<bool> runQuickStartWithRetry(
  Future<bool> Function() action, {
  List<Duration> delays = quickStartRetryDelays,
  QuickStartSleeper sleeper = _defaultSleeper,
  Future<void> Function(Object error)? onFailure,
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    Object? failure;
    try {
      if (await action()) return true;
      failure = StateError('quick start attempt $attempt reported failure');
    } catch (e) {
      failure = e;
    }
    if (onFailure != null) {
      try {
        await onFailure(failure);
      } catch (_) {
        // Cleanup is best-effort; never mask the original failure.
      }
    }
    if (attempt > delays.length) return false;
    await sleeper(delays[attempt - 1]);
  }
}

/// Persistent record of an exhausted quick start sequence. Stored as
/// JSON in the app-private data dir (see AppPath.quickStartFailurePath)
/// and consumed once by the UI isolate on the next launch.
class QuickStartFailureMarker {
  const QuickStartFailureMarker({
    required this.time,
    required this.step,
    required this.error,
    required this.attempts,
  });

  /// ISO-8601 timestamp of the final failure.
  final String time;

  /// Name of the sequence step that failed last
  /// (getSetupParams / quickStart / vpnStart / startListener).
  final String step;

  /// Short error summary (core message or exception text).
  final String error;

  /// How many attempts were made in total.
  final int attempts;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'time': time,
    'step': step,
    'error': error,
    'attempts': attempts,
  };

  String encode() => json.encode(toJson());

  static QuickStartFailureMarker? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      final time = decoded['time'];
      final step = decoded['step'];
      final error = decoded['error'];
      final attempts = decoded['attempts'];
      if (time is! String || step is! String || error is! String) {
        return null;
      }
      return QuickStartFailureMarker(
        time: time,
        step: step,
        error: error,
        attempts: attempts is int ? attempts : 0,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'time=$time step=$step attempts=$attempts error=$error';
}
