import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// T159: every zodiac theme carries exactly one guardian, the artwork
/// file is really on disk, and the root guardian layers (figure in the
/// background stack, name plate as root overlay) render for the active
/// theme on every page — and render nothing without a zodiac theme.
void main() {
  group('guardian data audit', () {
    test('all twelve themes have a guardian with an existing asset', () {
      expect(zodiacThemes, hasLength(12));
      expect(zodiacGuardians, hasLength(12));
      expect(
        zodiacGuardians.keys.toSet(),
        zodiacThemes.map((theme) => theme.id).toSet(),
      );
      for (final theme in zodiacThemes) {
        final guardian = zodiacGuardianForTheme(theme.id);
        expect(guardian, isNotNull, reason: '${theme.id} needs a guardian');
        expect(
          guardian!.assetPath,
          'assets/images/guardians/${theme.id}.webp',
        );
        expect(
          File(guardian.assetPath).existsSync(),
          isTrue,
          reason: '${guardian.assetPath} must exist on disk',
        );
        expect(guardian.latinName, isNotEmpty);
      }
    });

    test('localized names and sign names resolve per locale', () async {
      // Intl.message resolves through the global default locale at call
      // time, so each locale's assertions run while it is the loaded one.
      final zh = await AppLocalizations.load(
        const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
      );
      expect(zodiacGuardianForTheme('sagittarius')!.localizedName(zh), '宙斯');
      expect(zodiacGuardianForTheme('scorpio')!.localizedName(zh), '哈迪斯');
      expect(zodiacGuardianForTheme('libra')!.localizedName(zh), '忒弥斯');
      expect(zh.guardianLine('Zeus', '射手座'), 'Zeus · 射手座守护神');

      final en = await AppLocalizations.load(const Locale('en'));
      expect(zodiacGuardianForTheme('sagittarius')!.localizedName(en), 'Zeus');
      expect(
        en.guardianLine('Zeus', 'Sagittarius'),
        'Zeus · Guardian of Sagittarius',
      );

      expect(
        zodiacGuardianSignName(
          'sagittarius',
          const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
        ),
        '射手座',
      );
      expect(zodiacGuardianSignName('sagittarius', const Locale('en')), 'Sagittarius');
      expect(zodiacGuardianSignName('cancer', const Locale('ja')), '蟹座');
      expect(zodiacGuardianSignName('scorpio', const Locale('ru')), 'Скорпион');
      expect(zodiacGuardianSignName('libra', const Locale('fa')), 'میزان');
    });
  });

  testWidgets('root guardian layers show figure and name plate', (
    tester,
  ) async {
    await AppLocalizations.load(
      const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    );
    final theme = ThemeData(
      extensions: [ZodiacThemeExtension.of(resolveZodiacTheme('sagittarius'))],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          countryCode: 'CN',
        ),
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        // Mirrors the application.dart root stack: backdrop, figure
        // layer, page content, then the plate as the root overlay.
        home: const Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              ZodiacBackdrop(),
              Positioned.fill(child: ZodiacGuardianFigureLayer()),
              SizedBox.expand(),
              Positioned.fill(child: ZodiacGuardianPlate()),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ZodiacGuardianFigureLayer), findsOneWidget);
    expect(find.byType(ZodiacGuardianPlate), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(IgnorePointer), findsWidgets);
    expect(find.text('宙斯'), findsOneWidget);
    expect(find.text('ZEUS · 射手座守护神'), findsOneWidget);
  });

  testWidgets('guardian layers render nothing without a zodiac theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: ZodiacGuardianFigureLayer()),
              Positioned.fill(child: ZodiacGuardianPlate()),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byType(Text), findsNothing);
  });
}
