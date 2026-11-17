import 'dart:async';

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';

import 'package:flutter/foundation.dart';

class DelayTestCoordinator extends ChangeNotifier {
  String? _testingGroupName;
  int _epoch = 0;

  String? get testingGroupName => _testingGroupName;

  int get epoch => _epoch;

  bool get isTesting => _testingGroupName != null;

  bool isTestingGroup(String groupName) => _testingGroupName == groupName;

  Future<bool> run(String groupName, Future<void> Function() action) async {
    if (isTesting) {
      return false;
    }

    final epoch = _epoch;
    _testingGroupName = groupName;
    notifyListeners();
    try {
      await action();
      return true;
    } finally {
      if (epoch == _epoch) {
        _testingGroupName = null;
        notifyListeners();
      }
    }
  }

  void cancel() {
    _epoch++;
    if (_testingGroupName == null) return;
    _testingGroupName = null;
    notifyListeners();
  }
}

final delayTestCoordinator = DelayTestCoordinator();

@immutable
class DelayTestTarget {
  final String name;
  final String url;

  const DelayTestTarget({required this.name, required this.url});

  @override
  bool operator ==(Object other) {
    return other is DelayTestTarget && other.name == name && other.url == url;
  }

  @override
  int get hashCode => Object.hash(name, url);
}

class DelayTestRequestPool {
  final Map<DelayTestTarget, Future<Delay>> _pendingRequests = {};

  int get pendingCount => _pendingRequests.length;

  Future<Delay>? pendingRequest(DelayTestTarget target) =>
      _pendingRequests[target];

  Future<Delay> run(DelayTestTarget target, Future<Delay> Function() action) {
    final pendingRequest = _pendingRequests[target];
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = action();
    _pendingRequests[target] = request;
    return request.whenComplete(() {
      if (identical(_pendingRequests[target], request)) {
        _pendingRequests.remove(target);
      }
    });
  }

  void clear() => _pendingRequests.clear();
}

final _delayTestRequestPool = DelayTestRequestPool();

void cancelDelayTests() {
  delayTestCoordinator.cancel();
  _delayTestRequestPool.clear();
}

double get listHeaderHeight {
  final measure = globalState.measure;
  return 20 + measure.titleMediumHeight + 4 + measure.bodyMediumHeight;
}

double getItemHeight(ProxyCardType proxyCardType) {
  final measure = globalState.measure;
  final baseHeight =
      16 + measure.bodyMediumHeight * 2 + measure.bodySmallHeight + 8 + 4;
  return switch (proxyCardType) {
    ProxyCardType.expand =>
      baseHeight - measure.bodySmallHeight + measure.labelSmallHeight * 2 + 4,
    ProxyCardType.shrink => baseHeight,
    ProxyCardType.min => baseHeight - measure.bodyMediumHeight,
  };
}

Future<void> proxyDelayTest(Proxy proxy, [String? testUrl]) async {
  if (_isNonTestableProxy(proxy)) return;
  final appController = globalState.appController;
  final state = appController.getProxyCardState(proxy.name);
  final url = appController.getRealTestUrl(
    state.testUrl.getSafeValue(testUrl ?? ''),
  );
  if (state.proxyName.isEmpty) {
    return;
  }
  await _testProxyDelay(DelayTestTarget(name: state.proxyName, url: url));
  appController.addSortNum();
}

Future<Delay> _testProxyDelay(DelayTestTarget target) {
  final epoch = delayTestCoordinator.epoch;
  return _delayTestRequestPool.run(target, () async {
    final appController = globalState.appController;
    appController.setDelay(Delay(url: target.url, name: target.name, value: 0));
    final delay = await clashCore.getDelay(target.url, target.name);
    if (epoch == delayTestCoordinator.epoch) {
      appController.setDelay(delay);
    }
    return delay;
  });
}

class _DelayProgressListener with AppMessageListener {
  final Future<void> Function() onDelayUpdated;

  _DelayProgressListener(this.onDelayUpdated);

  @override
  void onDelays(List<Delay> delays) {
    unawaited(onDelayUpdated());
  }
}

Future<Map<DelayTestTarget, Delay>> _testProxyDelays(
  Iterable<DelayTestTarget> targets, {
  Future<void> Function()? onDelayUpdated,
}) async {
  final appController = globalState.appController;
  final epoch = delayTestCoordinator.epoch;
  final pending = <Future<Delay>>[];
  final batch = <DelayTestTarget>[];
  for (final target in targets) {
    final request = _delayTestRequestPool.pendingRequest(target);
    if (request != null) {
      pending.add(request);
    } else {
      batch.add(target);
    }
  }
  final listener = batch.isNotEmpty && onDelayUpdated != null
      ? _DelayProgressListener(onDelayUpdated)
      : null;
  if (listener != null) clashMessage.addListener(listener);
  Map<DelayTestTarget, Delay> resultMap = {};
  try {
    if (batch.isNotEmpty) {
      for (final target in batch) {
        appController.setDelay(
          Delay(url: target.url, name: target.name, value: 0),
        );
      }
      final results = clashCore
          .getDelays([
            for (final target in batch) (name: target.name, url: target.url),
          ], concurrency: globalState.config.proxiesStyle.concurrencyLimit)
          .then(
            (delays) => {
              for (final delay in delays)
                DelayTestTarget(name: delay.name, url: delay.url): delay,
            },
            onError: (Object e) {
              commonPrint.warn('Batch delay test failed: $e');
              return <DelayTestTarget, Delay>{};
            },
          );
      for (final target in batch) {
        pending.add(
          _delayTestRequestPool.run(target, () async {
            final delay =
                (await results)[target] ??
                Delay(name: target.name, url: target.url, value: -1);
            if (epoch == delayTestCoordinator.epoch) {
              appController.setDelay(delay);
            }
            return delay;
          }),
        );
      }
    }
    final values = await Future.wait(pending);
    resultMap = {
      for (final delay in values)
        DelayTestTarget(name: delay.name, url: delay.url): delay,
    };
  } finally {
    if (listener != null) clashMessage.removeListener(listener);
  }
  await onDelayUpdated?.call();
  return resultMap;
}

bool _isNonTestableProxyName(String proxyName) {
  final name = proxyName.toUpperCase();
  return name == 'REJECT' || name == 'REJECT-DROP' || name == 'PASS';
}

bool _isNonTestableProxyType(String proxyType) {
  return proxyType.toUpperCase() == 'REMATCH';
}

bool _isNonTestableProxy(Proxy proxy) {
  return _isNonTestableProxyName(proxy.name) ||
      _isNonTestableProxyType(proxy.type);
}

/// Resolves [proxies] to the concrete delay-test targets used by every
/// delay test entry point. A member that is itself a group resolves to the
/// leaf its group currently selects (with that group's test URL), matching
/// what the group card displays; plain members resolve to themselves.
/// Non-testable entries (REJECT/PASS/REMATCH plumbing) are skipped.
Set<DelayTestTarget> buildDelayTestTargets(
  Iterable<Proxy> proxies, {
  String? testUrl,
  required List<Group> currentGroups,
}) {
  final appController = globalState.appController;
  final targets = <DelayTestTarget>{};
  for (final proxy in proxies) {
    if (_isNonTestableProxy(proxy)) {
      continue;
    }
    final state = appController.getProxyCardState(proxy.name);
    final url = appController.getRealTestUrl(
      state.testUrl.getSafeValue(testUrl ?? ''),
    );
    final name = state.proxyName;
    if (name.isEmpty ||
        _isNonTestableProxyName(name) ||
        (currentGroups.getGroup(name) == null &&
            currentGroups.getRematchProxy(name) != null)) {
      continue;
    }
    targets.add(DelayTestTarget(name: name, url: url));
  }
  return targets;
}

Future<void> delayTest(
  List<Proxy> proxies, {
  String? testUrl,
  String? groupName,
  Future<void> Function()? onDelayUpdated,
}) async {
  Future<void> runTest() async {
    final appController = globalState.appController;
    final currentGroups = appController.getCurrentGroups();
    final testProxies = (groupName != null && groupName.isNotEmpty)
        ? currentGroups.getGroup(groupName)?.all ?? proxies
        : proxies;
    final targets = buildDelayTestTargets(
      testProxies,
      testUrl: testUrl,
      currentGroups: currentGroups,
    );
    await _testProxyDelays(targets, onDelayUpdated: onDelayUpdated);
    appController.addSortNum();
  }

  if (groupName == null || groupName.isEmpty) {
    await runTest();
    return;
  }
  await delayTestCoordinator.run(groupName, runTest);
}

/// Coordinator key reserving the shared [delayTestCoordinator] for a
/// global delay test run, so a global run and a per-group run can never
/// overlap. No real group can carry this name.
const globalDelayTestCoordinatorKey = '__global_delay_test__';

enum GlobalDelayTestPhase { idle, running, done }

/// Observable state of a global linked delay test run: every group and
/// node measured once, through the path it would actually take (the core
/// measures a proxy over its production dial path, so dialer-proxy chains
/// are traversed end to end). A run only ever measures — it never calls
/// the selection write path, so every group's selection stays untouched.
class GlobalDelayTestController extends ChangeNotifier {
  GlobalDelayTestPhase _phase = GlobalDelayTestPhase.idle;
  int _total = 0;
  int _completed = 0;
  int _failed = 0;
  int _runId = 0;
  Timer? _dismissTimer;

  GlobalDelayTestPhase get phase => _phase;

  bool get isRunning => _phase == GlobalDelayTestPhase.running;

  int get total => _total;

  int get completed => _completed;

  int get failed => _failed;

  void _begin(int total) {
    _dismissTimer?.cancel();
    _runId++;
    _phase = GlobalDelayTestPhase.running;
    _total = total;
    _completed = 0;
    _failed = 0;
    notifyListeners();
  }

  void _reportProgress({required bool failed}) {
    if (!isRunning) return;
    _completed++;
    if (failed) _failed++;
    notifyListeners();
  }

  void _complete(Map<DelayTestTarget, Delay> results) {
    if (!isRunning) return;
    var failed = 0;
    for (final delay in results.values) {
      if ((delay.value ?? -1) < 0) failed++;
    }
    _completed = results.length;
    _failed = failed;
    _phase = GlobalDelayTestPhase.done;
    notifyListeners();
    _scheduleAutoDismiss();
  }

  void _completeWithError() {
    if (!isRunning) return;
    _failed += _total - _completed;
    _completed = _total;
    _phase = GlobalDelayTestPhase.done;
    notifyListeners();
    _scheduleAutoDismiss();
  }

  void _scheduleAutoDismiss() {
    _dismissTimer?.cancel();
    final runId = _runId;
    // The result strip always auto-dismisses five seconds after the run
    // completes, failures included (user's call, 2026-11-17); the manual
    // close button stays for dismissing it sooner.
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (_phase == GlobalDelayTestPhase.done && _runId == runId) {
        dismiss();
      }
    });
  }

  void _cancel() {
    _dismissTimer?.cancel();
    if (!isRunning) return;
    _phase = GlobalDelayTestPhase.idle;
    notifyListeners();
  }

  void dismiss() {
    _dismissTimer?.cancel();
    if (_phase != GlobalDelayTestPhase.done) return;
    _phase = GlobalDelayTestPhase.idle;
    notifyListeners();
  }
}

final globalDelayTestController = GlobalDelayTestController();

class _GlobalDelayProgressListener with AppMessageListener {
  final GlobalDelayTestController controller;
  final Set<DelayTestTarget> targets;
  final Set<DelayTestTarget> _counted = {};

  _GlobalDelayProgressListener(this.controller, this.targets);

  @override
  void onDelays(List<Delay> delays) {
    for (final delay in delays) {
      if (delay.value == 0) continue;
      final key = DelayTestTarget(name: delay.name, url: delay.url);
      if (!targets.contains(key) || !_counted.add(key)) continue;
      controller._reportProgress(failed: (delay.value ?? -1) < 0);
    }
  }
}

/// Measures every testable proxy of every current group exactly once.
///
/// Targets are built per group with that group's test URL, using the same
/// resolution as the per-group test, so a group's displayed delay — the
/// delay of the leaf its current selection resolves to — is refreshed by
/// the same measurement. Concurrency is bounded by the user's proxies
/// style concurrency limit (the core caps it further) and each item by
/// the standard HTTP timeout. Selections are never written: the only
/// bridge call issued is the batch delay measurement.
Future<void> globalDelayTest({GlobalDelayTestController? controller}) async {
  final state = controller ?? globalDelayTestController;
  if (state.isRunning || delayTestCoordinator.isTesting) return;
  final appController = globalState.appController;
  final currentGroups = appController.getCurrentGroups();
  if (currentGroups.isEmpty) return;
  await delayTestCoordinator.run(globalDelayTestCoordinatorKey, () async {
    final targets = <DelayTestTarget>{};
    for (final group in currentGroups) {
      targets.addAll(
        buildDelayTestTargets(
          group.all,
          testUrl: group.testUrl,
          currentGroups: currentGroups,
        ),
      );
    }
    if (targets.isEmpty) return;
    state._begin(targets.length);
    final listener = _GlobalDelayProgressListener(state, targets);
    clashMessage.addListener(listener);
    try {
      final results = await _testProxyDelays(targets);
      state._complete(results);
    } catch (e) {
      commonPrint.warn('Global delay test failed: $e');
      state._completeWithError();
    } finally {
      clashMessage.removeListener(listener);
    }
    appController.addSortNum();
  });
}

/// Cancels an in-flight global run: pending results are discarded via the
/// shared delay-test epoch, and in-flight core measurements finish
/// silently without being applied.
void cancelGlobalDelayTest({GlobalDelayTestController? controller}) {
  final state = controller ?? globalDelayTestController;
  if (!state.isRunning) return;
  state._cancel();
  cancelDelayTests();
}

double getScrollToSelectedOffset({
  required String groupName,
  required List<Proxy> proxies,
}) {
  final appController = globalState.appController;
  final columns = appController.getProxiesColumns();
  final proxyCardType = globalState.config.proxiesStyle.cardType;
  final selectedProxyName = appController.getSelectedProxyName(groupName);
  final findSelectedIndex = proxies.indexWhere(
    (proxy) => proxy.name == selectedProxyName,
  );
  final selectedIndex = findSelectedIndex != -1 ? findSelectedIndex : 0;
  final rows = (selectedIndex / columns).floor();
  return rows * getItemHeight(proxyCardType) + (rows - 1) * 8;
}
