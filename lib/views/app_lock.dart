import 'package:bett_box/common/app_lock.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Live biometric capability probe (T66), shared by the lock screen
/// and the settings page. All platform failures fold into
/// [BiometricAvailability.unsupported] — the caller then falls back
/// to the PIN and says why, never to a dead switch.
Future<BiometricAvailability> probeBiometricAvailability() async {
  try {
    final auth = LocalAuthentication();
    final supported = await auth.isDeviceSupported();
    if (!supported) return BiometricAvailability.unsupported;
    final canCheck = await auth.canCheckBiometrics;
    final enrolled = await auth.getAvailableBiometrics();
    return resolveBiometricAvailability(
      deviceSupported: true,
      canCheckBiometrics: canCheck,
      enrolledCount: enrolled.length,
    );
  } catch (_) {
    return BiometricAvailability.unsupported;
  }
}

String appLockBiometricReason(BiometricAvailability availability) =>
    switch (availability) {
      BiometricAvailability.available =>
        appLocalizations.appLockBiometricUnavailable,
      BiometricAvailability.notEnrolled =>
        appLocalizations.appLockBiometricNotEnrolled,
      BiometricAvailability.noHardware =>
        appLocalizations.appLockBiometricNoHardware,
      BiometricAvailability.unsupported =>
        appLocalizations.appLockBiometricUnsupported,
    };

/// Numeric PIN pad shared by the lock screen and setup/verify flows.
class PinPad extends StatelessWidget {
  final int enteredLength;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onSubmit;

  const PinPad({
    super.key,
    required this.enteredLength,
    required this.onDigit,
    required this.onDelete,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback? onTap, {IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: context.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Center(
                child: icon != null
                    ? Icon(icon)
                    : Text(label, style: context.textTheme.headlineSmall),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 6; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < enteredLength
                      ? context.colorScheme.primary
                      : context.colorScheme.outlineVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final digit in row) key(digit, () => onDigit(digit))],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            key('', onDelete, icon: Icons.backspace_outlined),
            key('0', () => onDigit('0')),
            key('', onSubmit, icon: Icons.check),
          ],
        ),
      ],
    );
  }
}

/// Full-screen lock: shown on cold start and after the re-lock
/// interval. Covers the whole app (mounted above the navigator);
/// the VPN service is untouched by design.
class AppLockScreen extends StatefulWidget {
  final AppLockConfig config;
  final VoidCallback onUnlocked;

  const AppLockScreen({
    super.key,
    required this.config,
    required this.onUnlocked,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _entered = '';
  String? _error;
  int _lockedUntilMs = 0;

  /// Live availability, probed once when the lock screen appears
  /// (T66): the biometric affordance exists only when the device can
  /// really prompt right now. The gate re-locks on cold start and on
  /// return from background, and this screen is what it mounts, so
  /// the same re-lock timing covers biometric unlock too.
  BiometricAvailability? _biometricAvailability;

  @override
  void initState() {
    super.initState();
    _lockedUntilMs = widget.config.lockedUntilMs;
    if (widget.config.biometricEnabled) {
      _probeBiometrics();
    }
  }

  Future<void> _probeBiometrics() async {
    final availability = await probeBiometricAvailability();
    if (!mounted) return;
    setState(() => _biometricAvailability = availability);
    if (biometricUnlockAllowed(
      config: widget.config,
      availability: availability,
    )) {
      _tryBiometric();
    }
  }

  int get _waitSeconds {
    final remaining = _lockedUntilMs - DateTime.now().millisecondsSinceEpoch;
    return remaining > 0 ? (remaining / 1000).ceil() : 0;
  }

  Future<void> _tryBiometric() async {
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) return;
      final ok = await auth.authenticate(
        localizedReason: appLocalizations.appLockUnlockBiometric,
        biometricOnly: false,
      );
      if (ok && mounted) {
        await AppLockStore.save(
          widget.config.copyWith(failedAttempts: 0, lockedUntilMs: 0),
        );
        widget.onUnlocked();
      }
    } catch (_) {
      // Biometrics unavailable/failing falls back to the PIN pad.
    }
  }

  Future<void> _submit() async {
    if (_entered.length < 4 || _waitSeconds > 0) return;
    final result = await AppLockStore.verify(_entered);
    if (!mounted) return;
    if (result.ok) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _entered = '';
      _lockedUntilMs = result.config.lockedUntilMs;
      _error = _waitSeconds > 0
          ? appLocalizations.appLockWait
          : appLocalizations.appLockWrongPin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 44,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  appLocalizations.appLockEnterPin,
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 20,
                  child: _error == null
                      ? null
                      : Text(
                          _error!,
                          style: TextStyle(color: context.colorScheme.error),
                        ),
                ),
                const SizedBox(height: 16),
                PinPad(
                  enteredLength: _entered.length,
                  onDigit: (digit) {
                    if (_entered.length >= 6) return;
                    setState(() {
                      _entered += digit;
                      _error = null;
                    });
                  },
                  onDelete: () {
                    if (_entered.isEmpty) return;
                    setState(
                      () => _entered = _entered.substring(
                        0,
                        _entered.length - 1,
                      ),
                    );
                  },
                  onSubmit: _entered.length >= 4 && _waitSeconds == 0
                      ? _submit
                      : null,
                ),
                if (widget.config.biometricEnabled &&
                    _biometricAvailability ==
                        BiometricAvailability.available) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(appLocalizations.appLockUnlockBiometric),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mounts the lock over the whole app (T39). Locks on cold start
/// when enabled, and again after the configured background interval.
class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  AppLockConfig? _config;
  bool _loaded = false;
  bool _locked = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The settings page and this gate live in the same process:
    // every store save bumps the revision, and the gate reloads on
    // the spot. (Previously nothing ever refreshed the gate's
    // startup snapshot, so a lock enabled in settings stayed unknown
    // to the gate until the process died — the lock simply never
    // engaged when the task was swiped away but the process lived.)
    AppLockStore.revision.addListener(_onStoreChanged);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final config = await AppLockStore.load();
    if (!mounted) return;
    setState(() {
      _config = config;
      _loaded = true;
      _locked = appLockShouldLock(
        config: config,
        coldStart: true,
        backgroundedAt: null,
        now: DateTime.now(),
      );
    });
  }

  void _onStoreChanged() {
    AppLockStore.load().then((config) {
      if (mounted) setState(() => _config = config);
    });
  }

  @override
  void dispose() {
    AppLockStore.revision.removeListener(_onStoreChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (_locked) return;
    // Re-read the store instead of trusting the snapshot taken at
    // startup: the config may have changed while we were away (or
    // in a previous visit to the settings page in this process).
    AppLockStore.load().then((config) {
      if (!mounted) return;
      setState(() {
        _config = config;
        _locked = appLockShouldLock(
          config: config,
          coldStart: false,
          backgroundedAt: backgroundedAt,
          now: DateTime.now(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Nothing of the app shows until the first config read has
        // answered: content first appears either unlocked or behind
        // the PIN screen, never as a flash of the unlocked UI.
        if (_loaded) widget.child,
        if (!_loaded)
          Positioned.fill(
            child: ColoredBox(color: context.colorScheme.surface),
          ),
        if (_loaded && _locked && _config != null)
          Positioned.fill(
            child: AppLockScreen(
              config: _config!,
              onUnlocked: () => setState(() => _locked = false),
            ),
          ),
      ],
    );
  }
}

/// Settings entry in the application settings list.
class AppLockEntryItem extends StatelessWidget {
  const AppLockEntryItem({super.key});

  @override
  Widget build(BuildContext context) {
    // T70: no leading icon — matches the icon-less rows of the
    // application settings page so the title baseline aligns.
    return ListItem(
      title: Text(appLocalizations.appLock),
      subtitle: Text(appLocalizations.appLockDesc),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => BaseNavigator.push(context, const AppLockSettingsView()),
    );
  }
}

class AppLockSettingsView extends ConsumerStatefulWidget {
  const AppLockSettingsView({super.key});

  @override
  ConsumerState<AppLockSettingsView> createState() =>
      _AppLockSettingsViewState();
}

class _AppLockSettingsViewState extends ConsumerState<AppLockSettingsView> {
  AppLockConfig? _config;

  /// Probed when the settings page opens (T66): decides whether the
  /// biometric switch is live, or shown greyed with its reason.
  BiometricAvailability? _biometricAvailability;

  /// Setup/verify sub-flow: 'set' → enter new PIN, 'confirm' → repeat
  /// it, 'verifyDisable' → prove the PIN to turn the lock off.
  String? _flowStep;
  String _entered = '';
  String _firstPin = '';
  String? _flowError;

  @override
  void initState() {
    super.initState();
    _load();
    probeBiometricAvailability().then((availability) {
      if (mounted) setState(() => _biometricAvailability = availability);
    });
  }

  Future<void> _load() async {
    final config = await AppLockStore.load();
    if (mounted) setState(() => _config = config);
  }

  Future<void> _submitFlow() async {
    final config = _config;
    if (config == null || _entered.length < 4) return;
    switch (_flowStep) {
      case 'set':
        setState(() {
          _firstPin = _entered;
          _entered = '';
          _flowStep = 'confirm';
          _flowError = null;
        });
      case 'confirm':
        if (_entered != _firstPin) {
          setState(() {
            _entered = '';
            _firstPin = '';
            _flowStep = 'set';
            _flowError = appLocalizations.appLockPinMismatch;
          });
          return;
        }
        await AppLockStore.setPin(_entered);
        await _load();
        if (mounted) {
          setState(() {
            _flowStep = null;
            _entered = '';
          });
          globalState.showNotifier(appLocalizations.saveSuccess);
        }
      case 'verifyDisable':
        final result = await AppLockStore.verify(_entered);
        if (!result.ok) {
          setState(() {
            _entered = '';
            _flowError = appLocalizations.appLockWrongPin;
          });
          return;
        }
        await AppLockStore.disable();
        await _load();
        if (mounted) {
          setState(() {
            _flowStep = null;
            _entered = '';
          });
        }
    }
  }

  Widget _flowBody() {
    final title = switch (_flowStep) {
      'set' => appLocalizations.appLockSetPin,
      'confirm' => appLocalizations.appLockConfirmPin,
      _ => appLocalizations.appLockEnterPin,
    };
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Center(
          child: Text(title, style: context.textTheme.titleLarge),
        ),
        if (_flowError != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              _flowError!,
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: 24),
        PinPad(
          enteredLength: _entered.length,
          onDigit: (digit) {
            if (_entered.length >= 6) return;
            setState(() => _entered += digit);
          },
          onDelete: () {
            if (_entered.isEmpty) return;
            setState(
              () => _entered = _entered.substring(0, _entered.length - 1),
            );
          },
          onSubmit: _entered.length >= 4 ? _submitFlow : null,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _flowStep = null;
              _entered = '';
              _flowError = null;
            }),
            child: Text(appLocalizations.cancel),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return CommonScaffold(
      title: appLocalizations.appLock,
      body: config == null
          ? const Center(child: CircularProgressIndicator())
          : _flowStep != null
          ? _flowBody()
          : ListView(
              children: [
                ...generateSection(
                  items: [
                    ListItem(
                      title: Text(appLocalizations.appLock),
                      subtitle: Text(appLocalizations.appLockDesc),
                      trailing: Switch(
                        value: config.enabled && config.hasPin,
                        onChanged: (on) {
                          if (on) {
                            setState(() {
                              _flowStep = 'set';
                              _entered = '';
                              _flowError = null;
                            });
                          } else {
                            setState(() {
                              _flowStep = 'verifyDisable';
                              _entered = '';
                              _flowError = null;
                            });
                          }
                        },
                      ),
                    ),
                    if (config.enabled && config.hasPin) ...[
                      ListItem(
                        title: Text(appLocalizations.appLockRelock),
                        subtitle: Wrap(
                          spacing: 8,
                          children: [
                            for (final (seconds, label) in [
                              (0, appLocalizations.appLockRelockImmediate),
                              (30, appLocalizations.appLockRelock30s),
                              (60, appLocalizations.appLockRelock1m),
                              (300, appLocalizations.appLockRelock5m),
                            ])
                              ChoiceChip(
                                label: Text(label),
                                selected: config.relockSeconds == seconds,
                                onSelected: (_) async {
                                  await AppLockStore.save(
                                    config.copyWith(relockSeconds: seconds),
                                  );
                                  await _load();
                                },
                              ),
                          ],
                        ),
                      ),
                      // No fake switches (T66): the option is
                      // switchable only when the live probe says the
                      // device can really prompt; otherwise it is
                      // greyed and the reason sits right under it.
                      ListItem(
                        title: Text(appLocalizations.appLockBiometric),
                        subtitle:
                            _biometricAvailability != null &&
                                _biometricAvailability !=
                                    BiometricAvailability.available
                            ? Text(
                                appLockBiometricReason(
                                  _biometricAvailability!,
                                ),
                              )
                            : null,
                        trailing: Switch(
                          value: config.biometricEnabled,
                          onChanged:
                              _biometricAvailability ==
                                  BiometricAvailability.available
                              ? (on) async {
                                  await AppLockStore.save(
                                    config.copyWith(biometricEnabled: on),
                                  );
                                  await _load();
                                }
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    appLocalizations.appLockNoRecovery,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
