import 'dart:async';
import 'dart:convert';

import 'package:angelamihomo/clash/interface.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHandler extends ClashHandlerInterface {
  Object? channel = Object();
  final sent = <String>[];

  @override
  Future<Object?> sendMessage(String message) async {
    sent.add(json.decode(message)['id'] as String);
    return channel;
  }

  void replySetup(String id, Map<String, dynamic> data) {
    handleResult(
      ActionResult(method: ActionMethod.setupConfig, data: data, id: id),
    );
  }

  @override
  Future<bool> preload() async => true;

  @override
  FutureOr<void> reStart() {}

  @override
  FutureOr<bool> destroy() => true;
}

// T127: the core is the single authority on whether a profile applied,
// but applying a profile takes profile-dependent time in the core
// (synchronous initial fetch of cache-less providers, each fetch with a
// 20s budget, in two provider waves). The Dart side used to cap the wait
// at 15s and throw TimeoutException, so slow-but-valid profiles were
// declared failed and rolled back. The wait must cover the core's own
// worst-case envelope; the verdict must come from the core's result.
void main() {
  group('setupConfig deadline', () {
    test(
      'awaits a core verdict that arrives after the old 15s deadline',
      () async {
        final handler = _FakeHandler();
        final future = handler.setupConfig(
          const SetupParams(selectedMap: {}, testUrl: 'http://127.0.0.1/'),
        );
        await pumpEventQueue();
        final reply = Future.delayed(const Duration(seconds: 16), () {
          handler.replySetup(handler.sent.single, {
            'message': '',
            'global': 'GLOBAL',
          });
        });
        final result = await future;
        await reply;
        expect(result.message, '');
        expect(result.global, 'GLOBAL');
        expect(handler.callbackCompleterMap, isEmpty);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test('surfaces a genuine core rejection as the result message', () async {
      final handler = _FakeHandler();
      final future = handler.setupConfig(
        const SetupParams(selectedMap: {}, testUrl: 'http://127.0.0.1/'),
      );
      await pumpEventQueue();
      handler.replySetup(handler.sent.single, {
        'message': 'invalid config',
        'global': '',
      });
      final result = await future;
      expect(result.message, 'invalid config');
    });
  });
}
