import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T159: every zodiac theme carries exactly one guardian, the artwork
/// file is really on disk, and the guardian figure + name plate are
/// composed inside [ZodiacBackdrop] itself — so every surface that
/// paints the backdrop (root, pushed pages, desktop routes) carries
/// them as background, below page content — and surfaces without a
/// zodiac theme, or with the guardian switched off, render neither.
class _FixedPageLabel extends CurrentPageLabel {
  _FixedPageLabel(this.label);

  final PageLabel label;

  @override
  PageLabel build() => label;
}

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
        expect(guardian!.assetPath, 'assets/images/guardians/${theme.id}.webp');
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
      expect(
        zodiacGuardianSignName('sagittarius', const Locale('en')),
        'Sagittarius',
      );
      expect(zodiacGuardianSignName('cancer', const Locale('ja')), '蟹座');
      expect(zodiacGuardianSignName('scorpio', const Locale('ru')), 'Скорпион');
      expect(zodiacGuardianSignName('libra', const Locale('fa')), 'میزان');
    });
  });

  /// Pumps a lone [ZodiacBackdrop] for the Sagittarius theme with the
  /// current page label pinned to [label] — the same composition the
  /// root stack and every page-carried backdrop use in the app.
  Future<void> pumpBackdrop(
    WidgetTester tester, {
    PageLabel label = PageLabel.dashboard,
    bool showGuardian = true,
  }) async {
    await AppLocalizations.load(
      const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    );
    final theme = ThemeData(
      extensions: [ZodiacThemeExtension.of(resolveZodiacTheme('sagittarius'))],
    );
    await tester.pumpWidget(
      ProviderScope(
        // A fresh scope per pump: an existing scope keeps its first
        // overrides, so re-pumping with another label needs a new key.
        key: ValueKey((label, showGuardian)),
        overrides: [
          currentPageLabelProvider.overrideWith(() => _FixedPageLabel(label)),
        ],
        child: MaterialApp(
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
          home: Scaffold(body: ZodiacBackdrop(showGuardian: showGuardian)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('backdrop composes figure and name plate as background', (
    tester,
  ) async {
    await pumpBackdrop(tester);
    expect(find.byType(ZodiacGuardianFigureLayer), findsOneWidget);
    expect(find.byType(ZodiacGuardianPlate), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('宙斯'), findsOneWidget);
    expect(find.text('ZEUS · 射手座守护神'), findsOneWidget);
    // The plate is part of the backdrop, not a fixed overlay above
    // page content: it lives inside ZodiacBackdrop's own stack, so
    // sheets, dialogs and cards stacked over the backdrop cover it.
    expect(
      find.ancestor(
        of: find.byType(ZodiacGuardianPlate),
        matching: find.byType(ZodiacBackdrop),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byType(ZodiacGuardianFigureLayer),
        matching: find.byType(ZodiacBackdrop),
      ),
      findsOneWidget,
    );
  });

  testWidgets('backdrop poses the figure per page label', (tester) async {
    // The x-scale baked into the Transforms wrapping the figure
    // image: the proxies variant mirrors the artwork (a -1 entry),
    // the dashboard variant never does — same guardian, different
    // pose per page.
    List<double> xScales() => tester
        .widgetList<Transform>(
          find.ancestor(
            of: find.byType(Image),
            matching: find.byType(Transform),
          ),
        )
        .map((transform) => transform.transform.storage[0])
        .toList();

    await pumpBackdrop(tester, label: PageLabel.dashboard);
    expect(find.byType(Image), findsOneWidget);
    expect(xScales(), isNotEmpty);
    expect(xScales().every((scale) => scale > 0), isTrue);

    await pumpBackdrop(tester, label: PageLabel.proxies);
    expect(find.byType(Image), findsOneWidget);
    expect(xScales(), contains(-1.0));
  });

  testWidgets('backdrop renders no guardian when switched off', (tester) async {
    await pumpBackdrop(tester, showGuardian: false);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(Image), findsNothing);
    expect(find.text('宙斯'), findsNothing);
  });

  test('page variants pose the same guardian differently per page', () {
    // Every main page resolves a variant, and the acceptance pages do
    // not all share one transform signature — same artwork, different
    // presentation (the character itself never changes).
    for (final label in PageLabel.values) {
      expect(zodiacGuardianVariantFor(label), isNotNull, reason: '$label');
    }
    final signatures = {
      for (final label in [
        PageLabel.dashboard,
        PageLabel.proxies,
        PageLabel.profiles,
        PageLabel.tools,
      ])
        label: zodiacGuardianVariantFor(label).signature,
    };
    expect(signatures.values.toSet(), hasLength(signatures.length));
    expect(zodiacGuardianVariantFor(PageLabel.proxies).flipX, isTrue);
    expect(
      zodiacGuardianVariantFor(PageLabel.profiles).zoom,
      greaterThan(1),
      reason: 'profiles poses an upper-body close-up',
    );
  });

  testWidgets('backdrop renders nothing without a zodiac theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPageLabelProvider.overrideWith(
            () => _FixedPageLabel(PageLabel.dashboard),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ZodiacBackdrop())),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byType(ZodiacGuardianPlate), findsNothing);
    expect(find.text('宙斯'), findsNothing);
  });
}
