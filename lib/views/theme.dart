
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/plugins/app.dart';
import 'package:bett_box/providers/config.dart';
import 'package:bett_box/providers/state.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ThemeModeItem {
  final ThemeMode themeMode;
  final IconData iconData;
  final String label;

  const ThemeModeItem({
    required this.themeMode,
    required this.iconData,
    required this.label,
  });
}

class FontFamilyItem {
  final FontFamily fontFamily;
  final String label;

  const FontFamilyItem({required this.fontFamily, required this.label});
}

class ThemeView extends ConsumerWidget {
  const ThemeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(currentBrightnessProvider);
    final toggleItems = <Widget>[
      if (system.isAndroid) const _DarkIconItem(),
      if (system.isWindows) const _TrayIconInvertItem(),
      const _TextScaleFactorItem(),
    ];

    final items = <Widget>[
      const _ThemeModeItem(),
      if (brightness == Brightness.dark) const _PrueBlackItem(),
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

class _ThemeModeItem extends ConsumerWidget {
  const _ThemeModeItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final themeModeItems = <ThemeModeItem>[
      ThemeModeItem(
        iconData: Icons.auto_mode,
        label: appLocalizations.auto,
        themeMode: ThemeMode.system,
      ),
      ThemeModeItem(
        iconData: Icons.light_mode,
        label: appLocalizations.light,
        themeMode: ThemeMode.light,
      ),
      ThemeModeItem(
        iconData: Icons.dark_mode,
        label: appLocalizations.dark,
        themeMode: ThemeMode.dark,
      ),
    ];
    return ItemCard(
      info: Info(
        label: appLocalizations.themeMode,
        iconData: Icons.brightness_high,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: themeModeItems.length,
          itemBuilder: (_, index) {
            final themeModeItem = themeModeItems[index];
            return CommonCard(
              isSelected: themeModeItem.themeMode == themeMode,
              onPressed: () {
                ref
                    .read(themeSettingProvider.notifier)
                    .updateState(
                      (state) =>
                          state.copyWith(themeMode: themeModeItem.themeMode),
                    );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(child: Icon(themeModeItem.iconData)),
                    const SizedBox(width: 8),
                    Flexible(child: Text(themeModeItem.label)),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(width: 16),
        ),
      ),
    );
  }
}

class _PrueBlackItem extends ConsumerWidget {
  const _PrueBlackItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prueBlack = ref.watch(
      themeSettingProvider.select((state) => state.pureBlack),
    );
    return ListItem.switchItem(
      leading: const Icon(Icons.contrast),
      horizontalTitleGap: 12,
      title: Text(
        appLocalizations.pureBlackMode,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      delegate: SwitchDelegate(
        value: prueBlack,
        onChanged: (value) {
          ref
              .read(themeSettingProvider.notifier)
              .updateState((state) => state.copyWith(pureBlack: value));
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
