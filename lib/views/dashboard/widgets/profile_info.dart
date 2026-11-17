import 'dart:math' as math;

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/proxies/card.dart';
import 'package:angelamihomo/views/proxies/common.dart';
import 'package:angelamihomo/views/proxies/providers.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_mode.dart';

/// Helpers behind the dashboard's merged profile/mode card (T147):
/// subscription refresh, the profile switch sheet and the group
/// member sheet the card's current-selection row opens. The sheets
/// are selection surfaces only — the merged card's one speed-test
/// trigger is its status light, so the group sheet carries no test
/// action of its own.
Future<void> _updateProfile(Profile profile) async {
  final appController = globalState.appController;
  try {
    appController.setProfile(profile.copyWith(isUpdating: true));
    await appController.updateProfile(profile, applyUnchanged: false);
  } on Object catch (e) {
    appController.setProfile(profile.copyWith(isUpdating: false));
    globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: profileUpdateFailureNotice(
          profile.label ?? profile.id,
          e,
          automatic: false,
        ),
      ),
      cancelable: false,
    );
  }
}

Future<void> refreshProfileSubscription(
  BuildContext context,
  WidgetRef ref,
  Profile profile,
) async {
  if (profile.type == ProfileType.bundle) {
    final appController = globalState.appController;
    await appController.safeRun(
      () => appController.generateBundle(profile.id, refresh: true),
      silence: false,
    );
    return;
  }
  if (profile.providerSubscriptions.isNotEmpty) {
    await updateExternalProviders(ref, context, type: 'Proxy');
  }
  if (profile.type != ProfileType.url || !context.mounted) return;
  await _updateProfile(ref.read(currentProfileProvider) ?? profile);
}

void showProfileSwitchSheet(BuildContext context) {
  showSheet(
    context: context,
    builder: (_, type) => AdaptiveSheetScaffold(
      type: type,
      title: appLocalizations.profiles,
      actions: [
        IconButton(
          tooltip: appLocalizations.profiles,
          onPressed: () => globalState.appController.toProfiles(),
          icon: const Icon(Icons.open_in_new),
        ),
      ],
      body: const _ProfileSwitchList(),
    ),
  );
}

void showGroupProxySheet(BuildContext context, String groupName) {
  showSheet(
    context: context,
    builder: (_, type) => _GroupProxySheet(type: type, groupName: groupName),
  );
}

class _GroupProxySheet extends ConsumerWidget {
  final SheetType type;
  final String groupName;

  const _GroupProxySheet({required this.type, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(getProxyNameProvider(groupName), (previous, next) {
      if (previous == next || !context.mounted) return;
      Navigator.of(context).pop();
    });
    final group = ref.watch(
      groupsProvider.select((groups) => groups.getGroup(groupName)),
    );
    final proxies = ref.watch(sortedGroupProxiesProvider('', groupName)) ?? [];
    final (cardType, layout) = ref.watch(
      proxiesStyleSettingProvider.select(
        (state) => (state.cardType, state.layout),
      ),
    );
    return AdaptiveSheetScaffold(
      type: type,
      title: groupName,
      body: group == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (_, constraints) => GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: math.max(
                    1,
                    utils.getProxiesColumns(constraints.maxWidth, layout),
                  ),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: getItemHeight(cardType),
                ),
                itemCount: proxies.length,
                itemBuilder: (_, index) => ProxyCard(
                  key: ValueKey(proxies[index].name),
                  testUrl: group.testUrl,
                  groupType: group.type,
                  type: cardType,
                  proxy: proxies[index],
                  groupName: group.name,
                ),
              ),
            ),
    );
  }
}

class _ProfileSwitchList extends ConsumerWidget {
  const _ProfileSwitchList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);
    final currentProfileId = ref.watch(currentProfileIdProvider);
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: profiles.length,
      itemBuilder: (_, index) {
        final profile = profiles[index];
        return _ProfileSwitchItem(
          key: ValueKey(profile.id),
          profile: profile,
          selected: profile.id == currentProfileId,
          onTap: () {
            if (profile.id != currentProfileId) {
              ref.read(currentProfileIdProvider.notifier).value = profile.id;
            }
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _ProfileSwitchItem extends StatelessWidget {
  final Profile profile;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileSwitchItem({
    super.key,
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final usage = ProfileUsage.of(profile);
    final segments = usage?.segments ?? [];
    final subtitle = usage != null
        ? [usage.usageText, ?usage.expireText].join(' · ')
        : profile.type == ProfileType.file
        ? [
            appLocalizations.localFile,
            ?profile.lastUpdateDate?.lastUpdateTimeDesc,
          ].join(' · ')
        : appLocalizations.noUsageData;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 21,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EmojiText(
                        profile.label ?? profile.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: usage?.isExpired == true
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (segments.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        UsageSegmentBar(segments: segments, height: 3),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
