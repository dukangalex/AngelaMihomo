import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/design_tokens.dart';
import 'package:angelamihomo/widgets/card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// T334 batch 1: the star-rail design tokens land in the theme layer.
// The values below are the frozen design table (DESIGN-LANGUAGE.md
// in the goal workspace); pinning them here keeps code and design
// doc from drifting apart silently.
void main() {
  test('dark skeleton palette matches the design table', () {
    expect(StarRailColors.deepVoid, const Color(0xFF171130));
    expect(StarRailColors.surfacePurple, const Color(0xFF221A45));
    expect(StarRailColors.surfaceContainer, const Color(0xFF211B3A));
    expect(StarRailColors.starlightWhite, const Color(0xFFFFFFFF));
    expect(StarRailColors.primary, const Color(0xFF8B7CFF));
    expect(StarRailColors.secondary, const Color(0xFF5EEAD4));
    expect(StarRailColors.textPrimary, const Color(0xFFF4F2FF));
    expect(StarRailColors.textSecondary, const Color(0xFFA79FD1));
    expect(StarRailColors.warning, const Color(0xFFFFB03A));
    expect(StarRailColors.error, const Color(0xFFFF8A70));
    expect(StarRailColors.success, const Color(0xFF4ADE80));
  });

  test('light skeleton palette matches the design table', () {
    expect(StarRailColors.lightPrimaryBase, const Color(0xFF96C3F5));
    expect(StarRailColors.lightBackground, const Color(0xFFEAF3FE));
    expect(StarRailColors.lightSurface, const Color(0xFFFFFFFF));
    expect(StarRailColors.lightLine, const Color(0xFF3B2E7A));
    expect(StarRailColors.lightTextPrimary, const Color(0xFF221C4A));
    expect(StarRailColors.lightTextSecondary, const Color(0xFF6B639F));
  });

  test('card radius token stays aligned with commonCardRadius', () {
    expect(StarRailRadius.card, commonCardRadius);
    expect(StarRailRadius.button, 24);
    expect(StarRailRadius.sheetRow, 24);
  });

  test('type scale carries the design table sizes and weights', () {
    expect(StarRailType.headlineXl.fontSize, 32);
    expect(StarRailType.headlineXl.fontWeight, FontWeight.w700);
    expect(StarRailType.headlineLg.fontSize, 24);
    expect(StarRailType.headlineLg.fontWeight, FontWeight.w700);
    expect(StarRailType.headlineMd.fontSize, 20);
    expect(StarRailType.headlineMd.fontWeight, FontWeight.w600);
    expect(StarRailType.bodyLg.fontSize, 16);
    expect(StarRailType.bodyMd.fontSize, 14);
    expect(StarRailType.labelSm.fontSize, 12);
    expect(StarRailType.labelSm.fontWeight, FontWeight.w700);
    expect(StarRailType.labelSm.letterSpacing, 0.6);
    expect(
      StarRailType.readout.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('applyStarRailTypeScale touches only the six table slots', () {
    final base = ThemeData(brightness: Brightness.dark).textTheme;
    final scaled = applyStarRailTypeScale(base);
    expect(scaled.headlineLarge?.fontSize, 32);
    expect(scaled.headlineSmall?.fontSize, 24);
    expect(scaled.titleLarge?.fontSize, 20);
    expect(scaled.bodyLarge?.fontSize, 16);
    expect(scaled.bodyMedium?.fontSize, 14);
    expect(scaled.labelSmall?.fontSize, 12);
    // Slots the table does not define keep the base values.
    expect(scaled.displayLarge, base.displayLarge);
    expect(scaled.titleMedium, base.titleMedium);
    expect(scaled.bodySmall, base.bodySmall);
  });

  test('token extension resolves per brightness and lerps by step', () {
    expect(StarRailTokens.forBrightness(Brightness.dark), StarRailTokens.dark);
    expect(
      StarRailTokens.forBrightness(Brightness.light),
      StarRailTokens.light,
    );
    expect(StarRailTokens.dark.background, StarRailColors.deepVoid);
    expect(StarRailTokens.dark.glowLine, StarRailColors.starlightWhite);
    expect(StarRailTokens.light.background, StarRailColors.lightBackground);
    expect(StarRailTokens.light.glowLine, StarRailColors.lightLine);
    expect(StarRailTokens.dark.lerp(StarRailTokens.light, 0.4),
        StarRailTokens.dark);
    expect(StarRailTokens.dark.lerp(StarRailTokens.light, 0.6),
        StarRailTokens.light);
    final copy = StarRailTokens.dark.copyWith(primary: const Color(0xFF000000));
    expect(copy.primary, const Color(0xFF000000));
    expect(copy.background, StarRailTokens.dark.background);
  });

  test('nav labels: chinese locales take the star-rail names, '
      'other locales keep their words', () {
    Map<String, dynamic> arb(String lang) =>
        jsonDecode(File('arb/intl_$lang.arb').readAsStringSync())
            as Map<String, dynamic>;

    final zhCn = arb('zh_CN');
    expect(zhCn['dashboard'], '星轨');
    expect(zhCn['proxies'], '星群');
    expect(zhCn['profiles'], '星图');
    expect(zhCn['navConnections'], '轨迹');
    expect(zhCn['navTools'], '天枢');

    final zhTc = arb('zh_TC');
    expect(zhTc['dashboard'], '星軌');
    expect(zhTc['proxies'], '星群');
    expect(zhTc['profiles'], '星圖');
    expect(zhTc['navConnections'], '軌跡');
    expect(zhTc['navTools'], '天樞');

    final en = arb('en');
    expect(en['dashboard'], 'Home');
    expect(en['proxies'], 'Proxies');
    expect(en['profiles'], 'Profiles');
    expect(en['navConnections'], 'Connections');
    expect(en['navTools'], 'More');

    // The traffic-stats legend keeps its plain fact word in every
    // locale through its own key, so the rename cannot leak the
    // page name into a data label.
    for (final lang in ['en', 'fa', 'ja', 'ko', 'ru', 'zh_CN', 'zh_TC']) {
      expect(arb(lang)['proxyTraffic'], isNotNull, reason: lang);
    }
    expect(zhCn['proxyTraffic'], '代理流量');
    expect(en['proxyTraffic'], 'Proxy traffic');
  });
}
