import 'dart:io';

import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/path.dart';
import 'package:bett_box/common/patrol_store.dart';
import 'package:bett_box/controller.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/views/proxies/common.dart';

/// Outcome of running one whitelist patrol action (T29). Verification
/// is the caller's job (it rebuilds the report); this layer only
/// performs the action and reports whether it executed, plus the
/// snapshot needed to undo it.
class PatrolActionResult {
  /// The action itself ran without throwing.
  final bool executed;
  final String detail;

  /// Pre-action profile file backup (updateSubscription only).
  final String? profileBackupPath;

  const PatrolActionResult({
    required this.executed,
    this.detail = '',
    this.profileBackupPath,
  });
}

/// The phase-1 whitelist executor. Every action maps to an existing,
/// battle-tested app operation — no new core behavior is introduced:
///
/// * updateSubscription → the normal profile update flow, after a
///   file snapshot so a bad fetch can be rolled back;
/// * testNodes → the proxies total delay test (T41);
/// * flushDns → the core DNS + FakeIP cache flush;
/// * reloadConfig → the checked full-profile re-apply.
///
/// High-risk changes (chain structure, subscription source) are NOT
/// actions: the report points at them and the user does them by hand.
Future<PatrolActionResult> executePatrolAction(
  AppController controller,
  PatrolAction action, {
  Profile? profile,
}) async {
  switch (action) {
    case PatrolAction.updateSubscription:
      final target = profile;
      if (target == null) {
        return const PatrolActionResult(
          executed: false,
          detail: 'no current profile',
        );
      }
      final file = File(await appPath.getProfilePath(target.id));
      final backup = await PatrolStore.snapshotProfileFile(file);
      try {
        await controller.updateProfile(target);
        return PatrolActionResult(executed: true, profileBackupPath: backup);
      } catch (error) {
        return PatrolActionResult(
          executed: false,
          detail: '$error',
          profileBackupPath: backup,
        );
      }
    case PatrolAction.testNodes:
      await totalDelayTestCoordinator.runAll();
      return PatrolActionResult(
        executed: true,
        detail:
            '${totalDelayTestCoordinator.doneGroups}/'
            '${totalDelayTestCoordinator.totalGroups} groups',
      );
    case PatrolAction.flushDns:
      await clashCore.flushDnsCache();
      await clashCore.flushFakeIP();
      return const PatrolActionResult(executed: true);
    case PatrolAction.reloadConfig:
      final applied = await controller.applyProfileChecked();
      return PatrolActionResult(
        executed: applied,
        detail: applied ? '' : 'profile setup did not apply',
      );
  }
}

/// Rolls back a subscription update from its snapshot and re-applies
/// the restored profile. Used by automatic rollback after a failed
/// verification and by the records page's manual undo.
Future<bool> rollbackSubscriptionSnapshot(
  AppController controller, {
  required Profile profile,
  required String backupPath,
}) async {
  final file = File(await appPath.getProfilePath(profile.id));
  final restored = await PatrolStore.restoreProfileSnapshot(backupPath, file);
  if (!restored) return false;
  await PatrolStore.clearUpdateFailure(profile.id);
  return controller.applyProfileChecked();
}
