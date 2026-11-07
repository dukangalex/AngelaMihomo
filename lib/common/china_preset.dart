import 'package:bett_box/common/system_explicit.dart';

/// China adaptation preset (T57): a one-tap combination of EXISTING
/// app capabilities recommended for use from China — the system
/// explicit interception trio (privacy discovery block, WebRTC block,
/// ad block) plus automatic system DNS setup. Nothing new is added:
/// no extra rules, no extra requests, only switches the app already
/// ships, grouped.
enum ChinaPresetState { on, off, customized }

SystemExplicitOptions _withTrio(SystemExplicitOptions current, bool on) =>
    SystemExplicitOptions(
      privacy: on,
      chinaDirect: current.chinaDirect,
      chinaPublicDnsDirect: current.chinaPublicDnsDirect,
      lanDirect: current.lanDirect,
      blockCommonWebRtc: on,
      blockAds: on,
    );

/// The explicit options with the preset applied (other options —
/// including the rule-mode direct exceptions — are left untouched).
SystemExplicitOptions chinaPresetExplicitOn(SystemExplicitOptions current) =>
    _withTrio(current, true);

/// The explicit options with the preset removed (back to defaults —
/// the interception trio is opt-in, so default is off).
SystemExplicitOptions chinaPresetExplicitOff(SystemExplicitOptions current) =>
    _withTrio(current, false);

/// Preset state from the live values of its members. Any single-item
/// change by the user moves the preset to [ChinaPresetState.customized]
/// — the preset then steps back and never silently overrides the
/// user's own change (it only moves when explicitly applied/reset).
/// Automatic system DNS is part of the recommended combination and
/// also its factory default, so "off" means the trio is off.
ChinaPresetState chinaPresetState({
  required SystemExplicitOptions options,
  required bool autoSetSystemDns,
}) {
  final trioOn =
      options.privacy && options.blockCommonWebRtc && options.blockAds;
  final trioOff =
      !options.privacy && !options.blockCommonWebRtc && !options.blockAds;
  if (trioOn && autoSetSystemDns) return ChinaPresetState.on;
  if (trioOff) return ChinaPresetState.off;
  return ChinaPresetState.customized;
}
