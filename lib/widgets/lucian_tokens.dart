// Interaction tokens shared by the widgets ported from the
// angela-uxui component specs (Lucian UX/UI Prompt · MIT License,
// see the per-widget attribution notes). Values come from the
// library's tokens.css: --ux-ease and --ux-spring, plus the mint
// success colour used by the done states.
import 'package:material_ui/material_ui.dart';

/// --ux-ease: cubic-bezier(.2,.8,.2,1)
const lucianEase = Cubic(0.2, 0.8, 0.2, 1);

/// --ux-spring: cubic-bezier(.34,1.45,.64,1)
const lucianSpring = Cubic(0.34, 1.45, 0.64, 1);

/// --ux-mint in the light / dark token sets (#119C72 / #7EE8C0).
Color lucianMint(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? const Color(0xFF119C72)
    : const Color(0xFF7EE8C0);

/// --ux-warn in the light / dark token sets (#D6731E / #FFB26B).
Color lucianWarn(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? const Color(0xFFD6731E)
    : const Color(0xFFFFB26B);

/// --ux-danger in the light / dark token sets (#D93A55 / #FF7D8C).
Color lucianDanger(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? const Color(0xFFD93A55)
    : const Color(0xFFFF7D8C);

/// Whether the platform asks for reduced motion; the source specs
/// compress their timelines in that case instead of dropping them.
bool lucianReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);
