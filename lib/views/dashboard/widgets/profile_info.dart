import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:angelamihomo/clash/clash.dart';
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

/// Shared profile-surface helpers and components: subscription
/// refresh, the profile switch sheet and the group member sheet,
/// plus the usage segment bar and the zodiac-wheel update icon the
/// star-rail hero's subscription card renders. (T337: these two
/// components lived in the merged profile/mode card until that
/// card was retired into the hero; they moved here unchanged —
/// same rendering, same behaviour.)
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
  // Lucian UX/UI Prompt #336 · MIT License — on mobile the group
  // detail opens as the three-detent bottom sheet (collapsed /
  // half / full, spring snap with fling velocity); larger form
  // factors keep the adaptive sheet.
  final isMobile =
      utils.getViewMode(MediaQuery.sizeOf(context).width) == ViewMode.mobile;
  if (isMobile) {
    showDetentSheet(
      context: context,
      header: _GroupSheetHeader(groupName: groupName),
      child: _DetentGroupBody(groupName: groupName),
    );
    return;
  }
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
    return AdaptiveSheetScaffold(
      type: type,
      title: groupName,
      body: _GroupProxyGrid(groupName: groupName),
    );
  }
}

/// Header of the detent group sheet: the grab area carries the
/// group name and its node count, mirroring the spec's sheet head.
class _GroupSheetHeader extends ConsumerWidget {
  final String groupName;

  const _GroupSheetHeader({required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(sortedGroupProxiesProvider('', groupName))?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetentGroupBody extends ConsumerWidget {
  final String groupName;

  const _DetentGroupBody({required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(getProxyNameProvider(groupName), (previous, next) {
      if (previous == next || !context.mounted) return;
      Navigator.of(context).pop();
    });
    return _GroupProxyGrid(groupName: groupName);
  }
}

class _GroupProxyGrid extends ConsumerWidget {
  final String groupName;

  const _GroupProxyGrid({required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(
      groupsProvider.select((groups) => groups.getGroup(groupName)),
    );
    final proxies = ref.watch(sortedGroupProxiesProvider('', groupName)) ?? [];
    final (cardType, layout) = ref.watch(
      proxiesStyleSettingProvider.select(
        (state) => (state.cardType, state.layout),
      ),
    );
    if (group == null) return const SizedBox.shrink();
    return LayoutBuilder(
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

/// T301 (user 2026-11-25, supersedes the T300 Earth–Moon look as
/// "not tech-feeling enough"): the update button as a zodiac
/// astrolabe wheel, after the user's reference of a golden zodiac
/// star-disc — an outer ring divided into twelve sign sectors with
/// their glyphs and gem dots on the rim, an inner eight-point
/// compass star, drawn in the active color scheme's metal tones so
/// it belongs to the 星辰大海 interface in every theme. While
/// [updating] the glyph ring turns one way and the star counter-
/// turns, like an instrument at work; when the update ends both
/// finish their current revolution and park. [dimmed] renders the
/// wheel at disabled strength.
class ZodiacWheelUpdateIcon extends StatefulWidget {
  final bool updating;
  final bool dimmed;

  const ZodiacWheelUpdateIcon({
    super.key,
    required this.updating,
    this.dimmed = false,
  });

  @override
  State<ZodiacWheelUpdateIcon> createState() => _ZodiacWheelUpdateIconState();
}

class _ZodiacWheelUpdateIconState extends State<ZodiacWheelUpdateIcon>
    with TickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 9000),
  );
  late final AnimationController _star = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  void didUpdateWidget(ZodiacWheelUpdateIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updating == oldWidget.updating) return;
    if (widget.updating) {
      _ring.repeat();
      _star.repeat();
    } else {
      // Finish the current revolution on both layers, then park.
      for (final (controller, periodMs) in [(_ring, 9000), (_star, 6000)]) {
        final remaining = (1 - controller.value) * periodMs;
        controller
            .animateTo(1, duration: Duration(milliseconds: remaining.round()))
            .whenComplete(() {
              if (mounted && !widget.updating) controller.value = 0;
            });
      }
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    _star.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([_ring, _star]),
      builder: (_, _) => CustomPaint(
        size: const Size.square(26),
        painter: _ZodiacWheelPainter(
          ringAngle: _ring.value * 2 * math.pi,
          starAngle: -_star.value * 2 * math.pi,
          deep: colorScheme.primary,
          light: colorScheme.secondary,
          dimmed: widget.dimmed,
        ),
      ),
    );
  }
}

/// The twelve sign glyphs in zodiac order, one per wheel sector.
const List<String> _zodiacGlyphs = [
  '♈',
  '♉',
  '♊',
  '♋',
  '♌',
  '♍',
  '♎',
  '♏',
  '♐',
  '♑',
  '♒',
  '♓',
];

class _ZodiacWheelPainter extends CustomPainter {
  final double ringAngle;
  final double starAngle;
  final Color deep;
  final Color light;
  final bool dimmed;

  const _ZodiacWheelPainter({
    required this.ringAngle,
    required this.starAngle,
    required this.deep,
    required this.light,
    required this.dimmed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fade = dimmed ? 0.38 : 1.0;
    final center = Offset(size.width / 2, size.height / 2);
    const rimRadius = 12.3;
    const bandInner = 8.7;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // --- Glyph ring (rotates) ---
    canvas.save();
    canvas.rotate(ringAngle);
    canvas.drawCircle(
      Offset.zero,
      rimRadius,
      Paint()
        ..color = deep.withValues(alpha: 0.85 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset.zero,
      bandInner,
      Paint()
        ..color = deep.withValues(alpha: 0.7 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    final dividerPaint = Paint()
      ..color = deep.withValues(alpha: 0.55 * fade)
      ..strokeWidth = 0.7;
    for (var i = 0; i < 12; i++) {
      final a = (i * 30 + 15) * math.pi / 180;
      canvas.drawLine(
        Offset(math.cos(a), math.sin(a)) * bandInner,
        Offset(math.cos(a), math.sin(a)) * rimRadius,
        dividerPaint,
      );
      // Gem dot seated on the rim at each divider.
      canvas.drawCircle(
        Offset(math.cos(a), math.sin(a)) * rimRadius,
        0.55,
        Paint()..color = light.withValues(alpha: 0.9 * fade),
      );
    }
    for (var i = 0; i < 12; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 6);
      canvas.translate(0, -10.5);
      final glyph = TextPainter(
        text: TextSpan(
          text: _zodiacGlyphs[i],
          style: TextStyle(
            fontSize: 4.6,
            fontWeight: FontWeight.w700,
            color: deep.withValues(alpha: 0.9 * fade),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height / 2));
      canvas.restore();
    }
    canvas.restore();

    // --- Inner machinery ring + compass star (counter-rotates) ---
    canvas.save();
    canvas.rotate(starAngle);
    canvas.drawCircle(
      Offset.zero,
      5.6,
      Paint()
        ..color = deep.withValues(alpha: 0.5 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawCircle(
        Offset(math.cos(a), math.sin(a)) * 5.6,
        0.4,
        Paint()..color = deep.withValues(alpha: 0.5 * fade),
      );
    }
    final star = Path();
    for (var k = 0; k < 16; k++) {
      final a = k * math.pi / 8;
      final r = k.isOdd ? 1.75 : (k % 4 == 0 ? 4.9 : 3.6);
      final point = Offset(math.cos(a), math.sin(a)) * r;
      if (k == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..shader = LinearGradient(
          colors: [
            light.withValues(alpha: fade),
            deep.withValues(alpha: fade),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(-5, -5, 10, 10)),
    );
    canvas.drawPath(
      star,
      Paint()
        ..color = deep.withValues(alpha: 0.65 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    canvas.drawCircle(
      Offset.zero,
      1.2,
      Paint()..color = light.withValues(alpha: fade),
    );
    canvas.drawCircle(
      Offset.zero,
      0.55,
      Paint()..color = deep.withValues(alpha: fade),
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ZodiacWheelPainter oldDelegate) =>
      ringAngle != oldDelegate.ringAngle ||
      starAngle != oldDelegate.starAngle ||
      deep != oldDelegate.deep ||
      light != oldDelegate.light ||
      dimmed != oldDelegate.dimmed;
}

/// Subscription usage segment bar, shared with the profile switch
/// sheet's items.
class UsageSegmentBar extends StatelessWidget {
  final List<double> segments;
  final double height;

  const UsageSegmentBar({
    super.key,
    required this.segments,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, segment) in segments.indexed) ...[
          if (index > 0) const SizedBox(width: 3),
          Expanded(
            child: _UsageBar(value: segment, height: height),
          ),
        ],
      ],
    );
  }
}

class _UsageBar extends StatelessWidget {
  final double value;
  final double height;

  const _UsageBar({required this.value, required this.height});

  // Lucian UX/UI Prompt #299 · MIT License — the spec's warning
  // orange and limit red for a usage meter nearing its cap.
  static const warningColor = Color(0xFFF59E0B);
  static const criticalColor = Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    final radius = BorderRadius.circular(height / 2);
    final level = usageWarningLevel(value);
    final targetColor = switch (level) {
      UsageWarningLevel.normal => primary,
      UsageWarningLevel.warning => warningColor,
      UsageWarningLevel.critical => criticalColor,
    };
    // Spec motion: the fill grows over 600ms on
    // cubic-bezier(.3,1,.4,1) and its colour cross-fades over
    // 400ms when a threshold is crossed.
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        alignment: Alignment.centerLeft,
        color: primary.withValues(alpha: 0.15),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: value),
          duration: const Duration(milliseconds: 600),
          curve: const Cubic(0.3, 1, 0.4, 1),
          builder: (context, animatedValue, _) {
            return TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: targetColor),
              duration: const Duration(milliseconds: 400),
              builder: (context, animatedColor, _) {
                return FractionallySizedBox(
                  widthFactor: animatedValue.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: animatedColor ?? targetColor,
                      borderRadius: radius,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Today's total traffic (bytes) over the same stats query the
/// traffic-stats page runs for its current-day range. Null when
/// the stats feature is off or the core cannot answer: readers
/// show a dash instead of inventing a number. (T337: shared by
/// the today-traffic tile; it lived inside the hero while the
/// hero carried the readouts.)
final todayTrafficProvider = FutureProvider.autoDispose<int?>((ref) async {
  final enabled = ref.watch(
    trafficStatsSettingProvider.select((state) => state.enable),
  );
  if (!enabled) return null;
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final day = '${now.year}-${two(now.month)}-${two(now.day)}';
  try {
    final result = await clashCore.getTrafficStats(start: day, end: day);
    return result.total;
  } catch (_) {
    return null;
  }
});

/// The subscription-remaining presentation: days left coloured
/// by the three-band threshold (T292), the expired word once the
/// plan has lapsed, or the plan's own expiry text when no day
/// count exists.
({String text, Color? color}) subscriptionRemainingPresentation(
  BuildContext context,
  ProfileUsage? usage,
) {
  final tokens = context.starRail;
  final daysLeft = usage?.daysLeft;
  final expired = usage?.isExpired ?? false;
  final color = expired
      ? tokens?.error
      : daysLeft == null
      ? null
      : switch (expiryWarningLevel(daysLeft)) {
          ExpiryWarningLevel.normal => null,
          ExpiryWarningLevel.reminder => tokens?.warning,
          ExpiryWarningLevel.warning => tokens?.error,
        };
  final text = expired
      ? appLocalizations.expired
      : daysLeft != null
      ? '$daysLeft ${appLocalizations.days(daysLeft)}'
      : (usage?.expireText ?? '—');
  return (text: text, color: color);
}

class MiniReadout extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const MiniReadout({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}

class ReadoutTileCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget footnote;
  final VoidCallback? onTap;

  const ReadoutTileCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    required this.footnote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.starRail;
    return CommonCard(
      radius: commonCardRadius,
      onPressed: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color:
                  tokens?.textSecondary ?? context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  valueColor ??
                  tokens?.textPrimary ??
                  context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          footnote,
        ],
      ),
    );
  }
}
