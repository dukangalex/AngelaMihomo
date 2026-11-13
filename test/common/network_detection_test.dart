import 'dart:async';
import 'dart:io';

import 'package:bett_box/clash/core.dart';
import 'package:bett_box/clash/interface.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Detection enriches the trace result through the core bridge; install
// a handler that answers locally so no desktop core is started. The
// empty geo payload makes enrichment a no-op, leaving the trace data.
class _GeoHandler extends ClashHandlerInterface {
  @override
  Future<String> queryIpGeo(String ip) async => '';

  @override
  Future<bool> preload() async => true;

  @override
  void reStart() {}

  @override
  bool destroy() => true;

  @override
  Future<Object?> sendMessage(String message) async => null;
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met in time');
    }
    await Future.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late HttpServer server;
  late HttpServer originServer;
  final tunnelSockets = <Socket>[];
  Directory? certDir;
  final pending = <Completer<void>>[];
  var requestCount = 0;

  void setConfig({Mode mode = Mode.rule}) {
    globalState.config = Config(
      themeProps: defaultThemeProps,
      appSetting: const AppSettingProps(
        mobileDashboardWidgets: [],
        desktopDashboardWidgets: [],
      ),
      patchClashConfig: ClashConfig(mixedPort: server.port, mode: mode),
    );
  }

  void setAppState({required bool isInit}) {
    globalState.appState = AppState(
      isInit: isInit,
      runTime: 1,
      brightness: Brightness.light,
      version: 0,
      viewSize: Size.zero,
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
  }

  void release() {
    for (final completer in pending) {
      completer.complete();
    }
    pending.clear();
  }

  // The fake proxy below stands in for the local mixed port. Exit IP
  // discovery is a single HTTPS trace echo (cloudflare.com/cdn-cgi/trace),
  // so through a proxy it arrives as a CONNECT tunnel; the plain GET
  // handler alone can no longer observe it. CONNECT tunnels are therefore
  // relayed to a local TLS origin that serves the same gated trace
  // response. Geo enrichment happens locally in the core and produces no
  // network traffic, so exactly one request per check is expected.
  Future<void> handleDataRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      request.response.statusCode = HttpStatus.badGateway;
      await request.response.close();
      return;
    }
    requestCount++;
    final completer = Completer<void>();
    pending.add(completer);
    await completer.future;
    request.response.write('ip=1.2.3.4\nloc=US\n');
    await request.response.close().catchError((_) {});
  }

  setUpAll(() async {
    ClashCore.setHandlerForTesting(_GeoHandler());
    HttpOverrides.global = AngelaHttpOverrides();

    // Throwaway self-signed certificate for the fake origin, generated per
    // run so no private key is ever committed. The app-side HTTP overrides
    // accept any certificate, so a local openssl is all that is needed.
    certDir = await Directory.systemTemp.createTemp('network_detection_');
    final certFile = File('${certDir!.path}/cert.pem');
    final keyFile = File('${certDir!.path}/key.pem');
    final openssl = await Process.run('openssl', [
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-keyout',
      keyFile.path,
      '-out',
      certFile.path,
      '-days',
      '3650',
      '-nodes',
      '-subj',
      '/CN=localhost',
      '-addext',
      'subjectAltName=DNS:localhost,DNS:cloudflare.com',
    ]);
    if (openssl.exitCode != 0) {
      fail('openssl certificate generation failed: ${openssl.stderr}');
    }
    final securityContext = SecurityContext()
      ..useCertificateChain(certFile.path)
      ..usePrivateKey(keyFile.path);
    originServer = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      securityContext,
    );
    originServer.listen((request) async {
      await handleDataRequest(request);
    });

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.method == 'CONNECT') {
        final socket = await request.response.detachSocket(
          writeHeaders: false,
        );
        tunnelSockets.add(socket);
        try {
          final upstream = await Socket.connect(
            InternetAddress.loopbackIPv4,
            originServer.port,
          );
          tunnelSockets.add(upstream);
          socket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
          socket.listen(
            upstream.add,
            onError: (_) {},
            onDone: upstream.destroy,
          );
          upstream.listen(
            socket.add,
            onError: (_) {},
            onDone: socket.destroy,
          );
        } catch (_) {
          socket.destroy();
        }
        return;
      }
      await handleDataRequest(request);
    });
  });

  tearDownAll(() async {
    release();
    for (final socket in tunnelSockets) {
      socket.destroy();
    }
    await server.close(force: true);
    await originServer.close(force: true);
    await certDir?.delete(recursive: true).catchError((_) => certDir!);
  });

  setUp(() {
    requestCount = 0;
    setConfig();
    setAppState(isInit: true);
  });

  tearDown(() async {
    release();
    await _waitFor(() => !detectionState.state.value.isLoading);
  });

  test('进行中的检测不会被相同条件的触发重启', () async {
    detectionState.startCheck(immediate: true);
    await _waitFor(() => requestCount == 1);

    detectionState.startCheck(immediate: true);
    await Future.delayed(const Duration(milliseconds: 300));
    expect(requestCount, 1);

    release();
    await _waitFor(() => detectionState.state.value.ipInfo?.ip == '1.2.3.4');
    expect(detectionState.state.value.isLoading, isFalse);
  });

  test('初始化前的触发在初始化完成后补发', () async {
    setAppState(isInit: false);
    detectionState.startCheck(immediate: true);
    await Future.delayed(const Duration(milliseconds: 300));
    expect(requestCount, 0);

    setAppState(isInit: true);
    detectionState.flushPendingCheck();
    await _waitFor(() => requestCount == 1);

    detectionState.flushPendingCheck();
    release();
    await _waitFor(() => !detectionState.state.value.isLoading);
    await Future.delayed(const Duration(milliseconds: 2300));
    expect(requestCount, 1);
  });

  test('条件变化时重启检测', () async {
    detectionState.startCheck(immediate: true);
    await _waitFor(() => requestCount == 1);

    setConfig(mode: Mode.global);
    detectionState.startCheck(immediate: true);
    await _waitFor(() => requestCount == 2);

    release();
    await _waitFor(() => detectionState.state.value.ipInfo?.ip == '1.2.3.4');
  });
}
