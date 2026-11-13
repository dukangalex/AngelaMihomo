import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';

import 'package:flutter/foundation.dart';

class DelayTestCoordinator extends ChangeNotifier {
  String? _testingGroupName;

  String? get testingGroupName => _testingGroupName;

  bool get isTesting => _testingGroupName != null;

  bool isTestingGroup(String groupName) => _testingGroupName == groupName;

  Future<bool> run(String groupName, Future<void> Function() action) async {
    if (isTesting) {
      return false;
    }

    _testingGroupName = groupName;
    notifyListeners();
    try {
      await action();
      return true;
    } finally {
      _testingGroupName = null;
      notifyListeners();
    }
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
}

final _delayTestRequestPool = DelayTestRequestPool();

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
  return _delayTestRequestPool.run(target, () async {
    final appController = globalState.appController;
    appController.setDelay(Delay(url: target.url, name: target.name, value: 0));
    final delay = await clashCore.getDelay(target.url, target.name);
    appController.setDelay(delay);
    return delay;
  });
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

/// Resolves the concrete delay-test targets for a batch of proxies:
/// each proxy is mapped to the leaf node that would actually carry
/// its traffic (following group selections) together with the real
/// test URL for that leaf. Shared by [delayTest] and the global
/// delay test so both always measure exactly the same targets.
Set<DelayTestTarget> _collectDelayTestTargets(
  List<Proxy> proxies,
  String? testUrl,
  List<Group> currentGroups,
) {
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
    final targets = _collectDelayTestTargets(proxies, testUrl, currentGroups);
    final concurrencyLimit = globalState.config.proxiesStyle.concurrencyLimit;

    // 按实际节点和实际测试地址创建任务，避免多个代理组别名重复测速。
    final delayTasks = targets.map((target) {
      return () async {
        await _testProxyDelay(target);
        await onDelayUpdated?.call();
      };
    }).toList();

    if (concurrencyLimit <= 1 || delayTasks.length <= 1) {
      for (final task in delayTasks) {
        await task();
      }
    } else {
      var nextIndex = 0;
      final running = <Future<void>>{};
      while (nextIndex < delayTasks.length || running.isNotEmpty) {
        while (nextIndex < delayTasks.length &&
            running.length < concurrencyLimit) {
          final task = delayTasks[nextIndex++];
          late final Future<void> future;
          future = task().whenComplete(() {
            running.remove(future);
          });
          running.add(future);
        }
        if (running.isNotEmpty) {
          await Future.any(running);
        }
      }
    }
    appController.addSortNum();
  }

  if (groupName == null || groupName.isEmpty) {
    await runTest();
    return;
  }
  await delayTestCoordinator.run(groupName, runTest);
}

/// T113: picks the fastest available proxy out of measured delays.
///
/// Only strictly positive delays count as available: a null value
/// means the proxy was never measured, 0 marks a test still in
/// flight, and negative values are the failure/timeout markers the
/// core writes (including the A-12 data-plane-not-ready window), so
/// none of them may ever win an optimization pick. Returns null when
/// no candidate is available, in which case the caller must keep the
/// group's current selection.
String? pickFastestAvailableProxy(Map<String, int?> delayByName) {
  String? bestName;
  var bestValue = 0;
  for (final entry in delayByName.entries) {
    final value = entry.value;
    if (value == null || value <= 0) continue;
    if (bestName == null || value < bestValue) {
      bestName = entry.key;
      bestValue = value;
    }
  }
  return bestName;
}

/// Outcome of one global delay test + auto-optimization pass (T113).
class GlobalDelayTestResult {
  /// Unique (proxy, test-url) targets measured across all groups.
  final int totalNodes;

  /// Measured targets whose latest delay is a valid positive value.
  final int availableNodes;

  /// Selector groups whose selection was changed: group name ->
  /// newly selected proxy name.
  final Map<String, String> optimizedSelections;

  /// Selector groups that had testable members but not a single
  /// available one; their previous selection was kept.
  final List<String> noAvailableGroups;

  const GlobalDelayTestResult({
    required this.totalNodes,
    required this.availableNodes,
    required this.optimizedSelections,
    required this.noAvailableGroups,
  });
}

/// T113: global delay test behind the dashboard detection card.
///
/// Measures every member of every group through the exact same path
/// a per-group delay test takes (same target resolution via
/// [_collectDelayTestTargets], each group's own test-url, the same
/// concurrency pool inside [delayTest]), then picks the fastest
/// available member for every Selector group. Picks are written
/// through the App's single selection authority — the profile
/// selectedMap plus the core changeProxy call, i.e. the same pair a
/// manual tap performs (the debounced variant cannot be used here:
/// its per-tag debounce would drop all but the last group).
/// URLTest / Fallback / LoadBalance groups are kernel-managed and
/// never get a manual selection. DIRECT is measured like any other
/// member but is never an optimization candidate — auto-switching a
/// group to direct would silently change the user's routing intent.
Future<GlobalDelayTestResult> runGlobalDelayTest({
  void Function(int done, int total)? onProgress,
}) async {
  final appController = globalState.appController;
  final groups = appController.getCurrentGroups();

  // Pre-collect the targets of every group with the same resolution
  // delayTest applies, so progress totals line up with the callbacks.
  final plannedTargets = <DelayTestTarget>{};
  var plannedCount = 0;
  for (final group in groups) {
    final targets = _collectDelayTestTargets(group.all, group.testUrl, groups);
    plannedCount += targets.length;
    plannedTargets.addAll(targets);
  }
  var doneCount = 0;
  onProgress?.call(0, plannedCount);
  for (final group in groups) {
    await delayTest(
      group.all,
      testUrl: group.testUrl,
      groupName: group.name,
      onDelayUpdated: () async {
        doneCount++;
        onProgress?.call(doneCount, plannedCount);
      },
    );
  }

  var availableNodes = 0;
  for (final target in plannedTargets) {
    final delay = appController.getTrayProxyDelay(
      proxyName: target.name,
      testUrl: target.url,
    );
    if (delay != null && delay > 0) {
      availableNodes++;
    }
  }

  // Snapshot every Selector group's pick before applying any of
  // them, so one group's change cannot skew another group's read.
  final picks = <String, String>{};
  final noAvailableGroups = <String>[];
  for (final group in groups) {
    if (group.type != GroupType.Selector) continue;
    final delayByName = <String, int?>{};
    for (final member in group.all) {
      if (_isNonTestableProxy(member)) continue;
      if (member.name.toUpperCase() == 'DIRECT') continue;
      delayByName[member.name] = appController.getTrayProxyDelay(
        proxyName: member.name,
        testUrl: group.testUrl,
      );
    }
    if (delayByName.isEmpty) continue;
    final pick = pickFastestAvailableProxy(delayByName);
    if (pick == null) {
      noAvailableGroups.add(group.name);
      continue;
    }
    if (pick != appController.getSelectedProxyName(group.name)) {
      picks[group.name] = pick;
    }
  }
  for (final entry in picks.entries) {
    appController.updateCurrentSelectedMap(entry.key, entry.value);
    await appController.changeProxy(
      groupName: entry.key,
      proxyName: entry.value,
    );
  }
  if (picks.isNotEmpty) {
    await appController.updateGroups();
    appController.addCheckIp();
  }
  return GlobalDelayTestResult(
    totalNodes: plannedTargets.length,
    availableNodes: availableNodes,
    optimizedSelections: picks,
    noAvailableGroups: noAvailableGroups,
  );
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
