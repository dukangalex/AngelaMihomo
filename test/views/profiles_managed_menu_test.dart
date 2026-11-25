import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/controller.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/profiles/profiles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T139: every profile card menu carries a managed-mode toggle right
/// below Override. It writes the one binding the scripts page picker
/// writes ([profileWithScriptChoice] over `Profile.managed`), defaults
/// to off for every profile, and shows its state with the family's
/// selected language (check circle / plain circle).
void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('zh', 'CN'));
  });

  group('profileWithScriptChoice (the shared binding write)', () {
    const base = Profile(id: 'p', autoUpdateDuration: Duration.zero);

    test('a fresh profile defaults to no script and stays off', () {
      expect(base.managed, isFalse);
      expect(base.scriptId, isNull);
      expect(base.runsManagedScript, isFalse);
      final untouched = profileWithScriptChoice(base, null);
      expect(untouched.managed, isFalse);
      expect(untouched.scriptId, isNull);
    });

    test('choosing managed sets the flag and clears any library binding', () {
      final withLibrary = base.copyWith(scriptId: 'user-1');
      final chosen = profileWithScriptChoice(withLibrary, managedScriptId);
      expect(chosen.managed, isTrue);
      expect(chosen.scriptId, isNull);
      expect(chosen.runsManagedScript, isTrue);
    });

    test('choosing a library script clears the managed flag', () {
      final managed = base.copyWith(managed: true);
      final chosen = profileWithScriptChoice(managed, 'user-1');
      expect(chosen.managed, isFalse);
      expect(chosen.scriptId, 'user-1');
      expect(chosen.runsManagedScript, isFalse);
    });

    test('choosing none clears both (the menu toggle off position)', () {
      final managed = base.copyWith(managed: true);
      final chosen = profileWithScriptChoice(managed, null);
      expect(chosen.managed, isFalse);
      expect(chosen.scriptId, isNull);
      expect(chosen.runsManagedScript, isFalse);
    });

    test('bundle profiles never run the managed script', () {
      final bundle = base.copyWith(bundle: const ProfileBundle());
      final chosen = profileWithScriptChoice(bundle, managedScriptId);
      expect(chosen.runsManagedScript, isFalse);
    });
  });

  group('profile card menu toggle', () {
    const profile = Profile(
      id: 'p1',
      label: 'Sub One',
      autoUpdateDuration: Duration(hours: 1),
    );

    late ProviderContainer container;

    Future<void> pumpItem(WidgetTester tester, Profile item) async {
      globalState.appState = AppState(
        brightness: Brightness.light,
        version: 0,
        viewSize: const Size(400, 800),
        requests: FixedList(maxLength),
        logs: FixedList(maxLogLength),
        traffics: FixedList(30),
        totalTraffic: Traffic(),
        systemUiOverlayStyle: const SystemUiOverlayStyle(),
      );
      globalState.config = Config(
        themeProps: defaultThemeProps,
        currentProfileId: 'someone-else',
        profiles: [item],
      );
      container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(profilesProvider, (_, _) {});
      final zodiac = resolveZodiacTheme('sagittarius');
      final variant = zodiac.dark;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh', 'CN'),
            supportedLocales: AppLocalizations.delegate.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            theme: ThemeData(
              colorScheme: variant.toColorScheme(Brightness.dark),
              extensions: [ZodiacThemeExtension.of(zodiac, Brightness.dark)],
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  globalState.appController = AppController(context, ref);
                  // Mirror the real list: the card is fed from the
                  // profiles provider, so binding writes rebuild it.
                  final fresh =
                      ref.watch(profilesProvider).getProfile(item.id) ?? item;
                  return ProfileItem(
                    profile: fresh,
                    groupValue: null,
                    onChanged: (_) {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    Profile stored() => container.read(profilesProvider).getProfile('p1')!;

    testWidgets('item sits below Override, off by default, toggles the '
        'same binding the picker writes', (tester) async {
      await pumpItem(tester, profile);
      await openMenu(tester);

      final overrideY = tester.getCenter(find.text('覆写')).dy;
      final managedFinder = find.text('托管模式');
      expect(managedFinder, findsOneWidget);
      final managedY = tester.getCenter(managedFinder).dy;
      final chainY = tester.getCenter(find.text('链式代理')).dy;
      expect(overrideY < managedY, isTrue, reason: '托管模式 must follow 覆写');
      expect(managedY < chainY, isTrue, reason: '托管模式 must precede 链式代理');
      // Default off, in the family's selected language.
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(stored().managed, isFalse);

      // Toggle on through the menu.
      await tester.tap(managedFinder);
      await tester.pumpAndSettle();
      expect(stored().managed, isTrue);
      expect(stored().scriptId, isNull);
      expect(stored().runsManagedScript, isTrue);

      // The picker path (scripts page) writes the identical result.
      final viaPicker = profileWithScriptChoice(profile, managedScriptId);
      expect(stored().managed, viaPicker.managed);
      expect(stored().scriptId, viaPicker.scriptId);

      // Reopened menu shows the on state; toggling again turns it off.
      // (T152: the card now also carries a managed badge with the same
      // words, so the toggle tap targets the menu row's state icon,
      // which only the menu item has.)
      await openMenu(tester);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
      await tester.tap(find.byIcon(Icons.check_circle_rounded));
      await tester.pumpAndSettle();
      expect(stored().managed, isFalse);
      expect(stored().scriptId, isNull);
      expect(stored().runsManagedScript, isFalse);
    });

    testWidgets('bundle profiles have no managed-mode menu item', (
      tester,
    ) async {
      await pumpItem(
        tester,
        profile.copyWith(id: 'p1', bundle: const ProfileBundle()),
      );
      await openMenu(tester);
      expect(find.text('覆写'), findsOneWidget);
      expect(find.text('托管模式'), findsNothing);
    });
  });
}
