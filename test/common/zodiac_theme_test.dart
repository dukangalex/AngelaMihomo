import 'package:bett_box/common/zodiac_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('十二星座主题家族（T115）', () {
    test('十二套齐全，黄道顺序，id 唯一且与枚举名一致', () {
      expect(zodiacThemes, hasLength(12));
      expect(
        zodiacThemes.map((d) => d.sign),
        ZodiacSign.values,
      );
      expect(zodiacThemes.map((d) => d.id).toSet(), hasLength(12));
      for (final def in zodiacThemes) {
        expect(def.id, def.sign.name);
        expect(def.symbol, isNotEmpty);
        expect(def.nameZh, isNotEmpty);
        expect(def.nameEn, isNotEmpty);
      }
    });

    test('默认射手，未知与空值一律回落射手（存量旧选择不迁移）', () {
      expect(defaultZodiacTheme.sign, ZodiacSign.sagittarius);
      expect(zodiacById('sagittarius').sign, ZodiacSign.sagittarius);
      expect(zodiacById('not-a-theme').sign, ZodiacSign.sagittarius);
      expect(zodiacById(null).sign, ZodiacSign.sagittarius);
      expect(zodiacById('').sign, ZodiacSign.sagittarius);
      for (final def in zodiacThemes) {
        expect(zodiacById(def.id).sign, def.sign);
      }
    });

    test('家族通则：延迟三档与状态三色同源，禁用态为次级文字 45%', () {
      for (final def in zodiacThemes) {
        for (final palette in [def.light, def.dark]) {
          expect(palette.delayGood, palette.success);
          expect(palette.delayMid, palette.warning);
          expect(palette.delayBad, palette.error);
          expect(
            palette.disabled,
            palette.textSecondary.withValues(alpha: 0.45),
          );
          expect(palette.bgStops, isNotEmpty);
          expect(palette.selectedStops, isNotEmpty);
        }
      }
    });

    test('射手深色令牌锚点与设计稿一致', () {
      final dark = defaultZodiacTheme.dark;
      expect(dark.primary, const Color(0xFF6C4DF6));
      expect(dark.secondary, const Color(0xFF2DD4BF));
      expect(dark.textPrimary, const Color(0xFFE9EBFF));
      expect(dark.selectedStops, [
        const Color(0xFF6C4DF6),
        const Color(0xFF2DD4BF),
      ]);
      expect(dark.bgStops, hasLength(3));
      final light = defaultZodiacTheme.light;
      expect(light.primary, const Color(0xFF5B3DF0));
      expect(light.secondary, const Color(0xFF0CA678));
    });

    test('骨架差分：双子硬阴影 2.5px 描边、水瓶霓虹控制台、留白与素纸无框', () {
      final gemini = zodiacById('gemini');
      expect(gemini.spec.borderWidth, 2.5);
      expect(gemini.spec.hardShadow, isTrue);
      expect(gemini.spec.softShadow, isFalse);

      final aquarius = zodiacById('aquarius');
      expect(aquarius.skeleton, ZodiacSkeleton.consolePanel);
      expect(aquarius.neon, isTrue);
      expect(zodiacById('capricorn').neon, isFalse);

      for (final id in ['taurus', 'libra']) {
        expect(zodiacById(id).spec.frameless, isTrue, reason: id);
        expect(
          zodiacById(id).spec.selectedStyle,
          ZodiacSelectedStyle.underline,
          reason: id,
        );
      }
      for (final id in ['cancer', 'virgo']) {
        expect(zodiacById(id).spec.frameless, isTrue, reason: id);
        expect(
          zodiacById(id).spec.selectedStyle,
          ZodiacSelectedStyle.invertBlock,
          reason: id,
        );
      }
      for (final id in ['sagittarius', 'scorpio', 'pisces']) {
        expect(zodiacById(id).spec.translucent, isTrue, reason: id);
        expect(
          zodiacById(id).spec.selectedStyle,
          ZodiacSelectedStyle.gradient,
          reason: id,
        );
      }
    });

    test('配色方案逐令牌直出，无种子生成改色', () {
      for (final def in zodiacThemes) {
        for (final brightness in Brightness.values) {
          final palette = def.paletteFor(brightness);
          final scheme = zodiacColorScheme(palette, brightness);
          expect(scheme.primary, palette.primary);
          expect(scheme.secondary, palette.secondary);
          expect(scheme.tertiary, palette.accent);
          expect(scheme.error, palette.error);
          expect(scheme.surface, palette.surface);
          expect(scheme.onSurface, palette.textPrimary);
          expect(scheme.onSurfaceVariant, palette.textSecondary);
          expect(scheme.outline, palette.outline);
          expect(scheme.brightness, brightness);
        }
      }
    });

    test('半透表面合成的对话框表面不透明', () {
      for (final def in zodiacThemes) {
        for (final palette in [def.light, def.dark]) {
          expect(palette.dialogSurface.a, 1.0);
        }
      }
    });
  });
}
