import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

/// Futuristic keycap visuals (T62), shared by the bottom bar keys and
/// the dashboard start key. Parameters follow the approved v2 sample:
/// dark = translucent deep face, cyan (theme primary) edge light,
/// self-lit icon, seat glow that strengthens as the key sinks;
/// light = bright ceramic face with a cyan halo. Press sink is
/// 3–4dp with the layered seat shadow tightening as it travels.
BoxDecoration keycapFaceDecoration(
  ColorScheme scheme, {
  required bool selected,
  required double pressed01,
  BorderRadiusGeometry radius = const BorderRadius.all(Radius.circular(18)),
}) {
  final isLight = scheme.brightness == Brightness.light;
  final primary = scheme.primary;
  final sink = pressed01.clamp(0.0, 1.0);
  return BoxDecoration(
    borderRadius: radius,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isLight
          ? [Colors.white, Color.lerp(Colors.white, primary, 0.06)!]
          : [
              Color.lerp(scheme.surfaceContainerHigh, Colors.white, 0.07)!,
              scheme.surfaceContainerLow,
            ],
    ),
    border: Border.all(
      color: selected
          ? primary.withValues(alpha: isLight ? 0.75 : 0.9)
          : (isLight
                ? Colors.black.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.14)),
      width: selected ? 1.2 : 1,
    ),
    boxShadow: [
      // Layered seat shadow: shrinks as the key sinks into its seat.
      BoxShadow(
        color: Colors.black.withValues(alpha: isLight ? 0.18 : 0.45),
        blurRadius: 6 - 3 * sink,
        offset: Offset(0, (4 - 3 * sink).toDouble()),
      ),
      // Top rim light of the seat.
      BoxShadow(
        color: Colors.white.withValues(alpha: isLight ? 0.0 : 0.06),
        blurRadius: 2,
        offset: const Offset(0, -1),
      ),
      // Edge glow: always present on the selected key, and the seat
      // glow strengthens while any key is pressed (approved sample:
      // light intensity follows the sink).
      if (selected || sink > 0)
        BoxShadow(
          color: primary.withValues(
            alpha: (selected ? 0.30 : 0.0) + 0.25 * sink,
          ),
          blurRadius: 14 + 6 * sink,
          spreadRadius: 0.5,
        ),
    ],
  );
}

/// Wraps a tappable child with the keycap press motion: sinks 3.5dp
/// on pointer down (seat shadow tightens via [builder]'s pressed01)
/// and springs back with a slight overshoot on release. Pointer
/// events are observed passively (Listener), so the child's own tap
/// handling is untouched.
class KeycapPressable extends StatefulWidget {
  final Widget Function(BuildContext context, double pressed01) builder;

  const KeycapPressable({super.key, required this.builder});

  @override
  State<KeycapPressable> createState() => _KeycapPressableState();
}

class _KeycapPressableState extends State<KeycapPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sink = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );

  @override
  void dispose() {
    _sink.dispose();
    super.dispose();
  }

  void _press() {
    _sink.animateTo(
      1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
    );
  }

  void _release() {
    _sink.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 380, damping: 19),
        _sink.value,
        0,
        0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _sink,
        builder: (context, _) {
          final sink = _sink.value.clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, 3.5 * sink),
            child: widget.builder(context, sink),
          );
        },
      ),
    );
  }
}
