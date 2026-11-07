import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The system-explicit options as a section of the tools page
/// (OtherSettingView), where they live alongside the app's other
/// network-protection switches.
class SystemExplicitSection extends ConsumerStatefulWidget {
  const SystemExplicitSection({super.key});

  @override
  ConsumerState<SystemExplicitSection> createState() =>
      _SystemExplicitSectionState();
}

class _SystemExplicitSectionState extends ConsumerState<SystemExplicitSection> {
  var _ready = false;
  var _applyError = '';

  @override
  void initState() {
    super.initState();
    SystemExplicitStore.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  /// [directException] marks the direct-exception class (T54). Only
  /// that class needs rule mode: turning one on in global/direct mode
  /// offers the switch to rule mode. Interception options apply
  /// directly in every mode and never show the dialog.
  Future<void> _setRuleOption(
    bool on,
    void Function(bool) update, {
    required bool directException,
  }) async {
    final mode = ref.read(patchClashConfigProvider).mode;
    if (on && directException && mode != Mode.rule) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          // Liquid glass (T38 full rollout): same modal treatment as
          // CommonDialog — neutral fill, bright rim, specular band.
          final glassTokens = GlassTokens.resolve(
            dialogContext.colorScheme,
            GlassKind.dialog,
          );
          final glassShape = RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: glassTokens.rim,
              width: 0.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          );
          return GlassSurface(
            shape: glassShape,
            tokens: glassTokens,
            child: AlertDialog(
              shape: glassShape,
              backgroundColor: glassTokens.effectiveFill,
              title: Text(appLocalizations.systemExplicitRuleModeTitle),
              content: Text(
                appLocalizations.systemExplicitDirectExceptionModeDesc,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(appLocalizations.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(appLocalizations.systemExplicitSwitch),
                ),
              ],
            ),
          );
        },
      );
      if (accepted != true || !mounted) return;
      await globalState.appController.changeMode(Mode.rule);
      if (!mounted) return;
      if (ref.read(patchClashConfigProvider).mode != Mode.rule) {
        setState(
          () => _applyError = appLocalizations.systemExplicitRuleModeNotApplied,
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() => update(on));
    await _commit();
  }

  Future<void> _commit() async {
    try {
      await saveAndReloadSystemExplicit(
        save: SystemExplicitStore.instance.save,
        // Rule changes need a full profile setup, not updateConfig, which only
        // updates general settings and leaves the existing rules untouched.
        reload: () => globalState.appController.applyProfileChecked(),
      );
    } on Object catch (error) {
      // Saved choices can differ from the running configuration after failure.
      if (mounted) {
        setState(
          () => _applyError = appLocalizations.systemExplicitApplyUnconfirmed(
            '$error',
          ),
        );
      }
      return;
    }
    if (mounted) setState(() => _applyError = '');
  }

  /// Descriptions stay collapsed until the row is tapped, so the page reads
  /// as a compact list of switches; the explanation is one tap away.
  final _expanded = <String>{};

  void _toggleExpanded(String id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  Widget _optionItem({
    required String id,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final expanded = _expanded.contains(id);
    // Built with ListItem.switchItem like every other settings page, so the
    // switch is the component library's own and follows the app theme.
    // The chevron stays separately tappable: tapping the row toggles the
    // switch (the switchItem convention), tapping the chevron expands the
    // description. A plain GestureDetector is used on purpose: stock
    // Material buttons need a Material ancestor this tree does not have.
    return ListItem.switchItem(
      padding: const EdgeInsets.only(left: 16, right: 8),
      title: Text(title),
      subtitle: expanded ? Text(desc) : null,
      trailing: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleExpanded(id),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      delegate: SwitchDelegate(value: value, onChanged: onChanged),
    );
  }

  Widget _infoItem({
    required String id,
    required String title,
    required String desc,
  }) {
    final expanded = _expanded.contains(id);
    return ListItem(
      padding: const EdgeInsets.only(left: 16, right: 8),
      title: Text(title),
      subtitle: expanded ? Text(desc) : null,
      onTap: () => _toggleExpanded(id),
      trailing: Icon(
        expanded ? Icons.expand_less : Icons.expand_more,
        size: 20,
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.shrink();
    }
    final value = SystemExplicitStore.instance.value;
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final incompatible = !systemExplicitModeCompatible(value, mode);
    return generateSection(
      title: appLocalizations.systemExplicitTitle,
      items: [
        // T54: effectiveness is per class and visible on this page —
        // direct exceptions are the only options that pause outside
        // rule mode; interception options keep working everywhere.
        if (incompatible)
          ListItem(
            title: Text(appLocalizations.systemExplicitExceptionsInactive),
            subtitle: Text(
              appLocalizations.systemExplicitExceptionsInactiveDesc,
            ),
          ),
        if (mode != Mode.rule && value.interceptionEnabled)
          _infoItem(
            id: 'interceptionActive',
            title: appLocalizations.systemExplicitInterceptionActive,
            desc: appLocalizations.systemExplicitInterceptionActiveDesc,
          ),
        if (_applyError.isNotEmpty)
          ListItem(
            title: Text(appLocalizations.systemExplicitApplyState),
            subtitle: Text(_applyError),
          ),
        _optionItem(
          id: 'privacy',
          title: appLocalizations.systemExplicitPrivacy,
          desc: appLocalizations.systemExplicitPrivacyDesc,
          value: value.privacy,
          onChanged: (on) =>
              _setRuleOption(on, (valueOn) => value.privacy = valueOn, directException: false),
        ),
        _optionItem(
          id: 'chinaDirect',
          title: appLocalizations.systemExplicitChinaDirect,
          desc: appLocalizations.systemExplicitChinaDirectDesc,
          value: value.chinaDirect,
          onChanged: (on) =>
              _setRuleOption(on, (valueOn) => value.chinaDirect = valueOn, directException: true),
        ),
        _optionItem(
          id: 'chinaDnsDirect',
          title: appLocalizations.systemExplicitChinaDnsDirect,
          desc: appLocalizations.systemExplicitChinaDnsDirectDesc,
          value: value.chinaPublicDnsDirect,
          onChanged: (on) => _setRuleOption(
            on,
            (valueOn) => value.chinaPublicDnsDirect = valueOn,
            directException: true,
          ),
        ),
        _optionItem(
          id: 'lanDirect',
          title: appLocalizations.systemExplicitLanDirect,
          desc: appLocalizations.systemExplicitLanDirectDesc,
          value: value.lanDirect,
          onChanged: (on) =>
              _setRuleOption(on, (valueOn) => value.lanDirect = valueOn, directException: true),
        ),
        _optionItem(
          id: 'blockWebRtc',
          title: appLocalizations.systemExplicitBlockWebRtc,
          desc: appLocalizations.systemExplicitBlockWebRtcDesc,
          value: value.blockCommonWebRtc,
          onChanged: (on) => _setRuleOption(
            on,
            (valueOn) => value.blockCommonWebRtc = valueOn,
            directException: false,
          ),
        ),
        _optionItem(
          id: 'blockAds',
          title: appLocalizations.systemExplicitBlockAds,
          desc: appLocalizations.systemExplicitBlockAdsDesc,
          value: value.blockAds,
          onChanged: (on) =>
              _setRuleOption(on, (valueOn) => value.blockAds = valueOn, directException: false),
        ),
        _infoItem(
          id: 'limits',
          title: appLocalizations.systemExplicitLimits,
          desc: appLocalizations.systemExplicitLimitsDesc,
        ),
      ],
    ).first;
  }
}
