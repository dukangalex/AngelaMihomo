import 'dart:math' as math;

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/plugins/app.dart';
import 'package:angelamihomo/providers/config.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class FontFamilyItem {
  final FontFamily fontFamily;
  final String label;

  const FontFamilyItem({required this.fontFamily, required this.label});
}

class ThemeView extends ConsumerWidget {
  const ThemeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowBuiltinFont = ref.watch(
      appSettingProvider.select(
        (state) => switch (state.locale) {
          final locale? => locale.startsWith('zh') || locale.startsWith('en'),
          null => false,
        },
      ),
    );

    final toggleItems = <Widget>[
      if (shouldShowBuiltinFont) const _BuiltinFontItem(),
      if (system.isAndroid) const _DarkIconItem(),
      if (system.isWindows) const _TrayIconInvertItem(),
      const _TextScaleFactorItem(),
    ];

    final items = <Widget>[
      const _StarrySeaThemeItem(),
      if (toggleItems.isNotEmpty) ...generateSection(items: toggleItems),
    ];
    return generateListView(items);
  }
}

class ItemCard extends StatelessWidget {
  final Widget child;
  final Info info;
  final List<Widget> actions;

  const ItemCard({
    super.key,
    required this.info,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoHeader(info: info, actions: actions),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// The theme chooser: the 星辰大海 family name heads the card and
/// its one remaining series — the twelve constellations (T298) —
/// sits under it as a collapsible section, starting expanded.
class _StarrySeaThemeItem extends ConsumerStatefulWidget {
  const _StarrySeaThemeItem();

  @override
  ConsumerState<_StarrySeaThemeItem> createState() =>
      _StarrySeaThemeItemState();
}

class _StarrySeaThemeItemState extends ConsumerState<_StarrySeaThemeItem> {
  final Set<ThemeSeries> _expanded = {};

  @override
  void initState() {
    super.initState();
    final selectedId = ref.read(themeSettingProvider).zodiacTheme;
    _expanded.add(resolveAppTheme(selectedId).series);
  }

  void _select(String id) {
    ref
        .read(themeSettingProvider.notifier)
        .updateState((state) => state.copyWith(zodiacTheme: id));
  }

  void _toggle(ThemeSeries series) {
    setState(() {
      if (!_expanded.remove(series)) _expanded.add(series);
    });
  }

  String _selectedNameZh(AppThemeSelection selected) {
    return resolveZodiacTheme(selected.id).nameZh;
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(
      themeSettingProvider.select((state) => state.zodiacTheme),
    );
    final selected = resolveAppTheme(selectedId);
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ItemCard(
      info: Info(label: appLocalizations.theme, iconData: Icons.auto_awesome),
      child: Column(
        children: [
          // The family header: 星辰大海, with the active theme's name
          // riding at the right.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        starrySeaNameZh,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        starrySeaNameEn,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _selectedNameZh(selected),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _ZodiacRingPicker(selectedId: selected.id, onSelect: _select),
          _SeriesSection(
            nameZh: zodiacSeriesNameZh,
            nameEn: zodiacSeriesNameEn,
            expanded: _expanded.contains(ThemeSeries.zodiac),
            onToggle: () => _toggle(ThemeSeries.zodiac),
            children: [
              for (final theme in zodiacThemes)
                _ThemeRow(
                  glyph: theme.sign,
                  nameZh: theme.nameZh,
                  nameEn: theme.nameEn,
                  variant: theme.variantFor(Theme.of(context).brightness),
                  isSelected: theme.id == selected.id,
                  isDefault: theme.id == zodiacDefaultThemeId,
                  onTap: () => _select(theme.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Geometry of the star-ring picker (T334 batch 4, 星宫 —
/// signature interaction 2): the twelve signs ride one ring,
/// Aries at the top, advancing clockwise in zodiac order. The
/// ring is static — no rotation, no idle animation; only the
/// selected dot's glow changes when the selection does.
double zodiacRingAngle(int index) => -math.pi / 2 + index * (math.pi / 6);

double zodiacRingRadius(Size size) => size.shortestSide * 0.42;

Offset zodiacRingDotCenter(Size size, int index) {
  final center = Offset(size.width / 2, size.height / 2);
  final angle = zodiacRingAngle(index);
  return center +
      Offset(math.cos(angle), math.sin(angle)) * zodiacRingRadius(size);
}

/// The two concentric ring lines plus a tick at every sign.
class ZodiacRingPainter extends CustomPainter {
  final Color ringColor;
  final Color innerRingColor;

  const ZodiacRingPainter({
    required this.ringColor,
    required this.innerRingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = zodiacRingRadius(size);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      radius * 0.82,
      Paint()
        ..color = innerRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final tickPaint = Paint()
      ..color = ringColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final angle = zodiacRingAngle(i);
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * (radius - 4),
        center + dir * (radius + 4),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ZodiacRingPainter oldDelegate) {
    return oldDelegate.ringColor != ringColor ||
        oldDelegate.innerRingColor != innerRingColor;
  }
}

/// Maps one asterism star (normalized 0–1 field coordinates, the
/// same data the guardian backdrop paints) into a paint box.
Offset constellationPoint(Size size, ZodiacStar star) {
  return Offset(star.x * size.width, star.y * size.height);
}

/// Paints a theme's guardian asterism — the star chart at the
/// centre of the ring — from the theme's own constellation data.
class GuardianConstellationPainter extends CustomPainter {
  final ZodiacConstellation constellation;
  final Color lineColor;
  final Color starColor;

  const GuardianConstellationPainter({
    required this.constellation,
    required this.lineColor,
    required this.starColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stars = constellation.stars;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final edge in constellation.edges) {
      if (edge.a >= stars.length || edge.b >= stars.length) continue;
      canvas.drawLine(
        constellationPoint(size, stars[edge.a]),
        constellationPoint(size, stars[edge.b]),
        linePaint,
      );
    }
    for (final star in stars) {
      final point = constellationPoint(size, star);
      final radius = 1.4 + star.magnitude * 0.8;
      if (star.magnitude >= 3) {
        canvas.drawCircle(
          point,
          radius + 3.5,
          Paint()..color = starColor.withValues(alpha: 0.2),
        );
      }
      canvas.drawCircle(point, radius, Paint()..color = starColor);
    }
  }

  @override
  bool shouldRepaint(GuardianConstellationPainter oldDelegate) {
    return !identical(oldDelegate.constellation, constellation) ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.starColor != starColor;
  }
}

/// The ring picker heading the theme card: tapping a sign on the
/// ring selects that theme through the very same callback the
/// rows below use (one tap, same state, same persistence). The
/// centre shows the selected sign's asterism, name, date range
/// and current-theme plate; under the ring, the selected theme's
/// dark and light variants preview side by side from their own
/// variant data. The collapsible row list stays under it as the
/// alternate presentation — it alone carries the default badge
/// and the per-row palette dots.
class _ZodiacRingPicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _ZodiacRingPicker({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.starRail ??
        StarRailTokens.forBrightness(Theme.of(context).brightness);
    final selected = resolveZodiacTheme(selectedId);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final side = math.min(constraints.maxWidth, 360.0);
            final size = Size.square(side);
            return SizedBox(
              width: side,
              height: side,
              child: Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: ZodiacRingPainter(
                      ringColor: tokens.glowLine.withValues(alpha: 0.35),
                      innerRingColor: tokens.glowLine.withValues(alpha: 0.14),
                    ),
                  ),
                  for (var i = 0; i < zodiacThemes.length; i++)
                    _buildLabel(context, size, i, tokens),
                  for (var i = 0; i < zodiacThemes.length; i++)
                    _buildDot(size, i, tokens),
                  Center(child: _buildCenter(context, selected, side, tokens)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _variantPreview(context, selected, Brightness.dark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _variantPreview(context, selected, Brightness.light),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildDot(Size size, int index, StarRailTokens tokens) {
    final def = zodiacThemes[index];
    final isSelected = def.id == selectedId;
    final center = zodiacRingDotCenter(size, index);
    return Positioned(
      left: center.dx - 24,
      top: center.dy - 24,
      width: 48,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(def.id),
        child: Center(
          child: Container(
            width: isSelected ? 17 : 9,
            height: isSelected ? 17 : 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? tokens.glowLine
                  : tokens.textSecondary.withValues(alpha: 0.75),
              border: isSelected
                  ? null
                  : Border.all(color: tokens.glowLine.withValues(alpha: 0.35)),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: tokens.secondary.withValues(alpha: 0.65),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context,
    Size size,
    int index,
    StarRailTokens tokens,
  ) {
    final def = zodiacThemes[index];
    final isSelected = def.id == selectedId;
    final angle = zodiacRingAngle(index);
    final center =
        Offset(size.width / 2, size.height / 2) +
        Offset(math.cos(angle), math.sin(angle)) *
            (zodiacRingRadius(size) - 20);
    return Positioned(
      left: center.dx - 32,
      top: center.dy - 9,
      width: 64,
      height: 18,
      child: IgnorePointer(
        child: Text(
          zodiacGuardianSignName(def.id, Localizations.localeOf(context)),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? tokens.textPrimary : tokens.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCenter(
    BuildContext context,
    ZodiacThemeDef selected,
    double side,
    StarRailTokens tokens,
  ) {
    final locale = Localizations.localeOf(context);
    return SizedBox(
      width: side * 0.52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: side * 0.30,
            height: side * 0.21,
            child: CustomPaint(
              painter: GuardianConstellationPainter(
                constellation: selected.constellation,
                lineColor: tokens.glowLine.withValues(alpha: 0.55),
                starColor: tokens.glowLine,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            zodiacGuardianSignName(selected.id, locale),
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            zodiacDateRangeLabel(selected.id, locale),
            style: context.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: tokens.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(StarRailRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  appLocalizations.currentTheme,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: tokens.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One side of the dark/light preview pair: the variant's own
  /// background paint and ink, a miniature orbit glyph in its
  /// primary/secondary, its primary hex, and a live mark when
  /// this variant is the one the ambient brightness resolves to.
  Widget _variantPreview(
    BuildContext context,
    ZodiacThemeDef def,
    Brightness brightness,
  ) {
    final variant = def.variantFor(brightness);
    final isLive = Theme.of(context).brightness == brightness;
    final background = variant.background;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StarRailRadius.card),
        color: background.isAtmosphere
            ? variant.surface
            : background.isGradient
            ? null
            : background.solidColor,
        gradient: background.isGradient ? background.gradient : null,
        border: Border.all(color: variant.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: variant.primary, width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: variant.secondary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isLive ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isLive ? variant.primary : variant.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                brightness == Brightness.dark
                    ? appLocalizations.dark
                    : appLocalizations.light,
                style: context.textTheme.titleSmall?.copyWith(
                  color: variant.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                variant.primary.hex,
                style: context.textTheme.bodySmall?.copyWith(
                  color: variant.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeriesSection extends StatelessWidget {
  final String nameZh;
  final String nameEn;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _SeriesSection({
    required this.nameZh,
    required this.nameEn,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.star_border,
                    size: 15,
                    color: colorScheme.primary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameZh,
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          nameEn,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...children,
      ],
    );
  }
}

/// One theme row in the constellation series, led by its sign glyph.
class _ThemeRow extends StatelessWidget {
  final String glyph;
  final String nameZh;
  final String nameEn;
  final ZodiacVariant variant;
  final bool isSelected;
  final bool isDefault;
  final VoidCallback onTap;

  const _ThemeRow({
    this.glyph = '',
    required this.nameZh,
    required this.nameEn,
    required this.variant,
    required this.isSelected,
    this.isDefault = false,
    required this.onTap,
  });

  Widget _dot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activeVariant = context.zodiac?.variant;
    final selectedPaint = activeVariant?.selected;
    // Selected row form (design doc 5.1 + the finalized mockups): a
    // translucent surfaceVariant wash, a gradient marker bar and the
    // check — never a solid light block, which made the row unreadable
    // in the rejected theme-dark mockup.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color:
                        activeVariant?.surfaceVariant ??
                        colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (isSelected &&
                      selectedPaint != null &&
                      !selectedPaint.isNone) ...[
                    Container(
                      width: 4,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: selectedPaint.isGradient
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: selectedPaint.stops!,
                              )
                            : null,
                        color: selectedPaint.isGradient
                            ? null
                            : selectedPaint.solidColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  SizedBox(
                    width: 28,
                    child: Text(glyph, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nameZh,
                                style: textTheme.titleSmall?.copyWith(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      activeVariant?.surfaceVariant ??
                                      colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  appLocalizations.defaultText,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          nameEn,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Single-set family: one palette thumbnail per theme
                  // (primary + secondary dots of the canonical variant).
                  _dot(variant.primary),
                  const SizedBox(width: 4),
                  _dot(variant.secondary),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BuiltinFontItem extends ConsumerWidget {
  const _BuiltinFontItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useHarmonyFont = ref.watch(
      themeSettingProvider.select((state) => state.useHarmonyFont),
    );
    final textTheme = Theme.of(context).textTheme;
    final onSurfaceVariant = context.colorScheme.onSurfaceVariant;
    return ListItem.switchItem(
      leading: const Icon(Icons.font_download_outlined),
      horizontalTitleGap: 12,
      title: Text(
        appLocalizations.harmonyFont,
        style: textTheme.titleSmall?.copyWith(color: onSurfaceVariant),
      ),
      subtitle: Text(
        appLocalizations.harmonyFontDesc,
        style: textTheme.bodySmall?.copyWith(
          color: onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      delegate: SwitchDelegate(
        value: useHarmonyFont,
        onChanged: (value) {
          ref
              .read(themeSettingProvider.notifier)
              .updateState((state) => state.copyWith(useHarmonyFont: value));
        },
      ),
    );
  }
}

class _DarkIconItem extends ConsumerWidget {
  const _DarkIconItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useDarkIcon = ref.watch(
      themeSettingProvider.select((state) => state.useDarkIcon),
    );
    final textTheme = Theme.of(context).textTheme;
    final onSurfaceVariant = context.colorScheme.onSurfaceVariant;
    return ListItem.switchItem(
      leading: const Icon(Icons.dark_mode_outlined),
      horizontalTitleGap: 12,
      title: Text(
        appLocalizations.darkIcon,
        style: textTheme.titleSmall?.copyWith(color: onSurfaceVariant),
      ),
      subtitle: Text(
        appLocalizations.darkIconDesc,
        style: textTheme.bodySmall?.copyWith(
          color: onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      delegate: SwitchDelegate(
        value: useDarkIcon,
        onChanged: (value) async {
          await app.setLauncherIcon(value);
          ref
              .read(themeSettingProvider.notifier)
              .updateState((state) => state.copyWith(useDarkIcon: value));
        },
      ),
    );
  }
}

class _TrayIconInvertItem extends ConsumerWidget {
  const _TrayIconInvertItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invertTrayIcon = ref.watch(
      themeSettingProvider.select((state) => state.invertTrayIcon),
    );
    final textTheme = Theme.of(context).textTheme;
    final onSurfaceVariant = context.colorScheme.onSurfaceVariant;
    return ListItem.switchItem(
      leading: const Icon(Icons.invert_colors),
      horizontalTitleGap: 12,
      title: Text(
        appLocalizations.trayIconInvert,
        style: textTheme.titleSmall?.copyWith(color: onSurfaceVariant),
      ),
      subtitle: Text(
        appLocalizations.trayIconInvertDesc,
        style: textTheme.bodySmall?.copyWith(
          color: onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      delegate: SwitchDelegate(
        value: invertTrayIcon,
        onChanged: (bool value) async {
          ref
              .read(themeSettingProvider.notifier)
              .updateState((state) => state.copyWith(invertTrayIcon: value));
          await globalState.appController.updateTray(true);
        },
      ),
    );
  }
}

class _TextScaleFactorItem extends ConsumerWidget {
  const _TextScaleFactorItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (enable, scale) = ref.watch(
      themeSettingProvider.select(
        (state) => (state.textScale.enable, state.textScale.scale),
      ),
    );
    final String process = '${(scale * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ListItem.switchItem(
            leading: const Icon(Icons.text_fields),
            horizontalTitleGap: 12,
            title: Text(
              appLocalizations.textScale,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            delegate: SwitchDelegate(
              value: enable,
              onChanged: (value) {
                ref
                    .read(themeSettingProvider.notifier)
                    .updateState(
                      (state) => state.copyWith.textScale(enable: value),
                    );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            spacing: 32,
            children: [
              Expanded(
                child: DisabledMask(
                  status: !enable,
                  child: ActivateBox(
                    active: enable,
                    child: SliderTheme(
                      data: _SliderDefaultsM3(context),
                      child: Slider(
                        padding: EdgeInsets.zero,
                        min: minTextScale,
                        max: maxTextScale,
                        value: scale,
                        onChanged: (value) {
                          ref
                              .read(themeSettingProvider.notifier)
                              .updateState(
                                (state) =>
                                    state.copyWith.textScale(scale: value),
                              );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(process, style: context.textTheme.titleMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderDefaultsM3 extends SliderThemeData {
  _SliderDefaultsM3(this.context) : super(trackHeight: 16.0);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  late final Color _overlayColor = WidgetStateColor.resolveWith((
    Set<WidgetState> states,
  ) {
    if (states.contains(WidgetState.dragged)) {
      return _colors.primary.withValues(alpha: 0.1);
    }
    if (states.contains(WidgetState.hovered)) {
      return _colors.primary.withValues(alpha: 0.08);
    }
    if (states.contains(WidgetState.focused)) {
      return _colors.primary.withValues(alpha: 0.1);
    }
    return Colors.transparent;
  });

  static final WidgetStateProperty<Size?> _thumbSize =
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return const Size(4.0, 44.0);
        }
        if (states.contains(WidgetState.hovered)) {
          return const Size(4.0, 44.0);
        }
        if (states.contains(WidgetState.focused)) {
          return const Size(2.0, 44.0);
        }
        if (states.contains(WidgetState.pressed)) {
          return const Size(2.0, 44.0);
        }
        return const Size(4.0, 44.0);
      });

  @override
  Color? get activeTrackColor => _colors.primary;

  @override
  Color? get inactiveTrackColor => _colors.secondaryContainer;

  @override
  Color? get secondaryActiveTrackColor =>
      _colors.primary.withValues(alpha: 0.54);

  @override
  Color? get disabledActiveTrackColor =>
      _colors.onSurface.withValues(alpha: 0.38);

  @override
  Color? get disabledInactiveTrackColor =>
      _colors.onSurface.withValues(alpha: 0.12);

  @override
  Color? get disabledSecondaryActiveTrackColor =>
      _colors.onSurface.withValues(alpha: 0.38);

  @override
  Color? get activeTickMarkColor => _colors.onPrimary.withValues(alpha: 1.0);

  @override
  Color? get inactiveTickMarkColor =>
      _colors.onSecondaryContainer.withValues(alpha: 1.0);

  @override
  Color? get disabledActiveTickMarkColor => _colors.onInverseSurface;

  @override
  Color? get disabledInactiveTickMarkColor => _colors.onSurface;

  @override
  Color? get thumbColor => _colors.primary;

  @override
  Color? get disabledThumbColor => _colors.onSurface.withValues(alpha: 0.38);

  @override
  Color? get overlayColor => _overlayColor;

  @override
  TextStyle? get valueIndicatorTextStyle => Theme.of(
    context,
  ).textTheme.labelLarge?.copyWith(color: _colors.onInverseSurface);

  @override
  Color? get valueIndicatorColor => _colors.inverseSurface;

  @override
  SliderComponentShape? get valueIndicatorShape =>
      const RoundedRectSliderValueIndicatorShape();

  @override
  SliderComponentShape? get thumbShape => const HandleThumbShape();

  @override
  SliderTrackShape? get trackShape => const GappedSliderTrackShape();

  @override
  SliderComponentShape? get overlayShape => const RoundSliderOverlayShape();

  @override
  SliderTickMarkShape? get tickMarkShape =>
      const RoundSliderTickMarkShape(tickMarkRadius: 4.0 / 2);

  @override
  WidgetStateProperty<Size?>? get thumbSize => _thumbSize;

  @override
  double? get trackGap => 6.0;
}
