import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/widgets/fade_box.dart';
import 'package:bett_box/widgets/zodiac_surface.dart';
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
          // T115 homepage hard line: the title keeps its intrinsic
          // width; status chips on the right shrink to fit instead
          // of squeezing the title into an ellipsis.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [...actions],
              ),
            ),
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
    this.emphasis = false,
    required this.child,
    this.padding,
    this.enterAnimated = false,
    this.info,
    this.clipBehavior = Clip.antiAlias,
    this.elevated = true,
    this.subtle = false,
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

  /// Panel-tier emphasis (T115): the home page's primary surfaces
  /// (outbound mode, start control) take the skeleton's panel
  /// material; selected cards read as panel tier too.
  final bool emphasis;
  final Clip clipBehavior;
  final bool elevated;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
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
    final spec = context.zodiac.spec;
    final actualRadius =
        radius ??
        ((emphasis || isSelected) ? spec.panelRadius : spec.smallRadius);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(actualRadius),
    );
    // The constellation surface paints fill, border and shadow; the
    // button layer is fully transparent and only contributes
    // interaction and ink.
    Widget card = ZodiacSurface(
      tone: (emphasis || isSelected)
          ? ZodiacTone.panel
          : ZodiacTone.card,
      radius: radius,
      selected: isSelected,
      child: OutlinedButton(
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
    );

    return switch (enterAnimated) {
      true => FadeScaleEnterBox(child: card),
      false => card,
    };
  }
}

class _CardPressScale extends StatefulWidget {
  const _CardPressScale({required this.builder});

  final Widget Function(WidgetStatesController controller) builder;

  @override
  State<_CardPressScale> createState() => _CardPressScaleState();
}

class _CardPressScaleState extends State<_CardPressScale> {
  final _controller = WidgetStatesController();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleStates);
  }

  void _handleStates() {
    final pressed = _controller.value.contains(WidgetState.pressed);
    if (pressed == _pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStates);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: _pressed
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 260),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: widget.builder(_controller),
    );
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
          // Settings lists are long surfaces on the family's group
          // material, same language as the rest of the app.
          ZodiacSurface(
            tone: ZodiacTone.group,
            child: Column(children: settings),
          ),
        ],
      ),
    );
  }
}
