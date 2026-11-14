import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('the family has twelve themes in zodiac order', () {
    expect(zodiacThemes.map((t) => t.id), [
      'aries',
      'taurus',
      'gemini',
      'cancer',
      'leo',
      'virgo',
      'libra',
      'scorpio',
      'sagittarius',
      'capricorn',
      'aquarius',
      'pisces',
    ]);
    for (final theme in zodiacThemes) {
      expect(theme.sign, isNotEmpty);
      expect(theme.nameZh, contains('座'));
      expect(theme.nameEn, isNotEmpty);
    }
  });

  test('every variant carries the full token set with shared delay tiers', () {
    for (final theme in zodiacThemes) {
      for (final variant in [theme.light, theme.dark]) {
        expect(variant.delayGood, variant.success, reason: theme.id);
        expect(variant.delayMid, variant.warning, reason: theme.id);
        expect(variant.delayBad, variant.error, reason: theme.id);
        expect(
          variant.disabled,
          variant.textSecondary.withValues(alpha: 0.45),
          reason: theme.id,
        );
        expect(variant.background.isNone, isFalse, reason: theme.id);
      }
    }
  });

  test('sagittarius tokens match the design table', () {
    final sag = resolveZodiacTheme('sagittarius');
    expect(sag.light.primary, const Color(0xFF5B3DF0));
    expect(sag.light.secondary, const Color(0xFF0CA678));
    expect(sag.light.textPrimary, const Color(0xFF221C4A));
    expect(sag.light.surface, const Color(0xC7FFFFFF));
    expect(sag.light.selected.stops, [
      const Color(0xFF5B3DF0),
      const Color(0xFF0CA678),
    ]);
    expect(sag.dark.primary, const Color(0xFF6C4DF6));
    expect(sag.dark.secondary, const Color(0xFF2DD4BF));
    expect(sag.dark.backgroundBase, const Color(0xFF081A2E));
    expect(sag.dark.glow, const Color(0x802DD4BF));
    expect(sag.dark.glows, hasLength(2));
    expect(sag.dark.navBar, const Color(0x8C08081A));
  });

  test('unknown or missing selections fall back to sagittarius', () {
    expect(resolveZodiacTheme(null).id, 'sagittarius');
    expect(resolveZodiacTheme('').id, 'sagittarius');
    expect(resolveZodiacTheme('not-a-theme').id, 'sagittarius');
    expect(resolveZodiacTheme('leo').id, 'leo');
  });

  test('color schemes come from the tokens', () {
    final sag = resolveZodiacTheme('sagittarius');
    final dark = sag.dark.toColorScheme(Brightness.dark);
    expect(dark.primary, sag.dark.primary);
    expect(dark.secondary, sag.dark.secondary);
    expect(dark.error, sag.dark.error);
    expect(dark.onSurface, sag.dark.textPrimary);
    expect(dark.onSurfaceVariant, sag.dark.textSecondary);
    expect(dark.brightness, Brightness.dark);
    final leo = resolveZodiacTheme('leo');
    final light = leo.light.toColorScheme(Brightness.light);
    expect(light.primary, const Color(0xFFC07F0A));
    expect(light.onPrimary, const Color(0xFFFFFFFF));
  });

  test('theme props default to sagittarius, legacy configs included', () {
    expect(const ThemeProps().zodiacTheme, 'sagittarius');
    expect(ThemeProps.fromJson(const {}).zodiacTheme, 'sagittarius');
    expect(
      ThemeProps.fromJson(const {'zodiacTheme': 'pisces'}).zodiacTheme,
      'pisces',
    );
  });

  test('nav selection color follows the skeleton rule', () {
    final sagDark = ZodiacThemeExtension.of(
      resolveZodiacTheme('sagittarius'),
      Brightness.dark,
    );
    expect(sagDark.navSelected, const Color(0xFF2DD4BF));
    final ariesLight = ZodiacThemeExtension.of(
      resolveZodiacTheme('aries'),
      Brightness.light,
    );
    expect(ariesLight.navSelected, const Color(0xFFE63A17));
  });

  test('delay colors come from the variant tiers', () {
    final variant = resolveZodiacTheme('sagittarius').dark;
    expect(zodiacDelayColor(variant, null), isNull);
    expect(zodiacDelayColor(variant, -1), variant.delayBad);
    expect(zodiacDelayColor(variant, 120), variant.delayGood);
    expect(zodiacDelayColor(variant, 900), variant.delayMid);
    expect(zodiacDelayColor(null, 120), Colors.green);
  });
}
