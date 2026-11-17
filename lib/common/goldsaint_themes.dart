import 'package:material_ui/material_ui.dart';

import 'zodiac_themes.dart';

/// The Golden Saints series （星辰大海之黄金圣斗士）: the twelve
/// gold saints, one per sign, sibling to the twelve-constellation
/// series. A saint theme mirrors its sign's skeleton and
/// constellation (resolved through the registry) and re-skins it in
/// gold — the saint's palette is its own 21-token set, dominated by
/// gold with the sign's element color as its secondary.
class GoldSaintThemeDef {
  final String id;

  /// The constellation theme this saint mirrors (skeleton, sign
  /// and constellation come from it).
  final String zodiacId;
  final String nameZh;
  final String nameEn;
  final ZodiacVariant variant;

  const GoldSaintThemeDef({
    required this.id,
    required this.zodiacId,
    required this.nameZh,
    required this.nameEn,
    required this.variant,
  });
}

ZodiacVariant _gold({
  required List<Color> bg,
  required Color primary,
  required Color secondary,
  required Color accent,
  required Color textPrimary,
  required Color textSecondary,
  required Color outline,
}) {
  return ZodiacVariant(
    background: ZodiacPaint.gradient(bg),
    surface: const Color(0x12FFFFFF),
    surfaceVariant: const Color(0x14FFFFFF),
    primary: primary,
    secondary: secondary,
    accent: accent,
    onPrimary: const Color(0xFF2A1D05),
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    outline: outline,
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFFFB03A),
    error: const Color(0xFFFF8A70),
    navBar: bg.last,
    selected: ZodiacPaint.solid(primary),
    hero: ZodiacPaint.gradient([primary, secondary]),
    glow: primary.withValues(alpha: 0.4),
    glows: [
      ZodiacGlow(primary.withValues(alpha: 0.25), ZodiacGlowPos.topRight),
      ZodiacGlow(secondary.withValues(alpha: 0.16), ZodiacGlowPos.centerLeft),
    ],
  );
}

/// All twelve gold saints in zodiac order.
final List<GoldSaintThemeDef> goldSaintThemeDefs = [
  GoldSaintThemeDef(
    id: 'gold-aries',
    zodiacId: 'aries',
    nameZh: '白羊座·穆',
    nameEn: 'Aries · Mu',
    variant: _gold(
      bg: [Color(0xFF241A08), Color(0xFF171006)],
      primary: Color(0xFFF2C14E),
      secondary: Color(0xFFFF5A2A),
      accent: Color(0xFF4ADE80),
      textPrimary: Color(0xFFF9F0DC),
      textSecondary: Color(0xFFD8C4A0),
      outline: Color(0xFF3A2C14),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-taurus',
    zodiacId: 'taurus',
    nameZh: '金牛座·阿鲁迪巴',
    nameEn: 'Taurus · Aldebaran',
    variant: _gold(
      bg: [Color(0xFF211A0A), Color(0xFF141005)],
      primary: Color(0xFFE8C86A),
      secondary: Color(0xFF3ECF8E),
      accent: Color(0xFFEAF0DC),
      textPrimary: Color(0xFFF8F2DE),
      textSecondary: Color(0xFFD5C69E),
      outline: Color(0xFF372C12),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-gemini',
    zodiacId: 'gemini',
    nameZh: '双子座·撒加',
    nameEn: 'Gemini · Saga',
    variant: _gold(
      bg: [Color(0xFF251C09), Color(0xFF181106)],
      primary: Color(0xFFF2CE6B),
      secondary: Color(0xFF9D7BEE),
      accent: Color(0xFF4CC9F0),
      textPrimary: Color(0xFFFAF3DC),
      textSecondary: Color(0xFFDBC9A4),
      outline: Color(0xFF3B3014),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-cancer',
    zodiacId: 'cancer',
    nameZh: '巨蟹座·迪斯马斯克',
    nameEn: 'Cancer · Deathmask',
    variant: _gold(
      bg: [Color(0xFF201A10), Color(0xFF131007)],
      primary: Color(0xFFEBD9A8),
      secondary: Color(0xFF7FB2F0),
      accent: Color(0xFFF2A7C3),
      textPrimary: Color(0xFFF8F3E4),
      textSecondary: Color(0xFFD2C4A6),
      outline: Color(0xFF362E18),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-leo',
    zodiacId: 'leo',
    nameZh: '狮子座·艾欧里亚',
    nameEn: 'Leo · Aiolia',
    variant: _gold(
      bg: [Color(0xFF2A1E07), Color(0xFF1B1204)],
      primary: Color(0xFFFFC93A),
      secondary: Color(0xFFFF7847),
      accent: Color(0xFFFFE9A8),
      textPrimary: Color(0xFFFAF0D2),
      textSecondary: Color(0xFFE0CCA2),
      outline: Color(0xFF403214),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-virgo',
    zodiacId: 'virgo',
    nameZh: '处女座·沙加',
    nameEn: 'Virgo · Shaka',
    variant: _gold(
      bg: [Color(0xFF221C0B), Color(0xFF151106)],
      primary: Color(0xFFE3C878),
      secondary: Color(0xFF6FCF97),
      accent: Color(0xFFEDE6C8),
      textPrimary: Color(0xFFF8F4DE),
      textSecondary: Color(0xFFD6CAA2),
      outline: Color(0xFF383013),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-libra',
    zodiacId: 'libra',
    nameZh: '天秤座·童虎',
    nameEn: 'Libra · Dohko',
    variant: _gold(
      bg: [Color(0xFF241A10), Color(0xFF171007)],
      primary: Color(0xFFEBCB8B),
      secondary: Color(0xFFF2A7C3),
      accent: Color(0xFF7FB2F0),
      textPrimary: Color(0xFFF9F1E2),
      textSecondary: Color(0xFFD8C6AC),
      outline: Color(0xFF3A2C1A),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-scorpio',
    zodiacId: 'scorpio',
    nameZh: '天蝎座·米罗',
    nameEn: 'Scorpio · Milo',
    variant: _gold(
      bg: [Color(0xFF231309), Color(0xFF160B05)],
      primary: Color(0xFFD9A441),
      secondary: Color(0xFF9E3A5C),
      accent: Color(0xFFB48CF2),
      textPrimary: Color(0xFFF7EDDA),
      textSecondary: Color(0xFFD6BCA4),
      outline: Color(0xFF38220F),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-sagittarius',
    zodiacId: 'sagittarius',
    nameZh: '射手座·艾俄洛斯',
    nameEn: 'Sagittarius · Aiolos',
    variant: _gold(
      bg: [Color(0xFF26180B), Color(0xFF190F06)],
      primary: Color(0xFFF2B33A),
      secondary: Color(0xFF7FB2F0),
      accent: Color(0xFF4ADE80),
      textPrimary: Color(0xFFFAF0DA),
      textSecondary: Color(0xFFDECBA6),
      outline: Color(0xFF3D2A12),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-capricorn',
    zodiacId: 'capricorn',
    nameZh: '摩羯座·修罗',
    nameEn: 'Capricorn · Shura',
    variant: _gold(
      bg: [Color(0xFF211810), Color(0xFF141007)],
      primary: Color(0xFFC9A86A),
      secondary: Color(0xFFB0764A),
      accent: Color(0xFF9FD8E8),
      textPrimary: Color(0xFFF6EFDD),
      textSecondary: Color(0xFFD2C2A2),
      outline: Color(0xFF352A16),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-aquarius',
    zodiacId: 'aquarius',
    nameZh: '水瓶座·卡妙',
    nameEn: 'Aquarius · Camus',
    variant: _gold(
      bg: [Color(0xFF1E1A0E), Color(0xFF121006)],
      primary: Color(0xFFE8D28A),
      secondary: Color(0xFF4CC9F0),
      accent: Color(0xFFF06A8A),
      textPrimary: Color(0xFFF8F3DE),
      textSecondary: Color(0xFFCFC49E),
      outline: Color(0xFF332E15),
    ),
  ),
  GoldSaintThemeDef(
    id: 'gold-pisces',
    zodiacId: 'pisces',
    nameZh: '双鱼座·阿布罗狄',
    nameEn: 'Pisces · Aphrodite',
    variant: _gold(
      bg: [Color(0xFF201812), Color(0xFF130E08)],
      primary: Color(0xFFEBD3A0),
      secondary: Color(0xFF8FC7EE),
      accent: Color(0xFFF2A7C3),
      textPrimary: Color(0xFFF8F2E2),
      textSecondary: Color(0xFFD4C2AA),
      outline: Color(0xFF372A18),
    ),
  ),
];

List<GoldSaintThemeDef> get goldSaintThemes => goldSaintThemeDefs;

/// Series labels under the 星辰大海 umbrella.
const goldSaintSeriesNameZh = '星辰大海之黄金圣斗士';
const goldSaintSeriesNameEn = 'Starry Sea · The Golden Saints';

GoldSaintThemeDef? goldSaintThemeById(String? id) {
  for (final def in goldSaintThemeDefs) {
    if (def.id == id) return def;
  }
  return null;
}
