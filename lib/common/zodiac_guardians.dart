import 'package:bett_box/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';
import 'constant.dart';
import 'zodiac_themes.dart';

/// The guardian deity of one zodiac theme (T159; user spec finalised
/// 2026-11-15 22:25: every existing theme element stays untouched — the
/// guardian is one added layer on the dashboard only, anchored lower-left
/// raised, in Japanese-anime line style, gazing up at the theme's own
/// constellation chart at the top of the backdrop, with a name plate).
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

/// The dashboard-only guardian layer (T159). Sits above the app-root
/// [ZodiacBackdrop] light field (background gradient, glow spots,
/// constellation layer, sign watermark — all untouched) and below the
/// dashboard cards: the guardian figure at 55% opacity behind the left
/// card column, gazing up at the backdrop's constellation chart, plus
/// its name plate at the lower left, above the navigation bar.
class ZodiacGuardianLayer extends StatelessWidget {
  const ZodiacGuardianLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final zodiac = context.zodiac;
    if (zodiac == null) return const SizedBox.expand();
    final guardian = zodiacGuardianForTheme(zodiac.themeId);
    if (guardian == null) return const SizedBox.expand();
    final variant = zodiac.variant;
    final size = MediaQuery.sizeOf(context);
    final l10n = appLocalizations;
    final sign = zodiacGuardianSignName(
      zodiac.themeId,
      Localizations.localeOf(context),
    );
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -2,
            top: size.height * 0.4,
            width: size.width * 0.55,
            child: Opacity(
              opacity: 0.55,
              child: Image.asset(guardian.assetPath, fit: BoxFit.fitWidth),
            ),
          ),
          Positioned(
            left: 15,
            bottom: getFloatingBottomBarReserveHeight(context) + 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    gradient: LinearGradient(
                      colors: [variant.primary, variant.secondary],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  guardian.localizedName(l10n),
                  style: TextStyle(
                    color: variant.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.guardianLine(guardian.latinName, sign),
                  style: TextStyle(
                    color: variant.textSecondary,
                    fontSize: 9.5,
                    letterSpacing: 2.4,
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
