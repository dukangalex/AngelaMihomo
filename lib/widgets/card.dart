import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/widgets/fade_box.dart';
import 'package:bett_box/widgets/glass.dart';
import 'package:material_ui/material_ui.dart';

import 'text.dart';

class Info {
  final String label;
  final IconData? iconData;
  final TextStyle? style;

  const Info({required this.label, this.iconData, this.style});
}

class InfoHeader extends StatelessWidget {
  final Info info;
  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;

  const InfoHeader({
    super.key,
    required this.info,
    this.padding,
    List<Widget>? actions,
  }) : actions = actions ?? const [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? baseInfoEdgeInsets,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (info.iconData != null) ...[
                  Icon(
                    info.iconData,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  flex: 1,
                  child: TooltipText(
                    text: EmojiText(
                      info.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (info.style ?? Theme.of(context).textTheme.titleSmall)
                              ?.copyWith(
                                color:
                                    info.style?.color ??
                                    context.colorScheme.onSurfaceVariant,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [...actions],
          ),
        ],
      ),
    );
  }
}

class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    bool? isSelected,
    this.type = CommonCardType.plain,
    this.onPressed,
    this.onLongPress,
    this.selectWidget,
    this.radius,
    this.glassTier,
    required this.child,
    this.padding,
    this.enterAnimated = false,
    this.info,
    this.clipBehavior = Clip.antiAlias,
    this.elevated = true,
  }) : isSelected = isSelected ?? false;

  final bool enterAnimated;
  final bool isSelected;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final Widget? selectWidget;
  final Widget child;
  final EdgeInsets? padding;
  final Info? info;
  final CommonCardType type;
  final double? radius;

  /// Explicit glass hierarchy tier. Defaults to the home-page ruler:
  /// selected cards read as the primary layer, everything else secondary.
  final GlassTier? glassTier;
  final Clip clipBehavior;
  final bool elevated;

  GlassTier get tier =>
      glassTier ?? (isSelected ? GlassTier.primary : GlassTier.secondary);

  @override
  Widget build(BuildContext context) {
    final cardTier = tier;
    // Primary cards carry the landed 30px corner token.
    final actualRadius =
        radius ?? (cardTier == GlassTier.primary ? 30.0 : 20.0);
    var childWidget = child;

    if (info != null) {
      childWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoHeader(
            padding: baseInfoEdgeInsets.copyWith(bottom: 0),
            info: info!,
          ),
          Flexible(flex: 1, child: child),
        ],
      );
    }

    if (selectWidget != null && isSelected) {
      final List<Widget> children = [];
      children.add(childWidget);
      children.add(Positioned.fill(child: selectWidget!));
      childWidget = Stack(children: children);
    }

    final isInteractive = onPressed != null || onLongPress != null;
    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(actualRadius),
    );
    // The glass surface paints fill, rim and sheen; the button layer is
    // fully transparent and only contributes interaction and ink.
    Widget card = Stack(
      children: [
        Positioned.fill(
          child: GlassSurface(
            tier: cardTier,
            radius: actualRadius,
            clipShape: shape,
          ),
        ),
        OutlinedButton(
          onLongPress: onLongPress,
          clipBehavior: clipBehavior,
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(shape),
            iconColor: WidgetStatePropertyAll(colorScheme.primary),
            iconSize: WidgetStateProperty.all(20),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return colorScheme.primary.withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return colorScheme.primary.withValues(alpha: 0.05);
              }
              return null;
            }),
            side: const WidgetStatePropertyAll(BorderSide.none),
            minimumSize: WidgetStatePropertyAll(
              isInteractive ? null : Size.zero,
            ),
            tapTargetSize: isInteractive
                ? null
                : MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onPressed,
          child: childWidget,
        ),
      ],
    );

    if (elevated) {
      final tint = GlassTint.resolve(colorScheme);
      card = DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: isLight ? 0.045 : 0.25),
            ),
            // The primary layer glows in its rim color (round-7 structure).
            if (cardTier == GlassTier.primary) ...[
              BoxShadow(
                blurRadius: 36,
                offset: const Offset(0, 14),
                color: tint.rim.withValues(alpha: isLight ? 0.22 : 0.20),
              ),
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 6),
                color: tint.rim.withValues(alpha: isLight ? 0.16 : 0.14),
              ),
            ],
          ],
        ),
        child: card,
      );
    }

    return switch (enterAnimated) {
      true => FadeScaleEnterBox(child: card),
      false => card,
    };
  }
}

class SelectIcon extends StatelessWidget {
  const SelectIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.inversePrimary,
      shape: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.check, size: 16),
      ),
    );
  }
}

class SettingsBlock extends StatelessWidget {
  final String title;
  final List<Widget> settings;

  const SettingsBlock({super.key, required this.title, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          InfoHeader(info: Info(label: title)),
          // Settings lists are long surfaces: static glass, secondary
          // tier, same material language as the rest of the app.
          GlassSurface(
            tier: GlassTier.secondary,
            radius: 20,
            child: Column(children: settings),
          ),
        ],
      ),
    );
  }
}
