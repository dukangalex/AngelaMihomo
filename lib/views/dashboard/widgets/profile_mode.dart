import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'node_status_light.dart';
import 'profile_info.dart';
import 'quick_options.dart';

const List<double> _emptySegments = [0];

/// The merged home card (T147): the former profile card and the former
/// running-mode card as one dashboard widget, still added, removed and
/// resized as a single grid item. The two zones keep every function of
/// the cards they replace —
///
/// * profile zone: name with the switch-sheet entry, last-update time,
///   subscription usage with its segment bar and the current selection
///   (node name + delay);
/// * mode zone: the node status light, the VPN / system-proxy chips
///   and the rule / global / direct mode switch.
///
/// One speed test only (user directive): the light is the card's sole
/// test trigger and runs the shared global linked delay test (T131,
/// measure-only). The current selection's delay number reads the very
/// same delay data source the light reads, so the two always agree.
/// The upstream per-group test entry the old profile card carried into
/// its group sheet is not part of this card. The card carries no
/// refresh action either (T149): subscription refresh lives on the
/// profiles page, because a refresh makes the core re-test delays
/// through the upstream path and would read as a second test entry
/// on this card.
///
/// Layout (T286, user directive: every item fully visible, nothing
/// ellipsized): the profile zone stacks its rows — the profile name
/// gets a full-width row of its own (up to two lines); the meta row
/// joins the update time, the expiry and the usage numbers on one
/// wrapping line with the segment bar directly under it; the node
/// pill follows, its first line carrying the status light beside
/// the delay number and the node name on the pill's own full-width
/// second line (superseding the T211 top-right placement of the
/// light, which starved the name row). No field in the card
/// ellipsizes and no font shrinks. The card's height follows its
/// content with the old two-grid-row height as a floor (the
/// dashboard grid fits tiles to their content height), so long
/// names simply make a taller card instead of a clipped one; the
/// empty-profile placeholder keeps the exact fixed-height form it
/// always had.
class ProfileModeCard extends ConsumerWidget {
  final DashboardTileSize? size;

  const ProfileModeCard({super.key, this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = this.size ?? DashboardTileSize.large;
    final tall = size == DashboardTileSize.tall;
    final floor = getWidgetHeight(context, size.rows);
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: 16.ap,
      endIndent: 16.ap,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
    if (ref.watch(currentProfileProvider) == null) {
      return SizedBox(
        height: floor,
        child: CommonCard(
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              const Positioned(top: 0, right: 0, child: _ZodiacWatermark()),
              Column(
                children: [
                  Expanded(child: _ProfileZone(tall: tall)),
                  divider,
                  _ModeZone(tall: tall),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: floor),
      child: CommonCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            const Positioned(top: 0, right: 0, child: _ZodiacWatermark()),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileZone(tall: tall),
                divider,
                _ModeZone(tall: tall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// T294, revised by T296 at the user's direct instruction: the
/// header card's watermark is the theme's zodiac artwork — for the
/// solid zodiac, the animal's HEAD as a sketch portrait — never the
/// sign's name written as a text glyph. It sits at the card's top
/// right, behind every control, never intercepting a tap. The solid
/// animal is composited into its full-canvas image, so the
/// watermark shows that canvas through a square window centred on
/// the head (per-animal windows measured from the artworks
/// themselves; the dark and light canvases share one composition),
/// its patch edges faded so the base-colour block melts into the
/// card. The constellation series shows its guardian figure
/// (pre-faded artwork); deep-space shows its motif. Themes without
/// artwork carry no watermark.
class _ZodiacWatermark extends StatelessWidget {
  const _ZodiacWatermark();

  /// Head windows over the solid canvas, keyed by the artwork's
  /// file stem: (centre x, centre y, side) as canvas fractions,
  /// the side as a fraction of the canvas width (the canvas is
  /// 1440×2880, so the side spans half as much of its height).
  static const _solidHeadWindows = <String, (double, double, double)>{
    'rat': (0.87, 0.755, 0.15),
    'ox': (0.88, 0.545, 0.19),
    'tiger': (0.45, 0.69, 0.17),
    'rabbit': (0.76, 0.66, 0.25),
    'dragon': (0.73, 0.51, 0.18),
    'snake': (0.82, 0.51, 0.14),
    'horse': (0.415, 0.70, 0.16),
    'goat': (0.86, 0.52, 0.21),
    'monkey': (0.83, 0.625, 0.16),
    'rooster': (0.49, 0.53, 0.16),
    'dog': (0.865, 0.645, 0.17),
    'pig': (0.40, 0.70, 0.17),
  };

  @override
  Widget build(BuildContext context) {
    final zodiac = context.zodiac;
    if (zodiac == null) return const SizedBox.shrink();
    final solidPath = zodiac.solidAssetPath;
    if (solidPath != null) {
      final stem = solidPath.split('/').last.replaceAll('.webp', '');
      final head = _solidHeadWindows[stem];
      if (head == null) return const SizedBox.shrink();
      final (cx, cy, side) = head;
      const box = 124.0;
      final imgW = box / side;
      final imgH = imgW * 2;
      return IgnorePointer(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const RadialGradient(
            center: Alignment(0.25, -0.25),
            radius: 0.85,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.55, 1],
          ).createShader(bounds),
          child: SizedBox(
            width: box,
            height: box,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: box / 2 - cx * imgW,
                    top: box / 2 - cy * imgH,
                    width: imgW,
                    height: imgH,
                    child: Image.asset(solidPath, fit: BoxFit.fill),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (zodiac.motif != null) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.4,
          child: CustomPaint(
            size: const Size.square(120),
            painter: DeepSpaceMotifPainter(
              motif: zodiac.motif!,
              variant: zodiac.variant,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
      );
    }
    final guardian = zodiacGuardianForTheme(zodiac.themeId);
    if (guardian == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        opacity: 0.55,
        child: Image.asset(
          guardian.assetPath,
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ProfileZone extends ConsumerWidget {
  final bool tall;

  const _ProfileZone({required this.tall});

  Widget _nameRow(BuildContext context, Profile profile, TextStyle? style) {
    return _TapArea(
      onTap: () => showProfileSwitchSheet(context),
      child: _ProfileName(name: profile.label ?? profile.id, style: style),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final colorScheme = context.colorScheme;
    if (profile == null) {
      return InkWell(
        onTap: () => globalState.appController.toProfiles(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.ap, 8.ap, 16.ap, 8.ap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appLocalizations.profile,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                appLocalizations.nullProfileDesc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final usage = ProfileUsage.of(profile);
    final segments = usage?.segments ?? _emptySegments;
    final subtitle = [
      ?profile.lastUpdateDate?.lastUpdateTimeDesc,
      // T223: on a merged profile the expiry belongs to one source
      // (ProfileUsage.primaryEntry); name that source on the same
      // line so the date is not mistaken for another subscription's.
      ?usage?.primarySourceName,
      ?profile.usageExpireText(usage),
    ].join(' · ');
    // Stacked rows (T286): every item gets the full card width, so
    // no field ever has to ellipsize — the name row (up to two
    // lines), the meta line joining update time, expiry and the
    // usage numbers as one combined text (T288), the usage segment bar
    // directly under that row, then the node pill carrying the
    // status light.
    return Padding(
      padding: EdgeInsets.fromLTRB(16.ap, 6.ap, 16.ap, 6.ap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // T292: the static description icon is now a tappable
              // "update current profile" button. It reuses
              // refreshProfileSubscription (profile_info.dart), which
              // already routes by config type (bundle regenerate /
              // url fetch / external provider refresh) — no new
              // update logic here.
              _UpdateProfileButton(profile: profile),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _nameRow(
                    context,
                    profile,
                    context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (tall) ...[
                const SizedBox(width: 8),
                const NodeStatusLight(compact: true),
              ],
            ],
          ),
          const SizedBox(height: 2),
          _SubtitleUsageRow(subtitle: subtitle, usage: usage),
          if (tall) ...[
            const SizedBox(height: 2),
            const _CurrentNode(style: _NodeStyle.plain),
          ] else ...[
            if (segments.isNotEmpty) ...[
              const SizedBox(height: 4),
              UsageSegmentBar(segments: segments, height: 4),
            ],
            const SizedBox(height: 8),
            const _CurrentNodeRow(),
          ],
        ],
      ),
    );
  }
}

/// T292: the current profile card's leading update button, replacing
/// the old static description icon. It routes the tap to
/// refreshProfileSubscription (profile_info.dart), which already
/// handles every config kind — bundle regenerate, url re-fetch,
/// external-provider update — so this button adds no update logic of
/// its own.
///
/// States: while the profile reports isUpdating the button shrinks to
/// a small spinner and is disabled so a second tap cannot double-fire;
/// a file profile with no external providers has nothing to refresh,
/// so it is shown disabled (onPressed null).
class _UpdateProfileButton extends ConsumerWidget {
  final Profile profile;

  const _UpdateProfileButton({required this.profile});

  bool get _canRefresh {
    if (profile.isUpdating) return false;
    // A plain local file with no external providers has nothing to
    // refresh — the button is greyed out for it.
    if (profile.type == ProfileType.file &&
        profile.providerSubscriptions.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRefresh = _canRefresh;
    final colorScheme = context.colorScheme;
    final updating = profile.isUpdating;
    final color = canRefresh
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
    return IconButton(
      onPressed: canRefresh
          ? () => refreshProfileSubscription(context, ref, profile)
          : null,
      tooltip: appLocalizations.update,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
        maxWidth: 28,
        maxHeight: 28,
      ),
      icon: updating
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Icon(Icons.refresh_rounded, size: 20, color: color),
    );
  }
}

/// The meta line under the profile name (T286): last-update time,
/// expiry and the subscription usage presented as one line —
/// "time · expire · used / total".
///
/// T288: the line is a single combined [Text], not separate chunks
/// in a Wrap. The Wrap form laid the subtitle and the usage out as
/// two atomic boxes — the usage typeset larger (labelMedium) than
/// the subtitle (labelSmall) — so whenever the two boxes plus the
/// Wrap spacing exceeded the card width, the whole usage box was
/// pushed to a second line even though the same words as one
/// flowing text fit on the line (the user's phone hit exactly
/// that). As one text the line takes the full card width, stays on
/// one line whenever the words fit, and wraps only at natural text
/// break points when they genuinely do not; nothing ellipsizes or
/// shrinks, and the usage segment bar sits directly under the line
/// so the numbers and their bar stay adjacent.
class _SubtitleUsageRow extends StatelessWidget {
  final String subtitle;
  final ProfileUsage? usage;

  const _SubtitleUsageRow({required this.subtitle, required this.usage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final usage = this.usage;
    return Text(
      [
        if (subtitle.isNotEmpty) subtitle,
        // T223: the figure is cardUsageText, so on a merged profile
        // it describes the same source as the expiry beside it.
        usage?.cardUsageText ?? appLocalizations.noUsageData,
      ].join(' · '),
      style: context.textTheme.labelSmall?.copyWith(
        color: usage?.isExpired == true
            ? colorScheme.error
            : colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _ModeZone extends StatelessWidget {
  final bool tall;

  const _ModeZone({required this.tall});

  @override
  Widget build(BuildContext context) {
    // The status light lives in the profile zone's node row (T286),
    // so this header row carries only the mode label and, in the wide
    // form, the status chips; the segmented mode switch is shared
    // with the tall form, which does not repeat the chips.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InfoHeader(
          padding: EdgeInsets.fromLTRB(16.ap, 6.ap, 12.ap, 0),
          info: Info(
            label: appLocalizations.runningMode,
            iconData: Icons.call_split_sharp,
          ),
          actions: tall ? const [] : const [_OutboundStatusChips()],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(10.ap, 4.ap, 10.ap, 6.ap),
          child: SizedBox(
            height: 34.ap,
            child: Consumer(
              builder: (_, ref, _) {
                final mode = ref.watch(
                  patchClashConfigProvider.select((state) => state.mode),
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in Mode.values) ...[
                      if (item != Mode.values.first) const SizedBox(width: 2),
                      Expanded(
                        child: _OutboundModeButton(
                          mode: item,
                          selected: item == mode,
                          first: item == Mode.values.first,
                          last: item == Mode.values.last,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _OutboundModeButton extends StatelessWidget {
  final Mode mode;
  final bool selected;
  final bool first;
  final bool last;

  const _OutboundModeButton({
    required this.mode,
    required this.selected,
    required this.first,
    required this.last,
  });

  IconData get _icon => switch (mode) {
    Mode.rule => Icons.list_alt_rounded,
    Mode.global => Icons.language_rounded,
    Mode.direct => Icons.east_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.82);
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = Radius.circular(constraints.maxHeight / 2);
        const inner = Radius.circular(8);
        final shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: selected || first ? full : inner,
            right: selected || last ? full : inner,
          ),
        );
        return Focus(
          child: Builder(
            builder: (context) {
              final isFocused =
                  globalState.isAndroidTV && Focus.of(context).hasFocus;
              return AnimatedContainer(
                duration: midDuration,
                curve: Curves.easeOutCubic,
                decoration: ShapeDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(
                          alpha: isLight ? 0.12 : 0.20,
                        )
                      : colorScheme.onSurface.withValues(
                          alpha: isLight ? 0.04 : 0.06,
                        ),
                  shape: shape.copyWith(
                    side: isFocused
                        ? BorderSide(color: colorScheme.primary, width: 2)
                        : BorderSide.none,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: shape,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => globalState.appController.changeMode(mode),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icon, size: 17, color: foreground),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Intl.message(mode.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: foreground,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _OutboundStatusChips extends ConsumerWidget {
  const _OutboundStatusChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStart = ref.watch(runTimeProvider.select((value) => value != null));
    final realTunEnable = ref.watch(realTunEnableProvider);
    final (tunEnable, systemProxyEnable) = system.isAndroid
        ? ref.watch(
            vpnSettingProvider.select(
              (state) => (state.enable, state.systemProxy),
            ),
          )
        : (
            ref.watch(
              patchClashConfigProvider.select((state) => state.tun.enable),
            ),
            ref.watch(
              networkSettingProvider.select((state) => state.systemProxy),
            ),
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusChip(
          label: system.isAndroid ? 'VPN' : 'TUN',
          active: isStart && tunEnable && (system.isAndroid || realTunEnable),
          onTap: () =>
              system.isAndroid ? showVpnSheet(context) : showTunSheet(context),
        ),
        const SizedBox(width: 6),
        _StatusChip(
          label: appLocalizations.systemProxy,
          active: isStart && systemProxyEnable,
          onTap: () => showSystemProxySheet(context),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final color = active
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.55);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: midDuration,
          padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
          decoration: BoxDecoration(
            color: active
                ? colorScheme.primary.withValues(alpha: isLight ? 0.12 : 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? colorScheme.primary.withValues(alpha: isLight ? 0.28 : 0.36)
                  : colorScheme.outlineVariant.withValues(
                      alpha: isLight ? 0.9 : 0.6,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: midDuration,
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: active
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapArea extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _TapArea({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return Transform.translate(
      offset: const Offset(-6, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProfileName extends StatelessWidget {
  final String name;
  final TextStyle? style;

  const _ProfileName({required this.name, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          // T286: the name wraps to a second line instead of
          // ellipsizing — it is the card's primary label and the
          // switch-sheet entry, so it always reads in full.
          child: EmojiText(name, maxLines: 2, style: style),
        ),
        const SizedBox(width: 2),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.unfold_more,
            size: 16,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

enum _NodeStyle { pill, grouped, plain }

class _CurrentNode extends ConsumerWidget {
  final _NodeStyle style;

  const _CurrentNode({required this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDirect = ref.watch(
      patchClashConfigProvider.select((state) => state.mode == Mode.direct),
    );
    final groupName = ref.watch(currentMainGroupNameProvider);
    if (isDirect) {
      return _NodeLabel(style: style, nodeName: appLocalizations.direct);
    }
    if (groupName == null) return const SizedBox.shrink();
    return _GroupNode(style: style, groupName: groupName);
  }
}

class _GroupNode extends ConsumerWidget {
  final _NodeStyle style;
  final String groupName;

  const _GroupNode({required this.style, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeName = ref.watch(
      getProxyCardStateProvider(groupName).select((state) => state.proxyName),
    );
    // The one shared delay data source: the same getDelayProvider the
    // status light reads, fed by the global linked test (T131).
    final delay = ref.watch(getDelayProvider(proxyName: groupName));
    return _NodeLabel(
      style: style,
      nodeName: nodeName,
      delay: delay,
      onTap: () => showGroupProxySheet(context, groupName),
    );
  }
}

/// Full-width node row of the wide merged card (T286): inside the
/// pill that opens the group sheet, the status light and the delay
/// number share the first line (they read the same data source, so
/// they belong together) and the current node name gets the pill's
/// whole second line, wrapping to two lines when long — it never
/// ellipsizes and never has to fight the light for width. The light
/// keeps its own tap (the card's sole delay-test trigger); the rest
/// of the pill opens the group sheet, exactly as the old
/// right-aligned pill did.
///
/// Round 2 (user screenshot): the light's label was ellipsized
/// ("当前节...") because the light sat in a Flexible beside a
/// Spacer — flex split the leftover width evenly between them, so
/// the label only ever got half of what was free. The light now
/// takes the whole row minus the delay's intrinsic width (the most
/// any layout can give it) and the delay keeps its intrinsic width
/// at the right edge, so the label renders in full at any realistic
/// width; the light's own ellipsis remains only as a guard for
/// widths where label + delay physically exceed the row. The
/// pill's bottom padding is deeper than its top (8 vs 5) so Latin
/// descenders in the node name keep clear of the pill's edge with
/// fonts whose ink runs past the descent metric.
class _CurrentNodeRow extends ConsumerWidget {
  const _CurrentNodeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDirect = ref.watch(
      patchClashConfigProvider.select((state) => state.mode == Mode.direct),
    );
    final groupName = ref.watch(currentMainGroupNameProvider);
    if (!isDirect && groupName == null) {
      // No selection to label yet: the light still stands (and stays
      // tappable) without the pill around it.
      return const Align(
        alignment: AlignmentDirectional.centerStart,
        child: NodeStatusLight(),
      );
    }
    return _NodePillRow(groupName: groupName, direct: isDirect);
  }
}

class _NodePillRow extends ConsumerWidget {
  final String? groupName;
  final bool direct;

  const _NodePillRow({required this.groupName, required this.direct});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = context.colorScheme;
    final String nodeName;
    int? delay;
    if (direct) {
      nodeName = appLocalizations.direct;
    } else {
      nodeName = ref.watch(
        getProxyCardStateProvider(
          groupName!,
        ).select((state) => state.proxyName),
      );
      // The one shared delay data source: the same getDelayProvider
      // the status light reads, fed by the global linked test (T131).
      delay = ref.watch(getDelayProvider(proxyName: groupName!));
    }
    final delayValue = delay;
    final radius = BorderRadius.circular(10);
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: direct ? null : () => showGroupProxySheet(context, groupName!),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(child: NodeStatusLight()),
                  if (delayValue != null)
                    Text(
                      delayValue > 0 ? '$delayValue ms' : 'Timeout',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: zodiacDelayColor(
                          context.zodiac?.variant,
                          delayValue,
                        ),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              EmojiText(
                nodeName,
                maxLines: 2,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  final _NodeStyle style;
  final String nodeName;
  final int? delay;
  final VoidCallback? onTap;

  const _NodeLabel({
    required this.style,
    required this.nodeName,
    this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final delay = this.delay;
    final isPlain = style == _NodeStyle.plain;
    final row = Row(
      mainAxisSize: style == _NodeStyle.pill
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: [
        if (style == _NodeStyle.grouped) ...[
          Text(
            appLocalizations.currentSelection,
            style: context.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
        Flexible(
          fit: isPlain ? FlexFit.tight : FlexFit.loose,
          child: EmojiText(
            nodeName,
            maxLines: 2,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: isPlain ? null : FontWeight.w600,
            ),
          ),
        ),
        if (delay != null) ...[
          const SizedBox(width: 8),
          Text(
            delay > 0 ? '$delay ms' : 'Timeout',
            style: context.textTheme.labelSmall?.copyWith(
              color: zodiacDelayColor(context.zodiac?.variant, delay),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
    if (isPlain) return _TapArea(onTap: onTap, child: row);
    final radius = BorderRadius.circular(10);
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: row,
        ),
      ),
    );
  }
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
