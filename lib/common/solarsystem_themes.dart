import 'package:material_ui/material_ui.dart';

import 'zodiac_themes.dart';

/// The Solar System Home series （星辰大海之太阳系家园）: the eight
/// planets as plain-background themes. Each background is one flat
/// base color carrying exactly one planet, softly blurred
/// ([SolarPlanetPainter]) — the family's quiet, solid form. The
/// variant's background is a solid paint, so every surface derived
/// from it stays in the same flat tone.
class SolarSystemThemeDef {
  final String id;
  final SolarBody body;
  final String nameZh;
  final String nameEn;
  final ZodiacSkeleton skeleton;
  final ZodiacVariant variant;

  const SolarSystemThemeDef({
    required this.id,
    required this.body,
    required this.nameZh,
    required this.nameEn,
    required this.skeleton,
    required this.variant,
  });
}

ZodiacVariant _planet({
  required Color bg,
  required Color primary,
  required Color secondary,
  required Color accent,
  required Color onPrimary,
  required Color textPrimary,
  required Color textSecondary,
  required Color outline,
  required Color navBar,
}) {
  return ZodiacVariant(
    background: ZodiacPaint.solid(bg),
    surface: const Color(0x12FFFFFF),
    surfaceVariant: const Color(0x14FFFFFF),
    primary: primary,
    secondary: secondary,
    accent: accent,
    onPrimary: onPrimary,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    outline: outline,
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFFFB03A),
    error: const Color(0xFFFF8A70),
    navBar: navBar,
    selected: ZodiacPaint.solid(primary),
    hero: ZodiacPaint.none,
    glow: primary.withValues(alpha: 0.25),
    glows: [
      ZodiacGlow(primary.withValues(alpha: 0.10), ZodiacGlowPos.topRight),
      ZodiacGlow(secondary.withValues(alpha: 0.08), ZodiacGlowPos.centerLeft),
    ],
  );
}

/// All eight planets in solar order.
final List<SolarSystemThemeDef> solarSystemThemeDefs = [
  SolarSystemThemeDef(
    id: 'sol-mercury',
    body: SolarBody.mercury,
    nameZh: '水星·灰烬',
    nameEn: 'Mercury · Ashen World',
    skeleton: ZodiacSkeleton.layered,
    variant: _planet(
      bg: Color(0xFF161310),
      primary: Color(0xFFB8AFA4),
      secondary: Color(0xFF6E675C),
      accent: Color(0xFFE8E2D4),
      onPrimary: Color(0xFF262019),
      textPrimary: Color(0xFFF2EEE6),
      textSecondary: Color(0xFFCFC8BC),
      outline: Color(0xFF2E2A24),
      navBar: Color(0xFF100E0B),
    ),
  ),
  SolarSystemThemeDef(
    id: 'sol-venus',
    body: SolarBody.venus,
    nameZh: '金星·晨昏',
    nameEn: 'Venus · The Morning Star',
    skeleton: ZodiacSkeleton.layered,
    variant: _planet(
      bg: Color(0xFF181207),
      primary: Color(0xFFE8C87E),
      secondary: Color(0xFFB98A4A),
      accent: Color(0xFFF2E3BC),
      onPrimary: Color(0xFF2A1D05),
      textPrimary: Color(0xFFF8F1DC),
      textSecondary: Color(0xFFDECFA8),
      outline: Color(0xFF33270F),
      navBar: Color(0xFF120D05),
    ),
  ),
  SolarSystemThemeDef(
    id: 'sol-earth',
    body: SolarBody.earth,
    nameZh: '地球·蔚蓝',
    nameEn: 'Earth · The Blue Home',
    skeleton: ZodiacSkeleton.layered,
    variant: _planet(
      bg: Color(0xFF0B1320),
      primary: Color(0xFF6CB4EE),
      secondary: Color(0xFF3E7FC4),
      accent: Color(0xFF7FE3A0),
      onPrimary: Color(0xFF0B1A29),
      textPrimary: Color(0xFFEAF3FB),
      textSecondary: Color(0xFFB4C9DE),
      outline: Color(0xFF1E2C40),
      navBar: Color(0xFF070C14),
    ),
  ),
  SolarSystemThemeDef(
    id: 'sol-mars',
    body: SolarBody.mars,
    nameZh: '火星·赤砂',
    nameEn: 'Mars · The Red Sands',
    skeleton: ZodiacSkeleton.layered,
    variant: _planet(
      bg: Color(0xFF190D07),
      primary: Color(0xFFE07A4E),
      secondary: Color(0xFFA34A28),
      accent: Color(0xFFF2C14E),
      onPrimary: Color(0xFF2A1408),
      textPrimary: Color(0xFFF8EDE4),
      textSecondary: Color(0xFFDCBCA6),
      outline: Color(0xFF38200F),
      navBar: Color(0xFF110805),
    ),
  ),
  SolarSystemThemeDef(
    id: 'sol-jupiter',
    body: SolarBody.jupiter,
    nameZh: '木星·巨行',
    nameEn: 'Jupiter · The Giant',
    skeleton: ZodiacSkeleton.layered,
    variant: _planet(
      bg: Color(0xFF171008),
      primary: Color(0xFFE3C298),
      secondary: Color(0xFFB0764A),
      accent: Color(0xFFF2E3BC),
      onPrimary: Color(0xFF2A1C0A),
      textPrimary: Color(0xFFF8F1E2),
      textSecondary: Color(0xFFE2CCA6),
      outline: Color(0xFF33240F),
      navBar: Color(0xFF100A05),
    ),
  ),
  SolarSystemThemeDef(
    id: 'sol-saturn',
    body: SolarBody.saturn,
    nameZh: '土星·光环',
    nameEn: 'Saturn · The Ringed One',
    skeleton: ZodiacSkeleton.layered,
    variant: _planet(
      bg: Color(0xFF161106),
      primary: Color(0xFFEBD9A8),
      secondary: Color(0xFFBFA05E),
      accent: Color(0xFFF2E9CC),
      onPrimary: Color(0xFF2A2008),
      textPrimary: Color(0xFFF9F3DF),
      textSecondary: Color(0xFFE4D3A4),
      outline: Color(0xFF332A10),
      navBar: Color(0xFF110D04),
    ),
  ),
  SolarSystemThemeDef(
    id: 'sol-uranus',
    body: SolarBody.uranus,
    nameZh: '天王星·青冥',
    nameEn: 'Uranus · The Pale Cyan',
    skeleton: ZodiacSkeleton.layered,
    variant: _planet(
      bg: Color(0xFF0B1515),
      primary: Color(0xFF9FE3E0),
      secondary: Color(0xFF5FBFB8),
      accent: Color(0xFFE8FFFB),
      onPrimary: Color(0xFF06302C),
      textPrimary: Color(0xFFEBFAF8),
      textSecondary: Color(0xFFB2DCD8),
      outline: Color(0xFF1C3030),
      navBar: Color(0xFF060D0D),
    ),
  ),
  SolarSystemThemeDef(
    id: 'sol-neptune',
    body: SolarBody.neptune,
    nameZh: '海王星·深蓝',
    nameEn: 'Neptune · The Deep Blue',
    skeleton: ZodiacSkeleton.layered,
    variant: _planet(
      bg: Color(0xFF0B1020),
      primary: Color(0xFF6E8CF0),
      secondary: Color(0xFF3E56C4),
      accent: Color(0xFF9FD8E8),
      onPrimary: Color(0xFFFFFFFF),
      textPrimary: Color(0xFFEAEFFC),
      textSecondary: Color(0xFFB6C2E4),
      outline: Color(0xFF1E2A4A),
      navBar: Color(0xFF070A14),
    ),
  ),
];

List<SolarSystemThemeDef> get solarSystemThemes => solarSystemThemeDefs;

/// Series labels under the 星辰大海 umbrella.
const solarSystemSeriesNameZh = '星辰大海之太阳系家园';
const solarSystemSeriesNameEn = 'Starry Sea · Solar System Home';

SolarSystemThemeDef? solarSystemThemeById(String? id) {
  for (final def in solarSystemThemeDefs) {
    if (def.id == id) return def;
  }
  return null;
}
