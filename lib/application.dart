import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/external_control.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/manager/hotkey_manager.dart';
import 'package:bett_box/manager/manager.dart';
import 'package:bett_box/plugins/app.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controller.dart';
import 'pages/pages.dart';

class Application extends ConsumerStatefulWidget {
  const Application({super.key});

  @override
  ConsumerState<Application> createState() => ApplicationState();
}

class ApplicationState extends ConsumerState<Application>
    with WidgetsBindingObserver {
  Timer? _autoUpdateGroupTaskTimer;
  Timer? _autoUpdateProfilesTaskTimer;
  Timer? _autoSyncGeoTaskTimer;

  final _pageTransitionsTheme = const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static const _lightAppBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
    ),
  );

  static const _darkAppBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
    ),
  );

  final Map<Brightness, ((ColorScheme, String?, String), ThemeData)>
  _themeCache = {};

  ThemeData _themeOf(
    ColorScheme colorScheme,
    String? fontFamily,
    ZodiacThemeDef zodiacDef,
  ) {
    final key = (colorScheme, fontFamily, zodiacDef.id);
    final cached = _themeCache[colorScheme.brightness];
    if (cached != null && cached.$1 == key) {
      return cached.$2;
    }
    final theme = _buildTheme(colorScheme, fontFamily, zodiacDef);
    _themeCache[colorScheme.brightness] = (key, theme);
    return theme;
  }

  ThemeData _buildTheme(
    ColorScheme colorScheme,
    String? fontFamily,
    ZodiacThemeDef zodiacDef,
  ) {
    final isLight = colorScheme.brightness == Brightness.light;
    final palette = zodiacDef.paletteFor(colorScheme.brightness);
    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _pageTransitionsTheme,
      scaffoldBackgroundColor: palette.bgStops.first,
      appBarTheme: isLight ? _lightAppBarTheme : _darkAppBarTheme,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      extensions: [ZodiacThemeExtension.of(zodiacDef, colorScheme.brightness)],
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        elevation: 3,
        hoverElevation: 5,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.dialogSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.3 : 0.6),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isLight ? 0.6 : 0.5,
            ),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(
          alpha: isLight ? 0.45 : 0.25,
        ),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      switchTheme: _switchTheme(colorScheme, palette),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: isLight ? 0.6 : 0.5,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        textStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 13),
      ),
    );
  }

  SwitchThemeData _switchTheme(
    ColorScheme colorScheme,
    ZodiacPalette palette,
  ) {
    final isLight = colorScheme.brightness == Brightness.light;
    return SwitchThemeData(
      thumbIcon: const WidgetStatePropertyAll(Icon(null)),
      // T115 spec 3.5.8: on = selected color, off = surfaceVariant
      // fill with an outline-colored track border.
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return palette.outline;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
        return isLight ? Colors.white : colorScheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        if (states.contains(WidgetState.selected)) return palette.primary;
        return palette.surfaceVariant;
      }),
    );
  }

  InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    final isLight = colorScheme.brightness == Brightness.light;
    final border = _FieldInputBorder(
      borderSide: BorderSide(
        color: isLight
            ? colorScheme.outlineVariant
            : colorScheme.outline.withValues(alpha: 0.45),
      ),
    );
    final focusedBorder = _FieldInputBorder(
      borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
    );
    final errorBorder = _FieldInputBorder(
      borderSide: BorderSide(color: colorScheme.error),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.brightness == Brightness.light
          ? Color.lerp(
              colorScheme.surface,
              colorScheme.surfaceContainerLowest,
              0.5,
            )
          : colorScheme.surfaceContainerHighest,
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      disabledBorder: _FieldInputBorder(
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 1.6),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (system.isAndroid) {
      unawaited(SystemNavigator.setFrameworkHandlesBack(true));
    }
    globalState.backgroundMode.addListener(_syncAutoUpdateTasks);
    _syncAutoUpdateTasks();
    globalState.appController = AppController(context, ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initApp());
    });
  }

  bool get _isForeground {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
  }

  Future<void> _initApp() async {
    final currentContext = globalState.navigatorKey.currentContext;
    if (currentContext != null && currentContext != context) {
      globalState.appController = AppController(currentContext, ref);
    }
    await globalState.appController.init();
    if (!appPath.isPortable) {
      try {
        await ExternalControl.start();
      } catch (e) {
        commonPrint.warn('ExternalControl start failed: $e');
      }
    }
    globalState.appController.initLink();
    if (system.isAndroid) {
      app.initShortcuts();
    }
    Future.delayed(const Duration(seconds: 3), () {
      globalState.warmupCommonDialog();
    });
  }

  @override
  Future<bool> didPopRoute() async {
    if (!system.isAndroid) return false;
    final navigator = globalState.navigatorKey.currentState;
    if (navigator == null) return false;
    try {
      if (!await navigator.maybePop()) {
        await globalState.appController.handleBackOrExit();
      }
    } catch (e) {
      commonPrint.warn('Back dispatch failed: $e');
    }
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncAutoUpdateTasks();
  }

  void _syncAutoUpdateTasks() {
    final shouldRun = _isForeground && !globalState.backgroundMode.value;
    if (!shouldRun) {
      _autoUpdateGroupTaskTimer?.cancel();
      _autoUpdateGroupTaskTimer = null;
      if (!system.isDesktop) {
        _autoUpdateProfilesTaskTimer?.cancel();
        _autoUpdateProfilesTaskTimer = null;
        _autoSyncGeoTaskTimer?.cancel();
        _autoSyncGeoTaskTimer = null;
      }
      return;
    }
    if (_autoUpdateGroupTaskTimer == null) {
      _autoUpdateGroupTask();
    }
    if (_autoUpdateProfilesTaskTimer == null) {
      _autoUpdateProfilesTask();
    }
    if (_autoSyncGeoTaskTimer == null) {
      _autoSyncGeoTask();
    }
  }

  void _autoUpdateGroupTask() {
    _autoUpdateGroupTaskTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => globalState.appController.updateGroupsDebounce(),
    );
  }

  void _autoUpdateProfilesTask() {
    _autoUpdateProfilesTaskTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => unawaited(globalState.appController.autoUpdateProfiles()),
    );
  }

  // T107: hourly tick for the GEO auto sync. The controller's
  // due-check (settings + elapsed period) decides whether a run
  // actually happens, so the tick itself is cheap; a first check
  // on (re)start covers a period that elapsed while the app was
  // closed. The first check is deferred to the next frame:
  // _syncAutoUpdateTasks also runs from initState, before
  // globalState.appController is assigned.
  void _autoSyncGeoTask() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(globalState.appController.autoSyncGeoResources());
    });
    _autoSyncGeoTaskTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => unawaited(globalState.appController.autoSyncGeoResources()),
    );
  }

  Widget _buildPlatformState(Widget child) {
    if (system.isDesktop) {
      return WindowManager(
        child: TrayManager(
          child: HotKeyManager(
            child: ProxyManager(child: SmartAutoStopManager(child: child)),
          ),
        ),
      );
    }
    return AndroidManager(
      child: TileManager(child: SmartAutoStopManager(child: child)),
    );
  }

  Widget _buildState(Widget child) {
    return AppStateManager(
      child: ClashManager(
        child: ConnectivityManager(
          onConnectivityChanged: (results) async {
            if (!results.contains(ConnectivityResult.vpn)) {
              unawaited(
                clashCore.closeConnections().then<void>(
                  (_) {},
                  onError: (Object e) =>
                      commonPrint.debug('closeConnections ignored: $e'),
                ),
              );
            }
            if (system.isLinux) {
              // Wait for DHCP and the default route to settle before moving the
              // managed DNS from the previous network to the new one.
              await Future.delayed(const Duration(seconds: 1));
              if (!mounted) return;
              await system.updateDns(!ref.read(systemDnsTakeoverProvider));
            }
            globalState.appController.updateLocalNetwork();
            globalState.appController.addCheckIpNumDebounce();
          },
          child: child,
        ),
      ),
    );
  }

  Widget _buildPlatformApp(Widget child) {
    if (system.isDesktop) {
      return WindowHeaderContainer(child: child);
    }
    return VpnManager(child: child);
  }

  Widget _buildApp(Widget child) {
    return MessageManager(child: ThemeManager(child: child));
  }

  @override
  Widget build(context) {
    return _buildPlatformState(
      _buildState(
        Consumer(
          builder: (_, ref, child) {
            final locale = ref.watch(
              appSettingProvider.select((state) => state.locale),
            );
            final zodiacDef = ref.watch(currentZodiacThemeProvider);
            final lightColorScheme = ref.watch(
              genColorSchemeProvider(Brightness.light),
            );
            final darkColorScheme = ref.watch(
              genColorSchemeProvider(Brightness.dark),
            );
            const String? fontFamily = null;

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: globalState.navigatorKey,
              navigatorObservers: [routeIdleObserver],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              builder: (_, child) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: globalState.animationEnabled,
                    builder: (_, enabled, _) {
                      return TickerMode(
                        enabled: enabled,
                        child: _buildApp(
                          AppSidebarContainer(child: _buildPlatformApp(child!)),
                        ),
                      );
                    },
                  ),
                );
              },
              scrollBehavior: BaseScrollBehavior(),
              title: appName,
              locale:
                  utils.getLocaleForString(locale) ?? utils.getSystemLocale(),
              supportedLocales: AppLocalizations.delegate.supportedLocales,
              // T115 spec: brightness follows the system only.
              themeMode: ThemeMode.system,
              theme: _themeOf(lightColorScheme, fontFamily, zodiacDef),
              darkTheme: _themeOf(darkColorScheme, fontFamily, zodiacDef),
              home: child!,
            );
          },
          child: const HomePage(),
        ),
      ),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _themeCache.clear();
  }

  @override
  void dispose() {
    globalState.backgroundMode.removeListener(_syncAutoUpdateTasks);
    WidgetsBinding.instance.removeObserver(this);
    linkManager.destroy();
    _autoUpdateGroupTaskTimer?.cancel();
    _autoUpdateProfilesTaskTimer?.cancel();
    _autoSyncGeoTaskTimer?.cancel();
    ExternalControl.stop();
    if (!system.isAndroid && !globalState.isExiting) {
      unawaited(globalState.appController.handleExit());
    }
    super.dispose();
  }
}

class _FieldInputBorder extends InputBorder {
  const _FieldInputBorder({super.borderSide = BorderSide.none});

  static const _borderRadius = BorderRadius.all(Radius.circular(16));

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  _FieldInputBorder copyWith({BorderSide? borderSide}) {
    return _FieldInputBorder(borderSide: borderSide ?? this.borderSide);
  }

  @override
  ShapeBorder scale(double t) {
    return _FieldInputBorder(borderSide: borderSide.scale(t));
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is _FieldInputBorder) {
      return _FieldInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is _FieldInputBorder) {
      return _FieldInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(_borderRadius.toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(_borderRadius.toRRect(rect));
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) {
      return;
    }
    canvas.drawRRect(
      _borderRadius.toRRect(rect).deflate(borderSide.width / 2),
      borderSide.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _FieldInputBorder && other.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}
