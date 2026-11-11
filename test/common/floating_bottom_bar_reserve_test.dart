import 'package:bett_box/common/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// T67: the reserve helpers must derive from viewPadding only. Under the
// floating bottom bar, HomePage broadcasts the reserve itself as
// MediaQuery.padding.bottom; if the helpers read padding, the reserve
// would feed back into itself and inflate on every rebuild.
void main() {
  Future<double> pumpReserve(
    WidgetTester tester, {
    required EdgeInsets padding,
    required EdgeInsets viewPadding,
  }) async {
    double? value;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: padding, viewPadding: viewPadding),
        child: Builder(
          builder: (context) {
            value = getFloatingBottomBarReserveHeight(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return value!;
  }

  testWidgets('reserve ignores a polluted MediaQuery.padding', (
    tester,
  ) async {
    // Gesture-nav phone: system viewPadding 24 -> 84 + (24 - 12) = 96,
    // even when an ancestor already wrote 96 into padding.
    final polluted = await pumpReserve(
      tester,
      padding: const EdgeInsets.only(bottom: 96),
      viewPadding: const EdgeInsets.only(bottom: 24),
    );
    expect(polluted, 96);

    final clean = await pumpReserve(
      tester,
      padding: const EdgeInsets.only(bottom: 24),
      viewPadding: const EdgeInsets.only(bottom: 24),
    );
    expect(clean, 96);
  });

  testWidgets('reserve on a zero-inset display is the bare bar height', (
    tester,
  ) async {
    final value = await pumpReserve(
      tester,
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
    );
    expect(value, 84);
  });
}
