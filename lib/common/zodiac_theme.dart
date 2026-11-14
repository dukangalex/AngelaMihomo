import 'package:material_ui/material_ui.dart';

/// T115: the twelve-constellation theme family.
///
/// Single source of truth for the family's design spec
/// (DESIGN-十二星座主题家族.md): 12 themes x light/dark variants,
/// one shared set of 21 tokens, six skeleton families. The family
/// replaces the upstream theme mechanism wholesale — nothing else in
/// the app may define theme colors. Token values are transcribed
/// from the spec verbatim; derived tokens follow the spec's family
/// rules (delay tiers mirror the status colors, disabled is
/// textSecondary at 45% opacity).
enum ZodiacSign {
  aries,
  taurus,
  gemini,
  cancer,
  leo,
  virgo,
  libra,
  scorpio,
  sagittarius,
  capricorn,
  aquarius,
  pisces,
}

/// The six skeleton families of the spec. Themes sharing a skeleton
/// share its material parameters and differ only in token values.
enum ZodiacSkeleton {
  immersive,
  layeredCard,
  easternWhitespace,
  vibrantClash,
  plainPaper,
  consolePanel,
}

/// How a selected segment / strong state is painted.
enum ZodiacSelectedStyle { gradient, solid, underline, invertBlock }

/// Material parameters shared by every theme of one skeleton.
class ZodiacSkeletonSpec {
  final double panelRadius;
  final double groupRadius;
  final double smallRadius;
  final double borderWidth;
  final bool frameless;
  final bool translucent;
  final bool hardShadow;
  final bool softShadow;
  final ZodiacSelectedStyle selectedStyle;

  const ZodiacSkeletonSpec({
    required this.panelRadius,
    required this.groupRadius,
    required this.smallRadius,
    required this.borderWidth,
    required this.selectedStyle,
    this.frameless = false,
    this.translucent = false,
    this.hardShadow = false,
    this.softShadow = false,
  });
}

const Map<ZodiacSkeleton, ZodiacSkeletonSpec> zodiacSkeletonSpecs = {
  ZodiacSkeleton.immersive: ZodiacSkeletonSpec(
    panelRadius: 28,
    groupRadius: 26,
    smallRadius: 22,
    borderWidth: 1,
    selectedStyle: ZodiacSelectedStyle.gradient,
    translucent: true,
    softShadow: true,
  ),
  ZodiacSkeleton.layeredCard: ZodiacSkeletonSpec(
    panelRadius: 20,
    groupRadius: 18,
    smallRadius: 20,
    borderWidth: 1,
    selectedStyle: ZodiacSelectedStyle.solid,
    softShadow: true,
  ),
  ZodiacSkeleton.easternWhitespace: ZodiacSkeletonSpec(
    panelRadius: 0,
    groupRadius: 0,
    smallRadius: 0,
    borderWidth: 0,
    selectedStyle: ZodiacSelectedStyle.underline,
    frameless: true,
  ),
  ZodiacSkeleton.vibrantClash: ZodiacSkeletonSpec(
    panelRadius: 18,
    groupRadius: 14,
    smallRadius: 16,
    borderWidth: 2.5,
    selectedStyle: ZodiacSelectedStyle.solid,
    hardShadow: true,
  ),
  ZodiacSkeleton.plainPaper: ZodiacSkeletonSpec(
    panelRadius: 0,
    groupRadius: 0,
    smallRadius: 0,
    borderWidth: 0,
    selectedStyle: ZodiacSelectedStyle.invertBlock,
    frameless: true,
  ),
  ZodiacSkeleton.consolePanel: ZodiacSkeletonSpec(
    panelRadius: 6,
    groupRadius: 6,
    smallRadius: 6,
    borderWidth: 1,
    selectedStyle: ZodiacSelectedStyle.solid,
  ),
};

/// One brightness variant of a theme: the 21 spec tokens.
class ZodiacPalette {
  /// Page background gradient stops (a single entry means solid).
  final List<Color> bgStops;

  /// Radial atmosphere glows composited over [bgStops] at fixed
  /// positions (right-top / left-middle). Null where the skeleton
  /// has no atmosphere layer.
  final Color? haloPrimary;
  final Color? haloSecondary;

  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color success;
  final Color warning;
  final Color error;

  /// Selected-state fill stops (one entry = solid, two = gradient).
  final List<Color> selectedStops;

  final Color navBar;

  /// Brand-banner gradient stops; null where the theme has none.
  final List<Color>? heroStops;

  /// Glow color for lit elements; null where the theme has none.
  final Color? glow;

  const ZodiacPalette({
    required this.bgStops,
    this.haloPrimary,
    this.haloSecondary,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.success,
    required this.warning,
    required this.error,
    required this.selectedStops,
    required this.navBar,
    this.heroStops,
    this.glow,
  });

  // Family rules (spec section 2): the delay tiers share their
  // source with the status colors, and the disabled state is the
  // secondary text color at 45% opacity, in every variant.
  Color get delayGood => success;
  Color get delayMid => warning;
  Color get delayBad => error;
  Color get disabled => textSecondary.withValues(alpha: 0.45);

  /// Dialogs must read as fully opaque even on translucent
  /// skeletons: composite the surface over the background's middle
  /// stop when it carries alpha.
  Color get dialogSurface {
    if (surface.a >= 1) return surface;
    final mid = bgStops[bgStops.length ~/ 2];
    return Color.alphaBlend(surface, mid);
  }

  LinearGradient get bgGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: bgStops,
    stops: bgStops.length == 1
        ? null
        : List.generate(bgStops.length, (i) => i / (bgStops.length - 1)),
  );

  LinearGradient get selectedGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: selectedStops.length == 1
        ? [selectedStops.first, selectedStops.first]
        : selectedStops,
  );
}

/// One constellation theme: identity, skeleton, both variants.
class ZodiacThemeDef {
  final ZodiacSign sign;
  final ZodiacSkeleton skeleton;

  /// Neon-edged console variant (Aquarius only).
  final bool neon;

  final String symbol;
  final String nameZh;
  final String nameEn;
  final ZodiacPalette light;
  final ZodiacPalette dark;

  const ZodiacThemeDef({
    required this.sign,
    required this.skeleton,
    this.neon = false,
    required this.symbol,
    required this.nameZh,
    required this.nameEn,
    required this.light,
    required this.dark,
  });

  String get id => sign.name;

  ZodiacSkeletonSpec get spec => zodiacSkeletonSpecs[skeleton]!;

  ZodiacPalette paletteFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

Color _c(int value) => Color(value);

/// The family, in zodiac order (spec section 5: the selection list
/// follows this order; Sagittarius is not pushed to the top).
final List<ZodiacThemeDef> zodiacThemes = [
  ZodiacThemeDef(
    sign: ZodiacSign.aries,
    skeleton: ZodiacSkeleton.layeredCard,
    symbol: '♈',
    nameZh: '白羊座·熔岩炽阳',
    nameEn: 'Aries · Molten Sun',
    light: ZodiacPalette(
      bgStops: [_c(0xFFFFF8EC), _c(0xFFFFEDD9)],
      surface: _c(0xFFFFFFFF),
      surfaceVariant: _c(0xFFFDEEE3),
      primary: _c(0xFFE63A17),
      secondary: _c(0xFFFF7A1A),
      accent: _c(0xFF0E9F6E),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF33150C),
      textSecondary: _c(0xFF9A6A55),
      outline: _c(0xFFF3DCC8),
      success: _c(0xFF0E9F6E),
      warning: _c(0xFFC77400),
      error: _c(0xFFD92D20),
      selectedStops: [_c(0xFFE63A17)],
      navBar: _c(0xFFFFFDF8),
      heroStops: [_c(0xFFE63A17), _c(0xFFFF7A1A)],
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF170D0B)],
      surface: _c(0xFF261511),
      surfaceVariant: _c(0xFF38221A),
      primary: _c(0xFFFF5A2A),
      secondary: _c(0xFFFFB03A),
      accent: _c(0xFF4ADE80),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFFF7E8DE),
      textSecondary: _c(0xFFB98F77),
      outline: _c(0xFF40261C),
      success: _c(0xFF4ADE80),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFFFF5A2A)],
      navBar: _c(0xFF1D100C),
      heroStops: [_c(0xFFFF5A2A), _c(0xFFFFB03A)],
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.taurus,
    skeleton: ZodiacSkeleton.easternWhitespace,
    symbol: '♉',
    nameZh: '金牛座·森野蜜金',
    nameEn: 'Taurus · Verdant Honey Gold',
    light: ZodiacPalette(
      bgStops: [_c(0xFFFBF6E9)],
      surface: _c(0xFFFBF6E9),
      surfaceVariant: _c(0xFFF1EAD2),
      primary: _c(0xFF0E7A4F),
      secondary: _c(0xFFC9962E),
      accent: _c(0xFF1E2B1C),
      onPrimary: _c(0xFFFFF7EA),
      textPrimary: _c(0xFF1E2B1C),
      textSecondary: _c(0xFF7A7A5E),
      outline: _c(0xFFE3D9BE),
      success: _c(0xFF0E7A4F),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFF0E7A4F)],
      navBar: _c(0xFFFBF6E9),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF0D1F16)],
      surface: _c(0xFF0D1F16),
      surfaceVariant: _c(0xFF16301F),
      primary: _c(0xFF3ECF8E),
      secondary: _c(0xFFE3B341),
      accent: _c(0xFFEAF0DC),
      onPrimary: _c(0xFF0D1F16),
      textPrimary: _c(0xFFEAF0DC),
      textSecondary: _c(0xFF8FA583),
      outline: _c(0xFF24402E),
      success: _c(0xFF3ECF8E),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFF3ECF8E)],
      navBar: _c(0xFF0D1F16),
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.gemini,
    skeleton: ZodiacSkeleton.vibrantClash,
    symbol: '♊',
    nameZh: '双子座·双生撞色',
    nameEn: 'Gemini · Twin Clash',
    light: ZodiacPalette(
      bgStops: [_c(0xFFFFFBEA)],
      surface: _c(0xFFFFFFFF),
      surfaceVariant: _c(0xFFF3EFFF),
      primary: _c(0xFF7C4DFF),
      secondary: _c(0xFFFFC400),
      accent: _c(0xFF0E9F6E),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF17141F),
      textSecondary: _c(0xFF8A8378),
      outline: _c(0xFF17141F),
      success: _c(0xFF0E9F6E),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFF7C4DFF)],
      navBar: _c(0xFFFFFFFF),
      heroStops: [_c(0xFFFFC400)],
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF12101D)],
      surface: _c(0xFF1E1B30),
      surfaceVariant: _c(0xFF262240),
      primary: _c(0xFF7C4DFF),
      secondary: _c(0xFFFFD60A),
      accent: _c(0xFF4ADE80),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFFF5F1DE),
      textSecondary: _c(0xFF8E87A3),
      outline: _c(0xFFF5F1DE),
      success: _c(0xFF4ADE80),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFF7C4DFF)],
      navBar: _c(0xFF12101D),
      heroStops: [_c(0xFFFFD60A)],
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.cancer,
    skeleton: ZodiacSkeleton.plainPaper,
    symbol: '♋',
    nameZh: '巨蟹座·月海珍珠',
    nameEn: 'Cancer · Moonlit Pearl Sea',
    light: ZodiacPalette(
      bgStops: [_c(0xFFF4F8FC)],
      surface: _c(0xFFF4F8FC),
      surfaceVariant: _c(0xFFE7EFF6),
      primary: _c(0xFF3E6FA3),
      secondary: _c(0xFFFF7E67),
      accent: _c(0xFFFF7E67),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF1C2B3A),
      textSecondary: _c(0xFF7C93A8),
      outline: _c(0xFFDCE7F0),
      success: _c(0xFF0E9F6E),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFF1C2B3A)],
      navBar: _c(0xFFFFFFFF),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF0A1E33)],
      surface: _c(0xFF0A1E33),
      surfaceVariant: _c(0xFF12293F),
      primary: _c(0xFF9CC3E5),
      secondary: _c(0xFFFF8F78),
      accent: _c(0xFFFF8F78),
      onPrimary: _c(0xFF0A1E33),
      textPrimary: _c(0xFFE8F1F8),
      textSecondary: _c(0xFF84A3BC),
      outline: _c(0xFF1D3A56),
      success: _c(0xFF4ADE80),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFFE8F1F8)],
      navBar: _c(0xFF0A1E33),
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.leo,
    skeleton: ZodiacSkeleton.layeredCard,
    symbol: '♌',
    nameZh: '狮子座·鎏金日冕',
    nameEn: 'Leo · Gilded Corona',
    light: ZodiacPalette(
      bgStops: [_c(0xFFFDF6E3)],
      surface: _c(0xFFFFFFFF),
      surfaceVariant: _c(0xFFFAEFD2),
      primary: _c(0xFFC07F0A),
      secondary: _c(0xFFF07818),
      accent: _c(0xFF0E9F6E),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF33240A),
      textSecondary: _c(0xFF9A7B4F),
      outline: _c(0xFFEFE0BC),
      success: _c(0xFF0E9F6E),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFFC07F0A)],
      navBar: _c(0xFFFFFDF4),
      heroStops: [_c(0xFFC07F0A), _c(0xFFF07818)],
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF1D130A)],
      surface: _c(0xFF2A1C0E),
      surfaceVariant: _c(0xFF3A2812),
      primary: _c(0xFFE8A812),
      secondary: _c(0xFFFF7E29),
      accent: _c(0xFF7ED492),
      onPrimary: _c(0xFF2A1A05),
      textPrimary: _c(0xFFF7EBD3),
      textSecondary: _c(0xFFB99B6B),
      outline: _c(0xFF43301A),
      success: _c(0xFF7ED492),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF9D8A),
      selectedStops: [_c(0xFFE8A812)],
      navBar: _c(0xFF211508),
      heroStops: [_c(0xFFC07F0A), _c(0xFFE8A812)],
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.virgo,
    skeleton: ZodiacSkeleton.plainPaper,
    symbol: '♍',
    nameZh: '处女座·林间麦穗',
    nameEn: 'Virgo · Forest Wheat',
    light: ZodiacPalette(
      bgStops: [_c(0xFFFAFBF4)],
      surface: _c(0xFFFAFBF4),
      surfaceVariant: _c(0xFFEDF3E2),
      primary: _c(0xFF5FA83C),
      secondary: _c(0xFFD9A62E),
      accent: _c(0xFFD9A62E),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF22301F),
      textSecondary: _c(0xFF84917A),
      outline: _c(0xFFE3EAD3),
      success: _c(0xFF4E9A3D),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFF22301F)],
      navBar: _c(0xFFFFFFFF),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF14230F)],
      surface: _c(0xFF14230F),
      surfaceVariant: _c(0xFF1E3318),
      primary: _c(0xFF8FD45E),
      secondary: _c(0xFFE3B341),
      accent: _c(0xFFE3B341),
      onPrimary: _c(0xFF14230F),
      textPrimary: _c(0xFFEAF2DC),
      textSecondary: _c(0xFF93A87E),
      outline: _c(0xFF2A4420),
      success: _c(0xFF8FD45E),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFFEAF2DC)],
      navBar: _c(0xFF14230F),
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.libra,
    skeleton: ZodiacSkeleton.easternWhitespace,
    symbol: '♎',
    nameZh: '天秤座·云霞天平',
    nameEn: 'Libra · Rosy Balance',
    light: ZodiacPalette(
      bgStops: [_c(0xFFFDF3F6)],
      surface: _c(0xFFFDF3F6),
      surfaceVariant: _c(0xFFFBE7EE),
      primary: _c(0xFFF2668B),
      secondary: _c(0xFF3E9BE9),
      accent: _c(0xFF0E9F6E),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF2E2438),
      textSecondary: _c(0xFF9A8AA5),
      outline: _c(0xFFF0DCE6),
      success: _c(0xFF0E9F6E),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFFF2668B)],
      navBar: _c(0xFFFFF9FB),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF1B1830)],
      surface: _c(0xFF1B1830),
      surfaceVariant: _c(0xFF262244),
      primary: _c(0xFFFF8FAB),
      secondary: _c(0xFF6EC1FF),
      accent: _c(0xFF7ED492),
      onPrimary: _c(0xFF2A1220),
      textPrimary: _c(0xFFF2E9F2),
      textSecondary: _c(0xFF9A8FB5),
      outline: _c(0xFF2E2A4A),
      success: _c(0xFF7ED492),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFFFF8FAB)],
      navBar: _c(0xFF1B1830),
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.scorpio,
    skeleton: ZodiacSkeleton.immersive,
    symbol: '♏',
    nameZh: '天蝎座·深渊红月',
    nameEn: 'Scorpio · Abyssal Crimson Moon',
    light: ZodiacPalette(
      bgStops: [_c(0xFFFBF2F5), _c(0xFFF6EDF7)],
      surface: _c(0xBFFFFFFF),
      surfaceVariant: _c(0x99FFFFFF),
      primary: _c(0xFFA4133C),
      secondary: _c(0xFF7B2CBF),
      accent: _c(0xFF0B8A5F),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF33141F),
      textSecondary: _c(0xFF9A7B8C),
      outline: _c(0x1A33141F),
      success: _c(0xFF0B8A5F),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFFA4133C), _c(0xFF7B2CBF)],
      navBar: _c(0xB3FFFFFF),
      glow: _c(0x40A4133C),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF160710), _c(0xFF0D0512)],
      haloPrimary: _c(0x80A4133C),
      haloSecondary: _c(0x617B2CBF),
      surface: _c(0x0FFFFFFF),
      surfaceVariant: _c(0x14FFFFFF),
      primary: _c(0xFFC21840),
      secondary: _c(0xFFC77DFF),
      accent: _c(0xFF4ADE80),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFFF3E4EA),
      textSecondary: _c(0xFFB08CA0),
      outline: _c(0x24FFFFFF),
      success: _c(0xFF4ADE80),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFFC21840), _c(0xFFC77DFF)],
      navBar: _c(0x990A040E),
      glow: _c(0x80C77DFF),
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.sagittarius,
    skeleton: ZodiacSkeleton.immersive,
    symbol: '♐',
    nameZh: '射手座·靛夜飞箭',
    nameEn: 'Sagittarius · Indigo Night Arrow',
    light: ZodiacPalette(
      bgStops: [_c(0xFFF2F1FE), _c(0xFFEDF9F6)],
      surface: _c(0xC7FFFFFF),
      surfaceVariant: _c(0x99FFFFFF),
      primary: _c(0xFF5B3DF0),
      secondary: _c(0xFF0CA678),
      accent: _c(0xFF221C4A),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF221C4A),
      textSecondary: _c(0xFF7E77AC),
      outline: _c(0x1A221C4A),
      success: _c(0xFF0B8A5F),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFF5B3DF0), _c(0xFF0CA678)],
      navBar: _c(0xB3FFFFFF),
      glow: _c(0x405B3DF0),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF141040), _c(0xFF0D1030), _c(0xFF081A2E)],
      haloPrimary: _c(0x806C4DF6),
      haloSecondary: _c(0x4D2DD4BF),
      surface: _c(0x12FFFFFF),
      surfaceVariant: _c(0x14FFFFFF),
      primary: _c(0xFF6C4DF6),
      secondary: _c(0xFF2DD4BF),
      accent: _c(0xFF2DD4BF),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFFE9EBFF),
      textSecondary: _c(0xFF9AA3D8),
      outline: _c(0x26FFFFFF),
      success: _c(0xFF4ADE80),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFF6C4DF6), _c(0xFF2DD4BF)],
      navBar: _c(0x8C08081A),
      glow: _c(0x802DD4BF),
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.capricorn,
    skeleton: ZodiacSkeleton.consolePanel,
    symbol: '♑',
    nameZh: '摩羯座·岩甲指挥官',
    nameEn: 'Capricorn · Rock-Armored Commander',
    light: ZodiacPalette(
      bgStops: [_c(0xFFF4F2EC)],
      surface: _c(0xFFFFFFFF),
      surfaceVariant: _c(0xFFE9E5DB),
      primary: _c(0xFF3E6390),
      secondary: _c(0xFFB06A32),
      accent: _c(0xFF0B7A4B),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF1B2430),
      textSecondary: _c(0xFF7A7567),
      outline: _c(0xFFD8D2C4),
      success: _c(0xFF0B7A4B),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFF3E6390)],
      navBar: _c(0xFFF4F2EC),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF0E141B)],
      surface: _c(0xFF0A1017),
      surfaceVariant: _c(0xFF16202B),
      primary: _c(0xFF7FA6C9),
      secondary: _c(0xFFC87F4A),
      accent: _c(0xFF4ADE80),
      onPrimary: _c(0xFF0B1220),
      textPrimary: _c(0xFFDEE6EC),
      textSecondary: _c(0xFF71808E),
      outline: _c(0xFF22303E),
      success: _c(0xFF4ADE80),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFF7FA6C9)],
      navBar: _c(0xFF0E141B),
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.aquarius,
    skeleton: ZodiacSkeleton.consolePanel,
    neon: true,
    symbol: '♒',
    nameZh: '水瓶座·霓虹潮汐',
    nameEn: 'Aquarius · Neon Tide',
    light: ZodiacPalette(
      bgStops: [_c(0xFFEFFCFF)],
      surface: _c(0xFFFFFFFF),
      surfaceVariant: _c(0xFFDFF4FB),
      primary: _c(0xFF0090D9),
      secondary: _c(0xFF00B386),
      accent: _c(0xFF0B2B3A),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF0B2B3A),
      textSecondary: _c(0xFF6E93A5),
      outline: _c(0xFFCBE7F2),
      success: _c(0xFF00B386),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFF0090D9), _c(0xFF00B386)],
      navBar: _c(0xFFEFFCFF),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF03141C)],
      surface: _c(0xFF04202C),
      surfaceVariant: _c(0xFF06303F),
      primary: _c(0xFF00C2FF),
      secondary: _c(0xFF2BFFC8),
      accent: _c(0xFFDFFBFF),
      onPrimary: _c(0xFF03202E),
      textPrimary: _c(0xFFDFFBFF),
      textSecondary: _c(0xFF5E8CA3),
      outline: _c(0xFF0E4258),
      success: _c(0xFF2BFFC8),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFF00C2FF), _c(0xFF2BFFC8)],
      navBar: _c(0xFF03141C),
    ),
  ),
  ZodiacThemeDef(
    sign: ZodiacSign.pisces,
    skeleton: ZodiacSkeleton.immersive,
    symbol: '♓',
    nameZh: '双鱼座·梦境极光',
    nameEn: 'Pisces · Dream Aurora',
    light: ZodiacPalette(
      bgStops: [_c(0xFFFDF2F8), _c(0xFFE8F1FF), _c(0xFFE6FBF3)],
      haloPrimary: _c(0x73FFA8D6),
      haloSecondary: _c(0x595EEAD4),
      surface: _c(0xA8FFFFFF),
      surfaceVariant: _c(0x8CFFFFFF),
      primary: _c(0xFF7B61C9),
      secondary: _c(0xFF2FA98C),
      accent: _c(0xFFF472B6),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFF2A2440),
      textSecondary: _c(0xFF7A7396),
      outline: _c(0x172A2440),
      success: _c(0xFF0B8A5F),
      warning: _c(0xFFB45309),
      error: _c(0xFFC23333),
      selectedStops: [_c(0xFF7B61C9), _c(0xFF2FA98C)],
      navBar: _c(0x99FFFFFF),
      glow: _c(0x597B61C9),
    ),
    dark: ZodiacPalette(
      bgStops: [_c(0xFF1B1140), _c(0xFF150E2E), _c(0xFF0B1B33)],
      surface: _c(0x12FFFFFF),
      surfaceVariant: _c(0x14FFFFFF),
      primary: _c(0xFFA78BFA),
      secondary: _c(0xFF5EEAD4),
      accent: _c(0xFFF472B6),
      onPrimary: _c(0xFFFFFFFF),
      textPrimary: _c(0xFFECE7FB),
      textSecondary: _c(0xFF9A8FC4),
      outline: _c(0x24FFFFFF),
      success: _c(0xFF4ADE80),
      warning: _c(0xFFFFB03A),
      error: _c(0xFFFF8A70),
      selectedStops: [_c(0xFFA78BFA), _c(0xFF5EEAD4)],
      navBar: _c(0x8C0A061A),
      glow: _c(0x73A78BFA),
    ),
  ),
];

/// The family default (spec section 5): Sagittarius, always.
final ZodiacThemeDef defaultZodiacTheme = zodiacThemes.firstWhere(
  (def) => def.sign == ZodiacSign.sagittarius,
);

/// Resolves a stored theme id. Unknown values (including every
/// legacy upstream theme selection, which is never migrated) fall
/// back to the family default — there is no second authority.
ZodiacThemeDef zodiacById(String? id) {
  for (final def in zodiacThemes) {
    if (def.id == id) return def;
  }
  return defaultZodiacTheme;
}

/// Runtime carrier for the active variant, exposed through
/// ThemeData.extensions so any widget can read the tokens.
@immutable
class ZodiacThemeExtension extends ThemeExtension<ZodiacThemeExtension> {
  final ZodiacThemeDef def;
  final ZodiacPalette palette;

  const ZodiacThemeExtension({required this.def, required this.palette});

  factory ZodiacThemeExtension.of(ZodiacThemeDef def, Brightness brightness) =>
      ZodiacThemeExtension(def: def, palette: def.paletteFor(brightness));

  ZodiacSkeletonSpec get spec => def.spec;
  bool get neon => def.neon;

  @override
  ZodiacThemeExtension copyWith({
    ZodiacThemeDef? def,
    ZodiacPalette? palette,
  }) => ZodiacThemeExtension(
    def: def ?? this.def,
    palette: palette ?? this.palette,
  );

  @override
  ZodiacThemeExtension lerp(
    ThemeExtension<ZodiacThemeExtension>? other,
    double t,
  ) {
    if (other is! ZodiacThemeExtension) return this;
    // Theme switches are instant per spec; no color interpolation.
    return t < 0.5 ? this : other;
  }
}

extension ZodiacContext on BuildContext {
  /// The active constellation tokens. Widgets pumped outside the
  /// app's own theme (unit tests, embeds) fall back to the family
  /// default in the ambient brightness.
  ZodiacThemeExtension get zodiac {
    final ext = Theme.of(this).extension<ZodiacThemeExtension>();
    if (ext != null) return ext;
    return ZodiacThemeExtension.of(
      defaultZodiacTheme,
      Theme.of(this).brightness,
    );
  }
}

/// Builds the Material [ColorScheme] for one variant. Every slot
/// comes straight from the palette — no seed generation and no
/// chroma clamping, so the family's vivid colors survive verbatim.
ColorScheme zodiacColorScheme(ZodiacPalette p, Brightness brightness) {
  return ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.surfaceVariant,
    onPrimaryContainer: p.textPrimary,
    secondary: p.secondary,
    onSecondary: p.onPrimary,
    secondaryContainer: p.surfaceVariant,
    onSecondaryContainer: p.textPrimary,
    tertiary: p.accent,
    onTertiary: p.onPrimary,
    tertiaryContainer: p.surfaceVariant,
    onTertiaryContainer: p.textPrimary,
    error: p.error,
    onError: const Color(0xFFFFFFFF),
    errorContainer: p.surfaceVariant,
    onErrorContainer: p.error,
    surface: p.surface,
    onSurface: p.textPrimary,
    surfaceDim: p.surfaceVariant,
    surfaceBright: p.surface,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surfaceVariant,
    surfaceContainerHigh: p.surfaceVariant,
    surfaceContainerHighest: p.surfaceVariant,
    onSurfaceVariant: p.textSecondary,
    outline: p.outline,
    outlineVariant: p.outline.withValues(alpha: 0.55),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    inverseSurface: p.textPrimary,
    onInverseSurface: p.bgStops.first,
    inversePrimary: p.secondary,
    surfaceTint: p.primary,
  );
}
