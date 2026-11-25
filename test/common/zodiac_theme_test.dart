import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/models/models.dart';
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
    expect(sag.dark.primary, const Color(0xFF6C4DF6));
    expect(sag.dark.secondary, const Color(0xFF2DD4BF));
    expect(sag.dark.backgroundBase, const Color(0xFF081A2E));
    expect(sag.dark.surface, const Color(0x12FFFFFF));
    expect(sag.dark.selected.stops, [
      const Color(0xFF6C4DF6),
      const Color(0xFF2DD4BF),
    ]);
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
    final scheme = sag.dark.toColorScheme(Brightness.dark);
    expect(scheme.primary, sag.dark.primary);
    expect(scheme.secondary, sag.dark.secondary);
    expect(scheme.error, sag.dark.error);
    expect(scheme.onSurface, sag.dark.textPrimary);
    expect(scheme.onSurfaceVariant, sag.dark.textSecondary);
    // Dual-set family (T298): each variant composes at its own
    // brightness — the dark variant in the dark slot, the light
    // variant in the light slot.
    expect(scheme.brightness, Brightness.dark);
    final lightScheme = sag.light.toColorScheme(Brightness.light);
    expect(lightScheme.brightness, Brightness.light);
    expect(lightScheme.primary, sag.light.primary);
    expect(lightScheme.onSurface, sag.light.textPrimary);
    final leo = resolveZodiacTheme('leo');
    final leoScheme = leo.dark.toColorScheme(Brightness.dark);
    expect(leoScheme.primary, const Color(0xFFE8A812));
    expect(leoScheme.onPrimary, const Color(0xFF2A1A05));
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
    final sag = ZodiacThemeExtension.of(
      resolveZodiacTheme('sagittarius'),
      Brightness.dark,
    );
    expect(sag.navSelected, const Color(0xFF2DD4BF));
    final aries = ZodiacThemeExtension.of(
      resolveZodiacTheme('aries'),
      Brightness.dark,
    );
    expect(aries.navSelected, const Color(0xFFFF5A2A));
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
