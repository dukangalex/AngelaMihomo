import 'dart:async';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
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
        title: 'Channel',
        icon: Icons.campaign_outlined,
        onTap: () => globalState.openUrl('https://t.me/AngelaNexus'),
      ),
      _LinkTile(
        title: 'AngelaMihomoGroup',
        icon: Icons.groups_outlined,
        onTap: () => globalState.openUrl('https://t.me/AngelaMihomoGroup'),
      ),
    ];
    return generateSection(
      title: appLocalizations.more,
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
                return Wrap(
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
                          // T61: the bundled Mihomo core version, fed from
                          // core/CORE_VERSION by setup.dart (same source
                          // as the value injected into the core binary).
                          Text(
                            '${appLocalizations.mihomoCoreVersion} $bundledCoreVersion',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
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
