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
/// its three series sit under it as collapsible sections — 十二星座，
/// 人类深空探索, 纯色生肖. The section holding the
/// active theme starts expanded; every section can be opened or
/// closed on its own.
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
    return switch (selected.series) {
      ThemeSeries.zodiac => resolveZodiacTheme(selected.id).nameZh,
      ThemeSeries.deepSpace => deepSpaceThemeById(selected.id)?.nameZh ?? '',
      ThemeSeries.solid => solidThemeById(selected.id)?.nameZh ?? '',
    };
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
                  variant: theme.variant,
                  isSelected: theme.id == selected.id,
                  isDefault: theme.id == zodiacDefaultThemeId,
                  onTap: () => _select(theme.id),
                ),
            ],
          ),
          _SeriesSection(
            nameZh: deepSpaceSeriesNameZh,
            nameEn: deepSpaceSeriesNameEn,
            expanded: _expanded.contains(ThemeSeries.deepSpace),
            onToggle: () => _toggle(ThemeSeries.deepSpace),
            children: [
              for (final theme in deepSpaceThemes)
                _DeepSpaceThemeRow(
                  theme: theme,
                  isSelected: theme.id == selected.id,
                  onTap: () => _select(theme.id),
                ),
            ],
          ),
          _SeriesSection(
            nameZh: solidSeriesNameZh,
            nameEn: solidSeriesNameEn,
            expanded: _expanded.contains(ThemeSeries.solid),
            onToggle: () => _toggle(ThemeSeries.solid),
            children: [
              for (final theme in solidThemes)
                _ThemeRow(
                  glyph: theme.nameZh,
                  nameZh: theme.nameZh,
                  nameEn: theme.nameEn,
                  variant: theme.variant,
                  isSelected: theme.id == selected.id,
                  onTap: () => _select(theme.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One collapsible series section under the 星辰大海 header: the
/// series' full name （中文 primary, English under it) with a
/// chevron; tapping the header opens or closes its theme rows.
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

/// One Human Deep Space Exploration event row (T182): the year as
/// the leading mark, the event name in Chinese with the English
/// line under it, the palette dots and the same selected chrome as
/// the constellation rows.
class _DeepSpaceThemeRow extends StatelessWidget {
  final DeepSpaceThemeDef theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeepSpaceThemeRow({
    required this.theme,
    required this.isSelected,
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
    final variant = context.zodiac?.variant;
    final selectedPaint = variant?.selected;
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
                        variant?.surfaceVariant ??
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
                    width: 34,
                    child: Text(
                      theme.year,
                      style: textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.nameZh,
                          style: textTheme.titleSmall?.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          theme.nameEn,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _dot(theme.variant.primary),
                  const SizedBox(width: 4),
                  _dot(theme.variant.secondary),
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

/// One theme row in the glyph-led series (the constellations, and
/// the solid zodiac whose glyph is the animal's Chinese name).
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
                    child: Text(
                      glyph,
                      style: const TextStyle(fontSize: 20),
                    ),
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
