import 'dart:async';

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/providers/config.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  Future<void> _checkUpdate(BuildContext context) async {
    final commonScaffoldState = context.commonScaffoldState;
    if (commonScaffoldState?.mounted != true) return;
    final data = await globalState.appController.safeRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: appLocalizations.checkUpdate,
      needLoading: true,
    );
    globalState.appController.checkUpdateResultHandle(
      data: data,
      handleError: true,
    );
  }

  List<Widget> _buildMoreSection(BuildContext context) {
    final links = [
      _LinkTile(
        title: 'Github Releases',
        icon: Icons.star,
        onTap: () => globalState.openUrl(
          'https://github.com/dukangalex/AngelaMihomo/releases',
        ),
      ),
      _LinkTile(
        title: appLocalizations.checkUpdate,
        icon: Icons.refresh,
        external: false,
        onTap: () => _checkUpdate(context),
      ),
      _LinkTile(
        title: '官方频道',
        icon: Icons.campaign_outlined,
        onTap: () => globalState.openUrl('https://t.me/AngelaNexus'),
      ),
      _LinkTile(
        title: '交流群',
        icon: Icons.groups_outlined,
        onTap: () => globalState.openUrl('https://t.me/AngelaMihomoGroup'),
      ),
    ];
    return generateSection(
      title: appLocalizations.projectLinks,
      items: [
        for (var i = 0; i < links.length; i += 2)
          _LinkGridRow(
            left: links[i],
            right: i + 1 < links.length ? links[i + 1] : null,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (_, ref, _) {
                return _DeveloperModeDetector(
                  child: Wrap(
                    spacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${globalState.packageInfo.version}+${globalState.packageInfo.buildNumber}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const _CoreVersionText(),
                        ],
                      ),
                    ],
                  ),
                  onEnterDeveloperMode: () {
                    ref
                        .read(appSettingProvider.notifier)
                        .updateState(
                          (state) => state.copyWith(developerMode: true),
                        );
                    context.showNotifier(
                      appLocalizations.developerModeEnableTip,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              appLocalizations.desc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ..._buildMoreSection(context),
    ];
    return generateListView(items);
  }
}

/// 内核信息行：版本取核心运行时自报值（getCoreStatus 的 version 字段，
/// 由核心构建时注入的 constant.Version 而来），不写死版本号；
/// 核心未就绪、取不到值时整行不渲染。
class _CoreVersionText extends StatefulWidget {
  const _CoreVersionText();

  @override
  State<_CoreVersionText> createState() => _CoreVersionTextState();
}

class _CoreVersionTextState extends State<_CoreVersionText> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await clashCore.getCoreStatus();
      final version = status?.version.trim() ?? '';
      if (mounted && version.isNotEmpty) {
        setState(() => _version = version);
      }
    } catch (_) {
      // 核心未就绪时保持空缺，不渲染本行。
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_version.isEmpty) {
      return const SizedBox.shrink();
    }
    final display = _version.startsWith('v') ? _version : 'v$_version';
    return Text(
      '${appLocalizations.core}: Mihomo $display',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _DeveloperModeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onEnterDeveloperMode;

  const _DeveloperModeDetector({
    required this.child,
    required this.onEnterDeveloperMode,
  });

  @override
  State<_DeveloperModeDetector> createState() => _DeveloperModeDetectorState();
}

class _DeveloperModeDetectorState extends State<_DeveloperModeDetector> {
  int _counter = 0;
  Timer? _timer;

  void _handleTap() {
    _counter++;
    if (_counter >= 5) {
      widget.onEnterDeveloperMode();
      _resetCounter();
    } else {
      _timer?.cancel();
      _timer = Timer(Duration(seconds: 1), _resetCounter);
    }
  }

  void _resetCounter() {
    _counter = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _handleTap, child: widget.child);
  }
}

class _LinkGridRow extends StatelessWidget {
  final _LinkTile left;
  final _LinkTile? right;

  const _LinkGridRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 10,
            endIndent: 10,
            color: colorScheme.outlineVariant.withValues(
              alpha: colorScheme.brightness == Brightness.light ? 0.6 : 0.45,
            ),
          ),
          Expanded(child: right ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool external;
  final VoidCallback onTap;

  const _LinkTile({
    required this.title,
    required this.icon,
    this.external = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.opacity12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: colorScheme.primary),
                ),
                const Spacer(),
                Icon(
                  external ? Icons.arrow_outward : Icons.arrow_forward,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.opacity50,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
