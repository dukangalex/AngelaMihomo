import 'package:bett_box/common/china_preset.dart';
import 'package:bett_box/common/system_explicit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preset state follows its members', () {
    final off = SystemExplicitOptions();
    expect(
      chinaPresetState(options: off, autoSetSystemDns: true),
      ChinaPresetState.off,
    );
    final on = chinaPresetExplicitOn(off);
    expect(
      chinaPresetState(options: on, autoSetSystemDns: true),
      ChinaPresetState.on,
    );
    // One member changed by hand: customized, never silently "on".
    on.blockAds = false;
    expect(
      chinaPresetState(options: on, autoSetSystemDns: true),
      ChinaPresetState.customized,
    );
    // DNS off while the trio is on is also a customization.
    final onAgain = chinaPresetExplicitOn(SystemExplicitOptions());
    expect(
      chinaPresetState(options: onAgain, autoSetSystemDns: false),
      ChinaPresetState.customized,
    );
  });

  test('apply/reset only touch the trio, exceptions preserved', () {
    final current = SystemExplicitOptions(chinaDirect: true, lanDirect: true);
    final applied = chinaPresetExplicitOn(current);
    expect(applied.privacy, isTrue);
    expect(applied.blockCommonWebRtc, isTrue);
    expect(applied.blockAds, isTrue);
    expect(applied.chinaDirect, isTrue);
    expect(applied.lanDirect, isTrue);
    final reset = chinaPresetExplicitOff(applied);
    expect(reset.privacy, isFalse);
    expect(reset.chinaDirect, isTrue);
  });
}
