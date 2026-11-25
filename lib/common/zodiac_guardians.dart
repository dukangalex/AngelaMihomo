import 'dart:math' as math;

import 'package:angelamihomo/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/providers/app.dart';

import 'app_localizations.dart';
import 'constant.dart';
import 'zodiac_themes.dart';

/// The guardian deity of one zodiac theme (T159; user spec finalised
/// 2026-11-15 22:25: every existing theme element stays untouched — the
/// guardian is one added layer, anchored lower-left raised, in
/// Japanese-anime line style, gazing up at the theme's own constellation
/// chart at the top of the backdrop, with a name plate. Scope widened
/// 2026-11-16 by the user: not the dashboard only — every page that
/// shows the zodiac backdrop carries the figure and the plate).
class ZodiacGuardian {
  final String themeId;

  /// Latin name shown in the name plate's sub-line, in every locale.
  final String latinName;

  /// Pre-faded artwork (radial alpha edge baked in); the figure carries
  /// no constellation of its own — it gazes at the backdrop's chart.
  final String assetPath;

  const ZodiacGuardian({
    required this.themeId,
    required this.latinName,
    required this.assetPath,
  });

  /// The artwork for [brightness] (T299, user direction 2026-11-25:
  /// within one theme the watermark leans light on dark fields and
  /// dark on light fields). The shipped art is bright neon line work
  /// over a dark disc — right on dark fields, washed out on light
  /// ones — so every guardian also ships a derived light-field
  /// edition under guardians_light/: the same lines deepened into
  /// the dark family, the disc melted away, generated from the
  /// original art (luminance-driven alpha, hues kept).
  String assetPathFor(Brightness brightness) => brightness == Brightness.light
      ? assetPath.replaceFirst('images/guardians/', 'images/guardians_light/')
      : assetPath;

  /// The guardian's name in the active locale, resolved through the
  /// hand-maintained `guardian*` l10n keys.
  String localizedName(AppLocalizations l10n) {
    return switch (themeId) {
      'sagittarius' => l10n.guardianZeus,
      'aries' => l10n.guardianAres,
      'taurus' => l10n.guardianAphrodite,
      'gemini' => l10n.guardianHermes,
      'cancer' => l10n.guardianArtemis,
      'leo' => l10n.guardianApollo,
      'virgo' => l10n.guardianAstraea,
      'libra' => l10n.guardianThemis,
      'scorpio' => l10n.guardianHades,
      'capricorn' => l10n.guardianKronos,
      'aquarius' => l10n.guardianUranus,
      'pisces' => l10n.guardianPoseidon,
      _ => latinName,
    };
  }
}

/// All twelve guardians by theme id (Greek deity of each sign's ruling
/// planet / sign meaning; signs sharing a ruler are split by meaning —
/// Virgo takes Astraea, Libra takes Themis — so all twelve differ).
const zodiacGuardians = <String, ZodiacGuardian>{
  'sagittarius': ZodiacGuardian(
    themeId: 'sagittarius',
    latinName: 'Zeus',
    assetPath: 'assets/images/guardians/sagittarius.webp',
  ),
  'aries': ZodiacGuardian(
    themeId: 'aries',
    latinName: 'Ares',
    assetPath: 'assets/images/guardians/aries.webp',
  ),
  'taurus': ZodiacGuardian(
    themeId: 'taurus',
    latinName: 'Aphrodite',
    assetPath: 'assets/images/guardians/taurus.webp',
  ),
  'gemini': ZodiacGuardian(
    themeId: 'gemini',
    latinName: 'Hermes',
    assetPath: 'assets/images/guardians/gemini.webp',
  ),
  'cancer': ZodiacGuardian(
    themeId: 'cancer',
    latinName: 'Artemis',
    assetPath: 'assets/images/guardians/cancer.webp',
  ),
  'leo': ZodiacGuardian(
    themeId: 'leo',
    latinName: 'Apollo',
    assetPath: 'assets/images/guardians/leo.webp',
  ),
  'virgo': ZodiacGuardian(
    themeId: 'virgo',
    latinName: 'Astraea',
    assetPath: 'assets/images/guardians/virgo.webp',
  ),
  'libra': ZodiacGuardian(
    themeId: 'libra',
    latinName: 'Themis',
    assetPath: 'assets/images/guardians/libra.webp',
  ),
  'scorpio': ZodiacGuardian(
    themeId: 'scorpio',
    latinName: 'Hades',
    assetPath: 'assets/images/guardians/scorpio.webp',
  ),
  'capricorn': ZodiacGuardian(
    themeId: 'capricorn',
    latinName: 'Kronos',
    assetPath: 'assets/images/guardians/capricorn.webp',
  ),
  'aquarius': ZodiacGuardian(
    themeId: 'aquarius',
    latinName: 'Uranus',
    assetPath: 'assets/images/guardians/aquarius.webp',
  ),
  'pisces': ZodiacGuardian(
    themeId: 'pisces',
    latinName: 'Poseidon',
    assetPath: 'assets/images/guardians/pisces.webp',
  ),
};

ZodiacGuardian? zodiacGuardianForTheme(String? themeId) =>
    zodiacGuardians[themeId];

/// Sign names for the locales the theme defs do not carry: [ZodiacThemeDef]
/// only ships zh/en display names, so ja/ko/ru/fa and Traditional Chinese
/// resolve from this table; zh (simplified) and en derive from the def
/// itself so the plate always matches the theme page's own naming.
const _guardianSignNames = <String, Map<String, String>>{
  'zh_TC': {
    'aries': '牡羊座',
    'taurus': '金牛座',
    'gemini': '雙子座',
    'cancer': '巨蟹座',
    'leo': '獅子座',
    'virgo': '處女座',
    'libra': '天秤座',
    'scorpio': '天蠍座',
    'sagittarius': '射手座',
    'capricorn': '摩羯座',
    'aquarius': '水瓶座',
    'pisces': '雙魚座',
  },
  'ja': {
    'aries': '牡羊座',
    'taurus': '牡牛座',
    'gemini': '双子座',
    'cancer': '蟹座',
    'leo': '獅子座',
    'virgo': '乙女座',
    'libra': '天秤座',
    'scorpio': '蠍座',
    'sagittarius': '射手座',
    'capricorn': '山羊座',
    'aquarius': '水瓶座',
    'pisces': '魚座',
  },
  'ko': {
    'aries': '양자리',
    'taurus': '황소자리',
    'gemini': '쌍둥이자리',
    'cancer': '게자리',
    'leo': '사자자리',
    'virgo': '처녀자리',
    'libra': '천칭자리',
    'scorpio': '전갈자리',
    'sagittarius': '사수자리',
    'capricorn': '염소자리',
    'aquarius': '물병자리',
    'pisces': '물고기자리',
  },
  'ru': {
    'aries': 'Овен',
    'taurus': 'Телец',
    'gemini': 'Близнецы',
    'cancer': 'Рак',
    'leo': 'Лев',
    'virgo': 'Дева',
    'libra': 'Весы',
    'scorpio': 'Скорпион',
    'sagittarius': 'Стрелец',
    'capricorn': 'Козерог',
    'aquarius': 'Водолей',
    'pisces': 'Рыбы',
  },
  'fa': {
    'aries': 'حمل',
    'taurus': 'ثور',
    'gemini': 'جوزا',
    'cancer': 'سرطان',
    'leo': 'اسد',
    'virgo': 'سنبله',
    'libra': 'میزان',
    'scorpio': 'عقرب',
    'sagittarius': 'قوس',
    'capricorn': 'جدی',
    'aquarius': 'دلو',
    'pisces': 'حوت',
  },
};

/// The localized sign name for the name plate's sub-line.
String zodiacGuardianSignName(String themeId, Locale locale) {
  final def = resolveZodiacTheme(themeId);
  if (locale.languageCode == 'zh') {
    if (locale.countryCode == 'TC' || locale.scriptCode == 'Hant') {
      return _guardianSignNames['zh_TC']?[themeId] ??
          def.nameZh.split('·').first.trim();
    }
    return def.nameZh.split('·').first.trim();
  }
  return _guardianSignNames[locale.languageCode]?[themeId] ??
      def.nameEn.split('·').first.trim();
}

/// Resolves the active theme's guardian, or null when there is no
/// zodiac theme or the theme has no guardian mapped. Shared by the
/// figure layer and the name plate so both read the one data source.
({ZodiacGuardian guardian, ZodiacVariant variant})? _activeGuardian(
  BuildContext context,
) {
  final zodiac = context.zodiac;
  if (zodiac == null) return null;
  final guardian = zodiacGuardianForTheme(zodiac.themeId);
  if (guardian == null) return null;
  return (guardian: guardian, variant: zodiac.variant);
}

/// How one page presents its sign's guardian figure: a transform of
/// the sign's single canonical artwork (mirror, zoom/crop focus,
/// anchor micro-shift). Every page keeps the lower-left-raised grand
/// position; only the presentation changes, so no two pages pose the
/// guardian quite the same way.
///
/// HARD CONSTRAINT (user, 2026-11-16): every variant of a sign's
/// guardian is the SAME character — same face, same character design.
/// A variant may only ever be (a) a transform of the one canonical
/// artwork, as in this table, or (b) future new-pose artwork of that
/// same character. Introducing a different person, face or design for
/// a sign — per page or otherwise — is forbidden. When real new-pose
/// artwork arrives, swap only the asset mapping; this structure and
/// the per-page presentation split stay.
class GuardianFigureVariant {
  /// Mirror the artwork horizontally (the gaze flips with it).
  final bool flipX;

  /// Zoom into the artwork: above 1 crops toward [focal] (e.g. an
  /// upper-body close-up), below 1 pulls back to a farther full view.
  final double zoom;

  /// The focal point the zoom crops around.
  final Alignment focal;

  /// Figure width as a fraction of screen width (capped at 400dp).
  final double widthFactor;

  /// Figure top as a fraction of screen height.
  final double topFraction;

  /// Figure left offset in dp.
  final double left;

  const GuardianFigureVariant({
    this.flipX = false,
    this.zoom = 1,
    this.focal = Alignment.center,
    this.widthFactor = 0.6,
    this.topFraction = 0.36,
    this.left = -2,
  });

  /// The transform signature, for tests and debugging.
  (bool, double, Alignment, double, double, double) get signature =>
      (flipX, zoom, focal, widthFactor, topFraction, left);
}

/// The presentation the dashboard (home) uses; also the fallback for
/// any page without an explicit entry.
const defaultGuardianFigureVariant = GuardianFigureVariant();

/// The one extensible page-variant table (T159). Keys are the app's
/// main-page labels; pushed grandchild pages inherit their section's
/// variant (e.g. the app-settings page presents the tools variant).
const zodiacGuardianFigureVariants = <PageLabel, GuardianFigureVariant>{
  PageLabel.dashboard: defaultGuardianFigureVariant,
  PageLabel.proxies: GuardianFigureVariant(
    flipX: true,
    widthFactor: 0.56,
    topFraction: 0.34,
  ),
  PageLabel.profiles: GuardianFigureVariant(
    zoom: 1.45,
    focal: Alignment(-0.2, -0.55),
    widthFactor: 0.58,
    topFraction: 0.38,
  ),
  PageLabel.tools: GuardianFigureVariant(
    flipX: true,
    zoom: 1.2,
    focal: Alignment(0, -0.3),
    widthFactor: 0.54,
    topFraction: 0.33,
  ),
  PageLabel.logs: GuardianFigureVariant(
    zoom: 0.88,
    widthFactor: 0.58,
    topFraction: 0.4,
  ),
  PageLabel.resources: GuardianFigureVariant(
    zoom: 1.25,
    focal: Alignment(0.2, -0.4),
    widthFactor: 0.57,
    topFraction: 0.35,
  ),
  PageLabel.script: GuardianFigureVariant(
    flipX: true,
    zoom: 1.1,
    focal: Alignment(0, -0.2),
    widthFactor: 0.55,
    topFraction: 0.37,
  ),
  PageLabel.toolbox: GuardianFigureVariant(
    zoom: 1.35,
    focal: Alignment(-0.3, -0.5),
    widthFactor: 0.58,
    topFraction: 0.39,
  ),
  PageLabel.connections: GuardianFigureVariant(
    flipX: true,
    zoom: 0.95,
    widthFactor: 0.56,
    topFraction: 0.35,
  ),
};

/// The figure variant for a main-page label (never null: unmapped
/// pages fall back to [defaultGuardianFigureVariant]).
GuardianFigureVariant zodiacGuardianVariantFor(PageLabel pageLabel) =>
    zodiacGuardianFigureVariants[pageLabel] ?? defaultGuardianFigureVariant;

/// The guardian figure layer (T159). [ZodiacBackdrop] embeds it as its
/// own top layer — directly above the backdrop's light field
/// (background gradient, glow spots, constellation layer, sign
/// watermark — all untouched) and below all page content — so every
/// surface that paints the zodiac backdrop carries the figure with it:
/// anchored lower-left raised, gazing up at the backdrop's
/// constellation chart at the top, posed per page by
/// [zodiacGuardianFigureVariants].
class ZodiacGuardianFigureLayer extends StatelessWidget {
  /// The main page this layer instance presents the figure for.
  final PageLabel pageLabel;

  const ZodiacGuardianFigureLayer({super.key, required this.pageLabel});

  @override
  Widget build(BuildContext context) {
    final active = _activeGuardian(context);
    if (active == null) return const SizedBox.expand();
    // T299 (user 2026-11-25): the watermark adapts its tone family
    // to the active mode — the light-toned artwork on dark fields,
    // the derived dark-toned edition (assetPathFor) on light
    // fields — at the same presence in both, so neither mode's
    // watermark washes out against its own field.
    final brightness = Theme.of(context).brightness;
    final variant = zodiacGuardianVariantFor(pageLabel);
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: variant.left,
            top: size.height * variant.topFraction,
            width: math.min(size.width * variant.widthFactor, 400),
            child: Opacity(
              // The figure is a background presence, never the scene's
              // subject (user correction 2026-11-16): chain.26 weakens
              // it (T160) and the edge-feather masks below sink it into
              // the backdrop's light field — but at 0.45 with the
              // stronger blur it read as too faint on the user's real
              // device (2026-11-17, T193), so the presence is raised
              // to 0.6 and the blur eased in the backdrop.
              // T299: both modes take 0.6 — the per-mode artwork
              // (see above) carries the adaptation now.
              opacity: 0.6,
              child: ShaderMask(
                // T188: feather the artwork's edges into the
                // background on both axes so the figure reads as grown
                // into the backdrop rather than pasted on it. The
                // earlier single radial dissolve (T160) left the
                // asset's straight rectangular edges visible — alpha
                // was still high where the rectangle's sides sat
                // inside the radial falloff — and the user's real
                // device still read it as a pasted picture
                // (2026-11-17). A box feather drives alpha to exactly
                // zero at every side of the asset rectangle, so no
                // hard edge can survive anywhere on its perimeter.
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 0.22, 0.78, 1],
                ).createShader(rect),
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0, 0.12, 0.78, 1],
                  ).createShader(rect),
                  child: ClipRect(
                    child: Transform.scale(
                      scale: variant.zoom,
                      alignment: variant.focal,
                      child: Transform.flip(
                        flipX: variant.flipX,
                        child: Image.asset(
                          active.guardian.assetPathFor(brightness),
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The figure layer as [ZodiacBackdrop] embeds it: the page label —
/// and with it the section whose variant a pushed grandchild page
/// inherits — comes from the app's own current-page state, watched
/// here so no backdrop call site has to thread it through and the
/// figure re-poses itself when the main page changes.
class ZodiacGuardianBackdropFigure extends ConsumerWidget {
  const ZodiacGuardianBackdropFigure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ZodiacGuardianFigureLayer(
      pageLabel: ref.watch(currentPageLabelProvider),
    );
  }
}

/// The guardian name plate (T159): part of the background painting,
/// not a fixed overlay. [ZodiacBackdrop] embeds it as its topmost
/// layer — still below all page content, so bottom sheets, dialogs
/// and cards cover it naturally (user correction 2026-11-16: the name
/// must not be pinned above everything). Chain.26 (T161/T176): the
/// plate moves to the lower-right corner (the user found the right
/// side emptier) and is dimmed to background level — smaller, lighter
/// and translucent like the backdrop's watermark — so scrolling lists
/// no longer show a bright label shining through the glass cards.
class ZodiacGuardianPlate extends StatelessWidget {
  const ZodiacGuardianPlate({super.key});

  @override
  Widget build(BuildContext context) {
    final active = _activeGuardian(context);
    if (active == null) return const SizedBox.expand();
    final guardian = active.guardian;
    final variant = active.variant;
    final l10n = appLocalizations;
    final sign = zodiacGuardianSignName(
      guardian.themeId,
      Localizations.localeOf(context),
    );
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: 15,
            bottom: getFloatingBottomBarReserveHeight(context) + 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guardian.localizedName(l10n),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: variant.textPrimary.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.guardianLine(guardian.latinName.toUpperCase(), sign),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: variant.textSecondary.withValues(alpha: 0.7),
                    fontSize: 8.5,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
