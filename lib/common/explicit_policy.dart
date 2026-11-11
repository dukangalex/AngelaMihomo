/// Runtime config changes. The saved subscription is not touched.
const explicitChainGroup = '链式落地';

/// Whether a group carries a proxy choice (T85): at least one
/// reachable member can route traffic through a real proxy — a proxy
/// whose type is not direct-capable, a nested group that itself
/// carries a proxy choice, or a provider source. Builtin actions and
/// direct-type adapters never count; unknown names resolve against
/// proxy providers at runtime and count as proxy evidence. Mirrors
/// proxyChoiceIndex in core/patch.go: only groups passing this test
/// may receive the chain landing, so direct-only and action-only
/// selectors never offer a chain for traffic that never proxies.
bool _carriesProxyChoice(
  Map group,
  Map<String, String> proxyTypes,
  Map<String, Map> groupsByName,
  Set<String> visiting,
) {
  final use = group['use'];
  if (use is List && use.isNotEmpty) return true;
  for (final key in [
    'include-all',
    'include-all-proxies',
    'include-all-providers',
  ]) {
    if (group[key] == true) return true;
  }
  final members = group['proxies'];
  if (members is! List) return false;
  for (final member in members) {
    final name = member?.toString() ?? '';
    if (name.isEmpty) continue;
    if (const {
      'DIRECT',
      'REJECT',
      'REJECT-DROP',
      'COMPATIBLE',
      'PASS',
    }.contains(name)) {
      continue;
    }
    final child = groupsByName[name];
    if (child != null) {
      if (visiting.contains(name)) continue;
      visiting.add(name);
      final found = _carriesProxyChoice(
        child,
        proxyTypes,
        groupsByName,
        visiting,
      );
      visiting.remove(name);
      if (found) return true;
      continue;
    }
    final type = proxyTypes[name];
    if (type != null) {
      if (type != 'direct' && type != 'pass' && type != 'compatible') {
        return true;
      }
      continue;
    }
    return true;
  }
  return false;
}

/// Inline landing nodes get dialer-proxy. Provider node names, which are
/// not in the file, become a relay group the selectors can choose.
bool applyChainPolicy(
  Map<String, dynamic> raw, {
  required String entry,
  required String landing,
}) {
  final entryName = entry.trim();
  final landingName = landing.trim();
  if (entryName.isEmpty || landingName.isEmpty || entryName == landingName) {
    return false;
  }
  final proxies = raw['proxies'];
  Map? target;
  var hasEntry = false;
  if (proxies is List) {
    for (final proxy in proxies) {
      if (proxy is! Map) continue;
      if (proxy['name']?.toString() == entryName) hasEntry = true;
      if (proxy['name']?.toString() == landingName) target = proxy;
    }
  }
  if (hasEntry && target != null) {
    target['dialer-proxy'] = entryName;
    return true;
  }

  final groups = raw['proxy-groups'];
  final list = groups is List ? groups : <dynamic>[];
  final exists = list.any(
    (group) => group is Map && group['name']?.toString() == explicitChainGroup,
  );
  if (!exists) {
    list.add({
      'name': explicitChainGroup,
      'type': 'relay',
      'proxies': [entryName, landingName],
    });
  }
  // T40: region groups (a select group whose members include its
  // paired "<name>-自动选择" url-test group, the converter's region
  // signature) keep only their own region's nodes; the chain landing
  // is not appended there. Mirrors core/patch.go isRegionSelectGroup.
  final urlTestNames = <String>{
    for (final group in list)
      if (group is Map && group['type']?.toString() == 'url-test')
        group['name']?.toString() ?? '',
  };
  bool isRegionGroup(Map group) {
    final name = group['name']?.toString() ?? '';
    if (name.isEmpty) return false;
    final paired = '$name-自动选择';
    if (!urlTestNames.contains(paired)) return false;
    final members = group['proxies'];
    return members is List && members.contains(paired);
  }

  final proxyTypes = <String, String>{
    if (proxies is List)
      for (final proxy in proxies)
        if (proxy is Map && proxy['name'] != null)
          proxy['name'].toString(): proxy['type'].toString().toLowerCase(),
  };
  final groupsByName = <String, Map>{
    for (final group in list)
      if (group is Map && group['name'] != null)
        group['name'].toString(): group,
  };

  var selectors = 0;
  for (final group in list) {
    if (group is! Map || group['type']?.toString() != 'select') continue;
    if (group['name']?.toString() == explicitChainGroup) continue;
    final members = group['proxies'];
    if (members is! List || members.contains(explicitChainGroup)) continue;
    // T85: only selectors carrying a proxy choice receive the chain
    // landing; direct-only and action-only selectors never do, and
    // the first eligible selector is the main selector below.
    if (!_carriesProxyChoice(group, proxyTypes, groupsByName, <String>{})) {
      continue;
    }
    selectors++;
    if (selectors > 1 && isRegionGroup(group)) continue;
    if (selectors == 1) {
      // The main selector lists the chain first so it is the default
      // choice once a chain is configured; other selectors keep the
      // chain as an extra option at the end.
      members.insert(0, explicitChainGroup);
    } else {
      members.add(explicitChainGroup);
    }
  }
  raw['proxy-groups'] = list;
  return true;
}
