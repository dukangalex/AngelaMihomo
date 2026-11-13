/// Stored per-group state (selectedMap picks, groupSwitches)
/// whose group no longer exists in the live group list (T111
/// E-04). The entries are deliberately KEPT — renaming the group
/// back restores them — but the user is told they are dormant
/// instead of the state silently going stale.
Set<String> orphanedGroupNames({
  required Iterable<String> storedKeys,
  required Set<String> liveGroupNames,
}) {
  return storedKeys
      .where((key) => !liveGroupNames.contains(key))
      .toSet();
}
