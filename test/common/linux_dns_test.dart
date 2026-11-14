import 'dart:convert';
import 'dart:io';

import 'package:bett_box/common/linux_dns.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stateful fake of the nmcli / resolvectl environment. [dns] is the
/// effective DNS list of the default device; DHCP would hand out [dhcpDns].
class FakeEnv {
  static const hijack = '223.5.5.5';
  static const dhcpDns = ['192.168.1.1'];

  List<String> dns = List.of(dhcpDns);
  final List<List<String>> calls = [];

  bool nmcliMissing = false;
  bool modifyFails = false;
  bool modifyNoEffect = false;

  /// Simulates the NM+iwd failure mode: clearing the runtime DNS override
  /// reports success but the override survives; only a connection
  /// reactivation (fresh DHCP) removes it.
  bool clearIneffective = false;
  bool reactivateFails = false;
  bool resolvectlSetFails = false;

  Future<ProcessResult?> run(String executable, List<String> args) async {
    calls.add([executable, ...args]);
    switch (executable) {
      case 'ip':
        return ProcessResult(
          0,
          0,
          'default via 192.168.1.1 dev wlan0 proto dhcp metric 600\n',
          '',
        );
      case 'nmcli':
        if (nmcliMissing) return null;
        if (args.contains('IP4.DNS')) {
          return ProcessResult(0, 0, dns.join('\n'), '');
        }
        if (args.contains('GENERAL.CONNECTION')) {
          return ProcessResult(0, 0, 'MyWifi\n', '');
        }
        if (args[0] == 'device' && args[1] == 'modify') {
          if (modifyFails) return ProcessResult(0, 1, '', 'modify failed');
          if (!modifyNoEffect) {
            final value = args.last;
            if (value.isEmpty) {
              if (!clearIneffective) dns = List.of(dhcpDns);
            } else {
              dns = [value];
            }
          }
          return ProcessResult(0, 0, '', '');
        }
        if (args[0] == 'connection' && args[1] == 'up') {
          if (reactivateFails) {
            return ProcessResult(0, 1, '', 'activation failed');
          }
          dns = List.of(dhcpDns);
          return ProcessResult(0, 0, '', '');
        }
        return ProcessResult(0, 0, '', '');
      case 'resolvectl':
        if (args[0] == 'dns' && args.length == 2) {
          return ProcessResult(0, 0, 'Link 2 (wlan0): ${dns.join(' ')}\n', '');
        }
        if (args[0] == 'dns' && args.length == 3) {
          if (resolvectlSetFails) {
            return ProcessResult(0, 1, '', 'polkit: not authorized');
          }
          dns = [args[2]];
          return ProcessResult(0, 0, '', '');
        }
        if (args[0] == 'revert') {
          dns = List.of(dhcpDns);
          return ProcessResult(0, 0, '', '');
        }
        return ProcessResult(0, 0, '', '');
      default:
        return ProcessResult(0, 0, '', '');
    }
  }

  bool get usedReapply => calls.any((c) => c.contains('reapply'));

  bool calledWith(List<String> prefix) {
    return calls.any(
      (c) =>
          c.length >= prefix.length &&
          List.generate(
            prefix.length,
            (i) => c[i] == prefix[i],
          ).every((e) => e),
    );
  }
}

class MemoryBackupStore {
  String? content;

  LinuxDnsBackupStore get store => LinuxDnsBackupStore(
    read: () async => content,
    write: (value) async => content = value,
    delete: () async => content = null,
  );
}

void main() {
  late FakeEnv env;
  late MemoryBackupStore backups;
  var stub = false;

  LinuxDnsManager manager() => LinuxDnsManager(
    run: env.run,
    store: backups.store,
    usesResolvedStub: () async => stub,
  );

  setUp(() {
    env = FakeEnv();
    backups = MemoryBackupStore();
    stub = false;
  });

  group('parsers', () {
    test('parseDnsServers handles nmcli and resolvectl layouts', () {
      expect(parseDnsServers('192.168.1.1\n223.5.5.5\n'), [
        '192.168.1.1',
        '223.5.5.5',
      ]);
      expect(parseDnsServers('Link 2 (wlan0): 223.5.5.5'), ['223.5.5.5']);
      expect(parseDnsServers(''), isEmpty);
    });

    test('parseDefaultRouteDevice', () {
      expect(
        parseDefaultRouteDevice(
          'default via 192.168.1.1 dev wlan0 proto dhcp metric 600',
        ),
        'wlan0',
      );
      expect(parseDefaultRouteDevice('unreachable'), isNull);
    });

    test('resolvConfUsesStub', () {
      expect(resolvConfUsesStub('nameserver 127.0.0.53\n'), isTrue);
      expect(resolvConfUsesStub('nameserver 192.168.1.1\n'), isFalse);
    });

    test('backup round-trips and legacy backups still parse', () {
      const backup = LinuxDnsBackup(
        device: 'wlan0',
        connection: 'MyWifi',
        backend: LinuxDnsBackend.nmcli,
        dnsBefore: ['192.168.1.1'],
      );
      final parsed = LinuxDnsBackup.fromJson(
        jsonDecode(jsonEncode(backup.toJson())),
      );
      expect(parsed?.device, 'wlan0');
      expect(parsed?.connection, 'MyWifi');
      expect(parsed?.backend, LinuxDnsBackend.nmcli);
      expect(parsed?.dnsBefore, ['192.168.1.1']);

      final legacy = LinuxDnsBackup.fromJson({'device': 'eth0'});
      expect(legacy?.device, 'eth0');
      expect(legacy?.backend, isNull);
      expect(LinuxDnsBackup.fromJson({'nope': 1}), isNull);
      expect(LinuxDnsBackup.fromJson('junk'), isNull);
    });
  });

  group('command construction', () {
    test('restore never uses device reapply (Bettbox #598 regression)', () {
      expect(nmcliClearDnsArgs('wlan0'), [
        'device',
        'modify',
        'wlan0',
        'ipv4.dns',
        '',
      ]);
      final all = [
        nmcliSetDnsArgs('wlan0', FakeEnv.hijack),
        nmcliClearDnsArgs('wlan0'),
        nmcliReactivateArgs('MyWifi'),
        nmcliShowDnsArgs('wlan0'),
        ...resolvectlSetArgs('wlan0', FakeEnv.hijack),
        resolvectlRevertArgs('wlan0'),
      ];
      for (final args in all) {
        expect(args, isNot(contains('reapply')));
      }
    });
  });

  group('nmcli backend', () {
    test('set applies and verifies, backup captures previous DNS', () async {
      final result = await manager().update(restore: false);
      expect(result.status, LinuxDnsStatus.applied);
      expect(env.dns, [FakeEnv.hijack]);
      final backup = LinuxDnsBackup.fromJson(jsonDecode(backups.content!));
      expect(backup?.dnsBefore, FakeEnv.dhcpDns);
      expect(backup?.connection, 'MyWifi');
      expect(env.usedReapply, isFalse);
    });

    test('set command failure rolls back and deletes the backup', () async {
      env.modifyFails = true;
      final result = await manager().update(restore: false);
      expect(result.status, LinuxDnsStatus.failed);
      expect(result.failure, LinuxDnsFailure.setFailedRestored);
      expect(env.dns, FakeEnv.dhcpDns);
      expect(backups.content, isNull);
    });

    test('set that silently does not take effect is rolled back', () async {
      env.modifyNoEffect = true;
      final result = await manager().update(restore: false);
      expect(result.status, LinuxDnsStatus.failed);
      expect(result.failure, LinuxDnsFailure.setFailedRestored);
      expect(backups.content, isNull);
    });

    test('restore clears the override and deletes the backup', () async {
      env.dns = [FakeEnv.hijack];
      backups.content = jsonEncode(
        const LinuxDnsBackup(
          device: 'wlan0',
          connection: 'MyWifi',
          backend: LinuxDnsBackend.nmcli,
          dnsBefore: FakeEnv.dhcpDns,
        ).toJson(),
      );
      final result = await manager().update(restore: true);
      expect(result.status, LinuxDnsStatus.restored);
      expect(env.dns, FakeEnv.dhcpDns);
      expect(backups.content, isNull);
      expect(env.usedReapply, isFalse);
    });

    test('restore escalates to connection reactivation when the clear is '
        'ineffective (NM+iwd mode)', () async {
      env.dns = [FakeEnv.hijack];
      env.clearIneffective = true;
      backups.content = jsonEncode(
        const LinuxDnsBackup(
          device: 'wlan0',
          connection: 'MyWifi',
          backend: LinuxDnsBackend.nmcli,
        ).toJson(),
      );
      final result = await manager().update(restore: true);
      expect(result.status, LinuxDnsStatus.restored);
      expect(env.dns, FakeEnv.dhcpDns);
      expect(env.calledWith(['nmcli', 'connection', 'up', 'MyWifi']), isTrue);
      expect(backups.content, isNull);
    });

    test('restore keeps the backup when every removal path fails', () async {
      env.dns = [FakeEnv.hijack];
      env.clearIneffective = true;
      env.reactivateFails = true;
      backups.content = jsonEncode(
        const LinuxDnsBackup(
          device: 'wlan0',
          connection: 'MyWifi',
          backend: LinuxDnsBackend.nmcli,
        ).toJson(),
      );
      final result = await manager().update(restore: true);
      expect(result.status, LinuxDnsStatus.failed);
      expect(result.failure, LinuxDnsFailure.restoreFailed);
      expect(backups.content, isNotNull);
    });

    test('legacy device-only backup restores through the safe path', () async {
      env.dns = [FakeEnv.hijack];
      backups.content = jsonEncode({'device': 'wlan0'});
      final result = await manager().update(restore: true);
      expect(result.status, LinuxDnsStatus.restored);
      expect(env.dns, FakeEnv.dhcpDns);
      expect(env.usedReapply, isFalse);
    });

    test('a stuck hijack blocks a fresh set instead of stacking', () async {
      env.dns = [FakeEnv.hijack];
      env.clearIneffective = true;
      env.reactivateFails = true;
      backups.content = jsonEncode({'device': 'wlan0'});
      final callsBefore = env.calls.length;
      final result = await manager().update(restore: false);
      expect(result.failure, LinuxDnsFailure.restoreFailed);
      final newCalls = env.calls.sublist(callsBefore);
      expect(
        newCalls.any((c) => c.contains('modify') && c.last == FakeEnv.hijack),
        isFalse,
      );
    });

    test('missing nmcli reports unavailable and changes nothing', () async {
      env.nmcliMissing = true;
      final result = await manager().update(restore: false);
      expect(result.status, LinuxDnsStatus.unavailable);
      expect(backups.content, isNull);
    });
  });

  group('resolvectl backend', () {
    setUp(() => stub = true);

    test('set applies via resolvectl and verifies by read-back', () async {
      final result = await manager().update(restore: false);
      expect(result.status, LinuxDnsStatus.applied);
      expect(env.dns, [FakeEnv.hijack]);
      expect(
        env.calledWith(['resolvectl', 'dns', 'wlan0', FakeEnv.hijack]),
        isTrue,
      );
      expect(env.calledWith(['resolvectl', 'domain', 'wlan0', '~.']), isTrue);
    });

    test(
      'a resolvectl failure (polkit) is not swallowed: revert + report',
      () async {
        env.resolvectlSetFails = true;
        final result = await manager().update(restore: false);
        expect(result.status, LinuxDnsStatus.failed);
        expect(result.failure, LinuxDnsFailure.setFailedRestored);
        expect(env.calledWith(['resolvectl', 'revert', 'wlan0']), isTrue);
        expect(env.dns, FakeEnv.dhcpDns);
        expect(backups.content, isNull);
      },
    );

    test('restore reverts the link and verifies', () async {
      env.dns = [FakeEnv.hijack];
      backups.content = jsonEncode(
        const LinuxDnsBackup(
          device: 'wlan0',
          backend: LinuxDnsBackend.resolvectl,
        ).toJson(),
      );
      final result = await manager().update(restore: true);
      expect(result.status, LinuxDnsStatus.restored);
      expect(env.dns, FakeEnv.dhcpDns);
      expect(backups.content, isNull);
    });
  });
}
