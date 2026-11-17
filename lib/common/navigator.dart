import 'package:angelamihomo/common/zodiac_themes.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/app.dart';
import 'package:angelamihomo/state.dart';
import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialPageRoute;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class BaseNavigator {
  static const _keyboardTimeout = Duration(milliseconds: 350);

  static Future<void> _dismissKeyboard(BuildContext context) async {
    final view = View.maybeOf(context);
    if (view == null || view.viewInsets.bottom <= 0) return;
    final observer = _KeyboardObserver(view);
    WidgetsBinding.instance.addObserver(observer);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await observer.closed.timeout(_keyboardTimeout, onTimeout: () {});
    } finally {
      WidgetsBinding.instance.removeObserver(observer);
    }
  }

  static Future<T?> push<T>(
    BuildContext context,
    Widget child, {
    bool maintainState = true,
  }) async {
    final navigator = Navigator.of(context);
    if (globalState.appState.viewMode != ViewMode.mobile) {
      return await navigator.push<T>(
        CommonDesktopRoute(
          builder: (context) => child,
          maintainState: maintainState,
        ),
      );
    }
    await _dismissKeyboard(context);
    if (!navigator.mounted) return null;
    return await navigator.push<T>(
      _CleanCupertinoPageRoute(
        builder: (context) => child,
        maintainState: maintainState,
      ),
    );
  }
}

class _KeyboardObserver with WidgetsBindingObserver {
  final FlutterView view;
  final _closed = Completer<void>();

  _KeyboardObserver(this.view);

  Future<void> get closed => _closed.future;

  @override
  void didChangeMetrics() {
    if (_closed.isCompleted || view.viewInsets.bottom > 0) return;
    _closed.complete();
  }
}

/// Carries the app-wide zodiac backdrop inside a pushed page, so the
/// page owns an opaque bottom painted from the same light field as the
/// root backdrop (T125). Page surfaces are translucent by design; while
/// two pages overlap during a transition, a page without its own bottom
/// lets the page beneath show through its cards (ghosting). With the
/// backdrop inside the page, the incoming page occludes the outgoing
/// one pixel-for-pixel with the settled look, because both backdrops
/// are the same screen-fixed light field.
class _PageWithBackdrop extends StatelessWidget {
  const _PageWithBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [const ZodiacBackdrop(), child],
    );
  }
}

class _CleanCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  _CleanCupertinoPageRoute({
    required super.builder,
    super.title,
    super.settings,
    super.fullscreenDialog,
    super.maintainState,
  });

  @override
  Color? get barrierColor => null;

  static final DelegatedTransitionBuilder? _hostDelegatedTransition = () {
    final route = MaterialPageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );
    final transition = route.delegatedTransition;
    route.dispose();
    return transition;
  }();

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _hostDelegatedTransition;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final page = _PageWithBackdrop(child: child);
    if (defaultTargetPlatform != TargetPlatform.android) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        page,
      );
    }
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: page,
    );
  }
}

class CommonDesktopRoute<T> extends PageRoute<T> {
  final Widget Function(BuildContext context) builder;

  CommonDesktopRoute({required this.builder, this.maintainState = true});

  @override
  final bool maintainState;

  // Content fades are phased so the two pages' contents never overlap
  // mid-transition (T125): the covered page's content leaves over the
  // first 30% while the entering page's content arrives over the last
  // 65%. The page backdrop itself never fades — it is identical on both
  // pages, so swapping it is invisible and the top page stays opaque.
  static final _enterTween = CurveTween(curve: const Interval(0.35, 1));
  static final _exitTween = Tween<double>(
    begin: 1,
    end: 0,
  ).chain(CurveTween(curve: const Interval(0, 0.3)));

  static Widget? _buildExitTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return FadeTransition(
      opacity: _exitTween.animate(secondaryAnimation),
      child: child,
    );
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _buildExitTransition;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = builder(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ZodiacBackdrop(),
          FadeTransition(
            opacity: _exitTween.animate(secondaryAnimation),
            child: FadeTransition(
              opacity: _enterTween.animate(animation),
              child: result,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Both fades live in buildPage, outside/inside the page's own
    // backdrop; nothing to add at the route level.
    return child;
  }

  @override
  Duration get transitionDuration => Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => Duration(milliseconds: 260);
}

class RouteIdleObserver extends NavigatorObserver {
  static const _settleDuration = Duration(milliseconds: 250);
  static const _busyTimeout = Duration(seconds: 3);

  final busy = ValueNotifier<bool>(false);
  final _clock = Stopwatch()..start();
  Duration _changedAt = Duration.zero;
  int _activeTransitions = 0;
  bool _gestureActive = false;

  bool get isSettled {
    final elapsed = _clock.elapsed - _changedAt;
    return elapsed >= (busy.value ? _busyTimeout : _settleDuration);
  }

  void _update() {
    _changedAt = _clock.elapsed;
    busy.value = _gestureActive || _activeTransitions > 0;
  }

  void _track(Route<dynamic>? route) {
    final animation = route is ModalRoute ? route.animation : null;
    if (animation == null ||
        animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed) {
      _update();
      return;
    }
    _activeTransitions++;
    _update();
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      if (route is ModalRoute && route.offstage) return;
      animation.removeStatusListener(listener);
      _activeTransitions--;
      _update();
    }

    animation.addStatusListener(listener);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _gestureActive = true;
    _update();
  }

  @override
  void didStopUserGesture() {
    _gestureActive = false;
    _update();
  }

  Future<void> whenIdle({Duration timeout = const Duration(seconds: 3)}) async {
    if (!busy.value) return;
    final completer = Completer<void>();
    void listener() {
      if (!busy.value && !completer.isCompleted) completer.complete();
    }

    busy.addListener(listener);
    await completer.future.timeout(timeout, onTimeout: () {});
    busy.removeListener(listener);
  }
}

final routeIdleObserver = RouteIdleObserver();

mixin IdleAutofocusMixin<T extends StatefulWidget> on State<T> {
  FocusNode? _autofocusNode;

  bool get autofocusWhenIdle => true;

  FocusNode? get autofocusNode => _autofocusNode;

  @override
  void initState() {
    super.initState();
    if (!autofocusWhenIdle) return;
    final node = _autofocusNode = FocusNode();
    unawaited(node.requestFocusWhenIdle());
  }

  @override
  void dispose() {
    _autofocusNode?.dispose();
    super.dispose();
  }
}

extension FocusNodeIdleExt on FocusNode {
  Future<void> requestFocusWhenIdle() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    await routeIdleObserver.whenIdle();
    await binding.endOfFrame;
    if (context == null || !canRequestFocus) return;
    requestFocus();
  }
}
