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
      final variant = theme.variant;
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
  });

  test('sagittarius tokens match the design table', () {
    final sag = resolveZodiacTheme('sagittarius');
    expect(sag.variant.primary, const Color(0xFF6C4DF6));
    expect(sag.variant.secondary, const Color(0xFF2DD4BF));
    expect(sag.variant.backgroundBase, const Color(0xFF081A2E));
    expect(sag.variant.surface, const Color(0x12FFFFFF));
    expect(sag.variant.selected.stops, [
      const Color(0xFF6C4DF6),
      const Color(0xFF2DD4BF),
    ]);
    expect(sag.variant.glow, const Color(0x802DD4BF));
    expect(sag.variant.glows, hasLength(2));
    expect(sag.variant.navBar, const Color(0x8C08081A));
  });

  test('unknown or missing selections fall back to sagittarius', () {
    expect(resolveZodiacTheme(null).id, 'sagittarius');
    expect(resolveZodiacTheme('').id, 'sagittarius');
    expect(resolveZodiacTheme('not-a-theme').id, 'sagittarius');
    expect(resolveZodiacTheme('leo').id, 'leo');
  });

  test('color schemes come from the tokens', () {
    final sag = resolveZodiacTheme('sagittarius');
    final scheme = sag.variant.toColorScheme();
    expect(scheme.primary, sag.variant.primary);
    expect(scheme.secondary, sag.variant.secondary);
    expect(scheme.error, sag.variant.error);
    expect(scheme.onSurface, sag.variant.textPrimary);
    expect(scheme.onSurfaceVariant, sag.variant.textSecondary);
    // Single-set family: the scheme is always composed at dark
    // brightness (DESIGN doc section 1 rule 9).
    expect(scheme.brightness, Brightness.dark);
    final leo = resolveZodiacTheme('leo');
    final leoScheme = leo.variant.toColorScheme();
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
    final sag = ZodiacThemeExtension.of(resolveZodiacTheme('sagittarius'));
    expect(sag.navSelected, const Color(0xFF2DD4BF));
    final aries = ZodiacThemeExtension.of(resolveZodiacTheme('aries'));
    expect(aries.navSelected, const Color(0xFFFF5A2A));
  });

  test('delay colors come from the variant tiers', () {
    final variant = resolveZodiacTheme('sagittarius').variant;
    expect(zodiacDelayColor(variant, null), isNull);
    expect(zodiacDelayColor(variant, -1), variant.delayBad);
    expect(zodiacDelayColor(variant, 120), variant.delayGood);
    expect(zodiacDelayColor(variant, 900), variant.delayMid);
    expect(zodiacDelayColor(null, 120), Colors.green);
  });
}
