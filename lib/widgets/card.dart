import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/widgets/fade_box.dart';
import 'package:bett_box/widgets/glass.dart';
import 'package:bett_box/widgets/glass_prototype.dart';
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
    required this.child,
    this.padding,
    this.enterAnimated = false,
    this.info,
    this.clipBehavior = Clip.antiAlias,
    this.elevated = true,
    this.glassTier,
    this.shaderGlass = false,
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
  final Clip clipBehavior;
  final bool elevated;

  /// Glass hierarchy tier override (T64 round 6). Null keeps the
  /// card default — the secondary tier, which recedes. A page's main
  /// card / main action passes [GlassTier.primary] so it reads
  /// denser and brighter than the page's secondary cards, matching
  /// the home page's primary/secondary contrast.
  final GlassTier? glassTier;

  /// T83 prototype opt-in: render this card's glass through the
  /// shader edge-refraction prototype surface ([PrototypeGlassSurface])
  /// instead of [GlassSurface] — a clear face with refraction only in
  /// the bevel band. Only the home page's main status card opts in;
  /// every other surface keeps the production glass, and the
  /// prototype surface itself falls back to [GlassSurface] whenever
  /// the shader path is unavailable.
  final bool shaderGlass;

  // final WidgetStateProperty<Color?>? backgroundColor;
  // final WidgetStateProperty<BorderSide?>? borderSide;

  BorderSide getBorderSide(
    BuildContext context,
    Set<WidgetState> states, {
    GlassTokens? glass,
  }) {
    final colorScheme = context.colorScheme;
    final hoverColor = isSelected
        ? colorScheme.primary.opacity80
        : colorScheme.primary.opacity60;
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.pressed)) {
      return BorderSide(
        color: hoverColor,
        strokeAlign: BorderSide.strokeAlignInside,
      );
    }
    if (glass != null && !isSelected) {
      return BorderSide(
        color: glass.rim,
        // 0.5px hairline stroke (Apple iOS 27 kit calibre, T38); the
        // brighter rim light is painted by GlassSurface on top.
        width: 0.5,
        strokeAlign: BorderSide.strokeAlignInside,
      );
    }
    final isLight = colorScheme.brightness == Brightness.light;
    return BorderSide(
      color: isSelected
          ? colorScheme.primary
          : colorScheme.outlineVariant.withValues(
              alpha: elevated ? (isLight ? 0.65 : 0.35) : (isLight ? 0.8 : 0.4),
            ),
      strokeAlign: BorderSide.strokeAlignInside,
    );
  }

  Color? getBackgroundColor(
    BuildContext context,
    Set<WidgetState> states, {
    GlassTokens? glass,
  }) {
    final colorScheme = context.colorScheme;
    if (isSelected) {
      if (glass != null) {
        // Round 7: a selected card is a primary-semantic surface
        // (the profiles page's current profile above all). Under
        // glass it no longer paints the flat secondaryContainer
        // slab — the round-6 device photos showed exactly that
        // slab reading as a plain pale card — it blends the
        // container tint with the primary tier's dyed glass fill,
        // keeping the selection identity while joining the glass.
        // The blend leans further into the glass fill for primary
        // (0.7): in static scopes (the profiles list) the pale static
        // fill would otherwise be washed out by the container color
        // and the selected card would fall back to a flat tint.
        return Color.lerp(
          colorScheme.secondaryContainer,
          glass.effectiveFill,
          glass.tier == GlassTier.primary ? 0.7 : 0.45,
        );
      }
      return type == CommonCardType.filled
          ? colorScheme.secondaryContainer.opacity80
          : colorScheme.secondaryContainer;
    }
    if (glass != null) {
      return glass.effectiveFill;
    }
    final isLight = colorScheme.brightness == Brightness.light;
    return isLight
        ? Color.lerp(
            colorScheme.surface,
            colorScheme.surfaceContainerLowest,
            0.5,
          )
        : colorScheme.surfaceContainerHigh;
  }

  @override
  Widget build(BuildContext context) {
    // Round 7: the effective tier — an explicitly claimed tier
    // wins; a selected card (the page's current choice, a
    // primary-semantic surface) resolves as primary when the
    // caller claimed no tier of its own.
    final effectiveTier = glassTier ?? (isSelected ? GlassTier.primary : null);
    // Glass-surfaced cards take a larger, softer radius (T38 round 3,
    // 20–28 band); flat cards keep the stock 20. Round 6 addendum
    // (Orville curve language): primary-tier cards round further —
    // 30 — so the page's main surface carries the softest curve.
    final actualRadius =
        radius ??
        (GlassScope.isActive(context)
            ? (effectiveTier == GlassTier.primary ? 30.0 : 24.0)
            : 20.0);
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
    final isLight = context.colorScheme.brightness == Brightness.light;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(actualRadius),
    );
    final glass = GlassScope.isActive(context)
        ? GlassTokens.resolve(
            context.colorScheme,
            GlassKind.card,
            realtime: GlassScope.isLive(context),
            tier: effectiveTier,
          )
        : null;
    // T83 prototype: the opted-in card paints no fill of its own —
    // the prototype surface supplies the pane body (the shader's
    // backdrop sample, or the fallback fill layer).
    final useShaderGlass = shaderGlass && glass != null && !isSelected;
    Widget card = OutlinedButton(
      onLongPress: onLongPress,
      clipBehavior: clipBehavior,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(shape),
        iconColor: WidgetStatePropertyAll(context.colorScheme.primary),
        iconSize: WidgetStateProperty.all(20),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => useShaderGlass
              ? Colors.transparent
              : getBackgroundColor(context, states, glass: glass),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => getBorderSide(context, states, glass: glass),
        ),
        minimumSize: WidgetStatePropertyAll(isInteractive ? null : Size.zero),
        tapTargetSize: isInteractive ? null : MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: childWidget,
    );

    if (glass != null) {
      card = useShaderGlass
          ? PrototypeGlassSurface(
              shape: shape,
              tokens: glass,
              radius: actualRadius,
              child: card,
            )
          : GlassSurface(shape: shape, tokens: glass, child: card);
    }

    if (elevated) {
      card = DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 2),
              // Round 5: a touch more presence so the pane separates
              // from the colour field it floats on (light theme only —
              // the dark shadow was already strong).
              color: Colors.black.withValues(alpha: isLight ? 0.07 : 0.25),
            ),
            // Round 7: the primary tier's coloured ambient glow
            // rides under the neutral shadow — only primary tokens
            // carry glow shadows, so every other card is untouched.
            if (glass != null) ...glass.glowShadows,
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
          Card(
            color: context.colorScheme.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            child: Column(children: settings),
          ),
        ],
      ),
    );
  }
}
