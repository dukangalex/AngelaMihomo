import 'dart:convert';
import 'dart:io';

/// Linux "automatically set system DNS" management with a closed loop of
/// set -> read-back verification -> rollback on failure.
///
/// This replaces the previous nmcli implementation whose restore path used a
/// bare `nmcli device reapply`. On NetworkManager + iwd links reapply does
/// not re-run DHCP, so it wiped the DHCP-provided DNS servers (and the
/// resolved default-route flag) and left the whole machine without name
/// resolution until NetworkManager was restarted (Bettbox issue #598).
///
/// Design rules:
/// - The previous state is captured *before* anything is changed, and the
///   backup is only deleted after a restore has been verified by reading the
///   effective DNS back. A failed restore keeps the backup so the next
///   launch retries instead of silently losing the user's settings.
/// - Restore never uses `device reapply`. It clears the runtime DNS override
///   with `device modify ... ipv4.dns ""` (the runtime lease state stays
///   intact) and only escalates to reactivating the connection (which does
///   re-run DHCP) when the override survives the clear.
/// - When systemd-resolved owns resolution (stub resolv.conf), the
///   resolvectl path is used and every command's exit code is checked and
///   the result read back, so a resolvectl failure can no longer be
///   swallowed silently (cf. mihomo issue #3419).
/// - Nothing here throws: every outcome is reported as a [LinuxDnsResult]
///   so the UI layer can give the user explicit feedback on failure.
///
/// All command construction, output parsing and rollback decisions live in
/// this file and are unit-testable through the injected [LinuxDnsRunner].
typedef LinuxDnsRunner =
    Future<ProcessResult?> Function(String executable, List<String> arguments);

enum LinuxDnsBackend { nmcli, resolvectl }

enum LinuxDnsStatus {
  /// The hijack DNS was set and verified by read-back.
  applied,

  /// A previous hijack was removed and verified by read-back.
  restored,

  /// Nothing to do (no backup to restore, or DNS already in target state).
  unchanged,

  /// The environment cannot apply the feature at all (e.g. nmcli or
  /// resolvectl missing). Logged only; not surfaced as a user-facing error.
  unavailable,

  /// Something was attempted and failed. See [LinuxDnsResult.failure].
  failed,
}

enum LinuxDnsFailure {
  none,

  /// Setting the DNS failed, but the previous state was verified intact.
  setFailedRestored,

  /// Setting the DNS failed and rolling back could not remove the hijack
  /// DNS either. The backup is kept so a later restore can retry.
  setFailedRestoreFailed,

  /// Restoring the previous DNS failed. The backup is kept for a retry on
  /// the next launch.
  restoreFailed,
}

class LinuxDnsResult {
  final LinuxDnsStatus status;
  final LinuxDnsFailure failure;
  final String? detail;

  const LinuxDnsResult(
    this.status, {
    this.failure = LinuxDnsFailure.none,
    this.detail,
  });

  bool get isFailure => status == LinuxDnsStatus.failed;

  @override
  String toString() =>
      'LinuxDnsResult($status, failure: $failure, detail: $detail)';
}

/// The state captured before the hijack DNS is applied. Backups written by
/// older versions only contain `device`; every other field is optional so
/// those backups still restore (via the safe path, never reapply).
class LinuxDnsBackup {
  final String device;
  final String? connection;
  final LinuxDnsBackend? backend;
  final List<String> dnsBefore;

  const LinuxDnsBackup({
    required this.device,
    this.connection,
    this.backend,
    this.dnsBefore = const [],
  });

  Map<String, dynamic> toJson() => {
    'device': device,
    if (connection != null) 'connection': connection,
    if (backend != null) 'backend': backend!.name,
    'dnsBefore': dnsBefore,
  };

  static LinuxDnsBackup? fromJson(Object? decoded) {
    if (decoded is! Map) return null;
    final device = decoded['device'];
    if (device is! String || device.isEmpty) return null;
    final backendName = decoded['backend'];
    return LinuxDnsBackup(
      device: device,
      connection: decoded['connection'] is String
          ? decoded['connection'] as String
          : null,
      backend: LinuxDnsBackend.values
          .where((b) => b.name == backendName)
          .firstOrNull,
      dnsBefore:
          (decoded['dnsBefore'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }
}

/// Storage hooks for the backup record, abstracted for tests.
class LinuxDnsBackupStore {
  final Future<String?> Function() read;
  final Future<void> Function(String content) write;
  final Future<void> Function() delete;

  const LinuxDnsBackupStore({
    required this.read,
    required this.write,
    required this.delete,
  });
}

final _ipv4Pattern = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');

/// Extracts IPv4 addresses from nmcli / resolvectl output. Both tools print
/// DNS server lists in several layouts (one per line, space separated,
/// prefixed with link descriptions); tokenising on IPv4 shape is stable
/// across all of them and is all the verification predicates need.
List<String> parseDnsServers(String output) {
  return _ipv4Pattern.allMatches(output).map((m) => m.group(0)!).toList();
}

bool dnsOutputContains(String output, String server) =>
    parseDnsServers(output).contains(server);

/// Parses the device carrying the default route from `ip route show
/// default` output.
String? parseDefaultRouteDevice(String output) {
  return RegExp(r'\bdev\s+(\S+)').firstMatch(output)?.group(1);
}

/// Whether resolv.conf points at the systemd-resolved stub listener.
bool resolvConfUsesStub(String content) {
  return RegExp(
    r'^\s*nameserver\s+127\.0\.0\.53\b',
    multiLine: true,
  ).hasMatch(content);
}

// --- Command construction (pure) ---

List<String> nmcliShowDnsArgs(String device) => [
  '-g',
  'IP4.DNS',
  'device',
  'show',
  device,
];

List<String> nmcliConnectionNameArgs(String device) => [
  '-t',
  '-g',
  'GENERAL.CONNECTION',
  'device',
  'show',
  device,
];

List<String> nmcliSetDnsArgs(String device, String dns) => [
  'device',
  'modify',
  device,
  'ipv4.dns',
  dns,
];

/// Clearing the runtime override is the safe inverse of [nmcliSetDnsArgs]:
/// unlike `device reapply` it does not touch the DHCP lease state.
List<String> nmcliClearDnsArgs(String device) => [
  'device',
  'modify',
  device,
  'ipv4.dns',
  '',
];

List<String> nmcliReactivateArgs(String connection) => [
  'connection',
  'up',
  connection,
];

List<String> resolvectlShowDnsArgs(String device) => ['dns', device];

List<List<String>> resolvectlSetArgs(String device, String dns) => [
  ['dns', device, dns],
  ['domain', device, '~.'],
  ['default-route', device, 'true'],
];

List<String> resolvectlRevertArgs(String device) => ['revert', device];

class LinuxDnsManager {
  final LinuxDnsRunner _run;
  final LinuxDnsBackupStore _store;
  final Future<bool> Function() _usesResolvedStub;
  final void Function(String message)? _warn;
  final String hijackDns;

  LinuxDnsManager({
    required LinuxDnsRunner run,
    required LinuxDnsBackupStore store,
    required Future<bool> Function() usesResolvedStub,
    void Function(String message)? warn,
    this.hijackDns = '223.5.5.5',
  }) : _run = run,
       _store = store,
       _usesResolvedStub = usesResolvedStub,
       _warn = warn;

  void _log(String message) => _warn?.call(message);

  /// Serialized by the caller's lock. When [restore] is false this first
  /// restores any leftover managed state (so repeated enables never capture
  /// the app's own hijack as the "original" DNS), then applies the hijack.
  Future<LinuxDnsResult> update({required bool restore}) async {
    final restoreResult = await _restoreInternal();
    if (restore) return restoreResult;
    if (restoreResult.isFailure) {
      // A stuck hijack from an earlier session could not be removed; do not
      // stack a fresh capture on top of it.
      return restoreResult;
    }
    return _setInternal();
  }

  Future<LinuxDnsResult> _restoreInternal() async {
    final String? raw;
    try {
      raw = await _store.read();
    } catch (e) {
      _log('Failed to read Linux system DNS backup: $e');
      return const LinuxDnsResult(LinuxDnsStatus.unchanged);
    }
    if (raw == null) return const LinuxDnsResult(LinuxDnsStatus.unchanged);
    final LinuxDnsBackup? backup;
    try {
      backup = LinuxDnsBackup.fromJson(jsonDecode(raw));
    } catch (e) {
      _log('Failed to decode Linux system DNS backup: $e');
      await _store.delete();
      return const LinuxDnsResult(LinuxDnsStatus.unchanged);
    }
    if (backup == null) {
      await _store.delete();
      return const LinuxDnsResult(LinuxDnsStatus.unchanged);
    }
    final backend =
        backup.backend ??
        (await _usesResolvedStub()
            ? LinuxDnsBackend.resolvectl
            : LinuxDnsBackend.nmcli);
    final removed = backend == LinuxDnsBackend.resolvectl
        ? await _resolvectlRemove(backup.device)
        : await _nmcliRemove(backup);
    if (removed) {
      await _store.delete();
      return const LinuxDnsResult(LinuxDnsStatus.restored);
    }
    // Keep the backup: the next launch retries the restore instead of the
    // user silently losing their original DNS for good.
    return const LinuxDnsResult(
      LinuxDnsStatus.failed,
      failure: LinuxDnsFailure.restoreFailed,
      detail: 'hijack DNS still effective after restore attempt',
    );
  }

  /// Removes the hijack DNS via nmcli and verifies by read-back. Returns
  /// true only when the hijack DNS is confirmed gone.
  Future<bool> _nmcliRemove(LinuxDnsBackup backup) async {
    final device = backup.device;
    final clear = await _run('nmcli', nmcliClearDnsArgs(device));
    if (clear == null) return false;
    if (clear.exitCode != 0) {
      _log(
        'Failed to clear Linux system DNS: ${clear.stderr.toString().trim()}',
      );
    }
    if (!await _nmcliHijackActive(device)) return true;
    // The runtime override survived the clear (the iwd failure mode):
    // escalate to reactivating the connection, which re-runs DHCP.
    final connection = backup.connection ?? await _nmcliConnection(device);
    if (connection == null || connection.isEmpty) return false;
    final up = await _run('nmcli', nmcliReactivateArgs(connection));
    if (up == null || up.exitCode != 0) {
      _log(
        'Failed to reactivate connection while restoring DNS: '
        '${up?.stderr.toString().trim()}',
      );
      return false;
    }
    return !await _nmcliHijackActive(device);
  }

  Future<bool> _resolvectlRemove(String device) async {
    final revert = await _run('resolvectl', resolvectlRevertArgs(device));
    if (revert == null) return false;
    if (revert.exitCode != 0) {
      _log(
        'Failed to revert resolvectl DNS: ${revert.stderr.toString().trim()}',
      );
    }
    final read = await _run('resolvectl', resolvectlShowDnsArgs(device));
    if (read == null || read.exitCode != 0) return false;
    return !dnsOutputContains(read.stdout.toString(), hijackDns);
  }

  Future<LinuxDnsResult> _setInternal() async {
    final routeResult = await _run('ip', ['route', 'show', 'default']);
    if (routeResult == null || routeResult.exitCode != 0) {
      return const LinuxDnsResult(LinuxDnsStatus.unavailable);
    }
    final device = parseDefaultRouteDevice(routeResult.stdout.toString());
    if (device == null) {
      return const LinuxDnsResult(LinuxDnsStatus.unavailable);
    }
    final backend = await _usesResolvedStub()
        ? LinuxDnsBackend.resolvectl
        : LinuxDnsBackend.nmcli;
    return backend == LinuxDnsBackend.resolvectl
        ? _setViaResolvectl(device)
        : _setViaNmcli(device);
  }

  Future<LinuxDnsResult> _setViaNmcli(String device) async {
    // Probe first: if nmcli cannot even report the current DNS, the feature
    // cannot be applied in this environment (e.g. NetworkManager absent).
    final probe = await _run('nmcli', nmcliShowDnsArgs(device));
    if (probe == null || probe.exitCode != 0) {
      return const LinuxDnsResult(LinuxDnsStatus.unavailable);
    }
    final before = parseDnsServers(probe.stdout.toString());
    if (before.contains(hijackDns)) {
      // Already in the target state but not set by us in this session
      // (update() restores managed state first): leave it alone.
      return const LinuxDnsResult(LinuxDnsStatus.unchanged);
    }
    final connection = await _nmcliConnection(device);
    if (!await _writeBackup(
      LinuxDnsBackup(
        device: device,
        connection: connection,
        backend: LinuxDnsBackend.nmcli,
        dnsBefore: before,
      ),
    )) {
      return const LinuxDnsResult(
        LinuxDnsStatus.failed,
        failure: LinuxDnsFailure.setFailedRestored,
        detail: 'could not persist the DNS backup; nothing was changed',
      );
    }
    final set = await _run('nmcli', nmcliSetDnsArgs(device, hijackDns));
    final applied =
        set != null && set.exitCode == 0 && await _nmcliHijackActive(device);
    if (applied) return const LinuxDnsResult(LinuxDnsStatus.applied);
    if (set != null && set.exitCode != 0) {
      _log('Failed to set Linux system DNS: ${set.stderr.toString().trim()}');
    }
    return _rollbackAfterFailedSet(
      device: device,
      remove: () =>
          _nmcliRemove(LinuxDnsBackup(device: device, connection: connection)),
    );
  }

  Future<LinuxDnsResult> _setViaResolvectl(String device) async {
    final probe = await _run('resolvectl', resolvectlShowDnsArgs(device));
    if (probe == null || probe.exitCode != 0) {
      // resolved is not actually managing this link (or resolvectl is
      // missing): the feature cannot be applied here.
      return const LinuxDnsResult(LinuxDnsStatus.unavailable);
    }
    final before = parseDnsServers(probe.stdout.toString());
    if (before.contains(hijackDns)) {
      return const LinuxDnsResult(LinuxDnsStatus.unchanged);
    }
    if (!await _writeBackup(
      LinuxDnsBackup(
        device: device,
        backend: LinuxDnsBackend.resolvectl,
        dnsBefore: before,
      ),
    )) {
      return const LinuxDnsResult(
        LinuxDnsStatus.failed,
        failure: LinuxDnsFailure.setFailedRestored,
        detail: 'could not persist the DNS backup; nothing was changed',
      );
    }
    var commandsOk = true;
    for (final args in resolvectlSetArgs(device, hijackDns)) {
      final result = await _run('resolvectl', args);
      if (result == null || result.exitCode != 0) {
        commandsOk = false;
        _log(
          'Failed to run resolvectl ${args.first}: '
          '${result?.stderr.toString().trim()}',
        );
        break;
      }
    }
    final read = await _run('resolvectl', resolvectlShowDnsArgs(device));
    final applied =
        commandsOk &&
        read != null &&
        read.exitCode == 0 &&
        dnsOutputContains(read.stdout.toString(), hijackDns);
    if (applied) return const LinuxDnsResult(LinuxDnsStatus.applied);
    return _rollbackAfterFailedSet(
      device: device,
      remove: () => _resolvectlRemove(device),
    );
  }

  /// After a failed set, try to put the previous state back and report
  /// honestly whether that worked.
  Future<LinuxDnsResult> _rollbackAfterFailedSet({
    required String device,
    required Future<bool> Function() remove,
  }) async {
    if (await remove()) {
      await _store.delete();
      return const LinuxDnsResult(
        LinuxDnsStatus.failed,
        failure: LinuxDnsFailure.setFailedRestored,
        detail: 'set failed; previous DNS verified intact',
      );
    }
    // Keep the backup so the next restore attempt can retry removing the
    // hijack instead of orphaning it.
    return const LinuxDnsResult(
      LinuxDnsStatus.failed,
      failure: LinuxDnsFailure.setFailedRestoreFailed,
      detail: 'set failed and rollback could not remove the hijack DNS',
    );
  }

  /// The backup must exist before any system state is touched; if it
  /// cannot be persisted the set is aborted with nothing changed.
  Future<bool> _writeBackup(LinuxDnsBackup backup) async {
    try {
      await _store.write(jsonEncode(backup.toJson()));
      return true;
    } catch (e) {
      _log('Failed to persist the Linux system DNS backup: $e');
      return false;
    }
  }

  Future<bool> _nmcliHijackActive(String device) async {
    final read = await _run('nmcli', nmcliShowDnsArgs(device));
    if (read == null || read.exitCode != 0) return false;
    return dnsOutputContains(read.stdout.toString(), hijackDns);
  }

  Future<String?> _nmcliConnection(String device) async {
    final result = await _run('nmcli', nmcliConnectionNameArgs(device));
    if (result == null || result.exitCode != 0) return null;
    final name = result.stdout.toString().trim();
    return name.isEmpty ? null : name;
  }
}
