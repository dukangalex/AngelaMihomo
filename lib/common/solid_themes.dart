import 'package:material_ui/material_ui.dart';

import 'zodiac_themes.dart';

/// The Solid Zodiac series （纯色生肖， T224): twelve themes, one per
/// Chinese zodiac animal, sibling to the twelve-constellation and
/// deep-space series under the 星辰大海 umbrella. Each theme's
/// artwork is a single full-canvas image — a solid dark base with a
/// faint line-sketch of its animal already composited in — painted
/// by the backdrop as a full-bleed cover layer with no blur and no
/// opacity reduction; there is no constellation, no guardian, no
/// motif and no name plate.
///
/// Every variant's background gradient ends at, and its navBar is,
/// the exact base color sampled from its artwork's pixels, so the
/// UI chrome blends seamlessly into the image. The rest of each
/// palette is built around that hue in the deep-space style.
class SolidThemeDef {
  final String id;
  final String nameZh;
  final String nameEn;
  final ZodiacSkeleton skeleton;
  final ZodiacVariant variant;

  /// The full-canvas artwork for this theme, under
  /// `assets/images/solid/`.
  final String assetPath;

  const SolidThemeDef({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.skeleton,
    required this.variant,
    required this.assetPath,
  });
}

/// All twelve animals in Chinese zodiac order （鼠牛虎兔龙蛇马羊猴鸡狗猪）.
const List<SolidThemeDef> solidThemeDefs = [
  SolidThemeDef(
    id: 'solid-rat',
    nameZh: '鼠',
    nameEn: 'Rat',
    skeleton: ZodiacSkeleton.layered,
    assetPath: 'assets/images/solid/rat.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF2E3038), Color(0xFF26282E)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFF6C8AE5),
      secondary: Color(0xFF997CDE),
      accent: Color(0xFF89D3E6),
      onPrimary: Color(0xFF0E1425),
      textPrimary: Color(0xFFE9EBF1),
      textSecondary: Color(0xFFABB1C4),
      outline: Color(0xFF373A43),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF26282E),
      selected: ZodiacPaint.solid(Color(0xFF6C8AE5)),
      hero: ZodiacPaint.gradient([Color(0xFF6C8AE5), Color(0xFF997CDE)]),
      glow: Color(0x596C8AE5),
      glows: [
        ZodiacGlow(Color(0x386C8AE5), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x26997CDE), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-ox',
    nameZh: '牛',
    nameEn: 'Ox',
    skeleton: ZodiacSkeleton.eastern,
    assetPath: 'assets/images/solid/ox.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF3F2C20), Color(0xFF33241A)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFFE59C6C),
      secondary: Color(0xFFDED87C),
      accent: Color(0xFFE68996),
      onPrimary: Color(0xFF25170E),
      textPrimary: Color(0xFFF3ECE7),
      textSecondary: Color(0xFFCDB3A2),
      outline: Color(0xFF4C3627),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF33241A),
      selected: ZodiacPaint.solid(Color(0xFFE59C6C)),
      hero: ZodiacPaint.gradient([Color(0xFFE59C6C), Color(0xFFDED87C)]),
      glow: Color(0x59E59C6C),
      glows: [
        ZodiacGlow(Color(0x38E59C6C), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x26DED87C), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-tiger',
    nameZh: '虎',
    nameEn: 'Tiger',
    skeleton: ZodiacSkeleton.vibrant,
    assetPath: 'assets/images/solid/tiger.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF351D44), Color(0xFF2B1838)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFFB46CE5),
      secondary: Color(0xFFDE7CD1),
      accent: Color(0xFF8E89E6),
      onPrimary: Color(0xFF1C0E25),
      textPrimary: Color(0xFFEEE7F3),
      textSecondary: Color(0xFFBCA2CD),
      outline: Color(0xFF402353),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF2B1838),
      selected: ZodiacPaint.solid(Color(0xFFB46CE5)),
      hero: ZodiacPaint.gradient([Color(0xFFB46CE5), Color(0xFFDE7CD1)]),
      glow: Color(0x59B46CE5),
      glows: [
        ZodiacGlow(Color(0x38B46CE5), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x26DE7CD1), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-rabbit',
    nameZh: '兔',
    nameEn: 'Rabbit',
    skeleton: ZodiacSkeleton.paper,
    assetPath: 'assets/images/solid/rabbit.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF432935), Color(0xFF38222C)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFFE56CA3),
      secondary: Color(0xFFDE857C),
      accent: Color(0xFFE689E6),
      onPrimary: Color(0xFF250E18),
      textPrimary: Color(0xFFF3E7ED),
      textSecondary: Color(0xFFCDA2B6),
      outline: Color(0xFF50303F),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF38222C),
      selected: ZodiacPaint.solid(Color(0xFFE56CA3)),
      hero: ZodiacPaint.gradient([Color(0xFFE56CA3), Color(0xFFDE857C)]),
      glow: Color(0x59E56CA3),
      glows: [
        ZodiacGlow(Color(0x38E56CA3), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x26DE857C), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-dragon',
    nameZh: '龙',
    nameEn: 'Dragon',
    skeleton: ZodiacSkeleton.immersive,
    assetPath: 'assets/images/solid/dragon.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF242C4E), Color(0xFF1E2542)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFF6C83E5),
      secondary: Color(0xFF9E7CDE),
      accent: Color(0xFF89CDE6),
      onPrimary: Color(0xFF0E1225),
      textPrimary: Color(0xFFE7E9F3),
      textSecondary: Color(0xFFA2ABCD),
      outline: Color(0xFF2A345C),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF1E2542),
      selected: ZodiacPaint.solid(Color(0xFF6C83E5)),
      hero: ZodiacPaint.gradient([Color(0xFF6C83E5), Color(0xFF9E7CDE)]),
      glow: Color(0x596C83E5),
      glows: [
        ZodiacGlow(Color(0x386C83E5), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x269E7CDE), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-snake',
    nameZh: '蛇',
    nameEn: 'Snake',
    skeleton: ZodiacSkeleton.layered,
    assetPath: 'assets/images/solid/snake.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF1C4747), Color(0xFF173A3A)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFF6CE5E5),
      secondary: Color(0xFF7CA9DE),
      accent: Color(0xFF89E6B4),
      onPrimary: Color(0xFF0E2525),
      textPrimary: Color(0xFFE7F3F3),
      textSecondary: Color(0xFFA2CDCD),
      outline: Color(0xFF225555),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF173A3A),
      selected: ZodiacPaint.solid(Color(0xFF6CE5E5)),
      hero: ZodiacPaint.gradient([Color(0xFF6CE5E5), Color(0xFF7CA9DE)]),
      glow: Color(0x596CE5E5),
      glows: [
        ZodiacGlow(Color(0x386CE5E5), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x267CA9DE), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-horse',
    nameZh: '马',
    nameEn: 'Horse',
    skeleton: ZodiacSkeleton.vibrant,
    assetPath: 'assets/images/solid/horse.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF193A2B), Color(0xFF142E22)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFF6CE5AD),
      secondary: Color(0xFF7CD7DE),
      accent: Color(0xFF89E689),
      onPrimary: Color(0xFF0E251A),
      textPrimary: Color(0xFFE7F3EE),
      textSecondary: Color(0xFFA2CDB9),
      outline: Color(0xFF204936),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF142E22),
      selected: ZodiacPaint.solid(Color(0xFF6CE5AD)),
      hero: ZodiacPaint.gradient([Color(0xFF6CE5AD), Color(0xFF7CD7DE)]),
      glow: Color(0x596CE5AD),
      glows: [
        ZodiacGlow(Color(0x386CE5AD), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x267CD7DE), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-goat',
    nameZh: '羊',
    nameEn: 'Goat',
    skeleton: ZodiacSkeleton.eastern,
    assetPath: 'assets/images/solid/goat.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF393F1F), Color(0xFF2E3319)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFFCEE56C),
      secondary: Color(0xFF97DE7C),
      accent: Color(0xFFE6C689),
      onPrimary: Color(0xFF21250E),
      textPrimary: Color(0xFFF1F3E7),
      textSecondary: Color(0xFFC5CDA2),
      outline: Color(0xFF454D26),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF2E3319),
      selected: ZodiacPaint.solid(Color(0xFFCEE56C)),
      hero: ZodiacPaint.gradient([Color(0xFFCEE56C), Color(0xFF97DE7C)]),
      glow: Color(0x59CEE56C),
      glows: [
        ZodiacGlow(Color(0x38CEE56C), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x2697DE7C), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-monkey',
    nameZh: '猴',
    nameEn: 'Monkey',
    skeleton: ZodiacSkeleton.vibrant,
    assetPath: 'assets/images/solid/monkey.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF483416), Color(0xFF3A2A12)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFFECB665),
      secondary: Color(0xFFD5E576),
      accent: Color(0xFFEB8A84),
      onPrimary: Color(0xFF271C0C),
      textPrimary: Color(0xFFF3EEE7),
      textSecondary: Color(0xFFCDBCA2),
      outline: Color(0xFF573F1B),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF3A2A12),
      selected: ZodiacPaint.solid(Color(0xFFECB665)),
      hero: ZodiacPaint.gradient([Color(0xFFECB665), Color(0xFFD5E576)]),
      glow: Color(0x59ECB665),
      glows: [
        ZodiacGlow(Color(0x38ECB665), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x26D5E576), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-rooster',
    nameZh: '鸡',
    nameEn: 'Rooster',
    skeleton: ZodiacSkeleton.layered,
    assetPath: 'assets/images/solid/rooster.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF441D22), Color(0xFF38181C)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFFE56C7B),
      secondary: Color(0xFFDEA57C),
      accent: Color(0xFFE689C7),
      onPrimary: Color(0xFF250E11),
      textPrimary: Color(0xFFF3E7E8),
      textSecondary: Color(0xFFCDA2A8),
      outline: Color(0xFF532329),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF38181C),
      selected: ZodiacPaint.solid(Color(0xFFE56C7B)),
      hero: ZodiacPaint.gradient([Color(0xFFE56C7B), Color(0xFFDEA57C)]),
      glow: Color(0x59E56C7B),
      glows: [
        ZodiacGlow(Color(0x38E56C7B), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x26DEA57C), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-dog',
    nameZh: '狗',
    nameEn: 'Dog',
    skeleton: ZodiacSkeleton.console,
    assetPath: 'assets/images/solid/dog.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF3A3420), Color(0xFF2F2A1A)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFFE5C86C),
      secondary: Color(0xFFC1DE7C),
      accent: Color(0xFFE69E89),
      onPrimary: Color(0xFF25200E),
      textPrimary: Color(0xFFF3F0E7),
      textSecondary: Color(0xFFCDC3A2),
      outline: Color(0xFF484028),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF2F2A1A),
      selected: ZodiacPaint.solid(Color(0xFFE5C86C)),
      hero: ZodiacPaint.gradient([Color(0xFFE5C86C), Color(0xFFC1DE7C)]),
      glow: Color(0x59E5C86C),
      glows: [
        ZodiacGlow(Color(0x38E5C86C), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x26C1DE7C), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
  SolidThemeDef(
    id: 'solid-pig',
    nameZh: '猪',
    nameEn: 'Pig',
    skeleton: ZodiacSkeleton.paper,
    assetPath: 'assets/images/solid/pig.webp',
    variant: ZodiacVariant(
      background: ZodiacPaint.gradient([Color(0xFF3E2533), Color(0xFF331E2A)]),
      surface: Color(0x12FFFFFF),
      surfaceVariant: Color(0x14FFFFFF),
      primary: Color(0xFFE56CB1),
      secondary: Color(0xFFDE7C80),
      accent: Color(0xFFDC89E6),
      onPrimary: Color(0xFF250E1B),
      textPrimary: Color(0xFFF3E7EE),
      textSecondary: Color(0xFFCDA2BB),
      outline: Color(0xFF4B2C3E),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFFB03A),
      error: Color(0xFFFF8A70),
      navBar: Color(0xFF331E2A),
      selected: ZodiacPaint.solid(Color(0xFFE56CB1)),
      hero: ZodiacPaint.gradient([Color(0xFFE56CB1), Color(0xFFDE7C80)]),
      glow: Color(0x59E56CB1),
      glows: [
        ZodiacGlow(Color(0x38E56CB1), ZodiacGlowPos.topRight),
        ZodiacGlow(Color(0x26DE7C80), ZodiacGlowPos.centerLeft),
      ],
    ),
  ),
];

List<SolidThemeDef> get solidThemes => solidThemeDefs;

/// Series labels under the 星辰大海 umbrella (T182 pattern).
const solidSeriesNameZh = '纯色生肖';
const solidSeriesNameEn = 'Solid Zodiac';

SolidThemeDef? solidThemeById(String? id) {
  for (final def in solidThemeDefs) {
    if (def.id == id) return def;
  }
  return null;
}

bool isSolidThemeId(String? id) => solidThemeById(id) != null;
