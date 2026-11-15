import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

import 'constant.dart';
import 'path.dart';
import 'print.dart';
import 'system.dart';

class AutoLaunch {
  static AutoLaunch? _instance;

  AutoLaunch._internal() {
    launchAtStartup.setup(
      appName: appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  String get _taskName => appPath.isPortable ? '$appName Portable' : appName;

  factory AutoLaunch() {
    _instance ??= AutoLaunch._internal();
    return _instance!;
  }

  Future<bool> get isEnable async {
    if (system.isWindows) {
      // Windows 上改为通过任务计划实现开机自启动，状态以任务计划的
      // 实际回查为准（与注册/删除后的验证共用同一实现）。
      return await windows?.isTaskRegistered(_taskName) ?? false;
    }
    return await launchAtStartup.isEnabled();
  }

  Future<bool> enable() async {
    if (system.isWindows) {
      // 使用任务计划实现 Windows 开机自启动（管理员模式）
      return await windows?.registerTask(_taskName) ?? false;
    }
    return await launchAtStartup.enable();
  }

  Future<bool> disable() async {
    if (system.isWindows) {
      return await windows?.unregisterTask(_taskName) ?? false;
    }
    return await launchAtStartup.disable();
  }

  Future<void> updateStatus(bool isAutoLaunch) async {
    if (kDebugMode) {
      return;
    }
    if (await isEnable == isAutoLaunch) return;

    final succeeded = isAutoLaunch ? await enable() : await disable();
    // 以回查的实际状态为准绳：操作未生效必须留下可诊断日志，不许
    // 无声失败。设置项本身是用户意图、不回滚；由于实际状态仍与设置
    // 不一致，下一次 updateStatus（启动或设置变更时）会再次对账重试，
    // 界面状态不会与实际状态长期背离。
    final actual = await isEnable;
    if (!succeeded || actual != isAutoLaunch) {
      commonPrint.warn(
        'autoLaunch updateStatus: desired=$isAutoLaunch, actual=$actual, '
        'operation reported ${succeeded ? 'success' : 'failure'}',
      );
    }
  }
}

final autoLaunch = system.isDesktop ? AutoLaunch() : null;
