import 'dart:async';
import 'dart:math' as math;

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/pages/speed_test.dart';
import 'package:angelamihomo/pages/toolbox/traffic_stats.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/profiles/add_profile.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_info.dart';
import 'profile_mode.dart';
import 'quick_options.dart';

/// T334 batch 2: the star-rail home hero that heads the dashboard,
/// above the (unchanged) editable widget grid. Frozen design:
/// files/ui-redesign/DESIGN-LANGUAGE.md, screen 1 — a multi-ring
/// orbit whose core is the connection switch, ring dots carrying
/// the real exit / chain state, then plain-word readouts fed by the
/// very same providers the dashboard tiles already read.
///
/// Nothing here owns business logic: the core's tap and long-press
/// run the start button's exact calls (appController.updateStatus /
/// restartCore over the same selector providers), the speed-test
/// button opens the same SpeedTestPage the network-speed tile
/// opens, the subscription card reuses the merged card's refresh
/// and switch-sheet helpers, and every number below is read from an
/// existing provider — the hero is a relocation of the dashboard's
/// existing capabilities, never a second implementation of them.
class OrbitHomeHero extends ConsumerStatefulWidget {
  const OrbitHomeHero({super.key});

  @override
  ConsumerState<OrbitHomeHero> createState() => _OrbitHomeHeroState();
}

class _OrbitHomeHeroState extends ConsumerState<OrbitHomeHero> {
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    // Same live cadence the traffic stats page keeps for its
    // current-day view: today's total is re-asked every 30 s.
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(_todayTrafficProvider);
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusPills(),
        SizedBox(height: 8),
        _OrbitCore(),
        SizedBox(height: 16),
        _ReadoutRow(),
        SizedBox(height: 12),
        _SpeedCard(),
        SizedBox(height: 12),
        _SubscriptionCard(),
      ],
    );
  }
}

/// Today's recorded traffic (upload + download bytes) from the
/// core's traffic stats — the same query the traffic stats page
/// runs for its current-day range. Null when the stats feature is
/// off or the core cannot answer: the readout then shows a dash
/// instead of inventing a number.
final _todayTrafficProvider = FutureProvider.autoDispose<int?>((ref) async {
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

// ---------------------------------------------------------------------------
// Status pills: run state on the left, mode + live delay on the right.
// ---------------------------------------------------------------------------

class _StatusPills extends ConsumerWidget {
  const _StatusPills();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.starRail;
    final colorScheme = context.colorScheme;
    final state = ref.watch(startButtonSelectorStateProvider);
    final isSmartStopped = ref.watch(isSmartStoppedProvider);
    final isStart = ref.watch(runTimeProvider.select((time) => time != null));
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
    final groupName = mode == Mode.direct
        ? null
        : ref.watch(currentMainGroupNameProvider);
    final delay = groupName == null
        ? null
        : ref.watch(getDelayProvider(proxyName: groupName));

    final (dotColor, stateText) = isSmartStopped
        ? (colorScheme.outline, appLocalizations.coreSuspended)
        : state.isInit && !state.hasProfile
        ? (colorScheme.outline, appLocalizations.checkOrAddProfile)
        : isStart
        ? (
            tokens?.secondary ?? colorScheme.primary,
            appLocalizations.coreConnected,
          )
        : (colorScheme.outline, appLocalizations.serviceReady);

    return Row(
      children: [
        _Pill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stateText,
                style: context.textTheme.labelSmall?.copyWith(
                  color: tokens?.textPrimary ?? colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _Pill(
          onTap: () => showOutboundModeSheet(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                switch (mode) {
                  Mode.rule => Icons.alt_route_rounded,
                  Mode.global => Icons.language_rounded,
                  Mode.direct => Icons.east_rounded,
                },
                size: 14,
                color: tokens?.textSecondary ?? colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                Intl.message(mode.name),
                style: context.textTheme.labelSmall?.copyWith(
                  color: tokens?.textPrimary ?? colorScheme.onSurface,
                ),
              ),
              if (delay != null && delay > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$delay ms',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: tokens?.secondary ?? colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Pill({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.starRail;
    final decoration = BoxDecoration(
      color: (tokens?.surface ?? context.colorScheme.surfaceContainerHigh)
          .withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(StarRailRadius.pill),
      border: Border.all(
        color: (tokens?.glowLine ?? Colors.white).withValues(alpha: 0.14),
      ),
    );
    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: child,
    );
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: padded);
    }
    return DecoratedBox(
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(StarRailRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: padded),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The orbit: rings + dots painted, the core is the connection switch.
// ---------------------------------------------------------------------------

/// Ring radii as fractions of the orbit's half-size, outermost first.
const orbitRingFractions = [0.97, 0.80, 0.63];

/// Radius of the tappable core, as a fraction of the half-size.
const orbitCoreFraction = 0.46;

/// Where a dot sits on its ring: [angle] in radians, standard
/// canvas orientation (0 = east, positive angles clockwise).
Offset orbitDotOffset(Size size, double radiusFraction, double angle) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) / 2 * radiusFraction;
  return center + Offset(math.cos(angle), math.sin(angle)) * radius;
}

/// The exit dot starts at the top of the outer ring and travels
/// with the rotation phase.
double orbitExitAngle(double phase) => -math.pi / 2 + phase * 2 * math.pi;

/// The chain dot rides the middle ring, offset from the exit dot
/// so the two hops never overlap at phase 0.
double orbitChainAngle(double phase) => math.pi * 0.78 + phase * 2 * math.pi;

class OrbitPainter extends CustomPainter {
  final double phase;
  final bool active;
  final bool hasChain;
  final Color glowLine;
  final Color primary;
  final Color secondary;

  const OrbitPainter({
    required this.phase,
    required this.active,
    required this.hasChain,
    required this.glowLine,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final half = math.min(size.width, size.height) / 2;

    // Soft lit field behind the core while traffic flows.
    if (active) {
      canvas.drawCircle(
        center,
        half * orbitCoreFraction * 1.25,
        Paint()..color = secondary.withValues(alpha: 0.07),
      );
    }

    const ringAlphas = [0.45, 0.26, 0.38];
    for (final (index, fraction) in orbitRingFractions.indexed) {
      canvas.drawCircle(
        center,
        half * fraction,
        Paint()
          ..color = glowLine.withValues(
            alpha: active ? ringAlphas[index] : 0.10,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == 0 ? 1.8 : 1.4,
      );
    }

    // Instrument ticks on the outer ring (no numerals — the ring
    // is a state carrier, not a dial to read).
    final tickPaint = Paint()
      ..color = glowLine.withValues(alpha: active ? 0.30 : 0.10)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final outer = orbitDotOffset(size, orbitRingFractions[0], angle);
      final inner = orbitDotOffset(
        size,
        orbitRingFractions[0] - (i % 6 == 0 ? 0.055 : 0.03),
        angle,
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    void dot(double fraction, double angle, Color color) {
      final offset = orbitDotOffset(size, fraction, angle);
      if (active) {
        canvas.drawCircle(
          offset,
          8,
          Paint()..color = color.withValues(alpha: 0.22),
        );
      }
      canvas.drawCircle(
        offset,
        3.6,
        Paint()..color = color.withValues(alpha: active ? 1 : 0.35),
      );
    }

    dot(orbitRingFractions[0], orbitExitAngle(phase), secondary);
    if (hasChain) {
      dot(orbitRingFractions[1], orbitChainAngle(phase), primary);
    }
  }

  @override
  bool shouldRepaint(OrbitPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.active != active ||
      oldDelegate.hasChain != hasChain ||
      oldDelegate.glowLine != glowLine ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}

class _OrbitRings extends StatefulWidget {
  final bool rotating;
  final bool active;
  final bool hasChain;
  final StarRailTokens tokens;

  const _OrbitRings({
    required this.rotating,
    required this.active,
    required this.hasChain,
    required this.tokens,
  });

  @override
  State<_OrbitRings> createState() => _OrbitRingsState();
}

class _OrbitRingsState extends State<_OrbitRings>
    with SingleTickerProviderStateMixin {
  // One revolution per 90 s: the slowest motion that still reads
  // as an orbit. The controller is the hero's only continuous
  // animation; it runs solely while connected, on-screen
  // (TickerMode) and allowed by the system reduce-motion setting —
  // in every other state the painter is fully static.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  );

  @override
  void initState() {
    super.initState();
    if (widget.rotating) _controller.repeat();
  }

  @override
  void didUpdateWidget(_OrbitRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rotating == oldWidget.rotating) return;
    if (widget.rotating) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => CustomPaint(
          painter: OrbitPainter(
            phase: _controller.value,
            active: widget.active,
            hasChain: widget.hasChain,
            glowLine: widget.tokens.glowLine,
            primary: widget.tokens.primary,
            secondary: widget.tokens.secondary,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _OrbitCore extends ConsumerStatefulWidget {
  const _OrbitCore();

  @override
  ConsumerState<_OrbitCore> createState() => _OrbitCoreState();
}

class _OrbitCoreState extends ConsumerState<_OrbitCore> {
  // The start button's exact interaction state pattern: presses are
  // locked while a toggle is in flight and the core shows the
  // optimistic state until the real provider lands.
  bool _isDisabled = false;
  bool? _optimisticStart;

  void _handleStart() async {
    if (_isDisabled) return;
    final newState =
        ref.read(isSmartStoppedProvider) || ref.read(runTimeProvider) == null;
    setState(() {
      _isDisabled = true;
      _optimisticStart = newState;
    });
    try {
      await globalState.appController.updateStatus(newState);
    } catch (e) {
      commonPrint.error('updateStatus failed: $e');
      globalState.showNotifier(serviceToggleFailureNotice(e));
    } finally {
      if (mounted) {
        setState(() {
          _isDisabled = false;
          _optimisticStart = null;
        });
      }
    }
  }

  Future<void> _handleLongPress() async {
    final isStart = ref.read(runTimeProvider) != null;
    if (!isStart) return;
    final result = await globalState.showMessage(
      title: appLocalizations.restartCoreTitle,
      message: TextSpan(text: appLocalizations.restartCoreDesc),
    );
    if (result == true) {
      await globalState.appController.restartCore();
      globalState.showNotifier(appLocalizations.success);
    }
  }

  void _handleShowAddProfile() {
    showExtend(
      context,
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          body: AddProfileView(context: context),
          title: appLocalizations.add,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(startButtonSelectorStateProvider);
    final isSmartStopped = ref.watch(isSmartStoppedProvider);
    final isRestarting = ref.watch(isRestartingCoreProvider);
    final isStart = ref.watch(runTimeProvider.select((time) => time != null));
    final displayStart = isSmartStopped ? false : (_optimisticStart ?? isStart);
    final canPress = state.isInit && state.hasProfile && !_isDisabled;
    final hasNoProfile =
        state.isInit && !state.hasProfile && !_isDisabled && !isSmartStopped;

    final profile = ref.watch(currentProfileProvider);
    final chainHealth = ref.watch(chainCardHealthProvider).value;
    final hasChain =
        profile != null && (chainHealth?.containsKey(profile.id) ?? false);

    final tokens =
        context.starRail ??
        StarRailTokens.forBrightness(Theme.of(context).brightness);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final onScreen = TickerMode.valuesOf(context).enabled;
    final rotating = displayStart && !reduceMotion && onScreen;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = math.min(constraints.maxWidth, 320.0);
          final coreDiameter = diameter * orbitCoreFraction;
          return SizedBox.square(
            dimension: diameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: _OrbitRings(
                    rotating: rotating,
                    active: displayStart,
                    hasChain: hasChain,
                    tokens: tokens,
                  ),
                ),
                Container(
                  width: coreDiameter,
                  height: coreDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.surface.withValues(alpha: 0.92),
                    border: Border.all(
                      color: displayStart
                          ? tokens.secondary.withValues(alpha: 0.65)
                          : tokens.glowLine.withValues(alpha: 0.18),
                      width: 1.6,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: canPress
                          ? _handleStart
                          : hasNoProfile
                          ? _handleShowAddProfile
                          : null,
                      onLongPress: canPress && !isSmartStopped
                          ? _handleLongPress
                          : null,
                      child: _CoreContent(
                        state: state,
                        displayStart: displayStart,
                        isRestarting: isRestarting,
                        isDisabled: _isDisabled,
                        isSmartStopped: isSmartStopped,
                        tokens: tokens,
                        runTime: () => ref.read(runTimeProvider),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CoreContent extends StatelessWidget {
  final StartButtonSelectorState state;
  final bool displayStart;
  final bool isRestarting;
  final bool isDisabled;
  final bool isSmartStopped;
  final StarRailTokens tokens;
  final int? Function() runTime;

  const _CoreContent({
    required this.state,
    required this.displayStart,
    required this.isRestarting,
    required this.isDisabled,
    required this.isSmartStopped,
    required this.tokens,
    required this.runTime,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    if (isSmartStopped) {
      return _CoreLabel(
        icon: Icons.pause_circle_outline,
        iconColor: colorScheme.outline,
        text: appLocalizations.coreSuspended,
        textColor: colorScheme.outline,
      );
    }
    if (!state.isInit || isDisabled || isRestarting) {
      return Center(
        child: SpinKitThreeBounce(color: tokens.secondary, size: 20),
      );
    }
    if (!state.hasProfile) {
      return _CoreLabel(
        icon: Icons.power_settings_new,
        iconColor: colorScheme.onSurfaceVariant,
        text: appLocalizations.checkOrAddProfile,
        textColor: tokens.textSecondary,
      );
    }
    if (!displayStart) {
      return _CoreLabel(
        icon: Icons.power_settings_new,
        iconColor: colorScheme.onSurfaceVariant,
        text: appLocalizations.serviceReady,
        textColor: tokens.textSecondary,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.power_settings_new, size: 34, color: tokens.secondary),
        const SizedBox(height: 6),
        Text(
          appLocalizations.coreConnected,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        // Same 1 s tick the start button's runtime readout uses.
        ValueListenableBuilder<int>(
          valueListenable: dashboardRefreshManager.tick1s,
          builder: (_, _, _) => Text(
            _formatRunTime(runTime()),
            style: context.textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoreLabel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  const _CoreLabel({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: iconColor),
          const SizedBox(height: 6),
          Text(
            text,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Readout cards: exit + mode, then speeds with today / subscription.
// ---------------------------------------------------------------------------

class _ReadoutRow extends ConsumerWidget {
  const _ReadoutRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
    final isDirect = mode == Mode.direct;
    final groupName = isDirect ? null : ref.watch(currentMainGroupNameProvider);
    final nodeName = isDirect
        ? appLocalizations.direct
        : groupName == null
        ? ''
        : ref.watch(
            getProxyCardStateProvider(
              groupName,
            ).select((state) => state.proxyName),
          );
    final delay = groupName == null
        ? null
        : ref.watch(getDelayProvider(proxyName: groupName));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ReadoutCard(
            label: appLocalizations.speedTestExitNode,
            value: nodeName,
            footnote: const _ExitRegion(),
            onTap: groupName == null
                ? null
                : () => showGroupProxySheet(context, groupName),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ReadoutCard(
            label: appLocalizations.outboundMode,
            value: Intl.message(mode.name),
            footnote: Text(
              delay == null
                  ? ''
                  : delay > 0
                  ? '$delay ms'
                  : 'Timeout',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            onTap: () => showOutboundModeSheet(context),
          ),
        ),
      ],
    );
  }
}

/// The exit's region as the network detection last resolved it
/// (country · city) — the same DetectionState the network
/// detection tile renders. Empty until a check has landed.
class _ExitRegion extends StatelessWidget {
  const _ExitRegion();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NetworkDetectionState>(
      valueListenable: detectionState.state,
      builder: (_, state, _) {
        final ipInfo = state.ipInfo;
        final location = ipInfo == null
            ? ''
            : [
                ipInfo.country,
                if (ipInfo.city != ipInfo.country) ipInfo.city,
              ].where((item) => item?.isNotEmpty ?? false).join(' · ');
        return Text(
          location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

class _ReadoutCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget footnote;
  final VoidCallback? onTap;

  const _ReadoutCard({
    required this.label,
    required this.value,
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
              color: tokens?.textPrimary ?? context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          footnote,
        ],
      ),
    );
  }
}

class _SpeedCard extends ConsumerWidget {
  const _SpeedCard();

  Widget _speedBlock(
    BuildContext context, {
    required IconData icon,
    required String label,
    required TrafficValue value,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.showValue,
              style: context.textTheme.headlineSmall?.merge(
                StarRailType.readout,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${value.showUnit}/s',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.starRail;
    final todayTraffic = ref.watch(_todayTrafficProvider).value;
    final profile = ref.watch(currentProfileProvider);
    final usage = profile == null ? null : ProfileUsage.of(profile);
    final daysLeft = usage?.daysLeft;
    final expired = usage?.isExpired ?? false;

    final expiryColor = expired
        ? tokens?.error
        : daysLeft == null
        ? null
        : switch (expiryWarningLevel(daysLeft)) {
            ExpiryWarningLevel.normal => null,
            ExpiryWarningLevel.reminder => tokens?.warning,
            ExpiryWarningLevel.warning => tokens?.error,
          };
    final expiryText = expired
        ? appLocalizations.expired
        : daysLeft != null
        ? '$daysLeft ${appLocalizations.days(daysLeft)}'
        : (usage?.expireText ?? '—');

    return CommonCard(
      radius: commonCardRadius,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: dashboardRefreshManager.tick1s,
            builder: (_, _, _) {
              final traffics = ref.read(trafficsProvider).list;
              final traffic = traffics.isEmpty ? Traffic() : traffics.last;
              return Row(
                children: [
                  Expanded(
                    child: _speedBlock(
                      context,
                      icon: Icons.arrow_downward_rounded,
                      label: appLocalizations.downloadSpeed,
                      value: traffic.down,
                      accent: tokens?.secondary ?? context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _speedBlock(
                      context,
                      icon: Icons.arrow_upward_rounded,
                      label: appLocalizations.uploadSpeed,
                      value: traffic.up,
                      accent: tokens?.primary ?? context.colorScheme.secondary,
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniReadout(
                  label: appLocalizations.todayTraffic,
                  value: todayTraffic == null
                      ? '—'
                      : TrafficValue(value: todayTraffic).show,
                  onTap: () =>
                      BaseNavigator.push(context, const TrafficStatsPage()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MiniReadout(
                  label: appLocalizations.subscriptionRemaining,
                  value: expiryText,
                  valueColor: expiryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniReadout extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _MiniReadout({
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

// ---------------------------------------------------------------------------
// Subscription snapshot: name, usage, refresh — and the speed test.
// ---------------------------------------------------------------------------

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    if (profile == null) {
      return CommonCard(
        radius: commonCardRadius,
        onPressed: () => globalState.appController.toProfiles(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations.profile,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              appLocalizations.nullProfileDesc,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final usage = ProfileUsage.of(profile);
    final segments = usage?.segments ?? const <double>[];
    final subtitle = [
      ?profile.lastUpdateDate?.lastUpdateTimeDesc,
      ?usage?.primarySourceName,
      ?profile.usageExpireText(usage),
    ].join(' · ');
    final canRefresh =
        !profile.isUpdating &&
        !(profile.type == ProfileType.file &&
            profile.providerSubscriptions.isEmpty);

    return CommonCard(
      radius: commonCardRadius,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: canRefresh
                    ? () => refreshProfileSubscription(context, ref, profile)
                    : null,
                tooltip: appLocalizations.update,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                  maxWidth: 28,
                  maxHeight: 28,
                ),
                icon: ZodiacWheelUpdateIcon(
                  updating: profile.isUpdating,
                  dimmed: !canRefresh && !profile.isUpdating,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => showProfileSwitchSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EmojiText(
                          profile.label ?? profile.id,
                          maxLines: 2,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (usage != null) ...[
            Row(
              children: [
                Text(
                  appLocalizations.trafficUsage,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  usage.cardUsageText,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (segments.isNotEmpty) ...[
              const SizedBox(height: 6),
              UsageSegmentBar(segments: segments, height: 4),
            ],
          ] else
            Text(
              appLocalizations.noUsageData,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => BaseNavigator.push(context, const SpeedTestPage()),
            icon: const Icon(Icons.speed_sharp, size: 19),
            label: Text(appLocalizations.speedTest),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(StarRailRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The start button's runtime format, kept byte-identical so the
/// core and the tile always read the same uptime.
String _formatRunTime(int? timeStamp) {
  if (timeStamp == null) return '00:00:00';
  final diff = timeStamp / 1000;
  int inHours = (diff / 3600).floor();
  int inMinutes = (diff / 60 % 60).floor();
  int inSeconds = (diff % 60).floor();
  if (inHours > 999) {
    inHours = 999;
    inMinutes = 59;
    inSeconds = 59;
  }
  final hourStr = inHours < 100
      ? inHours.toString().padLeft(2, '0')
      : inHours.toString().padLeft(3, '0');
  return '$hourStr:${inMinutes.toString().padLeft(2, '0')}:${inSeconds.toString().padLeft(2, '0')}';
}
