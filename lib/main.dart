import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:bett_box/plugins/app.dart';
import 'package:bett_box/plugins/clipboard_ext.dart';
import 'package:bett_box/plugins/tile.dart';
import 'package:bett_box/plugins/vpn.dart';
import 'package:bett_box/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synchronized/synchronized.dart';

import 'application.dart';
import 'clash/core.dart';
import 'clash/lib.dart';
import 'common/common.dart';
import 'common/external_control.dart';
import 'common/network_matcher.dart';
import 'models/models.dart';

ReceivePort? _serviceReceiverPort;
ReceivePort? _messageReceiverPort;

Future<void> main(List<String> args) async {
  globalState.isService = false;
  WidgetsFlutterBinding.ensureInitialized();

  if (system.isDesktop &&
      (args.contains('--exit') || args.contains('--restart'))) {
    final command = args.contains('--exit') ? 'exit' : 'restart';
    await _sendControlCommand(command);
    exit(0);
  }

  if (system.isMacOS || appPath.isPortable) {
    final acquire = await singleInstanceLock.acquire();
    if (!acquire) {
      commonPrint.warn(
        'SingleInstanceLock: another instance detected or lock failed, exiting',
      );
      if (!appPath.isPortable) {
        await _sendControlCommand('show');
        await Future.delayed(const Duration(milliseconds: 100));
      }
      exit(0);
    }
  }

  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

  final version = await system.version;
  await Future.wait([globalState.initApp(version), clashCore.preload()]);

  try {
    await uiManager.initializeUI();
  } catch (e) {
    commonPrint.error('Failed to initialize UI: $e');
  }

  await _runApp();
}

Future<void> _sendControlCommand(String command) async {
  for (int i = 0; i < 5; i++) {
    try {
      await ExternalControl.sendCommand(command);
      commonPrint.log('Sent $command command to running instance');
      return;
    } catch (e) {
      if (i == 4) {
        commonPrint.warn('Failed to send $command command: $e');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}

Future<void> _runApp() async {
  await ensureRustLib();

  if (system.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  await android?.init();

  await window?.init();
  if (system.isWindows) {
    clipboardExt.init();
  }
  HttpOverrides.global = AngelaHttpOverrides();
  runApp(ProviderScope(retry: (_, _) => null, child: const Application()));
}

@pragma('vm:entry-point')
Future<void> _service(List<String> flags) async {
  globalState.isService = true;
  WidgetsFlutterBinding.ensureInitialized();
  await globalState.init();

  {
    final quickStart = flags.contains('quick');
    final bootStart = flags.contains('boot');
    final clashLibHandler = ClashLibHandler();
    final smartAutoStopLock = Lock();

    Future<void> checkSmartAutoStop() async {
      try {
        final vpnProps = globalState.config.vpnProps;
        if (!vpnProps.smartAutoStop) return;
        final networks = vpnProps.smartAutoStopNetworks;
        if (networks.isEmpty) return;

        await smartAutoStopLock.synchronized(() async {
          final isSmartStopped = await vpn?.isSmartStopped() ?? false;
          final candidateIps =
              await vpn?.getLocalIpAddresses() ?? const <String>[];
          final candidateGateways =
              await vpn?.getLocalGateways() ?? const <String>[];
          if (candidateIps.isEmpty && candidateGateways.isEmpty) return;

          final shouldStop =
              candidateIps.any((ip) => NetworkMatcher.matchAny(ip, networks)) ||
              candidateGateways.any(
                (gw) => NetworkMatcher.matchAnyGateway(gw, networks),
              );

          if (shouldStop && !isSmartStopped) {
            final isRunning = await vpn?.getStatus() ?? false;
            if (isRunning) {
              await vpn?.setSmartStopped(true);
              await vpn?.smartStop();
            }
          } else if (!shouldStop && isSmartStopped) {
            await vpn?.setSmartStopped(false);
            await vpn?.smartResume(clashLibHandler.getAndroidVpnOptions());
          }
        });
      } catch (e) {
        commonPrint.warn('Smart auto stop check failed: $e');
      }
    }

    tile?.addListener(
      _TileListenerWithService(
        onStart: () async {
          await app.tip(appLocalizations.startVpn);
          await globalState.handleStart();
        },
        onStop: () async {
          await app.tip(appLocalizations.stopVpn);
          clashLibHandler.stopListener();
          await vpn?.stop();
        },
        onReconnectIpc: () async {
          commonPrint.log(
            'Service: reconnectIpc requested, re-establishing IPC',
          );
          try {
            await _handleMainIpc(clashLibHandler);
          } catch (error, stackTrace) {
            commonPrint.error(
              'Service: failed to re-establish IPC: $error\n$stackTrace',
            );
          }
        },
      ),
    );

    vpn?.addListener(
      _VpnListenerWithService(
        onDnsChanged: (String dns) {
          clashLibHandler.updateDns(dns);
        },
        onNetworkChanged: checkSmartAutoStop,
      ),
    );

    if (!quickStart && !bootStart) {
      await _handleMainIpc(clashLibHandler);
      return;
    }

    if (bootStart && !globalState.config.appSetting.autoRun) {
      commonPrint.log(
        'Silent boot detected, but autoRun is disabled. Staying idle.',
      );
      await _handleMainIpc(clashLibHandler);
      return;
    }

    commonPrint.log('Executing ${bootStart ? "boot" : "quick"} start sequence');
    await ClashCore.initGeo();
    app.tip(appLocalizations.startVpn);
    final homeDirPath = await appPath.homeDirPath;
    final version = await system.version;
    final clashConfig = globalState.config.patchClashConfig.copyWith.tun(
      enable: false,
    );

    Future(() async {
      // T88: the quick/boot sequence is the only self-recovery path
      // after the system kills the main process in the background
      // (always-on restart). It used to run exactly once and fail
      // silently into vpn.stop(); it now retries with growing delays
      // and, if every attempt fails, leaves a persistent marker the
      // UI isolate surfaces on the next launch.
      var step = 'getSetupParams';
      var lastError = '';
      var attempts = 0;
      final ok = await runQuickStartWithRetry(
        () async {
          attempts++;
          step = 'getSetupParams';
          final params = await globalState.getSetupParams(
            pathConfig: clashConfig,
          );
          final profileId = globalState.config.currentProfileId;
          if (profileId == null) {
            // Nothing configured to start: a legitimate outcome,
            // not a failure — do not retry, do not mark.
            return true;
          }
          step = 'quickStart';
          final res = await clashLibHandler.quickStart(
            InitParams(homeDir: homeDirPath, version: version),
            params,
            globalState.getCoreState(),
          );
          final message = res.message;
          debugPrint(message);
          if (message.isNotEmpty) {
            lastError = message;
            commonPrint.error('QuickStart failed with error: $message');
            return false;
          }
          step = 'vpnStart';
          await vpn?.start(clashLibHandler.getAndroidVpnOptions());
          Future.delayed(const Duration(seconds: 2), checkSmartAutoStop);

          if (globalState.config.vpnProps.networkSpeedNotification) {
            final profile = globalState.config.profiles
                .where((e) => e.id == profileId)
                .firstOrNull;
            await SystemExplicitStore.instance.ensureLoaded();
            final profileName = SystemExplicitStore.instance
                .notificationLabel(profile?.label ?? 'Angela Mihomo');
            await vpn?.updateNotificationSpeed(profileName, '↑0B/s ↓0B/s');
          }

          step = 'startListener';
          await clashLibHandler.startListener();
          return true;
        },
        onFailure: (error) async {
          lastError = error.toString();
          commonPrint.error(
            'Quick start attempt $attempts failed at step $step: $error',
          );
          await vpn?.stop();
        },
      );
      if (!ok) {
        commonPrint.error(
          'Fatal error during service background start: quick start '
          'exhausted $attempts attempts, last step $step, error: $lastError',
        );
        try {
          final marker = QuickStartFailureMarker(
            time: DateTime.now().toUtc().toIso8601String(),
            step: step,
            error: lastError,
            attempts: attempts,
          );
          await File(
            await appPath.quickStartFailurePath,
          ).writeAsString(marker.encode(), flush: true);
        } catch (e) {
          commonPrint.error('Failed to persist quick start marker: $e');
        }
        await vpn?.stop();
      } else {
        // T88: a successful quick start is the only event that retires
        // a failure marker left by an earlier exhausted run (the UI
        // isolate used to delete it on read, which destroyed the
        // evidence before the user could export it). Best-effort.
        try {
          final markerFile = File(await appPath.quickStartFailurePath);
          if (await markerFile.exists()) {
            await markerFile.delete();
          }
        } catch (e) {
          commonPrint.warn('Failed to clear quick start marker: $e');
        }
      }
    });
  }
}

Future<void> _handleMainIpc(ClashLibHandler clashLibHandler) async {
  final sendPort = IsolateNameServer.lookupPortByName(mainIsolate);
  if (sendPort == null) {
    commonPrint.warn(
      'Service: mainIsolate sendPort not found, IPC unavailable',
    );
    return;
  }

  _serviceReceiverPort?.close();
  _messageReceiverPort?.close();

  _serviceReceiverPort = ReceivePort();
  _serviceReceiverPort!.listen((message) async {
    final res = await clashLibHandler.invokeAction(message);
    _safeSend(sendPort, res);
  });
  _safeSend(sendPort, _serviceReceiverPort!.sendPort);

  _messageReceiverPort = ReceivePort();
  clashLibHandler.attachMessagePort(_messageReceiverPort!.sendPort.nativePort);
  _messageReceiverPort!.listen((message) {
    _safeSend(sendPort, message);
  });

  try {
    await clashLibHandler.startListener();
  } catch (e) {
    commonPrint.error('Service: proxy listener failed to start: $e');
  }
}

void _safeSend(SendPort sendPort, dynamic message) {
  try {
    sendPort.send(message);
  } catch (e) {
    commonPrint.warn('Service: IPC send failed: $e');
    final retryPort = IsolateNameServer.lookupPortByName(mainIsolate);
    if (retryPort != null) {
      try {
        retryPort.send(message);
      } catch (_) {}
    }
  }
}

@immutable
class _TileListenerWithService with TileListener {
  final Function() _onStart;
  final Function() _onStop;
  final Function() _onReconnectIpc;

  const _TileListenerWithService({
    required Function() onStart,
    required Function() onStop,
    required Function() onReconnectIpc,
  }) : _onStart = onStart,
       _onStop = onStop,
       _onReconnectIpc = onReconnectIpc;

  @override
  void onStart() => _onStart();

  @override
  void onStop() => _onStop();

  @override
  void onReconnectIpc() => _onReconnectIpc();
}

@immutable
class _VpnListenerWithService with VpnListener {
  final Function(String dns) _onDnsChanged;
  final Function() _onNetworkChanged;

  const _VpnListenerWithService({
    required Function(String dns) onDnsChanged,
    required Function() onNetworkChanged,
  }) : _onDnsChanged = onDnsChanged,
       _onNetworkChanged = onNetworkChanged;

  @override
  void onDnsChanged(String dns) {
    super.onDnsChanged(dns);
    _onDnsChanged(dns);
  }

  @override
  void onNetworkChanged() {
    super.onNetworkChanged();
    _onNetworkChanged();
  }
}
